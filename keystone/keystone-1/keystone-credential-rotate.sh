#!/usr/bin/env bash
# Copyright 2016, Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Ansible managed: /etc/ansible/roles/os_keystone/templates/keystone-credential-rotate.sh.j2 modified on 2017-02-10 10:07:55 by root on infra

# This script is being created with mode 0755 intentionally. This is so that the
#  script can be executed by root to rotate the keys as needed. The script being
#  executed will always change it's user context to the keystone user before
#  execution and while the script may be world read/executable its contains only
#  the necessary bits that are required to run the rotate and sync commands.

function autorotate {
    # Ensure all credentials are encrypted with the newest primary key so the rotation doesn't fail.
    /openstack/venvs/keystone-14.1.0/bin/keystone-manage credential_migrate \
                                       --keystone-user "keystone" \
                                       --keystone-group "keystone"

    # Rotate the keys
    /openstack/venvs/keystone-14.1.0/bin/keystone-manage credential_rotate \
                                       --keystone-user "keystone" \
                                       --keystone-group "keystone"

    # Ensure all credentials are encrypted with the new primary key
    /openstack/venvs/keystone-14.1.0/bin/keystone-manage credential_migrate \
                                       --keystone-user "keystone" \
                                       --keystone-group "keystone"

    
    
    # Fernet sync job to "infra_keystone_container-678798f5"
    rsync -e 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' \
          -avz \
          --delete \
          /etc/keystone/credential-keys/ \
          keystone@172.29.238.57:/etc/keystone/credential-keys/
    
}

if [ "$(id -u)" == "0" ];then
# Change the script context to always execute as the "keystone" user.
su - "keystone" -s "/bin/bash" -c bash << EOC
    /opt/keystone-credential-rotate.sh
EOC
elif [ "$(whoami)" == "keystone" ];then
    logger $(autorotate)
else
    echo "Failed - you do not have permission to rotate, or you've executed the job as the wrong user."
    exit 99
fi
