#!/bin/bash
# Enable debugging and exit on errors
set -o xtrace
set -e

# Detect OS and architecture
os=$(uname | tr '[:upper:]' '[:lower:]')
arch=$(uname -m | sed s/aarch64/arm64/ | sed s/x86_64/amd64/)

# Function to install dependencies based on the operating system
install_dependencies() {
    if [ "$os" == "linux" ]; then
        if [ -f /etc/fedora-release ]; then
            echo "Detected Fedora"
            sudo dnf install -y libtinfo libdw-devel gmp-devel  # Install Fedora-specific packages
        else
            echo "Detected Debian-based Linux"
            export DEBIAN_FRONTEND=noninteractive
            sudo apt-get update
            sudo apt-get install -y libtinfo5 libdw-dev libgmp3-dev  # Install Debian/Ubuntu packages
        fi
        pip install cpplint pytest numpy sympy==1.12.1 cairo-lang==0.12.0  # Python dependencies

        # Install Bazelisk (build tool wrapper for Bazel)
        wget "https://github.com/bazelbuild/bazelisk/releases/download/v1.20.0/bazelisk-$os-$arch"
        chmod 755 "bazelisk-$os-$arch"
        sudo mv "bazelisk-$os-$arch" /bin/bazelisk

    elif [ "$os" == "darwin" ]; then
        echo "Detected macOS"
        brew install gmp  # Install GMP on macOS using Homebrew
        python3 -m pip install cpplint pytest numpy sympy==1.12.1 cairo-lang==0.12.0 --break-system-packages  # Install Python dependencies
    else
        echo "$os/$arch is not supported"
        exit 1
    fi
}

# Install dependencies based on the OS
install_dependencies

# Clone the stone-prover repository and build it
git clone https://github.com/baking-bad/stone-prover.git /tmp/stone-prover
cd /tmp/stone-prover || exit

# Build the project using Bazelisk for the appropriate architecture
bazelisk build --cpu=$arch //...

# Run tests using Bazelisk
bazelisk test --cpu=$arch //...

# Create symbolic links to the binaries for easier execution
ln -s /tmp/stone-prover/build/bazelbin/src/starkware/main/cpu/cpu_air_prover /usr/local/bin/cpu_air_prover
ln -s /tmp/stone-prover/build/bazelbin/src/starkware/main/cpu/cpu_air_verifier /usr/local/bin/cpu_air_verifier
