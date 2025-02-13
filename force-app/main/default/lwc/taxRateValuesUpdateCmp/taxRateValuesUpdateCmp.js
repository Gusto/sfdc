import { LightningElement, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecord, getFieldValue, updateRecord } from "lightning/uiRecordApi";
import CASE_STATUS from "@salesforce/schema/Case.Status";
import getTaxRateValues from "@salesforce/apex/TaxRateValuesUpdateController.getTaxRateValues";
import getFieldApiNames from "@salesforce/apex/TaxRateValuesUpdateController.getFields";
import syncTaxRateValuesForTNDC from "@salesforce/apex/TaxResNoticeIndexDetailsController.syncTaxRateValuesForTNDC";

export default class TaxRateValuesUpdateCmp extends LightningElement {
	@api recordId;
	idTaxNotice = "";
	blnIsTaxRateAvailable = false;
	blnIsLoading = false;
	list_strRateValues = [];
	list_TaxRates = [];
	list_CaseApiNames = [];
	blnIsCaseSolvedClosed = true;

	@wire(getRecord, { recordId: "$recordId", fields: [CASE_STATUS] })
	record({ error, data }) {
		if (data) {
			let caseStatus = data.fields[CASE_STATUS.fieldApiName].value;
			this.blnIsCaseSolvedClosed = caseStatus != "Closed" && caseStatus != "Solved" ? false : true;
			this.getTaxRateValueDetails();
		} else if (error) {
			console.error("error: ", error);
		}
	}

	connectedCallback() {
		this.getFieldsInfo();
	}

	getTaxRateValueDetails() {
		this.list_TaxRates = [];
		this.blnIsTaxRateAvailable = false;
		getTaxRateValues({
			strCaseId: this.recordId
		})
			.then((result) => {
				if (result) {
					this.list_TaxRates = [];
					result.forEach((objTaxRateValue) => {
						let objValue = {};
						objValue.label = objTaxRateValue.Tax_Rate_Type__r.Name;
						objValue.value = objTaxRateValue.Tax_Rate_Type__c;
						objValue.perCentSuiRate = objTaxRateValue.Rate_Decimal__c * 100;
						objValue.perCentSuiRate = objValue.perCentSuiRate.toFixed(10);
						this.idTaxNotice = objTaxRateValue.Tax_Notice_Index__c;

						this.list_TaxRates = [...this.list_TaxRates, objValue];
					});

					if (this.list_TaxRates?.length > 0) {
						this.blnIsTaxRateAvailable = true;
					} else {
						this.blnIsTaxRateAvailable = false;
					}
				}
			})
			.catch((error) => {
				console.log("~~!! error >" + error);
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

	//Calls apex method to process "Complete" logic for open case
	manageTaxRateValueRecords() {
		this.list_strRateValues = [];
		this.list_TaxRates.forEach((objTaxVal) => {
			if (objTaxVal.perCentSuiRate != null) {
				let decSuiRateTemp = objTaxVal.perCentSuiRate / 100;
				decSuiRateTemp = decSuiRateTemp.toFixed(10);
				this.list_strRateValues.push(objTaxVal.value + "=>" + decSuiRateTemp);
			}
		});
	}

	handleSubmit(event) {
		this.blnIsLoading = true;
		event.preventDefault(); // stop the form from submitting
		const fields = event.detail.fields;

		if (!this.blnIsCaseSolvedClosed) {
			this.template.querySelector("lightning-record-edit-form").submit(fields);
		} else if (this.idTaxNotice) {
			this.saveTaxValues();
		}
	}

	handleSuccess(event) {
		if (this.idTaxNotice) {
			this.saveTaxValues();
		} else {
			this.blnIsLoading = false;
		}
	}

	saveTaxValues() {
		this.blnIsLoading = true;
		this.manageTaxRateValueRecords();
		syncTaxRateValuesForTNDC({
			strTNDCId: this.idTaxNotice,
			list_TaxRateValues: this.list_strRateValues
		})
			.then((result) => {})
			.catch((error) => {
				console.log("~~!!saveTaxValues error>" + JSON.stringify(error));
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

	//Handle event for Tax rate
	handelSuiRateChange(event) {
		this.list_TaxRates.forEach((objTaxVal) => {
			if (event.target.dataset.rowId == objTaxVal.value) {
				objTaxVal.perCentSuiRate = event.target.value;
			}
		});
	}

	//retrieve comma separated field api names
	getFieldsInfo() {
		getFieldApiNames()
			.then((result) => {
				if (result) {
					let objField = {};
					let intResultSize = result.length;
					let intIndex = 1;
					result.forEach((strVal) => {
						if (!objField.val1) {
							objField.val1 = strVal;
						} else if (objField.val1 && !objField.val2) {
							objField.val2 = strVal;
						}

						if ((objField.val1 && objField.val2) || intIndex === intResultSize) {
							this.list_CaseApiNames = [...this.list_CaseApiNames, objField];
							objField = {};
						}

						intIndex++;
					});
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
			});
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