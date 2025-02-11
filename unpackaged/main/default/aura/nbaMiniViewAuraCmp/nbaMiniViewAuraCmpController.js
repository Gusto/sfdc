({
	doInit: function (component, event, helper) {
		// fetch opportunity data, fields from opportunity and account field sets
		var action = component.get("c.getFieldsFromFieldSet");
		// set apex method parameters
		action.setParams({
			strOppFieldSet: component.get("v.strOppFieldSet"),
			strAccFieldSet: component.get("v.strAccFieldSet"),
			strLeadFieldSet: component.get("v.strLeadFieldSet"),
			oppRecordId: component.get("v.recordId")
		});

		action.setCallback(this, function (response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				let fieldSetResponse = response.getReturnValue();
				// set opportunity fields if apex function returns success flag
				if (fieldSetResponse.blnSuccess) {
					component.set("v.oppFields", fieldSetResponse.list_OppFields);
					component.set("v.leadFields", fieldSetResponse.list_LeadFields);

					// if opportunity data is available, set account fields
					if (fieldSetResponse.objOppty) {
						component.set("v.strAccountId", fieldSetResponse.objOppty.AccountId);
						component.set("v.accFields", fieldSetResponse.list_AccFields);
					}
				} else {
					var toastEvent = $A.get("e.force:showToast");
					toastEvent.setParams({
						title: "Error in loading mini view",
						message: "Reason - " + fieldSetResponse.strMessage,
						type: "error"
					});
					toastEvent.fire();
				}
			}
		});
		$A.enqueueAction(action);
	},

	// toggle opportunity mini and detail view. also change title and checkbox label
	handleOppChange: function (component, event, helper) {
		if (event.detail.checked) {
			component.set("v.strOppCheckbox", "Show Mini View");
			component.set("v.strOppTitle", "Opportunity Detail View");
			component.set("v.blnOppDetailViewVisible", true);
		} else {
			component.set("v.strOppCheckbox", "Show Detail View");
			component.set("v.strOppTitle", "Opportunity Mini View");
			component.set("v.blnOppDetailViewVisible", false);
		}
	},

	// toggle account mini and detail view. also change title and checkbox label
	handleAccChange: function (component, event, helper) {
		if (event.detail.checked) {
			component.set("v.strAccCheckbox", "Show Mini View");
			component.set("v.strAccTitle", "Account Detail View");
			component.set("v.blnAccDetailViewVisible", true);
		} else {
			component.set("v.strAccCheckbox", "Show Detail View");
			component.set("v.strAccTitle", "Account Mini View");
			component.set("v.blnAccDetailViewVisible", false);
		}
	},

	// toggle lead mini and detail view. also change title and checkbox label
	handleLeadChange: function (component, event, helper) {
		if (event.detail.checked) {
			component.set("v.strLeadCheckbox", "Show Mini View");
			component.set("v.strLeadTitle", "Lead Detail View");
			component.set("v.blnLeadDetailViewVisible", true);
		} else {
			component.set("v.strLeadCheckbox", "Show Detail View");
			component.set("v.strLeadTitle", "Lead Mini View");
			component.set("v.blnLeadDetailViewVisible", false);
		}
	}
});