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
                component.set('v.objCase', objCase);
                component.set("v.strAccountId", objCase.AccountId);
                component.set("v.strOrigAccountId", objCase.AccountId);
                component.set("v.strPandaEE", objCase.Contact_Employee_Id__c);
                var strGustoBaseURL = $A.get("$Label.c.gusto_url_prefix");
                var strTackleBaseURL = strGustoBaseURL+'/panda';
                var strViewCompanyInPandaURL = strGustoBaseURL+'/panda'; 
                var strViewAccountingFirmInPandaURL = strGustoBaseURL+'/panda';                

                if (!component.get("v.strAccountId")) {
                    component.set("v.blnViewAccount", false);
                }
                if (objCase.Account) {
                    component.set("v.blnBenefitsAccount", objCase.Account.HI_Active_Benefits__c)
                }  
                
                if (objCase.Account && objCase.Account.ZP_Company_ID__c) {
                    strViewCompanyInPandaURL = strViewCompanyInPandaURL + '/companies/' + objCase.Account.ZP_Company_ID__c;
                    strTackleBaseURL = strTackleBaseURL + '/companies/' + objCase.Account.ZP_Company_ID__c + '/tax_investigations';
                    component.set("v.blnCompanyUrlExists", true);
                } else {
                    component.set("v.blnCompanyUrlExists", false);
                }

                if (objCase.Account && objCase.Account.ZP_Firm_ID__c) {
                    strViewAccountingFirmInPandaURL = strViewAccountingFirmInPandaURL + '/accounting_firms/'+objCase.Account.ZP_Firm_ID__c;
                    strTackleBaseURL = strTackleBaseURL + '/accounting_firms/'+objCase.Account.ZP_Firm_ID__c+'/tax_investigations';
                    component.set("v.blnAccountingFirmUrlExists", true);  
                } else {
                    component.set("v.blnAccountingFirmUrlExists", false);
                }
                
                var strNoticePeriod = objCase.Notice_Period__c;
                if (strNoticePeriod != null && strNoticePeriod.indexOf("Q")>-1) {
                    var strQuarter = strNoticePeriod.split(" ")[0].replace("Q","").trim();
                    var strYear = strNoticePeriod.split(" ")[1]
                    strTackleBaseURL = strTackleBaseURL + "?quarter=" + strQuarter + "&year=" + strYear;
                }
                component.set("v.strTackleboxURL", strTackleBaseURL);
                component.set("v.strCompanyURL", strViewCompanyInPandaURL);
                component.set("v.strAccountingFirmURL", strViewAccountingFirmInPandaURL);
            }
            else {
                console.log('!! UH OH', response.getReturnValue());
            }
        });

        $A.enqueueAction(action);
    },
    showTackleLink : function(component){
        var actionTackleLink = component.get("c.getMemberToAccessTackleLink");
        actionTackleLink.setCallback(this, function(response) {
            var state = response.getState();
            if(state === 'SUCCESS') {
                let blnShowLink = response.getReturnValue();
                component.set('v.blnShowLink', blnShowLink);
            }
            else {
                console.log('!! UH OH', response.getReturnValue());
            }
        });
        $A.enqueueAction(actionTackleLink);
    },
    saveAccount : function(component) {
        component.set("v.blnIsLoading", true);
        var action = component.get("c.updateAccount");
        action.setParams({
            strCaseId : component.get("v.objCase").Id,
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
        if(component.get("v.blnIsPopOverOpen")) {
            let timerInstance = component.get("v.timerInstance");
            clearTimeout(timerInstance);
            let newTimerInstance = setTimeout($A.getCallback(this.check.bind(this,component,event)), 1000);
            
            component.set("v.timerInstance" , newTimerInstance);
            component.set("v.blnIsPopOverOpen", true);
        }
    },
    
    check: function(component, event) {
        let popOverInstance = component.get("v.popoverInstance");
        if(popOverInstance && component.get("v.blnMouseOverChild") === false && component.get("v.blnMouseOverText") === false ) {
            popOverInstance.close();
            component.set("v.blnIsPopOverOpen", false);
        } else {
            this.createNewPopOverTimer(component, event);
        }

    }
})