#!/usr/bin/env sh

test "$DEBUG" && set -x
export IMAGE_INFO_FILE="$HOME"/docker-image.info

main() {
  local cmd="$1"; shift
  case "$cmd" in
    update-pkg-list)
      update_pkg_list "$@"
      ;;
    install-pkg)
      install_pkg "$@"
      ;;
    install)
      install "$@"
      ;;
    install-base)
      install_base "$@"
      ;;
    save-image-info)
      save_image_info "$@"
      ;;
    configure)
      configure "$@"
      ;;
    add-user)
      add_user "$@"
      ;;
    cleanup)
      cleanup "$@"
      ;;
    *)
      invalid_cmd "$cmd" "$@"
  esac
}

invalid_cmd() {
  echo "Usage: $0 update-pkg-list|install-base|install-pkg|install|save-image-info|configure|add-user|cleanup"
}

os_version() { (
  test -f /etc/os-release && . /etc/os-release
  local VERSION="$VERSION_ID"
  test -f /etc/debian_version && VERSION="$(cat /etc/debian_version)"
  echo "$PRETTY_NAME [$VERSION]"
) }

save_image_info() {
  local first_time=''
  test -f "$IMAGE_INFO_FILE" && printf -- '---\n\n' >> "$IMAGE_INFO_FILE" || first_time=1
  printf 'Build date: %s %s\n' "$(date +'%F %T.%N')" "$(date +%Z)" >> "$IMAGE_INFO_FILE"
  printf "Base image: $BASE_IMAGE\n" >> "$IMAGE_INFO_FILE"
  test "$first_time" && printf '%s\n(%s)\n' "$(os_version)" "$(uname -rsv)" >> "$IMAGE_INFO_FILE"
  return 0
}

update_pkg_list() {

  os_version | grep Alpine && {
    update_pkg_list_alpine "$@" || return $?
    return 0
  }

  os_version | grep Debian && {
    update_pkg_list_debian "$@" || return $?
    return 0
  }

  os_version && return 1

}

update_pkg_list_alpine() {
  apk update
}

install() {
  local arg="$1"; shift
  case "$arg" in
    timezone)
      install_timezone "$@"
      ;;
    tini)
      install_tini "$@"
      ;;
    gosu)
      install_gosu "$@"
      ;;
    maven-3)
      install_maven_3 "$@"
      ;;
    *)
      invalid_cmd "$arg" "$@"
  esac
}

install_base() {
  curl -fsSL https://raw.githubusercontent.com/elifarley/docker-dev-env/master/entry.sh -o /entry.sh || return $?
  curl -fsSL https://raw.githubusercontent.com/elifarley/docker-dev-env/master/env-vars.sh -o /env-vars.sh || return $?
  chmod +x /*.sh || return $?
}

install_tini() {
  test $# = 2 || {
    echo "Usage: $0 install tini <version> <sha1>"
    return 1
  }
  local version="$1"; shift
  local sha="$1"; shift
  curl -fsSL https://github.com/krallin/tini/releases/download/"$version"/tini-static -o /bin/tini && \
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

install_maven_3() {

  test $# -ge 2 || {
    echo "Usage: $0 install maven-3 <version> <sha1> [<prefix>=/usr/local]"
    return 1
  }

  local version="$1"; shift
  local sha="$1"; shift
  local prefix="${1:-/usr/local}"; shift

  curl -fsSL http://www-us.apache.org/dist/maven/maven-3/"$version"/binaries/apache-maven-"$version"-bin.tar.gz \
    -o /tmp/maven.tgz && echo "$sha  /tmp/maven.tgz" | sha1sum -wc - && \
    tar -xzf /tmp/maven.tgz -C "$prefix" && rm /tmp/maven.tgz || return $?
  ln -s apache-maven-"$version" "$prefix"/maven-3 && \
  ln -s ../maven-3/bin/mvn ../maven-3/bin/mvnDebug ../maven-3/bin/mvnyjp "$prefix"/bin

}

install_timezone() {
  test "$TZ" || {
    echo "TZ is not set"
    return 1
  }
  os_version | grep Alpine && {
    install_timezone_alpine "$@" || return $?
    return 0
  }
  os_version | grep Debian && {
    install_timezone_debian "$@" || return $?
    return 0
  }
  os_version && return 1
}

install_timezone_alpine() {
  apk add --no-cache tzdata || return $?
  echo "TZ set to '$TZ'"
  echo $TZ > /etc/TZ
  cp -a /usr/share/zoneinfo/"$TZ" /etc/localtime || return $?
  apk del tzdata
}

install_pkg() {
  os_version | grep Alpine && {
    install_pkg_alpine "$@" || return $?
    return 0
  }
  os_version | grep Debian && {
    install_pkg_debian "$@" || return $? 
    return 0
  }
  os_version && return 1
}

install_pkg_alpine() {
  grep -q 'testing' /etc/apk/repositories || \
    echo http://nl.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories
  apk add --no-cache "$@"
}

configure() {
  local arg="$1"; shift
  case "$arg" in
    sshd)
      configure_sshd "$@"
      ;;
    *)
      invalid_cmd "$arg" "$@"
  esac
}

configure_sshd() {
  os_version | grep Alpine && {
    configure_sshd_alpine "$@" || return $?
    return 0
  }
  os_version | grep Debian && {
    configure_sshd_debian "$@" || return $? 
    return 0
  }
  os_version && return 1
}

configure_sshd_alpine() {
  sed -e '/Port/d;/UsePrivilegeSeparation/d;/PermitRootLogin/d;/PermitUserEnvironment/d;/UsePAM/d;/UseDNS/d;/PasswordAuthentication/d;/ChallengeResponseAuthentication/d;/Banner/d;/PrintMotd/d;/PrintLastLog/d' \
    /etc/ssh/sshd_config > /etc/ssh/sshd_config.tmp || return $?
  printf "\nPort 2200\nUsePrivilegeSeparation no\nPermitRootLogin no\nPasswordAuthentication no\nChallengeResponseAuthentication no\nPermitUserEnvironment yes\nUseDNS no\nPrintMotd no\n\n#---\n" \
    > /etc/ssh/sshd_config || return $?
  cat /etc/ssh/sshd_config.tmp >> /etc/ssh/sshd_config || return $?
  rm /etc/ssh/sshd_config.tmp || return $?
  cp -a /etc/ssh /etc/ssh.cache
}

add_user() {

  os_version | grep Alpine && \
    add_user_alpine "$@" && return $?

  os_version | grep Debian && \
    add_user_debian "$@" && return $?

  os_version && return 1

}

add_user_alpine() {
  local user="$1"; shift

  adduser -D -h "$HOME" -s /bin/bash "$user" || return $?
  # Disable sudo: echo 'auth requisite  pam_deny.so' > /etc/pam.d/su
  { getent group "sudo" || addgroup -S sudo ;} || return $?
  printf '%sudo   ALL=(ALL:ALL) ALL\n' >> /etc/sudoers || return $?
  gpasswd -a "$user" sudo || return $?
  printf "$user ALL=(ALL) NOPASSWD: ALL\n" >> /etc/sudoers || return $?
  mkdir -p "$HOME"/.ssh || return $?
  chmod go-w "$HOME" || return $?
  chmod 700 "$HOME"/.ssh

  chown -R "$user:$user" "$HOME"
}

cleanup() {

  rm -rf /var/tmp/* /tmp/* || return $?

  os_version | grep Alpine && {
    cleanup_alpine "$@" || return $?
    return 0
  }

  os_version | grep Debian && {
    cleanup_debian "$@" || return $?
    return 0
  }

}

cleanup_alpine() {
  rm -rf /var/cache/apk/*
}

main "$@"
