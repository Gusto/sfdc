({
	doInit: function (component, event, helper) {
		let recordId = component.get("v.recordId");

		if (recordId) return;

		let workspaceAPI = component.find("workspace");

		workspaceAPI
			.getEnclosingTabId()
			.then(function (tabId) {
				console.log(tabId);

				let enclosingTabId = tabId;

				workspaceAPI
					.getAllTabInfo()
					.then(function (tabInfo) {
						for (let tabObj of tabInfo) {
							if (tabObj.tabId == enclosingTabId) {
								component.set("v.recordId", tabObj.recordId);
							}
						}
					})
					.catch(function (error) {
						console.log(error);
					});
			})
			.catch(function (error) {
				console.log(error);
			});
	},
    currentDisableTab : function(component, event, helper) {
        let isDisabled = event.getParam('isDisabled');
        
		helper.handleCurrentDisableTab(component, event, helper, isDisabled);
        helper.handledisableAllOtherTab(component, event, helper, isDisabled)
	}
});