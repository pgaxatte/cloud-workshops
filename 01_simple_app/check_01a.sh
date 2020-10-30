#!/bin/bash

(
    flavor="$(curl -sL http://169.254.169.254/latest/meta-data/instance-type | sed 's/-flex$//')"
    release="$(lsb_release -c | awk '{print $2}')"
    echo "${flavor}-${release}" | md5sum | cut -c-6
) 2>/dev/null
