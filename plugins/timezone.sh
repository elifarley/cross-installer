install_timezone_apk() {
  test "$TZ" || { echo "TZ is not set"; return 1 ;}
  apk add --no-cache tzdata || return
  echo "TZ set to '$TZ'"
  echo $TZ > /etc/TZ
  cp -a /usr/share/zoneinfo/"$TZ" /etc/localtime && \
  apk del tzdata
}

install_timezone_apt() {
  test "$TZ" || { echo "TZ is not set"; return 1 ;}
  # locale-gen $LANG && dpkg-reconfigure locales && /usr/sbin/update-locale LANG=$LANG
  echo "TZ set to '$TZ'"
  echo $TZ > /etc/TZ
  rm -f /etc/localtime && ln -s /usr/share/zoneinfo/"$TZ" /etc/localtime
}
