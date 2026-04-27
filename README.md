# Autonomous RocksDB Tuning Pipeline
**Comparing Reinforcement Learning, Active Learning, and Static Baselines**

This repository contains the benchmarking orchestration suite for evaluating autonomous machine learning tuning algorithms directly against a physical RocksDB Log-Structured Merge-Tree (LSM-Tree). 

## Project Architecture
*   `scripts/baseline/`: Core static load-testing configurations representing human-DBAs.
*   `scripts/active_learning/`: CAMAL-inspired Polynomial Regression tuner (`active_tuner.py`).
*   `scripts/rl/`: RusKey-inspired Continuous Actor-Critic agent (`rl_tuner.py`).
*   `scripts/master_benchmark.sh`: The master orchestration wrapper that iteratively executes all tuning methodologies across 3 variance loops.
*   `scripts/generate_plots.py`: Generates comparative Seaborn visualizations from the execution logs.

---

## Execution Guide 
You have two options to run this testing framework: natively on your local machine (Linux/macOS), or deployed into an isolated Google Cloud Platform (GCP) instance via Terraform.

### Option 1: Running Locally (Standalone Execution)
You can directly execute the machine learning scripts on your local machine. This is recommended if you wish to bypass GCP infrastructure costs.

**Prerequisites:**
1.  A compiled working version of RocksDB. Specifically, the `db_bench` testing macro must be executable.
2.  Python 3 installed with the required Data Science rendering dependencies:
    ```bash
    pip3 install torch scikit-learn pandas seaborn matplotlib numpy
    ```

**How to Run the Suite:**
1. Navigate to the root directory where the `scripts/` folder is located.
2. Ensure your execution scripts have proper permissions: 
   ```bash
   chmod +x scripts/*.sh scripts/**/*.sh
   ```
3. Execute the master benchmarking sequencer. Because compiling 50GB of raw database writes and orchestrating 27 distinct benchmarking loops takes multiple hours, running it in the background is highly recommended:
   ```bash
   nohup sudo ./scripts/master_benchmark.sh > /dev/null 2>&1 &
   ```
4. Follow the live execution trail:
   ```bash
   tail -f results/master_execution.log
   ```

### Option 2: Cloud Deployment via Terraform (Full Scale-Testing)
If testing massive database boundaries (e.g., 50GB+ payloads) to force physical SSD Write-Amplification mapping without destroying your local NVMe drive, use the Terraform configuration to deploy an isolated `n2-standard-8` instance into GCP.

**Prerequisites:**
*   HashiCorp Terraform installed locally.
*   A valid Google Cloud project with billing enabled.
*   GCP credential JSON authenticated locally (`gcloud auth application-default login`).

**To Deploy:**
1. Navigate to this directory (where `main.tf` is located).
2. Initialize the terraform state:
   ```bash
   terraform init
   ```
3. Deploy the GCP VM. Your local `startup.sh` script will automatically mount your disk, compile the RocksDB C++ libraries, and set up all Python virtual dependencies inside `/opt/rocksdb-workspace` automatically.
   ```bash
   terraform apply
   ```
4. SSH into the deployed `rocksdb-exp` instance and manually trigger `master_benchmark.sh` exactly like **Option 1**.

---

## Generating Visualizations
Once the master orchestrator completes, it will populate the `result/` folder with raw empirical latency logs.

To generate the high-resolution mathematical bar charts spanning Throughput, Tail Latency, and Compaction Overheads:
```bash
python3 scripts/generate_plots.py
```
This script aggressively parses the logs to extract all absolute P99 Tail Latencies, Ops/sec throughput ceilings, and Compaction byte data across the Baseline, AL, and RL pipelines, outputting them directly as `.png` files suitable for professional or academic conference reporting.
