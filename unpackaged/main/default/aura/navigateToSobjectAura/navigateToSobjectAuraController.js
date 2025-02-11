({
	invoke: function (component, event, helper) {
		var workspaceAPI = component.find("workspace");
		var recordId = component.get("v.recordId");
		workspaceAPI.openTab({
			pageReference: {
				type: "standard__recordPage",
				attributes: {
					recordId: recordId,
					actionName: "view"
				},
                state: {
                    c__taskReDirect: true
                }
			},
			focus: true
		});
	}
})