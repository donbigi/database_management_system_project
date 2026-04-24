#!/bin/bash
set -e

echo "========================================="
echo "  RocksDB RL (RusKey Emulation) Orchestrator"
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

# Install required python packages if not already present
pip3 install torch numpy >/dev/null 2>&1 || true

echo "----------------------------------------"
echo " Phase 1: RL Tuning (DDPG) "
echo "----------------------------------------"
OPTIONS_FILE="$WORKSPACE_DIR/OPTIONS_RL.ini"
python3 "$SCRIPTS_DIR/rl_tuner.py" "$OPTIONS_FILE" > "$RESULTS_DIR/rl_tuning_progress.log"
cat "$RESULTS_DIR/rl_tuning_progress.log"

echo "Executing $RUNS runs of $WORKLOAD workload with RL tuned config..."

for i in $(seq 1 $RUNS); do
    echo "----------------------------------------"
    echo " Starting Run $i / $RUNS"
    echo "----------------------------------------"
    
    echo "[1/3] Loading fresh dataset..."
    bash "$SCRIPTS_DIR/../shared/load_dataset.sh"

    echo "[Warmup] Running 30 seconds warmup..."
    python_warmup="$SCRIPTS_DIR/../shared/run_workload.sh"
    bash "$python_warmup" "balanced" 30 > "$WORKSPACE_DIR/warmup_rl.log" 2>&1 || echo "[Warmup] WARNING: Warmup script failed!"

    echo "[2/3] Running primary RL benchmark ($WORKLOAD) for 5 minutes..."
    WORKLOAD_OUT="$RESULTS_DIR/run_${i}_${WORKLOAD}_rl.txt"
    cd "$WORKSPACE_DIR/rocksdb"
    
    ./db_bench --db="$DB_DIR" --use_existing_db=1 --num=50000000 \
      --benchmarks=readrandomwriterandom \
      --duration=300 \
      --statistics=1 \
      --histogram=1 \
      --options_file="$OPTIONS_FILE" \
      > "$WORKLOAD_OUT"
      
    echo "[3/3] Collecting Metrics..."
    python3 "$SCRIPTS_DIR/../shared/collect_metrics.py" \
        --benchmark_out "$WORKLOAD_OUT" \
        --rocksdb_log "$DB_DIR/LOG" \
        --output "$RESULTS_DIR/final_results_rl.csv" \
        --run_id "${WORKLOAD}_rl_run_${i}"
        
    echo "Run $i Completed."
done

echo "========================================="
echo " All experiments finished."
echo " Final results stored in $RESULTS_DIR/final_results_rl.csv"
echo "========================================="
