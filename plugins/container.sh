install_base() {
  curl -fsSL https://raw.githubusercontent.com/elifarley/docker-dev-env/master/entry.sh -o /entry.sh && \
  curl -fsSL https://raw.githubusercontent.com/elifarley/docker-dev-env/master/env-vars.sh -o /env-vars.sh && \
  curl -fsSL https://raw.githubusercontent.com/elifarley/docker-dev-env/master/keytool-import-certs.sh -o /keytool-import-certs.sh && \
  chmod +x /*.sh
}

install_tini() {
  test $# = 2 || {
    echo "Usage: $0 install tini <version> <sha1>"
    return 1
  }
  local version="$1"; shift
  local sha="$1"; shift
  local url=https://github.com/krallin/tini/releases/download/"$version"/tini-static
  curl -fsSL "$url" -o /bin/tini || {
    echo "Please check URL '$url'"
    return 1
  }
  chmod +x /bin/tini && echo "$sha  /bin/tini" | sha1sum -wc -
}

install_gosu() {
  test $# = 2 || {
    echo "Usage: $0 install tini <version> <sha1>"
    return 1
  }
  local version="$1"; shift
  local sha="$1"; shift
  curl -fsSL https://github.com/tianon/gosu/releases/download/"$version"/gosu-amd64 -o /bin/gosu && \
    chmod 755 /bin/gosu && echo "$sha  /bin/gosu" | sha1sum -wc -
}
