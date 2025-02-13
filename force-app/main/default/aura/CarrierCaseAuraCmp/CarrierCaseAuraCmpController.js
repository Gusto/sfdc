({
    //Method to open the new case in a primary tab
    handlePrimaryTab: function (component, event, helper) {
        var strRecordId = event.getParam('newCaseId');
        var strCaseNumber = event.getParam('newCaseNumber');
        var blnModalBool = event.getParam('closeAfterCreate');
        var workspaceAPI = component.find("workspace");
        workspaceAPI.openTab({
            pageReference:
            {
                type: "standard__recordPage",
                attributes: { "recordId": strRecordId, "actionName": "view" }
            },

            focus: true
        })
            .then(function (response) {
                workspaceAPI.setTabLabel({
                    tabId: response,
                    label: strCaseNumber
                }),
                    workspaceAPI.setTabIcon({
                        tabId: response,
                        icon: "standard:case",
                        iconAlt: "Case"
                    })

                    component.set('v.openModal',event.getParam('blnModalBool'));
                    var receiver = component.getEvent("carrierEvent");
                   receiver.setParams({"handleModalClose":event.getParam('blnModalBool')});
                   receiver.fire();
            })
            .catch(function (error) {
                console.log(error);
            });
    },

    //Method to set the value for opening and closing of modal
    handleCarrierModal : function (component, event, helper){
        component.set('v.openModal',event.getParam('closeModal'));
        let receive = component.getEvent("carrierEvent");
       receive.setParams({"handleModalClose":event.getParam('closeModal')});
       receive.fire();
    }

})