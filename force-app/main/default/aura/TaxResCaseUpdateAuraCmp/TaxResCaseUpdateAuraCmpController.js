({      
    /* Whenever a tab is focused, perform an apex call
    to update case status to In Progress when Case OwnerId
    matches Logged In User Id */
    onTabFocused : function(component, event, helper) {
        let idFocusedTab = event.getParam('currentTabId');
        let workspaceAPI = component.find("workspace");
        // Get Focused Tab Info
        workspaceAPI.getTabInfo({
            tabId : idFocusedTab
        }).then(function(response) {  
            // Validate if it's record page and record type is Case
            // Adding additional check to ensure if the case is not opened as a sub tab
            // Find out if the user views a sub tab or a parent tab
            // If the user views a sub tab, fetch parent tab record Id
            // after getting parent tab record id, check if parent tab record id is Case
            if (response && response.pageReference.type === 'standard__recordPage' && response.pageReference.attributes.objectApiName === 'Case' && !response.isSubtab) { 
                // This is when user views a case tab
                if (response.recordId) {
                    helper.handleCaseUpdate(component, event, response.recordId);
                }
            }  else if (response && response.isSubtab && response.parentTabId) {
                // This execution happens when user views a sub tab and the tab has a parent tab Id
                workspaceAPI.getTabInfo({
                    tabId : response.parentTabId
                }).then(function(subTabResponse) {  
                    if (subTabResponse && subTabResponse.recordId) {
                        helper.handleCaseUpdate(component, event, subTabResponse.recordId);
                    }
                });
            }           
        });    
    },
    // On Tab Created, Set focussed Id tab in a Session
    onTabCreated : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        var idFocusedTab = event.getParam('tabId');
        workspaceAPI.getTabInfo({
            tabId : idFocusedTab
        }).then(function(response) {
            if (response && !response.isSubtab) {
                window.sessionStorage.setItem(idFocusedTab, response.recordId);
            } else if (response && response.isSubtab && response.parentTabId) {
                // If focussed tab is a sub tab, then get parent tab Id and update session object
                workspaceAPI.getTabInfo({
                    tabId : response.parentTabId
                }).then(function(subTabResponse) {  
                    window.sessionStorage.setItem(response.parentTabId, subTabResponse.recordId);
                });
            }
        });
    },
    // On Tab Closed, Remove Case Id from Session and update case status to open
    onTabClosed : function(component, event, helper) {
        // Get close tab Id
        var idCloseTab = event.getParam('tabId');
        // Get record id from session storage
        var idClosedTabRecordId = window.sessionStorage.getItem(idCloseTab);
        // If case record is not null
        if (idClosedTabRecordId) {
            // Update Status back to Open
            var list_CaseId = [];
            list_CaseId.push(idClosedTabRecordId);
            var closedTabAction = component.get("c.handleUnFocusedCaseEmailStatus");
            closedTabAction.setParams({ 'list_strNonFocusedCaseIds' : list_CaseId });
            console.log("~~!! closed tab > "+list_CaseId);
            closedTabAction.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {                    
                    window.sessionStorage.removeItem(idCloseTab);
                }
            });
            $A.enqueueAction(closedTabAction);                    
        } 
    }
})