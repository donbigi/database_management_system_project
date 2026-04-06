#!/usr/bin/env python3
import argparse
import sys
import os

TEMPLATE = """
[Version]
  rocksdb_version=8.10.0
  options_file_version=1.1

[DBOptions]
  create_if_missing=true
  create_missing_column_families=true
  statistics={statistics}
  
[CFOptions "default"]
  write_buffer_size={write_buffer_size}
  max_bytes_for_level_base={max_bytes_for_level_base}
  max_bytes_for_level_multiplier={max_bytes_for_level_multiplier}
  level0_file_num_compaction_trigger={compaction_trigger}
  target_file_size_base={target_file_size_base}
  compression={compression}
"""

def generate_config(args):
    # Default parameters based on realistic OLTP defaults
    options = {
        "statistics": "true" if args.stats else "false",
        "write_buffer_size": args.memtable_size * 1024 * 1024,
        "max_bytes_for_level_base": args.level_base_size * 1024 * 1024,
        "max_bytes_for_level_multiplier": args.level_multiplier,
        "compaction_trigger": args.compaction_trigger,
        "target_file_size_base": args.target_file_size * 1024 * 1024,
        "compression": "kSnappyCompression"
    }
    
    config_content = TEMPLATE.format(**options)
    
    with open(args.output, 'w') as f:
        f.write(config_content.strip() + "\n")
    
    print(f"Configuration written to {args.output}")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Apply RocksDB Configuration via OPTIONS file.")
    parser.add_argument("--output", type=str, default="/opt/rocksdb-workspace/OPTIONS.ini", help="Output file path")
    parser.add_argument("--memtable_size", type=int, default=64, help="write_buffer_size in MB")
    parser.add_argument("--level_base_size", type=int, default=256, help="max_bytes_for_level_base in MB")
    parser.add_argument("--level_multiplier", type=float, default=10.0, help="max_bytes_for_level_multiplier")
    parser.add_argument("--compaction_trigger", type=int, default=4, help="level0_file_num_compaction_trigger")
    parser.add_argument("--target_file_size", type=int, default=64, help="target_file_size_base in MB")
    parser.add_argument("--stats", action='store_true', help="Enable statistics")
    
    args = parser.parse_args()
    generate_config(args)
