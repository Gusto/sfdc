({
    copyTextToPublisher : function(component, event, helper) {
        var strFullHtmlCombined = event.getParam('fullhtmlbody');
        var caseIdValue = event.getParam('caseId');
        var actionAPI = component.find("quickActionAPI"); 
        console.log('caseIdValue>>'+ caseIdValue);
        // executing the functionality and passing the values to the publisher
        actionAPI.setActionFieldValues({            
            actionName: "Case.SendEmailLTE",
            targetFields: {HtmlBody:{value: strFullHtmlCombined, insertType: "begin"}, ReplyToEmailMessageId : caseIdValue}
        })
        .catch(function(e){
            console.error(JSON.stringify(e.errors));
        });
    }
})