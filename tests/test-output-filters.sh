#!/usr/bin/env bash
# shellcheck disable=SC2034
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_dir/rootfs/etc/s6-overlay/scripts/aiscatcher"
eval "$(sed -n '/^json_esc() {/,/^jbool_enabled() {/p' "$script")"
chk_enabled() { case "${1,,}" in true|yes|on|1|enabled) return 0 ;; *) return 1 ;; esac; }
check_feed_target() { return 0; }
connection_metadata() { printf '"description":"test","link":"https://example.com/"'; }
eval "$(sed -n '/^add_udp_feed() {/,/^# Interpret additional feed targets/p' "$script")"
output_filter_fields=''
server_json=''

generate_filters() {
    set +u
    eval "$(sed -n '/^filter_fields=()/,/^output_filter_fields=/p' "$script")"
    set -u
}

generate_filters
jq -e '. == {"unique":true}' <<< "{$output_filter_fields}" >/dev/null

DISABLE_WEBSITE='' SITESHOW='' DISABLE_GEOJSON='' DISABLE_SHIPSJSON_COMPRESS='' BACKUP_INTERVAL='' STATION_HISTORY=''
PROMETHEUS_ENABLE='' STATION_NAME='' STATION_LINK='' FEEDER_LAT='' FEEDER_LONG='' DISABLE_SHOWLASTMSG='' REALTIME=''
# shellcheck disable=SC2016
viewer_block="$(sed -n '/^if ! chk_enabled "${DISABLE_WEBSITE}"; then/,/^# extra_cli_args/p' "$script")"
eval "$viewer_block"
jq -e '.unique == true and .filter == true' <<< "{$server_json}" >/dev/null

export AISCATCHER_FILTER_ALLOW_TYPE='1,2,3' AISCATCHER_FILTER_BLOCK_TYPE='8'
export AISCATCHER_FILTER_ALLOW_REPEAT='0,1' AISCATCHER_FILTER_BLOCK_REPEAT='3'
export AISCATCHER_FILTER_ALLOW_MMSI='123456789,987654321' AISCATCHER_FILTER_BLOCK_MMSI='111111111'
export AISCATCHER_FILTER_ALLOW_CHANNEL='AB' AISCATCHER_FILTER_ID='0,4'
export AISCATCHER_FILTER_GPS=off AISCATCHER_FILTER_AIS=yes AISCATCHER_FILTER_REMOVE_EMPTY=on
export AISCATCHER_FILTER_UNIQUE=no AISCATCHER_FILTER_POSITION_INTERVAL=30 AISCATCHER_FILTER_OWN_INTERVAL=0
generate_filters
expected='{"allow_type":"1,2,3","block_type":"8","allow_repeat":"0,1","block_repeat":"3","allow_mmsi":"123456789,987654321","block_mmsi":"111111111","allow_channel":"AB","id":"0,4","gps":false,"ais":true,"remove_empty":true,"unique":false,"position_interval":"30","own_interval":"0","filter":true}'
jq -e --argjson expected "$expected" '. == $expected' <<< "{$output_filter_fields}" >/dev/null

udp_outputs=() tcp_outputs=() http_outputs=() mqtt_outputs=()
add_udp_feed '127.0.0.1:1234' ''
add_tcp_feed '127.0.0.1:1234' ''
add_http_feed 'https://example.com/'
add_mqtt_feed 'mqtt://example.com/'
for output in "${udp_outputs[@]}" "${tcp_outputs[@]}" "${http_outputs[@]}" "${mqtt_outputs[@]}"; do
    jq -e --argjson expected "$expected" '. as $output | $expected | to_entries | all(.[]; $output[.key] == .value)' <<< "$output" >/dev/null
done

eval "$viewer_block"
jq -e --argjson expected "$expected" '. as $output | $expected | to_entries | all(.[]; $output[.key] == .value)' <<< "{$server_json}" >/dev/null
[[ "$(grep -o '"filter"' <<< "$server_json" | wc -l)" == 1 ]]

root_screen='3'
config_json='{"config":"aiscatcher"'
# shellcheck disable=SC2016
eval "$(sed -n '/^screen_fields="\$output_filter_fields"/,/^config_json+=.*screen_fields/p' "$script")"
jq -e --argjson expected "$expected" '.screen as $output | $output.msgformat == "3" and ($expected | to_entries | all(.[]; $output[.key] == .value))' <<< "${config_json}}" >/dev/null

printf 'Shared output filter tests passed\n'