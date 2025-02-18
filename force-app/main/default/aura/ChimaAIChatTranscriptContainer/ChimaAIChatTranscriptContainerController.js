({
	currentDisableTab : function(component, event, helper) {
        let isDisabled = event.getParam('isDisabled');
        
		helper.handleCurrentDisableTab(component, event, helper, isDisabled);
        helper.handledisableAllOtherTab(component, event, helper, isDisabled)
	}
})