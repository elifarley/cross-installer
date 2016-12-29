add_golang() {
  test $# -ge 1 || {
    echo "Usage: $0 install golang <version> [<prefix>=/usr/local]"
    return 1
  }

  local version="$1"; shift
  local prefix="${1:-/usr/local}"; test $# -gt 0 && shift

  local url_golang='https://storage.googleapis.com/golang/go%s.linux-amd64.tar.gz'

  local url="$(printf "$url_golang" "$version")"
  untar_url --hash-id "golang:$version" --prefix "$prefix" "$url" "$version"

}
