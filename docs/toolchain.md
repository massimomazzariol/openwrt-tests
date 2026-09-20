# Hardware validation toolchain

The hardware validation extensions are designed to remain device-independent.

Device-specific expectations belong in target data or are derived from the
firmware image being tested. The validation core should not contain assumptions
specific to an individual router model.

## Tool policy

Prefer tools from the same OpenWrt source tree used to build the firmware.

This is especially important for firmware format and Device Tree inspection,
where using the matching OpenWrt build tools avoids differences between distro
tool versions and the tools actually used to produce the image.

System packages are used for generic host functionality and emulation.

`binwalk` is considered an optional diagnostic and reverse-engineering tool.
It must not be required for normal validation.

## Tested baseline

Baseline recorded on 2026-09-20.

### OpenWrt

- OpenWrt commit: `c1111ed5d69678613b7a47aa76f8e6209f0da56d`
- OpenWrt describe: `reboot-36385-gc1111ed5d6-dirty`
- Kernel used by the tested build: Linux 6.18.52

### Python test environment

- Python: 3.14.4
- uv: 0.12.17
- pytest: 9.1.1
- pytest-check: 2.9.1
- pytest-harvest: 1.10.5
- labgrid: 25.1.dev346
- labgrid source commit: `a457f36c5660fa8761e224d2959a796084f087c9`
- ansible: 11.13.0

The Python environment is managed with `uv`.

The repository lock file records the exact resolved dependency versions used
for the tested baseline.

## OpenWrt-native image tools

### firmware-utils

OpenWrt host firmware-utils source:

- source date: 2026-07-30
- source commit: `c9da48613b5d7b892d5a3871dc6332487360de4a`

Tested host binaries:

- `fwtool`
- `mktplinkfw2`

`fwtool` is used for OpenWrt image metadata.

Format-specific OpenWrt firmware-utils tools may be used by image-format
adapters. For example, TP-Link v2 images can be inspected and extracted with
`mktplinkfw2`.

The generic validation core must not depend on a specific vendor format.

### U-Boot image tools

- mkimage version: 2026.07

The OpenWrt-built copy is preferred over a system copy when inspecting firmware
produced by the corresponding OpenWrt build tree.

### Device Tree Compiler

OpenWrt-built DTC:

- DTC 1.7.2-g52f07dcc

The DTC built together with the OpenWrt kernel is preferred for Device Tree
inspection.

A distro-provided `device-tree-compiler` may be used as a fallback.

## Optional QEMU capabilities

QEMU is only required for targets which are tested through emulation.

Missing QEMU architectures must not prevent image inspection or validation of
physical hardware.

On Debian/Ubuntu systems:

- MIPS: `sudo apt-get install qemu-system-mips`
- x86/x86_64: `sudo apt-get install qemu-system-x86`
- AArch64: `sudo apt-get install qemu-system-arm`

## Generic host tools

Typical Debian/Ubuntu packages:

- `git`
- `make`
- `curl`
- `file`
- `xz-utils`
- `squashfs-tools`

Optional fallback inspection packages:

- `device-tree-compiler`
- `u-boot-tools`

The OpenWrt-built equivalents are preferred when available.
