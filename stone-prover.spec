Name: stone-prover
Version: 1.0.0
Release: 1%{?dist}
Summary: High-performance proof verification tool

License: MIT
BuildArch: x86_64

# Build dependencies
BuildRequires: gcc, make, bazelisk, rpm-build, python3-pip
Requires: libtinfo5, libdw-dev, libgmp3-dev, python3, python3-numpy, python3-sympy

%description
Stone-prover is a high-performance proof verification tool.

%prep
git clone https://github.com/baking-bad/stone-prover.git /tmp/stone-prover

%build
cd /tmp/stone-prover
bazelisk build --cpu=%{_arch} //...

%install
mkdir -p %{buildroot}/usr/local/bin
install -m 755 /tmp/stone-prover/build/bazelbin/src/starkware/main/cpu/cpu_air_prover %{buildroot}/usr/local/bin/cpu_air_prover
install -m 755 /tmp/stone-prover/build/bazelbin/src/starkware/main/cpu/cpu_air_verifier %{buildroot}/usr/local/bin/cpu_air_verifier

%files
/usr/local/bin/cpu_air_prover
/usr/local/bin/cpu_air_verifier

%changelog
* Wed Oct 02 2024 Your Name <youremail@example.com> - 1.0.0-1
- Initial RPM package for stone-prover.
