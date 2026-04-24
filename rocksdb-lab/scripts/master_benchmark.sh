#!/bin/bash
set -e

echo "=================================================="
echo "    OVERNIGHT MASTER BENCHMARK ORCHESTRATOR"
echo "=================================================="
echo "This script will sequentially run all workloads across"
echo "Baseline, Active Learning, and Reinforcement Learning."
echo "=================================================="

# Number of runs per combination for statistical variance
RUNS=3

# The workloads to test
WORKLOADS=("write_heavy" "balanced" "read_heavy")

# The evaluation pipelines
PIPELINES=("baseline" "active_learning" "rl")

WORKSPACE_DIR="/opt/rocksdb-workspace"
SCRIPTS_DIR="${WORKSPACE_DIR}"
MASTER_LOG="${WORKSPACE_DIR}/results/master_execution.log"

mkdir -p "${WORKSPACE_DIR}/results"

echo "Master benchmark started at: $(date)" | tee -a "$MASTER_LOG"

for pipeline in "${PIPELINES[@]}"; do
    echo "==================================================" | tee -a "$MASTER_LOG"
    echo "  STARTING PIPELINE: $pipeline" | tee -a "$MASTER_LOG"
    echo "==================================================" | tee -a "$MASTER_LOG"
    
    for workload in "${WORKLOADS[@]}"; do
        echo "--------------------------------------------------" | tee -a "$MASTER_LOG"
        echo "  [$(date)] -> Executing ${pipeline} / ${workload}" | tee -a "$MASTER_LOG"
        echo "--------------------------------------------------" | tee -a "$MASTER_LOG"
        
        # Execute the specific pipeline's run_experiment script
        run_script="${SCRIPTS_DIR}/${pipeline}/run_experiment.sh"
        
        if [ -f "$run_script" ]; then
            # We redirect standard output and error to our master log, but keep it visible on console if attached
            bash "$run_script" "$workload" "$RUNS" 2>&1 | tee -a "$MASTER_LOG"
        else
            echo "ERROR: Could not find $run_script" | tee -a "$MASTER_LOG"
        fi
        
        echo "  [$(date)] -> Finished ${pipeline} / ${workload}" | tee -a "$MASTER_LOG"
        echo "" | tee -a "$MASTER_LOG"
    done
done

echo "==================================================" | tee -a "$MASTER_LOG"
echo "ALL OVERNIGHT BENCHMARKS COMPLETED AT: $(date)" | tee -a "$MASTER_LOG"
echo "Results can be found in ${WORKSPACE_DIR}/results/" | tee -a "$MASTER_LOG"
echo "==================================================" | tee -a "$MASTER_LOG"
