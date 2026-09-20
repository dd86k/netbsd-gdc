#!/bin/sh
# Rebuild only libphobos in an existing gcc15 work tree, e.g. after changing a
# patch in patches/gcc15. Avoids a full GCC rebuild.
set -e

SCRIPTS=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPTS/common.sh"

need_netbsd
need_root
[ -x "$GMAKE" ] || die "$GMAKE missing"

jobs=${MAKE_JOBS:-$(sysctl -n hw.ncpu)}
found=0
for d in "$GCC15_DIR"/work/build/*--netbsd/libphobos; do
	[ -d "$d" ] || continue
	found=1
	info "rebuilding $d with -j$jobs"
	( cd "$d" && $GMAKE -j"$jobs" clean && $GMAKE -j"$jobs" && $GMAKE install ) ||
		die "libphobos rebuild failed in $d"
done
[ "$found" = 1 ] || die "no libphobos build dir under $GCC15_DIR/work/build"

verify_gdc "$GDC15"
