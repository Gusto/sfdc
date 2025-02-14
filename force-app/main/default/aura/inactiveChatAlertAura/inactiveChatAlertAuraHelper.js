({
	// Function to snooze the tab
	snoozeTab: function (component, event, helper) {
		if (component.get("v.intCount") !== 2) {
			// Increment the count
			component.set("v.intCount", component.get("v.intCount") + 1);
			// Get chat parameters
			let objChatParameter = component.get("v.objChatParameter");
			// capture the local context
			var self = this;
			// Set a timeout to redirect to the snoozed tab
			window.setTimeout(
				$A.getCallback(function () {
					self.redirectToSnoozedTab(component, event, helper);
				}),
				objChatParameter.timeoutlimit
			);
		}
	},

	// Function to redirect to the snoozed tab
	redirectToSnoozedTab: function (component, event, helper) {
		// capture the local context
		var self = this;
		// Get chat parameters from the component attribute
		var objChatParameter = component.get("v.objChatParameter");
		// Get tab information from the component attribute
		var tabInfo = component.get("v.tabInfo");
		// Get workspace API instance
		var workspaceAPI = component.find("workspace");

		if (workspaceAPI) {
			// Highlight the tab with error state and pulse effect
			workspaceAPI
				.setTabHighlighted({
					tabId: tabInfo.tabId,
					highlighted: true,
					options: {
						pulse: true,
						state: "error"
					}
				})
				.then(function (response) {
					// Display an alert with the timeout message and tab title
					alert(tabInfo.title + ": " + objChatParameter.timeoutmessage);
					// Repeat the snooze process
					self.snoozeTab(component);
				})
				.catch(function (error) {
					// Log any errors
					console.error("setTabHighlighted: " + error);
				});
		}
	}
});