add_maven3() {
  test $# -ge 1 || {
    echo "Usage: $0 install maven3 <version> [<prefix>=/usr/local]"
    return 1
  }

  local version="$1"; shift
  local prefix="${1:-/usr/local}"; test $# -gt 0 && shift

  local url_maven3='http://www-us.apache.org/dist/maven/maven-3/%s/binaries/apache-maven-%s-bin.tar.gz'

  local url="$(printf "$url_maven3" "$version" "$version")"
  untar_url --hash-id "maven:$version" --prefix "$prefix" "$url" "$version"

}
