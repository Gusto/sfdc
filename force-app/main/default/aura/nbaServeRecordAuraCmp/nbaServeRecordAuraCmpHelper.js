({
	handleServeRecord : function(cmp, strWrapper) {
		var action = cmp.get("c.serveNextRecord");
		cmp.set("v.isLoading", true);
		// Create a callback that is executed after
		// the server-side action returns
		action.setParams({ 'strWrapper': strWrapper });
		action.setCallback(this, function (response) {
			this.handleServeRecordResponse(cmp, response);
		});
		$A.enqueueAction(action);
	},

	handleServeRecordResponse: function (cmp, response) {
		var state = response.getState();
		if (state === "SUCCESS") {
			this.handleSuccess(cmp, response);
		} else if (state === "INCOMPLETE") {
			// do something
			cmp.set("v.isLoading", false);
		} else if (state === "ERROR") {
			cmp.set("v.isLoading", false);
			var errors = response.getError();
			if (errors) {
				if (errors[0] && errors[0].message) {
					console.log("Error message: " + errors[0].message);
					let errorToast = $A.get("e.force:showToast");
					errorToast.setParams({
						title: "System Error",
						message: " Reason: " + errors[0].message,
						type: "error"
					});
					errorToast.fire();
				}
			} else {
				console.log("Unknown error");
			}
		}
	},

	handleSuccess: function (cmp, response) {
		let source = cmp.get("v.strSource");
		// if success, show toast and open record in new tab
		let result = JSON.parse(response.getReturnValue());
		if (result.blnSuccess) {
			// if the record is not found, and intExecutiiionNumber is not empty, we need to batching
			if (result.objRecord === null && result.intExecutionNumber !== undefined) {
				result.intExecutionNumber = result.intExecutionNumber + 1;
				this.handleServeRecord(cmp, JSON.stringify(result));
			} else {
				if (result.objRecord.Id) {
					// insert record Id along with notification
					// based on record prefix, determine if it's a lead or opportunity
					let prefix = "a";
					if (
						result.strRecordType.startsWith("A") ||
						result.strRecordType.startsWith("E") ||
						result.strRecordType.startsWith("I") ||
						result.strRecordType.startsWith("O") ||
						result.strRecordType.startsWith("U")
					) {
						prefix = "an";
					}
					var toastEvent = $A.get("e.force:showToast");
					toastEvent.setParams({
						type: "success",
						mode: "dismissible",
						duration: 5000,
						message: "This is a required message",
						messageTemplate: "We found you " + prefix + " " + result.strRecordType + " ({0}) !",
						messageTemplateData: [
							{
								url: result.strBaseURL + "/" + result.objRecord.Id,
								label: result.strRecordName
							}
						]
					});
					toastEvent.fire();

					if (result.strWarningMessage) {
						var warningEvent = $A.get("e.force:showToast");
						warningEvent.setParams({
							type: "warning",
							mode: "dismissible",
							"title": "Please contact admin",
							"message": result.strWarningMessage
						});
						warningEvent.fire();
					}
	
					var workspaceAPI = cmp.find("workspace");
					let strURL = "/lightning/r/ " + result.strRecordType + "/" + result.objRecord.Id + "/view";
					workspaceAPI
						.openTab({
							url: strURL,
							focus: true
						})
						.then(function (response) {})
						.catch(function (error) {
							console.log(error);
						});
					// reset retry attempt
					cmp.set("v.intRetryAttempt", 1);
					// if the source is quick action - fire event to close quick action
					if (source == "quickAction") {
						var dismissActionPanel = $A.get("e.force:closeQuickAction");
						dismissActionPanel.fire();
					}
					cmp.set("v.isLoading", false);
				}
			}
		} else {
			// if its exception, check if its a lock error
			if (result.blnException) {
				var errorEvent = $A.get("e.force:showToast");
				if (result.strMessage) {
					// if its a lock error, retry 3 times
					if (result.strMessage.includes("unable to obtain exclusive access")) {
						let retryAttempt = cmp.get("v.intRetryAttempt");

						// if retry attempt is more than 3, show error toast and close quick action
						if (retryAttempt > 3) {
							errorEvent.setParams({
								title: "All 3 retry attempts have failed. Please contact your administrator.",
								message: " ",
								type: "error"
							});
							errorEvent.fire();
							cmp.set("v.intRetryAttempt", 1);

							if (source == "quickAction") {
								var dismissActionPanel = $A.get("e.force:closeQuickAction");
								dismissActionPanel.fire();
							}
							cmp.set("v.isLoading", false);
						} else {
							// show warning toast and retry after 5 seconds
							errorEvent.setParams({
								title: "The record you are trying to update is locked by another user. Retrying in 5 seconds... (Attempt " + retryAttempt + ")",
								message: " ",
								type: "warning"
							});
							errorEvent.fire();

							window.setTimeout(function () {
								retryAttempt = retryAttempt + 1;
								cmp.set("v.intRetryAttempt", retryAttempt);
								var functionCall = cmp.get("c.handlePlay");
								$A.enqueueAction(functionCall);
							}, 5000);
						}
					} else {
						// if its not a lock error, show error toast and close quick action
						errorEvent.setParams({
							title: "System Error - " + result.strExceptionType,
							message: result.strMessage,
							type: "error"
						});
						errorEvent.fire();

						if (source == "quickAction") {
							var dismissActionPanel = $A.get("e.force:closeQuickAction");
							dismissActionPanel.fire();
						}
						cmp.set("v.isLoading", false);
					}
				}
			} else {
				// if not exception or error, show warning toast and close quick action
				var warningEvent = $A.get("e.force:showToast");
				warningEvent.setParams({
					title: result.strMessage,
					message: " ",
					type: "warning"
				});
				warningEvent.fire();

				if (source == "quickAction") {
					var dismissActionPanel = $A.get("e.force:closeQuickAction");
					dismissActionPanel.fire();
				}
				cmp.set("v.isLoading", false);
			}
		}
		
	}
})