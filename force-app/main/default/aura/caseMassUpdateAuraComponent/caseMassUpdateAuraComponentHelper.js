({
	fetchCaseDetails: function (cmp, caseIdList) {
		cmp.set("v.isLoading", true);
		var action = cmp.get("c.fetchRelatedCases");
		action.setParams({ caseIdList: caseIdList });
		action.setCallback(this, function (response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				let result = response.getReturnValue();
				let data = [];
				result.forEach((element) => {
					let eachElement = {
						URL: "/" + element["Id"],
						CaseNumber: element.CaseNumber,
						recordTypeName: element.RecordType.Name,
						subject: element.Subject,
						ownerName: element.Owner.Name,
						Type: element.Type,
						Origin: element.Origin
					};
					eachElement.accountName = element.Account ? element.Account.Name : "";
					eachElement.contactName = element.Contact ? element.Contact.Name : "";
					data.push(eachElement);
				});

				cmp.set("v.columns", [
					{
						label: "Case Number",
						fieldName: "URL",
						type: "url",
						typeAttributes: {
							label: {
								fieldName: "CaseNumber"
							},
							target: "_self"
						},
						sortable: true
					},
					{ label: "Record Type", fieldName: "recordTypeName", type: "text" },
					{ label: "Account", fieldName: "accountName", type: "text" },
					{ label: "Contact", fieldName: "contactName", type: "text" },
					{
						label: "Subject",
						fieldName: "URL",
						type: "url",
						typeAttributes: {
							label: {
								fieldName: "subject"
							},
							tooltip: { fieldName: "subject" },
							target: "_self"
						},
						sortable: true
					},

					{ label: "Owner Name", fieldName: "ownerName", type: "text" },
					{ label: "Type", fieldName: "Type", type: "text" },
					{ label: "Origin", fieldName: "Origin", type: "text" }
				]);
				cmp.set("v.data", data);
			}
			cmp.set("v.isLoading", false);
		});
		$A.enqueueAction(action);
	},

	checkEligibility: function (cmp, caseIdList) {
		cmp.set("v.isLoading", true);
		var action = cmp.get("c.checkMassUpdateEligibility");
		action.setParams({ caseId: caseIdList[caseIdList.length - 1] });
		action.setCallback(this, function (response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				let result = response.getReturnValue();
				if (result.isSuccess) {
					cmp.set("v.isError", false);
					if (!result.isEligible) {
						cmp.set("v.isError", true);
						cmp.set("v.errorMessage", result.errorMessage);
					} else {
						cmp.set("v.selectedRecordType", result.selectedRecordType);
						if (result.selectedRecordType === "MF Termination" || result.selectedRecordType === "MF Member/Group Updates" || result.selectedRecordType === "MF NHE") {
							cmp.set("v.strChatterText", "Mass updated. Reason:");
							cmp.set("v.blnIsMFRTCase", true);
						}
						let caseRecordTypeList = [];
						result.caseRecordTypeList.forEach((eachRecordType) => {
							caseRecordTypeList.push({
								label: eachRecordType,
								value: eachRecordType
							});
						});
						cmp.set("v.caseRecordTypeList", caseRecordTypeList);
						this.loadFieldList(cmp);
					}
				} else {
					cmp.set("v.isError", true);
				}
			}
			cmp.set("v.isLoading", false);
		});
		$A.enqueueAction(action);
	},

	loadFieldList: function (cmp) {
		cmp.set("v.isLoading", true);
		var action = cmp.get("c.returnFieldNameAPIList");
		action.setParams({ selectedRecordType: cmp.get("v.selectedRecordType") });
		action.setCallback(this, function (response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				let result = response.getReturnValue();
				cmp.set("v.fieldsApiNameList", result.fieldSetWrapper);
				cmp.set("v.recordTypeId", result.recordTypeId);
				let caseReasonList = [];
				let caseReasonListLabels = [];
				result.caseReasons.forEach((eachCaseReason) => {
					caseReasonList.push({
						label: eachCaseReason,
						value: eachCaseReason
					});
					caseReasonListLabels.push(eachCaseReason);
				});

				let largeScaleIssueList = [];
				result.lsiList.forEach((eachLargeScaleIssue) => {
					largeScaleIssueList.push({
						label: eachLargeScaleIssue,
						value: eachLargeScaleIssue
					});
				});
				cmp.set("v.caseReasonList", caseReasonList);
				cmp.set("v.caseReasonListLabels", caseReasonListLabels);
				cmp.set("v.masterCaseReasonListLabels", caseReasonListLabels);
				cmp.set("v.largeScaleIssueList", largeScaleIssueList);
				cmp.set("v.isOwnerIdAvailable", result.isOwnerIdAvailable);
				if (!result.isOwnerIdAvailable) {
					var cmpTarget = cmp.find("ownerIdClass");
					$A.util.addClass(cmpTarget, "hidden");
				} else {
					var cmpTarget = cmp.find("ownerIdClass");
					$A.util.removeClass(cmpTarget, "hidden");
				}

				cmp.set("v.headerMessge", "The following records are going to be mass updated to <b>" + cmp.get("v.selectedRecordType") + " </b> record type");

				let caseToUpdate = { sobjectType: "Case" };
				cmp.set("v.toUpdateCase", caseToUpdate);
			}
			cmp.set("v.isLoading", false);
		});
		$A.enqueueAction(action);
	},

	massUpdate: function (cmp, event, isUpdateAndRoute) {
		cmp.set("v.isLoading", true);
		var action = cmp.get("c.massUpdateAndRouteCase");
		let caseObj = cmp.get("v.toUpdateCase");
		caseObj.RecordTypeId = cmp.get("v.recordTypeId");
		console.log("--case--" + JSON.stringify(caseObj));
		let propertyList = [];
		for (let property in caseObj) {
			console.log("---caseObj--" + JSON.stringify(caseObj));
			// Trying to ignore invalid sObject Attributes
			if (property !== "sobjectType" && property !== "Owner") {
				propertyList.push(property);
			}
			if (Array.isArray(caseObj[property])) {
				caseObj[property] = caseObj[property].toString();
			}
		}

		let objVar;
		if (cmp.find("caseOwner")) {
			objVar = cmp.find("caseOwner").get("v.value");
		}

		action.setParams({
			caseToUpdate: caseObj,
			isMassUpdateAndRoute: isUpdateAndRoute,
			attributeList: propertyList,
			caseIdList: cmp.get("v.caseIdList"),
			blnPostFeed: cmp.get("v.blnPostFeed"),
			strChatterText: cmp.get("v.strChatterText"),
			strOwnerId: objVar,
			strOwnerType: cmp.get("v.selectedOwnerType"),
			strStatus: cmp.get("v.selectedStatus"),
			strAssignmentType: cmp.get("v.selectedAssignmentType"),
			blnIsMFRecordTypeCase: cmp.get("v.blnIsMFRTCase")
		});
		action.setCallback(this, function (response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				let result = response.getReturnValue();
				if (result.isSuccess) {
					sforce.one.showToast({
						title: "Records have been mass updated to " + cmp.get("v.selectedRecordType") + " record type",
						message: " ",
						type: "success"
					});
					window.history.back();
				} else {
					sforce.one.showToast({
						title: "Mass update failed. Please try again later",
						message: "Reason: " + result.errorMessage,
						type: "error",
						mode: "sticky"
					});
					window.history.back();
				}
			}
			cmp.set("v.isLoading", false);
		});
		$A.enqueueAction(action);
	},

	populateOwnerTypes: function (cmp) {
		let caseOwnerTypeList = [];
		caseOwnerTypeList.push({
			label: cmp.get("v.strAccountSpecialist"),
			value: cmp.get("v.strAccountSpecialist")
		});
		caseOwnerTypeList.push({
			label: cmp.get("v.strMassUpdate"),
			value: cmp.get("v.strMassUpdate")
		});
		cmp.set("v.taxResOwnerTypeList", caseOwnerTypeList);

		//Populate Assignement Type list
		cmp.set("v.blnDisplayAssignmentType", true);
		let selectedOwnerType = cmp.get("v.selectedOwnerType");

		cmp.set("v.selectedAssignmentType", "");
		let assignmentList = [];
		assignmentList.push({
			label: "Round Robin IC Assignment",
			value: cmp.get("v.strRoundRobin")
		});
		assignmentList.push({
			label: "Direct IC assignment",
			value: cmp.get("v.strIcAssignment")
		});

		cmp.set("v.blnDisplayAssignmentType", true);
		cmp.set("v.blnDisplayTaxResStatus", false);
		cmp.set("v.blnDisplayTaxResOwner", false);
		cmp.set("v.taxResAssignmentTypeList", assignmentList);
		cmp.set("v.selectedStatus", cmp.get("v.strReadyForResearch"));
	},

	populateStatusList: function (cmp) {
		let selectedOwnerType = cmp.get("v.selectedOwnerType");
		let selectedAssignmentType1 = "";
		selectedAssignmentType1 = cmp.get("v.selectedAssignmentType");
		let statusList = [];
		cmp.set("v.blnDisplayTaxResStatus", false);
		cmp.set("v.blnDisplayTaxResOwner", false);

		if (selectedAssignmentType1 && selectedAssignmentType1 === cmp.get("v.strIcAssignment")) {
			cmp.set("v.blnDisplayTaxResOwner", true);
		}

		if (selectedAssignmentType1 && (selectedAssignmentType1 === cmp.get("v.strIcAssignment") || selectedAssignmentType1 === cmp.get("v.strRoundRobin"))) {
			cmp.set("v.selectedOwnerType", cmp.get("v.strAccountSpecialist"));
			statusList.push({
				label: cmp.get("v.strReadyForResearch"),
				value: cmp.get("v.strReadyForResearch")
			});
			cmp.set("v.selectedStatus", cmp.get("v.strReadyForResearch"));
		}

		cmp.set("v.taxResStatusList", statusList);

		if (statusList.length > 0) {
			cmp.set("v.blnDisplayTaxResStatus", true);
		} else {
			cmp.set("v.blnDisplayTaxResStatus", false);
		}
	}
});