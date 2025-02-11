({
    doInit: function (component, event, helper) {

        try {
            // check if case is eligible to be created from transcript & pass transcript record id to apex class
            var action = component.get("c.checkCaseCreateFromTranscript");
            action.setParams({ idChatTranscript: component.get("v.recordId") });
            
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    // check if return value is true
                    if (response.getReturnValue()) {

                        // set case creation is in progress
                        component.set("v.strMessage", "Case creation in progress...");
                        component.set("v.blnShowCase", true);

                        // send a callout to apex method to create modern bank case
                        var createCaseAction = component.get("c.createCaseFromTranscript");
                        createCaseAction.setParams({ idChatTranscript: component.get("v.recordId"), strRecordType: "Modern Bank" });
                        
                        createCaseAction.setCallback(this, function (createCaseResponse) {
                            var createCaseState = createCaseResponse.getState();
                            let idCase = createCaseResponse.getReturnValue();
                            // apex method returns case id
                            if (createCaseState === "SUCCESS") {   
                                // open newly created case in separate sub tab       
                                var workspaceAPI = component.find("workspace");
                                workspaceAPI.getFocusedTabInfo().then(function (response) {
                                    var strFocusedTabId = response.tabId;
                                    workspaceAPI.openSubtab({
                                        parentTabId: strFocusedTabId,
                                        recordId: idCase,
                                        focus: false
                                    });
                                })
                                    .catch(function (error) {
                                        console.log(error);
                                    });
                                // hide show case create flag.
                                component.set("v.blnShowCase", false);
                            }
                        });
                        $A.enqueueAction(createCaseAction);
                    }
                }
            });
            $A.enqueueAction(action);
        } catch (error) {
            console.log('error in create case from transcript component ', error);
        }
    }
})