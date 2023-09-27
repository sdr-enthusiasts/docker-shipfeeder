#!/command/with-contenv bash
# shellcheck shell=bash 

#---------------------------------------------------------------------------------------------
# Copyright (C) 2022-2023, Ramon F. Kolb (kx1t)
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program.
# If not, see <https://www.gnu.org/licenses/>.
#---------------------------------------------------------------------------------------------

set -e

CHECK_INTERVAL=180

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
