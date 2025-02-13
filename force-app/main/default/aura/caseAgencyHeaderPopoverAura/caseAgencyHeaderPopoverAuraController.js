({
    handleMouseLeave : function(component, event, helper) {
        
        var mouseLeaveEvent = $A.get("e.c:caseMouseLeaveAccountPopoverEvent");
		mouseLeaveEvent.setParams({ "recordId" : component.get("v.recordId") });
        mouseLeaveEvent.fire();
    },
    handleOpenContact: function(component, event, helper) {

        var workspaceAPI = component.find("workspace");
        var idContact = event.getParam("originalContactId");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.openSubtab({
                parentTabId: focusedTabId,
                recordId: idContact,
                focus: true
            });
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    handleMouseOver : function(component, event, helper) {

        var mouseOverEvent = $A.get("e.c:caseMouseOverAccountPopoverEvent");
        mouseOverEvent.setParams({ "recordId" : component.get("v.recordId") });
        mouseOverEvent.fire();
    },
    handleClosePopOver: function(component, event, helper) {
        var closePopOverEvent = $A.get("e.c:caseAccountPopOverCloseEvent");
        closePopOverEvent.setParams({ "recordId" : component.get("v.recordId") });
        closePopOverEvent.fire();
    },
    handleUpdateContact: function(component, event, helper) {
        
        var caseContactChangeEvt = $A.get("e.c:caseContactChangeEvent");
        caseContactChangeEvt.setParams({ "caseId" : component.get("v.recordId") });
        caseContactChangeEvt.fire();
    }
})