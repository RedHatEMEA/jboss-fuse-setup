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

## How to run:
## cd /opt/rh/scripts
##      && assign-profiles.sh -e local

# Configure logging to print line numbers
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

# Set colours
GREEN="\e[32m"
RED="\e[41m\e[37m\e[1m"
YELLOW="\e[33m"
WHITE="\e[0m"

read -n1 -r -p "Press the any key..."

ARGS_COUNTER=0
while getopts ":e:x:" opt; do
  ARGS_COUNTER=$[$ARGS_COUNTER +1]

  case $opt in
    e) export DEPLOYMENT_ENVIRONMENT=$OPTARG
    ;;
    x) export DEBUG_MODE=$OPTARG
    ;;
    \?)
    echo -e $RED"Illegal parameters: -$OPTARG"$WHITE
    echo -e $RED"Usage: ./assign-profiles.sh -e (environment) -x (debug - optional)"$WHITE
    echo -e $RED"Example: ./assign-profiles.sh -e local -x true"$WHITE
    exit 1
    ;;
  esac
done

if [[ $ARGS_COUNTER -gt 3 ]]; then
    echo -e $RED"Illegal number of parameters: $ARGS_COUNTER"$WHITE
    echo -e $RED"Usage: ./assign-profiles.sh -e (environment) -x (debug - optional)"$WHITE
    echo -e $RED"Example: ./assign-profiles.sh -e local -x true"$WHITE
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

export RELEASE_VERSION="1.2"

# Set the environment variables for the selected environment
. ./envs/$DEPLOYMENT_ENVIRONMENT/environment.sh
. ./lib/helper_functions.sh

karaf_commands

echo -e $RED"Continuing with this process will change your enviorment!"$WHITE
read -n1 -r -p "If you continue, your current enviroment will be updated!"

## deploy profiles to containers
. ./envs/$DEPLOYMENT_ENVIRONMENT/assign-profiles.sh

exit 0
