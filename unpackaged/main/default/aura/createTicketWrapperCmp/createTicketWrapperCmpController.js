({
    doInit : function(component, event, helper) {

        // Declare and Instantiate all your Objects
        var myPageRef = component.get("v.pageReference");
        var workspaceAPI = component.find("workspace");

        // Get Case Id from PageReference and send it down to child LWC
        var caseId = myPageRef.state.c__caseId;
        component.set("v.caseId", caseId);     
        let rendered = component.get("v.rendered");
        // // Set Tab Title to be Create a Ticket
        // if(!rendered) {
        //     workspaceAPI.getFocusedTabInfo().then(function(response) {
        //         var focusedTabId = response.tabId;
        //         component.set("v.rendered", caseId);  
        //         workspaceAPI.setTabLabel({
        //             tabId: focusedTabId,
        //             label: "New Ticket"
        //         });
        //         workspaceAPI.setTabIcon({
        //             tabId: focusedTabId,
        //             icon: "standard:case",
        //             iconAlt: "Case"
        //         })
        //     })
        //     .catch(function(error) {
        //         console.log(error);
        //     });
        // }
    },

    closeTab: function(component, event, helper) {

        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        })
        .catch(function(error) {
            console.log(error);
        });
    }
})