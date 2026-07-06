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

case "$ipa_name" in
  /*) ipa_path="$ipa_name" ;;
  *) ipa_path="$(pwd)/$ipa_name" ;;
esac

payload_root="$(mktemp -d)"
trap 'rm -rf "$payload_root"' EXIT

rm -f "$ipa_path"
mkdir "$payload_root/Payload"
cp -R "$app_path" "$payload_root/Payload/"
find "$payload_root/Payload" -type d -name "_CodeSignature" -prune -exec rm -rf {} +
find "$payload_root/Payload" -name "embedded.mobileprovision" -delete
find "$payload_root/Payload" -name ".DS_Store" -delete

(
  cd "$payload_root"
  /usr/bin/zip -qry "$ipa_path" Payload -x "._*" -x "__MACOSX/*"
)
echo "Created $ipa_path from $app_path"
