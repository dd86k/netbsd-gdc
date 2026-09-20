#!/bin/sh
# Stage 1: build GDC 12 from pkgsrc, bootstrapped with GDC 10.
#
#   stage1-gcc12.sh [build|clean]
set -e

SCRIPTS=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPTS/common.sh"

need_netbsd
need_root

case ${1:-build} in
build) ;;
clean)
	clean_pkg "$GCC12_DIR"
	exit 0
	;;
*) die "usage: $0 [build|clean]" ;;
esac

need_pkgdir "$GCC12_DIR"
need_gdc "$GDC10"
grep -q 'Mgcc-d' "$GCC12_DIR/options.mk" || die "run prep.sh first"
grep -q 'BOOT_LDFLAGS=.*-lgcc_eh' "$GCC12_DIR/Makefile" || die "run prep.sh first"

trap 'restore_libunwind' EXIT INT TERM
hide_libunwind

build_with_gdc "$GCC12_DIR" "$GDC10"
( cd "$GCC12_DIR" && $MAKE install ) || die "make install failed in $GCC12_DIR"

restore_libunwind
trap - EXIT INT TERM

verify_gdc "$GDC12"
info "stage1 done. The time-function linker warnings and the missing"
info ".debug_ranges warnings are cosmetic."
