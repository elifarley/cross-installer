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

  local url="$(printf "$url" "$version")"

  local archive_path="/tmp/archive"; local archive_root
  curl -fsSL "$url" -o "$archive_path" && \
    check_sha1 "$archive_path" "$sha" && \
    archive_root="$(tar --exclude='*/**' -tzf "$archive_path")" && \
    tar -xzf "$archive_path" -C "$prefix" && rm "$archive_path" || return
  archive_root="${archive_root%-$version/}"
  ln -s "$archive_root-$version" "$prefix/$archive_root" || return
  for f in "$prefix/$archive_root"/bin/*; do
    test -f "$f" || continue
    ln -s ../"$archive_root"/bin/"$(basename "$f")" "$prefix"/bin || return
  done
  return 0
}
