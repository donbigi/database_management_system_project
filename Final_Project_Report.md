# Autonomous Machine Learning Optimization of RocksDB LSM-Trees
**A Comparative Analysis of Reinforcement Learning, Active Learning, and Static Baselines**

## 1. Introduction to the Problem
Modern cloud-based database systems face highly volatile, unpredictable workloads where data ingestion rates and query patterns shift dynamically. Underneath most modern distributed databases (such as Cassandra, Kafka, or CockroachDB) lies an embedded storage engine built around the **Log-Structured Merge-Tree (LSM-Tree)**, with **RocksDB** being the industry standard.

LSM-Trees absorb incoming data exceptionally fast by batching writes into memory buffers and flushing them to disk as immutable sorted string tables (SSTables). However, this architecture is strictly bound by the **RUM (Read, Update, Memory) Conjecture**. You cannot infinitely optimize for update ingestion without trading off read performance or memory footprints. 

When a static DBMS is suddenly flooded with a "Write-Heavy" workload, it rapidly triggers cascaded internal compactions to merge levels. If the database engine reaches its I/O limit, it incurs massive **Write Amplification** and suffers catastrophic **Write Stalls**, completely halting operations. 

In traditional architectures, human Database Administrators (DBAs) manually tune static parameters—like the LSM-Tree Size Ratio ($T$) or Write Buffer sizes—to prevent these stalls. This heavily manual process is insufficient for modern elastic environments. This project explores the implementation of Autonomous Database Tuning, validating two recent research milestones: **CAMAL** (Cost-Aware Machine Learning) and **RusKey** (Reinforcement Learning-based tuning), to prove that dynamic Artificial Intelligence significantly outperforms human-configured static baselines.

---

## 2. Methodology
To validate the research claims within the constraints of a semester timeframe, we opted against modifying the RocksDB C++ kernel (a "White-Box" approach) and instead built a **"Black-Box Orchestration Pipeline"**. The engine was deployed onto Google Cloud Platform (GCP) architecture using Terraform (`n2-standard-8` instance, 32GB RAM). 

The pipeline tested three distinct tuning methodologies against a 50 Million record (50 GB) test database:

### A. The Baseline (Static Control)
The Baseline mirrors legacy, static configurations. The Size Ratio was hardcoded to $T = 10$ and buffers to $64$ MB. Regardless of workload shifts or write friction, the database made no attempt to analyze its internal bottlenecks or adapt its shape.

### B. Active Learning (CAMAL Emulation)
Based on the CAMAL framework, we designed an **Episodic Active Tuner** (`active_tuner.py`). 
*   **Decoupled Learning:** It utilizes a Polynomial Regression model (`sklearn`) to build a cost-function landscape mapping configuration parameters against foreground query latency. 
*   **Epsilon-Greedy Iteration:** It periodically injects random parameter shapes to explore the space, capturing performance metrics. It refits its regression curve mid-benchmark, actively optimizing for the lowest operational cost without relying on neural networks.

### C. Reinforcement Learning (RusKey Emulation)
We implemented a continuous **Deep Deterministic Policy Gradient (DDPG)** agent (`rl_tuner.py`) utilizing PyTorch. 
*   **Actor-Critic Network:** The *Actor* network maps current database contention states into granular, continuous actions (e.g., fractional adjustments to $T$ or buffer caps). The *Critic* evaluates the utility of those actions.
*   **Reward Mapping ($r_t$):** The agent was mathematically incentivized heavily against Write Stalls by mapping the foreground latency directly to a negative penalty (`Reward = -Latency`).
*   **Experience Replay Buffer:** The agent continually sampled previous historical shifts to avoid catastrophic forgetting during dynamic workloads.

---

## 3. Experiments
An automated Master Benchmark Orchestrator was designed to evaluate the tuning models under heavy duress. The orchestrator iteratively fired up RocksDB and piped extreme operations exclusively through `db_bench` over a 50 GB pre-loaded key-space. 

We forced the 32GB GCP instance to exhaust its Linux Page Cache by scaling the data to 50GB. This guaranteed that RocksDB had to write accurately to the SSD layers rather than spoofing metrics through background RAM caching. 

Each tuning model (Baseline, AL, RL) faced three distinct workloads. Each test evaluated thousands of ops over 5 minute bursts for 3 variance runs:
1.  **Write-Heavy Workload:** 10% Reads / 90% Updates. (Designed to violently trigger Write Stalls).
2.  **Balanced Workload:** 50% Reads / 50% Updates.
3.  **Read-Heavy Workload:** 90% Reads / 10% Updates. (Designed to test Read Amplification).

---

## 4. Results & Discussion

### 4.1 Write-Heavy Performance: The Machine Learning Triumph
The most prominent conclusion of our experiments validated the core thesis of both CAMAL and RusKey: static configurations completely shatter under write-floods.

*   **Baseline Average:** ~17,070 Ops/sec
*   **Active Learning Avg:** ~25,781 Ops/sec
*   **Reinforcement Learning Avg:** ~27,600 Ops/sec *(Peak: 27,892 Ops/sec)*

**Discussion:** The DDPG Reinforcement Learning agent outperformed the static Baseline by over **60%**, and it discovered its optimizations with more stability and speed than the Active Learning regression pipeline. RL gracefully adjusted the Size Ratio ($T$) to digest incoming data faster. By avoiding stalled states entirely, it maximized structural efficiency. 

### 4.2 The RUM Conjecture Penalty (Read-Heavy Impact)
While ML was wildly successful during write floods, it incurred a strict penalty during Read queries:
*   **Read-Heavy Baseline Avg:** ~21,700 Ops/sec
*   **Read-Heavy AL Avg:** ~19,250 Ops/sec
*   **Read-Heavy RL Avg:** ~18,850 Ops/sec

**Discussion:** This data perfectly illustrates the inescapable LSM-Tree architecture tradeoffs. Because the RL and AL algorithms deformed the tree to absorb writes intelligently (creating deeper or more fragmented layers), they inherently injected **Read Amplification**. To execute a `GET` command, the engine had to scavenge through more fragments, penalizing throughput. Unlike the RusKey paper which leveraged "White-Box" zero-copy pointers, our Black-Box orchestration cleared the Block Caches between iterations, exaggerating this read latency penalty compared to the original authors' findings.

### 4.3 Conclusion
This experiment overwhelmingly validates the hypothesis that Autonomous Database Tuning is fundamentally necessary for modern cloud infrastructure. 
1.  **Use Reinforcement Learning (DDPG/RusKey)** for aggressive ingestion engines (IoT queues, log streams) as continuous exploration stabilizes massive write variations.
2.  **Use Active Learning (CAMAL)** as a safer alternative when infrastructure lacks the resources to run real-time neural network tensor math. 
3.  **Use Static Configurations (Baseline)** strictly for read-heavy legacy silos where stable Read Amplification is mathematically preferred to ingestion agility.
