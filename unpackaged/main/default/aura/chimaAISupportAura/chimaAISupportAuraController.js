({
	disableUtility: function (component, event, helper) {
		var utilityBarAPI = component.find("chimaAIUtilityBar");
		var result = event.getParam("result");

		// get all utility info
		utilityBarAPI
			.getAllUtilityInfo()
			.then(function (response) {
				// iterate through utilities
				for (let utility of response) {
					// if utility is history, disable it
					if (utility.utilityLabel == "Request Help" && !result) {
						// set utility label
						utilityBarAPI.setUtilityLabel({
							label: "Not Available (Disabled)",
							utilityId: utility.id
						});

						// minimize utility
						helper.minimizeUtility(component, event, helper, response.utilityId);

						// handle when utility is clicked
						let utilityClickHandler = function (response) {
							helper.minimizeUtility(component, event, helper, response.utilityId);
						};

						// register event handler
						utilityBarAPI
							.onUtilityClick({
								eventHandler: utilityClickHandler,
								utilityId: utility.id
							})
							.then(function (result) {})
							.catch(function (error) {});
					}
				}
			})
			.catch(function (error) {});
	}
});