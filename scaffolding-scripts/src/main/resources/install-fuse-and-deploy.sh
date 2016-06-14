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
##       && ./install-fuse-and-deploy.sh -e local -u fuse

DEBUG_MODE=false

ARGS_COUNTER=0
while getopts ":e:u:x:" opt; do
  ARGS_COUNTER=$[$ARGS_COUNTER +1]

  case $opt in
    e) DEPLOYMENT_ENVIRONMENT=$OPTARG
    ;;
    u) SSH_USER=$OPTARG
    ;;
    x) DEBUG_MODE=$OPTARG
    ;;
    \?)
    echo -e $RED"Illegal parameters: -$OPTARG"$WHITE
    echo -e $RED"Usage: ./install-fuse-and-deploy.sh -e (environment) -u (sshuser) -x (debug - optional)"$WHITE
    echo -e $RED"Example: ./install-fuse-and-deploy.sh -e local -u fuse -x true"$WHITE
    exit 1
    ;;
  esac
done

./install-fuse.sh -e $DEPLOYMENT_ENVIRONMENT -x $DEBUG_MODE

cd /opt/rh/scripts/ &&
    ./deploy.sh -e $DEPLOYMENT_ENVIRONMENT -u $SSH_USER -x $DEBUG_MODE

exit 0;
