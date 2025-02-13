({
    getCase : function(component) {
        var action = component.get("c.queryCase");
        action.setParams({
            strId : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === 'SUCCESS') {
                let objCase = response.getReturnValue();
                component.set('v.case', objCase);
                component.set("v.strAccountId", objCase.AccountId);
                component.set("v.strOrigAccountId", objCase.AccountId);
                component.set("v.strPandaEE", objCase.Contact_Employee_Id__c);
                component.set("v.strPandaURL", objCase.Panda_Company_URL__c);
                if(!component.get("v.strAccountId")) {
                    component.set("v.blnViewAccount", false);
                }
                if(objCase.Account) {
                    component.set("v.blnBenefitsAccount", objCase.Account.HI_Active_Benefits__c)
                }
            }
            else {
                console.log('!! UH OH', response.getReturnValue());
            }
        });

        $A.enqueueAction(action);
    },
    saveAccount : function(component) {
        component.set("v.blnIsLoading", true);
        var action = component.get("c.updateAccount");
        action.setParams({
            strCaseId : component.get("v.case").Id,
            strAccountId : component.get("v.strAccountId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === 'SUCCESS') {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Account updated sucessfully",
                    "type": "success"
                });
                component.set("v.blnViewAccount", !component.get("v.blnViewAccount"));
                $A.get('e.force:refreshView').fire();
                component.set("v.blnIsLoading", false);
                this.getCase(component);
                toastEvent.fire();
                
                
                // Fire Contact Change Application Event
                var caseContactChangeEvt = $A.get("e.c:caseAccountChangeEvent");
                caseContactChangeEvt.setParams({ "caseId" : component.get("v.recordId") });
                caseContactChangeEvt.fire();
            }
            else {
                console.log('!! UH OH', response.getReturnValue());
            }
        });

        $A.enqueueAction(action);
    },
    
    createNewPopOverTimer: function(component, event) {
        if(component.get("v.isPopOverOpen")) {
            let timerInstance = component.get("v.timerInstance");
            clearTimeout(timerInstance);
            let newTimerInstance = setTimeout($A.getCallback(this.check.bind(this,component,event)), 1000);
            
            component.set("v.timerInstance" , newTimerInstance);
            component.set("v.isPopOverOpen", true);
        }
    },
    
    check: function(component, event) {
        let popOverInstance = component.get("v.popoverInstance");
        if(popOverInstance && component.get("v.blnMouseOverChild") === false && component.get("v.blnMouseOverText") === false ) {
            popOverInstance.close();
            component.set("v.isPopOverOpen", false);
        } else {
            this.createNewPopOverTimer(component, event);
        }

    }
})