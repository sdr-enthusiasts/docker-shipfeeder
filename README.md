# sdr-enthusiasts/docker-shipfeeder

[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

- [sdr-enthusiasts/docker-shipfeeder](#sdr-enthusiastsdocker-shipfeeder)
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
    - [Feeding Additional Services Using HTTP](#feeding-additional-services-using-http)
  - [Adding an `About` Page to the AIS-Catcher Website](#adding-an-about-page-to-the-ais-catcher-website)
  - [Logging](#logging)
  - [AIS-Catcher Web Plugin Support and AIS-Catcher Persistency](#ais-catcher-web-plugin-support-and-ais-catcher-persistency)
  - [Additional Statistics Dashboard with Prometheus and Grafana](#additional-statistics-dashboard-with-prometheus-and-grafana)
  - [Configuring 2 SDRs for Reception on Channels AB and CD](#configuring-2-sdrs-for-reception-on-channels-ab-and-cd)
  - [Aggregating multiple instances of the container](#aggregating-multiple-instances-of-the-container)
  - [Hardware requirements](#hardware-requirements)
  - [Getting Help](#getting-help)

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

Example `docker-compose.yml` extract

```yaml
version: '3.8'
services:
  shipfeeder:
    image: ghcr.io/sdr-enthusiasts/docker-shipfeeder
    container_name: shipfeeder
    hostname: shipfeeder
    restart: always
    environment:
      - VERBOSE_LOGGING=
      - SHARING_KEY=${SX_SHARING_KEY}
      - SERIAL_NUMBER=${SX_SERIAL_NUMBER}
      - RTLSDR_DEVICE_SERIAL=${SX_RTLSDR_DEVICE_SERIAL}
      - UDP_FEEDS=${SX_UDP_FEEDS}
      - RTLSDR_DEVICE_GAIN=${SX_RTLSDR_GAIN}
      - AISCATCHER_EXTRA_OPTIONS=${SX_EXTRA_OPTIONS}
      - STATION_NAME=${SX_STATION_NAME}${SX_SERIAL_NUMBER}
      - STATION_HISTORY=3600
      - BACKUP_INTERVAL=5
      - SXFEEDER_LON=${FEEDER_LONG}
      - SXFEEDER_LAT=${FEEDER_LAT}
      - PROMETHEUS_ENABLE=true
      - AISCATCHER_SHAREDATA=true
    ports:
      - 90:80
    devices:
      - /dev/bus/usb
    tmpfs:
      - /tmp
    volumes:
      - "/etc/localtime:/etc/localtime:ro"
      - "/etc/timezone:/etc/timezone:ro"
      - "/opt/ais/shipfeeder/data:/data"
    labels:
      - "com.centurylinklabs.watchtower.scope=ais"
```

Example accompanying `.env` file:

```bash
FEEDER_LAT=42.3788502
FEEDER_LONG=-71.0360718
SX_SHARING_KEY=0123456789abcdef
SX_SERIAL_NUMBER=SXTRPI000xxx
SX_RTLSDR_DEVICE_SERIAL=sdr_serial_number_here
SX_RTLSDR_GAIN=auto
SX_UDP_FEEDS=ip1:port1,ip2:port2:JSON on,ip3:port3
SX_EXTRA_OPTIONS=-p 0 -a 192K -m 4 -go AFC_WIDE on
SX_STATION_NAME=My_station_name_single_string_no_spaces_but_html_char_encoding_is_ok_for_example&nbsp;This&nbsp;is&nbsp;Boston&nbsp;Calling
```

Replace the `SHARING_KEY`, `SERIAL_NUMBER`, and `RTLSDR_DEVICE_SERIAL` with the appropriate values.
You can use `rtl_test` to see which devices and device serials are connected to your machine, or `rtl_eeprom` to rename the device's serial number.

In `SX_EXTRA_OPTIONS`, the `-p` directive indicates the PPM value of your SDR. Adapt it to your needs.

## Runtime Environment Variables

### SDR and Receiver Related Variables

| Environment Variable | Purpose | Default value if omitted |
| ---------------------- | ------------------------------- | --- |
| `RTLSDR_DEVICE_SERIAL` | Serial Number of your RTL-SDR dongle | Empty |
| `RTLSDR_DEVICE_GAIN` | SDR device gain. Can also be set to `auto` | `33` |
| `RTLSDR_DEVICE_PPM`| PPM deviation of your RTLSDR device | Empty |
| `RTLSDR_DEVICE_BANDWIDTH` | Channel bandwitdh of the receiver | `192K` |
| `AISCATCHER_CHANNELS` | Channels flag for `ais-catcher`. Set to `AB`, `CD`, or `AB CD` | Empty |
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

## Feeding AIS Aggregator Services

### Easy sharing with other services

This table shows which parameters to set and how to obtain credentials for a number of well-known AIS aggregators:

 | Name | Parameter | Default IP/DNS/URL | Feeding protocol:<br>UDP/TCP/HTTP/Other | How to register for a key or ID |
 | ---- | --------- | ------------------ | --------------------------------------- | ------------------------------- |
 | ADSB-Network (RadarVirtuel) | `RADARVIRTUEL_FEEDER_KEY`<br>`RADARVIRTUEL_STATION_ID` | [https://ais.adsbnetwork.com/ingester/insert/$RADARVIRTUEL_FEEDER_KEY](https://ais.adsbnetwork.com/ingester/insert/$RADARVIRTUEL_FEEDER_KEY) | HTTP | Email <support@adsbnetwork.com> with your request to join |
 | Airframes | `AIRFRAMES_STATION_ID` | [http://feed.airframes.io:5599](http://feed.airframes.io:5599) | HTTP | No signup needed. `AIRFRAMES_STATION_ID` is a self-chosen ID that has the form of `II-STATIONNAME-AIS`, where `II` are the initials of the owner's name, and `STATIONNAME` is a self-chosen station name (A-Z, 0-9 only please) |
 | AIS-Catcher | `AISCATCHER_SHAREDATA=true`<br>`AISCATCHER_FEEDER_KEY` | | Other | See [Exchanging data with `aiscatcher.org`](#exchanging-data-with-aiscatcherorg) [https://aiscatcher.org/#join](https://aiscatcher.org/#join). In the future, AISCatcher may provide you with an optional UUID that you can set in `AISCATCHER_FEEDER_KEY` |
 | AISHub | `AISHUB_UDP_PORT` | [data.aishub.net](http://data.aishub.net) | UDP | [https://www.aishub.net/join-us](https://www.aishub.net/join-us) |
 | [APRS.fi](http://APRS.fi) | `APRSFI_FEEDER_KEY`<br>`APRSFI_STATION_ID` | [http://aprs.fi/jsonais/post/$APRS_FEEDER_KEY](http://aprs.fi/jsonais/post/$APRS_FEEDER_KEY) | HTTP | Get AIS Password (`APRSFI_FEEDER_KEY`) at [https://aprs.fi/?c=account](https://aprs.fi/?c=account). Use your Ham Radio callsign for `APRSFI_STATION_ID`. Both fields are mandatory. |
 | BoatBeacon | `BOATBEACON_SHAREDATA=true` | [boatbeaconapp.com:5322](http://boatbeaconapp.com:5322) | UDP | [https://pocketmariner.com/ais-ship-tracking/cover-your-area/set-up-and-ais-shore-station/](https://pocketmariner.com/ais-ship-tracking/cover-your-area/set-up-and-ais-shore-station/) - no keys or IDs are required |
 | HPRadar | `HPRADAR_UDP_PORT` | [aisfeed.hpradar.com](http://aisfeed.hpradar.com) | UDP | |
 | MarineTraffic | `MARINETRAFFIC_UDP_PORT` | 5.9.207.224 | UDP | [https://www.marinetraffic.com/en/join-us/cover-your-area](https://www.marinetraffic.com/en/join-us/cover-your-area) |
 | MyShipTracking | `MYSHIPTRACKING_UDP_PORT` | 178.162.215.175 | UDP | [https://www.myshiptracking.com/help-center/contributors/add-your-station](https://www.myshiptracking.com/help-center/contributors/add-your-station) |
 | ShipFinder | `SHIPFINDER_SHAREDATA=true` | [ais.shipfinder.co.uk:4001](http://ais.shipfinder.co.uk:4001/) | UDP | [https://shipfinder.co/about/coverage/](https://shipfinder.co/about/coverage/) |
 | ShippingExplorer | `SHIPPINGEXPLORER_UDP_PORT` | 144.76.54.111 | UDP | Request UDP port at [https://www.shippingexplorer.net/en/contact](https://www.shippingexplorer.net/en/contact) |
 | ShipXplorer | `SHIPXPLORER_SHARING_KEY` or `SHARING_KEY` (legacy)<br>`SHIPXPLORER_SERIAL_NUMBER` or `SERIAL_NUMBER` (legacy) | | Other | See [Obtaining a ShipXplorer Sharing Key](#obtaining-a-shipxplorer-sharing-key) |
 | VesselFinder | `VESSELFINDER_UDP_PORT` | [ais.vesselfinder.com](http://ais.vesselfinder.com) | UDP | [https://stations.vesselfinder.com/become-partner](https://stations.vesselfinder.com/become-partner) |
 | VesselTracker | `VESSELTRACKER_UDP_PORT` | 83.220.137.136 | UDP | [https://www.vesseltracker.com/en/static/antenna-partner.html](https://www.vesseltracker.com/en/static/antenna-partner.html) |

Note: for all parameters `SERVICE_UDP_PORT`, you may use one of the following formats:

- `- SERVICE_UDP_PORT=1234` --> use UDP port 1234
- `- SERVICE_UDP_PORT=hostname:1234` or `- SERVICE_UDP_PORT=ip_addr:1234` --> use the hostname or ip address instead of the one indicated in the table, and UDP port 1234

For services that do no need any UDP ports or credentials, you can simply set `- SERVICE_SHAREDATA=true`. However, if you want to use a non-default port and/or hostname/ip, you can set also `SERVICE_UDP_PORT` (as shown above) for that service

### Exchanging data with `aiscatcher.org`

[aiscatcher.org](https://aiscatcher.org) is an exchange of AIS NMEA data. If you share your data with this server, you automatically receive data about other ships in return. **We recommend to switch this on for an optimal viewing experience.**
You can enable it by simply adding the following to the environment section of your `shipfeeder` service section in `docker-compose.yml`. Note that the `AISCATCHER_SHAREKEY` parameter is optional and will be ignored for now, pending implementation of this feature by AIS-Catcher.

```yaml
- AISCATCHER_SHAREDATA=true
- AISCATCHER_SHAREKEY=xxxxxxxx
```

### Configuring feeding to ShipXplorer

#### Obtaining a ShipXplorer Sharing Key

First-time users should obtain a ShipXplorer sharing key.

In order to obtain a ShipXplorer sharing key, on the first run of the container, it will generate a sharing key and print this to the container log. If you can't find it, you can also copy and paste this command:

```bash
timeout 180s docker run \
    --rm \
    -it \
    --entrypoint /usr/bin/get-creds \
    ghcr.io/sdr-enthusiasts/shipxplorer:latest
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
Take a note of the Sharing Key (`f1...57` - yours will be a different number) and the Serial Number (`SXTRPIxxxxxx`), and add these to the `SHARING_KEY` and `SERIAL_NUMBER` parameters of your `docker-compose.yml` file.

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

If you want to feed and additional AIS aggregator that uses a hostname/UDP port and that is not listed above, then simply add a comma separated list of hostnames/ip addresses and UDP ports to the `UDP_FEEDS` parameter. Format: `UDP_FEEDS=domain1.com:port1[:params],domain2,com:port2[:params],...`

For example:

```yaml
- UDP_FEEDS=1.2.3.4:9999,ais.aggregator.org:1234
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
Last - the software will run on a Raspberry Pi 3B+ or 4, with Raspberry Pi OS, Ubuntu, or a similar Debian-based operating system. It will also run on X86 (Linux PC) systems with Ubuntu. The prebuilt Docker container will work on `armhf`/`arm64`/`x86_64` (`amd64`) architectures. You may be able to build containers for other systems, but for that you're on your own.

## Getting Help

You can [log an issue](https://github.com/sdr-enthusiasts/docker-shipfeeder/issues) on the project's GitHub.

I also have a [Discord channel](https://discord.gg/sTf9uYF), feel free to [join](https://discord.gg/sTf9uYF) and converse.
