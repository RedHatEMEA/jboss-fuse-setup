# Scaffolding Scripts

# How to run
## install-fuse-and-deploy.sh - from Maven Central
cd /tmp &&
    wget https://repo1.maven.org/maven2/com/redhat/consulting/jboss-fuse-setup/scaffolding-scripts/${project.version}/scaffolding-scripts-${project.version}-all.zip &&
    unzip scaffolding-scripts-*-all.zip &&
    cd scripts &&
    chmod -R 755 *.sh &&
    ./install-fuse-and-deploy.sh -e local

## install-fuse-and-deploy.sh - from Local
cd /tmp &&
    rm -rf scaffolding-scripts.zip scripts/ &&
    wget -O scaffolding-scripts.zip "http://localhost:8081/nexus/service/local/artifact/maven/redirect?g=com.redhat.consulting.jboss-fuse-setup&a=scaffolding-scripts&v=LATEST&p=zip&c=all&r=snapshots" &&
    unzip scaffolding-scripts.zip &&
    cd scripts &&
    chmod -R 755 *.sh &&
    ./install-fuse-and-deploy.sh -e local

### install-fuse.sh
cd /opt/rh/scripts &&
    ./install-fuse.sh -e local

### deploy.sh
cd /opt/rh/scripts &&
    ./deploy.sh -e local -u fuse

## mvn branch
todo

## post-profile-deploy.sh
cd /opt/rh/scripts &&
    ./post-profile-deploy.sh -e local -v 1.2

## upgrade-to-release.sh
cd /opt/rh/scripts &&
    ./upgrade-to-release.sh -e local -v 1.3
