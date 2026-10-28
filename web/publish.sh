#!/usr/bin/env bash
# Writes the front page of download.cutefish.org from the ISOs published in
# the bucket and uploads it, with the R2 credentials of the environment.
#
#   web/publish.sh BUCKET
set -Eeuo pipefail

BUCKET="$1"
BASE=https://download.cutefish.org/iso/nightly

s3() { aws s3 --endpoint-url "https://$R2_ACCOUNT_ID.r2.cloudflarestorage.com" "$@"; }

isos=()
for arch in amd64 arm64; do
  name="$(curl -fsSL "$BASE/LATEST-$arch" 2>/dev/null)" || continue
  headers="$(curl -fsSI "$BASE/$name.iso" | tr -d '\r')" || continue
  size="$(awk 'tolower($1) == "content-length:" { print $2 }' <<< "$headers")"
  built="$(sed -n 's/^[Ll]ast-[Mm]odified: //p' <<< "$headers")"
  digest="$(curl -fsSL "$BASE/$name.iso.sha256" | cut -d ' ' -f 1)"
  isos+=("$arch" "$name" "$size" "$digest" "$built")
done

"$(dirname "$0")/index.sh" "${isos[@]}" > index.html
s3 cp index.html "s3://$BUCKET/index.html"
s3 cp index.html "s3://$BUCKET/debian/index.html"

# The ISOs had a page and a LATEST of their own before the front page listed them.
s3 rm "s3://$BUCKET/iso/nightly/index.html"
s3 rm "s3://$BUCKET/iso/nightly/LATEST"
