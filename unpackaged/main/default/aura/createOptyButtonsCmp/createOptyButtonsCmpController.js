({
    // doInit : function(component, event, helper) {
    
    // },
    handleBOROppy : function(component, event, helper) {
        component.set("v.blnShowModal", !component.get("v.blnShowModal"));
        var strCaseId = component.get("v.recordId");
        console.log('--caseID---'+strCaseId);
        console.log('--url--'+location.origin);
        var url = location.origin;
        var action = component.get("c.getAccountDetails");
        action.setParams({idCase : strCaseId});
        action.setCallback(this,function(a){
            let accountId = a.getReturnValue();
            var workspaceAPI = component.find("workspace");
            var oppBORRecordType = $A.get("$Label.c.Benefits_BOR_Opp_Record");
            workspaceAPI.getEnclosingTabId().then(function(enclosingTabId){
                workspaceAPI.openSubtab({
                    parentTabId :enclosingTabId,
                    url: url+'/apex/OpportunityNew?accId='+accountId+'&RecordType='+oppBORRecordType+'&sfdc.override=1',
                    focus: true
                })
                .then(function (subtabId){
                    workspaceAPI.setTabLabel({
                        tabId: subtabId,
                        label: 'BOR Opportunity'
                    })
                })
                .catch(function (error) {
                    console.log(error);
                });
            });
        });
        
        $A.enqueueAction(action);
        /*var urlEvent = $A.get("e.force:navigateToURL");
    	urlEvent.setParams({
        "url":"https://gusto--cxlex--c.visualforce.com/apex/OpportunityNew?core.apexpages.request.devconsole=1"
    });
    urlEvent.fire(); */
    },
    handleNPOppy : function(component,event,helper){
        component.set("v.blnShowModal", !component.get("v.blnShowModal"));
        var strCaseId = component.get("v.recordId");
        console.log('--caseID---'+strCaseId);
        var url = location.origin;
        var action = component.get("c.getAccountDetails");
        action.setParams({idCase : strCaseId});
        action.setCallback(this,function(a){
            let accountId = a.getReturnValue();
            var workspaceAPI = component.find("workspace");
            var oppNPRecordType = $A.get("$Label.c.Benefits_New_Plan_Opp_RecordType");
            workspaceAPI.getEnclosingTabId().then(function(enclosingTabId){
                workspaceAPI.openSubtab({
                    parentTabId :enclosingTabId,
                    url: url+'/apex/OpportunityNew?accId='+accountId+'&RecordType='+oppNPRecordType+'&sfdc.override=1',
                    focus: true
                })
                .then(function (subtabId){
                    workspaceAPI.setTabLabel({
                        tabId: subtabId,
                        label: 'NP Opportunity'
                    })
                })
                .catch(function (error) {
                    console.log(error);
                });
            });
        });
        
        $A.enqueueAction(action);
        
    },
    createBoR : function(component, event, helper) {
        
    },
    createNP : function(component, event, helper) {
        
    }
})