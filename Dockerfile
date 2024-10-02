# Stage 1: Build Stage
FROM fedora:latest AS build

WORKDIR /app

# Install build dependencies
RUN dnf update -y && dnf install -y \
    gcc gcc-c++ make python3-pip wget git \
    elfutils-libelf-devel gmp-devel python3-devel \
    clang libstdc++-devel libcxx libcxx-devel \
    ncurses-compat-libs bazelisk \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# Install Python dependencies
RUN pip install cpplint pytest numpy sympy==1.12.1 cairo-lang==0.12.0

# Copy the source code into the container
COPY . .

# Build the project using Bazelisk
RUN bazelisk build //... --cxxopt='-std=c++17'

# Stage 2: Testing Stage (Optional but useful for CI/CD)
FROM build AS test

# Run tests to verify the build
RUN bazelisk test //... --cxxopt='-std=c++17'

# Optional: Perform some end-to-end testing or proof verification
WORKDIR /app/e2e_test/CairoZero

# Example end-to-end test using Cairo files
RUN cairo-compile fibonacci.cairo --output fibonacci_compiled.json --proof_mode

RUN cairo-run \
    --program=fibonacci_compiled.json \
    --layout=small \
    --program_input=fibonacci_input.json \
    --air_public_input=fibonacci_public_input.json \
    --air_private_input=fibonacci_private_input.json \
    --trace_file=fibonacci_trace.json \
    --memory_file=fibonacci_memory.json \
    --min_steps=512 \
    --print_output \
    --proof_mode

RUN cpu_air_prover \
    --out_file=fibonacci_proof.json \
    --private_input_file=fibonacci_private_input.json \
    --public_input_file=fibonacci_public_input.json \
    --prover_config_file=cpu_air_prover_config.json \
    --parameter_file=cpu_air_params.json

RUN cpu_air_verifier --in_file=fibonacci_proof.json && echo "Successfully verified proof."

# Stage 3: Production Image (Small runtime environment)
FROM fedora:latest AS target

# Copy the prover and verifier binaries from the build stage
COPY --from=build /app/bazel-bin/src/starkware/main/cpu/cpu_air_prover /usr/local/bin/
COPY --from=build /app/bazel-bin/src/starkware/main/cpu/cpu_air_verifier /usr/local/bin/

# Install necessary runtime dependencies
RUN dnf update -y && dnf install -y \
    elfutils-libelf gmp libstdc++ \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# Entry point for running the binaries
ENTRYPOINT ["/bin/bash"]

