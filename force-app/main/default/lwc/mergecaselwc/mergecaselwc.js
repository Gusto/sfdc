import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import returnCaseList from "@salesforce/apex/LWC_MergeCaseController.returnCaseList";
import mergeSeletedCase from "@salesforce/apex/LWC_MergeCaseController.mergeSeletedCase";
import getSelectedCaseRecord from "@salesforce/apex/LWC_MergeCaseController.getSelectedCaseRecord";

export default class Mergecaselwc extends NavigationMixin(LightningElement) {
	@track currentCaseNumber;
	@track currentCase;
	@track onlyOpenCases = true;
	@track data = [];
	@track isLoading = false;
	@track hasData;
	@api recordId;
	@track str_caseNumber = "";
	@track str_InputChecked = true;
	caseIdList = [];
	caseNumbersList = [];
	@track selectedCaseNumbers = "";
	@track showCaseNumberCount = false;
	@track disableMergeAndCloseCurrentCaseButton = false;
	@track disableMergeAndCloseSelectedCaseButton = false;
	@track MergeandCloseCaseLabel = "";
	totalCheckboxesChecked = 0;
	@track selectedCaseRecordNumber;
	selectedCaseRecord = [];
	selectedCaseNumbersDummy = "";
	dataArray = [];

	connectedCallback() {
		this.callCaseList();
	}

	handleCaseNumberChange(event) {
		this.str_caseNumber = event.target.value;
		if (this.str_caseNumber !== "") {
			this.str_caseNumber = this.str_caseNumber.trim();
		}

		this.callCaseList();
	}
	handleInputChange(event) {
		this.str_InputChecked = event.target.checked;
		this.onlyOpenCases = this.str_InputChecked;
		this.callCaseList();
	}

	callCaseList() {
		this.totalCheckboxesChecked = 0;
		this.isLoading = true;
		this.data = null;
		this.data = [];
		this.dataArray = [];
		this.caseNumbersList = [];
		this.selectedCaseNumbers = "";
		this.caseIdList = [];
		this.showCaseNumberCount = false;

		returnCaseList({ caseRecordId: this.recordId, caseNumber: this.str_caseNumber, openCases: this.onlyOpenCases })
			.then((result) => {
				if (result && result.isSuccess) {
					for (let i = 0; i < result.responseData.caseList.length; i++) {
						this.dataArray.push({
							CaseNumber: result.responseData.caseList[i].CaseNumber,
							CaseUrl: "/" + result.responseData.caseList[i].Id,
							Id: result.responseData.caseList[i].Id,
							RecordTypeName:
								result.responseData.caseList[i].RecordTypeId !== undefined && result.responseData.caseList[i].RecordTypeId ? result.responseData.caseList[i].RecordType.Name : "",
							ContactName:
								result.responseData.caseList[i].ContactId !== undefined && result.responseData.caseList[i].ContactId !== null ? result.responseData.caseList[i].Contact.Name : "",
							Subject: result.responseData.caseList[i].Subject,
							Status: result.responseData.caseList[i].Status,
							OwnerName: result.responseData.caseList[i].OwnerId !== undefined && result.responseData.caseList[i].OwnerId ? result.responseData.caseList[i].Owner.Name : ""
						});
					}

					this.data = this.dataArray;
					this.currentCaseNumber = result.responseData.currentCase.CaseNumber;
					this.MergeandCloseCaseLabel = "Merge and Close Case : " + this.currentCaseNumber;
					this.currentCase = result.responseData.currentCase;
					this.hasData = true;
					this.isLoading = false;
				} else if (result && !result.isSuccess) {
					this.showToast("Error ", JSON.stringify(result.message), "error");
					this.hasData = false;
					this.isLoading = false;
				} else {
					this.isLoading = false;
					this.hasData = false;
				}
			})
			.catch((error) => {
				this.isLoading = false;
				this.showToast("Error", JSON.stringify(error), "error");
			});
	}

	handleSelectedCases(event) {
		this.isLoading = true;
		this.selectedCaseNumbers = "";
		let selectedCaseNumber = event.currentTarget.dataset.casenumber;
		let selectedCaseId = event.target.value;
		let isSelected = event.target.checked;
		this.selectedCaseRecordNumber = event.currentTarget.dataset.casenumber;

		if (isSelected) {
			this.caseIdList.push(selectedCaseId);
			this.caseNumbersList.push(selectedCaseNumber);
		} else {
			const index = this.caseIdList.indexOf(selectedCaseId);
			if (index > -1) {
				this.caseIdList.splice(index, 1);
			}
			const casenum = this.caseNumbersList.indexOf(selectedCaseNumber);
			if (casenum > -1) {
				this.caseNumbersList.splice(casenum, 1);
			}
		}

		if (this.caseNumbersList !== undefined && this.caseNumbersList.length > 0) {
			this.showCaseNumberCount = true;
			if (this.caseNumbersList.length > 1) {
				this.disableMergeAndCloseCurrentCaseButton = true;
			} else {
				this.disableMergeAndCloseCurrentCaseButton = false;
			}
			if (this.caseNumbersList.length <= 3) {
				this.selectedCaseNumbers = this.caseNumbersList.join(", ");
				this.selectedCaseNumbersDummy = this.selectedCaseNumbers;
				this.disableMergeAndCloseSelectedCaseButton = false;
			} else {
				this.selectedCaseNumbers = this.selectedCaseNumbersDummy;
				this.disableMergeAndCloseSelectedCaseButton = true;
			}
		} else {
			this.showCaseNumberCount = false;
		}
		if (this.caseNumbersList.length > 3) {
			this.isLoading = false;
			return;
		}

		this.isLoading = false;
	}

	showToast(title, message, variantType) {
		const event = new ShowToastEvent({
			title: title,
			message: message,
			variant: variantType
		});
		this.dispatchEvent(event);
	}
	handleMergeAndCloseSelectedCase() {
		this.isLoading = true;

		if (this.caseIdList !== undefined) {
			if (this.caseIdList.length === 0) {
				this.showToast("Warning", "Please select a record", "warning");
				this.isLoading = false;
			} else {
				mergeSeletedCase({ list_CaseIds: this.caseIdList, caseToMerge: this.currentCase, list_CaseNumbers: this.caseNumbersList })
					.then((result) => {
						if (result && result.isSuccess === true) {
							this.str_caseNumber = "";
							this.onlyOpenCases = false;
							this.closeMergePage();
							this.refreshpage();
							this.showToast("Success ", JSON.stringify(result.message), "success");
							this.isLoading = false;
						} else if (result && result.isSuccess === false) {
							this.showToast("Error 1", JSON.stringify(result.message), "error");
							this.isLoading = false;
						}
					})
					.catch(() => {
						this.isLoading = false;
					});
			}
		}
	}

	closeCurrentTab(currentCaseId) {
		if (currentCaseId) {
			this[NavigationMixin.GenerateUrl]({
				type: "standard__recordPage",
				attributes: {
					recordId: currentCaseId.Id,
					actionName: "view"
				}
			});
			const refreshEvent = new CustomEvent("casemergesuccesfull", { detail: {} });
			// Fire the custom event
			this.dispatchEvent(refreshEvent);
			this.showSpinner = false;
		}
	}

	handleMergeAndCloseCurrentCase() {
		this.isLoading = true;
		let currentCaseIdinArr = [];
		this.data.find((r) => {
			if (r.CaseNumber === this.selectedCaseRecordNumber) {
				this.selectedCaseRecord.push(r);
			}
		});

		currentCaseIdinArr.push(this.currentCase.Id);

		if (this.caseIdList !== undefined) {
			if (this.caseIdList.length === 0) {
				this.showToast("Warning", "Please select a record", "warning");
				this.isLoading = false;
			} else {
				getSelectedCaseRecord({ caseNumber: this.selectedCaseRecordNumber })
					.then((cRec) => {
						if (cRec) {
							return mergeSeletedCase({ list_CaseIds: currentCaseIdinArr, caseToMerge: cRec, list_CaseNumbers: this.caseNumbersList });
						} else {
							this.showToast("Success ", "Selected Case is not fit to be merged", "success");
							return;
						}
					})
					.then((result) => {
						if (result && result.isSuccess === true) {
							this.str_caseNumber = "";
							this.onlyOpenCases = false;
							this.closeMergePage();
							this.refreshpage();
							this.isLoading = false;
							this.showToast("Success ", JSON.stringify(result.message), "success");
						} else if (result && result.isSuccess === false) {
							this.showToast("Error 1", JSON.stringify(result.message), "error");
							this.isLoading = false;
						}
					})
					.catch(() => {
						this.isLoading = false;
					});
			}
		}
	}

	refreshpage() {
		const recordNavigation = new CustomEvent("refpage", {});
		this.dispatchEvent(recordNavigation);
	}

	closeMergePage() {
		const recordNavigation = new CustomEvent("closeCurrentTab", {});
		this.dispatchEvent(recordNavigation);
	}

	handleUrlclick(event) {
		let caseNumber = event.target.dataset.casenumber;
		let caseId = event.target.dataset.id;
		if (caseId !== undefined) {
			const recordNavigation = new CustomEvent("ClickCaseNumber", {
				detail: { detailRecordId: caseId, newCaseNumber: caseNumber }
			});

			this.dispatchEvent(recordNavigation);
		} else {
			this.showToast("Error", "Unable to access record", "error");
		}
	}
}