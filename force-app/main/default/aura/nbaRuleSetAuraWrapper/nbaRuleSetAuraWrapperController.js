({
	doInit: function (component, event, helper) {
		var workspaceAPI = component.find("workspace");
		workspaceAPI
			.getFocusedTabInfo()
			.then(function (response) {
				var focusedTabId = response.tabId;
				workspaceAPI.setTabIcon({
					tabId: focusedTabId,
					icon: "standard:maintenance_work_rule",
					iconAlt: "NBA Rule Set"
				});
			})
			.catch(function (error) {
				console.log(error);
			});

		workspaceAPI
			.getFocusedTabInfo()
			.then(function (response) {
				var focusedTabId = response.tabId;
				workspaceAPI.setTabLabel({
					tabId: focusedTabId,
					label: "NBA Rule Set"
				});
			})
			.catch(function (error) {
				console.log(error);
			});
	},
	handleOpenRecord: function (component, event, helper) {
		var workspaceAPI = component.find("workspace");
		workspaceAPI
			.openTab({
				recordId: event.getParam("data"),
				focus: true
			})
			.then(function (response) {})
			.catch(function (error) {
				console.log(error);
			});
	},

	handleOpenSubTab: function (component, event, helper) {
		// workspace api
		var workspaceAPI = component.find("workspace");
		var globalId = component.getGlobalId();

		workspaceAPI
			.openTab({
				pageReference: {
					type: "standard__component",
					attributes: {
						componentName: "c__nbaUserInterfaceAuraWrapper"
					},
					state: {
						c__uniqueId: event.getParam("data"),
						c__Id: event.getParam("data"),
						uid: event.getParam("data")
					}
				},
				focus: true
			})
			.then(function (response) {
				console.log(response);
			})
			.catch(function (error) {
				console.log(error);
			});
	}
});