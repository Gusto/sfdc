({
    /* Update Case Status on Other non-focussed tabs Tabs */
    allTabChange : function(component, event, focussedCaseId){
        // to capture all the other tabs and check for status
        var workspaceAPI = component.find("workspace"); 
        // Get all tab Info  
        // Iterate over each tab, get record Id and ensure you are not adding focussed case Id  
        workspaceAPI.getAllTabInfo().then(function (response){
            // Declare a list of caseId
            var list_caseId = [];
            if(response && response.length > 0) {
                response.forEach(objTab => {
                    if(focussedCaseId !== objTab.recordId) {
                        list_caseId.push(objTab.recordId);
                    }
                });
        		// Check if list of case Id to be update are more than one, then update case status to Open
                if(list_caseId && list_caseId.length > 0) {
                    var action = component.get("c.checkAllPrimaryTabStatus");
                    action.setParams({ 'list_caseId' : list_caseId });
                    action.setCallback(this, function(r) {
                    });
                    $A.enqueueAction(action);
                }
            }
        });
    },

    handleCaseUpdate: function(component, event, idCase) {
        var action = component.get("c.getAnswers");
        var strStatuses = component.get("v.caseStatuses");
        var list_Statuses = [];

        if (strStatuses) {
            list_Statuses = strStatuses.split(",");
        }

        action.setParams({ 
            'idPrimaryCase' : idCase,
            'list_CaseStatuses' : list_Statuses
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {      
                // On successful response, fire app event
                // Added by Praveen to fire App Event
                let result = response.getReturnValue();
                if(result && result.blnIsSuccess && result.objCase) {
                    var evtCaseStatusChange = $A.get("e.c:caseStatusChangeEvent");
                    evtCaseStatusChange.setParams({
                        "idCase" : result.objCase.Id,
                        "strStatus": result.objCase.Status
                    });
                    evtCaseStatusChange.fire();
                }

                this.allTabChange(component, event, idCase);
            }                   
        });
        $A.enqueueAction(action); 
    }
})