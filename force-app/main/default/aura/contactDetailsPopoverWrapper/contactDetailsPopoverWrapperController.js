({
    handleMouseLeave : function(component, event, helper) {
        
        // var compEvent = component.getEvent("mouseLeaveEvent");
        // compEvent.fire();
        var appEvent = $A.get("e.c:mouseLeaveComponentEvent");
        // Optional: set some data for the event (also known as event shape)
        // A parameter’s name must match the name attribute
        // of one of the event’s <aura:attribute> tags
        //appEvent.setParams({ "myParam" : myValue });
        appEvent.fire();
        console.log('!! app fired leave event');
    },
    handleMouseOver : function(component, event, helper) {
        
        // var compEvent = component.getEvent("mouseLeaveEvent");
        // compEvent.fire();
        var appEvent = $A.get("e.c:mouseOverComponentEvent");
        // Optional: set some data for the event (also known as event shape)
        // A parameter’s name must match the name attribute
        // of one of the event’s <aura:attribute> tags
        //appEvent.setParams({ "myParam" : myValue });
        appEvent.fire();
        console.log('!! app fired mouse over event');
    }
})