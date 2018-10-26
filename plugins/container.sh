IMAGE_BUILD_LOG_FILE=image-build.log
test -d "$HOME" -a "$HOME" != / && IMAGE_BUILD_LOG_FILE="$HOME"/"$IMAGE_BUILD_LOG_FILE" || IMAGE_BUILD_LOG_FILE=/etc/"$IMAGE_BUILD_LOG_FILE"
export IMAGE_BUILD_LOG_FILE

save_image_info() {
  local first_time=''
  touch "$IMAGE_BUILD_LOG_FILE" || { echo "Unable to write to '$IMAGE_BUILD_LOG_FILE'"; return 1 ;}
  test -s "$IMAGE_BUILD_LOG_FILE" && printf -- '---\n\n' >> "$IMAGE_BUILD_LOG_FILE" || first_time=1
  printf 'Build date: %s %s\n' "$(date +'%F %T.%N')" "$(date +%Z)" >> "$IMAGE_BUILD_LOG_FILE"
  printf "Base image: $BASE_IMAGE\n" >> "$IMAGE_BUILD_LOG_FILE"
  test "$first_time" && {
    printf '%s\n(%s)\n' "$(os_version)" "$(uname -rsv)" >> "$IMAGE_BUILD_LOG_FILE"
    chmod -w "$IMAGE_BUILD_LOG_FILE"
  }
  return 0
}

add_entrypoint() {
  local url_entrypoint='https://github.com/elifarley/container-entrypoint/archive/%s.tar.gz'

  local version='master'
  local url="$(printf "$url_entrypoint" "$version")"
  untar_url "$url" "$version"
}

configure_sshd_apk() {
  sed -e '/Port/d;/UsePrivilegeSeparation/d;/PermitRootLogin/d;/PermitUserEnvironment/d;/UsePAM/d;/UseDNS/d;/PasswordAuthentication/d;/ChallengeResponseAuthentication/d;/Banner/d;/PrintMotd/d;/PrintLastLog/d' \
    /etc/ssh/sshd_config > /etc/ssh/sshd_config.tmp || return
  printf "\nPort 2200\nPermitRootLogin no\nPasswordAuthentication no\nChallengeResponseAuthentication no\nPermitUserEnvironment yes\nUseDNS no\nPrintMotd no\n\n#---\n" \
    > /etc/ssh/sshd_config || return
  cat /etc/ssh/sshd_config.tmp >> /etc/ssh/sshd_config || return
  rm /etc/ssh/sshd_config.tmp || return
  cp -a /etc/ssh /etc/ssh.cache
}

configure_sshd_apt() {
  sed -e '/Port/d;/UsePrivilegeSeparation/d;/PermitRootLogin/d;/PermitUserEnvironment/d;/UsePAM/d;/PasswordAuthentication/d;/ChallengeResponseAuthentication/d;/Banner/d' /etc/ssh/sshd_config > /etc/ssh/sshd_config.tmp || return
  printf "\nPort 2200\nPermitRootLogin no\nUsePAM no\nPasswordAuthentication no\nChallengeResponseAuthentication no\nPermitUserEnvironment yes\n\n#---\n" > /etc/ssh/sshd_config || return
  cat /etc/ssh/sshd_config.tmp >> /etc/ssh/sshd_config && rm /etc/ssh/sshd_config.tmp && \
  cp -a /etc/ssh /etc/ssh.cache
}

configure_rsyslog() {
  mkdir -p /var/spool/rsyslog && \
  cat >/etc/rsyslog.conf <<-'EOF'
$ModLoad imuxsock # provides support for local system logging

# See http://www.rsyslog.com/doc/v8-stable/configuration/templates.html
template(name="def" type="list") {
  property(name="timegenerated" dateFormat="rfc3339")
  constant(value=" ")
  property(name="syslogtag")
  property(name="pri")
  property(name="msg" spifno1stsp="on" )
  property(name="msg" droplastlf="on" )
  constant(value="\n")
}

$ActionFileDefaultTemplate def

$FileOwner root
$FileGroup adm
$FileCreateMode 0640
$DirCreateMode 0755
$Umask 0022

# Where to place spool and state files
$WorkDirectory /var/spool/rsyslog

$IncludeConfig /etc/rsyslog.d/*.conf

# Check config syntax on startup and abort if unclean (default off)
$AbortOnUncleanConfig on

# Reduce repeating messages (default off)
$RepeatedMsgReduction on

cron.info /dev/null
cron.notice /dev/console
*.*;cron.none;mail.none;authpriv.none       /dev/console

EOF
}

add_user_apk() {
  local user="$1"; shift

  adduser -D -h "$HOME" -s /bin/bash "$user" || return
  # Disable sudo: echo 'auth requisite  pam_deny.so' > /etc/pam.d/su
  { getent group "sudo" || addgroup -S sudo ;} || return
  printf '%sudo   ALL=(ALL:ALL) ALL\n' >> /etc/sudoers || return
  hascmd gpasswd || main add-pkg shadow
  gpasswd -a "$user" sudo || return
  printf "$user ALL=(ALL) NOPASSWD: ALL\n" >> /etc/sudoers || return

  test -c /dev/console && ln -s /dev/console "$HOME/$user.log"

  mkdir -p "$HOME"/.ssh && \
  chmod go-w "$HOME" && \
  chmod 700 "$HOME"/.ssh && \
  chown -R "$user:$user" "$HOME"
}

add_user_apt() {
  local user="$1"; shift

  adduser --disabled-password --home "$HOME" --shell /bin/bash --gecos "" "$user" || return
  gpasswd -a "$user" sudo || return
  printf "$user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers || return

  test -c /dev/console && ln -s /dev/console "$HOME/$user.log"

  mkdir -p $HOME/.ssh && \
  chmod go-w $HOME && \
  chmod 700 $HOME/.ssh && \
  chown -R "$user:$user" "$HOME"
}

add_tini() {
  test $# -ge 1 || {
    echo "Usage: $0 add tini <version>"
    return 1
  }
  local version="$1"
  local url=https://github.com/krallin/tini/releases/download/"$version"/tini-static-amd64
  curl -fsSL "$url" -o /bin/tini || {
    echo "Please check URL '$url'"
    return 1
  }
  check_hash /bin/tini "tini:$version" && \
  chmod +x /bin/tini && \
  tini -h
}

add_gosu() {
  test $# -ge 1 || {
    echo "Usage: $0 add gosu <version>"
    return 1
  }
  local version="$1"
  curl -fsSL https://github.com/tianon/gosu/releases/download/"$version"/gosu-amd64 -o /bin/gosu && \
  check_hash /bin/gosu "gosu:$version" && \
  chmod +x /bin/gosu && \
  gosu >/dev/null "$(id -nu)" id -nu
}

cleanup() {

  if hascmd apk ; then
    cleanup_apk "$@" || return
  elif hascmd apt-get ; then
    cleanup_apt "$@" || return
  fi

  local rm_items='/tmp/* /var/tmp/* /var/backups/* /usr/share/man /usr/share/doc'
  echo Removing $rm_items
  rm -rf $rm_items

}

cleanup_apk() {
  rm -rf /var/cache/apk/*
}

cleanup_apt() {
  #ENV RM_APT='/var/lib/apt /var/lib/dpkg'
  apt-get autoremove --purge -y && apt-get clean && \
  rm -rf /var/lib/apt/lists/* /etc/cron.daily/{apt,passwd}
}
