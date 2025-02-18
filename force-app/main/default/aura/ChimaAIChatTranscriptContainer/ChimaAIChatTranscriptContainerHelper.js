({
    handleCurrentDisableTab : function(component, event, helper, isDisabled) {
        let workspaceAPI = component.find("workspace");
        
        workspaceAPI.getFocusedTabInfo()
        .then(function(response) {
            let focusedTabId = response.tabId;
            
            workspaceAPI.disableTabClose({
                tabId: focusedTabId,
                disabled: isDisabled
            })
            .then(function(tabInfo) {
                console.log("Success");
            })
            .catch(function(error) {
                console.log("Error ", error);
            });
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    
    handledisableAllOtherTab : function(component, event, helper, isDisabled) {
        let currentRecordId = component.get("v.recordId").substring(0, 15);
        let workspaceAPI = component.find("workspace");
        
        workspaceAPI.getAllTabInfo()
        .then(function(response) {
            
            for(let tabObj of response){
                let tabRecordId = tabObj.recordId ? tabObj.recordId.substring(0, 15) : '';
                
                if(currentRecordId == tabRecordId && tabObj.iconAlt == 'LiveChatTranscript'){
                    
                    workspaceAPI.disableTabClose({
                        tabId: tabObj.tabId,
                        disabled: isDisabled
                    })
                    .then(function(tabInfo) {
                        console.log("Success");
                    })
                    .catch(function(error) {
                        console.log("Error ", error);
                    });
                }
            }
        })
        .catch(function(error) {
            console.log(error);
        });
    }
})