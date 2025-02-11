({
	doInit: function (component) {
		var autoStarted = component.get("v.autoStartVar");
		var workspaceAPI = component.find("workspace");
		component.set("v.recordChangeVar", false);

		if (autoStarted == true) {
			component.set("v.pausedVar", false);
		} else {
			component.set("v.pausedVar", true);
		}
		workspaceAPI.getEnclosingTabId().then(function (response) {
			var enclosingTabId = response;
			component.set("v.consoleTabId", enclosingTabId);
			component.set("v.tabFocused", true);
		});
	},

	onTabCreated: function (component, event) {
		var currentTab = component.get("v.consoleTabId");
		var newTabId = event.getParam("tabId");

		if (newTabId == currentTab) {
			component.set("v.tabFocused", true);
			component.set("v.pausedVar", false);
		} else {
			component.set("v.tabFocused", false);
			component.set("v.pausedVar", true);
		}
	},

	onTabFocused: function (component, event) {
		var currentTab = component.get("v.consoleTabId");
		var focusedTabId = event.getParam("currentTabId");

		if (focusedTabId == currentTab) {
			component.set("v.tabFocused", true);
			component.set("v.pausedVar", false);
		} else {
			component.set("v.tabFocused", false);
			component.set("v.pausedVar", true);
		}
	},

	onTabUpdated: function (component, event) {
		var focusedTabId = event.getParam("tabId");
		var currentTab = component.get("v.consoleTabId");

		if (focusedTabId == currentTab) {
			component.set("v.tabFocused", true);
			component.set("v.pausedVar", false);
		} else {
			component.set("v.tabFocused", false);
			component.set("v.pausedVar", true);
		}
	},

	onTabReplaced: function (component, event) {
		var currentTab = component.get("v.consoleTabId");
		var replacedTabId = event.getParam("tabId");

		if (replacedTabId == currentTab) {
			component.set("v.tabFocused", true);
			component.set("v.pausedVar", false);
		} else {
			component.set("v.tabFocused", false);
			component.set("v.pausedVar", true);
		}
	},

	onTabClosed: function (component, event) {
		var currentTab = component.get("v.consoleTabId");
		var tabId = event.getParam("tabId");

		if (tabId == currentTab) {
			component.set("v.maintabClosed", true);
		} else {
			component.set("v.maintabClosed", false);
		}
	},

	onRecordChange: function (component) {
		var recordChangeVar = component.get("v.recordChangeVar");

		if (recordChangeVar == false) {
			component.set("v.recordChangeVar", true);
		} else {
			component.set("v.recordChangeVar", false);
		}
	},

	parentreceivedid: function (component, event) {
		var workspaceAPI = component.find("workspace");
		var agentId = event.getParam("passedrecid");

		workspaceAPI.isConsoleNavigation().then(function (response) {
			if (response) {
				workspaceAPI
					.openTab({
						recordId: agentId
					})
					.then(function (response) {
						workspaceAPI
							.getTabInfo({
								tabId: response
							})
							.then(function (tabInfo) {});
					})
					.catch(function (error) {});
			} else {
				var navEvt = $A.get("e.force:navigateToSObject");
				navEvt.setParams({
					recordId: agentId
				});
				navEvt.fire();
			}
		});
	}
});