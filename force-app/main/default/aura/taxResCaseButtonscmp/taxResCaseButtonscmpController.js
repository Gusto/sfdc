({
    doInit : function(component, event, helper) {
        helper.getCase(component);
        helper.getChangeOwnerPermission(component);
        helper.getChangeAccSpecialistPermission(component);
        helper.getUserInfo(component);
    },
    mergeCase : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.openSubtab({
                pageReference: {
                    "type": "standard__component",
                    "attributes": {
                        "componentName": "c__mergeCaseAuraCmp"     
                    },
                    "state": {
                        c__caserecordId: component.get("v.recordId")
                    }
                },
                focus: true
            }).then(function(subtabId){
                workspaceAPI.setTabLabel({
                    tabId: subtabId,
                    label: "Merge Case"
                });
                workspaceAPI.setTabIcon({
                    tabId: subtabId,
                    icon: "action:new_case",
                    iconAlt: "Merge Case"
                });
            }).catch(function(error) {
                console.log(error);
            });
        })
        .catch(function(error) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "Error while merging cases.",
                "type": "error"
            });
            toastEvent.fire();  
        });
    },
    toggleChangeOwnerModal : function(component, event, helper) {
        var blnOrigChangeOwner = component.get('v.blnChangeOwnerModal');
        component.set('v.blnChangeOwnerModal', !blnOrigChangeOwner);
    },
    toggleChangeAccountSpecialistModal : function(component, event, helper) {
        var blnOrigChangeAccSpecialist = component.get('v.blnChangeAccountSpecialistModal');
        component.set('v.blnChangeAccountSpecialistModal', !blnOrigChangeAccSpecialist);
    }, 
    openNewCaseModal : function(component, event, helper) {
        component.set('v.blnCreateNewCaseModal', true);
    },
    closeNewCaseModal : function(component, event, helper) {
        component.set('v.blnCreateNewCaseModal', false);
    }, 
    doChangeOwner : function(component, event, helper) {
        helper.changeOwner(component);
    },
    closeModal : function(component) {
        component.set('v.blnChangeAccountSpecialistModal', false);
        component.set('v.blnChangeNoticeAnalystModal', false);
    },
    handleASSubmit : function (component, event, helper) {
        component.set("v.blnIsLoading", true);
        component.set("v.blnDisabledOnClick",true);
        var _currentDate = Date.now();
        var _now = $A.localizationService.formatDate(_currentDate, "YYYY-MM-DD HH:MM:ss");
        event.preventDefault();
        const fields = event.getParam('fields');
        fields.Specialist_Last_Modified_By__c = component.get('v.objUser').Name + ' - ' + _now;
        component.find('recordEditFormAS').submit(fields);        
    },
    handleAccSpecialistSuccess : function(component, event, helper) {
        component.set("v.blnIsLoading", false);
        component.set('v.blnChangeAccountSpecialistModal', false);
        component.set("v.blnDisabledOnClick",false);
        helper.showToastMessage(component, event, "Success!", "Account Specialist Changed Successfully", "success");
    },
    handleAccSpecialistError : function(component, event, helper){
        component.set("v.blnIsLoading", false);
        component.set('v.blnChangeAccountSpecialistModal', false);
        component.set("v.blnDisabledOnClick",false);
        helper.showToastMessage(component, event, "Error!", "There is an error updating Account Specialist. Please reach out to admin for further details", "error");
    },
    handleConfirmDialog : function(component, event, helper) {
        component.set('v.blnShowConfirmDialog', true);
    }, 
    handleConfirmDialogYes : function(component, event, helper) {
        component.set('v.blnShowConfirmDialog', false);
        helper.unMergeCurrentCase(component);
    },
    handleConfirmDialogNo : function(component, event, helper) {
        component.set('v.blnShowConfirmDialog', false);
    }
})