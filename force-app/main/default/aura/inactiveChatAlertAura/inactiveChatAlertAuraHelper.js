({
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
					// Set the Time stamp
					self.handleSave(component);
					// Repeat the snooze process
					self.snoozeTab(component);
				})
				.catch(function (error) {
					// Log any errors
					console.error("setTabHighlighted: " + error);
				});
		}
	},

	handleSave: function (component, event, helper) {
		// Get the record object from the component's attribute
		var objRecord = component.get("v.objRecord");

		// Update the appropriate reminder stamp based on the count
		if (component.get("v.intCount") === 1) {
			objRecord.Reminder_Timestamp_1__c = new Date();
		} else if (component.get("v.intCount") === 2) {
			objRecord.Reminder_Timestamp_2__c = new Date();
		}

		// Set the updated record object back to the component's attribute
		component.set("v.objRecord", objRecord);

		// Save the record using force:recordData
		const recordHandler = component.find("recordHandler");
		recordHandler.saveRecord(
			$A.getCallback(function (saveResult) {
				// Handle the result of the save operation
				if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
				} else if (saveResult.state === "ERROR") {
					// Log the error and show an alert
					console.error("Error saving record:", JSON.stringify(saveResult.error));
				} else {
					// Log any unknown state
					console.log("Unknown problem, state:", saveResult.state);
				}
			})
		);
	}
});