
# Reinforcement Learning vs Static Tuning for LSM-Tree Optimization under OLTP Workloads

## 1. Overview

This project investigates whether **lightweight reinforcement learning (RL)–based adaptive tuning** can improve the performance of Log-Structured Merge (LSM) tree storage engines under dynamic OLTP workloads, compared to traditional static configurations.

Rather than re-implementing a full storage engine, this work focuses on **adaptive control of RocksDB configuration parameters** using an RL policy trained on workload and system metrics.

---

## 2. Paper Reference

Primary research anchor:

**Learning to Optimize LSM-trees: Towards a Reinforcement Learning based Key-Value Store for Dynamic Workloads**
SIGMOD / Proceedings of the ACM on Management of Data (2023)
[https://dl.acm.org/doi/10.1145/3617333](https://dl.acm.org/doi/10.1145/3617333)

---

## 3. Research Question

> Can a minimal reinforcement learning tuner produce measurable performance improvements over default RocksDB static configurations under dynamic OLTP workloads?

---

## 4. System Architecture

```bash
Workload Generator → RocksDB (LSM Engine) → Metrics Collector
                           ↑
                     RL Tuning Agent
```

The RL agent observes system and workload metrics and dynamically adjusts LSM configuration parameters.

---

## 5. Models Evaluated

### 5.1 Static LSM (Baseline)

* Default RocksDB configuration
* Represents vendor-tuned general-purpose settings

### 5.2 Manually Tuned LSM (Baseline)

* Expert-selected static configuration
* Serves as a stronger static comparator

### 5.3 RL-Tuned LSM

* Adaptive configuration tuning
* Policy learns optimal settings across workload phases

---

## 6. Tunable Parameters

The RL agent dynamically adjusts a subset of RocksDB parameters:

* Compaction policy (leveled vs tiered)
* Size ratio / level fanout
* MemTable size
* Bloom filter allocation (optional)

Parameter scope is intentionally limited to ensure semester feasibility.

---

## 7. Workload Design

Experiments simulate OLTP workloads with varying read/write characteristics.

### Static Workloads

* Read-heavy (90% reads)
* Write-heavy (90% writes)
* Balanced (50/50)

### Dynamic Workloads

Workload phases shift over time:

| Phase | Read % | Write % |
| ----- | ------ | ------- |
| 1     | 10     | 90      |
| 2     | 50     | 50      |
| 3     | 90     | 10      |

These shifts test adaptive tuning effectiveness.

---

## 8. Evaluation Metrics

Performance is evaluated using:

* **Throughput** (operations/sec)
* **P99 latency**
* **Read amplification**
* **Write amplification**
* **Adaptation time** (time to reach stable performance after workload shift)

---

## 9. Experimental Environment

### Storage Engine

* RocksDB (user-space build)

### RL Framework

* PyTorch (lightweight policy model)

### Workload Runner

* Custom OLTP generator / YCSB-style driver

### Infrastructure

* Development: Cloud VM (2–8 vCPU, SSD storage)
* Final experiments: Institutional research VM

---

## 10. Project Scope Constraints

To maintain semester feasibility, the project excludes:

* Storage engine structural redesign (e.g., FLSM-tree)
* Per-level compaction tuning
* Deep actor-critic RL models
* Distributed database deployments
* Kernel-level performance tuning

The focus remains on **adaptive configuration control**, not storage engine re-implementation.

---

## 11. Repository Structure

```bash
.
├── configs/              # RocksDB configuration profiles
├── workloads/            # Workload generators & traces
├── benchmark/            # Benchmark harness
├── rl_agent/             # RL policy & training loop
├── controller/           # Tuning interface
├── experiments/          # Experiment runners
├── results/              # Raw metrics & plots
└── report/               # Paper & analysis
```

---

## 12. Expected Outcomes

We hypothesize:

* RL tuning will outperform static configurations under dynamic workloads
* Gains will be modest but measurable (10–30%)
* Adaptation speed will be the primary differentiator
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

| Phase       | Deliverable             |
| ----------- | ----------------------- |
| Weeks 1     | Benchmark harness       |
| Weeks 2     | Static tuning baselines |
| Weeks 3-4   | RL environment          |
| Weeks 5     | Training & debugging    |
| Weeks 6     | Experiments             |
| Weeks 7-8   | Analysis & report       |

---
