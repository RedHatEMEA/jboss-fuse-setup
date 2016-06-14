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
## cd /tmp &&
##      wget https://repo1.maven.org/maven2/com/redhat/consulting/scaffolding-scripts/${project.version}/scaffolding-scripts-${project.version}-all.zip &&
##      unzip scaffolding-scripts-*-all.zip &&
##      cd scripts &&
##      chmod -R 755 install-fuse.sh &&
##      ./install-fuse.sh -e local

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
    echo -e $RED"Usage: ./install-fuse.sh -e (environment) -x (debug - optional)"$WHITE
    echo -e $RED"Example: ./install-fuse.sh -e local -x true"$WHITE
    exit 1
    ;;
  esac
done

if [[ $ARGS_COUNTER -gt 2 ]]; then
    echo -e $RED"Illegal number of parameters: $ARGS_COUNTER"$WHITE
    echo -e $RED"Usage: ./install-fuse.sh -e (environment) -x (debug - optional)"$WHITE
    echo -e $RED"Example: ./install-fuse.sh -e local -x true"$WHITE
    exit 1
fi

SUPPORTED_ENVS_ARRAY=($(ls -lrt $(pwd)/envs | grep -v grep | awk '{ print $9; }'))
if [[ " ${SUPPORTED_ENVS_ARRAY[@]} " =~ " ${DEPLOYMENT_ENVIRONMENT} " ]]; then
    echo -e $GREEN"Environment: $DEPLOYMENT_ENVIRONMENT"$WHITE
else
    echo -e $RED"Environment \"$DEPLOYMENT_ENVIRONMENT\" not supported. Expected: ${SUPPORTED_ENVS_ARRAY[@]}"$WHITE
    exit 1
fi

if [[ "$DEBUG_MODE" == "true" ]]; then
    echo -e $GREEN"Debug mode"$WHITE
    set -x
fi

echo ""

# Set the environment variables for the selected environment
. ./envs/$DEPLOYMENT_ENVIRONMENT/environment.sh
. ./lib/helper_functions.sh

FUSE_ZIP=jboss-fuse-full-6.2.1.redhat-084.zip
FUSE_ZIP_DOWNLOAD=http://$NEXUS_IP:8081/nexus/content/repositories/releases/org/jboss/fuse/jboss-fuse-full/6.2.1.redhat-084/$FUSE_ZIP
SCAFFOLDING_ZIP=$HOST_RH_HOME/scaffolding-scripts-${project.version}-all.zip
SCRIPTS_FOLDER=$HOST_RH_HOME/scripts

kill_karaf_instances

if [[ ! -d $HOST_RH_HOME ]]; then
    echo -e $RED"$HOST_RH_HOME does not exist!"$WHITE
    exit 1
fi

if [[ -d $HOST_FUSE_HOME ]]; then
    echo -e $RED"$HOST_FUSE_HOME already exists!"$WHITE
    read -n1 -r -p "If you continue, your current enviroment will be deleted!"

    echo -e $YELLOW"Removing old: $HOST_FUSE_HOME"$WHITE
    rm -rf $HOST_FUSE_HOME

    if [[ -d $HOST_FUSE_HOME ]]; then
        echo -e $RED"Couldnt delete: $HOST_FUSE_HOME :: rm -rf $HOST_FUSE_HOME"$WHITE
        exit 1
    fi
fi

if [[ $DOWNLOAD_FUSE_ZIP == "true" ]]; then
    if [[ -a $HOST_RH_HOME/$FUSE_ZIP ]]; then
        echo -e $YELLOW"Removing old: $HOST_RH_HOME/$FUSE_ZIP"$WHITE
        rm -rf $HOST_RH_HOME/$FUSE_ZIP
    fi
fi

if [[ -a $SCAFFOLDING_ZIP ]]; then
    echo -e $YELLOW"Removing old: $SCAFFOLDING_ZIP"$WHITE
    rm -f $SCAFFOLDING_ZIP
fi

if [[ -d $SCRIPTS_FOLDER ]]; then
    echo -e $YELLOW"Removing old: $SCRIPTS_FOLDER"$WHITE
    rm -rf $SCRIPTS_FOLDER
fi

echo -e $YELLOW"Removing any fabric8* or jboss-fuse* files/folders from /tmp"$WHITE
rm -rf /tmp/fabric8* /tmp/jboss-fuse*

echo -e $GREEN"Starting JBoss Fuse install..."$WHITE

if [[ $KARAF_PASSWORD == "readline" ]]; then
    echo -e $GREEN"Enter password for 'admin' user"$WHITE
    read -p "Password for 'admin' user: " adminpass
    KARAF_PASSWORD=$adminpass;

    sed -i 's/KARAF_PASSWORD=readline/KARAF_PASSWORD=$KARAF_PASSWORD/' /tmp/scripts/envs/$DEPLOYMENT_ENVIRONMENT/environment.sh
fi

if [[ $DOWNLOAD_FUSE_ZIP == "true" ]]; then
    echo -e $GREEN"Downloading JBoss Fuse.zip..."$WHITE

    cd $HOST_RH_HOME &&
        wget $FUSE_ZIP_DOWNLOAD &&
        unzip $FUSE_ZIP
else
    echo -e $GREEN"Unzipping JBoss Fuse.zip..."$WHITE

    cd $HOST_RH_HOME &&
        unzip $FUSE_ZIP
fi

if [[ ! -d $HOST_FUSE_HOME ]]; then
    echo -e $RED"$HOST_FUSE_HOME doesnt exist"$WHITE
    exit 1;
fi

echo -e $GREEN"Applying base config..."$WHITE
sed -i 's/encryption.enabled = false/encryption.enabled = true/' $HOST_FUSE_HOME/etc/org.apache.karaf.jaas.cfg
sed -i "s/karaf.name = root/karaf.name = $ROOT_NODE_NAME/" $HOST_FUSE_HOME/etc/system.properties
sed -i 's/JAVA_MIN_MEM=512M/JAVA_MIN_MEM=1024M/' $HOST_FUSE_HOME/bin/setenv
sed -i 's/JAVA_MAX_MEM=512M/JAVA_MAX_MEM=1024M/' $HOST_FUSE_HOME/bin/setenv

cd /tmp &&
    cp -R scripts $SCRIPTS_FOLDER
    cd $SCRIPTS_FOLDER &&
    chmod -R 755 *.sh commands/*.sh envs/$DEPLOYMENT_ENVIRONMENT/*.sh

cat >> $HOST_FUSE_HOME/etc/users.properties <<EOT

$KARAF_USER=$KARAF_PASSWORD,admin,manager,viewer,Monitor, Operator, Maintainer, Deployer, Auditor, Administrator, SuperUser
EOT

echo -e $GREEN"Install fuse $DEPLOYMENT_ENVIRONMENT Done"$WHITE
exit 0
