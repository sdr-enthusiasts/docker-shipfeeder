FROM ghcr.io/sdr-enthusiasts/docker-baseimage:base

ARG TARGETARCH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -x && \
    # define required packages
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    SX_PACKAGES=() && \
    #
    SX_PACKAGES+=(sxfeeder) && \
    SX_PACKAGES+=(aiscatcher) && \
    #
    TEMP_PACKAGES+=(gnupg) && \
    TEMP_PACKAGES+=(systemd) && \
    # install packages
    apt-get update && \
    apt-get install -q -o APT::Autoremove::RecommendsImportant=0 -o APT::Autoremove::SuggestsImportant=0 -o Dpkg::Options::="--force-confold" -y --no-install-recommends  --no-install-suggests \
        "${KEPT_PACKAGES[@]}" \
        "${TEMP_PACKAGES[@]}" \
        && \
    #
    if [ "$TARGETARCH" == "arm64" ]; then \
        dpkg --add-architecture armhf && \
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 1D043681 && \
        echo 'deb https://apt.rb24.com/ bullseye main' > /etc/apt/sources.list.d/rb24.list && \
        apt-get update -q && \
        apt-get install -q -o APT::Autoremove::RecommendsImportant=0 -o APT::Autoremove::SuggestsImportant=0 -o Dpkg::Options::="--force-confold" -y --no-install-recommends  --no-install-suggests \
            "${SX_PACKAGES[@]/%/:armhf}"; \
    else \
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 1D043681 && \
        echo 'deb https://apt.rb24.com/ bullseye main' > /etc/apt/sources.list.d/rb24.list && \
        apt-get update -q && \
        apt-get install -q -o APT::Autoremove::RecommendsImportant=0 -o APT::Autoremove::SuggestsImportant=0 -o Dpkg::Options::="--force-confold" -y --no-install-recommends  --no-install-suggests \
            "${SX_PACKAGES[@]}"; \
    fi && \
    #
    # clean up
    if [[ "${#TEMP_PACKAGES[@]}" -gt 0 ]]; then \
        apt-get remove -y "${TEMP_PACKAGES[@]}"; \
    fi && \
    apt-get autoremove -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/* && \

COPY rootfs/ /

# Expose ports
EXPOSE 32088/tcp 30105/tcp

# Add healthcheck
# HEALTHCHECK --start-period=3600s --interval=600s  CMD /healthcheck.sh
