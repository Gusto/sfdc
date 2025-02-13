({
	doInit: function (component, event, helper) {},
	handleOpenRecord: function (component, event) {
		var workspaceAPI = component.find("workspace");
		var recordId = event.getParam("recordId");
		workspaceAPI.openSubtab({
			pageReference: {
				type: "standard__recordPage",
				attributes: {
					recordId: recordId,
					actionName: "view"
				}
			},
			focus: true
		});
	},

	handleRefresh: function (component, event) {
		component.set("v.blnLoaded", false);
		component.set("v.blnLoaded", true);
		$A.get("e.force:refreshView").fire();
	}
});