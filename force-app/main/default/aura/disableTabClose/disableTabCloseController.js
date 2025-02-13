({
	doInit: function (component, event, helper) {
		let workspaceAPI = component.find("workspace");

		workspaceAPI
			.getFocusedTabInfo()
			.then(function (response) {
				let focusedTabId = response.tabId;
				console.log("response ", response);
				console.log("response sub tabs ", response.subtabs);
				// iterate over all sub tabs and enable tab close
				if (response.subtabs) {
					for (let tabCounter in response.subtabs) {
						// set disabled to false
						workspaceAPI
							.disableTabClose({
								tabId: response.subtabs[tabCounter].tabId,
								disabled: false
							})
							.then(function (tabInfo) {
								console.log(tabInfo);
							})
							.catch(function (error) {
								console.log(error);
							});
					}
				}

				workspaceAPI
					.disableTabClose({
						tabId: focusedTabId,
						disabled: false
					})
					.then(function (tabInfo) {
						console.log("Success");
					})
					.catch(function (error) {
						console.log("Error ", error);
					});
			})
			.catch(function (error) {
				console.log(error);
			});
	}
});