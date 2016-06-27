dotdecimal2decimal() { printf "%0${2:-3}u" ${1//./ }; echo ;}

check_sha1() {
  local filepath="$1"; local expected="$2"

  echo "$expected  $filepath" | sha1sum -wc - && return

  local actual="$(sha1sum "$filepath")"
  echo "Actual: ${actual% *}"
  return 1
}

add_androidsdk() {
  test $# -ge 2 || {
    echo "Usage: $0 install androidsdk <version> <sha1> [<prefix>=/usr/local]"
    return 1
  }

  local version="$1"; shift
  local sha="$1"; shift
  local prefix="${1:-/usr/local}"; test $# -gt 0 && shift

  local url_androidsdk
  test $(dotdecimal2decimal "$version") -lt $(dotdecimal2decimal 24.0.0) && \
    url_androidsdk='http://dl-ssl.google.com/android/repository/tools_r%s-linux.zip' || \
    url_androidsdk='https://dl.google.com/android/android-sdk_r%s-linux.tgz'

  local url="$(printf "$url_androidsdk" "$version")"
  local archive_path="/tmp/archive"
  curl -fsSL "$url" -o "$archive_path" && \
    check_sha1 "$archive_path" "$sha" && \
    unzip "$archive_path" -d "$prefix" && rm "$archive_path" || return
}
