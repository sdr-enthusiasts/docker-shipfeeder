#!/usr/bin/env bash
# shellcheck disable=SC2034
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_dir/rootfs/etc/s6-overlay/scripts/aiscatcher"
json_helpers="$(sed -n '/^json_esc() {/,/^jstr() {/p' "$script")"
input_parser="$(sed -n '/^# Native UDP inputs/,/^# Add a number of well-known feeders:/p' "$script")"

generate_inputs() (
    set +eu
    eval "$json_helpers"
    s6wrap=()
    additional_receiver_entries=()
    AISCATCHER_UDP_INPUTS="$1"
    AISCATCHER_TCP_INPUTS="$2"
    eval "$input_parser"
    printf '%s\n' "${additional_receiver_entries[@]}" | jq -s .
)

generated="$(generate_inputs ':9988,shipfeeder:9989:AB CD' ':23,192.0.2.1:99:n2k,:100:TXT,:101:basestation,:102:RAW1090,:103:NMEA')"
jq -e 'length == 8 and
    .[0] == {input:"udpserver",udpserver:{server:"0.0.0.0",port:"9988"}} and
    .[1] == {input:"udpserver",udpserver:{server:"shipfeeder",port:"9989"}} and
    .[2] == {input:"tcpserver",tcpserver:{server:"0.0.0.0",port:"23"}} and
    .[3] == {input:"tcpserver",tcpserver:{server:"192.0.2.1",port:"99",format:"N2K"}} and
    .[4].tcpserver.format == "TXT" and
    .[5].tcpserver.format == "BASESTATION" and
    .[6].tcpserver.format == "RAW1090" and
    .[7].tcpserver.format == "TXT"' <<< "$generated" >/dev/null

generated="$(generate_inputs ':9988:Dzi UDP,:9989:AB:Legacy feed,:9990:AB:TXT:With format,:9991:,:9992:A "quoted" \\ feed,:9993:::AB' ':23::Dzi feed,:24:TXT:With format,:25::,:26:RAW1090:Aircraft feed,:27:TCP feed,:28::TXT')"
jq -e 'length == 12 and
    .[0] == {input:"udpserver",description:"Dzi UDP",udpserver:{server:"0.0.0.0",port:"9988"}} and
    .[1].description == "Legacy feed" and .[2].description == "With format" and
    (.[3] | has("description") | not) and .[4].description == "A \"quoted\" \\\\ feed" and .[5].description == "AB" and
    .[6] == {input:"tcpserver",description:"Dzi feed",tcpserver:{server:"0.0.0.0",port:"23"}} and
    .[7].description == "With format" and .[7].tcpserver.format == "TXT" and
    (.[8] | has("description") | not) and .[9].description == "Aircraft feed" and
    .[10] == {input:"tcpserver",description:"TCP feed",tcpserver:{server:"0.0.0.0",port:"27"}} and
    .[11].description == "TXT" and (.[11].tcpserver | has("format") | not)' <<< "$generated" >/dev/null

for invalid in ':9988:JSON_NMEA' ':9988:AB:JSON_FULL' ':0' ':65536' ':notaport'; do
    if generate_inputs "$invalid" '' >/dev/null; then
        printf 'Unexpectedly accepted UDP input %s\n' "$invalid" >&2
        exit 1
    fi
done
for invalid in ':9988:Bad:description' ':9988:AB:Bad:description'; do
    if generate_inputs "$invalid" '' >/dev/null; then
        printf 'Unexpectedly accepted UDP description %s\n' "$invalid" >&2
        exit 1
    fi
done
for invalid in ':9988:JSON_FULL' ':9988:JSON_NMEA' ':0' ':65536' ':notaport'; do
    if generate_inputs '' "$invalid" >/dev/null; then
        printf 'Unexpectedly accepted TCP input %s\n' "$invalid" >&2
        exit 1
    fi
done
if generate_inputs '' ':9988::Bad:description' >/dev/null; then
    printf 'Unexpectedly accepted TCP description containing a colon\n' >&2
    exit 1
fi

adsb_parser="$(sed -n '/^# ADSB connector becomes/,/^# Assemble the final JSON/p' "$script")"
generate_adsb() (
    set +eu
    eval "$json_helpers"
    additional_receiver_entries=()
    ADSB_CONNECTOR="$1"
    FEEDER_LAT="$2"
    FEEDER_LONG="$3"
    eval "$adsb_parser"
    printf '%s\n' "${additional_receiver_entries[@]}" | jq -s .
)

for connector in 'beast,readsb,30005' 'beast,readsb,30005,'; do
    generate_adsb "$connector" '' '' | jq -e 'length == 1 and .[0] == {input:"RTLTCP",description:"ADSB Input",rtltcp:{protocol:"beast",host:"readsb",port:30005}}' >/dev/null
done
generate_adsb 'raw1090,readsb,30002,Roof "ADS-B"' '42.1' '-71.2' | jq -e 'length == 1 and .[0].description == "Roof \"ADS-B\"" and .[0].lat == "42.1" and .[0].lon == "-71.2" and .[0].rtltcp.protocol == "raw1090"' >/dev/null
for invalid_port in 0 65536 notaport; do
    if generate_adsb "beast,readsb,$invalid_port" '' '' >/dev/null; then
        printf 'Unexpectedly accepted ADS-B port %s\n' "$invalid_port" >&2
        exit 1
    fi
done

# shellcheck disable=SC2016
sdr_parser="$(sed -n '/^# Build the primary SDR receiver/,/^if \[\[ -n "${AISCATCHER_MQTT_URL}" \]\]; then/p' "$script" | sed '$d')"
generate_sdr() (
    set +eu
    eval "$json_helpers"
    # shellcheck disable=SC2317
    chk_enabled() { return 1; }
    # shellcheck disable=SC2317
    chk_disabled() { return 1; }
    # shellcheck disable=SC2317
    jbool_enabled() { printf false; }
    receiver_entries=()
    RTLSDR_DEVICE_SERIAL="$1"
    if [[ "$2" == '__unset__' ]]; then
        unset RTLSDR_DEVICE_DESCRIPTION
    else
        RTLSDR_DEVICE_DESCRIPTION="$2"
    fi
    SDR_TYPE=RTLSDR
    DEVICE_JSON_KEY=rtlsdr
    DEVICE_JSON_FIELDS='"tuner":"auto"'
    receiver_verbose=false
    eval "$sdr_parser"
    printf '%s\n' "${receiver_entries[@]}" | jq -s 'map(select(. != null))'
)

generate_sdr '12345678' 'Roof "AIS"' | jq -e 'length == 1 and .[0].description == "Roof \"AIS\"" and .[0].serial == "12345678" and (.[0].rtlsdr | has("description") | not)' >/dev/null
generate_sdr '12345678' '' | jq -e 'length == 1 and .[0].description == "12345678"' >/dev/null
generate_sdr '12345678' '__unset__' | jq -e 'length == 1 and .[0].description == "12345678"' >/dev/null
generate_sdr '' 'Unused name' | jq -e 'length == 0' >/dev/null

printf 'Native TCP and UDP input tests passed\n'