#!/usr/bin/env bash
# GitHub Actions cleanup across all orgs
# Deletes failed/skipped/cancelled runs and runs older than 2 weeks

set -euo pipefail

ORGS="aladac saiden-dev tengu-apps"
CUTOFF_DATE=$(date -v-14d +%Y-%m-%dT00:00:00Z 2>/dev/null || date -d '14 days ago' --iso-8601=seconds 2>/dev/null)
TOTAL_DELETED=0
TOTAL_FAILED=0
TOTAL_OLD=0

for org in $ORGS; do
  echo ""
  echo "=== $org ==="
  repos=$(gh repo list "$org" --limit 100 --json nameWithOwner --jq '.[].nameWithOwner' 2>/dev/null)

  for repo in $repos; do
    failed_ids=$(gh run list --repo "$repo" --limit 100 --json databaseId,conclusion \
      --jq '.[] | select(.conclusion == "failure" or .conclusion == "skipped" or .conclusion == "cancelled") | .databaseId' 2>/dev/null || true)

    old_ids=$(gh run list --repo "$repo" --limit 100 --json databaseId,createdAt,conclusion \
      --jq ".[] | select(.createdAt < \"$CUTOFF_DATE\" and .conclusion != null) | .databaseId" 2>/dev/null || true)

    # Merge and deduplicate
    all_ids=$(echo -e "${failed_ids}\n${old_ids}" | sort -u | grep -v '^$' || true)

    if [ -n "$all_ids" ]; then
      count=$(echo "$all_ids" | wc -l | tr -d ' ')
      fail_count=$(echo "$failed_ids" | grep -c . 2>/dev/null || echo 0)
      old_count=$((count - fail_count))
      [ "$old_count" -lt 0 ] && old_count=0

      echo "  $repo: $count runs ($fail_count failed/skipped, ~$old_count old)"

      echo "$all_ids" | while read -r id; do
        gh run delete "$id" --repo "$repo" 2>/dev/null || true
      done

      TOTAL_DELETED=$((TOTAL_DELETED + count))
      TOTAL_FAILED=$((TOTAL_FAILED + fail_count))
      TOTAL_OLD=$((TOTAL_OLD + old_count))
    fi
  done
done

echo ""
echo "--- Summary ---"
echo "Total deleted: $TOTAL_DELETED"
echo "  Failed/skipped/cancelled: $TOTAL_FAILED"
echo "  Older than 2 weeks: ~$TOTAL_OLD"
