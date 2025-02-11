({
    /* Handler to get the data from Cache */
    getSessionCache : function(component) {
        var action = component.get("c.getSessionCache");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if (response.getReturnValue().strQuestion) {
                    component.set("v.strQuestion", response.getReturnValue().strQuestion);
                } 
                if (response.getReturnValue().strFocusedCase) {
                    component.set("v.idFocusedCase", response.getReturnValue().strFocusedCase);
                }

                component.set("v.blnDisplayChild", true);
            } else {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.showToast('Error', errors[0].message, 'error', 'sticky');
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },

    /* Handler to display toast message */
    showToast: function(component, strTitle, strMessage, strType, strMode) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": strTitle,
            "message": strMessage,
            "type": strType,
            "mode": strMode
        });
        toastEvent.fire();
    }
})