import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { openTab } from "lightning/platformWorkspaceApi";
import getUserInfo from "@salesforce/apex/MFCasePlayModeCtrl.getUserInformation";
import getCases from "@salesforce/apex/MFCasePlayModeCtrl.getCaseDetails";
import playCases from "@salesforce/apex/MFCasePlayModeCtrl.executePlay";

export default class CasePlayModeCmp extends LightningElement {
	blnIsLoading = true;
	@track strCaseType = "--None--";
	@track strCarrier = "--None--";
	@track strCount = "0";
	@track strMsg = "";
	@track strSubMsg = "";
	@track strSortingOrder = null;
	@track strPlayType = null;
	@track blnEnableCarrier = false;
	@track blnEnableCount = false;
	@track objloggedInUser = [];
	@track list_CaseTypes = [];
	@track list_Carries = [];
	@track list_CaseNumber = [];

	connectedCallback() {
		this.loadUserInfo();
	}

	loadUserInfo() {
		getUserInfo()
			.then((result) => {
				if (result) {
					this.objloggedInUser = result.objloggedInUser;
					this.list_CaseTypes = result.list_CaseTypes;
					this.list_Carries = result.list_Carries;
					this.list_CaseNumber = result.list_CaseNumber;
				}
				this.blnIsLoading = false;
			})
			.catch((error) => {
				this.blnIsLoading = false;
				this.error = "Error loading User Info : " + error.body.message;
			});
	}

	caseTypeChangeHandler(event) {
		this.strCaseType = event.target.value;
		if (this.strCaseType == "--None--") {
			this.resetValue();
		} else if (this.strCaseType == "QSEHRA") {
			this.strCarrier = "--None--";
			this.blnEnableCarrier = false;
			this.blnEnableCount = true;
			this.fetchCaseDetail();
		} else {
			this.blnEnableCarrier = true;
			this.blnEnableCount = true;
			this.fetchCaseDetail();
		}
	}

	fetchCaseDetail() {
		this.blnIsLoading = true;
		this.strMsg = "";
		this.strSubMsg = "";
		getCases({
			strCaseType: this.strCaseType,
			strCarrierType: this.strCarrier
		}).then((result) => {
			this.blnIsLoading = false;
			var semicolonIndex = result.indexOf("!*!");
			if (semicolonIndex > -1) {
				this.strSortingOrder = result.substring(0, semicolonIndex);
				this.strPlayType = result.substring(semicolonIndex + 3);
			}

			if (this.strSortingOrder != null && this.strSortingOrder != "null") {
				var strMessaage = this.strSortingOrder.split("</br>");
				this.strMsg = strMessaage[0];
				if (strMessaage.length > 1) {
					this.strSubMsg = strMessaage[1];
				}
			} else {
				this.strMsg = "No record found.";
			}

			if (this.strPlayType !== null && this.strPlayType !== "null") {
				if (this.strPlayType == "Contact Play Mode") {
					this.strCarrier = "--None--";
					this.blnEnableCarrier = false;
					this.blnEnableCount = false;
				}
			}
		});
	}

	carrierChangeHandler(event) {
		this.strCarrier = event.target.value;
		this.fetchCaseDetail();
	}

	countChangeHandler(event) {
		this.strCount = event.target.value;
	}

	casePlay() {
		if (this.strCaseType == "--None--") {
			const event = new ShowToastEvent({
				title: "Error",
				variant: "Error",
				message: 'Please select "Case Type" field value. Required field.'
			});
			this.dispatchEvent(event);

			return false;
		}

		if (this.strPlayType == "Select Number of Cases Play Mode" && this.strCount == "0") {
			const event = new ShowToastEvent({
				title: "Error",
				variant: "Error",
				message: 'Please select "Number to Serve Up" field value. Required field.'
			});
			this.dispatchEvent(event);

			return false;
		}

		if (this.strMsg == "No record found.") {
			const event = new ShowToastEvent({
				title: "Error",
				variant: "Error",
				message: "No record found."
			});
			this.dispatchEvent(event);

			return false;
		}

		this.blnIsLoading = true;
		this.strMsg = "";
		playCases({
			strCaseType: this.strCaseType,
			strCarrierType: this.strCarrier,
			strCount: this.strCount
		}).then((result) => {
			this.blnIsLoading = false;
			for (var index = 0; index < result.length; index++) {
				this.openCase(result[index]);
			}
			this.resetValue();
		});
	}

	refresh() {
		window.location.reload();
	}

	resetValue() {
		this.strMsg = "";
		this.strSubMsg = "";
		this.strCaseType == "--None--";
		this.strCarrier = "--None--";
		this.strCount = "0";
		this.blnEnableCarrier = false;
		this.blnEnableCount = false;
	}

	/*Open Case record as a subtab */
	async openCase(idCase) {
		if (idCase != "") {
			await openTab({
				pageReference: {
					type: "standard__recordPage",
					attributes: {
						recordId: idCase,
						actionName: "view"
					}
				},
				focus: true
			}).catch((error) => {
				console.log("Error in CasePlayModeCmp LWC Component----->" + error);
			});
		}
	}
}