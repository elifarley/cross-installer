install_base() {
  curl -fsSL https://raw.githubusercontent.com/elifarley/docker-dev-env/master/entry.sh -o /entry.sh && \
  curl -fsSL https://raw.githubusercontent.com/elifarley/docker-dev-env/master/env-vars.sh -o /env-vars.sh && \
  curl -fsSL https://raw.githubusercontent.com/elifarley/docker-dev-env/master/keytool-import-certs.sh -o /keytool-import-certs.sh && \
  chmod +x /*.sh
}
