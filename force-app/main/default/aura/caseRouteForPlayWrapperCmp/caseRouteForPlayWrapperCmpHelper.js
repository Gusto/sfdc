({
    closePreviousTab : function(component, event, idCaseToClose) {

        var workspaceAPI = component.find("workspace");
        // Iterate over all tabs. Check if record id matches with idCaseToClose
        workspaceAPI.getAllTabInfo().then(function(response) {
            response.forEach(eachTab => {
                if(eachTab.recordId === idCaseToClose ) {
                    workspaceAPI.closeTab({tabId: eachTab.tabId});
                }
            });
        })
        .catch(function(error) {
            console.log('Error in caseRouteForPlayWrapperController - handleOpenCaseTab ', error);
        });
    },

    getTabPermissions : function(component) {
        var action = component.get("c.getTabVisibilityPermissions");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let objTabPermissions = response.getReturnValue();
                component.set("v.blnCanQA", objTabPermissions.blnQAPlayPermission);
                component.set("v.blnCaseDetailPlay", objTabPermissions.blnCaseDetailPlayPermission);
            }
        });
        $A.enqueueAction(action); 
    }
})