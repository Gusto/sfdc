({
    closePreviousTab : function(component, event) {
        var workspaceAPI = component.find("workspace");
        let idTabToClose = event.getParam("idTabToClose");
        if(idTabToClose) {
            // Get tab to close from event
            workspaceAPI.getAllTabInfo().then(function(response) {
                response.forEach(eachTab => {
                    // Iterate over each tab Id. Check if record id matches
                    // Close the tab
                    if(eachTab.recordId === idTabToClose) {
                        workspaceAPI.closeTab({tabId: eachTab.tabId});
                    }
                })
            })
            .catch(function(error) {
                console.log(error);
            });
        }
    },
    // Create case skip history records
    executeCaseSkip: function(component, event) {
        let strSkipComment = event.getParam("strSkipComment");
        let idTabToClose = event.getParam("idTabToClose");
        // If tabClose has an Id and if there are skip comments
        // Call LWC method that inserts skip case history records and re-routes cases
        if(idTabToClose && strSkipComment) {
            component.find('caseSkip').handleSkip(idTabToClose, strSkipComment);
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Case skipped successfully!",
                "message": " ",
                "type": "success"
            });
            toastEvent.fire();
        }
    }
})