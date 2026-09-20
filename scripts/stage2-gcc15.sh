#!/bin/sh
# Final stage: build GDC 15 from pkgsrc, bootstrapped with GDC 12, including
# the libphobos patches for NetBSD's renamed libc symbols.
set -e

SCRIPTS=$(cd "$(dirname "$0")" && pwd)
REPO=$(dirname "$SCRIPTS")
. "$SCRIPTS/common.sh"

need_netbsd
need_root
need_pkgdir "$GCC15_DIR"
need_gdc "$GDC12"
grep -q 'Mgcc-d' "$GCC15_DIR/options.mk" || die "run prep.sh first"
grep -q 'BOOT_LDFLAGS=.*-lgcc_eh' "$GCC15_DIR/Makefile" || die "run prep.sh first"
[ -x "${PKG_PREFIX}/libexec/cwrappers/config" ] || die "pkgtools/cwrappers missing; run prep.sh"
PATCHES_DIR=${PATCHES_DIR:-$REPO/patches/gcc15}
for p in "$PATCHES_DIR"/patch-*; do
	b=$(basename "$p")
	grep -q "($b)" "$GCC15_DIR/distinfo" || die "$b not in distinfo; run prep.sh"
done

trap 'restore_libunwind' EXIT INT TERM
hide_libunwind

build_with_gdc "$GCC15_DIR" "$GDC12"
( cd "$GCC15_DIR" && $MAKE install ) || die "make install failed in $GCC15_DIR"

restore_libunwind
trap - EXIT INT TERM

verify_gdc "$GDC15"

info "=== running the NetBSD-specific druntime tests"
for t in "$REPO"/tests/*.d; do
	out=/tmp/$(basename "$t" .d).$$
	"$GDC15" "$t" -o "$out" || die "$t failed to compile"
	"$out" || die "$t failed at runtime"
	rm -f "$out"
done

info "final stage done. GDC 15 is at $GDC15"
info "Next: scripts/post-install.sh for gdmd and DUB."
