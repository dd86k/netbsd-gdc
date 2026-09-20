#!/bin/sh
# Post-install: gdmd (DMD-flag wrapper) and DUB, both into /usr/pkg/gcc15/bin.
# Needs network access. Override the DUB release with DUB_VERSION=1.41.0.
set -e

SCRIPTS=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPTS/common.sh"

DUB_VERSION=${DUB_VERSION:-1.41.0}
WORKDIR=${WORKDIR:-${TMPDIR:-/tmp}/netbsd-gdc-post}
GCC15_BIN=${PKG_PREFIX}/gcc15/bin
PERL=${PKG_PREFIX}/bin/perl

need_netbsd
need_root
need_gdc "$GDC15"
[ -x "$PERL" ] || die "$PERL missing; build lang/perl5 from pkgsrc first"

fetch_to() {
	if [ -x "${PKG_PREFIX}/bin/curl" ]; then
		"${PKG_PREFIX}/bin/curl" -fL -o "$1" "$2"
	else
		ftp -o "$1" "$2"
	fi
}

mkdir -p "$WORKDIR"
cd "$WORKDIR"

info "=== gdmd"
fetch_to gdmd-repo.tar.gz \
	https://github.com/D-Programming-GDC/gdmd/archive/refs/heads/master.tar.gz
rm -rf gdmd-master
tar xzf gdmd-repo.tar.gz
cp gdmd-master/dmd-script "$GCC15_BIN/gdmd"
chmod +x "$GCC15_BIN/gdmd"
# pkgsrc perl lives in /usr/pkg/bin, not /usr/bin.
sed_inplace "$GCC15_BIN/gdmd" -e "1s|^#!.*perl|#!$PERL|"
"$GCC15_BIN/gdmd" --version || die "gdmd does not run"

write_hello
"$GCC15_BIN/gdmd" /tmp/hello.d -of/tmp/hello_gdmd.$$ || die "gdmd cannot compile hello.d"
/tmp/hello_gdmd.$$ || die "the binary built by gdmd does not run"
rm -f /tmp/hello_gdmd.$$

info "=== libcurl (DUB dependency)"
if [ -f "${PKG_PREFIX}/lib/libcurl.so" ]; then
	info "libcurl already installed"
else
	( cd "$PKGSRC/www/curl" && $MAKE install ) || die "www/curl failed to build"
fi

info "=== DUB $DUB_VERSION"
cd "$WORKDIR"
fetch_to "dub-v${DUB_VERSION}.tar.gz" \
	"https://github.com/dlang/dub/archive/refs/tags/v${DUB_VERSION}.tar.gz"
rm -rf "dub-${DUB_VERSION}"
tar xzf "dub-v${DUB_VERSION}.tar.gz"
cd "dub-${DUB_VERSION}"

mkdir -p source/dub bin
cat > source/dub/version_.d <<EOF
module dub.version_;
enum dubVersion = "v${DUB_VERSION}";
EOF

# build.sh needs bash, which NetBSD does not ship; drive gdmd directly.
if [ ! -f build-files.txt ]; then
	find source -name '*.d' > build-files.txt
	info "build-files.txt absent in this release; generated from source/"
fi

"$GCC15_BIN/gdmd" \
	-of"bin/dub" -I"source" \
	-version=DubUseCurl -version=DubApplication \
	-g -O -w \
	-L-lcurl -L-L"${PKG_PREFIX}/lib" -L-R"${PKG_PREFIX}/lib" \
	@build-files.txt || die "DUB failed to build"

cp bin/dub "$GCC15_BIN/dub"
"$GCC15_BIN/dub" --version || die "dub does not run"

info "post-install done; add $GCC15_BIN to PATH to use gdmd and dub"
