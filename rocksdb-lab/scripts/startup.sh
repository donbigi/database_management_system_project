#!/bin/bash
set -e
set -x   # log commands for debugging

# Update system
apt-get update

# Install dependencies
apt-get install -y \
  build-essential \
  cmake \
  git \
  libsnappy-dev \
  zlib1g-dev \
  libbz2-dev \
  liblz4-dev \
  libzstd-dev \
  libgflags-dev

# Prepare workspace
mkdir -p /opt
cd /opt

# Clone RocksDB if not present
if [ ! -d "rocksdb" ]; then
  git clone https://github.com/facebook/rocksdb.git
fi

cd rocksdb

# Build release static library + db_bench together
make static_lib db_bench -j$(nproc) DEBUG_LEVEL=0


# Prepare data directory
mkdir -p /mnt/data/dbbench

# Run experiment
./db_bench \
  --benchmarks=fillrandom \
  --num=1000000 \
  --db=/mnt/data/dbbench \
  --compression_type=snappy \
  > /opt/results.txt

# Upload results (optional but recommended)
# gsutil cp /opt/results.txt gs://YOUR_BUCKET/

# Shutdown VM when done
shutdown -h now
