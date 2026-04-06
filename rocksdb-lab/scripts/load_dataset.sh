#!/bin/bash
set -e
set -x

echo "========================================="
echo "  RocksDB Dataset Generation Script"
echo "========================================="

WORKSPACE_DIR="/opt/rocksdb-workspace"
DB_DIR="/mnt/data/rocksdb"
ROCKSDB_PATH="$WORKSPACE_DIR/rocksdb"

# Dataset Specs
RECORD_COUNT=5000000    # 5 Million records
VALUE_SIZE=1024         # 1 KB value size
KEY_SIZE=16             # 16 byte keys

echo "Cleaning previous database state..."
rm -rf "$DB_DIR"/*

cd "$ROCKSDB_PATH"

echo "Starting db_bench bulk load..."
start_time=$(date +%s)

# Run db_bench with fillseq (Sequential write is best for initial loading)
./db_bench \
  --benchmarks=fillseq \
  --num=$RECORD_COUNT \
  --value_size=$VALUE_SIZE \
  --key_size=$KEY_SIZE \
  --db="$DB_DIR" \
  --compression_type=snappy \
  --disable_auto_compactions=1 \
  --write_buffer_size=$((64 * 1024 * 1024)) \
  --target_file_size_base=$((64 * 1024 * 1024)) \
  --statistics=1

end_time=$(date +%s)
load_time=$((end_time - start_time))

echo "Dataset load complete! Time taken: $load_time seconds."
echo "Dataset resides in $DB_DIR"
