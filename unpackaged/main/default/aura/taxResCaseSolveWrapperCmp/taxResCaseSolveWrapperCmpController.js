({
	copyTextToPublisher : function(component, event, helper) {
        var strFullHtmlCombined = event.getParam('fullhtmlbody');
        var caseIdValue = event.getParam('caseId');
        var list_documentIds = event.getParam('list_SelectedDocIds');
        var list_AttachmentIds = event.getParam('list_SelectedAttachmentIds');
        var strAttachmentIds = '';
        if (list_AttachmentIds != null && list_AttachmentIds.length > 0) {
            strAttachmentIds = list_AttachmentIds.join(',');
        }
        var actionAPI = component.find("quickActionAPI"); 
        // executing the functionality and passing the values to the publisher
        actionAPI.setActionFieldValues({            
            actionName: "Case.SendEmailLTE",
            targetFields: {
                HtmlBody:{value: strFullHtmlCombined, insertType: "begin"}, 
                ReplyToEmailMessageId : caseIdValue,
                AttachmentIds: {
                    Id: strAttachmentIds
                },
                ContentDocumentIds: {
                    value: list_documentIds
                }
            }
        })
        .catch(function(error){
            let strErrorMessage = error.message;
            var toastEvent = $A.get("error.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": strErrorMessage,
                "type": "error"
            });
            toastEvent.fire();
        });
    }
})