({
    /* Close the tab that users are focussed on */
    /* Used when users click Save & Next = closes the tab, saves the case they are working on and opens a new tab */
    closePreviousTab : function(component, event) {
        var workspaceAPI = component.find("workspace");
        // Id of the tab to be closed
        let idTabToClose = event.getParam("idTabToClose");
        // Check if it exists
        if(idTabToClose) {
            // Iterate over all tab info. check if record id matches
            workspaceAPI.getAllTabInfo().then(function(response) {
                response.forEach(eachTab => {
                    // If record id matches, close the focussed tab
                    if(eachTab.recordId === idTabToClose) {
                        workspaceAPI.closeTab({tabId: eachTab.tabId});
                    }
                })
            })
            .catch(function(error) {
                console.error('Error in caseActionsWrapperCmpHelper - closePreviousTab ', error);
            });
        }
    },

    /* Saves case record - Save method exists in Child LWC */
    executeCaseSave: function(component, event) {
        /* Fetches case object from event */
        let objCase = event.getParam("objCase");
        if(objCase) {
            /* calls child method in LWC to save case */
            component.find('caseAction').saveCase(objCase);
        }
    }
})