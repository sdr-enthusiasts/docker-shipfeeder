# syntax=docker/dockerfile:1
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
    #KEPT_PACKAGES+=(librtlsdr0) && \
    KEPT_PACKAGES+=(libairspy0) && \
    KEPT_PACKAGES+=(libhackrf0) && \
    KEPT_PACKAGES+=(libzmq5) && \
    KEPT_PACKAGES+=(libsoxr0) && \
    # KEPT_PACKAGES+=(libcurl4) && \
    KEPT_PACKAGES+=(libssl3) && \
    KEPT_PACKAGES+=(tcpdump) && \
    KEPT_PACKAGES+=(git) && \
    KEPT_PACKAGES+=(nano) && \
    KEPT_PACKAGES+=(libpqxx-dev) && \
    KEPT_PACKAGES+=(lsb-release) && \
    KEPT_PACKAGES+=(sqlite3) && \
    TEMP_PACKAGES+=(git) && \
    TEMP_PACKAGES+=(make) && \
    TEMP_PACKAGES+=(gcc) && \
    TEMP_PACKAGES+=(g++) && \
    TEMP_PACKAGES+=(cmake) && \
    TEMP_PACKAGES+=(pkg-config)
    #
    # install packages
    apt-get update && \
    apt-get install -q -o Dpkg::Options::="--force-confnew" -y --no-install-recommends  --no-install-suggests \
    "${KEPT_PACKAGES[@]}" \
    "${TEMP_PACKAGES[@]}" \
    && \
    #
    # install shipfeeder packages
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 1D043681 && \
    echo 'deb https://apt.rb24.com/ bullseye main' > /etc/apt/sources.list.d/rb24.list && \
    #
    if [ "$TARGETPLATFORM" != "linux/arm/v7" ]; then \
    dpkg --add-architecture armhf; \
    fi && \
    #
    # The lines below would allow the apt.rb24.com repo to be access insecurely. We were using this because their key had expired
    # However, as of 1-feb-2024, the repo was updated to contain again a valid key so this is no longer needed. Leaving it in as an archifact for future reference.
    # apt-get update -q --allow-insecure-repositories && \
    # apt-get install -q -o Dpkg::Options::="--force-confnew" -y --no-install-recommends  --no-install-suggests --allow-unauthenticated \
    #         "${SX_PACKAGES[@]}"; \
    apt-get update -q && \
    apt-get install -q -o Dpkg::Options::="--force-confnew" -y --no-install-recommends  --no-install-suggests \
    "${SX_PACKAGES[@]}" && \
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
    # delete unnecessary qemu binaries to save lots of space
    { find /usr/bin -regex '/usr/bin/qemu-.*-static'  | grep -v qemu-arm-static | xargs rm -vf {} || true; } && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/*

# add AIS-catcher and libairspyhf
RUN \
    --mount=type=bind,from=build,source=/,target=/build/ \
    set -x && \
    cp -v /build/usr/local/bin/AIS-catcher /usr/local/bin/AIS-catcher && \
    find /build | grep libairspyhf | cut -d/ --complement -f1,2 | xargs --replace cp -a -T -v /build/'{}' /'{}' && \
    ldconfig && \
    true

RUN cd /root/; git clone https://github.com/hydrasdr/rfone_host.git --depth 1
RUN cd /root/rfone_host/libhydrasdr && mkdir build && cd build && cmake .. -DCMAKE_INSTALL_PREFIX=/usr && make && make install && ldconfig
RUN rm -rf /root/rfone_host

# Add Container Version
RUN set -x && \
    pushd /tmp && \
    branch="##BRANCH##" && \
    { [[ "${branch:0:1}" == "#" ]] && branch="main" || true; } && \
    git clone --depth=1 -b "$branch" https://github.com/sdr-enthusiasts/docker-shipfeeder.git && \
    cd docker-shipfeeder && \
    echo "$(TZ=UTC date +%Y%m%d-%H%M%S)_$(git rev-parse --short HEAD)_$(git branch --show-current)" > "/.CONTAINER_VERSION" && \
    popd && \
    rm -rf /tmp/*

COPY rootfs/ /

# Add healthcheck
HEALTHCHECK --start-period=60s --interval=120s --timeout=100s CMD /healthcheck/healthcheck.sh
