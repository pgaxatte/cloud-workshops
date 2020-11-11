#!/bin/bash

data="$(cat <<EOF
{\
"project_id":"$(curl -sL http://169.254.169.254/openstack/latest/meta_data.json | python -c 'import sys, json; print(json.load(sys.stdin)["project_id"])')",\
"disks":"$(lsblk -ln -o NAME | grep -v sda | paste -s -d, -)",\
"mounts":"$(awk '/^\/dev\/sd[^a]/ { print $1 }' < /proc/mounts | paste -s -d, -)",\
"hostname":"$(hostname)"\
}
EOF
)"

if ! out="$(curl -s -H "Content-Type: application/json" -d "${data}" https://{WORKSHOP_CHECK_SERVER}/102 2>&1 | jq -r '.results[]')"
then
    echo "Cannot upload the results of the check: ${out}"
    exit 1
fi
echo "${out}"
