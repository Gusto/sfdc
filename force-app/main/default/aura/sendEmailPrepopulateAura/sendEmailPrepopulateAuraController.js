({
	doInit: function (component, event, helper) {
		
		var sURL = window.location.href;
		var userId = sURL.split("c__taskReDirect=")[1];

		if (userId) {
			component.set("v.taskRedirect", userId);
		}
	},

	handleRecordUpdated: function (component, event, helper) {
		var eventParams = event.getParams();
		if (eventParams.changeType === "LOADED") {
			// record is loaded (render other component which needs record data value)

			if (component.get("v.taskRedirect") && component.get("v.fromAddress") && component.get("v.quickAction")) {
				var actionAPI = component.find("quickActionAPI");
				var targetFields = {
					ValidatedFromAddress: {
						value: component.get("v.fromAddress")
					},
					ToAddress: {
						value: component.get("v.simpleRecord.ContactEmail")
					}
				};
				var args = { actionName: component.get("v.quickAction"), targetFields: targetFields };
				actionAPI
					.setActionFieldValues(args)
					.then(function (result) {
						console.log("Set Action Fields---" + JSON.stringify(result));
					})
					.catch(function (e) {
					});
			}
		}
	}
});