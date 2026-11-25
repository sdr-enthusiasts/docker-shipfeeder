#!/usr/bin/env bash
# shellcheck disable=SC2034
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_dir/rootfs/etc/s6-overlay/scripts/aiscatcher"
json_helpers="$(sed -n '/^json_esc() {/,/^jstr() {/p' "$script")"
# shellcheck disable=SC2016
gps_parser="$(sed -n '/^if \[\[ -n "\$AISCATCHER_GPS_SERIAL" \]\]; then/,/^# Add a number of well-known feeders:/p' "$script")"

generate_gps() (
    set +eu
    eval "$json_helpers"
    s6wrap=()
    additional_receiver_entries=()
    AISCATCHER_GPS_SERIAL="$1"
    AISCATCHER_GPSD_PORT="$2"
    eval "$gps_parser"
    printf '%s\n' "${additional_receiver_entries[@]}" | jq -s 'map(select(. != null))'
)

generate_gps '' '' | jq -e 'length == 0' >/dev/null
generate_gps '/dev/ttyACM0' '' | jq -e '. == [{input:"serialport",serialport:{port:"/dev/ttyACM0"}}]' >/dev/null
generate_gps '/dev/ttyACM0:9600' 'gpsd:2947' | jq -e '. == [{input:"serialport",serialport:{port:"/dev/ttyACM0",baudrate:"9600"}},{input:"rtltcp",rtltcp:{protocol:"gpsd",host:"gpsd",port:"2947"}}]' >/dev/null
generate_gps '' 'localhost:2947' | jq -e '. == [{input:"rtltcp",rtltcp:{protocol:"gpsd",host:"localhost",port:"2947"}}]' >/dev/null

for invalid in ':9600' '/dev/ttyACM0:' '/dev/ttyACM0:abc' '/dev/ttyACM0:0' '/dev/ttyACM0:9600:extra'; do
    if generate_gps "$invalid" '' >/dev/null 2>&1; then
        printf 'Unexpectedly accepted serial GPS setting %s\n' "$invalid" >&2
        exit 1
    fi
done
for invalid in 'gpsd' ':2947' 'gpsd:' 'gpsd:0' 'gpsd:65536' 'gpsd:abc' 'gpsd:2947:extra'; do
    if generate_gps '' "$invalid" >/dev/null 2>&1; then
        printf 'Unexpectedly accepted GPSD setting %s\n' "$invalid" >&2
        exit 1
    fi
done

printf 'GPS input tests passed\n'