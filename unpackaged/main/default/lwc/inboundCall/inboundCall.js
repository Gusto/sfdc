import getOpportunities from "@salesforce/apex/InboundCallController.getOpportunities";
import searchContact from "@salesforce/apex/InboundCallController.searchContact";
import querySalesInteraction from "@salesforce/apex/InboundCallController.querySalesInteraction";
import searchLead from "@salesforce/apex/InboundCallController.searchLead";
import getCases from "@salesforce/apex/InboundCallController.getCases";
import upsertTask from "@salesforce/apex/InboundCallController.upsertTask";
import TASK_OBJECT from "@salesforce/schema/Task";
import SUBJECT_FIELD from "@salesforce/schema/Task.Subject";
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { api, LightningElement, track, wire } from "lwc";
import { getPicklistValuesByRecordType } from "lightning/uiObjectInfoApi";
import InboundCallTaskRecordTypeId from "@salesforce/label/c.InboundCallTaskRecordTypeId";
import clickToCallDNIS from "@salesforce/label/c.Click_to_Call_DNIS";
import disableInboundCallProfile from "@salesforce/label/c.Disable_Inbound_Call_Profile";
import disableInboundCallNumber from "@salesforce/label/c.Disabled_Inbound_Call_Number";
// get logged in user profile
import { getRecord } from "lightning/uiRecordApi";
import Id from "@salesforce/user/Id";
import ProfileName from "@salesforce/schema/User.Profile.Name";

import getAppUrlMaps from "@salesforce/apex/InboundCallController.getAppUrlMaps";

import { displayToast, TOAST_PARAMS, checkInputValidity, PicklistOption } from "c/utilityService";

import * as routeUtil from "c/salesCaseViewLwcCmp";

import * as util from "./inboundCallUtil.js";

export default class InboundCall extends NavigationMixin(LightningElement) {
	taskObject = TASK_OBJECT;
	taskFields = [SUBJECT_FIELD];

	@track error;
	@track allSelectedRows = [];
	@track interactionFound = true;
	@track errorMessage = "Unable to find sales interaction. please contact administrator.";

	ani;
	dnis;
	callConversationId;
	@api phone;

	@api recordId;
	@api objectApiName;
	@track searchObj = {
		strFirstName: "",
		strLastName: "",
		strAccountName: "",
		strPhone: "",
		strEmail: ""
	};
	@track contactId;
	@track accountId;
	@track blnSpinner;
	@track isContactRecordsFound = false;
	@track contactData;

	@track isLeadRecordsFound = false;
	@track leadData;
	leadDataValues = [];
	@api leadSourceDetailValue;
	@api leadSourceValue;

	@track isOppRecordsFound = false;
	@track opportunitiesData;

	@track isCaseRecordsFound = false;
	@track casesData;

	@api taskObj = { sobjectType: "Task" };

	strCaseType = "";
	blnRerender = false;

	contactReasonValues;
	subcontactReasonValues;
	selectedContactReasonValue = "";
	picklistValuesObj;
	selectedSubContactReasonValue = "";
	loggedInUserProfile = "";

	get list_CaseTypeOptions() {
		return routeUtil.list_CaseTypeOptions;
	}

	get blnShowCaseType() {
		const strPrimaryCallReason = this.taskObj?.Primary_Call_Reason__c;
		const strSecondaryCallReason = this.taskObj?.Secondary_Call_Reason__c;

		return (
			strPrimaryCallReason === util.CONTACT_REASON_TRANSFER &&
			(!strSecondaryCallReason || (strSecondaryCallReason !== util.SUB_CONTACT_REASON_BAD_TRANSFER && strSecondaryCallReason !== util.SUB_CONTACT_REASON_TRANSFER_TO_CARE))
		);
	}

	get blnShowLearnedAboutGusto() {
		return this.taskObj?.Primary_Call_Reason__c === util.CONTACT_REASON_SALES && this.taskObj?.Secondary_Call_Reason__c;
	}

	get blnShowReferredBy() {
		return this.blnShowLearnedAboutGusto;
	}

	get intCommentsLayoutItemSize() {
		return 12;
	}

	get blnIsSecCallReasonDisabled() {
		return !this.taskObj?.Primary_Call_Reason__c;
	}

	get list_ContactReasonOptions() {
		const list_ContactReasonValues = this.picklistValuesObj?.Primary_Call_Reason__c?.values;
		const list_Options = [new PicklistOption("--None--", "")];

		//Iterate the picklist values for the primary reason field
		list_ContactReasonValues?.forEach((objPicklist) => {
			list_Options.push(new PicklistOption(objPicklist.label, objPicklist.value));
		});

		this.setSubcontactReasonValues(this.taskObj?.Primary_Call_Reason__c);

		return list_Options;
	}

	@wire(CurrentPageReference)
	currentPageReference;

	// method to get Picklist values based on record type and dependant values too
	@wire(getPicklistValuesByRecordType, { objectApiName: "Task", recordTypeId: InboundCallTaskRecordTypeId })
	newPicklistValues({ error, data }) {
		if (data) {
			this.error = null;
			this.picklistValuesObj = data.picklistFieldValues;
		} else if (error) {
			this.error = JSON.stringify(error);
		}
	}

	// wire method to get logged in user profile
	@wire(getRecord, { recordId: Id, fields: [ProfileName] })
	userDetails({ error, data }) {
		if (error) {
		} else if (data) {
			if (data.fields.Profile.value) {
				this.loggedInUserProfile = data.fields.Profile.value.fields.Name.value;
			}
		}
	}

	setSubcontactReasonValues(selectedContactReasonValue) {
		const list_Options = [{ label: "--None--", value: "" }];

		if (selectedContactReasonValue) {
			const list_TotalSubContactReasonValues = this.picklistValuesObj?.Secondary_Call_Reason__c;
			// Getting the index of the controlling value as the single value can be dependant on multiple controller value
			const intControllerValueIndex = list_TotalSubContactReasonValues?.controllerValues[selectedContactReasonValue];
			const list_SubContactReasonPicklistValues = this.picklistValuesObj?.Secondary_Call_Reason__c.values;

			if (intControllerValueIndex !== null && intControllerValueIndex !== undefined) {
				//Iterate the picklist values for the secondary reason field
				list_SubContactReasonPicklistValues?.forEach((key) => {
					for (let i = 0; i < key.validFor.length; i++) {
						if (intControllerValueIndex === key.validFor[i]) {
							list_Options.push(new PicklistOption(key.label, key.value));
						}
					}
				});
			}
		}

		this.subcontactReasonValues = list_Options;
	}

	// get App URL Maps:
	@wire(getAppUrlMaps)
	list_AppUrlMaps;

	handleContactReasonChange(event) {
		this.taskObj.Primary_Call_Reason__c = event.detail.value;
		this.blnRerender = !this.blnRerender;
		this.taskObj.Secondary_Call_Reason__c = "";

		if (!this.taskObj.Id && event.detail.value === util.CONTACT_REASON_TRANSFER) {
			displayToast(this, util.ERROR_MSG_SAVE_TASK_PRIOR_TO_TRANSFER, "", TOAST_PARAMS.TYPE.ERROR, "");
		}
		this.selectedContactReasonValue = event.detail.value;

		this.setSubcontactReasonValues(this.selectedContactReasonValue);
	}

	handleSubContactReasonChange(event) {
		this.taskObj.Secondary_Call_Reason__c = event.detail.value;
		this.selectedSubContactReasonValue = event.detail.value;
		this.blnSpinner = true;

		if (!this.blnShowCaseType) {
			this.strCaseType = "";
		}

		if (this.selectedSubContactReasonValue === util.SUB_CONTACT_REASON_BAD_TRANSFER) {
			// Search Case
			getCases({ strPhone: this.phone })
				.then((result) => {
					// set @track contacts variable with return contact list from server
					this.casesData = result;
					if (result && result.length > 0) {
						this.isCaseRecordsFound = true;
					}
					let tempRecords = JSON.parse(JSON.stringify(result));
					tempRecords = tempRecords.map((row) => {
						var companyName = " ",
							contactName = " ",
							recordtypeName = " ";
						if (row && row.Account && row.Account.Name) {
							companyName = row.Account.Name;
						} else {
							companyName = " ";
						}
						if (row && row.Contact && row.Contact.Name) {
							contactName = row.Contact.Name;
						} else {
							contactName = " ";
						}
						if (row && row.RecordTypeId && row.RecordType.Name) {
							recordtypeName = row.RecordType.Name;
						} else {
							recordtypeName = " ";
						}
						return { ...row, Company: companyName, Contact: contactName, recordtypeName: recordtypeName };
					});
					this.casesData = tempRecords;
					this.blnSpinner = false;
				})
				.catch((error) => {
					const objEvent = new ShowToastEvent({
						title: "Error",
						variant: "error",
						message: error.body.message
					});
					this.dispatchEvent(objEvent);
					// reset contacts var with null
					this.casesData = null;
					this.isCaseRecordsFound = false;
					this.blnSpinner = false;
				});
		} else {
			this.casesData = null;
			this.isCaseRecordsFound = false;
			this.blnSpinner = false;
		}
	}

	connectedCallback() {
		this.blnSpinner = true;
		querySalesInteraction({ idRecord: this.recordId })
			.then((result) => {
				if (result) {
					this.interactionFound = true;

					this.ani = result.ANI__c;
					this.dnis = result.DNIS__c;

					if (this.ani) {
						this.phone = this.ani.slice(-10);
					}
					// pre-populate Phone Number field
					this.callConversationId = result.CCID__c;

					if (!this.ani || !this.dnis || !this.callConversationId) {
						this.interactionFound = false;
						this.errorMessage = "Missing Required Information (ANI, DNIS and CCID). please contact administrator.";
						return;
					}

					// set title of the tab
					this.setTabTitle();
					// apply search
					this.handleSearchKeyword(true);
					this.upsertTaskObj();
					this.contactColumns = util.contactColumns;
					this.leadColumns = util.leadColumns;
					this.opportunityColumns = util.opportunityColumns;
					this.caseColumns = util.caseColumns;
					this.saveMsg = "";
				} else {
					this.interactionFound = false;
					this.errorMessage = "Unable to find sales interaction. please contact administrator.";
					this.disableTabClose(false);
				}
			})
			.catch((error) => {
				this.blnSpinner = false;
				this.interactionFound = false;
				this.errorMessage = "Unable to find sales interaction. please contact administrator.";
				this.disableTabClose(false);
			});
	}

	setTabTitle() {
		this.invokeWorkspaceAPI("isConsoleNavigation").then((isConsole) => {
			if (isConsole) {
				this.invokeWorkspaceAPI("getAllTabInfo").then((allTabInfo) => {
					if (allTabInfo) {
						let allTabInfoLength = allTabInfo.length - 1;
						for (let ii = allTabInfoLength; ii >= 0; ii--) {
							if (allTabInfo[ii].recordId == this.recordId) {
								this.invokeWorkspaceAPI("setTabLabel", {
									tabId: allTabInfo[ii].tabId,
									label: `Inbound Call (${this.phone})`
								}).then((tabId) => {});
								this.invokeWorkspaceAPI("setTabIcon", {
									tabId: allTabInfo[ii].tabId,
									icon: "utility:incoming_call",
									iconAlt: "Call"
								}).then((tabId) => {});
								break;
							}
						}
					}
				});
			}
		});
	}

	upsertTaskObj() {
		if (!this.taskObj.Id && this.taskObj?.Primary_Call_Reason__c === util.CONTACT_REASON_TRANSFER) {
			displayToast(this, util.ERROR_MSG_SAVE_TASK_PRIOR_TO_TRANSFER, "", TOAST_PARAMS.TYPE.ERROR, "");
			return;
		}

		let taskObj = this.taskObj;
		taskObj.CallObject = this.callConversationId;
		taskObj.Genesys_Ani__c = this.ani;
		taskObj.Genesys_Interaction_Id__c = this.callConversationId;
		taskObj.Genesys_Called_Number__c = this.dnis;
		taskObj.Phone = this.phone;

		upsertTask({ objTask: taskObj, strPhone: this.phone, strleadSourceValue: this.leadSourceValue, strLeadSourceDetailValue: this.leadSourceDetailValue })
			.then((result) => {
				this.blnSpinner = false;
				// set @track contacts variable with return contact list from server
				this.taskObj = result;
				let blnWhoIdFound = false;
				let blnWhatIdFound = false;

				if (this.taskObj.WhoId) {
					blnWhoIdFound = true;

					// if who id is a lead, then what id is not required
					if (this.taskObj.WhoId.startsWith("00Q")) {
						blnWhatIdFound = true;
					}
					let WhoIdlookUp = this.template.querySelector(".WhoId");
					if (WhoIdlookUp) {
						WhoIdlookUp.setSelectedRecId(this.taskObj.WhoId, false);
					}
				}

				if (this.taskObj.WhatId) {
					blnWhatIdFound = true;

					// if what id is a case, then who id is not required
					if (this.taskObj.WhatId.startsWith("500")) {
						blnWhoIdFound = true;
					}

					let WhatIdlookUp = this.template.querySelector(".WhatId");
					if (WhatIdlookUp) {
						WhatIdlookUp.setSelectedRecId(this.taskObj.WhatId, false);
					}
				}

				if ((blnWhoIdFound && blnWhatIdFound) || (!this.isContactRecordsFound && !this.isLeadRecordsFound)) {
					// don't disable tabs if activity is linked to both who id and what id
					// or if both contacts and leads are not found - allow them to close the tab
					this.disableTabClose(false);
				} else {
					// if activity is not linked to what id or who id - disable tab close
					this.disableTabClose(true);
				}
			})
			.catch((error) => {
				const event = new ShowToastEvent({
					title: "Error",
					variant: "error",
					message: error.body.message
				});
				this.dispatchEvent(event);
				// reset contacts var with null
				this.opportunitiesData = null;
				this.isOppRecordsFound = false;
				this.blnSpinner = false;
				this.disableTabClose(false);
			});
	}

	getOpportunitiesBasedOnSelectIdAccountId(accountId) {
		this.blnSpinner = true;
		getOpportunities({ strAccountId: accountId })
			.then((result) => {
				this.opportunitiesData = result;
				if (result && result.length > 0) {
					let tempRecords = JSON.parse(JSON.stringify(result));
					tempRecords = tempRecords.map((row) => {
						var OwnerName = "";
						var AccountZP_Company_Overall_Status__c = "";
						var AccountBillingState = "";
						var AccountAnchor_Pay_Date__c = "";
						var AccountLink_Company__c = "";
						var AccountJoined_Date_Panda__c = "";
						var AccountRFI_Page__c = "";
						var ReferredByName = "";
						var SoldByName = "";
						if (row && row.Account) {
							if (row.Account.RecordType && row.Account.RecordType.Name === "Company") {
								OwnerName = row.Account.Owner.Name;
							} else if (row.Account.RecordType && row.Account.RecordType.Name === "Reseller") {
								OwnerName = row.Account.Owner.Name;
							}

							if (row.Account.ZP_Company_Overall_Status__c) {
								AccountZP_Company_Overall_Status__c = row.Account.ZP_Company_Overall_Status__c;
							}

							if (row.Account.BillingState) {
								AccountBillingState = row.Account.BillingState;
							}
							if (row.Account.Anchor_Pay_Date__c) {
								AccountAnchor_Pay_Date__c = row.Account.Anchor_Pay_Date__c;
							}
							if (row.Account.Joined_Date_Panda__c) {
								AccountJoined_Date_Panda__c = row.Account.Joined_Date_Panda__c;
							}

							if (row.Account?.Link_Company__c && row.Account?.ZP_Company_ID__c && this.list_AppUrlMaps?.data?.length && this.list_AppUrlMaps.data[0].URL__c) {
								AccountLink_Company__c = this.list_AppUrlMaps.data[0].URL__c + util.PANDA_URL_PREFIX_COMPANY + row.Account.ZP_Company_ID__c;
							}

							if (row.Account.RFI_Page__c && row.Account.ZP_Company_ID__c) {
								AccountRFI_Page__c = this.list_AppUrlMaps.data[0].URL__c + util.PANDA_URL_PREFIX_COMPANY + row.Account.ZP_Company_ID__c + "/information_requests";
							}

							if (row.Sold_By__c && row.Sold_By__r.Name) {
								SoldByName = row.Sold_By__r.Name;
								row.Sold_By__c = "/" + row.Sold_By__c;
							}

							row.OpportunityId = "/" + row.Id;

							if (row.Referred_By__c && row.Referred_By__r.Name) {
								ReferredByName = row.Referred_By__r.Name;
								row.Referred_By__c = "/" + row.Referred_By__c;
							}
						}

						return {
							...row,
							OwnerName: OwnerName,
							AccountZP_Company_Overall_Status__c: AccountZP_Company_Overall_Status__c,
							AccountBillingState: AccountBillingState,
							AccountJoined_Date_Panda__c: AccountJoined_Date_Panda__c,
							AccountAnchor_Pay_Date__c: AccountAnchor_Pay_Date__c,
							AccountLink_Company__c: AccountLink_Company__c,
							AccountRFI_Page__c: AccountRFI_Page__c,
							SoldByName: SoldByName,
							ReferredByName: ReferredByName
						};
					});

					this.opportunitiesData = tempRecords;
					this.isOppRecordsFound = true;
				}
				this.blnSpinner = false;
			})
			.catch((error) => {
				console.log("error ", error);
				const event = new ShowToastEvent({
					title: "Error",
					variant: "error",
					message: error.body.message
				});
				this.dispatchEvent(event);
				// reset contacts var with null
				this.opportunitiesData = null;
				this.isOppRecordsFound = false;
				this.blnSpinner = false;
			});
	}

	handleSelectedRec(event) {
		if (!event.detail.value.rowRecordId) {
			this.invokeWorkspaceAPI("isConsoleNavigation").then((isConsole) => {
				if (isConsole) {
					this.invokeWorkspaceAPI("getFocusedTabInfo").then((focusedTab) => {
						this.invokeWorkspaceAPI("openSubtab", {
							parentTabId: focusedTab.tabId,
							recordId: event.detail.value.objRecordId,
							focus: true
						}).then((tabId) => {});
					});
				}
			});
		} else {
			this.contactId = event.detail.value.rowRecordId;
			this.accountId = event.detail.value.objRecordId;
			if (this.accountId) {
				this.getOpportunitiesBasedOnSelectIdAccountId(event.detail.value.objRecordId);
			} else {
				const objEvent = new ShowToastEvent({
					title: "Warning",
					variant: "warning",
					message: "no record found"
				});
				this.dispatchEvent(objEvent);
			}
		}
	}

	// update searchValue var when input field value change
	searchKeyword(event) {
		this.searchObj = JSON.parse(JSON.stringify(this.searchObj));
		this.searchObj[event.target.name] = event.target.value;
	}

	handleEnter(event) {
		if (event.keyCode === 13) {
			this.handleSearchKeyword(false);
		}
	}

	handleSearchKeywordClick() {
		this.handleSearchKeyword(false);
	}

	// call apex method on button click
	handleSearchKeyword(doInit) {
		this.isContactRecordsFound = false;
		this.isLeadRecordsFound = false;
		let objSearch = {
			strFirstName: "",
			strLastName: "",
			strAccountName: "",
			strPhone: "",
			strEmail: ""
		};
		if (doInit) {
			objSearch.strPhone = this.phone;
		} else {
			objSearch = this.searchObj;
		}

		searchContact(objSearch)
			.then((result) => {
				// set @track contacts variable with return contact list from server
				let tempRecords = JSON.parse(JSON.stringify(result));
				tempRecords = tempRecords.map((row) => {
					var companyName = " ";
					if (row && row.Account && row.Account.Name) {
						companyName = row.Account.Name;
					} else {
						companyName = " ";
					}
					row.ContactId = "/" + row.Id;
					return { ...row, Company: companyName };
				});
				this.contactData = tempRecords;
				if (result && result.length > 0) {
					this.isContactRecordsFound = true;
				}
			})
			.catch((error) => {
				const event = new ShowToastEvent({
					title: "Error",
					variant: "error",
					message: error.body.message
				});
				this.dispatchEvent(event);
				// reset contacts var with null
				this.contactData = null;
				this.isContactRecordsFound = false;
				this.blnSpinner = false;
			});

		// Search Lead
		searchLead(objSearch)
			.then((result) => {
				// set @track contacts variable with return contact list from server
				this.leadData = result;
				this.leadDataValues = result;
				if (result && result.length > 0) {
					this.isLeadRecordsFound = true;
				}
			})
			.catch((error) => {
				const event = new ShowToastEvent({
					title: "Error",
					variant: "error",
					message: error.body.message
				});
				this.dispatchEvent(event);
				// reset contacts var with null
				this.leadData = null;
				this.isLeadRecordsFound = false;
				this.blnSpinner = false;
			});
	}

	navigateToNewLead() {
		var defaultFieldValues = `Normalized_Phone__c=${this.phone},Normalized_Alternate_Phone__c=${this.phone}, Normalized_Mobile_Phone__c=${this.phone},Phone=${this.phone},Secondary_Phone__c=${this.phone}`;

		// check dnis
		if (this.dnis && clickToCallDNIS && clickToCallDNIS.includes(this.dnis)) {
			let strLeadSourceDetail = "";
			let strLeadSource = "";

			if (this.dnis == "4159079375") {
				strLeadSourceDetail = "FY24 New Biz Control";
				strLeadSource = "Direct Mail";
			} else if (this.dnis == "4159079377") {
				strLeadSourceDetail = "FY24 Growing Biz Control";
				strLeadSource = "Direct Mail";
			} else if (this.dnis == "7207808402") {
				strLeadSourceDetail = "FY24 New Biz New";
				strLeadSource = "Direct Mail";
			} else if (this.dnis == "6504884278") {
				strLeadSourceDetail = "FY24 Growing Biz New";
				strLeadSource = "Direct Mail";
			} else if (this.dnis == "9253222799") {
				strLeadSourceDetail = "FY24 New Biz CTA";
				strLeadSource = "Direct Mail";
			} else if (this.dnis == "8009522342") {
				strLeadSourceDetail = "FY24 Growing Biz CTA";
				strLeadSource = "Direct Mail";
			} else if (this.dnis == "4159077035") {
				strLeadSourceDetail = "CLM Ongoing Nurtures";
				strLeadSource = "Email";
			} else if (this.dnis == "4159077003") {
				strLeadSourceDetail = "CLM Experiment Emails";
				strLeadSource = "Email";
			}

			defaultFieldValues = ",LeadSource=" + strLeadSource + ",Lead_Source_Detail__c=" + strLeadSourceDetail;
		}

		this.userDetailNavigateRef = {
			type: "standard__objectPage",
			attributes: {
				objectApiName: "Lead",
				actionName: "new"
			},
			state: {
				defaultFieldValues: defaultFieldValues,
				count: "1",
				nooverride: "1",
				useRecordTypeCheck: "1",
				navigationLocation: "RELATED_LIST"
			}
		};

		this[NavigationMixin.Navigate](this.userDetailNavigateRef);
	}
	navigateToNewOpportunity() {
		var defaultFieldValues = `accountId=${this.accountId}`;
		this.userDetailNavigateRef = {
			type: "standard__objectPage",
			attributes: {
				objectApiName: "Opportunity",
				actionName: "new"
			},
			state: {
				defaultFieldValues: defaultFieldValues,
				count: "1",
				nooverride: "1",
				useRecordTypeCheck: "1",
				navigationLocation: "RELATED_LIST"
			}
		};

		this[NavigationMixin.Navigate](this.userDetailNavigateRef);
	}
	navigateToNewContact() {
		var defaultFieldValues = `ZP_Phone__c=${this.phone},Phone=${this.phone}, Mobile=${this.phone},OtherPhone=${this.phone}`;

		this.userDetailNavigateRef = {
			type: "standard__objectPage",
			attributes: {
				objectApiName: "Contact",
				actionName: "new"
			},
			state: {
				defaultFieldValues: defaultFieldValues,
				count: "1",
				nooverride: "1",
				useRecordTypeCheck: "1",
				navigationLocation: "RELATED_LIST"
			}
		};

		this[NavigationMixin.Navigate](this.userDetailNavigateRef);
	}

	invokeWorkspaceAPI(methodName, methodArgs) {
		return new Promise((resolve, reject) => {
			const apiEvent = new CustomEvent("internalapievent", {
				bubbles: true,
				composed: true,
				cancelable: false,
				detail: {
					category: "workspaceAPI",
					methodName: methodName,
					methodArgs: methodArgs,
					callback: (err, response) => {
						if (err) {
							return reject(err);
						}
						return resolve(response);
					}
				}
			});

			window.dispatchEvent(apiEvent);
		});
	}
	handleRowAction(event) {
		const dataRow = event.detail.row;
		const strButtonTitle = event.detail.action.title;

		if (strButtonTitle && strButtonTitle === util.OPEN_PANDA) {
			let strNavigationURL = "";
			let blnIsURLValid = false;

			if (dataRow.Id?.startsWith("00Q") || dataRow.Id?.startsWith("003")) {
				let strObjectType;
				let strAccountType;
				let strCompanyId;
				let strAccountingFirmId;

				if (this.list_AppUrlMaps?.data?.length && this.list_AppUrlMaps.data[0].URL__c) {
					strNavigationURL += this.list_AppUrlMaps.data[0].URL__c;
				} else {
					displayToast(this, util.ERROR_MSG_URL_NOT_CONFIGURED, "", TOAST_PARAMS.TYPE.ERROR, "");
					return;
				}

				if (dataRow.Id?.startsWith("00Q")) {
					strObjectType = "Lead";

					// Company Lead:
					if (dataRow.RecordType?.Name === util.REC_TYPE_NAME_COMPANY && dataRow.ZP_Company_ID__c) {
						strAccountType = util.REC_TYPE_NAME_COMPANY;
						strCompanyId = dataRow.ZP_Company_ID__c;
					}

					// Reseller Lead:
					if (dataRow.RecordType?.Name === util.REC_TYPE_NAME_RESELLER && dataRow.ZP_Firm_ID__c) {
						strAccountType = util.REC_TYPE_NAME_RESELLER;
						strAccountingFirmId = dataRow.ZP_Firm_ID__c;
					}
				} else {
					strObjectType = "Contact";

					// Company Contact:
					if (dataRow.RecordType?.Name === util.REC_TYPE_NAME_COMPANY && dataRow.Account?.ZP_Company_ID__c) {
						strAccountType = util.REC_TYPE_NAME_COMPANY;
						strCompanyId = dataRow.Account.ZP_Company_ID__c;
					}

					// Reseller Contact:
					if (dataRow.RecordType?.Name === util.REC_TYPE_NAME_RESELLER && dataRow.Account?.ZP_Firm_ID__c) {
						strAccountType = util.REC_TYPE_NAME_RESELLER;
						strAccountingFirmId = dataRow.Account.ZP_Firm_ID__c;
					}
				}

				if (strAccountType && (strCompanyId || strAccountingFirmId)) {
					strNavigationURL += strAccountType === util.REC_TYPE_NAME_COMPANY ? util.PANDA_URL_PREFIX_COMPANY + strCompanyId : util.PANDA_URL_PREFIX_RESELLER + strAccountingFirmId;
					blnIsURLValid = true;
				} else {
					displayToast(this, "No Company or Firm Id is found on " + strObjectType + " record. Please try on a different record.", "", TOAST_PARAMS.TYPE.ERROR, "");
					return;
				}
			} else if (dataRow.Id?.startsWith("006")) {
				if (dataRow.AccountLink_Company__c) {
					strNavigationURL = dataRow.AccountLink_Company__c;
					blnIsURLValid = true;
				}
			}

			// Navigate to PANDA URL:
			if (blnIsURLValid) {
				window.open(strNavigationURL, "_blank");
			} else {
				displayToast(this, util.ERROR_MSG_SOMETHING_WENT_WRONG, "", TOAST_PARAMS.TYPE.ERROR, "");
			}

			return;
		}

		if ((dataRow.Id && dataRow.Id.startsWith("003")) || (dataRow.Id && dataRow.Id.startsWith("00Q"))) {
			let WhoIdlookUp = this.template.querySelector(".WhoId");

			for (var i = 0; i < this.leadDataValues.length; i++) {
				if (this.leadDataValues[i].Id == dataRow.Id) {
					if (this.dnis == "4159077035") {
						this.leadSourceDetailValue = "CLM Ongoing Nurtures";
						this.leadSourceValue = "Email";
					} else if (this.dnis == "4159077003") {
						this.leadSourceDetailValue = "CLM Experiment Emails";
						this.leadSourceValue = "Email";
					}
				}
			}

			if (WhoIdlookUp) {
				WhoIdlookUp.setSelectedRecId(dataRow.Id, false);
			}

			let WhatIdlookUp = this.template.querySelector(".WhatId");
			if (WhatIdlookUp) {
				if (dataRow.AccountId) {
					WhatIdlookUp.setSelectedRecId(dataRow.AccountId, false);
				} else {
					WhatIdlookUp.setSelectedRecId("", false);
				}
			}
		} else if (dataRow.Id && dataRow.Id.startsWith("500")) {
			let WhoIdlookUp = this.template.querySelector(".WhoId");
			if (WhoIdlookUp) {
				WhoIdlookUp.setSelectedRecId(dataRow.ContactId, false);
			}
			let WhatIdlookUp = this.template.querySelector(".WhatId");
			if (WhatIdlookUp && dataRow.Id) {
				WhatIdlookUp.setSelectedRecId(dataRow.Id, false);
			}
		} else {
			let WhatIdlookUp = this.template.querySelector(".WhatId");
			if (WhatIdlookUp && dataRow.Id) {
				WhatIdlookUp.setSelectedRecId(dataRow.Id, false);

				let WhoIdlookUp = this.template.querySelector(".WhoId");
				if (WhoIdlookUp) {
					WhoIdlookUp.setSelectedRecId(this.contactId, false);
				}
			}
		}
	}

	handleSelectRecordIdAction(event) {
		try {
			const { selectedRecordIds, refFieldApiName } = event.detail;
			this.taskObj[refFieldApiName] = selectedRecordIds;
		} catch (error) {
			let strErrMsg = error.body?.message || error.message;
			console.error(strErrMsg);
			displayToast(this, strErrMsg, "", TOAST_PARAMS.TYPE.ERROR, "");
		}
	}

	async handleSave() {
		let allValid = true;

		this.template.querySelectorAll("c-com-lookup").forEach((cur) => {
			cur.handleValidationAction((isValid) => {
				if (allValid) {
					allValid = isValid;
				}
			});
		});

		const All_Compobox_Valid = [...this.template.querySelectorAll("lightning-combobox")].reduce((validSoFar, input_Field_Reference) => {
			input_Field_Reference.reportValidity();
			return validSoFar && input_Field_Reference.checkValidity();
		}, true);

		const blnCallReason = [...this.template.querySelectorAll(`[data-name="Call Reason"]`)].reduce(checkInputValidity, true);

		let blnLearnedAboutGusto = true;
		if (this.blnShowLearnedAboutGusto) {
			blnLearnedAboutGusto = [...this.template.querySelectorAll(`[data-name="Learned About Gusto"]`)].reduce(checkInputValidity, true);
		}

		if (!allValid || !All_Compobox_Valid || !blnCallReason || !blnLearnedAboutGusto) {
			const event = new ShowToastEvent({
				title: "Error",
				variant: "error",
				message: "Please fill the required fields!"
			});
			this.dispatchEvent(event);
			return;
		}

		this.blnSpinner = true;

		try {
			let strUpsertTaskSuccessMsg = "{0} was saved successfully.";

			if (this.blnShowCaseType) {
				if (![...this.template.querySelectorAll(`[data-name="Route To"]`)].reduce(checkInputValidity, true)) {
					return;
				}
			} else {
				this.strCaseType = "";
			}
			this.taskObj = await upsertTask({ objTask: this.taskObj, strPhone: this.phone, strleadSourceValue: this.leadSourceValue, strLeadSourceDetailValue: this.leadSourceDetailValue });

			displayToast(this, TOAST_PARAMS.MESSAGE.SUCCESS, strUpsertTaskSuccessMsg, TOAST_PARAMS.TYPE.SUCCESS, "", [
				{
					url: `/${this.taskObj.Id}`,
					label: "Activity"
				}
			]);
			this.disableTabClose(false);
		} catch (error) {
			let strErrMsg = error.body?.message || error.message;
			console.error(strErrMsg);
			if (strErrMsg) {
				if (strErrMsg.includes("unable to obtain exclusive access")) {
					displayToast(this, "That didn't save correctly. Please wait for 10 seconds and save activity again", "", TOAST_PARAMS.TYPE.WARNING, "");
				} else {
					displayToast(this, strErrMsg, "", TOAST_PARAMS.TYPE.ERROR, "");
					this.disableTabClose(false);
				}
			}
		} finally {
			this.blnSpinner = false;
		}
	}

	handleFieldValueChange(event) {
		this.taskObj.Subject = event.detail.value;
	}

	commentHandleChange(event) {
		this.taskObj.Description = event.detail.value;
	}

	handleCaseTypeChange(event) {
		this.strCaseType = event.detail.value;
	}

	disableTabClose(blnDisable) {
		this.invokeWorkspaceAPI("getFocusedTabInfo").then((focusedTab) => {
			// If focused tab is Inbound call, then disable tab close
			if (focusedTab && focusedTab.customTitle && focusedTab.customTitle.startsWith("Inbound Call")) {
				// check profile from custom label. If custom label contains logged in user profile - close focused tab
				if (this.loggedInUserProfile && disableInboundCallProfile && disableInboundCallProfile.includes(this.loggedInUserProfile)) {
					// close tab if logged in user is cx profile
					this.closeTab(focusedTab);
				} else if (this.ani && disableInboundCallNumber && disableInboundCallNumber.includes(this.ani)) {
					// close tab if inbound call is from internal transfer phone number
					this.closeTab(focusedTab);
				} else if (!this.ani) {
					// close tab if no ani is found
					this.closeTab(focusedTab);
				} else {
					// if we have sub tabs - enable closing of all sub tabs
					if (focusedTab.subtabs) {
						// iterate over all sub tabs and enable tab close
						for (let tabCounter in focusedTab.subtabs) {
							// set disabled to false
							this.invokeWorkspaceAPI("disableTabClose", {
								tabId: focusedTab.subtabs[tabCounter].tabId,
								disabled: false
							}).then((tabId) => {});
						}

						// once all subtabs are enabled, set disabled on focused parent tab
						this.invokeWorkspaceAPI("disableTabClose", {
							tabId: focusedTab.tabId,
							disabled: blnDisable
						}).then((tabId) => {});
					} else {
						this.invokeWorkspaceAPI("disableTabClose", {
							tabId: focusedTab.tabId,
							disabled: blnDisable
						}).then((tabId) => {});
					}
				}
			}
		});

		// unlock all parent tabs that have a recordId
		this.invokeWorkspaceAPI("getAllTabInfo").then((list_Tabs) => {
			// iterate over each tab
			for (let i in list_Tabs) {
				let eachTab = list_Tabs[i];
				// check if each tab has a recordId and not closable, then enable tab close

				if (eachTab && eachTab.recordId && !eachTab.closable) {
					// check if eachTab has sub tabs. If yes enable tab close on subtabs
					if (eachTab.subtabs) {
						// iterate over all sub tabs and enable tab close
						for (let tabCounter in eachTab.subtabs) {
							if (eachTab.subtabs[tabCounter] && !eachTab.subtabs[tabCounter].closable) {
								// set disabled to false
								this.invokeWorkspaceAPI("disableTabClose", {
									tabId: eachTab.subtabs[tabCounter].tabId,
									disabled: false
								}).then((tabId) => {});
							}
						}
					}
					this.invokeWorkspaceAPI("disableTabClose", {
						tabId: eachTab.tabId,
						disabled: eachTab.recordId == this.recordId ? blnDisable : false
					}).then((tabId) => {});
				}
			}
		});
	}

	closeTab(focusedTab) {
		// set disabled to false
		this.invokeWorkspaceAPI("disableTabClose", {
			tabId: focusedTab.tabId,
			disabled: false
		}).then((tabId) => {});

		this.invokeWorkspaceAPI("closeTab", {
			tabId: focusedTab.tabId
		}).then((tabId) => {});
	}
}