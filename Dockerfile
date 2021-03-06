FROM alpine:3.12 AS build

RUN apk add --no-cache msgpack-c ncurses-libs libevent libexecinfo openssl zlib

RUN apk add --no-cache git wget cmake make gcc g++ linux-headers zlib-dev openssl-dev \
		automake autoconf libevent-dev ncurses-dev msgpack-c-dev libexecinfo-dev

# alpine 3.12 provides libssh-0.9.4-r0 and libssh-dev-0.9.4-r0, no need to rebuild
RUN apk add --no-cache libssh-dev

RUN mkdir -p /src/tmate-ssh-server
COPY . /src/tmate-ssh-server

RUN set -ex; \
	cd /src/tmate-ssh-server; \
	./autogen.sh; \
	./configure --prefix=/usr CFLAGS="-D_GNU_SOURCE"; \
	make -j "$(nproc)"; \
	make install

### Minimal run-time image
FROM alpine:3.12

# alpine 3.12 provides libssh-0.9.4-r0 no need to copy from "build"
RUN apk add --no-cache msgpack-c ncurses-libs libevent libexecinfo openssl zlib gdb bash libssh

COPY --from=build /usr/bin/tmate-ssh-server /usr/bin/

# TODO not run as root. Instead, use capabilities.

COPY docker-entrypoint.sh /usr/local/bin

EXPOSE 2200
ENTRYPOINT ["docker-entrypoint.sh"]
