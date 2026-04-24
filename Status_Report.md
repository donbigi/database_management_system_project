# DBMS Project Status Report
**Project:** Optimizing RocksDB via Active Learning (CAMAL Implementation)

## a) Problem Statement
The configuration of Log-Structured Merge (LSM) trees (such as those used in RocksDB) typically relies on static heuristics and manual tuning of numerous interrelated parameters (e.g., size ratio, memory allocations, bloom filter bits). A static, one-size-fits-all tuned configuration often fails to adapt to diverse or dynamic workloads, resulting in sub-optimal system performance, high read/write I/O amplification, and latency spikes. The core problem is finding an automated, efficient method to dynamically tune these parameters to specific workloads without succumbing to computationally prohibitive exhaustive grid searches or requiring massive historical training datasets.

## b) Basic Goal of the Project
The primary goal of this project to be achieved by the end of the semester is to design, implement, and benchmark an automated instance-optimized tuning system for RocksDB. Specifically, we are implementing the CAMAL (Optimizing LSM-trees via Active Learning) framework. Through decoupled active learning and polynomial regression models, we aim to dynamically tune RocksDB configuration parameters to achieve superior end-to-end lookup and write latency compared to static industry-standard configurations across long-haul workloads.

## c) Assumptions and Methods (and Differences)
*   **Assumptions:** We assume that mathematically derived, complexity-based I/O cost models provide an excellent starting neighborhood for parameter tuning but ultimately fail to capture real-world system complexities (like cache interactions or disk bottlenecks). Furthermore, we assume that interdependent parameters like the Size Ratio ($T$) and Write Buffer memory allocation ($M_b$) can be safely "decoupled" and tuned iteratively without losing the global optimal solution.
*   **Methods:** We utilize a Decoupled Active Learning approach. A Python script runs small workload samples to train a lightweight Polynomial Linear Regression model, isolating and discovering the optimal parameters one at a time.
*   **Differences from Existing Work:** Unlike exhaustive grid searches or complex Deep Reinforcement Learning models that require millions of operations to train, our hybrid approach anchors its starting point using theoretical complexity models and then actively samples sparse configurations. This effectively bypasses the traditional "cold start" problem and dramatically reduces tuning overhead.

## d) Software, Tools, and Data Sets
*   **Core Software:** RocksDB (v8.10.0), Python 3 (Scikit-learn, Numpy), Bash for orchestration.
*   **Infrastructure:** Infrastructure-as-Code via Terraform, deploying reproducible Google Cloud Platform (GCP) instances (`n2-standard-8`, Ubuntu 22.04 LTS) to guarantee hardware consistency across benchmarks.
*   **Data Sets:** 5,000,000 synthetically generated Key-Value records (1 KB values, 16-byte keys) initialized via `db_bench` (`fillseq`). Benchmarking simulates standard DB scenarios (e.g., balanced 50% reads / 50% updates).

## e) Detailed Plan of Experimental Studies
In accordance with the experimental studies mentioned in our core paper, we plan the following pipeline:
1.  **Baseline Emulation:** Benchmark the default, statically configured RocksDB instance under a standard `readrandomwriterandom` workload to establish precise baselines for throughput and amplification.
2.  **Training Overhead Profiling:** Measure the exact temporal and I/O footprint required for the Active Learning module to converge on its optimal parameters using short iterative samples (20-second bursts).
3.  **Sustained Execution Comparison:** Run longer horizon evaluations (multi-hour workloads) on both the static baseline and the AL-tuned configuration to capture long-term performance gains as the LSM-tree fully shifts structures.
4.  **Dynamic Workload Stress Test:** Introduce shifting workloads mid-execution (e.g., scaling from Write-Heavy to Read-Heavy) to measure the active learning model's capability to extrapolate parameter adjustments without undergoing full retraining.

## f) Current Status and Partial Results
**Status:** We have successfully scripted and provisioned the reproducible GCP evaluation environment via Terraform. The decoupled active tuning pipeline (`active_tuner.py`) utilizing `sklearn`, as well as its corresponding subset bash wrappers mapping back to the theoretical models, are functionally complete and injected gracefully into the benchmark orchestration via Terraform's GCP metadata bindings.

**Partial Results & Analysis:** We recently completed a brief 5-minute benchmark comparing a static baseline to the AL optimizer under a "Balanced" workload.
*   *Baseline:* 49,658 Ops/sec | 20.14 µs avg latency | 10.7 MB Compaction Written
*   *Active Tuning:* 35,922 Ops/sec | 27.84 µs avg latency | 21.4 MB Compaction Written

*Surprising Results:* Confounding initial expectations, the Active Learning model performed roughly 25% *worse* than the static baseline in this first benchmark, writing exactly double the background compaction data. Upon analysis, we identified the cause as the **Training Horizon Tradeoff**. Because our evaluation was extremely short (5 minutes), the active learner aggressively attempted to modify the DB structure (hence forcing 21.4 MB of compaction) for long-term read efficiency. However, the benchmark concluded before the system could reap the latent benefits, leaving only the compaction overhead. This finding practically confirms the underlying premise from the CAMAL paper: Active Learning configuration parameters require robust, continuous long-haul workloads to amortize their initial structural conversion costs.

## g) Brief Plan for the Remaining Month
*   **Week 1 (Current):** Refine the AL sampling scripts (expand the search space step logic). Scale our automated `run_experiment` pipeline to execute 2 to 3-hour workloads rather than 5-minute subsets to properly facilitate latency amortization.
*   **Week 2:** Collect comprehensive data across Write-Heavy, Read-Heavy, and Balanced sustained workloads. Graph the performance curves separating the "tuning overhead" phase from the "steady-state" execution phase.
*   **Week 3:** Advance to the "Dynamic Adaptation" experiments. Modify the pipeline to seamlessly change the read/write query mix natively during execution, assessing whether the model can extrapolate configuration adjustments on the fly without halting.
*   **Week 4:** Summarize all empirical validations and visualizations comparing Write Amplification and Latency against baseline instances. Prepare the final semester report and compile the concluding presentation format.
