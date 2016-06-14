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

import io.fabric8.api.FabricService;
import org.apache.felix.gogo.commands.Action;
import org.apache.felix.service.command.CommandSession;
import org.junit.Ignore;
import org.junit.Test;
import org.mockito.Mockito;

//TODO: Add arquillian
@Ignore
public class ContainerStatusActionTest {

    @Test
    public void canDoExecute() throws Exception {
        FabricService service = Mockito.mock(FabricService.class);
        Action action = new ContainerStatusAction(service);

        action.execute(Mockito.mock(CommandSession.class));
    }
}
