# Stage 1: Build
FROM fedora:latest AS build

WORKDIR /app

# Install dependencies
RUN dnf update -y && dnf install -y \
    gcc gcc-c++ make python3-pip wget git \
    elfutils-libelf-devel gmp-devel python3-devel \
    clang libstdc++-devel libcxx libcxx-devel \
    ncurses-compat-libs \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# Install Bazelisk
RUN wget https://github.com/bazelbuild/bazelisk/releases/download/v1.20.0/bazelisk-linux-amd64 \
    && chmod +x bazelisk-linux-amd64 \
    && mv bazelisk-linux-amd64 /usr/local/bin/bazelisk

COPY . .

# Build with Bazel disk cache management
RUN bazelisk build //... \
    --disk_cache=/tmp/bazel-disk-cache \
    --output_user_root=/tmp/bazel-user-root

# Clean up to reduce image size
RUN rm -rf /tmp/bazel-disk-cache /tmp/bazel-user-root

# Stage 2: Test (New)
FROM build AS test

# Run tests
RUN bazelisk test //... --cxxopt='-std=c++17'

# Stage 3: Target Image
FROM fedora:latest AS target

COPY --from=build /app/bazel-bin/src/starkware/main/cpu/cpu_air_prover /usr/local/bin/
COPY --from=build /app/bazel-bin/src/starkware/main/cpu/cpu_air_verifier /usr/local/bin/

# Install necessary runtime dependencies
RUN dnf update -y && dnf install -y \
    elfutils-libelf gmp libstdc++ \
    && dnf clean all \
    && rm -rf /var/cache/dnf

ENTRYPOINT ["/bin/bash"]
