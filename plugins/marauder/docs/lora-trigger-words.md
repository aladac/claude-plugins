# LoRA Trigger Words Reference

Quick reference for all LoRA models on junkpile (`/home/comfyui/models/loras/`).
Metadata sourced from tensors DB (`~/.local/share/tensors/models.db`).

## Mecha LoRAs

### Super Robot Diffusion Rise (SD 1.5)
**File:** `superRobotDiffusionRiseGundam_v10.safetensors`

| Trigger | Style |
|---------|-------|
| `SRS` | Super robot (Gundam-like) |
| `RRS` | Real robot |
| `MRS` | Military mech |
| `FRS` | Fantasy mech |
| `RARS` | Real armored |
| `HRS` | Heavy mech (Hawken-like) |
| `BRS` | Biomechanical |
| `LRS` | Light/skinny mech |
| `NJRS` | Ninja mech |
| `ROBOTANIMESTYLE` | Anime rendering |
| `ROBOTARTSTYLE` | Digital art rendering |

**Modifiers:** `MECHA-BACK-UNIT`, `MECHA-HUGE-ARMS`, `MECHA-QUAD-LEGS`, `MECHA-TANK-LEGS`, `MECHA-WINGS`

### Super Robot Diffusion XL (Illustrious/SDXL)
**File:** `srdxl_v2_7_7_for_IllustriousXL_v01.safetensors`

Same trigger system as Rise with prefixed variants:
- `A-SRS`, `B-SRS`, `R-SRS`, `S-SRS` (super robot variants)
- `A-RRS`, `B-RRS`, `R-RRS`, `S-RRS` (real robot variants)
- `ROBOTCGSTYLE` (CG rendering, XL exclusive)
- Weight tips: `(a heavy mech:1.2)`, `(hawken:1.2)`, `(sharp design mecha:1.6)`

### Mech Dystopia (SDXL & SD 1.5)
**File:** `Mech_Dystopia_Style_SDXL.safetensors`

| Trigger | Style |
|---------|-------|
| `ais-mechdystopia` | Dystopian mech aesthetic |

### Agitype01 (SD 1.5/PonyXL/Illustrious)
**File:** `AgiMSRITS.safetensors`

| Trigger | Style |
|---------|-------|
| `agitype01` | Mecha/synth/robot style |

### MechaDream (Checkpoint, not LoRA)
**File:** `mechadreamAllInOne_v1.safetensors` (in checkpoints)

No trigger words — use as base model directly.

## Art Style LoRAs

### Ignacio Noe Style (Illustrious)
**File:** `Ignacio_Noe_Style_-_Illustrious.safetensors`

| Trigger | Style |
|---------|-------|
| `Ignoe-Style` | Ignacio Noe comic art style |

### 70s Vintage (Pony)
**File:** `70s_VPMS_V1-E20.safetensors`

| Trigger | Style |
|---------|-------|
| `70spm` | 70s magazine style |
| `vintage porn, 70s era, 1970s photo` | Additional modifiers |

### Obsessive Compulsive Disorder
**File:** `vitpitillust.safetensors`

| Trigger | Style |
|---------|-------|
| `devildonia_style` | Dark/devil aesthetic |
| `flawless_style` | Clean skin rendering |
| `realistic_skin_texture` | Photorealistic skin |

## Character LoRAs

### Elvira (Illustrious)
**File:** `Elvira iIlluLoRA.safetensors`

| Trigger | Description |
|---------|-------------|
| `Elviradg` | Base character |
| `long hair, blue eyes, black hair, makeup, eyeshadow, black lips` | Features |
| `long dress, black dress` | Outfit |

### Candy [Jab Comix]
**File:** `Candy_Jab_Comix.safetensors`

| Trigger | Description |
|---------|-------------|
| `candy_jab` | Base character (blonde, blue eyes) |
| `long hair` / `short hair` | Hair variants |
| Outfit tags for clothing variants | |

### Nellie [Jab Comix]
**File:** `Nellie_Jab_Comix-000009.safetensors`

| Trigger | Description |
|---------|-------------|
| `Nellie_Jab` | Base character (red hair, mature) |
| `green eyes` / `blue eyes` | Eye variants |
| Multiple hair and outfit variants | Positions 3-14 |

## Utility LoRAs

### Pet Home (SDXL)
**File:** `petHomeSDXL_v10.safetensors`

| Trigger | Style |
|---------|-------|
| `AP` | Animal/pet generation |

---

*Updated: 2026-04-14. Source: `tsr db` on junkpile.*
