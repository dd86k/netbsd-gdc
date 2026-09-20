#!/bin/sh
# Run the whole bootstrap: prep, then every stage. Hours of compiling.
#
#   build-all.sh [build|clean]
set -e

SCRIPTS=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPTS/common.sh"

need_netbsd
need_root

case ${1:-build} in
build) ;;
clean)
	for d in "$GCC10_DIR" "$GCC12_DIR" "$GCC15_DIR"; do
		clean_pkg "$d"
	done
	exit 0
	;;
*) die "usage: $0 [build|clean]" ;;
esac

for s in prep.sh stage0-gcc10.sh stage1-gcc12.sh stage2-gcc15.sh; do
	info "########## $s"
	sh "$SCRIPTS/$s" || die "$s failed"
done

info "all stages done; gdmd and DUB are optional: sh $SCRIPTS/post-install.sh"
