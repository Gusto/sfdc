({
    handleOpenCase : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        var strId = event.getParam('strId');
        console.log('event ', strId);
        workspaceAPI.openTab({
            pageReference: {
                "type": "standard__recordPage",
                "attributes": {
                    "recordId": strId,
                    "actionName":"view"
                },

            },
            focus: true
        });
    }
})