#!/bin/sh
set -eu

archive_path="${archive_path:-archive}"
scheme="${scheme:-YaaglIOS}"
ipa_name="${ipa_name:-${scheme}.ipa}"
applications_dir="${archive_path}.xcarchive/Products/Applications"

if [ ! -d "$applications_dir" ]; then
  echo "Missing archived Applications directory: $applications_dir" >&2
  exit 1
fi

app_path="$(find "$applications_dir" -maxdepth 1 -type d -name "*.app" -print -quit)"
if [ -z "$app_path" ]; then
  echo "No .app bundle found in $applications_dir" >&2
  exit 1
fi

rm -rf Payload "$ipa_name"
mkdir Payload
cp -R "$app_path" Payload/
find Payload -name ".DS_Store" -delete

/usr/bin/zip -qry "$ipa_name" Payload -x "._*" -x "__MACOSX/*"
echo "Created $ipa_name from $app_path"
