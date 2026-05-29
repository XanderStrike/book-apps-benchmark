#!/usr/bin/env bash
# Run a MicroOPDS benchmark for a given book count
# Usage: ./run_microopds_benchmark.sh 10K|50K|100K|150K
set -euo pipefail

BOOKS="${1:?Usage: $0 10K|50K|100K|150K}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BOOK_DIR="$ROOT/books/books_$BOOKS"

if [[ ! -d "$BOOK_DIR" ]]; then
  echo "Book directory not found: $BOOK_DIR"
  echo "Generate it first: cd scripts && python3 generate_books.py ${BOOKS/K000}"
  exit 1
fi

echo "=== MicroOPDS Benchmark: $BOOKS books ==="

# Stop and remove previous container
podman rm -f microopds_loadtest 2>/dev/null || true

# Start container with defer-scan and no-watch, mounting only the target book folder
podman run -d \
  --name microopds_loadtest \
  -p 6070:8080 \
  -v "$BOOK_DIR:/books:ro" \
  -e TZ=Etc/UTC \
  xanderstrike/microopds \
  microopds -dir /books -port 8080 -defer-scan -no-watch

sleep 2

# Verify container is running and in defer-scan mode
podman logs microopds_loadtest 2>&1 | tail -2

# Start monitor in background (higher idle threshold for podman's CPU reporting)
python3 "$ROOT/scripts/monitor.py" microopds_loadtest \
  --label "MicroOPDS" \
  --books "$BOOKS" \
  --interval 2 \
  --idle-threshold 5 \
  --idle-duration 30 \
  --idle-window 60 &
MONITOR_PID=$!
echo "Monitor PID: $MONITOR_PID"
sleep 3

# Trigger the scan
echo "Triggering scan..."
SCAN_RESULT=$(curl -s -X POST http://localhost:6070/api/scan)
echo "Scan result: $SCAN_RESULT"

# Wait for monitor to finish
echo "Waiting for monitor to complete..."
wait $MONITOR_PID

echo ""
echo "=== Benchmark complete: $BOOKS ==="

# Clean up
podman rm -f microopds_loadtest 2>/dev/null || true
