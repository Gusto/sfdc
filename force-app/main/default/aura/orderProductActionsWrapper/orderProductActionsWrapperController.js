({
    doInit : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
        console.log(component.get('v.recordId'));
    },
    closeQA : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
		$A.get("e.force:closeQuickAction").fire();
    }
})