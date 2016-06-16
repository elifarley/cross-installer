update_pkg_list_alpine() {
  apk update
}

update_pkg_list_debian() {
  local aptconfig=/etc/apt/apt.conf.d/local
  test -f "$aptconfig" && grep 'Install-Recommends' "$aptconfig" && return 0

  printf 'APT::Get::Install-Recommends "false";\nDpkg::Options {\n"--force-confdef";\n"--force-confold";\n}' \
> "$aptconfig" && apt-get update && apt-get -y dist-upgrade
}

install_pkg_alpine() {
  grep -q 'testing' /etc/apk/repositories || \
    echo http://nl.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories
  test $# = 0 && apk add --no-cache $APK_PACKAGES || apk add --no-cache "$@"
}

remove_pkg_alpine() {
  apk del --purge "$@" || return
  apk apk cache clean --purge || true
}

install_pkg_debian() {
  test $# = 0 && \
    apt-get install -y --no-install-recommends $APTGET_PACKAGES \
    || apt-get install -y --no-install-recommends "$@"
}
