/*
 * #%L
 * RedHat Consulting :: Karaf Commands :: ensemble-healthy
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
package com.redhat.consulting.karaf.commands.ensemble.healthy;

import java.util.Collections;
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import io.fabric8.api.ZooKeeperClusterService;
import org.apache.commons.collections4.ListUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.felix.gogo.commands.Argument;
import org.apache.felix.gogo.commands.Command;
import org.apache.felix.gogo.commands.Option;
import org.apache.karaf.shell.console.AbstractAction;

@Command(name = EnsembleHealthy.FUNCTION_VALUE, scope = EnsembleHealthy.SCOPE_VALUE, description = EnsembleHealthy.DESCRIPTION)
public class EnsembleHealthyAction extends AbstractAction {

    static final String FORMAT = "%-30s %s";

    @Option(name = "--tick", aliases = "-t", required = false, multiValued = false, description = "Time between checks in milliseconds", valueToShowInHelp = "5000")
    protected long tick;

    @Option(name = "--wait", aliases = "-w", required = false, multiValued = false, description = "Time to wait until process fails in milliseconds", valueToShowInHelp = "60000")
    protected long wait;

    @Argument(index = 0, name = "container", description = "The name of the containers.", required = true, multiValued = true)
    private List<String> containers;

    private final ZooKeeperClusterService clusterService;

    EnsembleHealthyAction(ZooKeeperClusterService clusterService) {
        this.clusterService = clusterService;
    }

    @Override
    protected Object doExecute() throws Exception {
        if (tick <= 0) {
            tick = TimeUnit.SECONDS.toMillis(5);
        }

        if (wait <= 0) {
            wait = TimeUnit.MINUTES.toMillis(1);
        }

        //Sort them to be alphabetical
        Collections.sort(containers);

        log.trace("Checking ensemble of {} for {} every {}ms until {}ms.", StringUtils.join(containers, ','), tick, wait);

        Boolean hasTimedOut = waitForEnsembleHealthy();
        if (hasTimedOut) {
            throw new TimeoutException("Took longer than wait value");
        }

        return null;
    }

    protected Boolean waitForEnsembleHealthy() throws InterruptedException {
        Boolean hasTimedOut = false;

        Long currentTime = System.nanoTime();
        Long waitTimeout = currentTime + TimeUnit.MILLISECONDS.toNanos(wait);

        while (!hasTimedOut) {
            List<String> containersInEnsemble = clusterService.getEnsembleContainers();

            //Sort them to be alphabetical
            Collections.sort(containersInEnsemble);

            Boolean isEqualList = ListUtils.isEqualList(containers, containersInEnsemble);
            if (isEqualList) {
                log.trace("MATCH: Expected: {}, Result: {}", StringUtils.join(containers, ','), StringUtils.join(containersInEnsemble, ','));

                System.out.println(String.format(FORMAT, "Ensemble List: ", StringUtils.join(containersInEnsemble, ',')));
                System.out.println("Ensemble Healthy: success");
                break;

            } else {
                log.trace("NON-MATCH: Expected: {}, Result: {}. Waiting...", StringUtils.join(containers, ','), StringUtils.join(containersInEnsemble, ','));
            }

            currentTime = System.nanoTime();
            if (currentTime > waitTimeout) {
                log.trace("Ensemble of {} took too long. Current time {}ns is greater than wait {}ns", StringUtils.join(containers, ','), currentTime, waitTimeout);

                hasTimedOut = true;
                break;
            }

            //Probably not the best way, but does its job
            TimeUnit.MILLISECONDS.sleep(tick);
        }

        return hasTimedOut;
    }
}
