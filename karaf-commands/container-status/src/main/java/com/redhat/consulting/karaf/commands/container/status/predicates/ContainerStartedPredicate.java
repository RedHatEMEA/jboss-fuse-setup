/*
 * #%L
 * RedHat Consulting :: Karaf Commands :: container-status
 * %%
 * Copyright (C) 2013 - 2016 RedHat Consulting
 * %%
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *      http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * #L%
 */
package com.redhat.consulting.karaf.commands.container.status.predicates;

import io.fabric8.api.Container;
import io.fabric8.api.DataStore;

import org.apache.commons.lang3.builder.ToStringBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ContainerStartedPredicate implements StatusPredicate {

    public static final String STARTED = "started";

    private static final Logger LOG = LoggerFactory.getLogger(ContainerStartedPredicate.class);

    private String containerName;
    private DataStore dataStore;

    public ContainerStartedPredicate(String containerName, DataStore dataStore) {
        this.containerName = containerName;
        this.dataStore = dataStore;
    }

    public Boolean matches(Container container) {
        Boolean isAlive = container.isAlive();
        String provisionStatus = container.getProvisionStatus();
        Boolean isProvisioningComplete = container.isProvisioningComplete();
        Boolean isProvisionComplete = provisionStatus.equalsIgnoreCase(Container.PROVISION_SUCCESS);
        Boolean isDependencyFrameworkComplete = false;

        String blueprintStatus = dataStore.getContainerAttribute(containerName, DataStore.ContainerAttribute.BlueprintStatus, "", false, false);
        if (!blueprintStatus.isEmpty()) {
            isDependencyFrameworkComplete = blueprintStatus.equalsIgnoreCase(STARTED);
        }

        String springStatus = dataStore.getContainerAttribute(containerName, DataStore.ContainerAttribute.SpringStatus, "", false, false);
        if (!springStatus.isEmpty()) {
            isDependencyFrameworkComplete = springStatus.equalsIgnoreCase(STARTED);
        }

        String provisionException = container.getProvisionException();
        Boolean hasNoProvisionException = provisionException == null;
        if (hasNoProvisionException) {
            provisionException = "";
        }

        LOG.trace(new ToStringBuilder(this)
                      .append("containerName", containerName)
                      .append("isAlive", isAlive)
                      .append("isProvisioningComplete", isProvisioningComplete)
                      .append("isDependencyFrameworkComplete", isDependencyFrameworkComplete)
                      .append("isProvisionComplete", isProvisionComplete)
                      .append("hasNoProvisionException", hasNoProvisionException)
                      .append("provisionException", provisionException)
                      .toString());

        return isAlive && isProvisioningComplete && isDependencyFrameworkComplete && isProvisionComplete && hasNoProvisionException;
    }
}
