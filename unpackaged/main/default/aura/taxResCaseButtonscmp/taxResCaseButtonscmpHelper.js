({
    getCase : function(component) {
        var action = component.get("c.queryCase");
        action.setParams({ strId : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === 'SUCCESS') {
                let caseRecord = response.getReturnValue();
                var blnShowCallBackVal = ((caseRecord.Origin === 'Chat' || caseRecord.Origin === 'Phone' || caseRecord.Origin === 'Escalation') || (caseRecord.Origin === 'Gusto' && (caseRecord.Channel__c === 'Chat'  || caseRecord.Channel__c === 'Phone')))  ? true : false;
                var blnShowFollowUpButtonVal = ((caseRecord.Origin === 'Chat' || caseRecord.Origin === 'Phone') || (caseRecord.Origin === 'Gusto' && (caseRecord.Channel__c === 'Chat' ||  caseRecord.Channel__c === 'Phone'))) ? true : false;                          
                component.set('v.strCurrentRecordType', caseRecord.RecordType.Name);
                component.set('v.blnIsCaseClosed', caseRecord.IsClosed);
                component.set('v.blnShowCallBack', blnShowCallBackVal);
                component.set('v.blnShowFollowUpButton', blnShowFollowUpButtonVal);
            }
            else {
                console.log('!! UH OH', response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    getUserInfo : function(component) {
        //can user see change owner button
        var action = component.get("c.getLoggedInUser");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === 'SUCCESS') {
                component.set('v.objUser', response.getReturnValue());
            } else {
                console.log('!! UH OH', response.getReturnValue());
                this.showToastMessage("Error",response.getReturnValue(),"error");
            }
        });
        $A.enqueueAction(action);
    },
    getChangeOwnerPermission : function(component){
        //can user see change owner button
        var action = component.get("c.canUserChangeOwner");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === 'SUCCESS') {
                console.log('!! HERE');
                component.set('v.blnShowChangeOwner', response.getReturnValue());
            }
            else {
                console.log('!! UH OH', response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    getChangeAccSpecialistPermission : function(component){
        //can user see change owner button
        var action = component.get("c.canUserChangeAccSpecialist");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === 'SUCCESS') {
                console.log('!! HERE');
                component.set('v.blnShowChangeAccSpecialist', response.getReturnValue());
            }
            else {
                console.log('!! UH OH', response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    unMergeCurrentCase : function(component) {
        component.set("v.blnIsLoading", true);
        var action = component.get("c.updateCaseOnUnmerge");
        action.setParams({ strCaseId : component.get("v.recordId"), strRecordTypeName : component.get("v.strCurrentRecordType"), blnIsClosed : component.get("v.blnIsCaseClosed") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Case Unmerged",
                    "type": "success"
                });
                $A.get('e.force:refreshView').fire();
                component.set("v.blnIsLoading", false);
                toastEvent.fire();                
            }
            else {
                component.set("v.blnIsLoading", false);
            }
        });
        $A.enqueueAction(action);
    },   
    changeOwner : function(component) {
        component.set("v.blnIsLoading", true);
        component.set('v.blnChangeOwnerModal', false);

        var action = component.get("c.changeOwner");
        action.setParams({
            strCaseId : component.get('v.recordId'),
            strOwnerId : component.find("owner").get("v.value")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === 'SUCCESS') {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Owner changed successfully.",
                    "type": "success"
                });
                component.set("v.blnIsLoading", false);
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
            }
            else {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": action.getError()[0].message,
                    "type": "error"
                });
                component.set("v.blnIsLoading", false);
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
            }
        });
        $A.enqueueAction(action);
    },
    showToastMessage : function(component, event, strTitle, strMessage, strType) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": strTitle,
            "message": strMessage,
            "type": strType
        });
        toastEvent.fire();
        $A.get('e.force:refreshView').fire();
    }
})