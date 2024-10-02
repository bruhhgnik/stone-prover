#!/bin/bash
# Fix dependencies
set -o xtrace
set -e

# Detect OS and architecture
os=$(uname | tr '[:upper:]' '[:lower:]')
arch=$(uname -m | sed s/aarch64/arm64/ | sed s/x86_64/amd64/)

# Fedora-specific installation
if [ "$os" == "linux" ] && [ -f /etc/fedora-release ]; then
    echo "Detected Fedora"

    # Clean and update Fedora packages
    sudo dnf clean all
    sudo dnf update -y

    # Install dependencies
    sudo dnf install -y clang gcc-c++ libstdc++-devel libcxx libcxx-devel \
        ncurses-compat-libs elfutils-devel gmp-devel python3-devel wget git

    # Install Python dependencies
    pip install cpplint pytest numpy sympy==1.12.1 cairo-lang==0.12.0

    # Install Bazelisk (Bazel wrapper)
    wget "https://github.com/bazelbuild/bazelisk/releases/download/v1.20.0/bazelisk-linux-amd64"
    chmod 755 "bazelisk-linux-amd64"
    sudo mv "bazelisk-linux-amd64" /bin/bazelisk

else
    echo "$os is either not Fedora or not supported."
    exit 1
fi

# Clone the stone-prover repository
git clone https://github.com/baking-bad/stone-prover.git /tmp/stone-prover

# Move into the stone-prover directory
cd /tmp/stone-prover || exit

# Build with Bazel, specifying C++17 compatibility
bazelisk build --cpu=$arch //... --cxxopt='-std=c++17'

# Run tests
bazelisk test --cpu=$arch //... --cxxopt='-std=c++17'

# Create symbolic links for the built binaries
ln -s /tmp/stone-prover/build/bazelbin/src/starkware/main/cpu/cpu_air_prover /usr/local/bin/cpu_air_prover
ln -s /tmp/stone-prover/build/bazelbin/src/starkware/main/cpu/cpu_air_verifier /usr/local/bin/cpu_air_verifier
