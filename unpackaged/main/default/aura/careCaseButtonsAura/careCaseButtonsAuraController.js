({
    doInit : function(component, event, helper) {
        helper.getCase(component);
        helper.getPerms(component);
    },
    handleCallback :function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.openSubtab({
                pageReference: {
                    "type": "standard__component",
                    "attributes": {
                        "componentName": "c__callBackCmp"     
                    },
                    "state": {
                        c__recordId : component.get("v.recordId")
                                               
                    }                    
                },
                focus: true
            }).then(function(subtabId){
                workspaceAPI.setTabLabel({
                    tabId: subtabId,
                    label: "Call Back"
                });
                workspaceAPI.setTabIcon({
                    tabId: subtabId,
                    icon: "action:new_case",
                    iconAlt: "Call Back"
                });
            }).catch(function(error) {
                console.log(error);
            });
        })
        .catch(function(error) {
            console.log(error);
        });
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
            console.log(error);
        });
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
    },
    toggleChangeOwnerModal : function(component, event, helper) {
        var blnOrigChangeOwner = component.get('v.blnChangeOwnerModal');
        component.set('v.blnChangeOwnerModal', !blnOrigChangeOwner);
    },
    toggleCreateTicketModal : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.openSubtab({
                pageReference: {
                    "type": "standard__component",
                    "attributes": {
                        "componentName": "c__createTicketWrapperCmp"     
                    },
                    "state": {
                        "c__caseId": component.get("v.recordId"),
                        "c__accountId": component.get("v.objCase").AccountId,
                        "c__contactId": component.get("v.objCase").ContactId
                    }
                },
                focus: true
            }).then(function(subtabId){
                workspaceAPI.setTabLabel({
                    tabId: subtabId,
                    label: "New Ticket"
                });
                workspaceAPI.setTabIcon({
                    tabId: subtabId,
                    icon: "standard:case",
                    iconAlt: "New Ticket"
                });
            }).catch(function(error) {
                console.log(error);
            });
        })
        .catch(function(error) {
            console.log(error);
        });

    },

    toggleCreateFollowUpCaseModal : function(component, event, helper) {
        component.set('v.blnCreateFollowUpCaseModal',true);
    },
    
    handleCloseModal : function(component, event, helper){
        component.set('v.blnCreateFollowUpCaseModal',event.getParam('handleModalClose'));
    },
    toggleContactCarrierModal : function(component,event,helper){
        component.set('v.blnContactCarrierModal',true);
    },
    handleCarrierModal : function(component,event,helper){
        component.set('v.blnContactCarrierModal',event.getParam('handleModalClose'));
    },
    toggleEscalateCaseModal : function(component,event,helper){
        component.set('v.blnEscalateCaseModal',true);
    },
    handleEscalationModal :  function(component,event,helper){
        component.set('v.blnEscalateCaseModal',event.getParam('closeModal'));
    },
    handleFollowUpEscalationModal : function(component,event,helper){
        component.set('v.blnFollowUpEscalationCaseModal',event.getParam('closeModal'));
    },
    toggleFollowUpEscalationModal : function(component,event,helper){
        component.set('v.blnFollowUpEscalationCaseModal',true);
    },
    doChangeOwner : function(component, event, helper) {
        helper.changeOwner(component);
    },
    handleSkipSurvey : function(component, event, helper) {
        helper.doSkipSurvey(component);
    },
    handleSocialEscalation : function(component) {
        component.set("v.blnSocialEscalation", true);
        var objFlow = component.find("flowInterview");
        var inputVariables = [ 
            {
                name: 'currentCaseId',
                type: 'String',
                value: component.get("v.recordId")
            } 
        ];
        objFlow.startFlow("Social_Executive_Escalation_Flow", inputVariables);
    },
    handleCloseModal : function(component) {
        component.set("v.blnSocialEscalation", false);
    },
    handleFlowStatusChange : function(component, event) {
        var strFlowStatus = event.getParam('status');
        if (strFlowStatus === 'FINISHED') {
            component.set("v.blnSocialEscalation", false);
            var objToastEvent = $A.get("e.force:showToast");
                objToastEvent.setParams({
                    "title": "Success!",
                    "message": "Social & Executive Escalation Details Successfully Saved",
                    "type": "success"
                });
                objToastEvent.fire();
                $A.get('e.force:refreshView').fire();
        }
    }
})