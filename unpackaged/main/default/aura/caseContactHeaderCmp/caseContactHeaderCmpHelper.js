({
    handleUpdateClicked: function (component, event) {
        let blnViewContact = component.get("v.blnViewContact");
        component.set("v.blnViewContact", !blnViewContact);
    },

    createNewPopOverTimer: function (component, event) {
        if (component.get("v.blnPopOverOpen")) {
            let timerInstance = component.get("v.timerInstance");
            clearTimeout(timerInstance);
            let newTimerInstance = setTimeout($A.getCallback(this.check.bind(this, component, event)), 1000);

            component.set("v.timerInstance", newTimerInstance);
            component.set("v.blnPopOverOpen", true);
        }
    },

    check: function (component, event) {
        let popOverInstance = component.get("v.popoverInstance");
        if (popOverInstance && component.get("v.blnMouseOverChild") === false && component.get("v.blnMouseOverText") === false) {
            popOverInstance.close();
            component.set("v.blnPopOverOpen", false);
        } else {
            this.createNewPopOverTimer(component, event);
        }

    }
})