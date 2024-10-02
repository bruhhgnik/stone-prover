#!/bin/bash
# Fix dependencies
set -o xtrace
set -e

# Detect OS and architecture
os=$(uname | tr '[:upper:]' '[:lower:]')
arch=$(uname -m | sed s/aarch64/arm64/ | sed s/x86_64/amd64/)

# Install dependencies based on the OS
if [ "$os" == "linux" ]; then
    export DEBIAN_FRONTEND=noninteractive

    # Check for Fedora or Debian-based Linux
    if [ -f /etc/fedora-release ]; then
        echo "Detected Fedora"
        sudo dnf install -y ncurses-compat-libs libdw-devel gmp-devel python3-devel wget git

    else
        echo "Detected Debian-based Linux"
        sudo apt-get install -y libtinfo5 libdw-dev libgmp3-dev python3-dev wget git
    fi

    # Install Python dependencies
    pip install cpplint pytest numpy sympy==1.12.1 cairo-lang==0.12.0

    # Install Bazelisk (Bazel wrapper)
    wget "https://github.com/bazelbuild/bazelisk/releases/download/v1.20.0/bazelisk-$os-$arch"
    chmod 755 "bazelisk-$os-$arch"
    sudo mv "bazelisk-$os-$arch" /bin/bazelisk

elif [ "$os" == "darwin" ]; then
    # macOS dependencies
    echo "Detected macOS"
    brew install gmp

    # Install Python dependencies
    python3 -m pip install cpplint pytest numpy sympy==1.12.1 cairo-lang==0.12.0 --break-system-packages

else
    echo "$os/$arch is not supported"
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
