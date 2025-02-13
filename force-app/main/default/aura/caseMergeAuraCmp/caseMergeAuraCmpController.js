({
    handlePrimaryTab: function (component, event, helper) {
        //getting the values from the LWC component
        var idRecord = event.getParam('newCaseId');
        var strCaseNumber = event.getParam('newCaseNumber');
        var modalBool = event.getParam('closeAfterCreate');
        var workspaceAPI = component.find("workspace");

        // opening the tab as Primary tab.
        workspaceAPI.openTab({
            // setting the attributes
            pageReference:
            {
                type: "standard__recordPage",
                attributes: { "recordId": idRecord, "actionName": "view" }
            },

            focus: true
        })
            .then(function (response) {
                // setting the tab attributes
                workspaceAPI.setTabLabel({
                    tabId: response,
                    label: strCaseNumber
                }),
                // setting the tab Icon attributes
                workspaceAPI.setTabIcon({
                    tabId: response,
                    icon: "standard:case",
                    iconAlt: "Case"
                })

                component.set('v.blnOpenModal',event.getParam('modalBool'));
                var receiver = component.getEvent("newEvent");
                receiver.setParams({"handleModalClose":event.getParam('modalBool')});
                receiver.fire();
            })
            .catch(function (error) {
                console.log(error);
            });
    },

    handleCloseModal : function(component, event, helper){
        component.set('v.blnOpenModal',event.getParam('closeModal'));
        var receiver = component.getEvent("newEvent");
        receiver.setParams({"handleModalClose":event.getParam('closeModal')});
        receiver.fire();
    },

})