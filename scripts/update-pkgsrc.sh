#!/bin/sh
# Fetch or update the pkgsrc tree over anonymous CVS.
#
#   update-pkgsrc.sh                 update, staying on the current branch
#   update-pkgsrc.sh pkgsrc-2025Q4   update and switch to that quarterly branch
#   update-pkgsrc.sh current         update and switch to HEAD
#
# Our pkgsrc edits are reverted from their .pristine copies first, so cvs has
# nothing to conflict with; re-run prep.sh afterwards to put them back.
set -e

SCRIPTS=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPTS/common.sh"

BRANCH=${1:-}
DEFAULT_BRANCH=${DEFAULT_BRANCH:-pkgsrc-2025Q4}
ANONCVS=${ANONCVS:-anoncvs@anoncvs.NetBSD.org:/cvsroot}
CVS_RSH=${CVS_RSH:-ssh}
export CVS_RSH

need_netbsd
need_root
command -v cvs > /dev/null || die "cvs not found (it ships in NetBSD base)"

if [ -n "$DRYRUN" ]; then
	dry=-n
	info "dry run: nothing will be written"
else
	dry=
fi

if [ ! -d "$PKGSRC/CVS" ]; then
	parent=$(dirname "$PKGSRC")
	[ "$(basename "$PKGSRC")" = "pkgsrc" ] ||
		die "cvs checkout always creates a directory named pkgsrc, but PKGSRC=$PKGSRC"
	tag=${BRANCH:-$DEFAULT_BRANCH}
	info "checking out $tag into $PKGSRC (this takes a while)"
	case $tag in
	current | HEAD) rev= ;;
	*) rev="-r $tag" ;;
	esac
	# shellcheck disable=SC2086
	( cd "$parent" && cvs $dry -q -d "$ANONCVS" checkout $rev -P pkgsrc ) ||
		die "cvs checkout failed"
	info "checkout done; now run prep.sh"
	exit 0
fi

# CVS/Tag is a one-letter kind (T for branch) followed by the tag name.
if [ -f "$PKGSRC/CVS/Tag" ]; then
	current=$(sed -e 's/^.//' "$PKGSRC/CVS/Tag")
else
	current=HEAD
fi
info "$PKGSRC is on $current"

info "=== locally modified files (cvs' view)"
( cd "$PKGSRC" && cvs -q -n update -dP 2>/dev/null ) | grep '^[MC] ' || info "none"

info "=== reverting our pkgsrc edits"
found=0
for p in $(find "$PKGSRC" -name '*.pristine'); do
	found=1
	f=${p%.pristine}
	info "restoring $f"
	[ -n "$DRYRUN" ] && continue
	cat "$p" > "$f"
	rm -f "$p"
done
[ "$found" = 1 ] || info "no .pristine copies; nothing to revert"

case $BRANCH in
"") rev= ;;
current | HEAD) rev=-A ;;
*) rev="-r $BRANCH" ;;
esac

info "=== cvs update${BRANCH:+ to $BRANCH}"
# shellcheck disable=SC2086
( cd "$PKGSRC" && cvs $dry -q update -dP $rev ) || die "cvs update failed"

info "update done. Re-run prep.sh to reapply the gcc-d options, the"
info "BOOT_LDFLAGS fix and the libphobos patches."
warn "Existing work/ directories are from the old tree: 'make clean' in any"
warn "lang/gcc* package you have not finished installing yet."
