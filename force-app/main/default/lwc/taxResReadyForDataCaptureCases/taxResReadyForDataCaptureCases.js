import { LightningElement, track, wire } from "lwc";
import { displayToast } from "c/utilityService";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import Tier from "@salesforce/schema/Tax_Notice_Index__c.Tier__c";
import PartnerTier from "@salesforce/schema/Tax_Notice_Index__c.Partner_Tier__c";
import NoticeType from "@salesforce/schema/Case.Notice_Type__c";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import CASE_OBJECT from "@salesforce/schema/Case";
import getCases from "@salesforce/apex/TaxResReadyForDataCaptureCasesController.getCases";
import updateCaseOwner from "@salesforce/apex/TaxResReadyForDataCaptureCasesController.updateCaseOwner";

const columnsPE = [
	{
		type: "button-icon",
		initialWidth: 34,
		typeAttributes: {
			alternativeText: "Open Case",
			iconName: "utility:open",
			variant: "border-filled",
			name: "opencase"
		}
	},
	{
		label: '',
		fieldName: '',
		initialWidth: 30,
		cellAttributes: { iconName: { fieldName: 'dynamicIcon' }},
		sortable : false,
		hideDefaultActions: true,
		target: "_blank"
	},
	/* {
		label: "Is OCR Case",
		fieldName: "IsOCRProcessed",
		type: "text",
		sortable: true
	}, */
	{ label: "Auto Index Status", fieldName: "autoIndexStatus", type: "Text", sortable: true },
	{ label: "Case Number", fieldName: "caseNumber", type: "text", sortable: true },
	{ label: "Case Owner", fieldName: "caseOwner", type: "text", sortable: true },
	{ label: "Account Name", fieldName: "accountName", type: "text", sortable: true },
	{ label: "Agency", fieldName: "agencyInfo", type: "text", sortable: true },
	{ label: "Segment", fieldName: "segment", type: "text", sortable: true },
	{ label: "Tier", fieldName: "tier", sortable: true },
	{ label: "Status", fieldName: "status", sortable: true },
	{ label: "Age", fieldName: "age", type: "number", sortable: true, cellAttributes: { alignment: "center" } }
];

const CASE_LOAD_MESSAGE_ERROR = "Error while retrieving Case records.";
const ROW_ACTION_MESSAGE_ERROR = "Unable to access record.";
const DEFAULT_ROW_LIMIT = 5;
const DEFAULT_ROW_OFFSET = 0;
const DEFAULT_SORTBY = "createdDate";
const DEFAULT_SORT_DIRECTION = "ASC";
const PARTIALLY_INDEXED = "Partially Indexed";

export default class TaxResReadyForDataCaptureCases extends LightningElement {
	columns = columnsPE;
	strErrorMsg = "";

	@track list_Cases = [];
	strSortedDirection = DEFAULT_SORT_DIRECTION;
	strSortedBy = DEFAULT_SORTBY;
	strTierFilter = "";
	strPartnerTierFilter = "";
	intStartAgeFilter;
	intEndAgeFilter;
	dtStartDueDateFilter;
	dtEndDueDateFilter;
	strFilterCaseOwner = "";
	strTaxNoticeType = "";
	strSelectedSegment = "";
	@track blnSelectedIsOCRValue;
	strSelectedTier = "";
	strSelectedPartnerTier = "";
	blnIsLoading = false;
	blnShowTier = false;
	blnShowPopup = false;
	blnShowPartnerTier = false;
	rowLimit = DEFAULT_ROW_LIMIT;
	rowOffSet = DEFAULT_ROW_OFFSET;
	list_Segments = [];
	list_OCRValues = [];
	list_SelectedDatatableCaseIds = [];

	@wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
	accountInfo;

	@wire(getPicklistValues, {
		recordTypeId: "012000000000000AAA",
		fieldApiName: Tier
	})
	TierValues;

	@wire(getPicklistValues, {
		recordTypeId: "012000000000000AAA",
		fieldApiName: PartnerTier
	})
	partnerTierValues;

	@wire(getObjectInfo, { objectApiName: CASE_OBJECT })
	caseInfo;

	@wire(getPicklistValues, {
		recordTypeId: "$caseInfo.data.defaultRecordTypeId",
		fieldApiName: NoticeType
	})
	NoticeTypeValues;

	//onload lifecycle hook
	connectedCallback() {
		//Populate picklist value
		this.list_Segments = [];
		this.list_OCRValues = [];
		this.list_Segments = [
			{ label: "All", value: "All" },
			{ label: "Company", value: "Company" },
			{ label: "Reseller", value: "Reseller" },
			{ label: "Partner", value: "Partner" },
			{ label: "BizDev", value: "BizDev" }
		];
		this.list_OCRValues = [
			{ label: "N/A", value: "N/A" },
			{ label: "Yes", value: "true" },
			{ label: "No", value: "false" }
		];
		this.getEligibleCases();
	}

	//called on click of "refresh" button from page
	refreshPage() {
		this.resetDataTableVariables();
		this.getEligibleCases();
	}

	//method that calls apex method to get List of eligible cases
	getEligibleCases() {
		this.blnIsLoading = true;
		return getCases({
			intLimitSize: this.rowLimit,
			intOffset: this.rowOffSet,
			strOrderBy: this.strSortedBy,
			strOrderDirection: this.strSortedDirection,
			strTierFilter: this.strTierFilter,
			strPartnerTierFilter: this.strPartnerTierFilter,
			intStartAge: this.intStartAgeFilter,
			intEndAge: this.intEndAgeFilter,
			dtStartDueDate: this.dtStartDueDateFilter,
			dtEndDueDate: this.dtEndDueDateFilter,
			strTaxNoticeType: this.strTaxNoticeType,
			strOwnerId: this.strFilterCaseOwner,
			strSegment: this.strSelectedSegment,
			blnIsOCR: this.blnSelectedIsOCRValue
		})
			.then((data) => {
				let list_totalRecords = data;
				let list_tempCases = [];
				list_totalRecords.forEach((objCase) => {
					let tempCase = this.createTableInstance(objCase);
					list_tempCases.push(tempCase);
				});

				this.list_Cases = [...this.list_Cases, ...list_tempCases];

				/* let list_sortedCases = Object.values(this.list_UnAssignedCases).sort((a, b) => b.isPartiallyIndexed - a.isPartiallyIndexed);
				this.list_Cases = list_sortedCases; */

				this.strErrorMsg = undefined;
			})
			.catch((error) => {
				console.log(JSON.stringify(error))
				let errorMessage = CASE_LOAD_MESSAGE_ERROR;
				if (error.body && error.body.message) {
					errorMessage = error.body.message;
				} else if (error) {
					errorMessage = error;
				}
				this.showMessage("Error!", errorMessage, "error");
			})
			.finally(() => {
				this.blnIsLoading = false;
			});
	}

	//util method return dataTable object instance
	createTableInstance(objCase) {
		let tempCase = {};
		tempCase.id = objCase.Id;
		//tempCase.IsOCRProcessed = objCase.Is_OCR_Processed__c;
		tempCase.dynamicIcon = objCase.Auto_Indexing_Status__c == PARTIALLY_INDEXED ? 'custom:custom53' : '';
		tempCase.autoIndexStatus = objCase.Auto_Indexing_Status__c;
		tempCase.caseNumber = objCase.CaseNumber;
		tempCase.caseOwner = objCase.Owner.Name;
		tempCase.status = objCase.Status;
		tempCase.accountName = objCase.AccountId ? objCase.Account.Name : "";
		tempCase.tier = objCase.AccountId ? objCase.Account.Tier__c : "";
		tempCase.createdDate = objCase.CreatedDate;
		tempCase.age = objCase.Age__c ? objCase.Age__c : 0;
		tempCase.segment = objCase.AccountId ? objCase.Account.RecordType.Name : "";
		tempCase.agencyInfo = objCase.Agency_Information__c ? objCase.Agency_Information__r.Name : "";
		return tempCase;
	}

	/**function called from case table on sort event*/
	handleColumnSort(event) {
		this.strSortedBy = event.detail.fieldName;
		this.strSortedDirection = event.detail.sortDirection;
		console.log(this.strSortedBy)
		console.log(this.strSortedDirection)
		this.resetDataTableVariables();
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
	}

	resetDataTableVariables() {
		this.rowLimit = DEFAULT_ROW_LIMIT;
		this.rowOffSet = DEFAULT_ROW_OFFSET;
		this.list_Cases = [];
	}

	openCaseRecord(strCaseId) {
		if (strCaseId) {
			const recordNavigation = new CustomEvent("OpenCase", {
				detail: {
					idCase: strCaseId
				}
			});
			this.dispatchEvent(recordNavigation);
		} else {
			this.showMessage("Error!", ROW_ACTION_MESSAGE_ERROR, "warning");
		}
	}

	/**dataTable filters change handler method */
	handleFilterChange(event) {
		let blnHasFilterChanged = false;
		if (event.target.name === "blnIsOCR") {
			if (event.detail.value !== "N/A") {
				this.blnSelectedIsOCRValue = event.detail.value;
			} else {
				this.blnSelectedIsOCRValue = null;
			}

			blnHasFilterChanged = true;
		}
		if (event.target.name == "strSegment") {
			this.strSelectedSegment = event.detail.value.toString();
			this.blnShowTier = false;
			this.blnShowPartnerTier = false;
			this.strTierFilter = "";
			this.strPartnerTierFilter = "";
			if (this.strSelectedSegment === "Company") {
				this.blnShowTier = true;
			} else if (this.strSelectedSegment !== "All") {
				this.blnShowPartnerTier = true;
			}

			blnHasFilterChanged = true;
		}
		if (event.target.name == "tier") {
			this.strTierFilter = event.detail.value.toString();
			blnHasFilterChanged = true;
		}
		if (event.target.name == "partnertier") {
			this.strPartnerTierFilter = event.detail.value.toString();
			blnHasFilterChanged = true;
		}

		if (event.target.name == "startAge") {
			this.intStartAgeFilter = event.detail.value ? event.detail.value : 0;
			blnHasFilterChanged = true;
		}

		if (event.target.name == "endAge") {
			this.intEndAgeFilter = event.detail.value ? event.detail.value : 0;
			blnHasFilterChanged = true;
		}

		if (event.target.name == "startDueDate") {
			this.dtStartDueDateFilter = event.detail.value;
			blnHasFilterChanged = true;
		}

		if (event.target.name == "endDueDate") {
			this.dtEndDueDateFilter = event.detail.value;
			blnHasFilterChanged = true;
		}

		if (event.target.name == "strCaseOwner") {
			this.strFilterCaseOwner = event.detail.value.toString();
			blnHasFilterChanged = true;
		}

		if (event.target.name == "taxNoticeType") {
			this.strTaxNoticeType = event.detail.value.toString();
			blnHasFilterChanged = true;
		}

		if (event.target.name == "openUpdateOwnerPopup") {
			this.blnShowPopup = false;
			if (this.list_SelectedDatatableCaseIds.length == 0) {
				this.showMessage("Error!", "Please select case to change owner", "error");
			} else {
				this.blnShowPopup = true;
			}
		}

		if (event.target.name == "case-owner-values") {
			this.strSelectedCaseOwner = event.detail.value.toString();
		}

		if (blnHasFilterChanged) {
			this.resetDataTableVariables();
			this.getEligibleCases();
		}
	}

	/**Lazy loading start */
	loadMoreData(event) {
		const currentRecord = this.list_Cases;
		const { target } = event;
		this.blnIsLoading = true;

		this.rowOffSet = this.rowOffSet + this.rowLimit;
		if (this.rowOffSet < 2000) {
			this.getEligibleCases().then(() => {
				this.blnIsLoading = false;
			});
		}
	}
	/**Lazy loading end */
	/*Handle Case Table Row Selection*/
	handleCaseRowSelection(event) {
		this.list_SelectedDatatableCaseIds = [];
		const selectedRows = event.detail.selectedRows;
		for (let i = 0; i < selectedRows.length; i++) {
			this.list_SelectedDatatableCaseIds.push(selectedRows[i].id);
		}
	}

	/*Handle Popup functionality*/
	handleEvent(event) {
		/**Next Button event */
		if (event.target.name === "updateOwnerBtn") {
			this.updateCaseOwner();
		}
		if (event.target.name === "cancelmodelBtn") {
			this.blnShowPopup = false;
		}
	}

	updateCaseOwner() {
		this.blnIsLoading = true;
		return new Promise((resolve, reject) => {
			updateCaseOwner({
				list_CaseIds: this.list_SelectedDatatableCaseIds,
				strCaseOwner: this.strSelectedCaseOwner
			})
				.then((result) => {
					if (result === "success") {
						displayToast(this, "Success!", "The Case has been successfully updated.", "success", "");
						this.blnShowPopup = false;
						this.resetDataTableVariables();
						this.getEligibleCases();
					} else if (result === "invaliduser") {
						displayToast(this, "Error!", "Unauthorized user, please select a Tax Notice Indexor", "error", "");
					} else {
						displayToast(this, "Error!", result, "error", "");
					}
					resolve("done");
				})
				.catch((error) => {
					displayToast(this, "Error!", "Error while updating case.", "error", "");
				})
				.finally(() => {
					this.blnIsLoading = false;
				});
		});
	}

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