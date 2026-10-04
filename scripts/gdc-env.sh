#!/bin/sh
# Put GDC 15 on PATH. Source this, do not execute it:
#
#     . scripts/gdc-env.sh         # gdc, gdmd and dub only (default)
#     . scripts/gdc-env.sh all     # the whole gcc15 bin directory
#
# Default mode links just the D tools into ~/.gdc15/bin and prepends that.
# 'all' prepends /usr/pkg/gcc15/bin itself, which also puts GCC 15's cc, gcc,
# g++ and cpp ahead of the system ones -- enough to change what pkgsrc and
# configure scripts pick up, so it is not the default.

case $0 in
*gdc-env.sh)
	echo "gdc-env.sh must be sourced, not executed: . $0" >&2
	exit 1
	;;
esac

gdc_env_main() {
	_bin=${PKG_PREFIX:-/usr/pkg}/gcc15/bin

	if [ ! -x "$_bin/gdc" ]; then
		echo "gdc-env.sh: no gdc at $_bin; run stage2-gcc15.sh first" >&2
		return 1
	fi

	# Anything other than 'all' is the safe mode, since a sourced script can
	# inherit the calling shell's positional parameters.
	if [ "$1" = all ]; then
		_dir=$_bin
	else
		_dir=${GDC_ENV_DIR:-$HOME/.gdc15/bin}
		mkdir -p "$_dir" || return 1
		for _t in gdc gdmd dub; do
			[ -x "$_bin/$_t" ] && ln -sf "$_bin/$_t" "$_dir/$_t"
		done
	fi

	case :$PATH: in
	*:"$_dir":*) ;;
	*)
		PATH=$_dir:$PATH
		export PATH
		;;
	esac

	echo "gdc-env.sh: $_dir on PATH ($(gdc --version | head -1))"
}

gdc_env_main "$@"
_gdc_env_rc=$?
unset -f gdc_env_main
unset _bin _dir _t
[ "$_gdc_env_rc" = 0 ]
