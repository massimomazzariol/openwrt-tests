#!/bin/sh

set -u

OPENWRT_DIR="${OPENWRT_DIR:-}"

pass()
{
    printf 'PASS  %-24s %s\n' "$1" "$2"
}

info()
{
    printf 'INFO  %-24s %s\n' "$1" "$2"
}

miss()
{
    printf 'MISS  %-24s %s\n' "$1" "$2"
}

find_command()
{
    command -v "$1" 2>/dev/null || true
}

check_host_tool()
{
    cmd="$1"
    package="$2"

    path="$(find_command "$cmd")"

    if [ -n "$path" ]; then
        pass "$cmd" "$path"
    else
        miss "$cmd" "not installed"
        printf '      Debian/Ubuntu: sudo apt-get install %s\n' "$package"
        CORE_MISSING=$((CORE_MISSING + 1))
    fi
}

echo "========== HARDWARE VALIDATION PREFLIGHT =========="
echo

CORE_MISSING=0

echo "=== Core host tools ==="

check_host_tool git git
check_host_tool make make
check_host_tool curl curl
check_host_tool file file
check_host_tool xz xz-utils
check_host_tool unsquashfs squashfs-tools

echo
echo "=== Python environment ==="

UV="$(find_command uv)"

if [ -z "$UV" ] && [ -x "$HOME/.local/bin/uv" ]; then
    UV="$HOME/.local/bin/uv"
fi

if [ -n "$UV" ]; then
    pass uv "$("$UV" --version 2>/dev/null)"

    if "$UV" run python -c 'import pytest, labgrid' >/dev/null 2>&1; then
        "$UV" run python - <<'PY'
from importlib.metadata import version

for package in (
    "pytest",
    "pytest-check",
    "pytest-harvest",
    "labgrid",
    "ansible",
):
    print(f"PASS  {package:<24} {version(package)}")
PY
    else
        miss "Python project env" "not synchronized"
        echo "      run: uv sync"
        CORE_MISSING=$((CORE_MISSING + 1))
    fi
else
    miss uv "not installed"
    echo "      official installer:"
    echo "      curl -LsSf https://astral.sh/uv/install.sh | sh"
    CORE_MISSING=$((CORE_MISSING + 1))
fi

echo
echo "=== OpenWrt-native image tools ==="

if [ -z "$OPENWRT_DIR" ]; then
    info OPENWRT_DIR "not set"
    echo "      set OPENWRT_DIR to the OpenWrt source tree used to build the image"
else
    for tool in fwtool mktplinkfw2 mkimage; do
        path="$OPENWRT_DIR/staging_dir/host/bin/$tool"

        if [ -x "$path" ]; then
            pass "$tool" "$path"
        else
            miss "$tool" "not found in OpenWrt staging_dir"
        fi
    done

    DTC="$(find "$OPENWRT_DIR/build_dir" \
        -type f \
        -path '*/scripts/dtc/dtc' \
        -perm -u+x \
        -print 2>/dev/null | head -1)"

    if [ -n "$DTC" ]; then
        version="$("$DTC" --version 2>&1 || true)"
        pass "OpenWrt dtc" "$version"
    else
        miss "OpenWrt dtc" "not found"
        echo "      build the kernel for the target first"
    fi
fi

echo
echo "=== System fallback image tools ==="

for spec in \
    "dtc:device-tree-compiler" \
    "fdtget:device-tree-compiler" \
    "fdtdump:device-tree-compiler" \
    "mkimage:u-boot-tools" \
    "dumpimage:u-boot-tools"
do
    cmd="${spec%%:*}"
    package="${spec#*:}"
    path="$(find_command "$cmd")"

    if [ -n "$path" ]; then
        pass "$cmd" "$path"
    else
        info "$cmd" "optional fallback missing"
        printf '      Debian/Ubuntu: sudo apt-get install %s\n' "$package"
    fi
done

echo
echo "=== QEMU capabilities ==="

for spec in \
    "qemu-system-mips:qemu-system-mips:MIPS" \
    "qemu-system-x86_64:qemu-system-x86:x86_64" \
    "qemu-system-aarch64:qemu-system-arm:AArch64"
do
    cmd="$(printf '%s' "$spec" | cut -d: -f1)"
    package="$(printf '%s' "$spec" | cut -d: -f2)"
    arch="$(printf '%s' "$spec" | cut -d: -f3)"

    path="$(find_command "$cmd")"

    if [ -n "$path" ]; then
        pass "QEMU $arch" "$path"
    else
        info "QEMU $arch" "capability unavailable"
        printf '      Debian/Ubuntu: sudo apt-get install %s\n' "$package"
    fi
done

echo
echo "=== Optional diagnostic tools ==="

BINWALK="$(find_command binwalk)"

if [ -n "$BINWALK" ]; then
    pass binwalk "$BINWALK"
else
    info binwalk "optional; not required by validation core"
fi

echo
echo "========== RESULT =========="

if [ "$CORE_MISSING" -eq 0 ]; then
    echo "CORE_PREFLIGHT=PASS"
else
    echo "CORE_PREFLIGHT=NEEDS_SETUP"
fi

echo
echo "QEMU capabilities are reported separately and do not affect CORE_PREFLIGHT."
