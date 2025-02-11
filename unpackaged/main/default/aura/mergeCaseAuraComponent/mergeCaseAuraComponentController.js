({
    handlePrimaryTab: function (component, event, helper) {
        var recordId = event.getParam('detailRecordId');
        var caseNumber = event.getParam('newCaseNumber');
        var workspaceAPI = component.find("workspace");

        //console.log('componentName>>' + recordId);
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.openTab({
                pageReference:
                {
                    type: "standard__recordPage",
                    attributes: { 
                        recordId: recordId, 
                        objectApiName: "Case",
                        actionName : "view"                         
                    }
                },
                focus: true
            })
            .then(function (response) {
                // console.log("The new subtab ID is:" + response);
                workspaceAPI.setTabLabel({
                    tabId: response,
                    label: caseNumber
                }),
                workspaceAPI.setTabIcon({
                    tabId: response,
                    icon: "standard:case",
                    iconAlt: "Case"
                })
            })
            .catch(function (error) {
                console.log(error);
            });
        })
    },

    init: function (component, event, helper) {
        var pageReference = component.get("v.pageReference");
        var rId = pageReference.state.c__caserecordId;
        component.set("v.caseRecordId", rId);
        //console.log('rId>>' + JSON.stringify(rId));
    },
    closeSubTab : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focussedTab = response.tabId;
            workspaceAPI.closeTab({tabId: focussedTab});
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    refreshWholePage :function (component, event, helper) {
        var workspaceAPI = component.find("workspace");
        console.log('rIdrefresh>>');
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
        
            workspaceAPI.refreshTab({
                tabId: response.parentTabId,
                includeAllSubtabs: true
            });
            
        })
        .catch(function(error) {
            console.log(error);
        });
        //$A.get('e.force:refreshView').fire();
    }

})