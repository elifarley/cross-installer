CMD_BASE="$(readlink -f $0)" || CMD_BASE="$0"; CMD_BASE="$(dirname $CMD_BASE)"

test "$DEBUG" && set -x

prefix="${1:-/usr/local}"

test -L "$prefix"/bin/xinstall && {
  test -z "$FORCE" && {
    ls -Falk "$prefix"/bin/xinstall
    echo "Previous installation exists. Aborting.
You can set env var 'FORCE=1' to force installation."
    exit 1
  }

  rm -rf "$prefix"/cross-installer "$prefix"/bin/xinstall || exit $?
}

mkdir "$prefix"/cross-installer && tmp="$(mktemp -d)" || exit $?

local_archive="$CMD_BASE"/cross-installer.tgz
if test -s "$local_archive" ; then
  tar -xzf "$CMD_BASE"/cross-installer.tgz -C "$tmp" || { rm -rf "$tmp"; exit 1 ;}

elif type curl &>/dev/null ; then
  curl -fsSL https://github.com/elifarley/cross-installer/archive/master.tar.gz \
  | tar -xz -C "$tmp" || { rm -rfv "$tmp"; exit 1 ;}

else
  echo "Unable to download cross-installer." && exit 1
fi

mv "$tmp"/*/* "$prefix"/cross-installer || { rm -rfv "$tmp"; exit 1 ;}
rm -rf "$tmp" || exit $?

ln -sv ../cross-installer/bin/xinstall "$prefix"/bin
