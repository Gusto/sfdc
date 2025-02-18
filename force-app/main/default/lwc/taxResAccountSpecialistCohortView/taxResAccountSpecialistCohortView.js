import { api, LightningElement, track, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { displayToast } from "c/utilityService";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import retrieveUserRoleData from "@salesforce/apex/TaxResAccountSpecialistViewCmpCtrl.retrieveUserRoleData";
import getASCases from "@salesforce/apex/TaxResAccountSpecialistViewCmpCtrl.getAccountSpecialistCases";
import getCustomSettings from "@salesforce/apex/TaxResAccountSpecialistViewCmpCtrl.getCustomSettings";

import SystemModstamp from "@salesforce/schema/Account.SystemModstamp";
const DEFAULT_ROW_OFFSET = 0;
const SHOW_DATA_TYPE_ACTION_REQUIRED_NEW = "Account_Specialist_Overview_New_Case";
const SHOW_DATA_TYPE_ACTION_REQUIRED_INPROGRESS = "Account_Specialist_Overview_In_Progress";
const SHOW_DATA_TYPE_SHELVED_CASES = "Account_Specialist_Overview_ShelvedCases";
const CASE_SHELVED_STATUS = "Shelved";

export default class TaxResAccountSpecialistCohortView extends LightningElement {
	/* Flag for Spinner, Error Message*/
	@track blnIsLoading = false;
	@track blnIsAccountSpecialist = false;
	@track objUserRole;

	@track customConfigSettings;

	//For Action Required New Cases
	@track blnActionRequiredNewCasesRecordFound = false;
	@track list_ActionRequiredNewCasesData = [];

	//For Action Required IN Progress Cases
	@track blnActionRequiredInProgressCasesRecordFound = false;
	@track list_ActionRequiredInProgressCasesData = [];

	//For Shelved cases
	@track blnShelvedCasesRecordFound = false;
	@track list_ShelvedCasesData = [];

	rowLimitActionRequiredCases;
	rowLimitShelvedCases;

	rowOffSetActionRequiredNewCases = DEFAULT_ROW_OFFSET;
	@track strSortedDirectionActionRequiredNewCases;
	@track strSortedByActionRequiredNewCases;

	rowOffSetActionRequiredInProgressCases = DEFAULT_ROW_OFFSET;
	@track strSortedDirectionActionRequiredInProgressCases;
	@track strSortedByActionRequiredInProgressCases;

	rowOfSetShelvedCases = DEFAULT_ROW_OFFSET;
	@track strSortedDirectionShelvedCases;
	@track strSortedByShelvedCases;

	@track list_ASViewCasesColumns = [
		{
			label: "Case Number",
			fieldName: "CaseNumber",
			type: "customColumn",
			sortable: true,
			typeAttributes: {
				caseNumber: { fieldName: "CaseNumber" },
				escalationIcon: { fieldName: "EscalatedtoIcon" },
				pniIcon: { fieldName: "PnIIcon" },
				caseRecordId: {fieldName: "Id" }
			}
		},
		{
			label: "Account Name",
			fieldName: "AccountName",
			type: "text",
			sortable: true
		},
		{
			label: "Agency Information",
			fieldName: "AgencyInformation",
			type: "text",
			sortable: true
		},
		{
			label: "Tax Notice Form Number",
			fieldName: "TaxNoticeFormNumber",
			type: "text",
			sortable: true,
			initialWidth: 170
		},
		{
			label: "Age",
			fieldName: "Age",
			type: "number",
			sortable: true
		},
		{
			label: "Case Status",
			fieldName: "CaseStatus",
			type: "Text",
			sortable: true,
			initialWidth: 230
		},
		{
			label: "Email Status",
			fieldName: "EmailStatus",
			type: "text",
			sortable: true
		},
		{
			label: "Partner Tier",
			fieldName: "PartnerTier",
			type: "Text",
			sortable: true
		},
		{
			label: "Customer Tier",
			fieldName: "CustomerTier",
			type: "Text",
			sortable: true
		},
		{
			label: "Follow Up Date",
			fieldName: "FollowUpdate",
			type: "Date",
			sortable: true
		}
	];

	connectedCallback() {
		this.retrieveCustomSettingValue();
	}

	async retrieveCustomSettingValue() {
		let methodResult = await this.getCustomSettingValue();
		var t0 = performance.now();
		methodResult = await this.getUserRoleData();
		var t1 = performance.now();
		console.log("time: " + (t1 - t0) + " milliseconds.");
	}

	getCustomSettingValue() {
		this.blnIsLoading = true;
		return new Promise((resolve, reject) => {
			getCustomSettings({})
				.then((result) => {
					this.customConfigSettings = result;
					this.rowLimitActionRequiredCases = this.customConfigSettings.Tax_Res_AS_Action_Required_Cases_Limit__c;
					this.rowLimitShelvedCases = this.customConfigSettings.Tax_Res_AS_Shelved_Cases_Limit__c;
					resolve("done");
				})
				.catch((error) => {
					this.showMessage("Error!", "Error while retrieving custom settings data.", "error");
					this.blnIsLoading = false;
				})
				.finally(() => { });
		});
	}

	getUserRoleData() {
		this.blnIsAccountSpecialist = false;
		this.resetDataTableVariablesShelvedCases();
		this.resetDataTableVariablesActionRequiredNewCases();
		this.resetDataTableVariablesActionRequiredInProgressCases();
		return new Promise((resolve, reject) => {
			retrieveUserRoleData({})
				.then((result) => {
					this.objUserRole = result;
					//if record is retrieved successfully
					if (this.objUserRole?.Id) {
						this.retriveAsyncAllASCases();
					}

					//if "no record was retrieved" or "query failed"
					if (!this.objUserRole) {
						this.showMessage(
							"Error!",
							"Please set up the Tax-Resolution skills for the user.",
							"error"
						);
						this.blnIsAccountSpecialist = false;
						this.blnIsLoading = false;
					}

					resolve("done");
					this.blnIsLoading = false;
				})
				.catch((error) => {
					this.showMessage("Error!", "Error while retrieving data.", "error");
					this.blnIsAccountSpecialist = false;
					this.blnIsLoading = false;
				})
				.finally(() => { });
		});
	}

	async retriveAsyncAllASCases() {
		this.blnIsAccountSpecialist = true;
		this.blnActionRequiredNewCasesRecordFound = false;
		this.blnActionRequiredInProgressCasesRecordFound = false;
		this.blnShelvedCasesRecordFound = false;
		let methodResult = await this.retriveASActionRequiredNewCases();
		methodResult = await this.retriveASActionRequiredInProgressCases();
		methodResult = await this.retriveASShelvedCases();
	}

	//Common Method
	bindData(list_TotalCasesDataTemp) {
		var list_CasesTemp = [];
		list_TotalCasesDataTemp.forEach((objC) => {
			let assignedCases = {};
			assignedCases.Id = objC.objCase.Id;
			assignedCases.CaseNumber = objC.objCase.CaseNumber;
			assignedCases.Escalatedto = "";
			assignedCases.EscalatedtoIcon = "";
			
			if (objC.objCase.Mass_Email_Step__c != null && objC.objCase.Mass_Email_Step__c.includes("P&I Late Deposit/Amendment Partial Auto-Solve Fired")) {
				assignedCases.PnIIcon = "standard:campaign";
			}
			
			if (objC.objCase.Escalatedto__c != null && objC.objCase.Escalatedto__c != "PE/Captain") {
				assignedCases.Escalatedto = "slds-text-color_error";
				assignedCases.EscalatedtoIcon = "standard:incident";
			}

			assignedCases.AccountName = objC.objCase.Account ? objC.objCase.Account.Name : '';
			assignedCases.AgencyInformation = objC.objCase.Agency_Information__c ? objC.objCase.Agency_Information__r.Name : '';
			assignedCases.TaxNoticeFormNumber = objC.objCase.Tax_Notice_Form_Number__c;
			assignedCases.TaxNoticeType = objC.objCase.Notice_Type__c;
			assignedCases.Age = objC.objCase.Age__c;
			assignedCases.CaseStatus = objC.objCase.Status;
			if(objC.objCase.Status == CASE_SHELVED_STATUS){
				assignedCases.CaseStatus = objC.objCase.Status + '-' + objC.objCase.Shelved_Reason__c;
			}
			assignedCases.EmailStatus = objC.objCase.Email_Status__c;
			assignedCases.PartnerTier = objC.objCase.Account ? objC.objCase.Account.AM_Tier__c : '';
			assignedCases.CustomerTier = objC.objCase.Account ? objC.objCase.Account.Tier__c : '';
			assignedCases.FollowUpdate = objC.objCase.Follow_Up_Date__c;
			list_CasesTemp.push(assignedCases);
		});
		return list_CasesTemp;
	}

	//*****For Action Required new cases- Start************//
	//For AS Action Required New cases
	retriveASActionRequiredNewCases() {
		return new Promise((resolve, reject) => {
			this.blnIsLoading = true;
			getASCases({
				intLimitSize: this.rowLimitActionRequiredCases,
				intOffset: this.rowOffSetActionRequiredNewCases,
				strSortBy: this.strSortedByActionRequiredNewCases,
				strSortDirection: this.strSortedDirectionActionRequiredNewCases,
				strDataToShow: SHOW_DATA_TYPE_ACTION_REQUIRED_NEW
			}).then((result) => {
				//get All Type of Cases
				let list_CasesData = result
				let list_tempCases = [];
				//get Cases
				if (list_CasesData?.length > 0) {
					list_tempCases = this.bindData(list_CasesData);
				}

				this.list_ActionRequiredNewCasesData = [...this.list_ActionRequiredNewCasesData, ...list_tempCases];
				if (this.list_ActionRequiredNewCasesData?.length > 0) {
					this.blnActionRequiredNewCasesRecordFound = true;
				}

				if (this.strSortedByActionRequiredNewCases && this.list_ActionRequiredNewCasesData != undefined && this.list_ActionRequiredNewCasesData.length > 0) {
					this.sortData(this.strSortedByActionRequiredNewCases, this.strSortedDirectionActionRequiredNewCases, "New");
				}
				resolve("done");
			})
				.catch((error) => {
					this.showMessage("Error!", "Error while querying case records.", "error");
					reject(new Error(error));
				})
				.finally(() => {
					this.blnIsLoading = false;
				});
		});
	}

	//Method for sorting the data
	sortData(fieldname, direction, casesType) {
		let parseData;
		if(casesType == "New") {
			parseData = JSON.parse(JSON.stringify(this.list_ActionRequiredNewCasesData));
		}
		if(casesType == "InProgress") {
			parseData = JSON.parse(JSON.stringify(this.list_ActionRequiredInProgressCasesData));
		}
		if(casesType == "Shelved") {
			parseData = JSON.parse(JSON.stringify(this.list_ShelvedCasesData));
		}
		let keyValue = (a) => {
			return a[fieldname];
		};

		let isReverse = direction === "asc" ? 1 : -1;
		parseData.sort((x, y) => {
			x = keyValue(x) ? keyValue(x) : "";
			y = keyValue(y) ? keyValue(y) : "";

			return isReverse * ((x > y) - (y > x));
		});

		if(casesType == "New") {
			this.list_ActionRequiredNewCasesData = parseData;
		}
		if(casesType == "InProgress") {
			this.list_ActionRequiredInProgressCasesData = parseData;
		}
		if(casesType == "Shelved") {
			this.list_ShelvedCasesData = parseData;
		}
	}

	loadMoreActionRequiredNewCases(event) {
		this.blnIsLoading = true;
		this.rowOffSetActionRequiredNewCases = this.rowOffSetActionRequiredNewCases + this.rowLimitActionRequiredCases;
		if (this.rowOffSetActionRequiredNewCases < 2000) {
			this.retriveASActionRequiredNewCases();
		} else {
			this.blnIsLoading = false;
		}
	}

	sortColumnsForActionRequiredNewCases(event) {
		this.strSortedByActionRequiredNewCases = event.detail.fieldName;
		this.strSortedDirectionActionRequiredNewCases = event.detail.sortDirection;
		this.resetDataTableVariablesActionRequiredNewCases();
		this.retriveASActionRequiredNewCases();
	}

	resetDataTableVariablesActionRequiredNewCases() {
		this.rowLimitActionRequiredCases = this.customConfigSettings.Tax_Res_AS_Action_Required_Cases_Limit__c;
		this.rowOffSetActionRequiredNewCases = DEFAULT_ROW_OFFSET;
		this.list_ActionRequiredNewCasesData = [];
	}
	//*****For Action Required new cases- End************//

	//*****For Action Required In Progress cases- Start************//
	retriveASActionRequiredInProgressCases() {
		return new Promise((resolve, reject) => {
			this.blnIsLoading = true;
			getASCases({
				intLimitSize: this.rowLimitActionRequiredCases,
				intOffset: this.rowOffSetActionRequiredInProgressCases,
				strSortBy: this.strSortedByActionRequiredInProgressCases,
				strSortDirection: this.strSortedDirectionActionRequiredInProgressCases,
				strDataToShow: SHOW_DATA_TYPE_ACTION_REQUIRED_INPROGRESS
			}).then((result) => {
				//get All Type of Cases
				let list_CasesData = result
				let list_tempCases = [];
				//get Cases
				if (list_CasesData?.length > 0) {
					list_tempCases = this.bindData(list_CasesData);
				}

				this.list_ActionRequiredInProgressCasesData = [...this.list_ActionRequiredInProgressCasesData, ...list_tempCases];
				if (this.list_ActionRequiredInProgressCasesData?.length > 0) {
					this.blnActionRequiredInProgressCasesRecordFound = true;
				}

				if (this.strSortedByActionRequiredInProgressCases && this.list_ActionRequiredInProgressCasesData != undefined && this.list_ActionRequiredInProgressCasesData.length > 0) {
					this.sortData(this.strSortedByActionRequiredInProgressCases, this.strSortedDirectionActionRequiredInProgressCases, "InProgress");
				}
				resolve("done");
			})
				.catch((error) => {
					this.showMessage("Error!", "Error while querying case records.", "error");
					reject(new Error(error));
				})
				.finally(() => {
					this.blnIsLoading = false;
				});
		});
	}

	loadMoreActionRequiredInProgressCases(event) {
		this.blnIsLoading = true;
		this.rowOffSetActionRequiredInProgressCases = this.rowOffSetActionRequiredInProgressCases + this.rowLimitActionRequiredCases;
		if (this.rowOffSetActionRequiredInProgressCases < 2000) {
			this.retriveASActionRequiredInProgressCases();
		} else {
			this.blnIsLoading = false;
		}
	}

	sortColumnsForActionRequiredInProgressCases(event) {
		this.strSortedByActionRequiredInProgressCases = event.detail.fieldName;
		this.strSortedDirectionActionRequiredInProgressCases = event.detail.sortDirection;
		this.resetDataTableVariablesActionRequiredInProgressCases();
		this.retriveASActionRequiredInProgressCases();
	}

	resetDataTableVariablesActionRequiredInProgressCases() {
		this.rowLimitActionRequiredCases = this.customConfigSettings.Tax_Res_AS_Action_Required_Cases_Limit__c;
		this.rowOffSetActionRequiredInProgressCases = DEFAULT_ROW_OFFSET;
		this.list_ActionRequiredInProgressCasesData = [];
	}
	//*****For Action Required In Progress cases- End************//

	//*****For Action Shelved cases- Start************//
	retriveASShelvedCases() {
		return new Promise((resolve, reject) => {
			this.blnIsLoading = true;
			getASCases({
				intLimitSize: this.rowLimitShelvedCases,
				intOffset: this.rowOfSetShelvedCases,
				strSortBy: this.strSortedByShelvedCases,
				strSortDirection: this.strSortedDirectionShelvedCases,
				strDataToShow: SHOW_DATA_TYPE_SHELVED_CASES
			}).then((result) => {
				//get All Type of Cases
				let list_CasesData = result
				let list_tempCases = [];
				//get Cases
				if (list_CasesData?.length > 0) {
					list_tempCases = this.bindData(list_CasesData);
				}
				//get Shelved Cases
				this.list_ShelvedCasesData = [...this.list_ShelvedCasesData, ...list_tempCases];
				if (this.list_ShelvedCasesData?.length > 0) {
					this.blnShelvedCasesRecordFound = true;
				}

				if (this.strSortedByShelvedCases && this.list_ShelvedCasesData != undefined && this.list_ShelvedCasesData.length > 0) {
					this.sortData(this.strSortedByShelvedCases, this.strSortedDirectionShelvedCases, "Shelved");
				}
				resolve("done");
			})
				.catch((error) => {
					this.showMessage("Error!", "Error while querying case records.", "error");
					reject(new Error(error));
				})
				.finally(() => {
					this.blnIsLoading = false;
				});
		});
	}

	loadMoreShelvedCases(event) {
		this.blnIsLoading = true;
		this.rowOfSetShelvedCases = this.rowOfSetShelvedCases + this.rowLimitShelvedCases;
		if (this.rowOfSetShelvedCases < 2000) {
			this.retriveASShelvedCases();
		} else {
			this.blnIsLoading = false;
		}
	}

	sortColumnsForShelvedCases(event) {
		this.strSortedByShelvedCases = event.detail.fieldName;
		this.strSortedDirectionShelvedCases = event.detail.sortDirection;
		this.resetDataTableVariablesShelvedCases();
		this.retriveASShelvedCases();
	}

	resetDataTableVariablesShelvedCases() {
		this.rowLimitShelvedCases = this.customConfigSettings.Tax_Res_AS_Shelved_Cases_Limit__c;
		this.rowOfSetShelvedCases = DEFAULT_ROW_OFFSET;
		this.list_ShelvedCasesData = [];
	}
	//*****For Action Shelved cases- Start************//

	/* showMessage displays
	 * success, error or warning
	 * messages. depending on the strClassName,
	 * type fo messages will vary.
	 */
	showMessage(strTitle, strMessage, strVarient) {
		const evt = new ShowToastEvent({
			title: strTitle,
			message: strMessage,
			variant: strVarient
		});
		this.dispatchEvent(evt);
	}
}