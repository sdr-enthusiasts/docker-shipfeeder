# Configuration Examples for ShipXplorer

[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

- [Configuration Examples for ShipXplorer](#configuration-examples-for-shipxplorer)
  - [Introduction](#introduction)
  - [Installing `docker` on your machine](#installing-docker-on-your-machine)
  - [Downloading the sample configuration](#downloading-the-sample-configuration)
  - [Prep and download the sample configuration files](#prep-and-download-the-sample-configuration-files)
  - [Configuring your station](#configuring-your-station)
  - [Starting your AIS Feeder](#starting-your-ais-feeder)
  - [See ships and station data on your webpage](#see-ships-and-station-data-on-your-webpage)
  - [Troubleshooting](#troubleshooting)
  - [Advanced configuration](#advanced-configuration)
  - [Getting Help](#getting-help)

## Introduction

While the main README.md has information on how to configure and set up the container, this README describes how a practical setup could look.
We will cover 4 containers:

- the ShipXplorer container to decode data and feed to ShipXplorer and many other services
- VesselAlert to send alerts about new vessels to Mastodon or Discord
- AIS-Screenshot, a "helper" container for VesselAlert that provides screenshots of the map for addition to the alert notifications
- WatchTower to ensure that the containers are kept up to date

Before you go on, you should:

- Get the Latitude and Longitude of your receiver
- follow the [instructions][shipxplorer] and get a ShipXplorer Sharing Key and Serial Number
- know what serial number of your RTL-SDR dongle is (hint: use `rtl_test` to find out)
- sign up and collect credentials (mostly IP addresses and UDP ports) of any other services you want to feed
- [Get credentials][mastodon] if you want to send notifications to Mastodon
- Get one or more Discord Webhooks. If you want to send notification to our special [`#Vessel-Alerts` Discord Channel](https://discord.gg/UMgZMc2AGp), you can keep the Webhook in the `.env` sample file!
- Last, if your machine is NOT a Raspberry Pi, you should follow [this "work-around for CPU Serial Number"](https://github.com/sdr-enthusiasts/docker-shipxplorer#workaround-for-cpu-serial-only-needed-with-non-raspberry-pi-systems) before doing anything else.

## Installing `docker` on your machine

Follow the instructions here: [https://github.com/sdr-enthusiasts/docker-install](https://github.com/sdr-enthusiasts/docker-install)

## Downloading the sample configuration

The provided [sample `docker-compose.yml`](docker-compose.yml.sample) and [sample `environment variables`](.env.sample) files can be used as-is, unedited (after renaming them of course). If you use your machine for multiple purposes, we recommend putting your AIS containers in a separate stack from other containers. This is purely for ease of maintenance -- strictly speaking, you *can* put all containers in a single stack.

Here's what you do:

## Prep and download the sample configuration files

Log into your machine with the AIS dongle, and type or copy/paste this:

```bash
sudo mkdir /opt/ais
sudo chmod a+rwx /opt/ais
cd /opt/ais
curl https://raw.githubusercontent.com/sdr-enthusiasts/docker-shipxplorer/main/config-examples/docker-compose.yml.sample -o docker-compose.yml
curl https://raw.githubusercontent.com/sdr-enthusiasts/docker-shipxplorer/main/config-examples/.env.sample -o .env
```

## Configuring your station

Next thing is to edit the `.env` file and put your data in:

```bash
nano /opt/ais/.env
```

Make the changes based on the description below, and once you are done, you can Save & Exit with CTRL-x

| Parameter     | Description   |
|---------------|---------------|
| `FEEDER_LAT` | The latitude (xx.xxxxx) of your station |
| `FEEDER_LONG` | The longitude (xx.xxxxx) of your station |
| `SX_SHARING_KEY` | You ShipXplorer Sharing Key. This is a long string with numbers and letters |
| `SX_SERIAL_NUMBER` | Your ShipXplorer Serial Number. This looks like `SXTRPI000000` |
| `SX_RTLSDR_DEVICE_SERIAL` | The serial string of your AIS RTL-SDR dongle |
| `SX_RTLSDR_GAIN` | The gain of your RTL-SDR dongle. If you don't know what to put, we recommend leaving it set to `auto` |
| `SX_UDP_FEEDS` | If you want to feed any other services using UDP, you can enter them with this parameter. The format is `ip_or_hostname:port` and they are comma separated. See the example in the file. |
| `SX_EXTRA_OPTIONS` | Here you can put additional parameters as described for [Ais-Catcher](https://github.com/jvde-github/AIS-catcher#usage). These are like a command-line: just put spaces between sets of parameter. Examples: |
| | `-p -2` sets the PPM correction to `-2` |
| | `-a 192K` sets the tuner bandwidth to 192 kHz (recommended!) |
| | `-H http://aprs.fi/jsonais/post/zxxxxxxV ID AB1CE PROTOCOL aprs INTERVAL 30 RESPONSE off` uploads data to `aprs.fi` using HTTP |
| | et cetera |
| `SX_STATION_NAME` | Your station name. The text needs to be "web save": instead of spaces, please put `&nbsp;` between the words |
| `VA_MASTODON_SERVER` | The Mastodon server your account is on. For example `airwaves.social` |
| `VA_MASTODON_ACCESS_TOKEN` | The Mastodon Access Token you got when you created an app |
| `VA_MASTODON_SKIP_FILTER` | Skips notifications for any MMSI that matches this RegEx. For example, `^[9]{2}[0-9]{7}$$|^[0-9]{7}$$` filters any MMSI of 9 digits that start with `99` (which are Aids-to-Navigation: virtual waypoints) and it also filters any 7-digit MMSI. |
| `VA_MASTODON_CUSTOM_FIELD` | Additional text you want to add to your Mastodon notification |
| `VA_DISCORD_NAME` | Please put something meaningful here, containing both your STATION NAME and the LOCATION. We're a world-wide group! |
| `VA_DISCORD_AVATAR_URL` | Link to a URL that contains your avatar / picture |
| `VA_DISCORD_WEBHOOKS` | Webhook(s) for Discord notifications. If you have multiple channels your want to notify to, you can comma-separate them. We prefilled this field with one for our special [`#Vessel-Alerts` Discord Channel](https://discord.gg/UMgZMc2AGp) |
| `VA_SCREENSHOT_URL` | `http://ais-screenshot:5042` |
| `BACKUP_RETENTION_TIME` | Time (in days) to keep backups of `aiscatcher.bin` and plugins. Note - this only affects the backups of these files and not the active `aiscatcher.bin` or active plugins. Default: `30` (days) |

## Starting your AIS Feeder

Do this:

```bash
cd /opt/ais
docker-compose pull
docker-compose up -d
```

The system checks every 30 minutes if there's a new version of any of the container. However, you can also manually check if there are updates by repeating the commands above.

## See ships and station data on your webpage

You can browse to `http://my_ip:90` (replace `my_ip` with the IP address of your machine) to see the AIS-Catcher web interface.

## Troubleshooting

If things aren't running the way they should be, your first course of action is to check the container logs. They often give hints on what when wrong and how to fix it.

- If the web page doesn't work, or no data is sent to ShipXplorer, check the `shipxplorer` logs: `docker logs shipxplorer`
- If no notifications are sent, check the `VesselAlert` logs: `docker logs vesselalert`
- If the notification don't include a map, or the map screenshot is not good, check the `ais-screenshot` logs: `docker logs ais-screenshot`
Note -- you can "follow" the logs live by adding `-f` to the command: `docker logs -f shipxplorer`

## Advanced configuration

There are a few additional things you can configure by editing `docker-compose.yml`. Those shouldn't need changing under normal circumstances, but here they are in case you feel lucky:

- Changing the web page port: in the `shipxplorer` section, change the port definition from `- 90:80` to `- xxxx:80`, where `xxxx` is your desired web port number
- Changing the check interval for new software versions: in the `watchtower` section, change the command line from `command: --interval 1800 --scope ais` to `command: --interval xxxx --scope ais`, where `xxxx` is the check interval in seconds
- If the screenshots don't quite render correctly, you may want to increase the render time in the `screenshot-ais` section: change `- LOAD_SLEEP_TIME=15` to ``- LOAD_SLEEP_TIME=30` or so (time in seconds for the container to wait for the web page to render before a screenshot is taken)
- Similarly, you can change the map type for the screenshot in the `screenshot-ais` section: change `OpenStreetMap` in `- MAP_ARGS=map=OpenStreetMap` to any of `Positron`, `Dark%20Matter`, `Voyager`, or `Satellite`.

After making any of these changes, you should restart the containers with `docker-compose up -d --force-recreate`

## Getting Help

You can [log an issue](https://github.com/sdr-enthusiasts/docker-shipxplorer/issues) on the project's GitHub.

We also have a [Discord channel](https://discord.gg/sTf9uYF), feel free to [join](https://discord.gg/sTf9uYF) and chat with us if you need help or want to exchange experiences. We'd love to hear from you!.

[mastodon]: https://github.com/sdr-enthusiasts/docker-vesselalert/blob/main/README-Mastodon.md
[shipxplorer]: https://github.com/sdr-enthusiasts/docker-shipxplorer#readme
