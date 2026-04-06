#!/usr/bin/env python3
import argparse
import re
import csv
import json
import os

def parse_db_bench_output(filepath):
    metrics = {
        "throughput_ops_sec": None,
        "p99_latency_micros": None,
        "avg_latency_micros": None
    }
    try:
        with open(filepath, 'r') as f:
            content = f.read()
            
            # Extract Ops/sec: `readrandomwriterandom :      53.498 micros/op 18692 ops/sec; ...`
            ops_match = re.search(r"(\w+)\s+:\s+([0-9.]+)\s+micros/op\s+([0-9]+)\s+ops/sec", content)
            if ops_match:
                metrics["avg_latency_micros"] = float(ops_match.group(2))
                metrics["throughput_ops_sec"] = int(ops_match.group(3))
            
            # Extract Percentiles (P99): `Percentiles: P50: 14.10 P75: 22.84 P99: 144.35 P99.9: 310.45`
            p99_match = re.search(r"P99:\s+([0-9.]+)", content)
            if p99_match:
                metrics["p99_latency_micros"] = float(p99_match.group(1))

    except Exception as e:
        print(f"Error reading file {filepath}: {e}")
        
    return metrics

def parse_rocks_log(log_path):
    stats = {
        "read_amp": None,
        "write_amp": None,
        "compaction_bytes_read": 0,
        "compaction_bytes_written": 0
    }
    try:
        with open(log_path, 'r') as f:
            lines = f.readlines()
            for line in reversed(lines):
                # Search backwards for the final Cumulative compaction stats
                # `Cumulative compaction: 10.20 GB write, 15.30 MB read`
                if "Cumulative compaction:" in line and stats["compaction_bytes_written"] == 0:
                    c_write = re.search(r"([0-9.]+)\s+([KMG]?B)\s+write", line)
                    c_read = re.search(r"([0-9.]+)\s+([KMG]?B)\s+read", line)
                    
                    def to_bytes(match):
                        if not match: return 0
                        val, unit = float(match.group(1)), match.group(2)
                        return int(val * {"B": 1, "KB": 1024, "MB": 1024**2, "GB": 1024**3}.get(unit, 1))
                        
                    stats["compaction_bytes_written"] = to_bytes(c_write)
                    stats["compaction_bytes_read"] = to_bytes(c_read)
                    
                # Try to catch Read Amp if present in the same block
                ra_match = re.search(r"Read Amp:\s+([0-9.]+)", line)
                if ra_match and stats["read_amp"] is None:
                    stats["read_amp"] = float(ra_match.group(1))
                
                # Search backwards for Read Amp / Write Amp
                # RocksDB LOG often contains `Write Amp: 2.4` in its periodic stall/compaction outputs
                wa_match = re.search(r"Write Amp:\s+([0-9.]+)", line)
                if wa_match and stats["write_amp"] is None:
                    stats["write_amp"] = float(wa_match.group(1))
    except Exception as e:
        print(f"Warning: Could not parse LOG {log_path}: {e}")
    return stats


def main():
    parser = argparse.ArgumentParser(description="Collect db_bench and RocksDB metrics")
    parser.add_argument("--benchmark_out", required=True, help="Path to db_bench output file")
    parser.add_argument("--rocksdb_log", required=True, help="Path to RocksDB LOG file")
    parser.add_argument("--output", default="results.csv", help="Output file path (CSV or JSON)")
    parser.add_argument("--run_id", default="run_1", help="Identifier for this specific run")
    args = parser.parse_args()

    bench_metrics = parse_db_bench_output(args.benchmark_out)
    log_metrics = parse_rocks_log(args.rocksdb_log)

    combined = {
        "run_id": args.run_id,
        **bench_metrics,
        **log_metrics
    }

    print(json.dumps(combined, indent=2))

    # Append to CSV
    write_header = not os.path.exists(args.output) or os.path.getsize(args.output) == 0
    with open(args.output, 'a', newline='') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=combined.keys())
        if write_header:
            writer.writeheader()
        writer.writerow(combined)

    print(f"Metrics appended to {args.output}")

if __name__ == '__main__':
    main()
