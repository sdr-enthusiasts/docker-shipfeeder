#!/bin/bash
# shellcheck shell=bash disable=SC2015

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

SHA_FILE="aiscatcher.sha"

[ -z "$CHECK_CONTAINER" ] && CHECK_CONTAINER="$1" || true
[ -z "$CHECK_TAG" ] && CHECK_TAG="$2" || true

TOKEN="$(curl -sSL "https://ghcr.io/token?scope=repository:$CHECK_CONTAINER:pull" | awk -F'"' '$0=$4')"
manifest="$(curl -sSL -H "Authorization: Bearer ${TOKEN}" "https://ghcr.io/v2/$CHECK_CONTAINER/manifests/$CHECK_TAG")"
SHAs_remote="$(echo "$manifest"|jq '.manifests[].digest')"
SHAs_remote="${SHAs_remote//$'\n'/}"

if grep "error" <<< "$TOKEN $manifest" >/dev/null 2>&1
then
    echo "Error retrieving Token or Manifest."
    echo "TOKEN=$TOKEN"
    echo "MANIFEST=$manifest"
    exit 2
fi

#echo "TOKEN=$TOKEN"
#echo "manifest=$manifest"

touch "$SHA_FILE"
read -r SHAs_local < "$SHA_FILE"
# now compare:
if [ "$SHAs_local" != "$SHAs_remote" ]; then
    # we need to rebuild
    echo "$SHAs_remote" > "$SHA_FILE"
    git config --local user.name actions-user
    git config --local user.email "actions@github.com"
    git add "$SHA_FILE"
    git commit -am "GH Action SHA updated $(date)"
    git push -f origin main
    echo "Success - container needs rebuilding"
    exit 0
else
    echo "Remote container has not changed, no need to run deploy. Exiting."
    exit 1
fi
