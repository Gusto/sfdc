({
	handleCurrentDisableTab: function (component, event, helper, isDisabled) {
		let workspaceAPI = component.find("workspace");
		let currentRecordId = component.get("v.recordId").substring(0, 15);

		workspaceAPI
			.getFocusedTabInfo()
			.then(function (response) {
				let focusedTabId = response.tabId;
				let tabRecordId = response.recordId ? response.recordId.substring(0, 15) : '';

				// iterate over all sub tabs and enable tab close
				if (response.subtabs) {
					for (let tabCounter of response.subtabs) {

						let tabRecordId = tabCounter.recordId ? tabCounter.recordId.substring(0, 15) : '';

						if (tabRecordId == currentRecordId) {
							// set disabled to false
							workspaceAPI
								.disableTabClose({
									tabId: tabCounter.tabId,
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
				}

				if (tabRecordId == currentRecordId) {
					workspaceAPI
					.disableTabClose({
						tabId: focusedTabId,
						disabled: isDisabled
					})
					.then(function (tabInfo) {
						console.log("Success");
					})
					.catch(function (error) {
						console.log("Error ", error);
					});
				}
				
			})
			.catch(function (error) {
				console.log(error);
			});
	},

	handledisableAllOtherTab: function (component, event, helper, isDisabled) {
		let currentRecordId = component.get("v.recordId").substring(0, 15);
		let workspaceAPI = component.find("workspace");
		
		workspaceAPI
			.getAllTabInfo()
			.then(function (response) {
				for (let tabObj of response) {
					if (tabObj.subtabs) {
						// iterate over all sub tabs and enable tab close
						for (let tabCounter of tabObj.subtabs) {
							let tabRecordId = tabCounter.recordId ? tabCounter.recordId.substring(0, 15) : '';

							if (tabRecordId == currentRecordId) {
								// set disabled to false
								workspaceAPI
									.disableTabClose({
										tabId: tabCounter.tabId,
										disabled: isDisabled
									})
									.then(function (tabInfo) {
										console.log(tabInfo);
									})
									.catch(function (error) {
										console.log(error);
									});
							}
						}
					}

					let tabRecordId = tabObj.recordId ? tabObj.recordId.substring(0, 15) : '';
					
					if (tabRecordId == currentRecordId) {
						workspaceAPI
							.disableTabClose({
								tabId: tabObj.tabId,
								disabled: isDisabled
							})
							.then(function (tabInfo) {
								console.log("Success");
							})
							.catch(function (error) {
								console.log("Error ", error);
							});
					}
				}
			})
			.catch(function (error) {
				console.log(error);
			});
	}
});