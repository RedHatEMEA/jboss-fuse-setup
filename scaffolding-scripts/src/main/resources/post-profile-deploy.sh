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
##      && ./post-profile-deploy.sh -e local -v 1.2

# Configure logging to print line numbers
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

# Set colours
GREEN="\e[32m"
RED="\e[41m\e[37m\e[1m"
YELLOW="\e[33m"
WHITE="\e[0m"

read -n1 -r -p "Press the any key..."

ARGS_COUNTER=0
while getopts ":e:v:x:" opt; do
  ARGS_COUNTER=$[$ARGS_COUNTER +1]

  case $opt in
    e) export DEPLOYMENT_ENVIRONMENT=$OPTARG
    ;;
    v) export RELEASE_VERSION=$OPTARG
    ;;
    x) export DEBUG_MODE=$OPTARG
    ;;
    \?)
    echo -e $RED"Illegal parameters: -$OPTARG"$WHITE
    echo -e $RED"Usage: ./post-profile-deploy.sh -e (environment) -v (version) -x (debug - optional)"$WHITE
    echo -e $RED"Example: ./post-profile-deploy.sh -e local -v 1.2 -x true"$WHITE
    exit 1
    ;;
  esac
done

if [[ $ARGS_COUNTER -gt 3 ]]; then
    echo -e $RED"Illegal number of parameters: $ARGS_COUNTER"$WHITE
    echo -e $RED"Usage: ./post-profile-deploy.sh -e (environment) -v (version) -x (debug - optional)"$WHITE
    echo -e $RED"Example: ./post-profile-deploy.sh -e local -v 1.2 -x true"$WHITE
    exit 1
fi

SUPPORTED_ENVS_ARRAY=($(ls -lrt $(pwd)/envs | grep -v grep | awk '{ print $9; }'))
if [[ " ${SUPPORTED_ENVS_ARRAY[@]} " =~ " ${DEPLOYMENT_ENVIRONMENT} " ]]; then
    echo -e $GREEN"Environment: $DEPLOYMENT_ENVIRONMENT"$WHITE
else
    echo -e $RED"Environment \"$DEPLOYMENT_ENVIRONMENT\" not supported. Expected: ${SUPPORTED_ENVS_ARRAY[@]}"$WHITE
    exit 1
fi

echo -e $GREEN"RELEASE_VERSION: $RELEASE_VERSION"$WHITE

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

echo -e $RED"Continuing with this process will change your enviorment!"$WHITE
read -n1 -r -p "If you continue, your current enviroment will be changed!"
read -n1 -r -p "Only continue if you have deployed all fabric8-profiles for this enviroment!"

## Deploy profiles to containers
. ./envs/$DEPLOYMENT_ENVIRONMENT/upgrade-containers-to-version.sh

echo -e $YELLOW"Waiting for fabric command: version-set-default"$WHITE
karaf_client wait-for-command fabric version-set-default

echo -e $YELLOW"Updating default version to $RELEASE_VERSION"$WHITE
karaf_client fabric:version-set-default $RELEASE_VERSION

. ./envs/$DEPLOYMENT_ENVIRONMENT/assign-profiles.sh

echo -e $GREEN"Post profile deploy $DEPLOYMENT_ENVIRONMENT / $RELEASE_VERSION: Done"$WHITE
exit 0
