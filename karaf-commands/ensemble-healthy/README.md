# ensemble-healthy
Wait for a JBoss Fuse ensemble to be become active and healthy.

# Build and Install
- mvn clean install
- fabric:profile-edit --repository mvn:com.redhat.consulting.fuse/ensemble-healthy/1.0.0-SNAPSHOT/xml/features default
- fabric:profile-edit --feature ensemble-healthy default

# Usage
## Wait for ensemble to be healthy
- ensemble-healthy {fabric1} {fabric2} {fabric3}
- ensemble-healthy --tick 1000 --wait 60000 {fabric1} {fabric2} {fabric3}
