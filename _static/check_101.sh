#!/bin/bash

data="$(cat <<EOF
{\
"project_id":"$(curl -sL http://169.254.169.254/openstack/latest/meta_data.json | python -c 'import sys, json; print(json.load(sys.stdin)["project_id"])')",\
"flavor":"$(curl -sL http://169.254.169.254/latest/meta-data/instance-type | sed 's/-flex$//')",\
"release":"$(lsb_release -cs)",\
"hostname":"$(hostname)"\
}
EOF
)"

if ! out="$(curl -s -H "Content-Type: application/json" -d "${data}" https://{WORKSHOP_CHECK_SERVER}/101 2>&1)"
then
    echo "Cannot upload the results of the check: ${out}"
    exit 1
fi
echo "${out}"
