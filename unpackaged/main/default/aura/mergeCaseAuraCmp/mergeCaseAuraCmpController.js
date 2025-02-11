({
	handlePrimaryTab: function (component, event, helper) {
		// selected case record Id
		var idRecord = event.getParam("detailRecordId");
		//selected case number
		var strCaseNumber = event.getParam("newCaseNumber");
		var workspaceAPI = component.find("workspace");
		// opening the new primary tab
		workspaceAPI.getFocusedTabInfo().then(function (response) {
			/* setting the Focussed tab */
			var focusedTabId = response.tabId;
			/* opening the Primary Tab */
			workspaceAPI
				.openTab({
					pageReference: {
						type: "standard__recordPage",
						attributes: {
							recordId: idRecord,
							objectApiName: "Case",
							actionName: "view"
						}
					},
					focus: true
				})
				.then(function (response) {
					/* Setting the Tab properties */
					workspaceAPI.setTabLabel({
						tabId: response,
						label: strCaseNumber
					}),
						/* Setting the Tab icon properties */
						workspaceAPI.setTabIcon({
							tabId: response,
							icon: "standard:case",
							iconAlt: "Case"
						});
				})
				.catch(function (error) {
					console.log(error);
				});
		});
	},
	// this method runs on the load of the page
	init: function (component, event, helper) {
		var idRecordId = component.get("v.recordId");

		//below condition is added to check if record id is null or not
		if (idRecordId === undefined || idRecordId === "") {
			//Fetching the current case id from the page parameters and setting the current case id
			var pageReference = component.get("v.pageReference");
			idRecordId = pageReference.state.c__caserecordId;
		}
		component.set("v.idCaseRecord", idRecordId);
	},

	closeSubTab: function (component, event, helper) {
		var workspaceAPI = component.find("workspace");
		var selectedCaseRecordsIds = [];
		selectedCaseRecordsIds = event.getParam("selectedCaseRecords");

		//Below logic closes if any of merge related cases are open and keeps the parent merge case tab open
		if (selectedCaseRecordsIds != "" && selectedCaseRecordsIds != undefined) {
			var currentRecordId = component.get("v.idCaseRecord");
			var currentTabId;
			workspaceAPI
				.getAllTabInfo()
				.then(function (response) {
					for (let i = 0; i < response.length; i++) {
						if (selectedCaseRecordsIds.includes(response[i].recordId)) {
							workspaceAPI.closeTab({ tabId: response[i].tabId });
						}
						if (response[i].recordId == currentRecordId) {
							currentTabId = response[i].tabId;
						}
					}
					workspaceAPI.refreshTab({ tabId: currentTabId }); //Refresh the current Case tab
					$A.get("e.force:closeQuickAction").fire(); //Close the Modal Window
				})
				.catch(function (error) {
					console.log(error);
				});
		} else {
			var workspaceAPI = component.find("workspace");
			//closing the tab from the console.
			workspaceAPI
				.getFocusedTabInfo()
				.then(function (response) {
					var focussedTab = response.tabId;
					workspaceAPI.closeTab({ tabId: focussedTab });
					workspaceAPI.refreshTab({
						tabId: response.parentTabId,
						includeAllSubtabs: true
					});
				})
				.catch(function (error) {
					console.log(error);
				});
		}
	},

	refreshWholePage: function (component, event, helper) {
		var workspaceAPI = component.find("workspace");
		//refreshing the tab from the console.
		workspaceAPI
			.getFocusedTabInfo()
			.then(function (response) {
				var focusedTabId = response.tabId;

				workspaceAPI.refreshTab({
					tabId: response.parentTabId,
					includeAllSubtabs: true
				});
			})
			.catch(function (error) {
				console.log(error);
			});
	}
});