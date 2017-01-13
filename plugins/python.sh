add_python_3_apk() {
# See https://github.com/docker-library/python/blob/ad4706ad7d23ef13472d2ee340aa43f3b9573e3d/3.6/alpine/Dockerfile

# ensure local python is preferred over distribution python
export PATH=/usr/local/bin:"$PATH"

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
export LANG=C.UTF-8

# install ca-certificates so that HTTPS works consistently
# the other runtime dependencies for Python are installed later
main add-pkg ca-certificates

export \
GPG_KEY=0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D \
PYTHON_VERSION=3.6.0

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
export PYTHON_PIP_VERSION=9.0.1

set -ex

main add-pkg --virtual .fetch-deps gnupg openssl tar xz && \
curl -fsSL >python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" && \
curl -fsSL >python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" || return

export GNUPGHOME="$(mktemp -d)"
gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" && \
gpg --batch --verify python.tar.xz.asc python.tar.xz && \
rm -r "$GNUPGHOME" python.tar.xz.asc && \
mkdir -p /usr/src/python && \
tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz && \
rm python.tar.xz || return

main add-pkg --virtual .build-deps \
                bzip2-dev \
		gcc \
		gdbm-dev \
		libc-dev \
		linux-headers \
		make \
		ncurses-dev \
		openssl \
		openssl-dev \
		pax-utils \
		readline-dev \
		sqlite-dev \
		tcl-dev \
		tk \
		tk-dev \
		xz-dev \
		zlib-dev || return

# add build deps before removing fetch deps in case there's overlap \
main remove-pkg .fetch-deps || return

cd /usr/src/python && \
./configure --enable-loadable-sqlite-extensions --enable-shared && \
make -j$(getconf _NPROCESSORS_ONLN) && \
make install || return

# explicit path to "pip3" to ensure distribution-provided "pip3" cannot interfere
if [ ! -e /usr/local/bin/pip3 ]; then
  wget -O /tmp/get-pip.py 'https://bootstrap.pypa.io/get-pip.py' && \
  python3 /tmp/get-pip.py "pip==$PYTHON_PIP_VERSION" && \
  rm /tmp/get-pip.py
fi

# we use "--force-reinstall" for the case where the version of pip we're trying to install is the same as the version bundled with Python
# ("Requirement already up-to-date: pip==8.1.2 in /usr/local/lib/python3.6/site-packages")
# https://github.com/docker-library/python/pull/143#issuecomment-241032683
pip3 install --no-cache-dir --upgrade --force-reinstall "pip==$PYTHON_PIP_VERSION" || return

# then we use "pip list" to ensure we don't have more than one pip version installed
# https://github.com/docker-library/python/pull/100
[ "$(pip list |tac|tac| awk -F '[ ()]+' '$1 == "pip" { print $2; exit }')" = "$PYTHON_PIP_VERSION" ] \
	\
	&& find /usr/local -depth \
		\( \
			\( -type d -a -name test -o -name tests \) \
			-o \
			\( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
		\) -exec rm -rf '{}' + \
	&& runDeps="$( \
		scanelf --needed --nobanner --recursive /usr/local \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| sort -u \
			| xargs -r apk info --installed \
			| sort -u \
	)" \
	&& main add-pkg --virtual .python-rundeps $runDeps \
	&& main remove-pkg .build-deps \
	&& rm -rf /usr/src/python ~/.cache

# make some useful symlinks that are expected to exist
cd /usr/local/bin && {
  [ -e easy_install ] || { ln -s easy_install-* easy_install || return ;}
} && \
ln -s idle3 idle && \
ln -s pydoc3 pydoc && \
ln -s python3 python && \
ln -s python3-config python-config

}
