({
	setTabLabel: function (component, event, helper) {
		var workspaceAPI = component.find("workspace");
		// set tab icon
		workspaceAPI
			.getFocusedTabInfo()
			.then(function (response) {
				var focusedTabId = response.tabId;
				workspaceAPI.setTabIcon({
					tabId: focusedTabId,
					icon: "standard:maintenance_work_rule",
					iconAlt: event.getParam("data").objRuleSet.Rule_Name__c
				});
			})
			.catch(function (error) {
				console.log(error);
			});
		// set tab label
		workspaceAPI
			.getFocusedTabInfo()
			.then(function (response) {
				var focusedTabId = response.tabId;
				workspaceAPI.setTabLabel({
					tabId: focusedTabId,
					label: event.getParam("data").objRuleSet.Rule_Name__c
				});
			})
			.catch(function (error) {
				console.log(error);
			});
	}
});