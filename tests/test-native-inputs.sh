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

printf 'Native TCP and UDP input tests passed\n'