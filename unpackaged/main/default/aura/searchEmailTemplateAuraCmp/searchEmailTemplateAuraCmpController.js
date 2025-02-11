({
    handleOpenTab : function(component, event, helper) {
        //capturing the utility bar and minimizing it 
        var utilityAPI = component.find("utilitybar");
        utilityAPI.minimizeUtility();        
        
        // capturing the values passed from lwc
        var actionAPI = component.find("quickActionAPI");   
        var strFullHtmlCombined = event.getParam('fullhtmlbody');
        
        // executing the functionality and passing the values to the publisher
        actionAPI.setActionFieldValues({            
            actionName: "Case.SendEmailLTE",
            targetFields: {HtmlBody:{value: strFullHtmlCombined, insertType: "begin"}, ReplyToEmailMessageId:{value: event.getParam('strId')}}
        })
        .catch(function(e){
            console.error(JSON.stringify(e.errors));
        });        
    }
})