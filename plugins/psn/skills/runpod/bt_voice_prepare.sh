#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# BT-7274 Polish Piper Voice — Data Preparation Pipeline
# =============================================================================
# Runs entirely on junkpile (local GPU). Prepares everything needed for
# fine-tuning on a RunPod pod.
#
# Prerequisites:
#   - faster-whisper in ~/Projects/bt7274/.venv/
#   - sox, ffmpeg, espeak-ng installed
#   - ~/Projects/bt7274/bt_voices/ contains raw extracted WAVs
#
# Output:
#   ~/Projects/bt7274/training_package/  — ready to upload to RunPod
#     ├── dataset/
#     │   ├── metadata.csv
#     │   └── wav/
#     ├── base_checkpoint/
#     │   └── epoch=4909-step=1454360.ckpt
#     └── train.sh  — training script to run on the pod
# =============================================================================

PROJECT_DIR="$HOME/Projects/bt7274"
RAW_DIR="$PROJECT_DIR/bt_voices"
WORK_DIR="$PROJECT_DIR/training_prep"
OUTPUT_DIR="$PROJECT_DIR/training_package"
DATASET_DIR="$OUTPUT_DIR/dataset"
WAV_DIR="$DATASET_DIR/wav"
CHECKPOINT_DIR="$OUTPUT_DIR/base_checkpoint"
VENV="$PROJECT_DIR/.venv/bin"
WHISPER_MODEL="large-v3"

# Counters
total=0
skipped_short=0
skipped_dup=0
kept=0

echo "=============================================="
echo "  BT-7274 Polish Voice — Data Preparation"
echo "=============================================="
echo ""

# -----------------------------------------------------------------------------
# Phase 0: Clean slate
# -----------------------------------------------------------------------------
echo "==> Phase 0: Cleaning work directories..."
rm -rf "$WORK_DIR" "$OUTPUT_DIR"
mkdir -p "$WORK_DIR/filtered" "$WAV_DIR" "$CHECKPOINT_DIR"

# -----------------------------------------------------------------------------
# Phase 1: Deduplicate and filter
# -----------------------------------------------------------------------------
echo "==> Phase 1: Deduplicating and filtering audio..."
echo "    Source: $RAW_DIR"

# Strategy:
# - Keep only L3 variants (cleanest) when available, fall back to base
# - Skip L2 variants entirely (mid-processing layer)
# - Keep only diag_sp_ (story dialogue), skip diag_gs_ (short barks)
# - Drop anything under 1.5 seconds

# Build a map: base_name -> best variant
declare -A best_variant

for wav in "$RAW_DIR"/diag_sp_*.wav; do
    fname=$(basename "$wav" .wav)
    total=$((total + 1))

    # Determine base name (strip _L2 or _L3 suffix)
    if [[ "$fname" == *_L3 ]]; then
        base="${fname%_L3}"
        priority=3
    elif [[ "$fname" == *_L2 ]]; then
        # Skip L2 entirely
        skipped_dup=$((skipped_dup + 1))
        continue
    else
        base="$fname"
        priority=1
    fi

    # Keep highest priority variant per base name
    current_priority="${best_variant[$base]:-0}"
    if (( priority > current_priority )); then
        best_variant[$base]=$priority
    fi
done

echo "    Total diag_sp_ files scanned: $total"
echo "    Skipped L2 variants: $skipped_dup"

# Now copy best variants and filter by duration
for base in "${!best_variant[@]}"; do
    priority=${best_variant[$base]}
    if (( priority == 3 )); then
        src="$RAW_DIR/${base}_L3.wav"
    else
        src="$RAW_DIR/${base}.wav"
    fi

    if [[ ! -f "$src" ]]; then
        continue
    fi

    # Check duration
    duration=$(soxi -D "$src" 2>/dev/null || echo "0")
    duration_int=${duration%.*}

    if (( duration_int < 2 )); then
        skipped_short=$((skipped_short + 1))
        continue
    fi

    # Keep files under 15 seconds (very long files can hurt training)
    if (( duration_int > 15 )); then
        skipped_short=$((skipped_short + 1))
        continue
    fi

    cp "$src" "$WORK_DIR/filtered/"
    kept=$((kept + 1))
done

echo "    Skipped too short/long: $skipped_short"
echo "    Kept for processing: $kept"
echo ""

# -----------------------------------------------------------------------------
# Phase 2: Normalize audio to Piper format
# -----------------------------------------------------------------------------
echo "==> Phase 2: Normalizing audio to 22050Hz mono 16-bit..."

idx=0
declare -A file_map  # maps bt_NNNN -> original filename (for reference)

for wav in "$WORK_DIR/filtered/"*.wav; do
    outname=$(printf "bt%04d" $idx)

    # Convert to 22050Hz, mono, 16-bit, normalize volume
    sox "$wav" -r 22050 -c 1 -b 16 "$WAV_DIR/${outname}.wav" \
        norm -1 2>/dev/null

    file_map[$outname]=$(basename "$wav")
    idx=$((idx + 1))
done

echo "    Normalized $idx files to $WAV_DIR"
echo ""

# Save file mapping for reference
for key in $(echo "${!file_map[@]}" | tr ' ' '\n' | sort); do
    echo "$key|${file_map[$key]}"
done > "$OUTPUT_DIR/file_mapping.csv"

# -----------------------------------------------------------------------------
# Phase 3: Transcribe with Whisper large-v3
# -----------------------------------------------------------------------------
echo "==> Phase 3: Transcribing with Whisper $WHISPER_MODEL (Polish)..."
echo "    This may take 10-20 minutes..."

"$VENV/python3" - "$WAV_DIR" "$DATASET_DIR/metadata.csv" <<'PYEOF'
import sys
import os
from pathlib import Path
from faster_whisper import WhisperModel

wav_dir = Path(sys.argv[1])
output_csv = sys.argv[2]

print("  Loading Whisper large-v3...")
model = WhisperModel("large-v3", device="cuda", compute_type="float16")

wav_files = sorted(wav_dir.glob("bt*.wav"))
print(f"  Transcribing {len(wav_files)} files...")

results = []
errors = []

for i, wav in enumerate(wav_files):
    try:
        segments, info = model.transcribe(
            str(wav),
            language="pl",
            task="transcribe",
            beam_size=5,
            best_of=5,
            vad_filter=True,
            vad_parameters=dict(min_silence_duration_ms=500),
        )
        text = " ".join(seg.text.strip() for seg in segments).strip()

        if not text:
            errors.append(wav.stem)
            continue

        results.append((wav.stem, text))

        if (i + 1) % 50 == 0:
            print(f"  ... {i+1}/{len(wav_files)} done")
    except Exception as e:
        print(f"  ERROR on {wav.name}: {e}")
        errors.append(wav.stem)

# Write metadata.csv in LJSpeech format (pipe-delimited)
with open(output_csv, "w", encoding="utf-8") as f:
    for stem, text in results:
        # Double the text column (Piper LJSpeech format: id|text|text)
        f.write(f"{stem}|{text}|{text}\n")

print(f"  Transcribed: {len(results)}")
print(f"  Errors/empty: {len(errors)}")
if errors:
    print(f"  Failed files: {', '.join(errors[:10])}")
PYEOF

transcript_count=$(wc -l < "$DATASET_DIR/metadata.csv" 2>/dev/null || echo "0")
echo "    Transcripts written: $transcript_count"
echo ""

# -----------------------------------------------------------------------------
# Phase 4: Download Polish base checkpoint
# -----------------------------------------------------------------------------
CKPT_URL="https://huggingface.co/datasets/rhasspy/piper-checkpoints/resolve/main/pl/pl_PL/darkman/medium/epoch%3D4909-step%3D1454360.ckpt"
CKPT_FILE="$CHECKPOINT_DIR/epoch=4909-step=1454360.ckpt"

if [[ -f "$CKPT_FILE" ]]; then
    echo "==> Phase 4: Base checkpoint already downloaded"
else
    echo "==> Phase 4: Downloading Polish base checkpoint (darkman-medium, ~846MB)..."
    wget -q --show-progress -O "$CKPT_FILE" "$CKPT_URL"
fi
echo ""

# -----------------------------------------------------------------------------
# Phase 5: Generate RunPod training script
# -----------------------------------------------------------------------------
echo "==> Phase 5: Generating training script for RunPod pod..."

cat > "$OUTPUT_DIR/train.sh" <<'TRAINEOF'
#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# BT-7274 Piper Voice — RunPod Training Script
# =============================================================================
# Run this on a RunPod GPU pod after uploading the training_package directory.
#
# Prerequisites: Pod with PyTorch, CUDA, Python 3.10/3.11
# GPU: A40 (48GB) or better recommended
# =============================================================================

PACKAGE_DIR="${1:-/workspace/training_package}"
TRAINING_DIR="$PACKAGE_DIR/training_output"
DATASET_DIR="$PACKAGE_DIR/dataset"
CHECKPOINT="$PACKAGE_DIR/base_checkpoint/epoch=4909-step=1454360.ckpt"

echo "==> Installing Piper training dependencies..."
apt-get update -qq && apt-get install -y -qq espeak-ng > /dev/null 2>&1

pip install -q piper-phonemize~=1.1.0 piper-tts
pip install -q 'pytorch-lightning~=1.7.0' 'torch>=1.13.0,<2' librosa cython

# Clone piper for training module
if [[ ! -d "$PACKAGE_DIR/piper" ]]; then
    git clone --depth 1 https://github.com/rhasspy/piper.git "$PACKAGE_DIR/piper"
fi

cd "$PACKAGE_DIR/piper/src/python"
pip install -e . 2>/dev/null

echo "==> Preprocessing dataset..."
python3 -m piper_train.preprocess \
    --input-dir "$DATASET_DIR" \
    --output-dir "$TRAINING_DIR" \
    --language pl \
    --sample-rate 22050 \
    --dataset-format ljspeech \
    --single-speaker

echo "==> Starting fine-tuning from Polish base checkpoint..."
echo "    Base: darkman-medium (4909 epochs pre-trained)"
echo "    Target: 1000 additional epochs"

python3 -m piper_train \
    --dataset-dir "$TRAINING_DIR" \
    --accelerator gpu \
    --devices 1 \
    --batch-size 16 \
    --quality medium \
    --max_epochs 1000 \
    --checkpoint-epochs 100 \
    --validation-split 0.0 \
    --precision 32 \
    --resume_from_checkpoint "$CHECKPOINT"

echo "==> Exporting to ONNX..."
# Find the latest checkpoint
LATEST_CKPT=$(ls -t "$TRAINING_DIR/lightning_logs/version_"*/checkpoints/*.ckpt 2>/dev/null | head -1)
if [[ -z "$LATEST_CKPT" ]]; then
    echo "ERROR: No checkpoint found after training!"
    exit 1
fi

python3 -m piper_train.export_onnx \
    "$LATEST_CKPT" \
    "$PACKAGE_DIR/bt7274_polish.onnx"

echo ""
echo "=============================================="
echo "  Training complete!"
echo "  Model: $PACKAGE_DIR/bt7274_polish.onnx"
echo "=============================================="
TRAINEOF

chmod +x "$OUTPUT_DIR/train.sh"

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo "=============================================="
echo "  Preparation Complete"
echo "=============================================="
echo ""
echo "  Training package: $OUTPUT_DIR"
echo "    dataset/wav/         : $idx normalized WAV files"
echo "    dataset/metadata.csv : $transcript_count transcripts"
echo "    base_checkpoint/     : darkman-medium (pl_PL)"
echo "    train.sh             : RunPod training script"
echo "    file_mapping.csv     : original filename reference"
echo ""
echo "  Next steps:"
echo "    1. Review a few transcripts:  head -5 $DATASET_DIR/metadata.csv"
echo "    2. Spin up RunPod A40 pod"
echo "    3. Upload training_package/ to pod"
echo "    4. Run: bash /workspace/training_package/train.sh"
echo ""

# Package size
du -sh "$OUTPUT_DIR" | awk '{print "  Total package size: " $1}'
