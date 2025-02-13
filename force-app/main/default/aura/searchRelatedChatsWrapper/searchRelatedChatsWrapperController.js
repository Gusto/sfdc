({
    /* Handler to perform actions on initial load */
    doInit: function (component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo()
            .then(function (response) {
                var idFocusedTab = response.tabId;
                if (response.customTitle === 'Search Related Chats') {
                    component.set("v.idPrimaryTab", idFocusedTab);
                    workspaceAPI.setTabIcon({
                        tabId: idFocusedTab,
                        icon: "standard:live_chat",
                        iconAlt: "Search Related Chats"
                    });
                }  
            })
            .catch(function (error) {
                helper.showToast('Error', error, 'error', 'sticky');
            });

        /* To minimize any open utility bar item when agents click on Search related chats button */    
        var utilityBarAPI = component.find("utilitybar");
        utilityBarAPI.getAllUtilityInfo()
            .then(function (response) {
                for (let strKey in response) {
                    if (response[strKey].utilityVisible) {
                        utilityBarAPI.minimizeUtility({
                            utilityId: response[strKey].id
                        });
                    }
                }
            })
            .catch(function (error) {
                helper.showToast('Error', error, 'error', 'sticky');
            });

        helper.getSessionCache(component);
    },

    /* Handle when the tab is closed */
    onTabClosed: function (component, event, helper) {
        var workspaceAPI = component.find("workspace");
        var idClosedTab = event.getParam('tabId');
        var idFocusedCase = component.get("v.idFocusedCase");
        var idPrimaryTab = component.get("v.idPrimaryTab");
        if (idClosedTab === idPrimaryTab) {
            var result = workspaceAPI.focusTab({
                tabId: idFocusedCase
            }).then(function (response) {
            }).catch(function (focusError) {
                helper.showToast('Error', focusError, 'error', 'sticky');
            });
        }
    },

    /* Handler to open the ChatTranscript in a subtab when a row is clicked on the datatable */
    openChatRecord : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var idFocusedTab = response.tabId;
            workspaceAPI.openSubtab({
                parentTabId: idFocusedTab,
                recordId: event.getParam('chatId'),
                focus: true
            });
       })
        .catch(function(error) {
            helper.showToast('Error', error, 'error', 'sticky');
        });
    },

    /* Handler for tab creation where we set the primary tab id */
    onTabCreated : function(component, event) {
        var idNewTab = event.getParam('tabId');
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getTabInfo({
            tabId : idNewTab
        }).then(function(response) {
            if (response.pageReference.attributes.apiName === 'Search_Related_Chats') {
                workspaceAPI.setTabIcon({
                    tabId: idNewTab,
                    icon: "standard:live_chat",
                    iconAlt: "Search Related Chats"
                });
                component.set("v.idPrimaryTab", idNewTab);
            }
        })
        .catch(function(error) {
            helper.showToast('Error', error, 'error', 'sticky');
        });
    }
})