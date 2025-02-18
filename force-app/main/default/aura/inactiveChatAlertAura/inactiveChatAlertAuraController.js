({
	// Initialization function
	doInit: function (component, event, helper) {
		// Set chat parameters from custom label
		component.set("v.objChatParameter", JSON.parse($A.get("$Label.c.InactiveChatParameters")));
		// Get workspace API instance
		var workspaceAPI = component.find("workspace");

		if (workspaceAPI) {
			// Get the enclosing tab ID
			workspaceAPI
				.getEnclosingTabId()
				.then(function (tabId) {
					// Get tab information using the tab ID
					workspaceAPI
						.getTabInfo({
							tabId: tabId
						})
						.then(function (response) {
							// Set tab information to the component attribute
							component.set("v.tabInfo", response);
						})
						.catch(function (error) {
							// Log any errors
							console.error("getTabInfo: " + error);
						});
				})
				.catch(function (error) {
					// Log any errors
					console.error("getEnclosingTabId: " + error);
				});
			}
	},

	// Handler for chat ended event
	onChatEnded: function (component, event, helper) {
		// Get the record ID from the event
		let recordId = event.getParam("recordId");
		// Check if the component's record ID includes the event's record ID
		if (component.get("v.recordId").includes(recordId)) {
			// Call the helper function to snooze the tab
			helper.snoozeTab(component);
		}
	}
});