#!/bin/bash
set -e

echo "========================================="
echo "  RocksDB Experiment Orchestrator"
echo "========================================="

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 [workload_type] [runs]"
    echo "  workload_type : read_heavy | write_heavy | balanced | dynamic (default: balanced)"
    echo "  runs          : Integer number of times to run for variance (default: 3)"
    exit 1
fi

WORKLOAD=${1:-balanced}
RUNS=${2:-3}

WORKSPACE_DIR="/opt/rocksdb-workspace"
DB_DIR="/mnt/data/rocksdb"
SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
RESULTS_DIR="${WORKSPACE_DIR}/results"

mkdir -p "$RESULTS_DIR"

echo "Executing $RUNS runs of $WORKLOAD workload..."

for i in $(seq 1 $RUNS); do
    echo "----------------------------------------"
    echo " Starting Run $i / $RUNS"
    echo "----------------------------------------"
    
    # 1. Generate Config
    echo "[1/4] Generating Configuration..."
    python3 "$SCRIPTS_DIR/apply_config.py" --output "$WORKSPACE_DIR/OPTIONS.ini" \
        --memtable_size 64 \
        --level_base_size 256 \
        --level_multiplier 10 \
        --compaction_trigger 4 \
        --stats
        
    OPTIONS_FILE="$WORKSPACE_DIR/OPTIONS.ini"

    # 2. Reset and Load Dataset
    echo "[2/4] Loading fresh dataset..."
    bash "$SCRIPTS_DIR/../shared/load_dataset.sh"

    # Add Warmup phase
    echo "[Warmup] Running 30 seconds warmup..."
    python_warmup="$SCRIPTS_DIR/../shared/run_workload.sh"
    bash "$python_warmup" "balanced" 30 > "$WORKSPACE_DIR/warmup.log" 2>&1 || echo "[Warmup] WARNING: Warmup script failed! Check warmup.log for details. Continuing baseline..."

    # 3. Run Workload with Config
    echo "[3/4] Running primary workload ($WORKLOAD) for 5 minutes..."
    WORKLOAD_OUT="$RESULTS_DIR/run_${i}_${WORKLOAD}.txt"
    cd "$WORKSPACE_DIR/rocksdb"
    
    # Note: Using db_bench directly here to pass config via options_file safely, 
    # as run_workload.sh doesn't currently accept custom args without modifying it.
    ./db_bench --db="$DB_DIR" --use_existing_db=1 --num=5000000 \
      --benchmarks=readrandomwriterandom \
      --duration=300 \
      --statistics=1 \
      --histogram=1 \
      --options_file="$OPTIONS_FILE" \
      > "$WORKLOAD_OUT"
      
    # 4. Collect Metrics
    echo "[4/4] Collecting Metrics..."
    python3 "$SCRIPTS_DIR/../shared/collect_metrics.py" \
        --benchmark_out "$WORKLOAD_OUT" \
        --rocksdb_log "$DB_DIR/LOG" \
        --output "$RESULTS_DIR/final_results.csv" \
        --run_id "${WORKLOAD}_run_${i}"
        
    echo "Run $i Completed."
done

echo "========================================="
echo " All experiments finished."
echo " Final results stored in $RESULTS_DIR/final_results.csv"
echo "========================================="
