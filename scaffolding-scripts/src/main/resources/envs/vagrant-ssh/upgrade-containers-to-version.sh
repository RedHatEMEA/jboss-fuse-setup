 #!/usr/bin/env bash

###
# #%L
# RedHat Consulting :: JBoss Fuse Setup :: Scaffolding Scripts
# %%
# Copyright (C) 2013 - 2016 RedHat Consulting
# %%
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# #L%
###

# Set colours
GREEN="\e[32m"
RED="\e[41m\e[37m\e[1m"
YELLOW="\e[33m"
WHITE="\e[0m"

echo -e $GREEN"Upgrading containers to $RELEASE_VERSION..."$WHITE

echo -e $YELLOW"Waiting for fabric command: container-upgrade"$WHITE
karaf_client "wait-for-command fabric container-upgrade"

karaf_client "fabric:container-upgrade $RELEASE_VERSION amq-001"
wait_for_container_status "amq-001" "started"

karaf_client "fabric:container-upgrade $RELEASE_VERSION esb-001"
wait_for_container_status "esb-001" "started"

karaf_client "fabric:container-upgrade $RELEASE_VERSION gwy-001"
wait_for_container_status "gwy-001" "started"

karaf_client "fabric:container-upgrade $RELEASE_VERSION fabric-003"
wait_for_container_status "fabric-003" "started"

karaf_client "fabric:container-upgrade $RELEASE_VERSION fabric-002"
wait_for_container_status "fabric-002" "started"

karaf_client "fabric:container-upgrade $RELEASE_VERSION fabric-001"
wait_for_container_status "fabric-001" "started"
