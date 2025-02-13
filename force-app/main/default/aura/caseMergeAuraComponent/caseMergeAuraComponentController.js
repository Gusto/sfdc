({
    handlePrimaryTab: function (component, event, helper) {
        var recordId = event.getParam('newCaseId');
        var caseNumber = event.getParam('newCaseNumber');
        var modalBool = event.getParam('closeAfterCreate');
        var workspaceAPI = component.find("workspace");

        console.log('componentName>>' + recordId);

        workspaceAPI.openTab({
            pageReference:
            {
                type: "standard__recordPage",
                attributes: { "recordId": recordId, "actionName": "view" }
            },

            focus: true
        })
            .then(function (response) {
                console.log("The new subtab ID is:" + response);
                workspaceAPI.setTabLabel({
                    tabId: response,
                    label: caseNumber
                }),
                    workspaceAPI.setTabIcon({
                        tabId: response,
                        icon: "standard:case",
                        iconAlt: "Case"
                    })

                    component.set('v.openModal',modalBool);
                    var receiver = component.getEvent("newEvent");
                   receiver.setParams({"handleModalClose":modalBool});
                   receiver.fire();
            })
            .catch(function (error) {
                console.log(error);
            });
    },

    handleCloseModal : function(component, event, helper){
        component.set('v.openModal',event.getParam('closeModal'));
        var receiver = component.getEvent("newEvent");
       receiver.setParams({"handleModalClose":event.getParam('closeModal')});
       receiver.fire();
    },

})