#!/usr/bin/env bash

set -e

CHECK_INTERVAL=30

# use TCPDUMP to monitor UDP packets sent internally to port 34995. If none are sent, things are unhealthy.

PACKETCOUNT="$(grep captured <<< "$(timeout --preserve-status $CHECK_INTERVAL tcpdump -p -i lo udp port 34995 2>/dev/stdout 1>/dev/null)"| awk '{print $1}')"
if [[ -z "$PACKETCOUNT" ]] || [[ "$PACKETCOUNT" -lt 1 ]]
then
    echo "No data received from SDR for $CHECK_INTERVAL or more seconds. UNHEALTHY"
    EXITCODE=1
else
    echo "$PACKETCOUNT packets received from SDR during the last $CHECK_INTERVAL seconds. HEALTHY"
    EXITCODE=0
fi

exit $EXITCODE
