({
    /* Used to Open any file in the preview mode */
    OpenFile :function(component,event,helper){  
        /* capturing the record Id */
        var idRec = event.getParam("attachedfileId");

        /* Using the standard event to open the file preview in whole page */
        $A.get('e.lightning:openFiles').fire({ 
          recordIds: [idRec] 
        });  
    }, 

    /** when the user clicks on this the attachment record opens in a new Sub tab */
    handleAttachTabOpen : function(component, event, helper) {
        // workspace api
        var workspaceAPI = component.find("workspace");

        /* capturing the values from the LWC component */
        var idAttachment = event.getParam("attachmentRecId");
        var strUrl = event.getParam("attachRecUrl");

        /* declaring the Focussed tab variable*/
        var idFocusedTab;
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            /* setting the Focussed tab */
            idFocusedTab = response.tabId;

            /* opening the Sub Tab */
            workspaceAPI.openSubtab({
                parentTabId: idFocusedTab, 
                pageReference: {
                    "type": "standard__component",
                    "attributes": {
                        "componentName": "c__showAttachmentRecordCmp"
                    },
                    "state": {
                        "c__Id": idAttachment,
                        "c__url": strUrl
                    }
                }
            })       
            .then(function(response) {

                /* Setting the Tab properties */
                workspaceAPI.setTabLabel({
                    tabId: response,
                    label: 'attachmentName'
                }),

                /* Setting the Tab Icon properties */
                workspaceAPI.setTabIcon({
                    tabId: response,
                    icon: "utility:file",
                    iconAlt: 'attachmentName'
                })
            })
            .catch(function(error) {
                console.error('filesPreviewCmpController - handleAttachTabOpen -->' + error);
            });
        })
    },

    /* when the user clicks on this the Files record opens in a new Sub tab */
    handleTabOpen : function(component, event, helper) {
        // workspace api
        var workspaceAPI = component.find("workspace");

        /* capturing the values from the LWC component */
        var strAttachmentUrl = event.getParam("attachedfileurl");
        var strAttachmentName = event.getParam("attachmentfileName");
        
        /* declaring the Focussed tab variable*/
        var idFocusedTab;
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            /* setting the Focussed tab */
            idFocusedTab = response.tabId;

            /* opening the Sub Tab */
            workspaceAPI.openSubtab({
                parentTabId: idFocusedTab, 
                url: strAttachmentUrl,
                focus: true
            })       
            .then(function(response) {
                
                /* Setting the Tab properties */
                workspaceAPI.setTabLabel({
                    tabId: response,
                    label: strAttachmentName
                }),

                /* Setting the Tab Icon properties */
                workspaceAPI.setTabIcon({
                    tabId: response,
                    icon: "utility:file",
                    iconAlt: strAttachmentName
                })
            })
            .catch(function(error) {
                console.error('filesPreviewCmpController - handleTabOpen -->' + error);
            });
        })
    }
})