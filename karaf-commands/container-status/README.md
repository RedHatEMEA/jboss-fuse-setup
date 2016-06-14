# container-status
Wait for a JBoss Fuse deployed container within a Fabric to be at a certain status.

# Build and Install
- mvn clean install
- fabric:profile-edit --repository mvn:com.redhat.consulting.fuse/container-status/1.0.0-SNAPSHOT/xml/features default
- fabric:profile-edit --feature container-status default

# Usage
## Wait for container to be started
- container-status --status started {container-name}
- container-status --status started --tick 1000 --wait 60000 {container-name}

## Wait for container to be stopped
- container-status --status stopped {container-name}
- container-status --status stopped --tick 1000 --wait 60000 {container-name}
