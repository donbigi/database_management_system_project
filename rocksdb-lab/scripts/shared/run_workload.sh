#!/bin/bash
set -e
set -x

echo "========================================="
echo "  RocksDB Workload Runner Script"
echo "========================================="

WORKSPACE_DIR="/opt/rocksdb-workspace"
DB_DIR="/mnt/data/rocksdb"
ROCKSDB_PATH="$WORKSPACE_DIR/rocksdb"
RESULTS_DIR="${WORKSPACE_DIR}/results"

mkdir -p "$RESULTS_DIR"

if [ -z "$1" ]; then
  echo "Usage: $0 <workload_type> [duration_seconds]"
  echo "Workload types: read_heavy, write_heavy, balanced, dynamic"
  exit 1
fi

WORKLOAD_TYPE=$1
DURATION=${2:-600} # Default 10 minutes

RECORD_COUNT=50000000
VALUE_SIZE=1024

cd "$ROCKSDB_PATH"

# Base db_bench arguments
BASE_ARGS="--db=$DB_DIR --use_existing_db=1 --num=$RECORD_COUNT --value_size=$VALUE_SIZE --duration=$DURATION --statistics=1 --histogram=1 --bloom_bits=10"

echo "Running workload: $WORKLOAD_TYPE for $DURATION seconds..."

case $WORKLOAD_TYPE in
  read_heavy)
    # 90% read, 10% update natively using mixgraph or readrandomwriterandom
    ./db_bench $BASE_ARGS \
      --benchmarks=readrandomwriterandom \
      --readwritepercent=90 \
      > "$RESULTS_DIR/${WORKLOAD_TYPE}_results.txt"
    ;;
  
  write_heavy)
    # 10% read, 90% update
    ./db_bench $BASE_ARGS \
      --benchmarks=readrandomwriterandom \
      --readwritepercent=10 \
      > "$RESULTS_DIR/${WORKLOAD_TYPE}_results.txt"
    ;;

  balanced)
    # 50% read, 50% update
    ./db_bench $BASE_ARGS \
      --benchmarks=readrandomwriterandom \
      --readwritepercent=50 \
      > "$RESULTS_DIR/${WORKLOAD_TYPE}_results.txt"
    ;;

  dynamic)
    # Phase 1: Write Heavy (10% read)
    echo "Running Phase 1: Write Heavy..."
    ./db_bench $BASE_ARGS --duration=$((DURATION/3)) --benchmarks=readrandomwriterandom --readwritepercent=10 > "$RESULTS_DIR/dynamic_phase1.txt"
    
    # Phase 2: Balanced (50% read)
    echo "Running Phase 2: Balanced..."
    ./db_bench $BASE_ARGS --duration=$((DURATION/3)) --benchmarks=readrandomwriterandom --readwritepercent=50 > "$RESULTS_DIR/dynamic_phase2.txt"

    # Phase 3: Read Heavy (90% read)
    echo "Running Phase 3: Read Heavy..."
    ./db_bench $BASE_ARGS --duration=$((DURATION/3)) --benchmarks=readrandomwriterandom --readwritepercent=90 > "$RESULTS_DIR/dynamic_phase3.txt"
    ;;

  *)
    echo "Unknown workload type: $WORKLOAD_TYPE"
    exit 1
    ;;
esac

echo "Workload complete. Results saved in $RESULTS_DIR/"
