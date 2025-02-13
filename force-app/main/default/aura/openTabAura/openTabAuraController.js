({
	handleOpen: function (component, event, helper) {
		let strSearchUrl = component.get("v.searchURL");

		if (helper.isValidURL(strSearchUrl)) {
			component
				.find("workspace")
				.openTab({
					url: strSearchUrl,
					focus: true
				})
				.catch(function (error) {
					helper.showToast("error", "ERROR!", "Invalid/ Not an SFDC URL.");
					console.log(error);
				});
		} else {
			helper.showToast("error", "ERROR!", "Invalid URL.");
		}
	}
});