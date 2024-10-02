#!/bin/bash
set -eo pipefail

# Install dependencies
dnf install -y clang gcc-c++ libstdc++-devel libcxx libcxx-devel \
    ncurses-compat-libs elfutils-devel gmp-devel python3-devel wget git

# Install Python dependencies
pip install cpplint pytest numpy sympy==1.12.1 cairo-lang==0.12.0

# Build the project with Bazel, ensuring C++17 compatibility
bazelisk build //... --cxxopt='-std=c++17'

# Optionally, run tests (uncomment if needed)
# bazelisk test //... --cxxopt='-std=c++17'
