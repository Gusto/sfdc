({
    doInit: function (component, event, helper) {

        var action = component.get("c.queryCase");
        action.setParams({ strId: component.get("v.recordId") });

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let result = response.getReturnValue();
                if (result) {
                    component.set("v.caseRecord", result.CaseRec);
                    component.set("v.idWorkingRecord", result.CaseRec.Id);
                    component.set("v.idOriginalContact", result.CaseRec.ContactId);
                    if (!result.CaseRec.ContactId) {
                        component.set("v.blnViewContact", false);
                    }
                    
                    if (result.CaseRec.Contact != null) {
                        if (!result.CaseRec.Contact.Contractor_Id__c) {
                            component.set("v.blnIsContractor", false);
                        }
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },

    updateClicked: function (component, event, helper) {
        component.set("v.idContact", "");
        helper.handleUpdateClicked(component, event);
    },

    toggleViewContact: function (component, event, helper) {
        let blnViewContact = component.get("v.blnViewContact");
        component.set("v.blnViewContact", !blnViewContact);
    },

    handleContactChange: function (component, event, helper) {
        let newContactId = component.find("contactId").get("v.value");
        component.set("v.idContact", newContactId);
    },

    handleSave: function (component, event, helper) {

        component.set("v.blnShowSpinner", true);
        var action = component.get("c.updateContactOnSave");
        action.setParams({
            strCaseId: component.get("v.idWorkingRecord"),
            strContactId: component.get("v.idContact")
        });

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.idOriginalContact", component.get("v.idContact"));
                let blnViewContact = component.get("v.blnViewContact");
                component.set("v.blnViewContact", !blnViewContact);

                component.set("v.caseRecord", response.getReturnValue());
                component.set("v.blnShowSpinner", false);

                // Fire Contact Change Application Event
                var caseContactChangeEvt = $A.get("e.c:caseContactChangeEvent");
                caseContactChangeEvt.setParams({ "caseId": component.get("v.recordId") });
                caseContactChangeEvt.fire();
            }
        });
        $A.enqueueAction(action);
    },

    handleOpenContact: function (component, event, helper) {

        var workspaceAPI = component.find("workspace");
        var contactId = component.get("v.idOriginalContact");
        workspaceAPI.getFocusedTabInfo().then(function (response) {
            var focusedTabId = response.tabId;
            workspaceAPI.openSubtab({
                parentTabId: focusedTabId,
                recordId: contactId,
                focus: true
            });
        })
        .catch(function (error) {
            let strErrorMessage = error.message;
            var toastEvent = $A.get("error.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": strErrorMessage,
                "type": "error"
            });
            toastEvent.fire();
        });
    },
    goToPanda: function(component, event, helper) {
        let caseRecord = component.get("v.caseRecord");
        window.open('https://app.gusto.com/panda/employees/' + caseRecord.Contact_Employee_Id__c, '_blank');
    },
    viewUserInPanda: function(component, event, helper) {
        let caseRecord = component.get("v.caseRecord");
        window.open('https://app.gusto.com/panda/users/' + caseRecord.Contact_User_Id__c, '_blank');
    },
    viewContractorInPanda: function(component, event, helper){
        let caseRecord = component.get("v.caseRecord");
        window.open('https://app.gusto.com/panda/contractors/' + caseRecord.Contact.Contractor_Id__c, '_blank');
    },
    handleShowPop: function (component, event, helper) {
        component.set("v.blnMouseOverText", true);
        if (!component.get("v.blnPopOverOpen")) {
            $A.createComponent("c:caseContactHeaderPopOverWrapperCmp", { recordId: component.get("v.recordId") },
                function (content, status, errorMessage) {
                    if (status === "SUCCESS") {
                        component.find('overlayLib').showCustomPopover({
                            body: content,
                            referenceSelector: "#css" + component.get("v.recordId"),
                            cssClass: "popClass"
                        }).then(function (overlay) {
                            component._overlay = overlay;
                            component.set("v.popoverInstance", overlay);
                            let timerInstance = setTimeout(function () {
                                if (component.get("v.blnMouseOverChild") === false && component.get("v.blnMouseOverText") === false) {
                                    component.get("v.popoverInstance").close();
                                    component.set("v.blnPopOverOpen", false);
                                } else {
                                    helper.createNewPopOverTimer(component, event);
                                }
                            }, 1000);
                            component.set("v.timerInstance", timerInstance);
                            component.set("v.blnPopOverOpen", true);
                        });
                    }
                });
        } else {
            helper.createNewPopOverTimer(component, event);
        }
    },
    handleMouseAwayFromText: function (component, event, helper) {
        component.set("v.blnMouseOverText", false);
    },
    handleMouseLeavePopover: function (component, event, helper) {
        if (event.getParam("recordId") === component.get("v.recordId")) {
            component.set("v.blnMouseOverChild", false);
        }
    },
    handleMouseOverPopover: function (component, event, helper) {
        if (event.getParam("recordId") === component.get("v.recordId")) {
            component.set("v.blnMouseOverChild", true);
        }
    },
    handleClosePopOver: function (component, event, helper) {
        if (event.getParam("recordId") === component.get("v.recordId")) {
            let popOverInstance = component.get("v.popoverInstance");
            if (popOverInstance) {
                popOverInstance.close();
                component.set("v.blnPopOverOpen", false);
                component.get("v.blnMouseOverChild", false);
            }
        }
    }
})