({
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
	},

	openUtility: function (component, event) {
		var utilityAPI = component.find("utilitybar");
		utilityAPI
			.getAllUtilityInfo()
			.then(function (response) {
				response.forEach(function (utilityInfo) {
					if (utilityInfo.utilityLabel === "Phone") {
						if (utilityInfo.utilityVisible === false) {
							utilityAPI.openUtility({
								utilityId: utilityInfo.id
							});
						}
					}
				});
			})
			.catch(function (error) {
				console.log(error);
			});
	}
});