import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecord } from "lightning/uiRecordApi";

const FIELDS = [
	"Opportunity.Name",
	"Opportunity.ZP_Add_Company_Addresses__c",
	"Opportunity.ZP_Add_Employees__c",
	"Opportunity.ZP_Set_Up_Federal_Taxes__c",
	"Opportunity.ZP_Set_Up_State_Taxes__c",
	"Opportunity.ZP_Set_Up_Bank_Account__c",
	"Opportunity.ZP_Select_a_Payroll_Schedule__c",
	"Opportunity.ZP_Report_Previous_Paystubs__c",
	"Opportunity.ZP_Add_Signatory__c",
	"Opportunity.ZP_Sign_Company_Forms__c",
	"Opportunity.ZP_Enter_Unpaid_Tax_Liabilities__c",
	"Opportunity.ZP_Ran_Payroll__c"
];

export default class MultiLineStepTitles extends LightningElement {
	@api recordId;
	@track isLoad = true;
	opportunityObj;
	ZP_Add_Company_Addresses__c;
	ZP_Add_Employees__c;

	@wire(getRecord, { recordId: "$recordId", fields: FIELDS })
	wiredRecord({ error, data }) {
		if (error) {
			let message = "Unknown error";
			if (Array.isArray(error.body)) {
				message = error.body.map((e) => e.message).join(", ");
			} else if (typeof error.body.message === "string") {
				message = error.body.message;
			}
			this.dispatchEvent(
				new ShowToastEvent({
					title: "Error loading contact",
					message,
					variant: "error"
				})
			);
		} else if (data) {
			this.isLoad = false;
			this.isLoad = true;
			this.opportunityObj = data;
			var needToIsActiveClassName;
			this.ZP_Add_Company_Addresses__c = this.opportunityObj.fields.ZP_Add_Company_Addresses__c.value;
			this.ZP_Add_Employees__c = this.opportunityObj.fields.ZP_Add_Employees__c.value;
			this.ZP_Set_Up_Federal_Taxes__c = this.opportunityObj.fields.ZP_Set_Up_Federal_Taxes__c.value;
			this.ZP_Set_Up_State_Taxes__c = this.opportunityObj.fields.ZP_Set_Up_State_Taxes__c.value;
			this.ZP_Set_Up_Bank_Account__c = this.opportunityObj.fields.ZP_Set_Up_Bank_Account__c.value;
			this.ZP_Select_a_Payroll_Schedule__c = this.opportunityObj.fields.ZP_Select_a_Payroll_Schedule__c.value;
			this.ZP_Report_Previous_Paystubs__c = this.opportunityObj.fields.ZP_Report_Previous_Paystubs__c.value;
			this.ZP_Add_Signatory__c = this.opportunityObj.fields.ZP_Add_Signatory__c.value;
			this.ZP_Sign_Company_Forms__c = this.opportunityObj.fields.ZP_Sign_Company_Forms__c.value;
			this.ZP_Enter_Unpaid_Tax_Liabilities__c = this.opportunityObj.fields.ZP_Enter_Unpaid_Tax_Liabilities__c.value;
			var ZP_Add_Company_Addresses__c = this.template.querySelector(".ZP_Add_Company_Addresses__c");
			var ZP_Ran_Payroll__c = this.template.querySelector(".ZP_Ran_Payroll__c");
			var ZP_Add_Employees__c = this.template.querySelector(".ZP_Add_Employees__c");
			var ZP_Set_Up_Federal_Taxes__c = this.template.querySelector(".ZP_Set_Up_Federal_Taxes__c");
			var ZP_Set_Up_State_Taxes__c = this.template.querySelector(".ZP_Set_Up_State_Taxes__c");
			var ZP_Set_Up_Bank_Account__c = this.template.querySelector(".ZP_Set_Up_Bank_Account__c");
			var ZP_Select_a_Payroll_Schedule__c = this.template.querySelector(".ZP_Select_a_Payroll_Schedule__c");
			var ZP_Report_Previous_Paystubs__c = this.template.querySelector(".ZP_Report_Previous_Paystubs__c");
			var ZP_Add_Signatory__c = this.template.querySelector(".ZP_Add_Signatory__c");
			var ZP_Sign_Company_Forms__c = this.template.querySelector(".ZP_Sign_Company_Forms__c");
			var ZP_Enter_Unpaid_Tax_Liabilities__c = this.template.querySelector(".ZP_Enter_Unpaid_Tax_Liabilities__c");
			var ZP_Ran_Payroll__c = this.template.querySelector(".ZP_Ran_Payroll__c");

			if (this.ZP_Add_Company_Addresses__c) {
				if (ZP_Set_Up_Bank_Account__c) {
					ZP_Set_Up_Bank_Account__c.classList.remove("slds-is-active");
					ZP_Add_Company_Addresses__c.className += " slds-is-completed";
				}
				needToIsActiveClassName = "ZP_Add_Employees__c";
			} else {
				if (ZP_Set_Up_Bank_Account__c) {
					ZP_Add_Company_Addresses__c.classList.remove("slds-is-completed");
				}
				needToIsActiveClassName = "ZP_Add_Company_Addresses__c";
			}

			if (this.ZP_Add_Employees__c) {
				if (ZP_Add_Employees__c) {
					ZP_Add_Employees__c.classList.remove("slds-is-active");
					ZP_Add_Employees__c.className += " slds-is-completed";
				}
				needToIsActiveClassName = "ZP_Set_Up_Federal_Taxes__c";
			} else {
				if (ZP_Add_Employees__c) {
					ZP_Add_Employees__c.classList.remove("slds-is-completed");
				}
			}

			if (this.ZP_Set_Up_Federal_Taxes__c) {
				if (ZP_Set_Up_Federal_Taxes__c) {
					ZP_Set_Up_Federal_Taxes__c.classList.remove("slds-is-active");
					ZP_Set_Up_Federal_Taxes__c.className += " slds-is-completed";
				}
				needToIsActiveClassName = "ZP_Set_Up_State_Taxes__c";
			} else {
				if (ZP_Set_Up_Federal_Taxes__c) {
					ZP_Set_Up_Federal_Taxes__c.classList.remove("slds-is-completed");
				}
			}

			if (this.ZP_Set_Up_State_Taxes__c) {
				if (ZP_Set_Up_State_Taxes__c) {
					ZP_Set_Up_State_Taxes__c.classList.remove("slds-is-active");
					ZP_Set_Up_State_Taxes__c.className += " slds-is-completed";
				}
				needToIsActiveClassName = "ZP_Set_Up_Bank_Account__c";
			} else {
				if (ZP_Set_Up_State_Taxes__c) {
					ZP_Set_Up_State_Taxes__c.classList.remove("slds-is-completed");
				}
			}

			if (this.ZP_Set_Up_Bank_Account__c) {
				if (ZP_Set_Up_Bank_Account__c) {
					ZP_Set_Up_Bank_Account__c.classList.remove("slds-is-active");
					ZP_Set_Up_Bank_Account__c.className += " slds-is-completed";
				}
				needToIsActiveClassName = "ZP_Select_a_Payroll_Schedule__c";
			} else {
				if (ZP_Set_Up_Bank_Account__c) {
					ZP_Set_Up_Bank_Account__c.classList.remove("slds-is-completed");
				}
			}

			if (this.ZP_Select_a_Payroll_Schedule__c) {
				if (ZP_Select_a_Payroll_Schedule__c) {
					ZP_Select_a_Payroll_Schedule__c.classList.remove("slds-is-active");
					ZP_Select_a_Payroll_Schedule__c.className += " slds-is-completed";
					needToIsActiveClassName = "ZP_Report_Previous_Paystubs__c";
				}
			} else {
				if (ZP_Select_a_Payroll_Schedule__c) {
					ZP_Select_a_Payroll_Schedule__c.classList.remove("slds-is-completed");
				}
			}

			if (this.ZP_Report_Previous_Paystubs__c) {
				if (ZP_Report_Previous_Paystubs__c) {
					ZP_Report_Previous_Paystubs__c.classList.remove("slds-is-active");
					ZP_Report_Previous_Paystubs__c.className += " slds-is-completed";
				}
				needToIsActiveClassName = "ZP_Add_Signatory__c";
			} else {
				if (ZP_Report_Previous_Paystubs__c) {
					ZP_Report_Previous_Paystubs__c.classList.remove("slds-is-completed");
				}
			}

			if (this.ZP_Add_Signatory__c) {
				if (ZP_Add_Signatory__c) {
					ZP_Add_Signatory__c.classList.remove("slds-is-active");
					ZP_Add_Signatory__c.className += " slds-is-completed";
					needToIsActiveClassName = "ZP_Sign_Company_Forms__c";
				}
			} else {
				if (ZP_Add_Signatory__c) {
					ZP_Add_Signatory__c.classList.remove("slds-is-completed");
				}
			}

			if (this.ZP_Sign_Company_Forms__c) {
				if (ZP_Sign_Company_Forms__c) {
					ZP_Sign_Company_Forms__c.classList.remove("slds-is-active");
					ZP_Sign_Company_Forms__c.className += " slds-is-completed";
					needToIsActiveClassName = "ZP_Enter_Unpaid_Tax_Liabilities__c";
				}
			} else {
				if (ZP_Sign_Company_Forms__c) {
					ZP_Sign_Company_Forms__c.classList.remove("slds-is-completed");
				}
			}

			if (this.ZP_Enter_Unpaid_Tax_Liabilities__c) {
				if (ZP_Enter_Unpaid_Tax_Liabilities__c) {
					ZP_Enter_Unpaid_Tax_Liabilities__c.classList.remove("slds-is-active");
					ZP_Enter_Unpaid_Tax_Liabilities__c.className += " slds-is-completed";
					needToIsActiveClassName = "ZP_Ran_Payroll__c";
				}
			} else {
				if (ZP_Enter_Unpaid_Tax_Liabilities__c) {
					ZP_Enter_Unpaid_Tax_Liabilities__c.classList.remove("slds-is-completed");
				}
			}

			if (this.ZP_Ran_Payroll__c) {
				if (ZP_Ran_Payroll__c) {
					ZP_Ran_Payroll__c.classList.remove("slds-is-active");
					ZP_Ran_Payroll__c.className += " slds-is-completed";
				}
			} else {
				if (ZP_Ran_Payroll__c) {
					ZP_Ran_Payroll__c.classList.remove("slds-is-completed");
				}
			}

			if (needToIsActiveClassName && this.template.querySelector("." + needToIsActiveClassName)) {
				this.template.querySelector("." + needToIsActiveClassName).className += " slds-is-active";
			}
		}
	}

	handleClick(event) {
		var strClassName = event.currentTarget.dataset.title;
		event.currentTarget.classList.toggle("clicked");
	}
}