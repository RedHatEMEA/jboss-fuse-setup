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

karaf_commands

echo -e $GREEN"Assigning profiles..."$WHITE

echo -e $YELLOW"Waiting for fabric command: container-stop / container-remove-profile / container-add-profile / container-start"$WHITE
karaf_client wait-for-command fabric container-stop
karaf_client wait-for-command fabric container-remove-profile
karaf_client wait-for-command fabric container-add-profile
karaf_client wait-for-command fabric container-start

karaf_client fabric:container-stop --force gwy-001
karaf_client fabric:container-stop --force esb-001
karaf_client fabric:container-stop --force amq-001

wait_for_container_status "gwy-001" "stopped"
wait_for_container_status "esb-001" "stopped"
wait_for_container_status "amq-001" "stopped"

karaf_client fabric:container-remove-profile gwy-001 gateway-http gateway-mq
karaf_client fabric:container-remove-profile esb-001 jboss-fuse-minimal
karaf_client fabric:container-remove-profile amq-001 mq-amq

karaf_client fabric:container-add-profile gwy-001 rhc-gateway-http rhc-gateway-mq
karaf_client fabric:container-add-profile esb-001 rhc-esb
karaf_client fabric:container-add-profile amq-001 rhc-amq

karaf_client fabric:container-start --force amq-001
karaf_client fabric:container-start --force esb-001
karaf_client fabric:container-start --force gwy-001

wait_for_container_status "amq-001" "started"
wait_for_container_status "esb-001" "started"
wait_for_container_status "gwy-001" "started"
