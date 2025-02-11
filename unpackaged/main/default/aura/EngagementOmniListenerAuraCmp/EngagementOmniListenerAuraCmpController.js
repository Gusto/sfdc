({
	// On Tab Closed, Remove Case Id from Session and update case status to open
	doCaseUpdateOnAgentStatusChange: function (component, event, helper) {
		console.log("omniChannelStatusChangedevent:: called");
		var omniAPI = component.find("omniToolkit");
		var currentStatus = event.getParam("statusName");
		console.log("currentStatus::" + currentStatus);

		if (currentStatus == "Email - Available") {
			var action = component.get("c.updateCaseStatus");
			action.setParams({ strPresenceStatus: currentStatus });
			action.setCallback(this, function (response) {
				var state = response.getState();
				if (state === "SUCCESS") {
					console.log("SUCCESS: " + state);
				}
			});
			$A.enqueueAction(action);
		}
	}
});