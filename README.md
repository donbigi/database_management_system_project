# Reinforcement Learning vs Active Learning Tuning for LSM Tree Optimization under OLTP Workloads

---

## 1. Overview

This project investigates whether **machine learning–driven adaptive tuning** can improve the performance of Log-Structured Merge (LSM) tree storage engines under dynamic OLTP workloads, compared to traditional static configurations.

Specifically, we implement and compare two automated tuning paradigms:

* Reinforcement Learning (RL)–based adaptive tuning
* Active Learning–based configuration optimization

Rather than re-implementing full storage engines, this work focuses on **normalized tuner comparison** — applying both learning strategies to the same RocksDB engine and evaluating performance under identical workloads and infrastructure conditions.

---

## 2. Paper References

### Primary Paper — RL Tuning

**Learning to Optimize LSM-trees: Towards a Reinforcement Learning based Key-Value Store for Dynamic Workloads**
SIGMOD / Proceedings of the ACM on Management of Data (2023)
[https://dl.acm.org/doi/10.1145/3617333](https://dl.acm.org/doi/10.1145/3617333)

---

### Comparative Paper — Active Learning Tuning

**CAMAL: Optimizing LSM-trees via Active Learning**
SIGMOD / Proceedings of the ACM on Management of Data (2024)
[https://dl.acm.org/doi/10.1145/3677138](https://dl.acm.org/doi/10.1145/3677138)

CAMAL proposes an active learning framework that efficiently explores LSM configuration space to identify performance-optimal parameter settings.

---

## 3. Research Questions

Primary:

> How does reinforcement learning–based adaptive tuning compare to active learning–based configuration optimization for LSM-tree performance under dynamic OLTP workloads?

Secondary:

* Can lightweight RL achieve measurable gains over static tuning?
* Does active learning converge faster to optimal configurations?
* Which tuner adapts better to workload shifts?

---

## 4. Normalized System Architecture

```bash
Workload Generator → RocksDB (LSM Engine) → Metrics Collector
                           ↑
            ┌──────────────┴──────────────┐
            │                             │
     RL Tuning Agent              Active Learning Tuner
```

Both tuners:

* Observe identical metrics
* Modify identical configuration knobs
* Operate on the same storage engine

This ensures fair comparison.

---

## 5. Models Evaluated

### 5.1 Static LSM (Baseline)

* Default RocksDB configuration
* Vendor-optimized general-purpose tuning

---

### 5.3 RL-Tuned LSM

* Adaptive configuration control
* Policy learns via reward feedback
* Optimizes performance across workload phases

---

### 5.4 Active Learning–Tuned LSM (CAMAL)

* Guided configuration sampling
* Performance cost modeling
* Efficient exploration of parameter space

---

## 6. Tunable Parameters

Both tuners operate on the same configuration surface:

* Compaction policy (leveled vs tiered)
* Size ratio / level fanout
* MemTable size
* Bloom filter memory allocation

Parameter scope is intentionally constrained for semester feasibility.

---

## 7. Workload Design

Experiments simulate OLTP workloads with varying read/write distributions.

---

### Static Workloads

* Read-heavy (90% reads)
* Write-heavy (90% writes)
* Balanced (50/50)

---

### Dynamic Workloads

Workload phases shift over time:

| Phase | Read % | Write % |
| ----- | ------ | ------- |
| 1     | 10     | 90      |
| 2     | 50     | 50      |
| 3     | 90     | 10      |

Dynamic workloads evaluate tuner adaptation capability.

---

## 8. Evaluation Metrics

Performance is evaluated using:

* **Throughput** (operations/sec)
* **P99 latency**
* **Read amplification**
* **Write amplification**
* **Adaptation time**
* **Tuning convergence cost** (samples / training steps)

---

## 9. Experimental Environment

### Storage Engine

* RocksDB (user-space build)

### Learning Frameworks

* PyTorch — RL policy model
* Scikit-learn / custom — Active learning model

### Workload Runner

* Custom OLTP generator / YCSB-style driver

### Infrastructure

* Development: Cloud VM (2–8 vCPU, SSD storage)
* Final experiments: Institutional research VM

---

## 10. Project Scope Constraints

To maintain semester feasibility, the project excludes:

* Storage engine structural redesign (e.g., FLSM-tree)
* Internal compaction algorithm modifications
* Deep actor-critic RL architectures
* Distributed database deployments
* Kernel-level performance tuning

The focus remains on **tuner comparison**, not storage engine re-implementation.

---

## 11. Repository Structure

```bash
.
├── configs/              # RocksDB configuration profiles
├── workloads/            # Workload generators & traces
├── benchmark/            # Benchmark harness
├── rl_agent/             # RL policy & training loop
├── al_tuner/             # Active learning tuner
├── controller/           # Tuning interface
├── experiments/          # Experiment runners
├── results/              # Raw metrics & plots
└── report/               # Paper & analysis
```

---

## 12. Comparative Hypotheses

We hypothesize:

* RL tuning will outperform static configurations under dynamic workloads
* Active learning will converge faster to optimal static configurations
* RL will adapt more effectively to workload shifts
* Active learning will incur lower training overhead
* Static tuning may remain competitive under fixed workloads

---

## 13. Reproducibility

All experiments are:

* Scripted
* Parameterized
* Hardware-documented
* Seed-controlled (RL training)

Instructions for reproducing results will be included in `/experiments`.

---

## 14. Timeline (Semester Scope)

| Phase      | Deliverable             |
| ---------- | ----------------------- |
| Week 1     | Benchmark harness       |
| Week 2     | Static baselines        |
| Weeks 3–4  | RL tuner implementation |
| Weeks 5–6  | Active learning tuner   |
| Week 7     | Integration             |
| Week 8     | Experiments             |
| Weeks 9–10 | Analysis & report       |

---
