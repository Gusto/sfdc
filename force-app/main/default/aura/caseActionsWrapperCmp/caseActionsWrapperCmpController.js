({
    /* Used to serve next case using play mode */
    /* Closes current tab and opens a new focussed tab */
    handleCloseTab : function(component, event, helper) {
        // workspace api
        var workspaceAPI = component.find("workspace");
        // next case in play mode to serve
        let idNextCaseToServe = event.getParam("idNextCaseToServe");
        // If next case exist open next case, close previous tab and save previous case
        if(idNextCaseToServe) {
            workspaceAPI.openTab({
                pageReference: {
                    "type": "standard__recordPage",
                    "attributes": {
                        "recordId": idNextCaseToServe,
                        "actionName":"view"
                    },
                    "state": {}
                },
                focus: true
            }).then(function(newTabResponse) {
                // Open focussed tab
                workspaceAPI.focusTab({tabId : newTabResponse});
                // Close previous Tab
                helper.closePreviousTab(component, event);
                // Save Case Changes
                helper.executeCaseSave(component, event);
            }).catch(function(error) {
                console.log(error);
            });
        } else {
            // If next does not exist, close just close previous tab and save previous case
            helper.closePreviousTab(component, event);
            helper.executeCaseSave(component, event);
        }
    },

    /* Receives event from answers aura component */
    /* It takes care of updating case status to In Progress when logged in user views a case that they own*/
    handleStatusChangeEvent: function(component, event, helper) {
        let idRecord = component.get('v.recordId');
        let idCase = event.getParam('idCase');
        let strStatus = event.getParam('strStatus');
        // check if record id from page is matching record id from event
        // ensure that the handler is only listening for correct records
        if(idCase === idRecord) {
            // pass status to lwc and update status
            component.find('caseAction').setStatus(strStatus);
        }
    },

    /* handling reload cases */
    /* when same cases are opened in multiple tabs, they need to be refreshed when case is updated */
    /* this method takes care and firing events */
    handleReloadCase: function(component, event, helper) {
        var idCase = event.getParam('data').idCase;
        var objTrackedFieldChanges = event.getParam('data').objTrackedFieldChanges;
        var caseUpdateEvent = $A.get("e.c:caseUpdateEvent");
        caseUpdateEvent.setParams({
            "idCase" : idCase,
            "objTrackedFieldChanges": objTrackedFieldChanges
        });
        caseUpdateEvent.fire();
    },

    /* Handling close focussed tab */
    /* When you solve a case, the focussed tab needs to be closed */
	handleCloseFocussedTab: function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.closeTab({tabId: component.get("v.focusedTabId")});

    },

    /* handling case update */
    /* when same cases are opened in multiple tabs, they need to be refreshed when case is updated */
    /* this method takes care of handling caseUpdateEvent */
    handleCaseUpdate: function(component, event, helper) {
        let idCase = event.getParam('idCase');
        let objTrackedFieldChanges = event.getParam('objTrackedFieldChanges');
        component.find('caseAction').loadCaseRecord(idCase, objTrackedFieldChanges);
    },

    /*Get the focused tab Id when component is loaded.*/
    doInit : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var strFocusedTabId = response.tabId;
            component.set("v.strFocusedTabId", strFocusedTabId);
        })
        .catch(function(error) {
            console.log(error);
        });
    }
})