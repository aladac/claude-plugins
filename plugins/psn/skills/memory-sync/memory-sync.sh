#!/usr/bin/env bash
# Memory sync skill — synchronize PSN memories across all stores
# Usage: bash memory-sync.sh <command>

set -euo pipefail

SQLITE_DB="$HOME/.local/share/personality/main.db"
FUJI_PSQL="/opt/homebrew/opt/postgresql@17/bin/psql"
FUJI_PG="postgresql://psn:psn@localhost:5432/personality"
JUNKPILE_PG_PASS=$(op item get personality_db --vault DEV --fields credential 2>/dev/null || echo "tEtMSwXP5f963uGGh9d3RoOHpsX77hmH")
JUNKPILE_PG="postgresql://psn:${JUNKPILE_PG_PASS}@10.0.0.2:5432/personality"

cmd="${1:-status}"

fuji_sqlite_count() {
  sqlite3 "$SQLITE_DB" "SELECT count(*) FROM memories WHERE cart_id=1;"
}
fuji_sqlite_max() {
  sqlite3 "$SQLITE_DB" "SELECT max(id) FROM memories WHERE cart_id=1;"
}
fuji_sqlite_core() {
  sqlite3 "$SQLITE_DB" "SELECT count(*) FROM memories WHERE cart_id=1 AND classification='core';"
}
fuji_pg_count() {
  $FUJI_PSQL "$FUJI_PG" -t -A -c "SELECT count(*) FROM memories WHERE cart_id=1;" 2>/dev/null || echo "0"
}
fuji_pg_max() {
  $FUJI_PSQL "$FUJI_PG" -t -A -c "SELECT COALESCE(max(id),0) FROM memories WHERE cart_id=1;" 2>/dev/null || echo "0"
}
fuji_pg_core() {
  $FUJI_PSQL "$FUJI_PG" -t -A -c "SELECT count(*) FROM memories WHERE cart_id=1 AND classification='core';" 2>/dev/null || echo "0"
}
junkpile_pg_query() {
  ssh -T j "PGPASSWORD=$JUNKPILE_PG_PASS psql -U psn -h localhost -d personality -t -A -c \"$1\"" 2>/dev/null || echo "0"
}
junkpile_pg_count() {
  junkpile_pg_query "SELECT count(*) FROM memories WHERE cart_id=1;"
}
junkpile_pg_max() {
  junkpile_pg_query "SELECT COALESCE(max(id),0) FROM memories WHERE cart_id=1;"
}
junkpile_pg_core() {
  junkpile_pg_query "SELECT count(*) FROM memories WHERE cart_id=1 AND classification='core';"
}

case "$cmd" in
  status|s)
    echo "=== PSN Memory Sync Status ==="
    echo ""
    printf "%-20s %8s %8s %8s\n" "Store" "Count" "Max ID" "Core"
    printf "%-20s %8s %8s %8s\n" "---" "---" "---" "---"
    printf "%-20s %8s %8s %8s\n" "Fuji SQLite" "$(fuji_sqlite_count)" "$(fuji_sqlite_max)" "$(fuji_sqlite_core)"
    printf "%-20s %8s %8s %8s\n" "Fuji PG" "$(fuji_pg_count)" "$(fuji_pg_max)" "$(fuji_pg_core)"
    printf "%-20s %8s %8s %8s\n" "Junkpile PG" "$(junkpile_pg_count)" "$(junkpile_pg_max)" "$(junkpile_pg_core)"
    echo ""

    sc=$(fuji_sqlite_count)
    fc=$(fuji_pg_count)
    jc=$(junkpile_pg_count)
    if [ "$sc" = "$fc" ] && [ "$fc" = "$jc" ]; then
      echo "STATUS: IN SYNC"
    else
      echo "STATUS: OUT OF SYNC"
      [ "$sc" != "$fc" ] && echo "  Fuji PG behind SQLite by $((sc - fc)) memories"
      [ "$fc" != "$jc" ] && echo "  Junkpile PG differs from Fuji PG by $((fc - jc)) memories"
    fi
    ;;

  sync)
    echo "Full sync: SQLite → Fuji PG → Junkpile PG"
    bash "$0" sync-local
    bash "$0" sync-remote
    echo ""
    bash "$0" status
    ;;

  sync-local|sl)
    echo "Syncing Fuji SQLite → Fuji PG..."

    # Export from SQLite
    python3 << 'PY'
import sqlite3, json, subprocess, sys

PSQL = "/opt/homebrew/opt/postgresql@17/bin/psql"
DB = "postgresql://psn:psn@localhost:5432/personality"

db = sqlite3.connect(sys.argv[1] if len(sys.argv) > 1 else "/Users/chi/.local/share/personality/main.db")
db.row_factory = sqlite3.Row

# Ensure carts exist
for cart in db.execute("SELECT * FROM carts WHERE id IN (1, 32)").fetchall():
    tag = cart["tag"].replace("'", "''")
    name = (cart["name"] or "").replace("'", "''")
    ctype = (cart["type"] or "").replace("'", "''")
    sql = f"INSERT INTO carts (id, tag, name, type) VALUES ({cart['id']}, '{tag}', '{name}', '{ctype}') ON CONFLICT (id) DO NOTHING;"
    subprocess.run([PSQL, DB, "-c", sql], capture_output=True)

# Get existing PG IDs
r = subprocess.run([PSQL, DB, "-t", "-A", "-c", "SELECT id FROM memories ORDER BY id;"], capture_output=True, text=True)
pg_ids = set(int(x) for x in r.stdout.strip().split("\n") if x)

rows = db.execute("SELECT * FROM memories WHERE cart_id IN (1, 32) ORDER BY id").fetchall()
inserted = 0
updated = 0
for m in rows:
    content = m["content"].replace("'", "''")
    subject = (m["subject"] or "").replace("'", "''")
    metadata = (m["metadata"] or "{}").replace("'", "''")
    classification = m["classification"] or "standard"
    created = m["created_at"]
    updated_at = m["updated_at"] or created

    if m["id"] in pg_ids:
        sql = f"UPDATE memories SET subject='{subject}', content='{content}', metadata='{metadata}'::jsonb, classification='{classification}', updated_at='{updated_at}' WHERE id={m['id']};"
        updated += 1
    else:
        sql = f"INSERT INTO memories (id, cart_id, subject, content, metadata, classification, created_at, updated_at) VALUES ({m['id']}, {m['cart_id']}, '{subject}', '{content}', '{metadata}'::jsonb, '{classification}', '{created}', '{updated_at}');"
        inserted += 1

    subprocess.run([PSQL, DB, "-c", sql], capture_output=True)

# Reset sequence
subprocess.run([PSQL, DB, "-c", "SELECT setval('memories_id_seq', (SELECT MAX(id) FROM memories));"], capture_output=True)

print(f"  Inserted: {inserted}, Updated: {updated}, Total: {inserted + updated}")
PY
    echo "Done"
    ;;

  sync-remote|sr)
    echo "Syncing Fuji PG → Junkpile PG..."

    # Dump fuji PG data
    $FUJI_PSQL "$FUJI_PG" -c "COPY (SELECT * FROM carts) TO STDOUT WITH CSV HEADER" > /tmp/psn-carts.csv 2>/dev/null
    $FUJI_PSQL "$FUJI_PG" -c "COPY (SELECT id, cart_id, subject, content, metadata, classification, created_at, updated_at FROM memories ORDER BY id) TO STDOUT WITH CSV HEADER" > /tmp/psn-memories.csv 2>/dev/null

    # Upload and restore on junkpile
    scp -q /tmp/psn-carts.csv /tmp/psn-memories.csv j:/tmp/

    ssh -T j "PGPASSWORD=$JUNKPILE_PG_PASS psql -U psn -h localhost -d personality << 'SQL'
TRUNCATE memories, carts CASCADE;
\copy carts FROM '/tmp/psn-carts.csv' WITH CSV HEADER;
\copy memories(id, cart_id, subject, content, metadata, classification, created_at, updated_at) FROM '/tmp/psn-memories.csv' WITH CSV HEADER;
SELECT setval('memories_id_seq', (SELECT MAX(id) FROM memories));
SQL" 2>&1

    rm -f /tmp/psn-carts.csv /tmp/psn-memories.csv
    echo "Done"
    ;;

  tag-core|tc)
    echo "Tagging core memories in all stores..."

    # Tag in SQLite
    sqlite3 "$SQLITE_DB" "
    UPDATE memories SET classification = 'core'
    WHERE cart_id = 1 AND classification != 'core' AND (
      subject LIKE 'self.identity%' OR subject LIKE 'self.trait%'
      OR subject LIKE 'self.protocol%' OR subject LIKE 'self.speech%'
      OR subject LIKE 'self.capability%' OR subject LIKE 'self.relationship%'
      OR subject LIKE 'self.quote%' OR subject LIKE 'self.logic%'
      OR subject LIKE 'self.arsenal%' OR subject LIKE 'self.loadouts%'
      OR subject LIKE 'self.humor%' OR subject LIKE 'self.protocols%'
      OR subject LIKE 'self.source%' OR subject LIKE 'pilot.pack%'
      OR subject = 'user.philosophy'
    );"
    echo "  SQLite: $(fuji_sqlite_core) core memories"

    # Sync core tags to PG
    bash "$0" sync-local
    bash "$0" sync-remote
    echo "Done"
    ;;

  help|h|*)
    echo "memory-sync.sh — Synchronize PSN memories across all stores"
    echo ""
    echo "Commands:"
    echo "  status       Show sync status (counts, max IDs, core tags)"
    echo "  sync         Full sync: SQLite → Fuji PG → Junkpile PG"
    echo "  sync-local   Sync Fuji SQLite → Fuji PG only"
    echo "  sync-remote  Sync Fuji PG → Junkpile PG only"
    echo "  tag-core     Tag core memories in all stores"
    ;;
esac
