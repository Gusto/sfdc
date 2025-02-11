({
    handleMouseLeave : function(component, event, helper) {
        
        var mouseLeaveEvent = $A.get("e.c:caseMouseLeaveContactPopoverEvent");
		mouseLeaveEvent.setParams({ "recordId" : component.get("v.recordId") });
        mouseLeaveEvent.fire();
    },
    handleMouseOver : function(component, event, helper) {

        var mouseOverEvent = $A.get("e.c:caseMouseOverContactPopoverEvent");
        mouseOverEvent.setParams({ "recordId" : component.get("v.recordId") });
        mouseOverEvent.fire();
    },
    handleRefresh : function(component, event, helper) {
        var action= $A.get("e.c:caseCloseAfterRouteEvent");
        action.fire();
    },
    handleClosePopOver: function(component, event, helper) {
        var closePopOverEvent = $A.get("e.c:caseContactPopOverCloseEvent");
        closePopOverEvent.setParams({ "recordId" : component.get("v.recordId") });
        closePopOverEvent.fire();
    },
    handleOpenContact: function(component, event, helper) {

        // var workspaceAPI = component.find("workspace");
        //var contactId = event.getParam("originalContactId");
        // workspaceAPI.getFocusedTabInfo().then(function(response) {
        //     var focusedTabId = response.tabId;
        //     workspaceAPI.openSubtab({
        //         parentTabId: focusedTabId,
        //         recordId: contactId,
        //         focus: true
        //     });
        // })
        // .catch(function(error) {
        //     console.log(error);
        // });
        var strPandaURL = event.getParam("strPandaURL");
        if(strPandaURL !== '') {
            window.open('https://app.gusto.com/panda/' + strPandaURL, '_blank');
        }
    },
    handleAccountChange: function(component, event, helper) {
        var caseAccountChangeEvent = $A.get("e.c:caseAccountChangeEvent");
        caseAccountChangeEvent.setParams({ "caseId" : component.get("v.recordId") });
        caseAccountChangeEvent.fire();
    }
})