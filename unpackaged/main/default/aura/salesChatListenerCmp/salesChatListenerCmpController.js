({
    onChatEnded: function(component, event, helper) {
        var recordId = event.getParam("recordId");
        
        var inputVariables = [
         { 
             name : "idChatTranscript",
             type : "String",
             value: event.getParam("recordId")
         }
       ];
        
        var flow = component.find("flowData");
        flow.startFlow("Post_Chat_Notes", inputVariables);
    }
})