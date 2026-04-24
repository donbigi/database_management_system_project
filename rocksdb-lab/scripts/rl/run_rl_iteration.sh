#!/bin/bash
set -e

WORKLOAD=${1:-balanced}
OPTIONS_FILE=$2

WORKSPACE_DIR="/opt/rocksdb-workspace"
DB_DIR="/mnt/data/rocksdb"

WORKLOAD_OUT="/tmp/rl_temp_benchmark.txt"
cd "$WORKSPACE_DIR/rocksdb"

# Quick measurement for RL (20 seconds) - reusing dataset DB to save time in loop
./db_bench --db="$DB_DIR" --use_existing_db=1 --num=50000000 \
  --benchmarks=readrandomwriterandom \
  --duration=20 \
  --statistics=1 \
  --options_file="$OPTIONS_FILE" \
  > "$WORKLOAD_OUT" 2>/dev/null || true

# Extract the avg_latency_micros from the output:
latency=$(grep "readrandomwriterandom" "$WORKLOAD_OUT" | awk '{print $3}')

if [ -z "$latency" ]; then
    echo "0"
else
    echo "$latency"
fi
