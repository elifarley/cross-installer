os_version() { (
  test -f /etc/os-release && . /etc/os-release
  local VERSION="$VERSION_ID"
  test -f /etc/debian_version && VERSION="$(cat /etc/debian_version)"
  echo "$PRETTY_NAME [$VERSION]"
) }

# Prints only a word to describe the type of the first argument
# (alias, builtin, function, file)
typeof() {

  # Bash
  type --help >/dev/null 2>&1 || { type -t "$1"; return ;}

  # Ash
  local result="$(type "$1")"
  echo $result | grep -oq 'not found' && return 1
  echo $result | grep -oq alias && result=alias
  result="${result##* }"; test ${result##/*} || result=file
  echo $result

}

hascmd() { for i in "$@"; do typeof "$i" >/dev/null 2>&1 || return $?; done ;}
