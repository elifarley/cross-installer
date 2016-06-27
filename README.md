# cross-installer
A mostly POSIX-compliant set of shell scripts that helps in installing software in multiple linux distros

Useful when creating **Docker** images based on different Linux distributions.

Here's an example of a **Dockerfile** using **Cross Installer**'s *xinstall* command:

    FROM alpine:3.4
    MAINTAINER Elifarley <elifarley@gmail.com>
    ENV \
      BASE_IMAGE=alpine:3.4 \
      LANG=C.UTF-8

    RUN apk --no-cache add ca-certificates curl && \
    curl -fsSL https://raw.githubusercontent.com/elifarley/cross-installer/master/install.sh | sh && \
      xinstall install glibc && \
      xinstall save-image-info && \
      xinstall remove-pkg ca-certificates curl && \
      xinstall cleanup && \
      xinstall meta remove

## Similar Tools
* See [Zero Install](http://0install.net/)
