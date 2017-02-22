update_pkg_list_apk() {
  apk update
}

update_pkg_list_apt() {
  local aptconfig=/etc/apt/apt.conf.d/local
  test -f "$aptconfig" && grep -q 'Install-Recommends' "$aptconfig" || \
    printf 'APT::Get::Install-Recommends "false";\nDpkg::Options {\n"--force-confdef";\n"--force-confold";\n}' \
    > "$aptconfig"

  apt-get update
}

update_pkg_list_yum() {
  yum update -y
}

add_pkg_apk() {
  local apk_no_cache=''
  test "$(ls -A /var/cache/apk/* 2>/dev/null)" || apk_no_cache="--no-cache"

  local should_update=''

  grep -q 'edge/community' /etc/apk/repositories || {
    echo http://nl.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories && \
    should_update=1
  }

  grep -q 'edge/testing' /etc/apk/repositories || {
    echo http://nl.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
    should_update=1
  }

  test "$should_update" && apk update

  if test $# = 0; then
    apk add $apk_no_cache $APK_PACKAGES;
  else
    apk add $apk_no_cache "$@";
  fi

}

remove_pkg_apk() {
  apk del --purge "$@"
  apk cache clean --purge >/dev/null ||:
}

add_pkg_apt() {
  
  # TODO: call function "dir_not_empty"
  test "$(ls -A /var/lib/apt/lists/* 2>/dev/null)" || main update-pkg-list
  
  if test $# = 0; then
    apt-get install -y --no-install-recommends $APT_PACKAGES
  else
    apt-get install -y --no-install-recommends "$@"
  fi
  
}

remove_pkg_apt() {
  apt-get remove --purge -y "$@" && apt-get autoremove --purge -y
}

add_pkg_yum() {
    if test $# = 0; then
      yum install -y $YUM_PACKAGES
    else
      yum install -y "$@"
    fi
}

remove_pkg_yum() {
  yum remove --setopt=clean_requirements_on_remove=1 -y "$@"
}

pkg_owner_apk() {
  apk info --who-owns "$@"
}

pkg_owner_apt() {
  pkg_owner_dpkg "$@"
}

pkg_owner_dpkg() {
  dpkg -S "$@"
}

pkg_owner_pacman() {
  pacman -Qo "$@"
}

pkg_owner_rpm() {
  rpm -qf "$@"
}

pkg_owner_yum() {
  yum --disablerepo=* whatprovides "$@"
}
