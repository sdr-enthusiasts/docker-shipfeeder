FROM ghcr.io/jvde-github/ais-catcher:edge AS build

FROM ghcr.io/sdr-enthusiasts/docker-baseimage:base

ARG TARGETPLATFORM TARGETOS TARGETARCH

ENV S6_KILL_FINISH_MAXTIME=10000 \
    UPDATE_PLUGINS=true

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -x && \
#
echo "TARGETPLATFORM $TARGETPLATFORM" && \
echo "TARGETOS $TARGETOS" && \
echo "TARGETARCH $TARGETARCH" && \
#
    # define required packages
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    SX_PACKAGES=() && \
    #
    SX_PACKAGES+=(sxfeeder:armhf) && \
    # SX_PACKAGES+=(aiscatcher:armhf) && \
    #
    TEMP_PACKAGES+=(gnupg) && \
    if [ "${TARGETARCH:0:3}" != "arm" ]; then KEPT_PACKAGES+=(qemu-user-static); fi && \
    #
    KEPT_PACKAGES+=(librtlsdr0) && \
    KEPT_PACKAGES+=(libairspy0) && \
    KEPT_PACKAGES+=(libhackrf0) && \
    KEPT_PACKAGES+=(libairspyhf1) && \
    KEPT_PACKAGES+=(libzmq5) && \
    KEPT_PACKAGES+=(libsoxr0) && \
    KEPT_PACKAGES+=(libcurl4) && \
    KEPT_PACKAGES+=(tcpdump) && \
    KEPT_PACKAGES+=(git) && \
    KEPT_PACKAGES+=(nano) && \
    KEPT_PACKAGES+=(libpqxx-dev) && \
    #
    # install packages
    apt-get update && \
    apt-get install -q -o Dpkg::Options::="--force-confnew" -y --no-install-recommends  --no-install-suggests \
        "${KEPT_PACKAGES[@]}" \
        "${TEMP_PACKAGES[@]}" \
        && \
    #
    # install shipxplorer packages
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 1D043681 && \
    echo 'deb https://apt.rb24.com/ bullseye main' > /etc/apt/sources.list.d/rb24.list && \
    #
    if [ "$TARGETPLATFORM" != "linux/arm/v7" ]; then \
        dpkg --add-architecture armhf; \
    fi && \
    #
    apt-get update -q && \
    apt-get install -q -o Dpkg::Options::="--force-confnew" -y --no-install-recommends  --no-install-suggests \
            "${SX_PACKAGES[@]}"; \
    #
    # Do some other stuff
    echo "alias dir=\"ls -alsv\"" >> /root/.bashrc && \
    echo "alias nano=\"nano -l\"" >> /root/.bashrc && \
    #
    # clean up
    if [[ "${#TEMP_PACKAGES[@]}" -gt 0 ]]; then \
        apt-get remove -y "${TEMP_PACKAGES[@]}"; \
    fi && \
    apt-get autoremove -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/*

COPY rootfs/ /

# add AIS-catcher
COPY --from=build /usr/local/bin/AIS-catcher /usr/local/bin/AIS-catcher

# Add Container Version
RUN set -x && \
pushd /tmp && \
    branch="##BRANCH##" && \
    [[ "${branch:0:1}" == "#" ]] && branch="main" || true && \
    git clone --depth=1 -b "$branch" https://github.com/sdr-enthusiasts/docker-shipxplorer.git && \
    cd docker-shipxplorer && \
    echo "$(TZ=UTC date +%Y%m%d-%H%M%S)_$(git rev-parse --short HEAD)_$(git branch --show-current)" > "/.CONTAINER_VERSION" && \
popd && \
rm -rf /tmp/*

# Add healthcheck
HEALTHCHECK --start-period=60s --interval=600s --timeout=200s CMD /healthcheck/healthcheck.sh
