meta_remove() {
  local prefix="$(readlink -f "$CMD_BASE"/../..)"
  remove_shell_lib /usr/local/shell-lib
  echo "[meta] Removing cross-installer from prefix '$prefix'..."
  rm -rv "$prefix"/cross-installer* "$prefix"/bin/xinstall && \
  echo "[meta] OK - cross-installer has been removed from prefix '$prefix'."
}
