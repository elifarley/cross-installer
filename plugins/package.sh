update_pkg_list_apk() {
  apk update
}

update_pkg_list_apt() {
  local aptconfig=/etc/apt/apt.conf.d/local
  test -f "$aptconfig" && grep 'Install-Recommends' "$aptconfig" && return 0

  printf 'APT::Get::Install-Recommends "false";\nDpkg::Options {\n"--force-confdef";\n"--force-confold";\n}' \
> "$aptconfig" && apt-get update && apt-get -y dist-upgrade
}

add_pkg_apk() {
  grep -q 'testing' /etc/apk/repositories || \
    echo http://nl.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories
  test $# = 0 && apk add --no-cache $APK_PACKAGES || apk add --no-cache "$@"
}

remove_pkg_apk() {
  apk del --purge "$@" || return
  apk cache clean --purge || true
}

add_pkg_apt() {
  test $# = 0 && \
    apt-get install -y --no-install-recommends $APT_PACKAGES || \
    apt-get install -y --no-install-recommends "$@"
}

add_pkg_yum() {
    test $# = 0 && \
    yum install -y $YUM_PACKAGES || \
    yum install -y "$@"
}
