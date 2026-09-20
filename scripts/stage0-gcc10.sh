#!/bin/sh
# Stage 0: build GDC 10 from pkgsrc. GCC 10 is the last release whose D
# frontend still builds with a C++ compiler alone, so nothing bootstraps it.
set -e

SCRIPTS=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPTS/common.sh"

need_netbsd
need_root
need_pkgdir "$GCC10_DIR"
grep -q 'Mgcc-d' "$GCC10_DIR/options.mk" || die "run prep.sh first"

if ! ( cd "$GCC10_DIR" && $MAKE ); then
	warn "if the failure was a checksum mismatch after editing options.mk:"
	warn "    cd $GCC10_DIR && $MAKE distclean && $MAKE checksum"
	die "make failed in $GCC10_DIR"
fi
( cd "$GCC10_DIR" && $MAKE install ) || die "make install failed in $GCC10_DIR"

verify_gdc "$GDC10"
info "stage0 done. Linker warnings about nanosleep/clock_gettime/time are"
info "expected here; the final stage fixes them with the libphobos patches."
info "Reclaim disk space with: cd $GCC10_DIR && $MAKE clean"
