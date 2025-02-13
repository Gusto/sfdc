({
	handleCaseAccountContactChange : function(component, event, helper) {
		
        let recordId = component.get('v.recordId');
        let caseId = event.getParam('caseId');
        // check if record id from page is matching record id from event
        // ensure that the handler is only listening for correct records
        // if(caseId === recordId) {
            // pass status to lwc and update status
            component.find('renderDynamicFields').loadConfig();
        // }
	}
})