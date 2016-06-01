CMD_BASE="$(readlink -f $0)" || CMD_BASE="$0"; CMD_BASE="$(dirname $CMD_BASE)"

set -x

prefix="${1:-/usr/local}"; shift

mkdir "$prefix"/cross-installer && tmp="$(mktemp -d)" || return $?

local_archive="$CMD_BASE"/cross-installer.tgz
test -s "$local_archive" && {
  tar -xzf "$CMD_BASE"/cross-installer.tgz -C "$tmp" || { rm -rf "$tmp"; exit 1 ;}

} || which curl >/dev/null 2>&1 && {
  curl -fsSL https://github.com/elifarley/cross-installer/archive/master.tar.gz \
  | tar -xz -C "$tmp" || { rm -rf "$tmp"; exit 1 ;}

}

mv "$tmp"/*/* "$prefix"/cross-installer || { rm -rf "$tmp"; exit 1 ;}
rm -rf "$tmp" || exit $?

ln -sv ../cross-installer/bin/xinstall "$prefix"/bin
