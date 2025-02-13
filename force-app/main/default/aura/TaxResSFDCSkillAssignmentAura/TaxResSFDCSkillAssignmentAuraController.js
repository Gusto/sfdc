({
	doInit: function (component, event, helper) {},
	openReportInNewTab: function (component, event, helper) {
		// Replace 'reportId' with the actual Id of your report
		var reportId = event.getParam("idReport"); // Replace with your report's Id

		var workspaceAPI = component.find("workspace");
		if (workspaceAPI) {
			workspaceAPI
				.openTab({
					url: "/lightning/r/Report/" + reportId + "/view",
					focus: true
				})
				.then(function (response) {
					// Report opened in a new tab successfully
				})
				.catch(function (error) {
					// Handle any errors here
					console.error(error);
				});
		} else {
			// Workspace API not available, handle accordingly
			console.error("Workspace API is not available.");
		}
	}
});