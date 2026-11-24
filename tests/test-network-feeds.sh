#!/usr/bin/env bash
# shellcheck disable=SC2034
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_dir/rootfs/etc/s6-overlay/scripts/aiscatcher"
eval "$(sed -n '/^json_esc() {/,/^jstr() {/p' "$script")"
check_feed_target() { return 0; }
connection_metadata() { printf '"description":"Feed","link":"https://example.com/"'; }
eval "$(sed -n '/^add_udp_feed() {/,/^# Interpret additional feed targets/p' "$script")"

function /usr/local/bin/AIS-catcher() {
    local protocol="$1" host="$2" port="$3"
    shift 3
    case "$1" in
        JSON) [[ "$2" == on && "$3" == -J ]] || return 1; jq -cn --arg host "$host" --arg port "$port" '{udp:[{host:$host,port:$port,json:"on"}]}' ;;
        MSGFORMAT) [[ "$2" == JSON_NMEA && "$3" == -J ]] || return 1; jq -cn --arg host "$host" --arg port "$port" --arg protocol "$protocol" '{($protocol | if . == "-u" then "udp" else "tcp" end):[{host:$host,port:$port,msgformat:"JSON_NMEA"}]}' ;;
        UNIQUE) [[ "$2" == off && "$3" == -J ]] || return 1; jq -cn --arg host "$host" --arg port "$port" '{udp:[{host:$host,port:$port,unique:false}]}' ;;
        *) return 1 ;;
    esac
}

s6wrap=()
output_filter_fields='"filter":true,"unique":true'
udp_outputs=() tcp_outputs=()
add_udp_feed '10.0.0.107:9988 JSON on'
add_udp_feed '127.0.0.1:10110:MSGFORMAT:JSON_NMEA'
add_udp_feed '127.0.0.1:10111' '"msgformat":"JSON_NMEA"'
add_udp_feed '127.0.0.1:10112 UNIQUE off'
add_tcp_feed '127.0.0.1:9988 MSGFORMAT JSON_NMEA'
add_tcp_feed '127.0.0.1:00999'

printf '%s\n' "${udp_outputs[@]}" | jq -s -e 'length == 4 and
    .[0].host == "10.0.0.107" and .[0].port == 9988 and .[0].json == "on" and
    .[1].msgformat == "JSON_NMEA" and .[2].msgformat == "JSON_NMEA" and
    all(.[]; .unique == true and .filter == true and .description == "Feed")' >/dev/null
printf '%s\n' "${tcp_outputs[@]}" | jq -s -e 'length == 2 and .[0].msgformat == "JSON_NMEA" and .[0].port == 9988 and .[1].port == 999 and all(.[]; .unique == true)' >/dev/null

udp_outputs=() tcp_outputs=()
UDP_FEEDS='10.0.0.107:9988 JSON on,127.0.0.1:10111,'
TCP_FEEDS='127.0.0.1:9988 MSGFORMAT JSON_NMEA,'
# shellcheck disable=SC2016
eval "$(sed -n '/^# Interpret additional feed targets/,/^if \[\[ -z "\$SDR_TYPE" \]\]; then/p' "$script" | sed '$d')"
[[ ${#udp_outputs[@]} -eq 2 && ${#tcp_outputs[@]} -eq 1 ]]

udp_outputs=()
AISFRIENDS_UDP_PORT='9988 JSON on' AISFRIENDS_TCP_PORT=''
eval "$(sed -n '/^# AIS Friends:/,/^# AISHub:/p' "$script")"
jq -e '.host == "ais.aisfriends.com" and .port == 9988 and .json == "on" and .unique == true' <<< "${udp_outputs[0]}" >/dev/null

for invalid in '127.0.0.1:0' '127.0.0.1:65536' '127.0.0.1:notaport' '127.0.0.1:9999 INVALID on'; do
    if (add_udp_feed "$invalid") >/dev/null 2>&1; then
        printf 'Unexpectedly accepted UDP feed %s\n' "$invalid" >&2
        exit 1
    fi
done
for invalid in '127.0.0.1:0' '127.0.0.1:65536' '127.0.0.1:notaport' '127.0.0.1:9999 INVALID on'; do
    if (add_tcp_feed "$invalid") >/dev/null 2>&1; then
        printf 'Unexpectedly accepted TCP feed %s\n' "$invalid" >&2
        exit 1
    fi
done

# shellcheck disable=SC2016
mqtt_parser="$(sed -n '/^if \[\[ -n "${AISCATCHER_MQTT_URL}" \]\]; then/,/^# ADSB connector/p' "$script")"
generate_mqtt() (
    set +u
    AISCATCHER_MQTT_URL='mqtt://example.com'
    AISCATCHER_MQTT_QOS="$1"
    AISCATCHER_MQTT_MSGFORMAT='' AISCATCHER_MQTT_CLIENT_ID='' AISCATCHER_MQTT_TOPIC=''
    # shellcheck disable=SC2317
    add_mqtt_feed() { printf '{%s}\n' "$2"; }
    eval "$mqtt_parser"
)
for qos in 0 1 2; do
    generate_mqtt "$qos" | jq -e --argjson qos "$qos" '.qos == $qos' >/dev/null
done
for qos in 3 -1 invalid; do
    if generate_mqtt "$qos" >/dev/null 2>&1; then
        printf 'Unexpectedly accepted MQTT QoS %s\n' "$qos" >&2
        exit 1
    fi
done

printf 'Network feed tests passed\n'