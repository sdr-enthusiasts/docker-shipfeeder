# sdr-enthusiasts/docker-shipxplorer

[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

- [sdr-enthusiasts/docker-shipxplorer](#sdr-enthusiastsdocker-shipxplorer)
  - [Prerequisites](#prerequisites)
  - [Multi Architecture Support](#multi-architecture-support)
  - [Obtaining a ShipXplorer Sharing Key](#obtaining-a-shipxplorer-sharing-key)
  - [Up-and-Running with Docker Compose](#up-and-running-with-docker-compose)
  - [Claiming Your ShipXplorer Receiver](#claiming-your-shipxplorer-receiver)
  - [Runtime Environment Variables](#runtime-environment-variables)
  - [Feeding Other Service](#feeding-other-service)
    - [Feeding Services Using UDP](#feeding-services-using-udp)
    - [Feeding Service Using HTTP](#feeding-service-using-http)
      - [Feeding `aprs.fi`](#feeding-aprsfi)
      - [Feeding `airframes.io`](#feeding-airframesio)
  - [Adding an `About` Page to the AIS-Catcher Website](#adding-an-about-page-to-the-ais-catcher-website)
  - [Logging](#logging)
  - [Workaround for CPU Serial (only needed with non-Raspberry Pi systems)](#workaround-for-cpu-serial-only-needed-with-non-raspberry-pi-systems)
  - [Feeding other services](#feeding-other-services)
  - [AIS-Catcher Web Plugin Support and AIS-Catcher Persistency](#ais-catcher-web-plugin-support-and-ais-catcher-persistency)
  - [Additional Statistics Dashboard with Prometheus and Grafana](#additional-statistics-dashboard-with-prometheus-and-grafana)
  - [Aggregating multiple instances of the container](#aggregating-multiple-instances-of-the-container)
  - [Hardware requirements](#hardware-requirements)
  - [Getting Help](#getting-help)

Docker container running [AirNav ShipXplorer](https://www.shipxplorer.com)'s `sxfeeder` and `AIS-catcher`. Builds and runs on `arm64`, `armv7/armhf`, and `amd64/x86`.

`AIS-catcher` pulls AIS information from a RTL-SDR dongle.
`sxfeeder` sends this data to RadarBox.

You can also use this container to feed other AIS services that take NMEA-formatted AIS data over either UDP or HTTP. See below for details.

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

## Obtaining a ShipXplorer Sharing Key

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

## Up-and-Running with Docker Compose

Example `docker-compose.yml` extract

```yaml
version: '3.8'
services:
  shipxplorer:
    image: ghcr.io/sdr-enthusiasts/shipxplorer
    container_name: shipxplorer
    hostname: shipxplorer
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
    ports:
      - 90:80
    devices:
      - /dev/bus/usb
    tmpfs:
      - /tmp
    volumes:
      - "/etc/localtime:/etc/localtime:ro"
      - "/etc/timezone:/etc/timezone:ro"
      - "/opt/ais/shipxplorer/data:/data"
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

## Claiming Your ShipXplorer Receiver

Once your container is up and running, you should claim your receiver.

1. Go to <https://www.shipxplorer.com>
2. Create an account or sign in
3. Claim your receiver by visiting <https://www.shipxplorer.com/addcoverage> and following the instructions

Note - you will need your `SHARING_KEY` and the location of your feeder (coordinates or pick on map). As of now, it appears that you don't need your SN or Public IP address.

## Runtime Environment Variables

There are a series of available environment variables:

| Environment Variable | Purpose                         |
| ---------------------- | ------------------------------- |
| `SHARING_KEY`          | Sharing Key generated by `sxfeeder`. See instructions above. If unset, then no data will be sent to ShipXplorer but the container can still be used to feed other services without feeding ShipXplorer |
| `SERIAL_NUMBER`        | Required. Serial Number generated by `sxfeeder`. See instructions above |
| `RTLSDR_DEVICE_SERIAL` | Required. Serial Number of your RTL-SDR dongle. See instructions above |
| `UDP_FEEDS`            | Optional. Defines target UDP feeds in addition to ShipExplorer. Format: `UDP_FEEDS=domain1.com:port1[:params],domain2,com:port2[:params],...` |
| `VERBOSE_LOGGING`      | Optional. If empty, a summary is displayed every 60 seconds. If set to a number (`0`-`5`), it's set to the `AIS-Catcher -o` [log level](https://github.com/jvde-github/AIS-catcher#usage). Any other non-empty string corresponds to `-o 2`. To silence `AIS-Catcher` logs, set this parameter to `0` |
| `RTLSDR_DEVICE_GAIN`   | Optional. SDR device gain. If omitted, default value is 33.3 is used. Can also be set to `auto` |
| `AISCATCHER_EXTRA_OPTIONS` | Optional. Any additional command line parameters you wish to pass to `AIS-catcher`. Default: empty |
| `SXFEEDER_EXTRA_OPTIONS` | Optional. Any additional command line parameters you wish to pass to `sxfeeder`. Default: empty |
| `PLUGINS_FILE` | Optional. Load a file with custom javascript to override parts of the WebUI or add functionality. Map the container `/data` to any volume, place your file inside the volume and put the file name here (for example `plugins.js`) |
| `STYLES_FILE` | Optional. Load a file with custom css to override parts of the WebUI or add functionality. Map the container `/data` to any volume, place your file inside the volume and put the file name here (for example `styles.css`) |
| `STATION_NAME` | Optional. Station name displayed on stat web page. If omitted, it will should your ShipXplorer Serial Number |
| `STATION_LINK` | Optional. URL displayed on stat web page. If omitted, it will show your ShipXplorer URL |
| `STATION_HISTORY` | Optional. The number of seconds of history that will be shown in plots on the website. Default if omitted: `3600` (1 hour)  |
| `BACKUP_INTERVAL` | Optional. How often a file with data statistics (`aiscatcher.bin`) will be written to disk, in minutes. In order to make this backup persistent, make sure to map the `/data` directory to a volume. See example in [docker-compose.yml](docker-compose.yml). Default: 2880 minutes (=2 days) |
| `BACKUP_RETENTION_TIME` | Time (in days) to keep backups of `aiscatcher.bin` and plugins. Note - this only affects the backups of these files and not the active `aiscatcher.bin` or active plugins | `30` (days) |
| `SITESHOW` | Optional. If set to anything non-empty, it will show the station location as a dot on the map |
| `SXFEEDER_LAT` | Optional. Used for calculating ship distances on web page |
| `SXFEEDER_LON` | Optional. Used for calculating ship distances on web page |
| `PROMETHEUS_ENABLE` | Optional. Enables Prometheus data at `/metrics` on the webserver. Empty (disabled) by default |
| `DISABLE_SHOWLASTMSG` | Optional. If enabled, the last NMEA0182 message option won't be shown on the website. Default empty (disabled) (i.e., last message option is available on website) |
| `DISABLE_WEBSITE` | Optional. If enabled, the AIS-Catcher website will not be available. Default empty (disabled) (i.e., the website is available) |
| `PLUGIN_UPDATE_INTERVAL` | Optional. Set this to the interval (for example, `30` (secs) or `5m` or `6h` or `3d`) to check the AIS-Catcher github repository for updates to the JavaScript web plugins. Set to `0` or `off` to disable checking. Default value: `6h` |

## Feeding Other Service

### Feeding Services Using UDP

Simply add a comma separated list of hostnames/ip addresses and UDP ports to the `SX_UDP_FEEDS` parameter. For example:

```bash
SX_UDP_FEEDS=1.2.3.4:9999,ais.aggregator.org:1234
```

### Feeding Service Using HTTP

#### Feeding `aprs.fi`

To feed `aprs.fi` using HTTP, you firwst need to create an AIS feeder account at that service. Note that creating accounts is limited to licensed amateur radio operators. With this account, you can create a personalized feeder URL, for example `http://aprs.fi/jsonais/post/aBcDeFgHiJkL`.
To initiate feeding, add the following to the `AISCATCHER_EXTRA_OPTIONS` parameter (replace the URL with your personalized link, and `MY0CALL` with your registered amateur radio callsign):

```bash
AISCATCHER_EXTRA_OPTIONS=-H http://aprs.fi/jsonais/post/aBcDeFgHiJkL ID MY0CALL PROTOCOL aprs INTERVAL 30 RESPONSE off
```

#### Feeding `airframes.io`

Since feeding `airframes.io` is still in a private alpha phase, you need to contact them to obtain a URL and be granted access to their private ZeroTier network. Once you have this all squared, you should add the following to the `AISCATCHER_EXTRA_OPTIONS` parameter:

```bash
AISCATCHER_EXTRA_OPTIONS=-H http://1.2.3.4/test ID my_station_name INTERVAL 30 RESPONSE off
```

Note: if you want to feed multiple HTTP aggregators, you can simply append each feeder string to the `AISCATCHER_EXTRA_OPTIONS` variable. For example:

```bash
AISCATCHER_EXTRA_OPTIONS=-H http://aprs.fi/jsonais/post/aBcDeFgHiJkL ID MY0CALL PROTOCOL aprs INTERVAL 30 RESPONSE off -H http://1.2.3.4/test ID my_station_name INTERVAL 30 RESPONSE off
```

## Adding an `About` Page to the AIS-Catcher Website

You can add an About page to the AIS-Catcher Website by placing a file called `about.md` in the `/data` directory of the container. If you mapped this directory to a volume as shown in the example, the file as seen from the host system would be `/opt/ais/shipxplorer/about.md`.
You can format the text in this file using [Markdown](https://www.markdownguide.org/cheat-sheet/).

## Logging

- All processes are logged to the container's stdout, and can be viewed with `docker logs [-f] container`.

## Workaround for CPU Serial (only needed with non-Raspberry Pi systems)

The `sxfeeder` binary effectively greps for `serial\t\t:` in your `/proc/cpuinfo` file, to determine the RPi's serial number.

For systems that don't have a CPU serial number in `/proc/cpuinfo`, we can "fudge" this by generating a replacement `cpuinfo` file with a random serial number. To do this, copy and paste the following on your host machine:

```bash
sudo mkdir -m777 -p /opt/shipxplorer/cpuinfo
sudo install -m 666 /proc/cpuinfo /opt/shipxplorer/cpuinfo/
echo -e "serial\t\t: $(hexdump -n 8 -e '4/4 "%08X" 1 "\n"' /dev/urandom | tr '[:upper:]' '[:lower:]')" >> /opt/shipxplorer/cpuinfo/cpuinfo
```

You can now map this file into your container:

- If using docker run, simply add `-v /opt/shipxplorer/cpuinfo/cpuinfo:/proc/cpuinfo` to your command.
- If using docker-compose, add the following to the `volumes:` section of your shipxplorer container definition:

```yaml
  - /opt/shipxplorer/cpuinfo/cpuinfo:/proc/cpuinfo
```

## Feeding other services

You can use the `UDP_FEEDS` parameter to feed additional services, as long as they can accept the UDP data format.  for example to feed MarineTraffic:

```yaml
     - UDP_FEEDS=5.9.207.224:5321
```

If you signed up and configured a station at their website, please replace the IP:port by the one allocated to your station. You can add multiple comma-separated UDP feeds here.

If you have a Ham Radio license, you can also feed to `aprs.fi` via HTTP. In this case, configure `AISCATCHER_EXTRA_OPTIONS` like this:

```yaml
     - AISCATCHER_EXTRA_OPTIONS=-H http://aprs.fi/jsonais/post/abcdefghijklmn ID C9LLSIGN PROTOCOL aprs INTERVAL 30 RESPONSE off
```

where you replace `abcdefghijklmn` with the key you get when you sign up at aprs.fi, and `C9LLSIGN` with your Ham Radio callsign.

## AIS-Catcher Web Plugin Support and AIS-Catcher Persistency

We recommend mapping a volume (as shown in the sample `docker-compose.yml` file in this repo) to the `/data` directory. This will ensure that AIS-Catcher data will persist across restarts and container recreation.

Web Plugins for AIS-Catcher can be placed in the `/data/plugins` directory.

## Additional Statistics Dashboard with Prometheus and Grafana

See [this readme](README-grafana.md) for information on how to set up and configure a Grafana stats dashboard for use with ShipXplorer.

## Aggregating multiple instances of the container

Sometimes it's convenient to aggregate the data of multiple instances of the container into a single one, and then feed the AIS aggregators from this "central" instance. An example of this is when you have a SDR receiving from channels AB in one instance, and a SDR receiving from channels CD in a separate instance. In this case, you'd want to send the data from channels CD to the instance that (also) receives channels AB, and then use the Channel AB instance to disperse the data to the various services.

In this case, do the following. We are assuming that the hostname/container name for the instance receiving channels AB is `shipxplorer_ab` and the hostname/container name for the instance receiving channels CD is `shipxplorer_cd`. Your names may vary.

Situation 1: both instances are in the same container stack, on the same machine:

- In the section of the `docker-compose.yml` file for `shipxplorer_ab`, make sure to add the following to the `UDP_FEEDS` parameter:

```yaml
    - UDP_FEEDS=.....;shipxplorer_cd:9988 JSON on
```

- In the section of the `docker-compose.yml` file for `shipxplorer_cd`, make sure to add the following to the `UDP_FEEDS` parameter. Make sure that the name after `-x` matches your container name:

```yaml
    - AISCATCHER_EXTRA_OPTIONS=...... -x shipxplorer_cd 9988 -c AB CD
```

Situation 2: both instances are on different machines or in different stacks on the same machine:

- In the section of the `docker-compose.yml` file for `shipxplorer_ab`, make sure to add the following to the `UDP_FEEDS` parameter. Make sure that you replace `target_machine` with the IP or hostname of the target machine:

```yaml
    - UDP_FEEDS=.....;target_machine:9988
```

- In the section of the `docker-compose.yml` file for `shipxplorer_cd`, make sure to add the following to the `UDP_FEEDS` parameter. Make sure that the name after `-x` matches your container name. (DO NOT USE `localhost` or `127.0.0.1` - that won't work):

```yaml
    - AISCATCHER_EXTRA_OPTIONS=...... -x shipxplorer_cd 9988 -c AB CD
```

- In addition, to the same section of the `docker-compose.yml` file for `shipxplorer_cd`, make sure to forward the UPD port to the container:

```yaml
    ports:
      [...]
      - 9988:9988/udp
```

Once you have done this, and after you recreate the containers, the `shipxplorer_cd` instance will now forward its data to `shipxplorer_ab`, and `shipxplorer_ab` will aggregate this data, display it on the AIS-Catcher map and tables, and forward it to any service you may have configured for it.

## Hardware requirements

AIS data is transmitted in the 160 MHz band, for which you'd need a suitable antenna. Note -- ADSB/UAT antennas will definitely not work!
You would need a RTL-SDR dongle, potentially with an LNA, and potentially with a filter. The filter must be dedicated to the 160 MHz band. Dongles with built-in filters for the ADSB or UAT bands won't work.
Last - the software will run on a Raspberry Pi 3B+ or 4, with Raspberry Pi OS, Ubuntu, or a similar Debian-based operating system. It will also run on X86 (Linux PC) systems with Ubuntu. The prebuilt Docker container will work on `armhf`/`arm64`/`x86_64` (`amd64`) architectures. You may be able to build containers for other systems, but for that you're on your own.

## Getting Help

You can [log an issue](https://github.com/sdr-enthusiasts/docker-shipxplorer/issues) on the project's GitHub.

I also have a [Discord channel](https://discord.gg/sTf9uYF), feel free to [join](https://discord.gg/sTf9uYF) and converse.
