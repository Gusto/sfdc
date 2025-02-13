({
    doInit: function(component, event, helper) {
        var myPageRef = component.get("v.pageReference");
        /** Getting the record Id from the Parent Page */
        var recordId = myPageRef.state.c__recordId;
        /** Setting the record Id in an attribute to pass to LWC */
        component.set("v.idRec", recordId);
    },

    handleCloseTab: function(component, event, helper) {

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