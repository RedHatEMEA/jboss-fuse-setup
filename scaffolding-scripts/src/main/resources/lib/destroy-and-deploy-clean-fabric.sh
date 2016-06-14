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

# Kill and clean fuse from all fuse hosts
echo -e $GREEN"Cleaning up ${#FUSE_HOSTS[@]} hosts : ${FUSE_HOSTS[@]}"$WHITE

for i in ${FUSE_HOSTS[@]}; do
    if [[ ${i} == $ROOT_NODE ]]; then
        #Step-2
		kill_karaf_instances

        #Step-3
		clear_karaf_container
        clear_other_folders
        clear_m2
	else
	    #Step-1
		ssh_copy_scripts "${i}"

		#Step-2
		ssh_kill_fuse "${i}"

		#Step-3
		ssh_clear_karaf_and_containers "${i}"
	fi
done

start_and_wait_for_karaf

echo -e $GREEN"Creating fabric for $ROOT_NODE_NAME..."$WHITE
karaf_client $FABRIC_CREATE_CMD

echo -e $YELLOW"Waiting for fabric command: info / container-list / profile-edit / version-create"$WHITE
karaf_client wait-for-command fabric info
karaf_client wait-for-command fabric container-info
karaf_client wait-for-command fabric profile-edit
karaf_client wait-for-command fabric version-create

echo -e $GREEN"Creating version $RELEASE_VERSION"$WHITE
karaf_client fabric:version-create --default $RELEASE_VERSION

echo -e $GREEN"Applying base config for mvn and logging"$WHITE

# Set maven repos
karaf_client fabric:profile-edit --pid io.fabric8.agent/org.ops4j.pax.url.mvn.repositories=\"$REMOTE_MAVEN_REPOSITORY\" default
karaf_client fabric:profile-edit --pid io.fabric8.agent/patch.repositories=\"$PATCH_MAVEN_REPOSITORY\" default

# Increase debugging
karaf_client fabric:profile-edit --append --pid org.ops4j.pax.logging/log4j.logger.org.apache.sshd.common.io.nio2.Nio2Session=INFO karaf
karaf_client fabric:profile-edit --append --pid org.ops4j.pax.logging/log4j.logger.io.fabric8.service.ssh=DEBUG karaf
karaf_client fabric:profile-edit --pid \"org.ops4j.pax.logging/log4j.rootLogger=DEBUG, out, osgi:*\" karaf
karaf_client fabric:profile-edit --append --pid org.ops4j.pax.logging/$RH_LOGGING karaf

# Install any helpful features for the future
karaf_client fabric:profile-edit --features fabric-zookeeper-commands fabric

echo -e $GREEN"Upgrading container to $RELEASE_VERSION"$WHITE
karaf_client fabric:container-upgrade $RELEASE_VERSION $ROOT_NODE_NAME

# Install container-status command
karaf_client fabric:profile-create --parents fabric com-rhc-fabriccommands
karaf_client fabric:profile-edit --repository mvn:com.redhat.consulting.karaf-commands/container-status/1.0.0/xml/features com-rhc-fabriccommands
karaf_client fabric:profile-edit --repository mvn:com.redhat.consulting.karaf-commands/ensemble-healthy/1.0.0/xml/features com-rhc-fabriccommands
karaf_client fabric:profile-edit --feature container-status com-rhc-fabriccommands
karaf_client fabric:profile-edit --feature ensemble-healthy com-rhc-fabriccommands

karaf_client fabric:container-add-profile $ROOT_NODE_NAME com-rhc-fabriccommands

wait_for_container_status "$ROOT_NODE_NAME" "started"
