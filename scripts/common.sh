#!/bin/sh
# Shared helpers for the NetBSD GDC bootstrap scripts. Sourced, never executed.

PKGSRC=${PKGSRC:-/usr/pkgsrc}
PKG_PREFIX=${PKG_PREFIX:-/usr/pkg}
MKCONF=${MKCONF:-/etc/mk.conf}
MAKE=${MAKE:-make}
GMAKE=${GMAKE:-${PKG_PREFIX}/bin/gmake}

GCC10_DIR=${PKGSRC}/lang/gcc10
GCC12_DIR=${PKGSRC}/lang/gcc12
GCC15_DIR=${PKGSRC}/lang/gcc15

GDC10=${PKG_PREFIX}/gcc10/bin/gdc
GDC12=${PKG_PREFIX}/gcc12/bin/gdc
GDC15=${PKG_PREFIX}/gcc15/bin/gdc

UNWIND_HEADERS="unwind.h __libunwind_config.h libunwind.h"

# cwrappers installs only libexec/cwrappers/*-wrapper; there is no config file.
CWRAPPERS_PROBE=${PKG_PREFIX}/libexec/cwrappers/cc-wrapper

info() { echo ">>> $*"; }
warn() { echo "!!! $*" >&2; }
die() { echo "*** $*" >&2; exit 1; }

need_root() {
	[ "$(id -u)" = "0" ] || die "must run as root (try: su root -c $0)"
}

need_netbsd() {
	[ "$(uname -s)" = "NetBSD" ] || die "this script only runs on NetBSD"
}

need_pkgdir() {
	[ -f "$1/Makefile" ] || die "no pkgsrc package at $1 (set PKGSRC=)"
}

need_gdc() {
	[ -x "$1" ] || die "$1 missing; run the previous stage script first"
}

have_cwrappers() {
	[ -x "$CWRAPPERS_PROBE" ]
}

# Rewrite a file through sed without relying on sed -i semantics.
sed_inplace() {
	_f=$1
	shift
	sed "$@" "$_f" > "$_f.tmp$$" || die "sed failed on $_f"
	cat "$_f.tmp$$" > "$_f"
	rm -f "$_f.tmp$$"
}

# Keep one pristine copy of anything we edit in the pkgsrc tree.
backup_once() {
	[ -f "$1.pristine" ] || cp -p "$1" "$1.pristine"
}

mkconf_option() {
	_pkg=$1
	_opt=$2
	[ -f "$MKCONF" ] || : > "$MKCONF"
	if grep -Eq "^PKG_OPTIONS\.${_pkg}[+:]?=.*${_opt}" "$MKCONF"; then
		info "mk.conf already enables $_opt for $_pkg"
		return 0
	fi
	echo "PKG_OPTIONS.${_pkg}+= ${_opt}" >> "$MKCONF"
	info "mk.conf: enabled $_opt for $_pkg"
}

# LLVM libunwind's headers shadow GCC's own unwind.h and break libgcc.
hide_libunwind() {
	for _h in $UNWIND_HEADERS; do
		if [ -f "${PKG_PREFIX}/include/$_h" ]; then
			mv "${PKG_PREFIX}/include/$_h" "${PKG_PREFIX}/include/$_h.bak"
			info "moved aside ${PKG_PREFIX}/include/$_h"
		fi
	done
}

restore_libunwind() {
	for _h in $UNWIND_HEADERS; do
		if [ -f "${PKG_PREFIX}/include/$_h.bak" ]; then
			mv "${PKG_PREFIX}/include/$_h.bak" "${PKG_PREFIX}/include/$_h"
			info "restored ${PKG_PREFIX}/include/$_h"
		fi
	done
}

# pkgsrc points the bootstrap 'gdc' wrapper at the build compiler (gcc6).
# 0 = repointed, 1 = wrapper dir not created yet, 2 = already correct.
fix_gdc_wrapper() {
	_w=$1/work/.gcc/bin/gdc
	[ -d "$1/work/.gcc/bin" ] || return 1
	if [ -L "$_w" ] && [ "$(readlink "$_w")" = "$2" ]; then
		return 2
	fi
	rm -f "$_w"
	ln -s "$2" "$_w"
	return 0
}

# Build a gcc package whose D frontend needs an earlier GDC. The first make
# is expected to fail at configure ("GDC is required to build d") until the
# wrapper symlink is repointed.
build_with_gdc() {
	_pkgdir=$1
	_bootgdc=$2
	_try=1
	while [ $_try -le 3 ]; do
		info "make in $_pkgdir (attempt $_try)"
		if ( cd "$_pkgdir" && $MAKE ); then
			return 0
		fi
		fix_gdc_wrapper "$_pkgdir" "$_bootgdc"
		case $? in
		0) info "repointed GDC wrapper at $_bootgdc; retrying" ;;
		1) warn "GDC wrapper not created yet; retrying to reach that phase" ;;
		2) die "make failed with the GDC wrapper already correct; read the log above" ;;
		esac
		_try=$((_try + 1))
	done
	die "$_pkgdir still fails after $((_try - 1)) attempts"
}

clean_pkg() {
	need_pkgdir "$1"
	if [ ! -d "$1/work" ]; then
		info "$1 has no work dir, nothing to clean"
		return 0
	fi
	info "make clean in $1"
	( cd "$1" && $MAKE clean ) || die "make clean failed in $1"
}

write_hello() {
	cat > /tmp/hello.d <<'EOF'
import std.stdio;
void main() { writeln("Hello from GDC on NetBSD!"); }
EOF
}

verify_gdc() {
	_gdc=$1
	[ -x "$_gdc" ] || die "$_gdc was not installed"
	"$_gdc" --version || die "$_gdc does not run"
	write_hello
	_out=/tmp/hello.$$
	"$_gdc" /tmp/hello.d -o "$_out" || die "$_gdc cannot compile hello.d"
	"$_out" || die "the binary built by $_gdc does not run"
	rm -f "$_out"
	info "$_gdc works"
}
