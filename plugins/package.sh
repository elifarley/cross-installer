update_pkg_list_apk() {
  apk update
}

update_pkg_list_apt() {
  local aptconfig=/etc/apt/apt.conf.d/local
  test -f "$aptconfig" && grep 'Install-Recommends' "$aptconfig" || \
    printf 'APT::Get::Install-Recommends "false";\nDpkg::Options {\n"--force-confdef";\n"--force-confold";\n}' \
    > "$aptconfig"

  apt-get update
}

add_pkg_apk() {
  grep -q 'testing' /etc/apk/repositories || \
    echo http://nl.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories

  local apk_no_cache=''; test "$(ls -A /var/cache/apk/* 2>/dev/null)" || apk_no_cache="--no-cache"
  test $# = 0 && apk add $apk_no_cache $APK_PACKAGES || apk add $apk_no_cache "$@"
}

remove_pkg_apk() {
  apk del --purge "$@" || return
  apk cache clean --purge || echo "Never mind."
}

add_pkg_apt() {
  # TODO: call function "dir_not_empty"
  test "$(ls -A /var/lib/apt/lists/* 2>/dev/null)" || main update-pkg-list
  test $# = 0 && \
    apt-get install -y --no-install-recommends $APT_PACKAGES || \
    apt-get install -y --no-install-recommends "$@"
}

add_pkg_yum() {
    test $# = 0 && \
    yum install -y $YUM_PACKAGES || \
    yum install -y "$@"
}
