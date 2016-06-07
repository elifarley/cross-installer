install_gradle_debian() {
  _common_install_gradle "$@"
}

install_gradle_alpine() {
  _common_install_gradle "$@" && \
  apk update && apk add libstdc++
}

_common_install_gradle() {
  test $# -ge 2 || {
    echo "Usage: $0 install gradle <version> <sha1> [<prefix>=/usr/local]"
    return 1
  }

  local url_gradle='https://services.gradle.org/distributions/gradle-%s-bin.zip'

  local version="$1"; shift
  local sha="$1"; shift
  local prefix="${1:-/usr/local}"; test $# -gt 0 && shift

  local url="$(printf "$url_gradle" "$version")"
  local archive_path="/tmp/archive"
  curl -fsSL "$url" -o "$archive_path" && \
    echo "$sha  $archive_path" | sha1sum -wc - && \
    unzip "$archive_path" -d "$prefix" && rm "$archive_path" || return
  ln -s gradle-"$version" "$prefix"/gradle && \
  ln -s ../gradle/bin/gradle "$prefix"/bin
}
