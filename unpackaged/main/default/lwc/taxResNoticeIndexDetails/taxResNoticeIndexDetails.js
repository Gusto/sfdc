import { LightningElement, api, track } from "lwc";
import LightningConfirm from "lightning/confirm";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getCaseDetails from "@salesforce/apex/TaxResNoticeIndexDetailsController.getCaseDetails";
import completeNoticeIndexRecord from "@salesforce/apex/TaxResNoticeIndexDetailsController.completeNoticeIndexRecord";
import getRequiredFields from "@salesforce/apex/TaxResNoticeIndexDetailsController.getRequiredFields";
import getAccountDetails from "@salesforce/apex/TaxResNoticeIndexDetailsController.getAccountDetails";
import getSuiRateFormNumbers from "@salesforce/apex/TaxResNoticeIndexDetailsController.getSuiRateFormNumbers";
import getTaxRatesForAgency from "@salesforce/apex/TaxResNoticeIndexDetailsController.getTaxRatesForAgency";
import syncTaxRateValuesForTNDC from "@salesforce/apex/TaxResNoticeIndexDetailsController.syncTaxRateValuesForTNDC";
import getTaxRatesValuesTNDC from "@salesforce/apex/TaxResNoticeIndexDetailsController.getTaxRatesValuesTNDC";
import SystemModstamp from "@salesforce/schema/Account.SystemModstamp";
import TNDC_Form_Number from "@salesforce/label/c.TNDC_Form_Number";
import Federal_Agencies from "@salesforce/label/c.Federal_Agencies";
import getTaxNoticeTypes from "@salesforce/apex/TaxResNoticeIndexDetailsController.getTaxNoticeTypes";

const COMPLETE_CONFIRMATION = "Do you want to sync the agency details back to Case.";
const COMPLETED_SUCCESSFULLY = "Record successfully completed";
const ERROR_PROCESS = "Not able to process the record.";
const NOTICE_CREATED = "Notice Index created";
const NOTICE_UPDATED = "Notice Index updated";
const REQUIRED_FIELDS_MISSING = "Following fields are required.";
const COMPANY = "Company";
const ELECTRONIC_NOTICE = "Electronic Notice";
const INCORRECT_CASE_STATUS = 'This functionality is only available for "Data Capture in Progress" cases.';

export default class TaxResNoticeIndexDetails extends LightningElement {
	@api recordId;
	@track idNoticeIndexRecord;
	@track objCase;
	@track strCaseAgencyInfo;
	@track strAccountTier;
	@track strAccountId;
	strAccountSegment = "";
	blnCompletedCase = false;
	blnBlankTaxRateValue = false;
	strRequiredFields = "";
	blnIsLoading = false;
	blnIsCompany = true;
	blnFoundIndexRecord = false;
	blnElectronicNotice = false;

	ownerName;
	blnGustoAddressee = false;

	/*Auto Solve variables */
	blnIsNoticeMissing = false;
	blnDisableFields = false;
	list_SuiRateFormNumbers = [];
	suiYrQtr = "";
	suiYrQtrSpecial = "";
	strDefaultSuiYrQtr = "";

	dtDefaultEffectiveDate = "";
	dtEffectiveSpecialDate = "";
	dtEffectiveDate = "";

	decSuiRate = 0;
	strEnteredFormNumber = "";
	selectedSuiRateType = "Decimal";
	isSelectedSuiRateTypeDecimal = true;
	list_TaxRates = [];
	strSelectedSuiRateTypeId = "";
	blnIsNoticeDueDateNotPopulated = true;
	blnDisableNoticeDueDate = true;
	blnIsSatusDataCaptureInProgress = false;
	strRAFVal = "";

	//both the variables needs to be true for a valid "sui rate" scenario
	blnDisplaySuiRateFields = false;
	blnIsTaxRateAvailable = false;
	blnZeroTaxRateValues = false;
	list_TNDCSuiRate = [];

	selectedNoticeType = "";
	list_TaxNoticeTypes = [];

	get suiRateOptions() {
		return [
			{ label: "Percentage", value: "Percentage" },
			{ label: "Decimal", value: "Decimal" }
		];
	}

	connectedCallback() {
		let strYear = new Date().getFullYear() + 1;
		this.strDefaultSuiYrQtr = "Q1 " + strYear;
		this.suiYrQtr = this.strDefaultSuiYrQtr;
		this.suiYrQtrSpecial = "Q3 " + strYear;

		this.dtDefaultEffectiveDate = strYear + "-01-01";
		this.dtEffectiveSpecialDate = strYear + "-07-01";
		this.dtEffectiveDate = this.dtDefaultEffectiveDate;

		this.getDetails();
	}

	async getDetails() {
		await this.getRelatedCaseDetails();
		await this.getRequiredFieldsInfo();
	}

	//retrieve case details on page load
	getRelatedCaseDetails() {
		getCaseDetails({
			strCaseId: this.recordId
		})
			.then((result) => {
				if (result) {
					let agencySuiFormNumbers = "";
					this.objCase = result;
					this.ownerName = result.Owner.Name;
					this.blnFoundIndexRecord = true;
					if (result.Tax_Notice_Indexs__r && result.Tax_Notice_Indexs__r.length > 0 && result.Tax_Notice_Indexs__r[0].Id) {
						this.idNoticeIndexRecord = result.Tax_Notice_Indexs__r[0].Id;
						this.blnIsNoticeMissing = result.Tax_Notice_Indexs__r[0].No_Notice_Attached__c;
						this.blnDisableFields = this.blnIsNoticeMissing;
						this.strEnteredFormNumber = result.Tax_Notice_Indexs__r[0].Tax_Notice_Form_Number__c;
						this.suiYrQtr = result.Tax_Notice_Indexs__r[0].Yr_Qtr__c;
						this.dtEffectiveDate = result.Tax_Notice_Indexs__r[0].SUI_Rate_Effective_Date__c;
						this.blnGustoAddressee = result.Tax_Notice_Indexs__r[0].Gusto_is_addressee_of_record__c;
						this.strRAFVal = result.Tax_Notice_Indexs__r[0].RAF_Indicator__c;
						if (result.Tax_Notice_Indexs__r[0].Tax_Notice_Due_Date__c) {
							this.blnIsNoticeDueDateNotPopulated = false;
						}
					} else {
						this.idNoticeIndexRecord = null;
						this.blnGustoAddressee = result.Physical_Mail__c;
						if (result.Origin === ELECTRONIC_NOTICE) {
							this.blnElectronicNotice = true;
						}
					}

					if (!this.idNoticeIndexRecord) {
						this.strCaseAgencyInfo = result.Agency_Information__c;
						this.strAccountSegment = result.AccountId ? result.Account.RecordType.Name : "";
						this.strAccountId = result.AccountId;
						agencySuiFormNumbers = result.Agency_Information__r?.SUI_Rate_Form_Numbers__c;

						if (result.Account.RecordType.Name === COMPANY) {
							this.strAccountTier = result.Account?.Tier__c;
							this.blnIsCompany = true;
						} else {
							this.strAccountTier = result.Account?.AM_Tier__c;
							this.blnIsCompany = false;
						}
					} else {
						this.strCaseAgencyInfo = result.Tax_Notice_Indexs__r[0]?.Agency_Information__c;
						this.strAccountId = result.Tax_Notice_Indexs__r[0].Client_Name__c;
						agencySuiFormNumbers = result.Tax_Notice_Indexs__r[0].Agency_Information__r?.SUI_Rate_Form_Numbers__c;

						if (result.Tax_Notice_Indexs__r[0].Segment__c) {
							this.strAccountSegment = result.Tax_Notice_Indexs__r[0].Segment__c;
						} else {
							this.strAccountSegment = result.AccountId ? result.Account.RecordType.Name : "";
						}

						if (this.strAccountId && result.Tax_Notice_Indexs__r[0].Client_Name__r?.RecordType.Name === COMPANY) {
							this.strAccountTier = result.Tax_Notice_Indexs__r[0].Tier__c ? result.Tax_Notice_Indexs__r[0].Tier__c : result.Account.Tier__c;
							this.blnIsCompany = true;
						} else {
							this.strAccountTier = result.Tax_Notice_Indexs__r[0].Partner_Tier__c ? result.Tax_Notice_Indexs__r[0].Partner_Tier__c : result.Account?.AM_Tier__c;
							this.blnIsCompany = false;
						}
						this.selectedNoticeType = result.Tax_Notice_Indexs__r[0].Tax_Notice_Type__c;
					}

					if (this.objCase.Status === "Data Capture in Progress") {
						this.blnIsSatusDataCaptureInProgress = true;
					}

					this.parseFormNumbers(agencySuiFormNumbers);
					this.getTaxRates();
					this.getTaxNoticeType();
				}
			})
			.catch((error) => {
				let errorMessage = "";
				errorMessage = error?.body ? error.body?.message : error?.message;
				errorMessage = errorMessage ? errorMessage : "Error while retrieving Case details";
				this.showMessage("Error!", errorMessage, "error", null);
			})
			.finally(() => {
				this.blnIsLoading = false;
				if (!this.idNoticeIndexRecord) {
					this.handleRAFAutomation();
				}
			});
	}

	//retrieve comma separated field api names
	getRequiredFieldsInfo() {
		getRequiredFields()
			.then((result) => {
				if (result) {
					this.strRequiredFields = result;
				}
			})
			.catch((error) => {
				let errorMessage = error;
				if (error.body && error.body.message) {
					errorMessage = error.body.message;
				}

				errorMessage = errorMessage ? errorMessage : "Error while retrieving required field details.";
				this.showMessage("Error!", errorMessage, "error", null);
			})
			.finally(() => {
				this.blnIsLoading = false;
				if (!this.idNoticeIndexRecord) {
					this.handleRAFAutomation();
				}
			});
	}

	//retrieve semi-colon separated form numbers
	getEligibleSuiRateFormNumbers() {
		this.list_SuiRateFormNumbers = [];
		getSuiRateFormNumbers({
			strAgencyId: this.strCaseAgencyInfo
		})
			.then((result) => {
				if (result) {
					this.parseFormNumbers(result);
					this.getTaxRates();
				}
			})
			.catch((error) => {
				let errorMessage = error;
				if (error.body && error.body.message) {
					errorMessage = error.body.message;
				}
				errorMessage = errorMessage ? errorMessage : "Error while retrieving eligible sui rate form numbers.";
				this.showMessage("Error!", errorMessage, "error", null);
			})
			.finally(() => {
				this.blnIsLoading = false;
			});
	}

	parseFormNumbers(strFormNumbers) {
		let listTemp = [];
		this.list_SuiRateFormNumbers = [];
		strFormNumbers
			?.toString()
			.split(";")
			.forEach((element) => {
				if (element) {
					listTemp = [...listTemp, element.trim()];
				}
			});

		this.list_SuiRateFormNumbers = listTemp;
		if (this.strEnteredFormNumber && this.list_SuiRateFormNumbers && this.list_SuiRateFormNumbers.length > 0 && this.list_SuiRateFormNumbers.indexOf(this.strEnteredFormNumber) > -1) {
			this.blnDisplaySuiRateFields = true;
		} else {
			this.blnDisplaySuiRateFields = false;
		}
	}

	getTaxRates() {
		this.list_TaxRates = [];
		this.blnIsTaxRateAvailable = false;
		getTaxRatesForAgency({
			strAgencyId: this.strCaseAgencyInfo,
			strTNDCId: this.idNoticeIndexRecord
		})
			.then((result) => {
				if (result) {
					this.list_TaxRates = [];
					result.forEach((objTaxRate) => {
						let ojbTaxRate = {};
						ojbTaxRate.label = objTaxRate.Name;
						ojbTaxRate.value = objTaxRate.Id;
						if (objTaxRate.Tax_Rate_Values__r?.length > 0) {
							ojbTaxRate.decSuiRate = objTaxRate.Tax_Rate_Values__r[0].Rate_Decimal__c;
						}
						this.list_TaxRates = [...this.list_TaxRates, ojbTaxRate];
					});
					if (this.list_TaxRates?.length > 0) {
						this.blnIsTaxRateAvailable = true;
						this.strSelectedSuiRateTypeId = this.list_TaxRates[0].value;
					} else {
						this.blnIsTaxRateAvailable = false;
					}
				}
			})
			.catch((error) => {
				let errorMessage = "Error while retrieving Tax Rate related Agency.";
				if (error.body && error.body.message) {
					errorMessage = error.body.message;
				}
				this.showMessage("Error!", errorMessage, "error", null);
			})
			.finally(() => {
				this.blnIsLoading = false;
			});
	}

	//Handle event for Tax rate
	handelSuiRateChange(event) {
		this.list_TaxRates.forEach((objTaxVal) => {
			if (event.target.dataset.rowId == objTaxVal.value) {
				objTaxVal.decSuiRate = event.target.value;
			}
		});
	}

	//handle "Submit" event on button click
	handleSubmit(event) {
		this.blnIsLoading = true;
		this.blnBlankTaxRateValue = true;
		this.blnZeroTaxRateValues = false;
		event.preventDefault(); // stop the form from submitting
		if (this.list_TaxRates.length > 0 && this.blnDisplaySuiRateFields) {
			this.list_TaxRates.forEach((objTaxVal) => {
				if (objTaxVal.decSuiRate == null || objTaxVal.decSuiRate == "") {
					this.blnBlankTaxRateValue = false;
				}
				if (objTaxVal.decSuiRate == 0) {
					this.blnZeroTaxRateValues = true;
				}
			});

			if (!this.blnBlankTaxRateValue) {
				this.showMessage("Error", "Tax rate values should not be blank", "error", "sticky");
				this.blnIsLoading = false;
				return;
			}

			if (this.blnZeroTaxRateValues) {
				var blnConfirm = confirm("Are you sure about the tax rate value being 0");
				if (blnConfirm == false) {
					this.blnIsLoading = false;
					return;
				}
			}
		}

		const fields = event.detail.fields;
		// modify fields
		fields.No_Notice_Attached__c = this.blnIsNoticeMissing;
		fields.Case__c = this.recordId;
		fields.Segment__c = this.strAccountSegment;
		fields.Gusto_is_addressee_of_record__c = this.blnGustoAddressee;
		//update fields based on related account type
		fields.Tax_Notice_Form_Number__c = fields.Tax_Notice_Form_Number__c?.toUpperCase();
		fields.SUI_Rate_Effective_Date__c = this.dtEffectiveDate;
		fields.Agency_Information__c = this.strCaseAgencyInfo;
		fields.RAF_Indicator__c = this.strRAFVal;
		if (this.blnIsNoticeDueDateNotPopulated) {
			fields.Tax_Notice_Due_Date__c = null;
		}

		if (this.blnIsCompany) {
			fields.Tier__c = this.strAccountTier;
			fields.Partner_Tier__c = null;
		} else {
			fields.Partner_Tier__c = this.strAccountTier;
			fields.Tier__c = null;
		}

		if (!(this.blnDisplaySuiRateFields && this.blnIsTaxRateAvailable)) {
			fields.SUI_Rate_Effective_Date__c = null;
		} else {
			fields.Yr_Qtr__c = this.suiYrQtr;
		}

		//update checkbox for manual indexing
		fields.Manually_Indexed__c = true;

		fields.Tax_Notice_Type__c = this.selectedNoticeType;

		let emptyRequiredFields = "";
		if (this.blnCompletedCase && !this.blnIsNoticeMissing) {
			let fieldsAPIs = this.strRequiredFields.split(",");
			fieldsAPIs.forEach((strApiName) => {
				if (strApiName && (!fields[strApiName] || fields[strApiName]?.length == 0 || fields[strApiName] == "")) {
					/*
					1. skip "partner tier" field if related account is company
					2. skip "tier" field if related account is reseller
					3. skip "sui rate" fields if form number does no matches
					*/
					if (
						(this.blnIsCompany && strApiName === "Partner_Tier__c") ||
						(!this.blnIsCompany && strApiName === "Tier__c") ||
						(!this.blnDisplaySuiRateFields && !this.blnIsTaxRateAvailable && (strApiName === "SUI_ER_Rate__c" || strApiName === "SUI_Rate_Effective_Date__c"))
					) {
						return;
					}

					if (this.blnDisplaySuiRateFields && this.blnIsTaxRateAvailable && this.decSuiRate > 0 && strApiName === "SUI_ER_Rate__c") {
						return;
					}

					if (strApiName == "Tax_Notice_Amount_Total__c") {
						if (fields[strApiName] === 0) {
							return;
						} else {
							strApiName = "Total_Amount_Due__c";
						}
					}

					if (strApiName == "Tax_Notice_Tax_Amount__c") {
						if (fields[strApiName] === 0) {
							return;
						} else {
							strApiName = "Tax_Amount_Due__c";
						}
					}

					if (strApiName == "Penalty_Amount_Due__c") {
						if (fields[strApiName] === 0) {
							return;
						}
					}

					if (strApiName == "Interest_Amount_Due__c") {
						if (fields[strApiName] === 0) {
							return;
						}
					}

					if (strApiName === "Tax_Notice_Due_Date__c" && this.blnIsNoticeDueDateNotPopulated) {
						return;
					}

					emptyRequiredFields += strApiName.replace("__c", "").replace(/_/gi, " ") + ", ";
				}
			});
		}

		if (!emptyRequiredFields) {
			this.template.querySelector("lightning-record-edit-form").submit(fields);
		} else {
			this.showMessage(REQUIRED_FIELDS_MISSING, emptyRequiredFields, "warning", "sticky");
			this.blnCompletedCase = false;
			this.blnIsLoading = false;
		}
	}

	//handle "Success" event of "Submit" event on button click
	handleSuccess(event) {
		let strMsg;
		if (this.idNoticeIndexRecord) {
			strMsg = NOTICE_UPDATED;
		} else {
			this.idNoticeIndexRecord = event.detail.id;
			strMsg = NOTICE_CREATED;
		}

		if (this.blnDisplaySuiRateFields && this.blnIsTaxRateAvailable) {
			this.manageTaxRateValueRecords();
		}

		if (this.blnCompletedCase) {
			this.completeCase();
		} else {
			this.showMessage(strMsg, "Record ID: " + event.detail.id, "success", null);
			this.blnIsLoading = false;
		}
	}

	//handle "onclick" event of "Complete" button
	handleComplete(event) {
		this.blnCompletedCase = true;
	}

	//Calls apex method to process "Complete" logic for open case
	completeCase() {
		this.blnIsLoading = true;
		let list_CaseId = [];
		list_CaseId.push(this.recordId);
		completeNoticeIndexRecord({
			list_CaseRecordId: list_CaseId
		})
			.then((result) => {
				let strMsg;
				if (result) {
					strMsg = COMPLETED_SUCCESSFULLY;
					this.showMessage("Success!", strMsg, "success", null);
				} else {
					strMsg = ERROR_PROCESS;
					this.showMessage("Error!", strMsg, "error", "sticky");
				}
			})
			.catch((error) => {
				let errorMessage = ERROR_PROCESS;
				if (error.body && error.body.message) {
					errorMessage = error.body.message;
				}
				this.showMessage("Error!", errorMessage, "error", "sticky");
			})
			.finally(() => {
				this.blnIsLoading = false;
				this.blnCompletedCase = false;
			});
	}

	//Calls apex method to process "Complete" logic for open case
	manageTaxRateValueRecords() {
		this.blnIsLoading = true;
		this.list_TNDCSuiRate = [];
		if (this.selectedSuiRateType === "Percentage") {
			this.list_TaxRates.forEach((objTaxVal) => {
				if (objTaxVal.decSuiRate != null) {
					let decSuiRateTemp = objTaxVal.decSuiRate / 100;
					decSuiRateTemp = decSuiRateTemp.toFixed(10);
					this.list_TNDCSuiRate.push(objTaxVal.value + "=>" + decSuiRateTemp);
				}
			});
		} else {
			this.list_TaxRates.forEach((objTaxVal) => {
				if (objTaxVal.decSuiRate != null) {
					this.list_TNDCSuiRate.push(objTaxVal.value + "=>" + objTaxVal.decSuiRate);
				}
			});
		}

		syncTaxRateValuesForTNDC({
			strTNDCId: this.idNoticeIndexRecord,
			list_TaxRateValues: this.list_TNDCSuiRate
		})
			.then((result) => {})
			.catch((error) => {
				let errorMessage = error;
				if (error.body && error.body.message) {
					errorMessage = error.body.message;
				}
				errorMessage = errorMessage ? errorMessage : "Error while retrieving Tax Rate Value records.";
				this.showMessage("Error!", errorMessage, "error", "sticky");
			})
			.finally(() => {
				this.blnIsLoading = false;
				this.blnCompletedCase = false;
			});
	}

	//handle account change event on page
	handleAccountChange(event) {
		if (event.detail && event.detail.value) {
			this.getAccountInfo(event.detail.value.toString());
			this.strAccountId = event.detail.value.toString();
		}
	}

	//on account change gets the new account field info
	getAccountInfo(strAccountIdTemp) {
		this.blnIsLoading = true;
		getAccountDetails({
			strAccountId: strAccountIdTemp
		})
			.then((result) => {
				if (result) {
					this.strAccountSegment = result.RecordType.Name;
					if (result.RecordType.Name === COMPANY) {
						this.strAccountTier = result.Tier__c;
						this.blnIsCompany = true;
					} else {
						this.strAccountTier = result.AM_Tier__c;
						this.blnIsCompany = false;
					}
				}
			})
			.catch((error) => {
				let errorMessage = error;
				if (error.body && error.body.message) {
					errorMessage = error.body.message;
				}
				errorMessage = errorMessage ? errorMessage : "Error while retrieving account information";
				this.showMessage("Error!", errorMessage, "error", "sticky");
			})
			.finally(() => {
				this.blnIsLoading = false;
			});
	}

	handleEvent(event) {
		if (event.target.name === "noticeMissing") {
			this.blnIsNoticeMissing = event.target.checked;
			this.blnDisableFields = this.blnIsNoticeMissing;
		}

		if (event.target.dataset.id === "rafIndicator") {
			this.strRAFVal = event.target.value;
		}

		if (event.target.dataset.id === "gustoAddressee") {
			this.blnGustoAddressee = event.target.value;
			this.handleRAFAutomation();
		}

		if (event.target.dataset.id === "formNumber") {
			this.strEnteredFormNumber = event.target.value;
			if (this.list_SuiRateFormNumbers.length > 0) {
				if (this.strEnteredFormNumber && this.list_SuiRateFormNumbers.indexOf(this.strEnteredFormNumber) > -1) {
					this.blnDisplaySuiRateFields = true;
					this.dtEffectiveDate = this.dtDefaultEffectiveDate;
					this.suiYrQtr = this.strDefaultSuiYrQtr;
					if (TNDC_Form_Number.indexOf(this.strEnteredFormNumber) > -1) {
						this.dtEffectiveDate = this.dtEffectiveSpecialDate;
						this.suiYrQtr = this.suiYrQtrSpecial;
					}
					if (this.list_TaxRates.length == 0) {
						this.getTaxRates();
					}
				} else {
					this.blnDisplaySuiRateFields = false;
				}
			} else {
				this.getEligibleSuiRateFormNumbers();
			}
		}

		if (event.target.dataset.id === "suiRate") {
			this.decSuiRate = event.target.value;
		}

		if (event.target.dataset.id === "suiDate" && event.target.value) {
			let quarter = Math.ceil(event.target.value.split("-")[1].trim() / 3);
			let yrQtr = "Q" + quarter + " " + event.target.value.split("-")[0].trim();
			this.suiYrQtr = yrQtr;
		}

		if (event.target.dataset.id === "suiRateType") {
			this.selectedSuiRateType = event.target.value;
			if (this.selectedSuiRateType === "Decimal") {
				this.isSelectedSuiRateTypeDecimal = true;
				this.list_TaxRates.forEach((objTaxVal) => {
					if (objTaxVal.decSuiRate != "" && objTaxVal.decSuiRate != undefined) {
						objTaxVal.decSuiRate = objTaxVal.decSuiRate / 100;
						objTaxVal.decSuiRate = objTaxVal.decSuiRate.toFixed(10);
					}
				});
			} else {
				this.isSelectedSuiRateTypeDecimal = false;
				this.list_TaxRates.forEach((objTaxVal) => {
					if (objTaxVal.decSuiRate != "" && objTaxVal.decSuiRate != undefined) {
						objTaxVal.decSuiRate = (objTaxVal.decSuiRate * 100).toFixed(10);
					}
				});
			}
		}

		if (event.target.dataset.id === "suiRateKey") {
			this.strSelectedSuiRateTypeId = event.target.value;
		}

		if (event.target.dataset.id === "suiDate") {
			this.dtEffectiveDate = event.target.value;
		}

		if (event.target.dataset.id === "agencyInfo") {
			this.strCaseAgencyInfo = event.target.value;
			this.handleAgencyChange();
			this.handleRAFAutomation();
			this.selectedNoticeType = "";
		}

		if (event.target.name === "noDueDate") {
			this.blnIsNoticeDueDateNotPopulated = event.target.checked;
		}

		if (event.target.name === "noticeType") {
			this.selectedNoticeType = event.target.value;
		}
	}

	async handleAgencyChange() {
		await this.getEligibleSuiRateFormNumbers();
		await this.getTaxRates();
		await this.getTaxNoticeType();
	}

	getTaxNoticeType() {
		if (this.strCaseAgencyInfo != null && this.strCaseAgencyInfo != "" && this.strCaseAgencyInfo != undefined) {
			getTaxNoticeTypes({
				strAgencyId: this.strCaseAgencyInfo
			})
				.then((result) => {
					if (result) {
						this.list_TaxNoticeTypes = [];
						this.list_TaxNoticeTypes = [...this.list_TaxNoticeTypes, { label: "--None--", value: "" }];
						if (!this.selectedNoticeType) {
							this.selectedNoticeType = "";
						} else if (!result.includes(this.selectedNoticeType)) {
							this.list_TaxNoticeTypes = [...this.list_TaxNoticeTypes, { label: this.selectedNoticeType, value: this.selectedNoticeType }];
						}
						result.forEach((item) => {
							const option = {
								label: item,
								value: item
							};
							this.list_TaxNoticeTypes = [...this.list_TaxNoticeTypes, option];
						});
					}
				})
				.catch((error) => {
					let errorMessage = error;
					if (error.body && error.body.message) {
						errorMessage = error.body.message;
					}
					this.showMessage("Error!", errorMessage, "error", "sticky");
				});
		} else {
			this.list_TaxNoticeTypes = [];
		}
	}

	handleRAFAutomation() {
		if (Federal_Agencies.indexOf(this.strCaseAgencyInfo) > -1 && this.blnGustoAddressee) {
			this.strRAFVal = "Y";
		} else if (!this.idNoticeIndexRecord && this.blnElectronicNotice) {
			this.strRAFVal = "Y";
		} else {
			this.strRAFVal = "N";
		}
	}

	validateSuiRate(event) {
		var t = event.target.value;
		let finalVal;
		if (t.indexOf(".") >= 0) {
			let valArray = t.split(".");
			let frontVal = valArray[0];
			let decimalVal = valArray[1];
			frontVal = frontVal?.length >= 4 ? frontVal.substr(0, 3) : frontVal;
			decimalVal = decimalVal?.length >= 10 ? decimalVal.substr(0, 9) : decimalVal;
			finalVal = frontVal + "." + decimalVal;
		} else {
			finalVal = t?.length > 13 ? t.substr(0, 12) : t;
		}
		event.target.value = finalVal;
	}

	get noNoticeStatus() {
		if (this.blnDisableFields || this.blnIsNoticeDueDateNotPopulated) {
			return true;
		} else {
			return false;
		}
	}

	/* showMessage displays
	 * success, error or warning
	 * messages. depending on the strClassName,
	 * type fo messages will vary.
	 */
	showMessage(strTitle, strMessage, strVarient, strMode) {
		const evt = new ShowToastEvent({
			title: strTitle,
			message: strMessage,
			variant: strVarient,
			mode: strMode
		});
		this.dispatchEvent(evt);
	}
}