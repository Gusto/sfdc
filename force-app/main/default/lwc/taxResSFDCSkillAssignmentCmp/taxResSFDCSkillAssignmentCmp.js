import { api, LightningElement, track, wire } from "lwc";
import { loadStyle } from "lightning/platformResourceLoader";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getPicklistValues, getObjectInfo } from "lightning/uiObjectInfoApi";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import fetchWrapperData from "@salesforce/apex/TaxResSFDCSkillAssignmentWrapper.fetchUserSkills";
import dmlOnServiceSkills from "@salesforce/apex/TaxResSFDCSkillAssignmentWrapper.dmlOnUserSkills";
import getAllSkillsForUserRoleAgency from "@salesforce/apex/TaxResSFDCSkillAssignmentWrapper.getAllSkillsForUserRoleAgency";

import NOTICE_TYPE from "@salesforce/schema/Case.Tax_Notice_Type__c";
import TIER from "@salesforce/schema/Account.Tier__c";
import PARTNER_TIER from "@salesforce/schema/Account.AM_Tier__c";
import WrappedHeaderTable from "@salesforce/resourceUrl/WrappedHeaderTable";
import DEFAULT_ROW_LIMIT from '@salesforce/label/c.IR_Skill_Assignment_Page_Size';
import USER_SKILL_OBJ from '@salesforce/schema/User_Skill__c';
import USER_SKILL_DEBIT_CREDIT from "@salesforce/schema/User_Skill__c.Debit_Credit__c";
import USER_SKILL_TIER from "@salesforce/schema/User_Skill__c.Tier__c";
const FIELDS = ["Agency_Information__c.Agency_Complexity__c"];

const map_UpdatedWrapperRecords = new Map();
const DELETE_BTN = "deleteButton";
const SAVE_BTN = "saveButton";
const MSG_DELETE_SELECT_ALTEAST_ONE_ROW = "Select at least one row to delete.";
const MSG_SAVE_NEED_ATLEAST_ONE_ROW = "Fill at least one row to create.";
const DEFAULT_ROW_OFFSET = 0;
const DEFAULT_SORTBY = "Name";
const DEFAULT_SORT_DIRECTION = "ASC";
const DEFAULT_SCROLL_SIZE = 50;
const ERROR_MSG_BOTH_CAN_NOT_BE_FILLED = "Tier and Partner Tier both cannot be filled in.";
const ERROR_MSG_BOTH_CAN_NOT_BE_NULL = "Tier and Partner Tier both cannot be null.";
const ERROR_MSG_INVALID_VALUE_NA = 'NA is not a valid value, please deselect NA and try again.';
const AGENT_BACKUP_SAME_MSG = 'Resource cannot be its own backup.';

//Get columns for the Service Resource table
const mainColumns = [
	{
		label: "Service Resource Name",
		fieldName: "strAgentName",
		initialWidth: 150,
		type: "text",
		sortable: true,
		wrapText: true
	},
	{
		label: "Backup Resource Name",
		fieldName: "strBAgentName",
		initialWidth: 150,
		type: "text",
		sortable: false,
		wrapText: true
	},
	{
		label: "Agency Name",
		fieldName: "strAgencyName",
		initialWidth: 150,
		type: "text",
		sortable: false,
		wrapText: true
	},
	{
		label: "Agency Complexity",
		fieldName: "strAgencyComplexity",
		type: "text",
		sortable: false
	},
	{
		label: "Tax Notice Type",
		fieldName: "strNoticeType",
		type: "text",
		sortable: false
	},
	{
		label: "Form Number Complexity",
		fieldName: "strFormNumberComplexity",
		type: "text",
		sortable: false
	},
	{
		label: "Debit/Credit",
		fieldName: "strDebitCredit",
		type: "text",
		sortable: false
	},
	{
		label: "$ Threshold",
		fieldName: "strThreshold",
		type: "text",
		sortable: false,
		wrapText: true
	},
	{
		label: "Tier",
		fieldName: "strTier",
		type: "text",
		sortable: false
	},
	{
		label: "Partner Tier",
		fieldName: "strPartnerTier",
		type: "text",
		sortable: false
	},
	{
		label: "Multi Year Y/N",
		fieldName: "strMultiYear",
		type: "text",
		sortable: false
	}
];

//Get columns for the Skill details table
const mainColumns2 = [
	{
		label: "Service Resource Name",
		fieldName: "strAgentName",
		initialWidth: 100,
		type: "text",
		wrapText: true
	},
	{
		label: "Agency Name",
		fieldName: "strAgencyName",
		type: "text",
		sortable: false,
		initialWidth: 150,
		wrapText: true
	},
	{
		label: "Agency Complexity",
		fieldName: "strAgencyComplexity",
		type: "text",
		sortable: false
	},
	{
		label: "Tax Notice Type",
		fieldName: "strNoticeType",
		type: "text",
		sortable: false
	},
	{
		label: "Form Number Complexity",
		fieldName: "strFormNumberComplexity",
		type: "text",
		sortable: false
	},
	{
		label: "Debit/Credit",
		fieldName: "strDebitCredit",
		type: "text",
		sortable: false
	},
	{
		label: "$ Threshold",
		fieldName: "strThreshold",
		type: "text",
		sortable: false,
		wrapText: true
	},
	{
		label: "Tier",
		fieldName: "strTier",
		type: "text",
		sortable: false
	},
	{
		label: "Partner Tier",
		fieldName: "strPartnerTier",
		type: "text",
		sortable: false
	},
	{
		label: "Multi Year Y/N",
		fieldName: "strMultiYear",
		type: "text",
		sortable: false
	},
	{
		label: "Active",
		fieldName: "blnIsActive",
		type: "boolean",
		sortable: false
	}
];

const map_Complexity = new Map();
map_Complexity.set('Low', 'L');
map_Complexity.set('Medium', 'M');
map_Complexity.set('High', 'H');

const map_DebitCredit = new Map();
map_DebitCredit.set('Debit', 'D');
map_DebitCredit.set('Credit', 'C');
map_DebitCredit.set('No Balance Due', 'N');

const map_Threshold = new Map();
map_Threshold.set('$0.00', '0');
map_Threshold.set('$0.00 - $50.00', '50');
map_Threshold.set('$0.00 - $1500.00', '1500');
map_Threshold.set('$0.00 - $10,000.00', '10000');
map_Threshold.set('$0.00 - $10,000.00+', '10000+');

const map_MultiYear = new Map();
map_MultiYear.set('Yes', 'Y');
map_MultiYear.set('No', 'N');

export default class TaxResSFDCSkillAssignmentCmp extends LightningElement {
	blnShowServiceResourcesSummary = true;
	blnShowServiceResourcesEditable = false;
	@track columns = mainColumns;
	@track error;
	@track data = []; // to store all the data received from server
	@track visibleData = []; // to store the data to be displayed
	@track newData;
	@track list_ToBeDeletedRecordIds;
	@track blnIsLoading = true;
	blnAddNewRows = false;
	strSortedBy = DEFAULT_SORTBY;
	strSortedDirection = DEFAULT_SORT_DIRECTION;
	rowLimit = DEFAULT_ROW_LIMIT;
	rowOffSet = DEFAULT_ROW_OFFSET;
	intScrollSize = DEFAULT_SCROLL_SIZE;
	blnRowsSelectedForDeletion = false;
	strToActivateSkillIds = "";
	strToDeactivateSkillIds = "";
	intTotalRecordCount = 0;
	strReportId = '';
	blnIsEditSkill = false;
	objEditedRow = '';

	//new agencygrouping related variables
	strSelectAgencyRowId = '';
	userSkillsData = [];
	@track agencySkillColumns = mainColumns2;
	blnShowAgencySkills = false;

	/**Filter Variables */
	map_ResourceNameId = new Map();
	list_ResourceNameMaster = [];
	list_ResourceNameFiltered = [];
	strSelectedResourceName = "";
	strSelectedResourceIds = "";
	strSelectedAgencyNames = "";
	list_AgencyNameOptions = [];
	list_EditAgencies = [];
	blnIsAgencyFound = false;
	list_TierOptions = [];
	list_PartnerTierOptions = [];
	strActionType = '';

	strSelectedDebitCredit = "";
	strSelectedTier = "";
	/**AutoComplete */
	@api values;
	@api label = "";
	@api name = "";
	@api value = "";
	@api required;
	@api placeholder = "";
	initialized = false;

	/**Agency Complexity related fields*/
	@track userSelectedAgencyId = "";
	changedAgencyRowUniqueId = "";
	@track fields = FIELDS;
	@track agencyRecord;
	isRendered = false;

	@track selectedValue = "C"; //selected values
	@track selectedValueList = []; //selected values
	@track selectedAgencyList = [];
	@track selectedTiers = [];
	@track selectedPartnerTiers = [];
	@track selectedNoticeTypes = [];
	@track selectedDebitTypes = [];

	@wire(getPicklistValues, {
		recordTypeId: "0121M000001Yf5fQAC",
		fieldApiName: NOTICE_TYPE
	})
	list_NoticeTypeOptions;

	@wire(getPicklistValues, {
		recordTypeId: "012G0000001B3nzIAC",
		fieldApiName: TIER
	})
	getPicklistValuesForField({ data, error }) {
		if (error) {
			console.error(error);
		} else if (data) {
			this.list_TierOptions = [{ label: "NA", value: "NA" }, ...data.values];
		}
	}

	@wire(getPicklistValues, {
		recordTypeId: "0128Y000001h3USQAY",
		fieldApiName: PARTNER_TIER
	})
	getPicklistValuesForPartner({ data, error }) {
		if (error) {
			console.error(error);
		} else if (data) {
			this.list_PartnerTierOptions = [{ label: "NA", value: "NA" }, ...data.values];
		}
	}

	//User Skill Picklist Values
	@wire(getObjectInfo, { objectApiName: USER_SKILL_OBJ })
	userSkillObjectInfo;

	@wire(getPicklistValues, {
		recordTypeId: '$userSkillObjectInfo.data.defaultRecordTypeId',
		fieldApiName: USER_SKILL_DEBIT_CREDIT
	})
	getPicklistValuesForField1({ data, error }) {
		if (data) {
			this.list_UserSkillDebitCreditOptions = data.values;
		} else if (error) {
			console.error(error);
		}
	}

	@wire(getPicklistValues, {
		recordTypeId: '$userSkillObjectInfo.data.defaultRecordTypeId',
		fieldApiName: USER_SKILL_TIER
	})
	getPicklistValuesForField2({ data, error }) {
		if (data) {
			this.list_UserSkillTierOptions = data.values;
		} else if (error) {
			console.error(error);
		}
	}

	get complexityOptions() {
		return [
			{ label: "Low", value: "L" },
			{ label: "Medium", value: "M" },
			{ label: "High", value: "H" }
		];
	}

	get debitCreditOptions() {
		return [
			{ label: "Debit", value: "D" },
			{ label: "Credit", value: "C" },
			{ label: "No Balance Due", value: "N" }
		];
	}

	get thresholdOptions() {
		return [
			{ label: "$0.00", value: "0" },
			{ label: "$0.00 - $50.00", value: "50" },
			{ label: "$0.00 - $1500.00", value: "1500" },
			{ label: "$0.00 - $10,000.00", value: "10000" },
			{ label: "$0.00 - $10,000.00+", value: "10000+" }
		];
	}

	get multiYearOptions() {
		return [
			{ label: "Yes", value: "Y" },
			{ label: "No", value: "N" }
		];
	}

	connectedCallback() {
		this.getResourceSkills();
		this.columns.push({ type: "action", typeAttributes: { rowActions: this.getMainTableRowActions } });
		this.agencySkillColumns.push({ type: "action", typeAttributes: { rowActions: this.getRowActions } });
	}

	getMainTableRowActions(row, doneCallback) {
		doneCallback([{ label: "Show All Skills", name: "allSkills", iconName: "utility:open" },
		{ label: "Edit", name: "edit", iconName: "utility:edit" },
		{ label: "Clone", name: "clone", iconName: "utility:copy" }]);
	}

	getRowActions(row, doneCallback) {
		if (row.blnIsActive === true) {
			doneCallback([{ label: "Deactivate", name: "deactivate", iconName: "utility:block_visitor" },
			]);
		}
		if (row.blnIsActive === false) {
			doneCallback([{ label: "Activate", name: "activate", iconName: "utility:adduser" }]);
		}
	}

	//setting css style
	renderedCallback() {
		if (!this.isRendered) {
			Promise.all([loadStyle(this, WrappedHeaderTable)])
				.then(() => {
					this.isRendered = true;
				})
				.catch((error) => {
					console.error("Error loading custom styles");
				});
		}
	}

	/**This method handles existing Resource Skills record query onPageLoad and based on filters*/
	getResourceSkills() {
		this.handleIsLoading(true);

		fetchWrapperData({
			strResourceFilter: this.strSelectedResourceIds?.toString(),
			strAgencyFilter: this.strSelectedAgencyNames?.toString(),
			strOrderBy: this.strSortedBy,
			strOrderByDirection: this.strSortedDirection,
			intLimitSize: this.rowLimit,
			intOffset: this.rowOffSet,
			strDebitCreditFilter: this.strSelectedDebitCredit?.toString(),
			strTierFilter: this.strSelectedTier?.toString()
		})
			.then((result) => {
				if (result) {
					this.data = result.list_UserSkillWrapper;
					this.visibleData = this.data?.slice(0, this.intScrollSize); // display the first 10 items

					this.map_ResourceNameId = new Map();
					let list_AgencyOptions = [];
					let listTempResource = [];
					let listTempResourceOptions = [];
					let list_DebitCreditOpts = [];
					let list_TierOpts = [];
					result.list_AgentNameId.forEach((objResource) => {
						let list_temp = objResource.split("#");
						this.map_ResourceNameId.set(list_temp[0], list_temp[1]);
						listTempResource.push(list_temp[0]);
						listTempResourceOptions.push({ label: list_temp[0], value: list_temp[1] });
					});
					this.list_ResourceNameMaster = listTempResource;
					this.list_ResourceNameFiltered = listTempResourceOptions;

					result.list_AgencyNameAbbreviations.forEach((objAgency) => {
						let list_temp = objAgency.split("#");
						list_AgencyOptions.push({ label: list_temp[0], value: list_temp[1] });
					});

					this.intTotalRecordCount = result.intTotalRecords;
					this.strReportId = result.strReportId;

					this.list_AgencyNameOptions = list_AgencyOptions;
					this.blnIsAgencyFound = true;
				} else {
					this.showMessage("Info!", "Not able to found any records.", "info", null);
				}

			})
			.catch((error) => {
				this.handleIsLoading(false);
				var strErrorMessage = error?.body?.message ? error?.body?.message : error;
				this.showMessage("Error while retrieving skills!", strErrorMessage, "error", null);
			})
			.finally(() => {
				this.handleIsLoading(false);
			});
	}

	/**This method is called when user selects "Show all skills" row action*/
	getAllSkills() {
		this.handleIsLoading(true);

		getAllSkillsForUserRoleAgency({
			strUniqueIndetifier: this.strSelectAgencyRowId,
			strType: ''
		})
			.then((result) => {
				if (result) {
					this.userSkillsData = result;
					this.blnShowAgencySkills = true;
				} else {
					this.showMessage("Info!", "Not able to found any user skills.", "info", null);
				}
			})
			.catch((error) => {
				this.handleIsLoading(false);
				var strErrorMessage = error?.body?.message ? error?.body?.message : error;
				this.showMessage("Error while retrieving user skills!", strErrorMessage, "error", null);
			})
			.finally(() => {
				this.handleIsLoading(false);
			});
	}


	//handle sort event on table
	handleColumnSort(event) {
		this.strSortedBy = event.detail.fieldName;
		this.strSortedDirection = event.detail.sortDirection;
		this.resetDataTableVariables();
		this.getResourceSkills();
	}

	//utility method to clear out data array
	resetDataTableVariables() {
		this.visibleData = [];
		this.data = [];
	}

	/**Lazy loading start */
	loadMoreData(event) {
		if (this.visibleData.length < DEFAULT_ROW_LIMIT && this.data.length > this.visibleData.length) {
			const currentLength = this.visibleData.length;
			const nextSet = this.data.slice(currentLength, currentLength + this.intScrollSize);
			this.visibleData = [...this.visibleData, ...nextSet];
		}
	}

	// Methods related to filtering data
	handleFilterList(event) {
		let value = event.detail ?? "";
		this.list_ResourceNameFiltered = this.list_ResourceNameMaster.filter(function (eachQueue) {
			return eachQueue.toLowerCase().indexOf(value.toLowerCase()) !== -1;
		});
	}

	/**dataTable agency filters change handler method */
	handleFilterSelected(event) {
		this.handleIsLoading(true);
		let oldResourceVal = this.strSelectedResourceIds;
		if (!event.detail || !this.map_ResourceNameId.has(event.detail)) {
			this.strSelectedResourceName = "";
			this.strSelectedResourceIds = "";
		} else if (this.map_ResourceNameId.has(event.detail)) {
			this.strSelectedResourceName = event.detail;
			this.strSelectedResourceIds = this.map_ResourceNameId.get(event.detail);
		}

		if (oldResourceVal !== this.strSelectedResourceIds) {
			this.resetDataTableVariables();
			this.getResourceSkills();
		}
	}

	/**dataTable agency filters change handler method */
	handleFilterChange(event) {
		let blnHasFilterChanged = false;
		this.handleIsLoading(true);
		if (event.target.name == "agencyFilter") {
			this.strSelectedAgencyNames = event.detail.value;
			blnHasFilterChanged = true;
		}

		if (blnHasFilterChanged) {
			this.resetDataTableVariables();
			this.getResourceSkills();
		}

		this.handleIsLoading(false);
	}

	/**Existing Resource Skills delete event handling method*/
	handleRowAction(event) {
		const actionName = event.detail.action.name;
		const row = event.detail.row;
		this.blnIsEditSkill = false;

		if (actionName === "activate") {
			this.strToActivateSkillIds = row.strUniqueId;
		} else if (actionName === "deactivate") {
			this.strToDeactivateSkillIds = row.strUniqueId;
		} else if (actionName === "allSkills" || actionName === "edit" || actionName === "clone") {
			this.strSelectAgencyRowId = row.strUniqueId;
		}

		if (actionName === "activate" || actionName === "deactivate") {
			this.handleDMLActions();
		} else if (actionName === "allSkills") {
			this.getAllSkills();
		} else if (actionName === "edit" || actionName === "clone") {
			if (actionName === 'edit') {
				this.blnIsEditSkill = true;
				this.objEditedRow = row;
			}
			this.strActionType = actionName;
			this.handleEditClone(actionName);
		}
	}

	/*Handle Resource Skills Table Row Selection*/
	handleResourceRowSelection(event) {
		this.list_ToBeDeletedRecordIds = [];
		const selectedRows = event.detail.selectedRows;
		for (let i = 0; i < selectedRows.length; i++) {
			this.list_ToBeDeletedRecordIds.push(selectedRows[i].strUniqueId);
		}

		this.blnRowsSelectedForDeletion = this.list_ToBeDeletedRecordIds.length > 0 ? true : false;
	}

	/*called when user selects edit/clone row action, in this method we are getting 
	all the user skills for the selected user*/
	handleEditClone(strType) {
		this.handleIsLoading(true);
		getAllSkillsForUserRoleAgency({
			strUniqueIndetifier: this.strSelectAgencyRowId,
			strType: strType
		})
			.then((result) => {
				if (result) {
					this.newData = result;
					this.newData.forEach((objData) => {
						this.list_EditAgencies = [];
						objData.selectedTiers = objData.strTier ? objData.strTier.split(",") : ["NA"];
						objData.selectedPartnerTiers = objData.strPartnerTier ? objData.strPartnerTier.split(",") : ["NA"];
						objData.selectedNoticeTypes = objData.strNoticeType.split(",");
						objData.selectedDebitTypes = objData.strDebitCredit.split(",");

						if (strType == 'clone') {
							let randomId = Math.random() * 16;
							objData.strAgentName = '';
							objData.strUniqueId = randomId;
						}
					});
					this.agencyRecord = true;
					this.blnAddNewRows = true;
				} else {
					this.showMessage("Info!", "Not able to found any user skills.", "info", null);
				}
			})
			.catch((error) => {
				this.handleIsLoading(false);
				var strErrorMessage = error?.body?.message ? error?.body?.message : error;
				this.showMessage("Error while retrieving user skills!", strErrorMessage, "error", null);
			})
			.finally(() => {
				this.handleIsLoading(false);
			});
	}

	/**Add new skills panel related methods ------ Start--- */
	addRow() {
		this.handleIsLoading(true);
		this.selectedValueList = [];
		this.blnAddNewRows = true;
		let randomId = Math.random() * 16;
		let myNewElement = {
			strUniqueId: randomId.toString(),
			strAgentId: "",
			strAgentName: this.objEditedRow.strAgentId,
			strBAgentName: "",
			strAgencyName: "",
			strAgencyComplexity: "",
			strNoticeType: "",
			strFormNumberComplexity: "",
			strDebitCredit: "",
			strThreshold: "",
			strTier: "",
			strPartnerTier: "",
			strMultiYear: "",
			selectedDebitTypes: [],
			selectedTiers: [],
			selectedPartnerTiers: [],
			selectedNoticeTypes: []
		};

		if (this.newData) {
			this.newData = [...this.newData, myNewElement];
		} else {
			this.newData = [myNewElement];
		}
		this.handleIsLoading(false);
	}

	//responsible to close the popup dialogue box
	closeAddRow() {
		this.blnAddNewRows = false;
		this.selectedValueList = [];
		this.selectedDebitTypes = [];
		this.selectedNoticeTypes = [];
		this.selectedPartnerTiers = [];
		this.selectedTiers = [];
		this.newData = [];
		this.strActionType = '';
		this.blnIsEditSkill = false;
		this.objEditedRow = '';
	}

	closeAgencySkills() {
		this.blnShowAgencySkills = false;
		this.userSkillsData = [];
		this.blnRowsSelectedForDeletion = false;
	}

	//responsible to delete individual rows in the popup dialogue box
	deleteRow(event) {
		this.newData.splice(
			this.newData.findIndex((row) => row.strUniqueId === event.target.dataset.id.toString()),
			1
		);
	}

	//get agency record to retrieve Agency Complexity
	@wire(getRecord, { recordId: "$userSelectedAgencyId", fields: "$fields" })
	wiredRecord({ error, data }) {
		if (data) {
			this.agencyRecord = data;
			var foundelement = this.newData.find((ele) => ele.strUniqueId === this.changedAgencyRowUniqueId);
			foundelement.strAgencyComplexity = this.agencyComplexity;
		} else if (error) {
			console.log('~~!! getAgencyRecord Error>' + error);
		}
	}

	//return Agency_Complexity__c field value related to selected agency in the popup dialogue box
	get agencyComplexity() {
		return getFieldValue(this.agencyRecord, "Agency_Information__c.Agency_Complexity__c");
	}
	/**Add new skills panel related methods ------ End--- */

	//show/hide spinner
	handleIsLoading(blnIsLoading) {
		this.blnIsLoading = blnIsLoading;
	}

	//handle save and process dml, called on click of save button from "add row" page
	handleDMLActions(event) {
		let strDeleteServiceSkillIds = "";
		this.handleIsLoading(true);

		if (event?.target?.name === DELETE_BTN) {
			if (this.list_ToBeDeletedRecordIds?.length > 0) {
				strDeleteServiceSkillIds = this.list_ToBeDeletedRecordIds.toString();
			} else {
				this.showMessage("Error!", MSG_DELETE_SELECT_ALTEAST_ONE_ROW, "error", null);
				this.handleIsLoading(false);
				return;
			}
		}

		let blnIsError = false;
		if (event?.target?.name === SAVE_BTN) {
			if (!this.newData || this.newData?.length === 0) {
				this.showMessage("Error!", MSG_SAVE_NEED_ATLEAST_ONE_ROW, "error", null);
				this.handleIsLoading(false);
				return;
			}

			let blnIsTierPartnerBothPopulated = false;
			let blnIsBothNA = false;
			let blnIsContainsInvalidNA = false;
			this.newData.forEach((objData) => {
				if (this.checkFields(objData)) {
					this.showMessage("Error!", "Please fill all the required fields", "error", null);
					this.handleIsLoading(false);
					blnIsError = true;
					return;
				}

				if (objData.strTier && objData.strPartnerTier && objData.strTier != "NA" && objData.strPartnerTier != "NA") {
					blnIsTierPartnerBothPopulated = true;
					blnIsError = true;
					return;
				}

				//null check in tier and partner tier fields
				if ((!objData.strTier || objData.strTier === "NA") && (!objData.strPartnerTier || objData.strPartnerTier === "NA")) {
					blnIsBothNA = true;
					blnIsError = true;
					return;
				}

				if ((objData.strTier && objData.strTier.indexOf(';') > -1 && objData.strTier.indexOf('NA') > -1) ||
					(objData.strPartnerTier && objData.strPartnerTier.indexOf(';') > -1 && objData.strPartnerTier.indexOf('NA') > -1)) {
					blnIsContainsInvalidNA = true;
					blnIsError = true;
				}
			});

			if (blnIsTierPartnerBothPopulated) {
				this.showMessage("Error!", ERROR_MSG_BOTH_CAN_NOT_BE_FILLED, "error", null);
				this.handleIsLoading(false);
				return;
			}

			//Error Message: positive null in tier and partner tier fields
			if (blnIsBothNA) {
				this.showMessage("Error!", ERROR_MSG_BOTH_CAN_NOT_BE_NULL, "error", null);
				this.handleIsLoading(false);
				return;
			}

			//Error Message: positive null in tier and partner tier fields
			if (blnIsContainsInvalidNA) {
				this.showMessage("Error!", ERROR_MSG_INVALID_VALUE_NA, "error", null);
				this.handleIsLoading(false);
				return;
			}
		}

		if (!blnIsError) {
			dmlOnServiceSkills({
				objNewSkillsJson: this.newData,
				strRemoveSkillIds: strDeleteServiceSkillIds,
				strActivateSkillIds: this.strToActivateSkillIds,
				strDeactivateSkillIds: this.strToDeactivateSkillIds,
				strType: this.strActionType
			})
				.then((result) => {
					this.handleIsLoading(false);
					this.showMessage("Success!", result, "success", null);
					this.getResourceSkills();
					if (this.strToActivateSkillIds || this.strToDeactivateSkillIds) {
						this.getAllSkills();
					}
				})
				.catch((error) => {
					this.handleIsLoading(false);
					var strErrorMessage = error?.body?.message ? error?.body?.message : error;
					this.showMessage("Error updating or refreshing records!", strErrorMessage, "error", null);
				})
				.finally(() => {
					this.closeAddRow();
					if (!this.strToActivateSkillIds && !this.strToDeactivateSkillIds) {
						this.closeAgencySkills();
					}
					this.strToActivateSkillIds = "";
					this.strToDeactivateSkillIds = "";
					this.handleIsLoading(false);
				});
		}
	}

	//update table row values in list, change event handler for "Add row" page
	updateValues(event) {
		var foundelement = this.newData.find((ele) => ele.strUniqueId == event.target.dataset.id);

		if (event.target.name === "strAgentName") {
			foundelement.strAgentName = event.target.value?.toString();
		} else if (event.target.name === "strBAgentName") {
			foundelement.strBAgentName = event.target.value?.toString();
		} else if (event.target.name === "strAgencyName") {
			foundelement.strAgencyName = event.detail;
			this.userSelectedAgencyId = "";
			this.userSelectedAgencyId = event.detail;
			this.changedAgencyRowUniqueId = event.target.dataset.id;
		} else if (event.target.name === "strNoticeType") {
			foundelement.strNoticeType = event.detail?.toString();
			foundelement.selectedNoticeTypes = event.detail;
		} else if (event.target.name === "strFormNumberComplexity") {
			foundelement.strFormNumberComplexity = event.target.value;
		} else if (event.target.name === "strDebitCredit") {
			foundelement.strDebitCredit = event.detail?.toString();
			foundelement.selectedDebitTypes = event.detail;
		} else if (event.target.name === "strThreshold") {
			foundelement.strThreshold = event.target.value;
		} else if (event.target.name === "strTier") {
			if(event.detail?.includes('NA')){
				event.detail.splice(event.detail.indexOf('NA'), 1);
			}
			foundelement.strTier = event.detail?.toString();
			foundelement.selectedTiers = event.detail;
		} else if (event.target.name === "strPartnerTier") {
			if(event.detail?.includes('NA')){
				event.detail.splice(event.detail.indexOf('NA'), 1);
			}
			foundelement.strPartnerTier = event.detail ? event.detail?.toString() : "NA";
			foundelement.selectedPartnerTiers = event.detail;
		} else if (event.target.name === "strMultiYear") {
			foundelement.strMultiYear = event.target.value;
		}

		//agent cannot be its own backup
		if (foundelement.strAgentName && foundelement.strBAgentName && foundelement.strBAgentName === foundelement.strAgentName) {
			this.showMessage("Error!", AGENT_BACKUP_SAME_MSG, "warning");
		} else {
			map_UpdatedWrapperRecords.set(foundelement.strUniqueId, foundelement);
		}
	}

	//for multiselect picklist
	handleSelectOptionList(event) {
		this.selectedValueList = event.detail;
		if (event?.target?.name === "agencyFilter") {
			this.strSelectedAgencyNames = event.detail;
		} else if (event?.target?.name === "resourceFilter") {
			this.strSelectedResourceIds = event.detail;
		} else if (event?.target?.name === "debitCreditFilter") {
			this.strSelectedDebitCredit = event.detail;
		} else if (event?.target?.name === "tierFilter") {
			this.strSelectedTier = event.detail;
		}

		this.resetDataTableVariables();
		this.getResourceSkills();
	}

	// called on click of "Report will all skills"
	openReport(event) {
		if (this.strReportId) {
			const recordNavigation = new CustomEvent("OpenReport", {
				detail: {
					idReport: this.strReportId
				}
			});
			this.dispatchEvent(recordNavigation);
			this.blnIsLoading = false;
		} else {
			this.showMessage("Error!", 'Report id is not configured.', "warning");
		}
	}

	/* showMessage displays
	 * success, error or warning
	 * messages. depending on the strClassName,
	 * type fo messages will vary.
	 */
	showMessage(strTitle, strMessage, strVariant, strMode) {
		if (strMode === null) {
			strMode = "dismissible";
		}

		const evt = new ShowToastEvent({
			title: strTitle,
			message: strMessage,
			variant: strVariant,
			mode: strMode
		});
		this.dispatchEvent(evt);
	}

	checkFields(objData) {
		let blnError = false;
		let objRows = this.template.querySelectorAll(`.data-validation[data-rowid="${objData.strUniqueId}"]`);
		objRows.forEach(element => {
			if (element.dataset.label === 'Service Resource Name') {
				if (!objData.strAgentName) {
					element.classList.add('show-error');
					blnError = true;
				} else {
					element.classList.remove('show-error');
				}
			} else if (element.dataset.label === 'Backup Resource Name') {
				if (!objData.strBAgentName) {
					element.classList.add('show-error');
					blnError = true;
				} else {
					element.classList.remove('show-error');
				}
			} else if (element.dataset.label === 'Agency Name') {
				if (!objData.strAgencyName) {
					element.classList.add('show-error');
					blnError = true;
				} else {
					element.classList.remove('show-error');
				}
			} else if (element.dataset.label === 'Tax Notice Type') {
				if (!objData.selectedNoticeTypes) {
					element.classList.add('show-error');
					blnError = true;
				} else {
					element.classList.remove('show-error');
				}
			} else if (element.dataset.label === 'Form Number Complexity') {
				if (!objData.strFormNumberComplexity) {
					element.classList.add('show-error');
					blnError = true;
				} else {
					element.classList.remove('show-error');
				}
			} else if (element.dataset.label === 'Debit/Credit') {
				if (!objData.selectedDebitTypes) {
					element.classList.add('show-error');
					blnError = true;
				} else {
					element.classList.remove('show-error');
				}
			} else if (element.dataset.label === '$ Threshold') {
				if (!objData.strThreshold) {
					element.classList.add('show-error');
					blnError = true;
				} else {
					element.classList.remove('show-error');
				}
			} else if (element.dataset.label === 'Multi Year Y/N') {
				if (!objData.strMultiYear) {
					element.classList.add('show-error');
					blnError = true;
				} else {
					element.classList.remove('show-error');
				}
			}
		});

		return blnError;
	}
}