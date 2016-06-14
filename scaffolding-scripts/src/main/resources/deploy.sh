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
set +x

## How to run:
## cd /opt/rh/scripts
##       && ./deploy.sh -e local -u fuse

# Configure logging to print line numbers
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

export RELEASE_VERSION="1.1"

# Set colours
GREEN="\e[32m"
RED="\e[41m\e[37m\e[1m"
YELLOW="\e[33m"
WHITE="\e[0m"

read -n1 -r -p "Press the any key..."

ARGS_COUNTER=0
while getopts ":e:u:x:" opt; do
  ARGS_COUNTER=$[$ARGS_COUNTER +1]

  case $opt in
    e) export DEPLOYMENT_ENVIRONMENT=$OPTARG
    ;;
    u) export SSH_USER=$OPTARG
    ;;
    x) export DEBUG_MODE=$OPTARG
    ;;
    \?)
    echo -e $RED"Illegal parameters: -$OPTARG"$WHITE
    echo -e $RED"Usage: ./deploy.sh -e (environment) -u (sshuser) -x (debug - optional)"$WHITE
    echo -e $RED"Example: ./deploy.sh -e local -u fuse -x true"$WHITE
    exit 1
    ;;
  esac
done

if [[ $ARGS_COUNTER -gt 3 ]]; then
    echo -e $RED"Illegal number of parameters: $ARGS_COUNTER"$WHITE
    echo -e $RED"Usage: ./deploy.sh -e (environment) -u (sshuser) -x (debug - optional)"$WHITE
    echo -e $RED"Example: ./deploy.sh -e local -u fuse -x true"$WHITE
    exit 1
fi

SUPPORTED_ENVS_ARRAY=($(ls -lrt $(pwd)/envs | grep -v grep | awk '{ print $9; }'))
if [[ " ${SUPPORTED_ENVS_ARRAY[@]} " =~ " ${DEPLOYMENT_ENVIRONMENT} " ]]; then
    echo -e $GREEN"Environment: $DEPLOYMENT_ENVIRONMENT"$WHITE
else
    echo -e $RED"Environment \"$DEPLOYMENT_ENVIRONMENT\" not supported. Expected: ${SUPPORTED_ENVS_ARRAY[@]}"$WHITE
    exit 1
fi

echo -e $GREEN"SSH_USER: $SSH_USER"$WHITE

if [[ "$DEBUG_MODE" == "true" ]]; then
    echo -e $GREEN"Debug mode"$WHITE
    set -x
fi

echo ""

# Set the environment variables for the selected environment
. ./envs/$DEPLOYMENT_ENVIRONMENT/environment.sh
. ./lib/helper_functions.sh

karaf_commands

if [[ ! -d $HOST_RH_HOME ]]; then
    echo -e $RED"$HOST_RH_HOME does not exist!"$WHITE
    exit 1
fi

if [[ -d "$HOST_FUSE_HOME/data" ]]; then
    echo -e $RED"$HOST_FUSE_HOME/data already exists!"$WHITE
    read -n1 -r -p "If you continue, your current enviroment will be deleted!"
fi

# Create fabric
. ./lib/destroy-and-deploy-clean-fabric.sh
. ./envs/$DEPLOYMENT_ENVIRONMENT/create-ensemble.sh

# Deploy containers
. ./envs/$DEPLOYMENT_ENVIRONMENT/create-brokers.sh
. ./envs/$DEPLOYMENT_ENVIRONMENT/create-app.sh
. ./envs/$DEPLOYMENT_ENVIRONMENT/create-gateways.sh

echo -e $GREEN"All containers have been created."$WHITE

# Reset debugging
echo -e $YELLOW"Waiting for fabric command: profile-edit"$WHITE
karaf_client wait-for-command fabric profile-edit

karaf_client fabric:profile-edit --pid io.fabric8.agent/org.ops4j.pax.url.mvn.repositories=\"$MAVEN_REPOSITORY\" default
karaf_client fabric:profile-edit --pid org.ops4j.pax.logging/log4j.logger.io.fabric8.service.ssh=INFO karaf
karaf_client fabric:profile-edit --pid \"org.ops4j.pax.logging/log4j.rootLogger=INFO, out, osgi:*\" karaf

if [[ $AMQ_INTERNAL_PASSWORD == "readline" ]]; then
    echo -e $GREEN"Enter password for 'amq' user"$WHITE
    read -p "Password for 'amq' user: " amqpass
    AMQ_INTERNAL_PASSWORD=$amqpass;
fi

echo -e $YELLOW"Waiting for jaas command: manage / useradd / update"$WHITE
karaf_client wait-for-command jaas manage
karaf_client wait-for-command jaas useradd
karaf_client wait-for-command jaas update
karaf_client jaas:manage --index 1\; jaas:useradd $AMQ_INTERNAL_USER $AMQ_INTERNAL_PASSWORD\; jaas:update

get_git_url

echo -e $GREEN"Deploy $DEPLOYMENT_ENVIRONMENT Done"$WHITE
exit 0
