({
    onCustomEvent: function(component, event, helper) {
        let strData = event.getParam("data");
        component.set("v.strURL", strData);
    },
    onNewMessage: function(component, event, helper) {
        var strContent = event.getParam('content');
        var strName = event.getParam('name');
        var strType = event.getParam('type');
        var strRecordId = event.getParam('recordId');
        if (strType === 'EndUser' && component.get("v.recordId").includes(strRecordId)) {
            var notify = new Notification(`New message from ${strName}`, {
                body: strContent
            });
        }
    }
})