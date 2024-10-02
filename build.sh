#!/bin/bash
set -eo pipefail

# Install dependencies
dnf install -y clang gcc-c++ libstdc++-devel libcxx libcxx-devel \
    ncurses-compat-libs elfutils-devel gmp-devel python3-devel wget git

# Install Python dependencies
pip install cpplint pytest numpy sympy==1.12.1 cairo-lang==0.12.0

# Build with Bazel, specifying C++17 compatibility
bazelisk build //... --cxxopt='-std=c++17'

# Run tests (comment out if tests are too resource-intensive for CI)
# bazelisk test //... --cxxopt='-std=c++17'