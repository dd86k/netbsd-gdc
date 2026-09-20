#!/bin/sh
# Run the whole bootstrap: prep, then every stage. Hours of compiling.
set -e

SCRIPTS=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPTS/common.sh"

need_netbsd
need_root

for s in prep.sh stage0-gcc10.sh stage1-gcc12.sh stage2-gcc15.sh; do
	info "########## $s"
	sh "$SCRIPTS/$s" || die "$s failed"
done

info "all stages done; gdmd and DUB are optional: sh $SCRIPTS/post-install.sh"
