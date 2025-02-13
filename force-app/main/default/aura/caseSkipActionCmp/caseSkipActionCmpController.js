({  
    // Handle Close tab closes focussed tab, opens a new case and also creates case skip history
    handleCloseTab : function(component, event, helper) {
    
        var workspaceAPI = component.find("workspace");
        let idNextCaseToServe = event.getParam("idNextCaseToServe");
        if(idNextCaseToServe) {
            // Opens next case
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
                // Focuses the new tab
                workspaceAPI.focusTab({tabId : newTabResponse});
                // Calls helper method to close previous tab
                helper.closePreviousTab(component, event);
                helper.executeCaseSkip(component, event);
            }).catch(function(error) {
                console.log(error);
            });
        } else {
            // If there are no next case. User reached Skip and Next on the last case served
            helper.closePreviousTab(component, event);
            helper.executeCaseSkip(component, event);
        }
    },

    // Sets logged in user info
    handleDoInit: function(component, event, helper) {
        component.set("v.idUser", $A.get("$SObjectType.CurrentUser.Id"));
    },
    // Refresh View - Standard Event 
    handleRefreshView: function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
    },
    // Hide the entire component
    handleHideComponent: function(component, event, helper) {
        component.set("v.blnShowComponent", false);
    }
})