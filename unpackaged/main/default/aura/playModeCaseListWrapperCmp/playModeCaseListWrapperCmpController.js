({
    handleOpenTab : function(component, event, helper) {

        var workspaceAPI = component.find("workspace");
        let list_cases = event.getParam("list_cases");
        // load first case - load other tabs later
        let objFirstCaseToLoad = list_cases[0];
        // open first case
        workspaceAPI.openTab({
            pageReference: {
                "type": "standard__recordPage",
                "attributes": {
                    "recordId": objFirstCaseToLoad.Id,
                    "actionName":"view"
                },
                "state": {}
            },
            focus: false
        }).then(function(response) {
            workspaceAPI.focusTab({tabId : response});
        }).catch(function(error) {
            console.log(error);
        });
    },

    // Minimize the utility once play mode is clicked
    handleMinimizeUtility: function(component, event, helper) {
        var utilityAPI = component.find("utilitybar");
        utilityAPI.minimizeUtility();
    }
})