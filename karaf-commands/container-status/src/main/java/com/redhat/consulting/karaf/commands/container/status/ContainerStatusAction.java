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
package com.redhat.consulting.karaf.commands.container.status;

import java.util.Locale;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import com.redhat.consulting.karaf.commands.container.status.predicates.ContainerStartedPredicate;
import com.redhat.consulting.karaf.commands.container.status.predicates.ContainerStoppedPredicate;
import com.redhat.consulting.karaf.commands.container.status.predicates.StatusPredicate;

import io.fabric8.api.Container;
import io.fabric8.api.DataStore;
import io.fabric8.api.FabricService;
import io.fabric8.boot.commands.support.FabricCommand;
import org.apache.felix.gogo.commands.Argument;
import org.apache.felix.gogo.commands.Command;
import org.apache.felix.gogo.commands.Option;
import org.apache.karaf.shell.console.AbstractAction;

@Command(name = ContainerStatus.FUNCTION_VALUE, scope = ContainerStatus.SCOPE_VALUE, description = ContainerStatus.DESCRIPTION)
public class ContainerStatusAction extends AbstractAction {

    static final String FORMAT = "%-30s %s";

    @Option(name = "--status", aliases = "-s", required = true, multiValued = false, description = "Status of container. Possible values are: started, stopped)", valueToShowInHelp = "started")
    protected String status;

    @Option(name = "--tick", aliases = "-t", required = false, multiValued = false, description = "Time between checks in milliseconds", valueToShowInHelp = "5000")
    protected long tick;

    @Option(name = "--wait", aliases = "-w", required = false, multiValued = false, description = "Time to wait until process fails in milliseconds", valueToShowInHelp = "60000")
    protected long wait;

    @Argument(index = 0, name = "container", description = "The name of the container.", required = true, multiValued = false)
    private String containerName;

    private final FabricService fabricService;
    private final DataStore dataStore;

    ContainerStatusAction(FabricService fabricService) {
        this.fabricService = fabricService;
        this.dataStore = fabricService.adapt(DataStore.class);
    }

    @Override
    protected Object doExecute() throws Exception {
        if (tick <= 0) {
            tick = TimeUnit.SECONDS.toMillis(5);
        }

        if (wait <= 0) {
            wait = TimeUnit.MINUTES.toMillis(1);
        }

        log.trace("Checking status of {} for {} every {}ms until {}ms.", status, containerName, tick, wait);

        Container container = FabricCommand.getContainer(fabricService, containerName);

        Boolean hasTimedOut;
        if (status.equals(ContainerStartedPredicate.STARTED)) {
            hasTimedOut = waitForContainerStatus(container, new ContainerStartedPredicate(containerName, dataStore));
        } else if (status.equals(ContainerStoppedPredicate.STOPPED)) {
            hasTimedOut = waitForContainerStatus(container, new ContainerStoppedPredicate(containerName, dataStore));
        } else {
            throw new IllegalArgumentException("Status " + status + " does not exist. Expected '"
                                               + ContainerStartedPredicate.STARTED + "' or '" + ContainerStoppedPredicate.STOPPED + "'");
        }

        if (hasTimedOut) {
            throw new TimeoutException("Took longer than wait value");
        }

        return null;
    }

    protected Boolean waitForContainerStatus(Container container, StatusPredicate predicate) throws InterruptedException {
        Boolean hasTimedOut = false;

        Long currentTime = System.nanoTime();
        Long waitTimeout = currentTime + TimeUnit.MILLISECONDS.toNanos(wait);

        while (!hasTimedOut) {
            Boolean isComplete = predicate.matches(container);
            if (isComplete) {
                log.trace("{} matches status {}", containerName, status);
                break;
            }

            currentTime = System.nanoTime();
            if (currentTime > waitTimeout) {
                log.trace("{} status took too long. Current time {}ns is greater than wait {}ns", containerName, currentTime, waitTimeout);

                hasTimedOut = true;
                break;
            }

            //Probably not the best way, but does its job
            TimeUnit.MILLISECONDS.sleep(tick);
        }

        printContainerStatus(container, predicate);

        return hasTimedOut;
    }

    private void printContainerStatus(Container container, StatusPredicate predicate) {
        System.out.println(String.format(FORMAT, "Name:", container.getId()));
        System.out.println(String.format(FORMAT, "Connected:", container.isAlive()));

        Long processId = container.getProcessId();
        if (processId != null) {
            System.out.println(String.format(FORMAT, "Process ID:", processId.toString()));
        }

        String blueprintStatus = dataStore.getContainerAttribute(containerName, DataStore.ContainerAttribute.BlueprintStatus, "", false, false);
        if (!blueprintStatus.isEmpty()) {
            System.out.println(String.format(FORMAT, "Blueprint Status:", blueprintStatus.toLowerCase(Locale.ENGLISH)));
        }

        String springStatus = dataStore.getContainerAttribute(containerName, DataStore.ContainerAttribute.SpringStatus, "", false, false);
        if (!springStatus.isEmpty()) {
            System.out.println(String.format(FORMAT, "Spring Status:", springStatus.toLowerCase(Locale.ENGLISH)));
        }

        System.out.println(String.format(FORMAT, "Provision Status:", container.getProvisionStatus()));
        if (container.getProvisionException() != null) {
            System.out.println(String.format(FORMAT, "Provision Error:", container.getProvisionException()));
        }

        String overall = predicate.matches(container) ? "success" : "failed";
        System.out.println("Overall Status: " + overall);
    }
}
