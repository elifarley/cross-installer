import_shell_lib() {
  local prefix="${1:-/usr/local}"; test $# -gt 0 && shift
  test "$(ls -A "$prefix"/shell-lib/lib/* 2>/dev/null)" || return 1
  for f in "$prefix"/shell-lib/lib/*; do . "$f"; done
}

install_shell_lib() {
  test "$1" = '--help' && {
    echo "Usage: $0 install shell-lib <version> <sha1> [<prefix>=/usr/local]"
    return 1
  }
  local version="$1"; test $# -gt 0 && shift
  set -- "${version:-master}" "$@"
  untar_url 'https://github.com/elifarley/shell-lib/archive/%s.tar.gz' "$@" && \
  import_shell_lib
}

remove_shell_lib() {
  remove_prefix_aliases /usr/local/shell-lib
}

remove_prefix_aliases() {
  local installation_root="$1"

  echo "Removing '$installation_root' and its aliases from '$(readlink -f "$installation_root"/../bin)'..."
  for f in "$installation_root"/bin/*; do
    test -f "$f" || continue
    rm -fv "$installation_root"/../bin/"$(basename "$f")"
  done
  rm -rfv "$installation_root" "$installation_root"-*
  echo "OK - Removed '$installation_root'."
}

check_sha1() {
  local filepath="$1"; local expected="$2"
  test "$expected" || return 0
  echo "$expected  $filepath" | sha1sum -wc - && return
  local actual="$(sha1sum "$filepath")"; echo "Actual: ${actual% *}"
  return 1
}

untar_url() {
  local url="$1"; test $# -gt 0 && shift
  local version="$1"; test $# -gt 0 && shift
  local sha="$1"; test $# -gt 0 && shift
  local prefix="${1:-/usr/local}"; test $# -gt 0 && shift

  local _force; test "$FORCE" && _force=f
  local url="$(printf "$url" "$version")"

  local archive_path="/tmp/archive"; local archive_root
  curl -fsSL "$url" -o "$archive_path" && \
    check_sha1 "$archive_path" "$sha" && \
    archive_root="$(tar -tzf "$archive_path" | egrep -m1 '[^/]*/$')" && \
    tar -xzf "$archive_path" -C "$prefix" && rm "$archive_path" || return
  archive_root="${archive_root%-$version/}"
  test "$_force" && test -d "$prefix/$archive_root" && rm -rfv "$prefix/$archive_root"
  ln -${_force}s "$archive_root-$version" "$prefix/$archive_root" || return
  for f in "$prefix/$archive_root"/bin/*; do
    test -f "$f" && test "${f%%*.jar}" || continue
    chmod +x "$f" && \
    ln -${_force}s ../"$archive_root"/bin/"$(basename "$f")" "$prefix"/bin || return
  done
  printf "$prefix/$archive_root\n"
}
