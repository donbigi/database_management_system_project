#!/bin/bash
set -e
set -x   # log commands for debugging

echo "========================================="
echo "  RocksDB Environment Setup Script"
echo "========================================="

# Update system and install dependencies
sudo apt-get update
sudo apt-get install -y \
  build-essential \
  cmake \
  git \
  libsnappy-dev \
  zlib1g-dev \
  libbz2-dev \
  liblz4-dev \
  libzstd-dev \
  libgflags-dev \
  python3 \
  python3-pip

# Prepare workspace
WORKSPACE_DIR="/opt/rocksdb-workspace"
DB_DIR="/mnt/data/rocksdb"
sudo mkdir -p "$WORKSPACE_DIR"
sudo mkdir -p "$DB_DIR"
sudo chown -R $USER:$USER "$WORKSPACE_DIR"
sudo chown -R $USER:$USER "$DB_DIR"

cd "$WORKSPACE_DIR"

# Clone RocksDB if not present
if [ ! -d "rocksdb" ]; then
  echo "Cloning RocksDB..."
  git clone https://github.com/facebook/rocksdb.git
fi

cd rocksdb

# Checkout a stable release for guaranteed compilation
git checkout v8.10.0

# Add swap to prevent OOM during parallel compilation
if [ ! -f /swapfile ] && [ ! -b /swapfile ]; then
    echo "Creating swapfile to prevent OOM..."
    sudo fallocate -l 4G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
fi

# Build release static library + db_bench together
echo "Building db_bench..."
DISABLE_WARNING_AS_ERROR=1 make db_bench -j$(nproc) DEBUG_LEVEL=0

# Verify db_bench runs and document default configuration
echo "Verifying db_bench and documenting default config..."
./db_bench --benchmarks=fillrandom \
  --num=1000 \
  --db="$DB_DIR" \
  --compression_type=snappy \
  --statistics=1 \
  --histogram=1 \
  --bloom_bits=10 \
  --compaction_style=0 \
  > "$WORKSPACE_DIR/default_config_test.txt"

echo "RocksDB setup complete. db_bench is ready."
echo "Default configuration test output saved to $WORKSPACE_DIR/default_config_test.txt"
