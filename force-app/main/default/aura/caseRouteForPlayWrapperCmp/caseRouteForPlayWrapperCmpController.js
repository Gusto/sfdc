({
    doInit : function(component, event, helper) {
        helper.getTabPermissions(component);
    },

    // Opens Case Tab
    handleOpenCaseTab : function(component, event, helper) {
        var idCase = event.getParam('objCase').idCaseToOpen;
        var workspaceAPI = component.find("workspace");
        // Open case tab using workspace api and set focus to true
        workspaceAPI.openTab({
            recordId: idCase,
            focus: true
        }).then(function(response) {
            if(event.getParam('objCase').idCaseToClose) {
                // Close Previous Tab
                helper.closePreviousTab(component, event, event.getParam('objCase').idCaseToClose);
            }
        })
        .catch(function(error) {
            console.log('Error in caseRouteForPlayWrapperController - handleOpenCaseTab ', error);
        });
    }
})