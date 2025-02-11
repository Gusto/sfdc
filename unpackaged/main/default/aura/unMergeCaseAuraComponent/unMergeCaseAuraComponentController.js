({
    init: function (component, event, helper) {
        var pageReference = component.get("v.pageReference");
        var rId = pageReference.state.c__caserecordId;
        component.set("v.caseRecordId", rId);
        console.log('rId>>' + JSON.stringify(rId));
    },
    refreshPage : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
    }
})