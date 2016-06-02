maven_install_maven3() {
  test $# -ge 2 || {
    echo "Usage: $0 install maven3 <version> <sha1> [<prefix>=/usr/local]"
    return 1
  }

  local version="$1"; shift
  local sha="$1"; shift
  local prefix="${1:-/usr/local}"; test $# -gt 0 && shift

  curl -fsSL http://www-us.apache.org/dist/maven/maven-3/"$version"/binaries/apache-maven-"$version"-bin.tar.gz \
    -o /tmp/maven.tgz && echo "$sha  /tmp/maven.tgz" | sha1sum -wc - && \
    tar -xzf /tmp/maven.tgz -C "$prefix" && rm /tmp/maven.tgz || return $?
  ln -s apache-maven-"$version" "$prefix"/maven-3 && \
  ln -s ../maven-3/bin/mvn ../maven-3/bin/mvnDebug ../maven-3/bin/mvnyjp "$prefix"/bin
}
