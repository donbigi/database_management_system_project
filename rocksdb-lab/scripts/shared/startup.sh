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

# Make them executable
chmod +x shared/*.sh shared/*.py baseline/*.sh baseline/*.py

# Execute the main setup which builds RocksDB (public repo clone, no auth needed)
echo "Running RocksDB setup..."
./shared/setup_rocksdb.sh

# The master experiment script is intentionally NOT run on startup to save costs.
# To run benchmarks manually, SSH into the instance and run:
#   cd /opt/rocksdb-workspace
#   sudo ./baseline/run_experiment.sh balanced 3

# If desired, upload results to a bucket, or shut down the machine.
# gsutil cp /opt/rocksdb-workspace/results/final_results.csv gs://YOUR_BUCKET/
# shutdown -h now
