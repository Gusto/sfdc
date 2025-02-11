({
	doInit: function (component, event, helper) {
		var caseId = component.get("v.caseId");
		let caseIdList = [];
		let parsedArray = JSON.parse(caseId);
		parsedArray.forEach((eachCase) => {
			caseIdList.push(eachCase.Id);
		});
		component.set("v.caseIdList", caseIdList);
		helper.fetchCaseDetails(component, caseIdList);
		helper.checkEligibility(component, caseIdList);
		helper.populateOwnerTypes(component);
	},

	handleCancel: function (component, event, helper) {
		// window.history.back();
		var action = component.get("c.getListViews");
		action.setParams({
			objName: "Case", //component.get("v.toUpdateCase"),
			listviewName: "All Cases"
		});
		action.setCallback(this, function (listView) {
			let listViewName = listView.getReturnValue().Id;
			window.location = "/lightning/o/Case/list?filterName=" + listViewName;
			// put window.loction = 'whatever date'+ listViewName;
		});

		$A.enqueueAction(action);
	},

	handleRecordTypeChange: function (component, event, helper) {
		let selectedRecordType = event.getParam("value");
		component.set("v.selectedRecordType", selectedRecordType);
		if (selectedRecordType === "MF Termination" || selectedRecordType === "MF Member/Group Updates" || selectedRecordType === "MF NHE") {
			component.set("v.strChatterText", "Mass updated. Reason:");
			component.set("v.blnIsMFRTCase", true);
		} else {
			component.set("v.strChatterText", "Mass updated. Please do not route back to FS.");
			component.set("v.blnIsMFRTCase", false);
		}

		var cmpTarget = component.find("ownerUpdate");
		if (selectedRecordType !== 'Tax Res') {
			$A.util.addClass(cmpTarget, "slds-hide");
		} else if (component.get("v.selectedOwnerType") === 'Mass Update') {
			$A.util.removeClass(cmpTarget, "slds-hide");
		}

		helper.loadFieldList(component);
	},
	handleAssignmentTypeChange: function (component, event, helper) {
		component.set("v.selectedAssignmentType", event.getParam("value"));
		helper.populateStatusList(component);
	},

	handleOwnerTypeChange: function (component, event) {
		let strSelectedOwnerType = event.getParam("value");
		component.set("v.selectedOwnerType", strSelectedOwnerType);
		var cmpTarget = component.find("ownerUpdate");
		if (strSelectedOwnerType === 'Mass Update' && component.get("v.selectedRecordType") === 'Tax Res') {
			$A.util.removeClass(cmpTarget, "slds-hide");
			var cmpTarget2 = component.find("ownerIdClass");
			$A.util.addClass(cmpTarget2, "slds-hide");
		} else {
			$A.util.addClass(cmpTarget, "slds-hide");
		}
	},

	handleStatusChange: function (component, event, helper) {
		component.set("v.selectedStatus", event.getParam("value"));
	},

	handleDataChange: function (component, event, helper) {
		let caseToUpdate = component.get("v.toUpdateCase");
		caseToUpdate[event.getSource().get("v.fieldName")] = event.getParam("value") ? event.getParam("value") : event.getParam("checked");
		component.set("v.toUpdateCase", caseToUpdate);
	},

	handleLargeScaleIssueChange: function (component, event, helper) {
		let caseToUpdate = component.get("v.toUpdateCase");
		caseToUpdate.Large_Scale_Issue__c = event.getParam("value");
		component.set("v.toUpdateCase", caseToUpdate);
	},

	handleRoutingReasonChange: function (component, event, helper) {
		let caseToUpdate = component.get("v.toUpdateCase");
		caseToUpdate.Routing_Case_Reason__c = event.getParam("value");
		component.set("v.toUpdateCase", caseToUpdate);
	},

	handleConfirmRoutingReasonChange: function (component, event, helper) {
		let caseToUpdate = component.get("v.toUpdateCase");
		caseToUpdate.Confirm_Case_Reason__c = event.getParam("value");
		component.set("v.toUpdateCase", caseToUpdate);
	},

	handleMassUpdate: function (component, event, helper) {
		helper.massUpdate(component, event, false);
	},

	handleMassUpdateAndRoute: function (component, event, helper) {
		helper.massUpdate(component, event, true);
	},
	handleFilterList: function (component, event, helper) {
		var value = event.getParam("data");
		value = value ? value : "";
		var filteredList = [];

		var masterList = component.get("v.masterCaseReasonListLabels");
		console.log("--MasterList--" + masterList);
		let counter = 0;
		masterList.forEach((eachValue) => {
			if (eachValue) {
				if (eachValue.toLowerCase().includes(value.toLowerCase())) {
					if (counter < 30) {
						filteredList.push(eachValue);
						counter = counter + 1;
					}
				}
			}
		});
		console.log("--FilteredList--" + filteredList);
		component.set("v.caseReasonListLabels", filteredList);
	},
	handleFilterSelected: function (component, event, helper) {
		component.set("v.selectedField", event.getParam("data"));
		let caseToUpdate = component.get("v.toUpdateCase");
		caseToUpdate.Routing_Case_Reason__c = event.getParam("data");
		component.set("v.toUpdateCase", caseToUpdate);
	},
	handleFilterSelectedConfirm: function (component, event, helper) {
		component.set("v.selectedFieldConfirmCase", event.getParam("data"));
		let caseToUpdate = component.get("v.toUpdateCase");
		caseToUpdate.Confirm_Case_Reason__c = event.getParam("data");
		component.set("v.toUpdateCase", caseToUpdate);
	},
	handlePostFeedChange: function (component, event, helper) {
		component.set("v.blnPostFeed", component.find("postChatter").get("v.checked"));
	}
});