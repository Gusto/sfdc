({
    handleViewFullCase: function (component, event, helper) {

        component.set("v.blnIsLoading", true);
        // Apex Call to Set Case In Route to be False
        var action = component.get("c.updateCaseInRoute");
        action.setParams({ idCase: component.get("v.recordId") });

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let result = response.getReturnValue();
                if(result) {
                    // On successful response, refresh the UI
                    $A.get('e.force:refreshView').fire();
                }
            }
            component.set("v.blnIsLoading", false);
        });
        $A.enqueueAction(action);
    }
})