# sdr-enthusiasts/docker-shipfeeder

[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

## What's New

So you came here expecting `docker-shipxplorer`? As of March 15, 2024 (*the Ides of March*!), the `docker-shipxplorer` repo has been renamed to `docker-shipfeeder`. The container can do so much more than just feeding ShipXplorer, and the new name covers the scope of what we're doing much better!

We're still enthusiastic feeders of AIS data to AirNav's ShipXplorer, and the amount of support that company has provided to the community is much appreciated. No changes there!

The newly updated container now also allows you to much easier configure feeding the other aggregators, see the [Feeding AIS Aggregator Services](#feeding-ais-aggregator-services) section!

In adding all these improvements, we didn't forget our current users: the container is fully backwards compatible with the settings and environment variables you are already using. So no change is needed, unless you want to. We're also automatically producing two container images in parallel - they are exactly the same except for their names: `ghcr.io/sdr-enthusiasts/docker-shipfeeder` (new!) and `ghcr.io/sdr-enthusiasts/shipxplorer` (legacy).

If you need help, feel free to chat with us at the Discord server that is linked elsewhere in this Readme.

## Table of Contents

- [sdr-enthusiasts/docker-shipfeeder](#sdr-enthusiastsdocker-shipfeeder)
  - [What's New](#whats-new)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Multi Architecture Support](#multi-architecture-support)
  - [Up-and-Running with Docker Compose](#up-and-running-with-docker-compose)
  - [Runtime Environment Variables](#runtime-environment-variables)
    - [SDR and Receiver Related Variables](#sdr-and-receiver-related-variables)
    - [Website Related Parameters](#website-related-parameters)
  - [Feeding AIS Aggregator Services](#feeding-ais-aggregator-services)
    - [Easy sharing with other services](#easy-sharing-with-other-services)
    - [Exchanging data with `aiscatcher.org`](#exchanging-data-with-aiscatcherorg)
    - [Configuring feeding to ShipXplorer](#configuring-feeding-to-shipxplorer)
      - [Obtaining a ShipXplorer Sharing Key](#obtaining-a-shipxplorer-sharing-key)
      - [Claiming Your ShipXplorer Receiver](#claiming-your-shipxplorer-receiver)
      - [Adding Additional Command-line Parameters to `sxfeeder`](#adding-additional-command-line-parameters-to-sxfeeder)
      - [Workaround for CPU Serial (only needed when feeding ShipXplorer with non-Raspberry Pi systems)](#workaround-for-cpu-serial-only-needed-when-feeding-shipxplorer-with-non-raspberry-pi-systems)
    - [Feeding Additional Services Using UDP](#feeding-additional-services-using-udp)
    - [Feeding Additional Services Using TCP](#feeding-additional-services-using-tcp)
    - [Feeding Additional Services Using HTTP](#feeding-additional-services-using-http)
    - [Sending AIS data to a MQTT broker](#sending-ais-data-to-a-mqtt-broker)
  - [Adding an `About` Page to the AIS-Catcher Website](#adding-an-about-page-to-the-ais-catcher-website)
  - [Logging](#logging)
  - [AIS-Catcher Web Plugin Support and AIS-Catcher Persistency](#ais-catcher-web-plugin-support-and-ais-catcher-persistency)
  - [Additional Statistics Dashboard with Prometheus and Grafana](#additional-statistics-dashboard-with-prometheus-and-grafana)
  - [Configuring 2 SDRs for Reception on Channels AB and CD](#configuring-2-sdrs-for-reception-on-channels-ab-and-cd)
  - [Aggregating multiple instances of the container](#aggregating-multiple-instances-of-the-container)
  - [Hardware requirements](#hardware-requirements)
    - [Working around ShipXplorer issues on Raspberry Pi 5](#working-around-shipxplorer-issues-on-raspberry-pi-5)
  - [Getting Help](#getting-help)
  - [Acknowledgements](#acknowledgements)
  - [License](#license)

Docker container for feeding many AIS aggregators, showing a local map with ships heard, etc. The container uses [AIS-Catcher](https://aiscatcher.org) and also includes [AirNav ShipXplorer](https://www.shipxplorer.com)'s `sxfeeder`. Builds and runs on `arm64`, `armv7/armhf`, and `amd64/x86`.

## Prerequisites

We expect you to have the following:

- a piece of hardware that runs Linux. The prebuilt containers support `armhf`, `arm64`, and `amd64`. Systems with those architectures include Raspberry Pi 3B+, 4, and Linux PCs with Ubuntu.
- a dedicated RTL-SDR dongle that can receive at 160 MHz, with an appropriate antenna
- Docker must be installed on your system. If you don't know how to do that, please read [here](https://github.com/sdr-enthusiasts/docker-install).
- Some basic knowledge on how to use Linux and how to configure docker containers with `docker-compose`.

## Multi Architecture Support

Currently, this image should pull and run on the following architectures:

- `arm32v7`, `armv7l`, `armhf`: ARMv7 32-bit (Odroid HC1/HC2/XU4, RPi 2/3/4 32-bit)
- `arm64`, `aarch64`: ARMv8 64-bit (RPi 4 64-bit OSes)
- `amd64`, `x86_64`: X86 64-bit Linux (Linux PC)

Other architectures (Windows, Mac) are not currently supported, but feel free to see if the container builds and runs for these.
In theory, it should work, but I don't have the time nor inclination to test it.

## Up-and-Running with Docker Compose

You can find these as files here: [`docker-compose.yml` example](https://github.com/sdr-enthusiasts/docker-shipfeeder/blob/main/config-examples/docker-compose.yml.sample); [`.env` example](https://github.com/sdr-enthusiasts/docker-shipfeeder/blob/main/config-examples/.env.sample)

<details>
  <summary>&lt;&dash;&dash; Click the arrow to see the <code>docker-compose.yml</code> and <code>.env</code> examples</summary>

```yaml
services:
  shipfeeder:
    image: ghcr.io/sdr-enthusiasts/docker-shipfeeder
    container_name: shipfeeder
    hostname: shipfeeder
    restart: always
    environment:
#     general parameters:
      - VERBOSE_LOGGING=
#     ais-catcher general and website related parameters
      - AISCATCHER_EXTRA_OPTIONS=${SX_EXTRA_OPTIONS}
      - STATION_NAME=${STATION_NAME}
      - STATION_HISTORY=3600
      - BACKUP_INTERVAL=5
      - FEEDER_LONG=${FEEDER_LONG}
      - FEEDER_LAT=${FEEDER_LAT}
      - SITESHOW=on
      - PROMETHEUS_ENABLE=on
      - REALTIME=on
#     ais-catcher receiver-related parameters
      - RTLSDR_DEVICE_SERIAL=${RTLSDR_DEVICE_SERIAL}
      - RTLSDR_DEVICE_GAIN=${RTLSDR_DEVICE_GAIN}
      - RTLSDR_DEVICE_PPM=${RTLSDR_DEVICE_PPM}
      - RTLSDR_DEVICE_BANDWIDTH=${RTLSDR_DEVICE_BANDWIDTH}
      - AISCATCHER_DECODER_AFC_WIDE=${AISCATCHER_DECODER_AFC_WIDE}
#     aggregrators-related parameters
      - AIRFRAMES_STATION_ID=${AIRFRAMES_STATION_ID}
      - AISCATCHER_FEEDER_KEY=${AISCATCHER_FEEDER_KEY}
      - AISFRIENDS_UDP_PORT=${AISFRIENDS_UDP_PORT}
      - AISHUB_UDP_PORT=${AISHUB_UDP_PORT}
      - APRSFI_FEEDER_KEY=${APRSFI_FEEDER_KEY}
      - BOATBEACON_SHAREDATA=${BOATBEACON_SHAREDATA}
      - HPRADAR_UDP_PORT=${HPRADAR_UDP_PORT}
      - MARINETRAFFIC_UDP_PORT=${MARINETRAFFIC_UDP_PORT}
      - MYSHIPTRACKING_UDP_PORT=${MYSHIPTRACKING_UDP_PORT}
      - RADARVIRTUEL_FEEDER_KEY=${RADARVIRTUEL_FEEDER_KEY}
      - RADARVIRTUEL_STATION_ID=${RADARVIRTUEL_STATION_ID}
      - SDRMAP_STATION_ID=${SDRMAP_STATION_ID}
      - SDRMAP_PASSWORD=${SDRMAP_PASSWORD}
      - SHIPFINDER_SHAREDATA=${SHIPFINDER_SHAREDATA}
      - SHIPPINGEXPLORER_UDP_PORT=${SHIPPINGEXPLORER_UDP_PORT}
      - SHIPXPLORER_SHARING_KEY=${SHIPXPLORER_SHARING_KEY}
      - SHIPXPLORER_SERIAL_NUMBER=${SHIPXPLORER_SERIAL_NUMBER}
      - VESSELFINDER_UDP_PORT=${VESSELFINDER_UDP_PORT}
      - VESSELTRACKER_UDP_PORT=${VESSELTRACKER_UDP_PORT}
      - UDP_FEEDS=${SX_UDP_FEEDS}
#     incoming UDP data related parameters:
      - AISCATCHER_UDP_INPUTS=${AISCATCHER_UDP_INPUTS}
    ports:
      - 90:80
      - 9988:9988/udp
    device_cgroup_rules:
      - 'c 189:* rwm'
    tmpfs:
      - /tmp
    volumes:
      - "/etc/localtime:/etc/localtime:ro"
      - "/etc/timezone:/etc/timezone:ro"
      - "/opt/ais/shipxplorer/data:/data"
      - /dev:/dev:rw
```

Example accompanying `.env` file:

```ini
# ShipFeeder receiver and webpage related parameters:
FEEDER_LAT=xx.xxxxxx
FEEDER_LONG=yy.yyyyyy
RTLSDR_DEVICE_SERIAL=DEVICE-SERIAL
RTLSDR_DEVICE_GAIN=xxx
RTLSDR_DEVICE_PPM=xxx
AISCATCHER_DECODER_AFC_WIDE=on
STATION_NAME=My&nbsp;Station&nbsp;Name
#
# keys and params for aggregators:
# If you aren't feeding a specific aggregator, leave the value EMPTY or remove the parameter
AIRFRAMES_STATION_ID=XX-XXXXXXX-AIS
AISCATCHER_FEEDER_KEY=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AISFRIENDS_UDP_PORT=xxxxx
AISHUB_UDP_PORT=xxxxx
APRSFI_FEEDER_KEY=xxxxxxx
APRSFI_STATION_ID=MYCALL
BOATBEACON_SHAREDATA=true
HPRADAR_UDP_PORT=xxxxx
MARINETRAFFIC_UDP_PORT=xxxxx
MYSHIPTRACKING_UDP_PORT=xxxxx
RADARVIRTUEL_FEEDER_KEY=xxxxxxxxx
RADARVIRTUEL_STATION_ID=xx
SDRMAP_STATION_ID=xxxxxx
SDRMAP_PASSWORD=xxxxxx
SHIPFINDER_SHAREDATA=true
SHIPPINGEXPLORER_UDP_PORT=xxxxx
SHIPXPLORER_SHARING_KEY=xxxxxxxxxxxxxxxxxxx
SHIPXPLORER_SERIAL_NUMBER=SXTRPI00xxxx
VESSELFINDER_UDP_PORT=xxxxx
VESSELTRACKER_UDP_PORT=xxxxx
```

Replace these parameters with the appropriate values.
You can use `rtl_test` to see which devices and device serials are connected to your machine, or `rtl_eeprom` to rename the device's serial number.

</details>

## Runtime Environment Variables

### SDR and Receiver Related Variables

| Environment Variable | Purpose | Default value if omitted |
| ---------------------- | ------------------------------- | --- |
| `RTLSDR_DEVICE_SERIAL` | Serial Number of your RTL-SDR dongle | Empty |
| `RTLSDR_DEVICE_GAIN` | SDR device gain. Can also be set to `auto` | `33` |
| `RTLSDR_DEVICE_PPM`| PPM deviation of your RTLSDR device | Empty |
| `RTLSDR_DEVICE_RTLAGC` | Switches AGC on/off for your RTL-SDR device. | `on` |
| `RTLSDR_DEVICE_BANDWIDTH` | Channel bandwitdh of the receiver | `192K` |
| `RTLSDR_DEVICE_BIASTEE` | If set to `on`, `1`, `enabled`, or `yes`, the bias-tee function of the RTLSDR device will be switched on | Empty |
| `AISCATCHER_CHANNELS` | Channels flag for `ais-catcher`. Set to `AB` (receive on channel AB, default value if omitted), `CD` (receive on channel CD), or `CD AB` (receive on channel CD but forward this data to aggregators saying it's channel AB; this can be used to send channels CD data to aggregators that can't handle CD data) | Empty (`AB`) |
| `AISCATCHER_DECODER_MODEL` | Decoder model number for `ais-catcher` | `2` |
| `AISCATCHER_DECODER_AFC_WIDE` | `-go AFC_WIDE` flag for `ais-catcher`. Recommended to set to `on` | `on` |
| `AISCATCHER_DECODER_FP_DS` | `-go PF_DS` flag for `ais-catcher` | Empty |
| `AISCATCHER_DECODER_PS_EMA` | `-go PS_EMA` flag for `ais-catcher` | Empty |
| `AISCATCHER_DECODER_SOXR` | `-go SOXR` flag for `ais-catcher` | Empty |
| `AISCATCHER_DECODER_SRC` | `-go SRC` flag for `ais-catcher` | Empty |
| `AISCATCHER_DECODER_DROOP` | `-go DROOP` flag for `ais-catcher` | Empty |
| `AISCATCHER_UDP_INPUTS` | List of comma-separated `hostname:port[:CHANNELS]` combinations of external NMEA AIS data UDP sources. You can use this to feed data between `ais-catcher` or `docker-shipfeeder` instances. The `:CHANNELS` part is optional; channels `AB` will be used if omitted. Examples</br>`AISCATCHER_UDP_INPUTS=remotehost-1:9999:AB CD,remotehost-2:9988,remotehost-3:8899:CD` | Empty |
| `AISCATCHER_EXTRA_OPTIONS` | Any additional command line parameters you wish to pass to `AIS-catcher` | Empty |
| `VERBOSE_LOGGING` | If set to a number (`0`-`5`), it's set to the `AIS-Catcher -o` [log level](https://github.com/jvde-github/AIS-catcher#usage). Any other non-empty string corresponds to `-o 2`. To silence `AIS-Catcher` logs, set this parameter to `0` | `2` (a summary is displayed every 60 seconds) |

If the `AISCATCHER_CHANNELS` and `AISCATCHER_DECODER_XXXX` parameters listed above are set, they will overwrite/remove any equivalent parameters added to the `AISCATCHER_EXTRA_OPTIONS` parameter.

### Website Related Parameters

| Environment Variable | Purpose | Default value if omitted |
| ---------------------- | ------------------------------- | --- |
| `DISABLE_WEBSITE` | If set to `true`, the AIS-Catcher website will not be available | `false` |
| `PLUGINS_FILE` | Load a file with custom javascript to override parts of the WebUI or add functionality. Map the container `/data` to any volume, place your file inside the volume and put the file name here (for example `plugins.js`) | Empty |
| `STYLES_FILE` | Load a file with custom css to override parts of the WebUI or add functionality. Map the container `/data` to any volume, place your file inside the volume and put the file name here (for example `styles.css`) | Empty |
| `STATION_NAME` | Station name displayed on stat web page | Empty |
| `STATION_LINK` | URL displayed on stat web page | Empty |
| `STATION_HISTORY` | The number of seconds of history that will be shown in plots on the website | `3600` |
| `BACKUP_INTERVAL` | How often a file with data statistics (`aiscatcher.bin`) will be written to disk, in minutes. In order to make this backup persistent, make sure to map the `/data` directory to a volume. See example in [docker-compose.yml](docker-compose.yml). | `2880` (=2 days) |
| `BACKUP_RETENTION_TIME` | Time (in days) to keep backups of `aiscatcher.bin` and plugins. Note - this only affects the backups of these files and not the active `aiscatcher.bin` or active plugins. | `30` (days) |
| `SITESHOW` | If set to anything non-empty, it will show the station location as a dot on the map | Empty |
| `FEEDER_LAT` or `SXFEEDER_LAT` (legacy) | Used for calculating ship distances on web page | Empty |
| `FEEDER_LONG` or `SXFEEDER_LON` (legacy) | Used for calculating ship distances on web page | Empty |
| `DISABLE_SHOWLASTMSG` | If set to `true`, the last NMEA0182 message option won't be shown on the website. | Empty, i.e., last message option is available on website |
| `PLUGIN_UPDATE_INTERVAL` | Optional. Set this to the interval (for example, `30` (secs) or `5m` or `6h` or `3d`) to check the AIS-Catcher github repository for updates to the JavaScript web plugins. Set to `0` or `off` to disable checking. | `6h` |
| `REFRESHRATE` | Refresh rate of the vessel data on the web page, in msec. Larger numbers reduce web page traffic, which can become an issue if there are a large number of vessels | `2500` (msec) |
| `DISABLE_GEOJSON` | If set to `true`, no GeoJSON info will be available at <http://my_aiscatcher/geojson>. This is normally enabled if the parameter is omitted. | Empty (GeoJSON is default enabled) |
| `ADSB_CONNECTOR` | Connect to a `beast` or `raw1090` ADS-B data stream to show aircraft on your AIS map. Format: `ADSB_CONNECTOR=<format>,<hostname>,<port>` where `<format>` is either `beast` or `raw1090`, and the `<hostname>` and `<port>` parameters indicate where the data comes from | Empty |

## Feeding AIS Aggregator Services

### Easy sharing with other services

This table shows which parameters to set and how to obtain credentials for a number of well-known AIS aggregators. A (partial) list of these aggregators and instructions on how to get a key or port for them can be found [here](https://docs.google.com/spreadsheets/d/1W9uuuS2tGHcNENm7Ze3M1UPl2u8tMZv2N_bID6x060Y/edit?usp=sharing)

 | Name | Parameter | Default IP/DNS/URL | Feeding protocol:<br>UDP/TCP/HTTP/Other | How to register for a key or ID |
 | ---- | --------- | ------------------ | --------------------------------------- | ------------------------------- |
 | ADSB-Network (RadarVirtuel) | `RADARVIRTUEL_FEEDER_KEY` (optional, value is `lourd` if omitted)<br>`RADARVIRTUEL_STATION_ID` | [https://ais.adsbnetwork.com/ingester/insert/$RADARVIRTUEL_FEEDER_KEY](https://ais.adsbnetwork.com/ingester/insert/$RADARVIRTUEL_FEEDER_KEY) | HTTP | Email <support@adsbnetwork.com> with your request to join. If you receive an `ais-catcher` string like this: `-H http://ais.adsbnetwork.com/ingester/insert/lourd ID xx INTERVAL 5 RESPONSE off`, then simply set `RADARVIRTUEL_STATION_ID` to `xx` and omit or leave blank the `RADARVIRTUEL_FEEDER_KEY` parameter |
 | Airframes | `AIRFRAMES_STATION_ID` | [http://feed.airframes.io:5599](http://feed.airframes.io:5599) | HTTP | No signup needed. `AIRFRAMES_STATION_ID` is a self-chosen ID that has the form of `II-STATIONNAME-AIS`, where `II` are the initials of the owner's name, and `STATIONNAME` is a self-chosen station name (A-Z, 0-9 only please) |
 | AIS-Catcher | `AISCATCHER_SHAREDATA=true`<br>`AISCATCHER_FEEDER_KEY` | | Other | See [Exchanging data with `aiscatcher.org`](#exchanging-data-with-aiscatcherorg) [https://aiscatcher.org/#join](https://aiscatcher.org/#join). In the future, AISCatcher may provide you with an optional UUID that you can set in `AISCATCHER_FEEDER_KEY` |
 | AIS Friends | `AISFRIENDS_UDP_PORT` | `ais.aisfriends.com` | UDP | Sign up at [AIS Friends](https://www.aisfriends.com/register) to receive a dedicated UDP port by email |
 | AISHub | `AISHUB_UDP_PORT` | [data.aishub.net](http://data.aishub.net) | UDP | [https://www.aishub.net/join-us](https://www.aishub.net/join-us) |
 | [APRS.fi](http://APRS.fi) | `APRSFI_FEEDER_KEY`<br>`APRSFI_STATION_ID` | [http://aprs.fi/jsonais/post/$APRS_FEEDER_KEY](http://aprs.fi/jsonais/post/$APRS_FEEDER_KEY) | HTTP | Get AIS Password (`APRSFI_FEEDER_KEY`) at [https://aprs.fi/?c=account](https://aprs.fi/?c=account). Use your Ham Radio callsign for `APRSFI_STATION_ID`. Both fields are mandatory. |
 | BoatBeacon (aka Pocket Mariner)| `BOATBEACON_SHAREDATA=true` or<br/> `BOATBEACON_UDP_PORT` or<br/> `BOATBEACON_TCP_PORT` | [boatbeaconapp.com:5322](http://boatbeaconapp.com:5322) | UDP / TCP | [https://pocketmariner.com/ais-ship-tracking/cover-your-area/set-up-and-ais-shore-station/](https://pocketmariner.com/ais-ship-tracking/cover-your-area/set-up-and-ais-shore-station/) - set `BOATBEACON_SHAREDATA=true` to feed without any key or assigned port, or set your assigned UDP or TCP port in the respective parameter |
 | HPRadar | `HPRADAR_UDP_PORT` | [aisfeed.hpradar.com](http://aisfeed.hpradar.com) | UDP | |
 | MarineTraffic | `MARINETRAFFIC_UDP_PORT` or<br/>`MARINETRAFFIC_TCP_PORT` | 5.9.207.224 | UDP / TCP | [https://www.marinetraffic.com/en/join-us/cover-your-area](https://www.marinetraffic.com/en/join-us/cover-your-area) Please use either the UDP option or the TCP option as instructed by MarineTraffic, but don't use both! |
 | MyShipTracking | `MYSHIPTRACKING_UDP_PORT` or<br/>`MYSHIPTRACKING_TCP_PORT` | 178.162.215.175 | UDP / TCP | [https://www.myshiptracking.com/help-center/contributors/add-your-station](https://www.myshiptracking.com/help-center/contributors/add-your-station) By default, you should use UDP to feed, unless you are specifically asked to use TCP by the company. Do not use both! |
 | SDRMap | `SDRMAP_STATION_ID`<br />`SDRMAP_PASSWORD` | [https://ais.feed.sdrmap.org/](https://ais.feed.sdrmap.org/) | HTTP | See here for instructions to get your STATION_ID and PASSWORD: <https://github.com/sdrmap/docs/wiki/2.1-Feeding#request-api-credentials> |
 | ShipFinder | `SHIPFINDER_SHAREDATA=true` | [ais.shipfinder.co.uk:4001](http://ais.shipfinder.co.uk:4001/) | UDP | [https://shipfinder.co/about/coverage/](https://shipfinder.co/about/coverage/) |
 | ShippingExplorer | `SHIPPINGEXPLORER_UDP_PORT` or<br/>`SHIPPINGEXPLORER_TCP_PORT` | 144.76.54.111 | UDP or TCP | Request UDP port at [https://www.shippingexplorer.net/en/contact](https://www.shippingexplorer.net/en/contact) By default, you should use UDP to feed, unless you are specifically asked to use TCP by the company. Do not use both! |
 | ShipXplorer | `SHIPXPLORER_SHARING_KEY` or `SHARING_KEY` (legacy)<br>`SHIPXPLORER_SERIAL_NUMBER` or `SERIAL_NUMBER` (legacy) | | Other | See [Obtaining a ShipXplorer Sharing Key](#obtaining-a-shipxplorer-sharing-key) |
 | ShipXplorer (alt. config with UDP) | `SHIPXPLORER_UDP_PORT` | hub.shipxplorer.com| UDP | Alternative way to feed ShipXplorer via UDP instead of via a Sharing Key. Please use one or the other, but not both! Sign up at [https://www.shipxplorer.com/addcoverage](https://www.shipxplorer.com/addcoverage) and select "I want to share with: NMEA over UDP" |
 | VesselFinder | `VESSELFINDER_UDP_PORT` or<br/>`VESSELFINDER_TCP_PORT` | [ais.vesselfinder.com](http://ais.vesselfinder.com) | UDP / TCP | [https://stations.vesselfinder.com/become-partner](https://stations.vesselfinder.com/become-partner) By default, you should use UDP to feed, unless you are specifically asked to use TCP by the company. Do not use both! |
 | VesselTracker | `VESSELTRACKER_UDP_PORT` or<br/>`VESSELTRACKER_TCP_PORT` | 83.220.137.136 | UDP or TCP| [https://www.vesseltracker.com/en/static/antenna-partner.html](https://www.vesseltracker.com/en/static/antenna-partner.html) By default, you should use UDP to feed, unless you are specifically asked to use TCP by the company |

Note: for all parameters `SERVICE_UDP_PORT` (and similarly for `SERVICE_TCP_PORT` where supported), you may use one of the following formats:

- `- SERVICE_UDP_PORT=1234` --> use UDP port 1234
- `- SERVICE_UDP_PORT=hostname:1234` or `- SERVICE_UDP_PORT=ip_addr:1234` --> use the hostname or ip address instead of the one indicated in the table, and UDP port 1234

For services that do not need any UDP ports or credentials, you can simply set `- SERVICE_SHAREDATA=true`. However, if you want to use a non-default port and/or hostname/ip, you can set also `SERVICE_UDP_PORT` (as shown above) for that service. Order of preference:

- if `SERVICE_UDP_PORT` is defined --> use this UDP port regardless of the value of `SERVICE_SHAREDATA`
- if `SERVICE_SHAREDATA` is set to `true` and `SERVICE_UDP_PORT` is not defined --> use the default UDP port to feed `SERVICE`
- if `SERVICE_TCP_PORT` is defined --> use this TCP port in addition to any UDP port (or `SHAREDATA` setting). Warning - this may cause duplicate feeding to the aggregator

We decided to allow parallel feeding to UDP and TCP ports because some aggregators have asked our users to do this temporarily for testing. However, the user should take caution not to feed duplicate data to any aggregator unless the aggregator specifically requested this for testing purposes.

### Exchanging data with `aiscatcher.org`

[aiscatcher.org](https://aiscatcher.org) is an exchange of AIS NMEA data. If you share your data with this server, you automatically receive data about other ships in return. **We recommend to switch this on for an optimal viewing experience.**
You can enable it by simply adding the following to the environment section of your `shipfeeder` service section in `docker-compose.yml`. Note that the `AISCATCHER_SHAREKEY` parameter is optional and will be ignored for now, pending implementation of this feature by AIS-Catcher.

```yaml
- AISCATCHER_SHAREDATA=true
- AISCATCHER_SHAREKEY=xxxxxxxx
```

### Configuring feeding to ShipXplorer

#### Obtaining a ShipXplorer Sharing Key

**ATTENTION** Raspberry Pi 5 users (only) should read [Working around ShipXplorer issues on Raspberry Pi 5](#working-around-shipxplorer-issues-on-raspberry-pi-5) before proceeding!

First-time users should obtain a ShipXplorer sharing key.
In order to obtain a ShipXplorer sharing key, on the first run of the container, it will generate a sharing key and print this to the container log. If you can't find it, you can also copy and paste this command:

```bash
timeout 180s docker run \
    --rm \
    -it \
    --entrypoint /usr/bin/get-creds \
    ghcr.io/sdr-enthusiasts/docker-shipfeeder:latest
```

This will run the container for 3 minutes, allowing a sharing key to be generated.
Shortly after, you will see something like this:

```text
WARNING: SHARING_KEY or SERIAL_NUMBER environment variable was not set!
Please make sure you note down the keys generated and update your docker-compose.yml with these values.
Set environment var SHARING_KEY to the new key displayed below - this is the long hex number
Set environment var SERIAL_NUMBER to the Serial Number displayed below - this is the SXTRPIxxxxxx string
They must be set for this container to run.
Please set it and restart the container.

[2022-11-01 19:48:19]  Your new key is f1xxxxxxxxxxxxxxxxxxxxxxxx57 and Serial Number (SN) is SXTRPIxxxxxx.
Please save this key for future use. You will have to know this key to link this receiver to your account
in https://www.shipxplorer.com/. This key is also saved in configuration file (/etc/sxfeeder.ini)
```

You can wait for the 3 minutes to pass, or you can press CTRL-C now to finish.
Take a note of the Sharing Key (`f1...57` - yours will be a different number) and the Serial Number (`SXTRPIxxxxxx`), and add these to the `SHIPXPLORER_SHARING_KEY` and `SHIPXPLORER_SERIAL_NUMBER` parameters of your `docker-compose.yml` file.

If you're not a first time user and are migrating from another installation, you can retrieve your sharing key by doing this:

- SSH onto your existing receiver and run the command `cat /etc/sxfeeder.ini`

The `key` and `sn` lines show your current credentials

#### Claiming Your ShipXplorer Receiver

Once your container is up and running, you should claim your receiver.

1. Go to <https://www.shipxplorer.com>
2. Create an account or sign in
3. Claim your receiver by visiting <https://www.shipxplorer.com/addcoverage> and following the instructions

Note - you will need your `SHARING_KEY` and the location of your feeder (coordinates or pick on map). As of now, it appears that you don't need your SN or Public IP address.

#### Adding Additional Command-line Parameters to `sxfeeder`

`sxfeeder` is the binary component that is used to feed data to ShipXplorer. Normally, you don't have to interact with it, but exceptional circumstances may arise where you would like to add additional command line parameters to this program. You can do so, by adding them as follows:

| Environment Variable | Purpose | Default value if omitted |
| --- | --- | --- |
| `SXFEEDER_EXTRA_OPTIONS` | Any additional command line parameters you wish to pass to `sxfeeder` | Empty |

#### Workaround for CPU Serial (only needed when feeding ShipXplorer with non-Raspberry Pi systems)

The `sxfeeder` binary effectively greps for `serial\t\t:` in your `/proc/cpuinfo` file, to determine the RPi's serial number.

For systems that don't have a CPU serial number in `/proc/cpuinfo`, we can "fudge" this by generating a replacement `cpuinfo` file with a random serial number. To do this, copy and paste the following on your host machine:

```bash
sudo mkdir -m777 -p /opt/shipfeeder/cpuinfo
sudo install -m 666 /proc/cpuinfo /opt/shipfeeder/cpuinfo/
echo -e "serial\t\t: $(hexdump -n 8 -e '4/4 "%08X" 1 "\n"' /dev/urandom | tr '[:upper:]' '[:lower:]')" >> /opt/shipfeeder/cpuinfo/cpuinfo
```

You can now map this file into your container:

- If using docker run, simply add `-v /opt/shipfeeder/cpuinfo/cpuinfo:/proc/cpuinfo` to your command.
- If using docker-compose, add the following to the `volumes:` section of your shipfeeder container definition:

```yaml
  - /opt/shipfeeder/cpuinfo/cpuinfo:/proc/cpuinfo
```

### Feeding Additional Services Using UDP

If you want to feed and additional AIS aggregator that uses a hostname/UDP port that is not listed above, then simply add a comma separated list of hostnames/ip addresses and UDP ports to the `UDP_FEEDS` parameter. Format: `UDP_FEEDS=domain1.com:port1[:params],domain2,com:port2[:params],...`

For example:

```yaml
- UDP_FEEDS=1.2.3.4:9999,ais.aggregator.org:1234
```

### Feeding Additional Services Using TCP

If you want to feed and additional AIS aggregator that uses a hostname/TCP port that is not listed above, then simply add a comma separated list of hostnames/ip addresses and UDP ports to the `TCP_FEEDS` parameter. Format: `TCP_FEEDS=domain1.com:port1[:params],domain2,com:port2[:params],...`

For example:

```yaml
- TCP_FEEDS=1.2.3.4:8888,ais.aggregator.org:4321
```

### Feeding Additional Services Using HTTP

To feed additional AIS aggregators that are not listed above using HTTP, you first need to create an AIS feeder account at that service. They will provide you with a URL and any additional parameters you need to configure AIS-Catcher. For example:

```yaml
- AISCATCHER_EXTRA_OPTIONS=-H http://1.2.3.4/test ID my_station_name INTERVAL 30 RESPONSE off
```

Note: if you want to feed multiple HTTP aggregators, you can simply append each feeder string to the `AISCATCHER_EXTRA_OPTIONS` variable with a space in between them. For example:

```yaml
- AISCATCHER_EXTRA_OPTIONS=-H http://5.6.7.8/test/post/aBcDeFgHiJkL ID MYSTATION PROTOCOL aprs INTERVAL 30 RESPONSE off -H http://1.2.3.4/test ID my_station_name INTERVAL 30 RESPONSE off JSON on
```

### Sending AIS data to a MQTT broker

Shipfeeder supports sending AIS data to a MQTT broker. This is done by setting the MQTT broker's URL in the `AISCATCHER_MQTT_URL` parameter, and (optionally) adding values to the parameters listed below.

| Environment Variable | Purpose | Default value if omitted |
| --- | --- | --- |
| `AISCATCHER_MQTT_URL` | MQTT Broker's URL. This often has the format of `mqtt://username:password@ipaddress:1883`. When left empty, MQTT is disabled. Note - the `ipaddress` can be an IP Address or hostname that is resolved by the container. When using IP addresses, avoid using internal IP addresses like `128.0.0.1` because they point at the container itself. Instead, if your MQTT broker runs on your host system, use the IP address that is rendered when you do `hostname -I \| awk '{print $1}'` on the command line | Empty |
| `AISCATCHER_MQTT_CLIENT_ID` | (Optional) `CLIENT_ID` value that is passed to the MQTT Broker. For example, `aiscatcher`. | Empty |
| `AISCATCHER_MQTT_QOS` | (Optional) QOS (Quality of Service) value that is passed to the MQTT Broker. For example, `0`. | Empty |
| `AISCATCHER_MQTT_TOPIC` | (Optional) MQTT Topic that is passed to the MQTT Broker. For example, `data/ais`. | Empty |
| `AISCATCHER_MQTT_MSGFORMAT` | (Optional) Message Format indicator for the messages passed to the MQTT Broker. The following values are supported: `NMEA`, `NMEA_TAG`, `FULL`, `JSON_NMEA`, `JSON_SPARSE` `JSON_FULL` | `JSON_FULL` |

Note - if you want to configure ShipFeeder to *receive* AIS data from a MQTT broker, you can do this by adding (for example) the following to the `AISCATCHER_EXTRA_OPTIONS` parameter:

```yaml
AISCATCHER_EXTRA_OPTIONS=-t mqtt://hostname:port -gt TOPIC data/ais USERNAME admin PASSWORD password
```

## Adding an `About` Page to the AIS-Catcher Website

You can add an About page to the AIS-Catcher Website by placing a file called `about.md` in the `/data` directory of the container. If you mapped this directory to a volume as shown in the example, the file as seen from the host system would be `/opt/ais/shipfeeder/about.md`.
You can format the text in this file using [Markdown](https://www.markdownguide.org/cheat-sheet/).

## Logging

- All processes are logged to the container's stdout, and can be viewed with `docker logs [-f] container`.

## AIS-Catcher Web Plugin Support and AIS-Catcher Persistency

We recommend mapping a volume (as shown in the sample `docker-compose.yml` file in this repo) to the `/data` directory. This will ensure that AIS-Catcher data will persist across restarts and container recreation.

Web Plugins for AIS-Catcher can be placed in the `/data/plugins` directory.

## Additional Statistics Dashboard with Prometheus and Grafana

See [this readme](README-grafana.md) for information on how to set up and configure a Grafana stats dashboard for use with shipfeeder.
Make sure to set this parameter to enable Prometheus data for the container:

| Environment Variable | Purpose | Default value if omitted |
| --- | --- | --- |
| `PROMETHEUS_ENABLE` | If set to `true`, enables Prometheus data at `/metrics` on the webserver. | Empty (disabled) |

## Configuring 2 SDRs for Reception on Channels AB and CD

If you want `shipfeeder` to use 2 SDRs to listen to AIS Channels AB and CD at the same time, you can do the following

- Configure your first SDR (for use with channels AB) via the "normal" [`RTLSDR_DEVICE_XXXX` parameters](#sdr-and-receiver-related-variables)
- Configure the second SDR using the `AISCATCHER_EXTRA_OPTIONS` parameter as follows (replace `SDR2-SERIAL` with the Serial Number of your second SDR):

```yaml
- AISCATCHER_EXTRA_OPTIONS=-d SDR2-SERIAL -p 2 -a 192K -c CD -gr tuner auto rtlagc ON -v 60
```

- Subsequently, you can also add separate web pages for each SDR individually. The "normal" web interface on port `80` will show the combined receivers, while the following adds new web interfaces on ports `81` for your Channels AB receiver, and on port `82` for your Channels CD receiver. You can add this to the end of the `AISCATCHER_EXTRA_OPTIONS` parameter, replacing `SDR1_SERIAL` and `SDR2_SERIAL` with the two serial IDs of the SDRs, and adjusting the other parameters as appropriate:

```yaml
- AISCATCHER_EXTRA_OPTIONS=... -N 81 GROUPS_IN 1 STATION SDR1-SERIAL FILE /data/aiscatcher-ab.bin PLUGIN_DIR /data/plugins BACKUP 5 HISTORY 3600 STATION_LINK https://my.ais-station.com LAT xx.xxxx LON yy.yyyy SHARE_LOC on MESSAGE on REALTIME on -N 82 GROUPS_IN 2 STATION SDR2_SERIAL FILE /data/aiscatcher-cd.bin PLUGIN_DIR /data/plugins BACKUP 5 HISTORY 3600 STATION_LINK https://my.ais-station.com LAT xx.xxxx LON yy.yyyy SHARE_LOC on MESSAGE on REALTIME on
```

## Aggregating multiple instances of the container

Sometimes it's convenient to aggregate the data of multiple instances of the container into a single one, and then feed the AIS aggregators from this "central" instance. An example of this is when you have a SDR receiving from channels AB in one instance, and a SDR receiving from channels CD in a separate instance on another machine. (If you have both SDRs on the same machine, you can use a single container instance for both of them as described above). In our case, you'd want to send the data from channels CD to the instance that receives channels AB, and then use that machine to disperse the data to the various services, show its webpage, etc.

Do the following. We are assuming that the hostname/container name for the instance receiving channels AB is `shipfeeder_ab` and the hostname/container name for the instance receiving channels CD is `shipfeeder_cd`. Your names may vary.

- In the section of the `docker-compose.yml` file for `shipfeeder_cd`, make sure to add the following to the `UDP_FEEDS` parameter. Make sure that you replace `target_machine` with the IP or hostname of the machine where `shipfeeder_ab` runs:

```yaml
    - UDP_FEEDS=.....;target_machine:9988
```

- In the section of the `docker-compose.yml` file for `shipfeeder_ab`, make sure to add the following to the `AISCATCHER_UDP_INPUTS` parameter. (DO NOT USE `localhost` or `127.0.0.1` - that won't work):

```yaml
    - AISCATCHER_UDP_INPUTS=shipfeeder_cd:9988:AB CD
```

- In addition, to the same section of the `docker-compose.yml` file for `shipfeeder_cd`, make sure to forward the UPD port to the container:

```yaml
    ports:
      [...]
      - 9988:9988/udp
```

Once you have done this, and after you recreate the containers, the `shipfeeder_cd` instance will now forward its data to `shipfeeder_ab`, and `shipfeeder_ab` will aggregate this data, display it on the AIS-Catcher map and tables, and forward it to any service you may have configured for it.

## Hardware requirements

AIS data is transmitted in the 160 MHz band, for which you'd need a suitable antenna. Note -- ADSB/UAT antennas will definitely not work!
You would need a RTL-SDR dongle, potentially with an LNA, and potentially with a filter. The filter must be dedicated to the 160 MHz band. Dongles with built-in filters for the ADSB or UAT bands won't work.
Last - the software will run on a Raspberry Pi 3B+ or 4, with Raspberry Pi OS, Ubuntu, or a similar Debian-based operating system. It will also run on X86 (Linux PC) systems with Ubuntu. The prebuilt Docker container will work on `armhf`/`arm64` (`aarch64`) /`x86_64` (`amd64`) architectures. You may be able to build containers for other systems, but for that you're on your own.

### Working around ShipXplorer issues on Raspberry Pi 5

If you use ShipXplorer as recommended in [Configuring feeding to ShipXplorer](#configuring-feeding-to-shipxplorer), the container internally uses a binary called `sxfeeder` to send data to the ShipXplorer service. This binary is provided as closed-source by AirNav (the company that operates ShipXplorer) and is only available in `armhf` (32-bits) format using 4kb kernel pages. This will work well on Raspberry Pi 3B+, 4B, and other ARM-based systems that use either 32-bits or 64-bits Debian Linux with a 4kb kernel page size.

Debian Linux for Raspberry Pi 5 uses by default a kernel with 16kb page sizes, and this is not compatible with the `sxfeeder` binary. You will see this in your container logs:

```text
2024-05-23T23:15:48.998327000Z [2024-05-24 01:15:48.998][sxfeeder] Starting: /usr/bin/sxfeeder
2024-05-23T23:15:49.003069000Z [2024-05-24 01:15:49.002][sxfeeder] FATAL: sxfeeder cannot be run natively, and QEMU is not available. You cannot use this container
2024-05-23T23:15:49.004680000Z [2024-05-24 01:15:49.004][sxfeeder] FATAL: on this system / architecture. Feel free to file an issue at https://github.com/sdr-enthusiasts/docker-shipxplorer/issues
2024-05-23T23:15:49.006086000Z [2024-05-24 01:15:49.005][sxfeeder] FATAL: Cannot initiate feeder to ShipXplorer.
```

You can check your kernel page size with this command: `getconf PAGE_SIZE` . If the value returned is 4096, then all is good. If it is something else (for example 16384 for 16kb page size), you will need to implement one of the following work-arounds. You should implement either of them; it's not necessary to implement both:

- Add the following to `/boot/firmware/config.txt` (Debian 12 Bookworm or later) or `/boot/config.txt` (Debian 11 Bullseye or earlier) to use a kernel with page size of 4kb. This will make CPU use across your Raspberry Pi 5 slightly less efficient, but it will solve the issue for many software packages that have [the same issue](https://github.com/raspberrypi/bookworm-feedback/issues/107). After changing this, you must reboot your system for it to take effect:

  ```config
  kernel=kernel8.img
  ```

- Feed ShipXplorer with UDP instead of with a Sharing Key. To do this:
  - Browse to [https://www.shipxplorer.com/addcoverage](https://www.shipxplorer.com/addcoverage) and select "*I want to share with: NMEA over UDP*"
  - Follow the instructions until you are issued a hostname and UDP port number
  - set this environment variable in your `docker-compose.yml` file: `SHIPXPLORER_UDP_PORT=portnumber` (replace `portnumber` with the UDP port you were assigned) and remove `SHIPXPLORER_SHARING_KEY` and/or `SHARING_KEY` from your configuration
  - recreate and restart the container with `docker compose up -d`

## Getting Help

You can [log an issue](https://github.com/sdr-enthusiasts/docker-shipfeeder/issues) on the project's GitHub.

I also have a [Discord channel](https://discord.gg/sTf9uYF), feel free to [join](https://discord.gg/sTf9uYF) and converse.

## Acknowledgements

This effort wouldn't exist without much help and advice of the following individuals:

- [JvdE-Github](https://github.com/jvde-github/ais-catcher), who created the excellent `ais-catcher` package which forms the basis of this container
- [Wiedehopf](https://github.com/wiedehopf) without whose advice we'd all still live in the stone age
- [John Norrbin](https://github.com/Johnex) for his ideas, testing, feature requests, more testing, nagging, pushing, prodding, and overall efforts to make this a high quality container and for the USB "hotplug" configuration
- The community at the [SDR-Enthusiasts Discord Server](https://discord.gg/sTf9uYF) for helping out, testing, asking questions, and generally driving to make this a better productn
- [Pete](https://pliw.co.uk/ais) who provided access and major help testing new features

## License

Copyright (C) 2022-2024, Ramon F. Kolb (kx1t)

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
