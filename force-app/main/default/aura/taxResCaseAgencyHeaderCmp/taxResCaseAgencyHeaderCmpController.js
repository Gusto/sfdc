({
    doInit : function(component, event, helper) {
        helper.getCase(component);
    },
    handleOpenAgencyInfo : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        var idAgencyInfo = component.get("v.objCase").Agency_Information__c;
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var strFocusTab = response.tabId;
            workspaceAPI.openSubtab({
                parentTabId: strFocusTab,
                recordId: idAgencyInfo,
                focus: true
            });
        })
        .catch(function(error) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "Error while opening up Agency Information.",
                "type": "error"
            });
            toastEvent.fire();
        });
    },
    refreshView : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
    },
    updateClicked : function(component, event, helper) {
        $A.enqueueAction(component.get('c.toggleViewAgency'));
        component.set('v.strAgencyInfoId', "");
        component.set("v.blnShowPopover", false);
    },
    toggleViewAgency : function(component, event, helper) {
        component.set("v.blnViewAgency", !component.get("v.blnViewAgency"));
    },
    handleSave : function(component, event, helper) {
        helper.saveAgencyInfo(component);
    },
    handleReset: function(component, event, helper) {
        component.set("v.strAgencyInfoId", component.get("v.strOrigAgencyInfoId"));
        component.find("caseAgencyInfoId").reset();
        $A.enqueueAction(component.get('c.toggleViewAgency'));
    },
    handleShowPop : function(component, event, helper) {
        component.set("v.blnMouseOverText", true);
        if (!component.get("v.blnIsPopOverOpen")) {
            $A.createComponent("c:caseAgencyHeaderPopoverAura", { recordId : component.get("v.recordId") },
            function(content, status, errorMessage) {
                if (status === "SUCCESS") {
                    component.find('overlayLib').showCustomPopover({
                        body: content, 
                        referenceSelector: "#agencyCss" + component.get("v.recordId"),
                        cssClass: "popClass"
                    }).then(function (overlay) {
                        component._overlay = overlay;
                        component.set("v.popoverInstance", overlay);
                        let timerInstance = setTimeout(function() {
                            if(component.get("v.blnMouseOverChild") === false && component.get("v.blnMouseOverText") === false ) {
                                component.get("v.popoverInstance").close();
                                component.set("v.blnIsPopOverOpen", false);
                            } else {
                                helper.createNewPopOverTimer(component, event);
                            }
                        }, 1000);
                        component.set("v.timerInstance" , timerInstance);
                        component.set("v.blnIsPopOverOpen", true);
                    });
                }
            });
            
        } else { 
            helper.createNewPopOverTimer(component, event);
        }
    },
    handleMouseAwayFromText : function(component, event, helper) {
        component.set("v.blnMouseOverText", false);
    },
    handleMouseLeavePopover : function(component, event, helper) {
        if (event.getParam("recordId") === component.get("v.recordId")) {
        	component.set("v.blnMouseOverChild", false);
        }
    },
    handleMouseOverPopover : function(component, event, helper) {
        if (event.getParam("recordId") === component.get("v.recordId")) {
        	component.set("v.blnMouseOverChild", true);
        }
    },
    handleClosePopOver: function(component, event, helper) {
        if (event.getParam("recordId") === component.get("v.recordId")) {
        	let popOverInstance = component.get("v.popoverInstance");
            if (popOverInstance) {
                popOverInstance.close();
                component.set("v.blnIsPopOverOpen", false);
                component.get("v.blnMouseOverChild", false);
            }
        }
    }
})