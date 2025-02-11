({
    /* Update Case Status on Other non-focussed tabs Tabs */
    allTabChange : function(component, event, idFocusedCase){
        // to capture all the other tabs and check for status
        var workspaceAPI = component.find("workspace"); 
        // Get all tab Info  
        // Iterate over each tab, get record Id and ensure you are not adding focussed case Id  
        workspaceAPI.getAllTabInfo().then(function (response) {
            // Declare a list of caseId
            var list_caseId = [];
            if (response && response.length > 0) {
                response.forEach(objTab => {
                    if(idFocusedCase !== objTab.recordId) {
                        list_caseId.push(objTab.recordId);
                    }
                });
        		// Check if list of case Id to be update are more than one, then update case status to Open
                if (list_caseId && list_caseId.length > 0) {
                    var action = component.get("c.handleUnFocusedCaseEmailStatus");
                    action.setParams({ 'list_strNonFocusedCaseIds' : list_caseId });
                    action.setCallback(this, function(response) {
                        var state = response.getState();
                        var returnVal = response.getReturnValue();
                        if (state == "ERROR" || returnVal != 'success') {
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": "Error!",
                                "message": returnVal
                            });
                            toastEvent.fire();
                        }                        
                    });
                    $A.enqueueAction(action);
                }
            }
        });
    },
    handleCaseUpdate: function(component, event, idCase) {
        var action = component.get("c.handleFocusedCaseEmailStatus");
        action.setParams({ 'strFocusedCaseId' : idCase});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {  
                this.allTabChange(component, event, idCase);
            }                   
        });
        $A.enqueueAction(action); 
    }
})