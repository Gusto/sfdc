({
	minimizeUtility: function (component, event, helper, utilityId) {
		let utilityBarAPI = component.find("chimaAIUtilityBar");

		utilityBarAPI
			.minimizeUtility({
				utilityId: utilityId
			})
			.then(function (result) {})
			.catch(function (error) {});
	}
});