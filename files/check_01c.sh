#!/bin/bash

data="$(cat <<EOF
{\
"id":"01c",\
"project_id":"$(curl -sL http://169.254.169.254/openstack/latest/meta_data.json | python -c 'import sys, json; print(json.load(sys.stdin)["project_id"])')",\
"ip_eth1":"$(ip addr show eth1 2>/dev/null | sed -n 's/\s\+inet \(.*\)\/.*/\1/p')",\
"hostname":"$(hostname)"\
}
EOF
)"

if ! out="$(curl -X POST -H "Content-Type: application/json" -d "${data}" https://{{WORKSHOP_SERVER}}/ 2>&1)"
then
    echo "Cannot upload the results of the check: ${out}"
    exit 1
fi
echo "${out}"
