({
    doInit : function(component, event, helper) {
		//helper.pollLWC(component, event, helper);
	},
	openSubTab: function (component, event, helper) {
		var strCaseId = event.getParam("idCase");
		var workspaceAPI = component.find("workspace");
		var strMatchingTabId = "";

		workspaceAPI
        .getAllTabInfo()
        .then(function (response) {
            /**try to see if tab for pod already exists or not */
            if (response) {
                for (let objTab of response) {
                    if (strCaseId === objTab.pageReference.state.recordId) {
                        strMatchingTabId = objTab.tabId;
                        break;
                    }
                }
            }

            /**if same pod already open focus on tab */
            if (strMatchingTabId) {
                workspaceAPI.focusTab({ tabId: strMatchingTabId });
            } else {
                workspaceAPI
                .openTab({
                    pageReference: {
                        "type": "standard__recordPage",
                        "attributes": {
                            "recordId": strCaseId,
                            "actionName":"view"
                        },
                        "state": {}
                    },
                    focus: true
                })
                .then(function (response) {
                })
                .catch(function (error) {
                    let strErrorMessage = error.message;
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": strErrorMessage,
                        "type": "error"
                    });
                    toastEvent.fire();
                });
            }
        })
        .catch(function (error) {
            let strErrorMessage = error.message;
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": strErrorMessage,
                "type": "error"
            });
            toastEvent.fire();
        });
	}
})