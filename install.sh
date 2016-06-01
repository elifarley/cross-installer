CMD_BASE="$(readlink -f $0)" || CMD_BASE="$0"; CMD_BASE="$(dirname $CMD_BASE)"

set -x

prefix="${1:-/usr/local}"

mkdir "$prefix"/cross-installer && tmp="$(mktemp -d)" || return $?

local_archive="$CMD_BASE"/cross-installer.tgz

if test -s "$local_archive" ; then
  tar -xzf "$CMD_BASE"/cross-installer.tgz -C "$tmp" || { rm -rf "$tmp"; exit 1 ;}

elif which curl >/dev/null 2>&1 ; then
  curl -fsSL https://github.com/elifarley/cross-installer/archive/master.tar.gz \
  | tar -xz -C "$tmp" || { rm -rf "$tmp"; exit 1 ;}

fi

mv "$tmp"/*/* "$prefix"/cross-installer || { rm -rf "$tmp"; exit 1 ;}
rm -rf "$tmp" || exit $?

ln -sv ../cross-installer/bin/xinstall "$prefix"/bin
