# Stage 1: Build
FROM fedora:latest AS build

# Set the working directory
WORKDIR /app

# Install dependencies and handle package cache clean-up
RUN dnf clean all && \
    dnf makecache && \
    dnf update -y && \
    dnf install -y \
        gcc \
        gcc-c++ \
        make \
        python3-pip \
        wget \
        git \
        elfutils-libelf-devel \
        gmp-devel \
        python3-devel \
        clang \
        libstdc++-devel \
        libcxx \
        libcxx-devel \
        ncurses-compat-libs \
        bazelisk && \
    dnf clean all && \
    rm -rf /var/cache/dnf

# Install Bazelisk (Bazel wrapper)
RUN wget https://github.com/bazelbuild/bazelisk/releases/download/v1.20.0/bazelisk-linux-amd64 && \
    chmod +x bazelisk-linux-amd64 && \
    mv bazelisk-linux-amd64 /usr/local/bin/bazelisk

# Copy all project files into the container
COPY . .

# Build the project with Bazel using disk cache for better performance
RUN bazelisk build //... \
    --disk_cache=/tmp/bazel-disk-cache \
    --output_user_root=/tmp/bazel-user-root

# Clean up build artifacts to reduce image size
RUN rm -rf /tmp/bazel-disk-cache /tmp/bazel-user-root

# Stage 2: Target Image for Final Application
FROM fedora:latest AS target

# Copy the built binaries from the build stage
COPY --from=build /app/bazel-bin/src/starkware/main/cpu/cpu_air_prover /usr/local/bin/
COPY --from=build /app/bazel-bin/src/starkware/main/cpu/cpu_air_verifier /usr/local/bin/

# Install the necessary runtime dependencies
RUN dnf clean all && \
    dnf makecache && \
    dnf update -y && \
    dnf install -y \
        elfutils-libelf \
        gmp \
        libstdc++ && \
    dnf clean all && \
    rm -rf /var/cache/dnf

# Ent
