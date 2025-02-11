({
    getCase : function(component) {
        var action = component.get("c.queryCase");
        action.setParams({
            strId : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                let objCase = response.getReturnValue();
                component.set('v.objCase', objCase);
                component.set("v.strAgencyInfoId", objCase.Agency_Information__c);
                component.set("v.strOrigAgencyInfoId", objCase.Agency_Information__c);
                component.set("v.strPandaEE", objCase.Contact_Employee_Id__c);
                component.set("v.strPandaURL", objCase.Panda_Company_URL__c);
                if (!component.get("v.strAgencyInfoId")) {
                    component.set("v.blnViewAgency", false);
                }
                if (objCase.Account) {
                    component.set("v.blnBenefitsAccount", objCase.Account.HI_Active_Benefits__c)
                }
            }
            else {
                console.log('!! UH OH', response.getReturnValue());
            }
        });

        $A.enqueueAction(action);
    },
    saveAgencyInfo : function(component) {
        component.set("v.blnIsLoading", true);
        var action = component.get("c.updateAgencyInfo");
        action.setParams({
            strCaseId : component.get("v.objCase").Id,
            strAgencyInfoId : component.get("v.strAgencyInfoId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Agency updated sucessfully",
                    "type": "success"
                });
                component.set("v.blnViewAgency", !component.get("v.blnViewAgency"));
                $A.get('e.force:refreshView').fire();
                component.set("v.blnIsLoading", false);
                this.getCase(component);
                toastEvent.fire();                
                
                // Fire Agency change application event
                var caseAgencyChangeEvt = $A.get("e.c:caseAgencyChangeEvent");
                caseAgencyChangeEvt.setParams({ "caseId" : component.get("v.recordId") });
                caseAgencyChangeEvt.fire();
            }
            else {
                console.log('!! UH OH', response.getReturnValue());
            }
        });

        $A.enqueueAction(action);
    },
    
    createNewPopOverTimer: function(component, event) {
        if (component.get("v.blnIsPopOverOpen")) {
            let timerInstance = component.get("v.blnIsPopOverOpen");
            clearTimeout(timerInstance);
            let newTimerInstance = setTimeout($A.getCallback(this.check.bind(this,component,event)), 1000);
            
            component.set("v.blnIsPopOverOpen" , newTimerInstance);
            component.set("v.blnIsPopOverOpen", true);
        }
    },
    
    check: function(component, event) {
        let popOverInstance = component.get("v.popoverInstance");
        if (popOverInstance && component.get("v.blnMouseOverChild") === false && component.get("v.blnMouseOverText") === false ) {
            popOverInstance.close();
            component.set("v.blnIsPopOverOpen", false);
        } else {
            this.createNewPopOverTimer(component, event);
        }

    }
})