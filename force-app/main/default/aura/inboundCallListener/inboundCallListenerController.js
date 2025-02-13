({
	onInit: function (component, event, helper) {
		var action = component.get("c.loggedInUserEmail");

		// Create a callback that is executed after
		// the server-side action returns
		action.setCallback(this, function (response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				let loggedInEmailAddress = response.getReturnValue();

				if (loggedInEmailAddress) {
					component.set("v.loggedInEmailAddress", response.getReturnValue());

					// Get the empApi component
					const empApi = component.find("empApi");
					// Get the channel from the input box
					const channel = component.find("channel").get("v.value");
					// Replay option to get new events
					const replayId = -1;

					// Subscribe to an event
					empApi
						.subscribe(
							channel,
							replayId,
							$A.getCallback((eventReceived) => {
								// Process event (this is called each time we receive an event)
								let emailAddress = eventReceived.data.payload.Email_Address__c;
								let loggedInEmailAddress = component.get("v.loggedInEmailAddress");

								if (loggedInEmailAddress == emailAddress) {
									var a = component.get("c.openUtility");
									$A.enqueueAction(a);
								}
							})
						)
						.then((subscription) => {
							console.log("Subscription request sent to: ", subscription.channel);
						});
				}
			}
		});

		$A.enqueueAction(action);
	},

	openUtility: function (component, event, helper) {
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