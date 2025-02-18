import { LightningElement, track, wire } from "lwc";
import { displayToast } from "c/utilityService";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getCases from "@salesforce/apex/TaxResICReadyForDataCaptureCasesCtrl.getCases";
import takeItCase from "@salesforce/apex/TaxResICReadyForDataCaptureCasesCtrl.takeItCase";

const columnsIC = [
	{
		type: "button-icon",
		initialWidth: 34,
		typeAttributes: { alternativeText: "Open Case", iconName: "utility:open", variant: "border-filled", name: "opencase" }
	},
	{
		type: "button",
		initialWidth: 100,
		typeAttributes: { alternativeText: "Take It", variant: "border-filled", name: "takeIt", label: "Take It", variant: "brand", disabled: { fieldName: "inProgress" } },
		cellAttributes: { alignment: "center" }
	},
	{ label: "Case Number", fieldName: "caseNumber", type: "text", sortable: true },
	{ label: "Account Name", fieldName: "accountName", type: "text", sortable: true },
	{ label: "Agency", fieldName: "agencyInfo", type: "text", sortable: true },
	{ label: "Segment", fieldName: "segment", type: "text", sortable: true },
	{ label: "Tier", fieldName: "tier", sortable: true },
	{ label: "Status", fieldName: "status", sortable: true },
	{ label: "Age", fieldName: "age", type: "number", sortable: true, cellAttributes: { alignment: "center" } }
];

const CASE_LOAD_MESSAGE_ERROR = "Error while retrieving Case records.";
const ROW_ACTION_MESSAGE_ERROR = "Unable to access record.";
const TAKE_IT_SUCCESS_MSG = "The Case has been successfully updated.";
const TAKE_IT_ALREADY_TAKEN_MSG = "Case has already been taken care by someone else.";
const TAKE_IT_ERROR_MSG = "Error while updating case.";
const TAKE_IT_MY_CASES_PRESENT_ERROR_MSG = "Can not pick a new case before completing all the assigned cases first.";
const TAKE_IT_MY_CASES_INPROGRESS_ERROR_MSG = "Can not pick a new case before completing all the in-progress cases first.";
const DEFAULT_ROW_LIMIT_MY_CASES = 7;
const DEFAULT_ROW_LIMIT = 12;
const DEFAULT_ROW_OFFSET = 0;
const DEFAULT_SORTBY = "Age__c";
const DEFAULT_SORT_DIRECTION = "DESC";
const CASE_STATUS_DATA_CAPTURE_IN_PROGRESS = "Data Capture in Progress";

export default class TaxResICReadyForDataCaptureNonIDPCases extends LightningElement {
	columns = columnsIC;
	strErrorMsg = "";
	blnIsLoading = false;
	blnIsMyCases = false;

	/**my cases table related variables*/
	@track list_MyCases = [];
	rowLimitMyCases = DEFAULT_ROW_LIMIT_MY_CASES;
	rowOffSetMyCases = DEFAULT_ROW_OFFSET;
	strSortedDirectionMyCases = DEFAULT_SORT_DIRECTION;
	strSortedByMyCases = DEFAULT_SORTBY;
	blnIsInProgressCasePresent = false;

	/**unassigned cases table related variables*/
	@track list_UnAssignedCases = [];
	rowLimit = DEFAULT_ROW_LIMIT;
	rowOffSet = DEFAULT_ROW_OFFSET;
	strSortedDirection = DEFAULT_SORT_DIRECTION;
	strSortedBy = DEFAULT_SORTBY;

	//onload lifecycle hook
	connectedCallback() {
		this.getCaseDetails();
	}

	//called on click of "refresh" button from page
	refreshPage() {
		this.resetDataTableVariables();
		this.resetDataTableVariablesMyCases();
		this.getCaseDetails();
	}

	async getCaseDetails() {
		let methodResult = await this.getEligibleCases();
		this.blnIsMyCases = true;
		methodResult = await this.getEligibleCases();
		this.blnIsMyCases = false;
	}

	//method that calls apex method to get List of eligible cases
	getEligibleCases() {
        console.log('test')
		return new Promise((resolve, reject) => {
			this.blnIsLoading = true;
			getCases({
				intLimitSize: this.blnIsMyCases ? this.rowLimitMyCases : this.rowLimit,
				intOffset: this.blnIsMyCases ? this.rowOffSetMyCases : this.rowOffSet,
				strOrderBy: this.blnIsMyCases ? this.strSortedByMyCases : this.strSortedBy,
				strOrderDirection: this.blnIsMyCases ? this.strSortedDirectionMyCases : this.strSortedDirection,
				blnIsMyCases: this.blnIsMyCases,
                blnIsIDP: false
			})
				.then((data) => {
					let list_totalRecords = data;
					let list_tempCases = [];
					list_totalRecords.forEach((objCase) => {
						let tempCase = this.createTableInstance(objCase);
						list_tempCases.push(tempCase);
					});

					if (this.blnIsMyCases) {
						this.list_MyCases = [...this.list_MyCases, ...list_tempCases];
					} else {
						this.list_UnAssignedCases = [...this.list_UnAssignedCases, ...list_tempCases];
					}

					this.strErrorMsg = undefined;
					resolve("done");
				})
				.catch((error) => {
					let errorMessage = CASE_LOAD_MESSAGE_ERROR;
					if (error.body && error.body.message) {
						errorMessage = error.body.message;
					} else if (error) {
						errorMessage = error;
					}
					this.showMessage("Error!", errorMessage, "error");
					reject(new Error(error));
				})
				.finally(() => {
					this.blnIsLoading = false;
				});
		});
	}

	//util method return dataTable object instance
	createTableInstance(objCase) {
		let tempCase = {};
		tempCase.id = objCase.Id;
		tempCase.caseNumber = objCase.CaseNumber;
		tempCase.status = objCase.Status;
		tempCase.accountName = objCase.AccountId ? objCase.Account.Name : "";
		tempCase.tier = objCase.AccountId ? objCase.Account.Tier__c : "";
		tempCase.createdDate = objCase.CreatedDate;
		tempCase.age = objCase.Age__c ? objCase.Age__c : 0;
		tempCase.segment = objCase.AccountId ? objCase.Account.RecordType.Name : "";
		tempCase.agencyInfo = objCase.Agency_Information__c ? objCase.Agency_Information__r.Name : "";
		tempCase.inProgress = objCase.Status === CASE_STATUS_DATA_CAPTURE_IN_PROGRESS ? true : false;
		if (tempCase.inProgress) {
			this.blnIsInProgressCasePresent = tempCase.inProgress;
		}
		return tempCase;
	}

	/**function called from case table on sort event*/
	handleColumnSort(event) {
		this.strSortedBy = event.detail.fieldName;
		this.strSortedDirection = event.detail.sortDirection;
		this.resetDataTableVariables();
		this.blnIsMyCases = false;
		this.getEligibleCases();
	}

	/**function called from my cases table on sort event*/
	handleColumnSortMyCases(event) {
		this.strSortedByMyCases = event.detail.fieldName;
		this.strSortedDirectionMyCases = event.detail.sortDirection;
		this.resetDataTableVariablesMyCases();
		this.blnIsMyCases = true;
		this.getEligibleCases();
	}

	/**dataTable row action handler method */
	handleRowAction(event) {
		const action = event.detail.action;
		const row = event.detail.row;

		if (action.name === "opencase") {
			let strCaseId = row.id;
			this.openCaseRecord(strCaseId);
		}

		if (action.name === "takeIt") {
			if (this.list_MyCases.length > 0) {
				this.showMessage("Information!", TAKE_IT_MY_CASES_PRESENT_ERROR_MSG, "info");
			} else {
				let strCaseId = row.id;
				this.blnIsMyCases = false;
				this.TakeIt(strCaseId);
			}
		}
	}

	handleRowActionMyCases(event) {
		const action = event.detail.action;
		const row = event.detail.row;

		if (action.name === "opencase") {
			let strCaseId = row.id;
			this.openCaseRecord(strCaseId);
		}

		if (action.name === "takeIt") {
			if (this.blnIsInProgressCasePresent) {
				this.showMessage("Information!", TAKE_IT_MY_CASES_INPROGRESS_ERROR_MSG, "info");
			} else {
				this.blnIsMyCases = true;
				this.blnIsInProgressCasePresent = false;
				let strCaseId = row.id;
				this.TakeIt(strCaseId);
			}
		}
	}

	resetDataTableVariables() {
		this.rowLimit = DEFAULT_ROW_LIMIT;
		this.rowOffSet = DEFAULT_ROW_OFFSET;
		this.list_UnAssignedCases = [];
	}

	resetDataTableVariablesMyCases() {
		this.rowLimitMyCases = DEFAULT_ROW_LIMIT_MY_CASES;
		this.rowOffSetMyCases = DEFAULT_ROW_OFFSET;
		this.list_MyCases = [];
	}

	openCaseRecord(strCaseId) {
		console.log("strCaseId ===> " + strCaseId);
		if (strCaseId) {
			const recordNavigation = new CustomEvent("OpenCaseRecord", {
				detail: {
					idCase: strCaseId
				}
			});
			this.dispatchEvent(recordNavigation);
			this.blnIsLoading = false;
		} else {
			this.showMessage("Error!", ROW_ACTION_MESSAGE_ERROR, "warning");
		}
	}

	//Handles "Take It" functionality by calling apex method
	TakeIt(strCaseId) {
		this.blnIsLoading = true;
		return new Promise((resolve, reject) => {
			takeItCase({
				strCaseId: strCaseId
			})
				.then((result) => {
					if (result === "success") {
						displayToast(this, "Success!", TAKE_IT_SUCCESS_MSG, "success", "");
						//refreshing the table to get correct records
						if (this.blnIsMyCases) {
							this.resetDataTableVariablesMyCases();
						} else {
							this.resetDataTableVariables();
						}

						this.getEligibleCases();
						this.openCaseRecord(strCaseId);
					} else if (result === "alreadytaken") {
						displayToast(this, "Error!", TAKE_IT_ALREADY_TAKEN_MSG, "error", "");
						//refreshing the table to get correct records
						if (this.blnIsMyCases) {
							this.resetDataTableVariablesMyCases();
						} else {
							this.resetDataTableVariables();
						}
						this.getEligibleCases();
						this.blnIsLoading = false;
					} else {
						displayToast(this, "Error!", result, "error", "");
						this.blnIsLoading = false;
					}
					resolve("done");
				})
				.catch((error) => {
					displayToast(this, "Error!", TAKE_IT_ERROR_MSG, "error", "");
				})
				.finally(() => {});
		});
	}

	/**Lazy loading start */
	loadMoreData(event) {
		this.blnIsLoading = true;

		this.rowOffSet = this.rowOffSet + this.rowLimit;
		if (this.rowOffSet < 2000) {
			this.getEligibleCases();
		}
	}

	loadMoreDataMyCases(event) {
		this.blnIsLoading = true;

		this.rowOffSetMyCases = this.rowOffSetMyCases + this.rowLimitMyCases;
		if (this.rowOffSetMyCases < 2000) {
			this.blnIsMyCases = true;
			this.getEligibleCases();
		}
	}
	/**Lazy loading end */

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