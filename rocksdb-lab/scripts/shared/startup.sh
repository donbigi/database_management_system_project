#!/bin/bash
set -x

# Prepare workspace for scripts and RocksDB
WORKSPACE_DIR="/opt/rocksdb-workspace"
mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"

echo "Fetching scripts from GCP Metadata..."

# Function to fetch metadata robustly
get_metadata() {
  local key=$1
  local output=$2
  curl -s -f -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/${key}" > "${output}"
}

# Fetch shared scripts
mkdir -p shared
get_metadata "setup_rocksdb" "shared/setup_rocksdb.sh"
get_metadata "load_dataset" "shared/load_dataset.sh"
get_metadata "run_workload" "shared/run_workload.sh"
get_metadata "collect_metrics" "shared/collect_metrics.py"

# Fetch baseline scripts
mkdir -p baseline
get_metadata "apply_config" "baseline/apply_config.py"
get_metadata "run_experiment" "baseline/run_experiment.sh"

# Fetch active learning scripts
mkdir -p active_learning
get_metadata "al_tuner" "active_learning/active_tuner.py"
get_metadata "al_run_iter" "active_learning/run_al_iteration.sh"
get_metadata "al_run_experiment" "active_learning/run_experiment.sh"

# Fetch RL scripts
mkdir -p rl
get_metadata "rl_tuner" "rl/rl_tuner.py"
get_metadata "rl_run_iter" "rl/run_rl_iteration.sh"
get_metadata "rl_run_experiment" "rl/run_experiment.sh"

# Fetch master orchestrator
get_metadata "master_benchmark" "master_benchmark.sh"

# Make them executable
chmod +x shared/*.sh shared/*.py baseline/*.sh baseline/*.py active_learning/*.sh active_learning/*.py rl/*.sh rl/*.py master_benchmark.sh

# Execute the main setup which builds RocksDB (public repo clone, no auth needed)
echo "Running RocksDB setup..."
./shared/setup_rocksdb.sh

# The master experiment script is intentionally NOT run on startup to save costs.
# To run benchmarks manually, SSH into the instance and run:
#   cd /opt/rocksdb-workspace
#   nohup sudo ./scripts/master_benchmark.sh > /dev/null 2>&1 &

# check logs
# tail -f /opt/rocksdb-workspace/results/master_execution.log

# If desired, upload results to a bucket, or shut down the machine.
# gsutil cp /opt/rocksdb-workspace/results/final_results.csv gs://YOUR_BUCKET/
# shutdown -h now
