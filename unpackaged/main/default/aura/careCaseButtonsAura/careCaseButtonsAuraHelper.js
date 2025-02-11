({
    getCase : function(component) {
        var action = component.get("c.queryCase");
        action.setParams({ strId : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                let caseRecord = response.getReturnValue();
                component.set('v.objCase', caseRecord);
                if (caseRecord) {
                    if (caseRecord.RecordType && caseRecord.RecordType.Name) {
                        component.set('v.strCurrentRecordType', caseRecord.RecordType.Name);
                        component.set('v.blnIsCaseClosed', caseRecord.RecordType.Name.includes(' - Read Only') ? true : false);
                    }

                    if (caseRecord.Origin) {
                        var blnShowCallBackVal = ((caseRecord.Origin === 'Chat' || caseRecord.Origin === 'Phone' || caseRecord.Origin === 'Escalation') || (caseRecord.Origin === 'Gusto' && (caseRecord.Channel__c === 'Chat'  || caseRecord.Channel__c === 'Phone')))  ? true : false;
                        component.set('v.blnShowCallBack', blnShowCallBackVal);
                    }

                    if (caseRecord.Show_Create_Follow_Up_Button__c) {
                        var blnShowFollowUpButtonVal = caseRecord.Show_Create_Follow_Up_Button__c;
                        component.set('v.blnShowFollowUpButton', blnShowFollowUpButtonVal);
                    }
                }
            } else {
                console.log('!! UH OH', response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    getPerms : function(component) {
        var action = component.get("c.getPermissions");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var objResponse = response.getReturnValue();
                for (const strPerm in objResponse) {
                    switch(strPerm) {
                        case 'blnReroutePerm':
                            component.set('v.blnShowEscalate', objResponse[strPerm]);
                            break;
                        case 'objEscalatePerm':
                            component.set('v.blnShowCreateEscCase', objResponse[strPerm].blnCaseEscalationAccess);
                            component.set('v.strEscalationType', objResponse[strPerm].strEscalationType);
                            component.set('v.strEscalationQueueName', objResponse[strPerm].strEscalationQueueName);
                            break;
                        case 'blnChangeOwnerPerm':
                            component.set('v.blnShowChangeOwner', objResponse[strPerm]);
                            break;
                        case 'blnSurveyOverride':
                            component.set('v.blnHasSkipSurvey', objResponse[strPerm]);
                            break;
                        case 'blnSocialEscalationPermission':
                            component.set('v.blnShowSocialEscalation', objResponse[strPerm]);
                            break;
                        default:
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": "Error",
                                "message": action.getError()[0].message,
                                "type": "error"
                            });
                            toastEvent.fire();                
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },
    unMergeCurrentCase : function(component) {
        component.set("v.blnIsLoading", true);
        var action = component.get("c.updateCaseOnUnmerge");
        action.setParams({ strCaseId : component.get("v.recordId"), strRecordTypeName : component.get("v.strCurrentRecordType") });
        //action.setParams({ recordTypename : component.get("v.strCurrentRecordType")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === 'SUCCESS') {                
                //console.log('!caseRecord: ', JSON.stringify(response));
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
                console.log('!! UH OH', response.getReturnValue());
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
    doSkipSurvey : function(component) {
        component.set("v.blnIsLoading", true);

        var action = component.get("c.skipSurvey");
        action.setParams({
            strCaseId : component.get('v.recordId'),
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === 'SUCCESS') {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Survey skipped.",
                    "type": "success"
                });
                component.set("v.blnIsLoading", false);
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
            }
            else {
                console.log('!! error ' , response.getReturnValue());
                component.set("v.blnIsLoading", false);
            }
        });
        $A.enqueueAction(action);
    }
})