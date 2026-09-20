#!/bin/sh
# Prepare /etc/mk.conf and the pkgsrc tree for the whole GDC bootstrap.
# Idempotent: every edit checks for itself first, and each touched pkgsrc file
# is copied to <file>.pristine before the first modification.
set -e

SCRIPTS=$(cd "$(dirname "$0")" && pwd)
REPO=$(dirname "$SCRIPTS")
. "$SCRIPTS/common.sh"

need_netbsd
need_root
need_pkgdir "$GCC10_DIR"
need_pkgdir "$GCC12_DIR"
need_pkgdir "$GCC15_DIR"

avail=$(df -k "$PKGSRC" | awk 'NR == 2 { print $4 }')
if [ "${avail:-0}" -lt 8388608 ]; then
	warn "only $((avail / 1024)) MiB free on $PKGSRC; the three stages want ~8 GiB"
fi

# Add an option to PKG_SUPPORTED_OPTIONS, which always lists gcc-fortran.
supported_option_add() {
	_file=$1
	_opt=$2
	if grep -E "^PKG_SUPPORTED_OPTIONS=" "$_file" | grep -q -- "$_opt"; then
		info "$_file already supports $_opt"
		return 0
	fi
	backup_once "$_file"
	sed_inplace "$_file" -e "/^PKG_SUPPORTED_OPTIONS=/s/gcc-fortran/$_opt gcc-fortran/"
	grep -E "^PKG_SUPPORTED_OPTIONS=" "$_file" | grep -q -- "$_opt" ||
		die "could not add $_opt to PKG_SUPPORTED_OPTIONS in $_file; do it by hand"
	info "$_file: added $_opt to PKG_SUPPORTED_OPTIONS"
}

# The gcc-d block teaches pkgsrc to build the D frontend with an earlier GDC.
append_gcc_d_block() {
	_file=$1
	_bootver=$2
	if grep -q 'Mgcc-d' "$_file"; then
		info "$_file already has a gcc-d block"
		return 0
	fi
	backup_once "$_file"
	cat >> "$_file" <<EOF

# GDC is required to build d, use GDC ${_bootver} as bootstrap compiler
.if !empty(PKG_OPTIONS:Mgcc-d)
LANGS+=		d
GCC_REQD=		${_bootver}
_GCC_VARS+=		GDC
_GCC_GDC=		\${_GCC_DIR}/bin/\${_GCC_BIN_PREFIX}gdc\${GCC_VERSION_SUFFIX}
_ALIASES.GDC=		gdc
.include "../../lang/gcc${_bootver}/buildlink3.mk"
post-tools: \${_GCC_GDC}
.if !target(\${_GCC_GDC})
\${_GCC_GDC}:
	\${RUN}\${MKDIR} \${.TARGET:H}
.    if !empty(COMPILER_USE_SYMLINKS:M[Yy][Ee][Ss])
	\${RUN}\${RM} -f \${.TARGET}
	\${RUN}\${LN} -s \${_GCCBINDIR}/\${.TARGET:T} \${.TARGET}
.    else
	\${RUN}					\\
	(\${ECHO} '#!\${TOOLS_SHELL}';		\\
	 \${ECHO} 'exec \${_GCCBINDIR}/\${.TARGET:T} "\$\$@"';	\\
	) > \${.TARGET}
	\${RUN}\${CHMOD} +x \${.TARGET}
.    endif
.    for _alias_ in \${_ALIASES.\${_var}}
	\${RUN}					\\
	if [ ! -x "\${.TARGET:H}/\${_alias_}" ]; then			\\
		\${LN} -f -s \${.TARGET:T} \${.TARGET:H}/\${_alias_};	\\
	fi
.    endfor
.endif
.endif
EOF
	info "$_file: appended gcc-d block (bootstrap GDC $_bootver)"
}

# BOOT_LDFLAGS uses -static-libgcc but never links libgcc_eh, so the stage1
# link dies on undefined _Unwind_* symbols.
boot_ldflags_fix() {
	_file=$1/Makefile
	if grep -q 'BOOT_LDFLAGS=.*-lgcc_eh' "$_file"; then
		info "$_file already links libgcc_eh"
		return 0
	fi
	grep -q '^BOOT_LDFLAGS=' "$_file" || die "no BOOT_LDFLAGS in $_file"
	backup_once "$_file"
	sed_inplace "$_file" -e '/^BOOT_LDFLAGS=/s/-static-libgcc/-static-libgcc -lgcc_eh/'
	info "$_file: added -lgcc_eh to BOOT_LDFLAGS"
}

info "=== /etc/mk.conf"
if grep -Eq "^MAKE_JOBS[+:]?=" "$MKCONF" 2>/dev/null; then
	info "mk.conf already sets MAKE_JOBS"
else
	jobs=$(sysctl -n hw.ncpu)
	echo "MAKE_JOBS= $jobs" >> "$MKCONF"
	info "mk.conf: MAKE_JOBS= $jobs"
fi
mkconf_option gcc10 gcc-d
mkconf_option gcc12 gcc-d
mkconf_option gcc15 gcc-d

info "=== stage0: lang/gcc10"
supported_option_add "$GCC10_DIR/options.mk" gcc-d
if grep -q 'Mgcc-d' "$GCC10_DIR/options.mk"; then
	info "$GCC10_DIR/options.mk already has a gcc-d block"
else
	backup_once "$GCC10_DIR/options.mk"
	# GCC 10 still has the C++ bootstrap frontend, so no GDC is needed here.
	cat >> "$GCC10_DIR/options.mk" <<'EOF'

.if !empty(PKG_OPTIONS:Mgcc-d)
LANGS+=			d
.endif
EOF
	info "$GCC10_DIR/options.mk: appended gcc-d block"
fi

info "=== stage1: lang/gcc12"
supported_option_add "$GCC12_DIR/options.mk" gcc-d
append_gcc_d_block "$GCC12_DIR/options.mk" 10
boot_ldflags_fix "$GCC12_DIR"

info "=== final stage: lang/gcc15"
supported_option_add "$GCC15_DIR/options.mk" gcc-d
append_gcc_d_block "$GCC15_DIR/options.mk" 12
boot_ldflags_fix "$GCC15_DIR"

# Most of these are upstream in dlang/dmd (#22720); a newer GCC tarball may
# already carry some, in which case drop them here and re-run.
PATCHES_DIR=${PATCHES_DIR:-$REPO/patches/gcc15}

info "=== libphobos patches from $PATCHES_DIR"
mkdir -p "$GCC15_DIR/patches"
backup_once "$GCC15_DIR/distinfo"
for p in "$PATCHES_DIR"/patch-*; do
	cp "$p" "$GCC15_DIR/patches/"
	info "installed $(basename "$p")"
done
( cd "$GCC15_DIR" && $MAKE makepatchsum ) || die "make makepatchsum failed in $GCC15_DIR"

if [ -n "$SKIP_CWRAPPERS" ]; then
	info "=== skipping pkgtools/cwrappers (SKIP_CWRAPPERS set)"
elif [ -x "${PKG_PREFIX}/libexec/cwrappers/config" ]; then
	info "=== pkgtools/cwrappers already installed"
else
	info "=== pkgtools/cwrappers (required by gcc15)"
	( cd "$PKGSRC/pkgtools/cwrappers" && $MAKE install ) ||
		die "cwrappers failed to build"
fi

info "prep done; now run stage0-gcc10.sh, stage1-gcc12.sh, stage2-gcc15.sh"
