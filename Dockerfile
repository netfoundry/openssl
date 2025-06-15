FROM ubuntu:22.04 AS openssl-fips

ARG TARGETARCH

ENV OPENSSL_BUILD_VERSION="3.1.2"
ENV OPENSSL_BUILD_TARBALL_SHA256="a0ce69b8b97ea6a35b96875235aa453b966ba3cba8af2de23657d8b6767d6539"
ENV OPENSSL_BUILD_CONFIGURE_ARGS="enable-fips"

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
      curl \
      build-essential \
      && rm -rf /var/lib/apt/lists/*

RUN mkdir /usr/local/src/openssl
WORKDIR /usr/local/src/openssl

RUN curl -L -o openssl.tar.gz https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_BUILD_VERSION}/openssl-${OPENSSL_BUILD_VERSION}.tar.gz \
    && echo "${OPENSSL_BUILD_TARBALL_SHA256}  openssl.tar.gz" | sha256sum --quiet -c - \
    && tar --strip-components=1 -xzf openssl.tar.gz

# disable the aflag test because it doesn't work on qemu (aka cross compile, see https://github.com/openssl/openssl/pull/17945)
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
            ./Configure ${OPENSSL_BUILD_CONFIGURE_ARGS} && make -j"$(nproc)" && make -j"$(nproc)" test TESTS="-test_afalg"; \
      else \
            ./Configure ${OPENSSL_BUILD_CONFIGURE_ARGS} && make -j"$(nproc)"; \
      fi

RUN make install_sw install_ssldirs install_fips
