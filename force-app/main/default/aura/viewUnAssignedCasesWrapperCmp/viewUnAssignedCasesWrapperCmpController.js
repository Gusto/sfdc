({
    handleCaseContactChange : function(component, event, helper) {
        // When an event is fired, it refreshes ui to get unassigned cases for a new contact
		component.find('unassignedcases').handleDoInit();
    }
})