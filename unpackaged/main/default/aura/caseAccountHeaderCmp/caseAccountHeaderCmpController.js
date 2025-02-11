({
    doInit : function(component, event, helper) {
        helper.getCase(component);
    },
    handleOpenAccount : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        var idAccount = component.get("v.case").AccountId;
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var strFocusTab = response.tabId;
            workspaceAPI.openSubtab({
                parentTabId: strFocusTab,
                recordId: idAccount,
                focus: true
            });
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    handleOpenCase : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        var idCase = event.getParam('caseid');
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var strFocusTab = response.tabId;
            workspaceAPI.openSubtab({
                parentTabId: strFocusTab,
                recordId: idCase,
                focus: true
            });
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    handleOpenNote : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        var idNote = event.getParam('noteid');
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var strFocusTab = response.tabId;
            workspaceAPI.openSubtab({
                parentTabId: strFocusTab,
                recordId: idNote,
                focus: true
            });
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    refreshView : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
    },
    updateClicked : function(component, event, helper) {
        $A.enqueueAction(component.get('c.toggleViewAccount'));
        component.set('v.strAccountId', "");
        component.set("v.blnShowPopover", false);
    },
    toggleViewAccount : function(component, event, helper) {
        component.set("v.blnViewAccount", !component.get("v.blnViewAccount"));
    },
    handleSave : function(component, event, helper) {
        helper.saveAccount(component);
    },
    handleReset: function(component, event, helper) {
        component.set("v.strAccountId", component.get("v.strOrigAccountId"));
        component.find("caseAccountId").reset();
        $A.enqueueAction(component.get('c.toggleViewAccount'));
    },
    goToPanda : function(component, event, helper){
        if(component.get("v.strPandaURL") !== '') {
            window.open('https://app.gusto.com/panda/' + component.get("v.strPandaURL"), '_blank');
        }
    },
    goToHippo : function(component, event, helper){
        if(component.get("v.strPandaURL") !== '') {
            window.open('https://hippo.gusto.com/' + component.get("v.strPandaURL"), '_blank');
        }
        
    },
    handleShowPop : function(component, event, helper) {
        component.set("v.blnMouseOverText", true);
        if(!component.get("v.isPopOverOpen")) {
            $A.createComponent("c:caseAccountHeaderPopoverAura", { recordId : component.get("v.recordId") },
            function(content, status, errorMessage) {
                if (status === "SUCCESS") {
                    component.find('overlayLib').showCustomPopover({
                        body: content, 
                        referenceSelector: "#acctCss" + component.get("v.recordId"),
                        cssClass: "popClass"
                    }).then(function (overlay) {
                        component._overlay = overlay;
                        component.set("v.popoverInstance", overlay);
                        let timerInstance = setTimeout(function() {
                            if(component.get("v.blnMouseOverChild") === false && component.get("v.blnMouseOverText") === false ) {
                                component.get("v.popoverInstance").close();
                                component.set("v.isPopOverOpen", false);
                            } else {
                                helper.createNewPopOverTimer(component, event);
                            }
                        }, 1000);
                        component.set("v.timerInstance" , timerInstance);
                        component.set("v.isPopOverOpen", true);
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
        if(event.getParam("recordId") === component.get("v.recordId")) {
        	component.set("v.blnMouseOverChild", false);
        }
    },
    handleMouseOverPopover : function(component, event, helper) {
        if(event.getParam("recordId") === component.get("v.recordId")) {
        	component.set("v.blnMouseOverChild", true);
        }
    },
    handleClosePopOver: function(component, event, helper) {
        if(event.getParam("recordId") === component.get("v.recordId")) {
        	let popOverInstance = component.get("v.popoverInstance");
            if(popOverInstance) {
                popOverInstance.close();
                component.set("v.isPopOverOpen", false);
                component.get("v.blnMouseOverChild", false);
            }
        }
    }
})