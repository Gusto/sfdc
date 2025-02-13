/* eslint-disable vars-on-top */
import { LightningElement, api, track } from "lwc";

import getOnboardingSteps from "@salesforce/apex/OrderOnboardingStepsController.getOnboardingSteps";
import { displayToast } from "c/utilityService";

export default class OrderOnboardingSteps extends LightningElement {
	@api recordId;
	@track isLoad = true;
	opportunityObj;
	blnIsInceptionOrContractorOnly = false;
	ZP_Add_Company_Addresses__c;
	ZP_Add_Employees__c;
	needToIsActiveClassName;
	@track blnShowMessage = false;

	connectedCallback() {
		getOnboardingSteps({
			idRecordId: this.recordId
		})
		.then((result) => {
			try {
				// if result does not exist, set and show error message
				if (!result) {
					this.blnShowMessage = true;
					return;
				}
				this.opportunityObj = result;
				if (!this.opportunityObj.ZP_Report_Previous_Paystubs__c || this.opportunityObj.Pricebook2.Product_Tier__c.includes('contractor_only')){
					this.blnIsInceptionOrContractorOnly = true;
				}
				this.deferredDOMUpdate();
			}
			catch(error){
				console.log("error ", error);
				displayToast(this, "Error in loading onboarding steps. Check console.", "", "error", "");
			}
		})
		.catch((error) => {
			console.log("error ", error);
			displayToast(this, "Error in loading onboarding steps. Check console.", "", "error", "");
		});
	}

	handleClick(event) {
		var strClassName = event.currentTarget.dataset.title;
		event.currentTarget.classList.toggle("clicked");
	}

	deferredDOMUpdate() {
    let deferDOMChange = new Promise(function(resolve) {
        resolve('promise returned');
    });
    deferDOMChange.then((success) => {
        this.needToIsActiveClassName = this.blnIsInceptionOrContractorOnly ? "ZP_Add_Employees__c" : "ZP_Add_Company_Addresses__c";
        this.ZP_Add_Company_Addresses__c = this.opportunityObj.ZP_Add_Company_Addresses__c;
        this.ZP_Add_Employees__c = this.opportunityObj.ZP_Add_Employees__c;
        this.ZP_Set_Up_Federal_Taxes__c = this.opportunityObj.ZP_Set_Up_Federal_Taxes__c;
        this.ZP_Set_Up_State_Taxes__c = this.opportunityObj.ZP_Set_Up_State_Taxes__c;
        this.ZP_Set_Up_Bank_Account__c = this.opportunityObj.ZP_Set_Up_Bank_Account__c;
        this.ZP_Select_a_Payroll_Schedule__c = this.opportunityObj.ZP_Select_a_Payroll_Schedule__c;
        this.ZP_Report_Previous_Paystubs__c = this.opportunityObj.ZP_Report_Previous_Paystubs__c;
        this.ZP_Add_Signatory__c = this.opportunityObj.ZP_Add_Signatory__c;
        this.ZP_Sign_Company_Forms__c = this.opportunityObj.ZP_Sign_Company_Forms__c;
        this.ZP_Enter_Unpaid_Tax_Liabilities__c = this.opportunityObj.ZP_Enter_Unpaid_Tax_Liabilities__c;
        this.ZP_Ran_Payroll__c = this.opportunityObj.ZP_Ran_Payroll__c;
        var ZP_Add_Company_Addresses__c = this.template.querySelector(".ZP_Add_Company_Addresses__c");
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
            if (ZP_Add_Company_Addresses__c) {
                ZP_Add_Company_Addresses__c.classList.remove("slds-is-active");
                ZP_Add_Company_Addresses__c.className += " slds-is-completed";
            }
            this.needToIsActiveClassName = this.blnIsInceptionOrContractorOnly ? "ZP_Set_Up_State_Taxes__c" : "ZP_Add_Employees__c";
        } else {
            if (ZP_Add_Company_Addresses__c) {
                ZP_Add_Company_Addresses__c.classList.remove("slds-is-completed");
                ZP_Add_Company_Addresses__c.classList.remove("slds-is-active");
            }
        }

        if (this.ZP_Add_Employees__c) {
            if (ZP_Add_Employees__c) {
                ZP_Add_Employees__c.classList.remove("slds-is-active");
                ZP_Add_Employees__c.className += " slds-is-completed";
            }
            this.needToIsActiveClassName = this.blnIsInceptionOrContractorOnly ? "ZP_Add_Company_Addresses__c" : "ZP_Set_Up_Federal_Taxes__c";
        } else {
            if (ZP_Add_Employees__c) {
                ZP_Add_Employees__c.classList.remove("slds-is-completed");
                ZP_Add_Employees__c.classList.remove("slds-is-active");
            }
        }

        if (this.ZP_Set_Up_Federal_Taxes__c) {
            if (ZP_Set_Up_Federal_Taxes__c) {
                ZP_Set_Up_Federal_Taxes__c.classList.remove("slds-is-active");
                ZP_Set_Up_Federal_Taxes__c.className += " slds-is-completed";
            }
            this.needToIsActiveClassName = "ZP_Set_Up_State_Taxes__c";
        } else {
            if (ZP_Set_Up_Federal_Taxes__c) {
                ZP_Set_Up_Federal_Taxes__c.classList.remove("slds-is-completed");
                ZP_Set_Up_Federal_Taxes__c.classList.remove("slds-is-active");
            }
        }

        if (this.ZP_Set_Up_State_Taxes__c) {
            if (ZP_Set_Up_State_Taxes__c) {
                ZP_Set_Up_State_Taxes__c.classList.remove("slds-is-active");
                ZP_Set_Up_State_Taxes__c.className += " slds-is-completed";
            }
            this.needToIsActiveClassName = "ZP_Set_Up_Bank_Account__c";
        } else {
            if (ZP_Set_Up_State_Taxes__c) {
                ZP_Set_Up_State_Taxes__c.classList.remove("slds-is-completed");
                ZP_Set_Up_State_Taxes__c.classList.remove("slds-is-active");
            }
        }

        if (this.ZP_Set_Up_Bank_Account__c) {
            if (ZP_Set_Up_Bank_Account__c) {
                ZP_Set_Up_Bank_Account__c.classList.remove("slds-is-active");
                ZP_Set_Up_Bank_Account__c.className += " slds-is-completed";
            }
            this.needToIsActiveClassName = "ZP_Select_a_Payroll_Schedule__c";
        } else {
            if (ZP_Set_Up_Bank_Account__c) {
                ZP_Set_Up_Bank_Account__c.classList.remove("slds-is-completed");
                ZP_Set_Up_Bank_Account__c.classList.remove("slds-is-active");
            }
        }

        if (this.ZP_Select_a_Payroll_Schedule__c) {
            if (ZP_Select_a_Payroll_Schedule__c) {
                ZP_Select_a_Payroll_Schedule__c.classList.remove("slds-is-active");
                ZP_Select_a_Payroll_Schedule__c.className += " slds-is-completed";
                this.needToIsActiveClassName = "ZP_Report_Previous_Paystubs__c";
            }
        } else {
            if (ZP_Select_a_Payroll_Schedule__c) {
                ZP_Select_a_Payroll_Schedule__c.classList.remove("slds-is-completed");
                ZP_Select_a_Payroll_Schedule__c.classList.remove("slds-is-active");
            }
        }

        if (this.ZP_Report_Previous_Paystubs__c) {
            if (ZP_Report_Previous_Paystubs__c) {
                ZP_Report_Previous_Paystubs__c.classList.remove("slds-is-active");
                ZP_Report_Previous_Paystubs__c.className += " slds-is-completed";
                this.needToIsActiveClassName = this.blnIsInceptionOrContractorOnly ? "ZP_Sign_Company_Forms__c" : "ZP_Add_Signatory__c";
            }
        } else {
            if (ZP_Report_Previous_Paystubs__c) {
                ZP_Report_Previous_Paystubs__c.classList.remove("slds-is-completed");
                ZP_Report_Previous_Paystubs__c.classList.remove("slds-is-active");
            }
        }

        if (this.ZP_Add_Signatory__c) {
            if (ZP_Add_Signatory__c) {
                ZP_Add_Signatory__c.classList.remove("slds-is-active");
                ZP_Add_Signatory__c.className += " slds-is-completed";
                this.needToIsActiveClassName = "ZP_Sign_Company_Forms__c";
            }
        } else {
            if (ZP_Add_Signatory__c) {
                ZP_Add_Signatory__c.classList.remove("slds-is-completed");
                ZP_Add_Signatory__c.classList.remove("slds-is-active");
            }
        }

        if (this.ZP_Sign_Company_Forms__c) {
            if (ZP_Sign_Company_Forms__c) {
                ZP_Sign_Company_Forms__c.classList.remove("slds-is-active");
                ZP_Sign_Company_Forms__c.className += " slds-is-completed";
                this.needToIsActiveClassName = "ZP_Enter_Unpaid_Tax_Liabilities__c";
            }
        } else {
            if (ZP_Sign_Company_Forms__c) {
                ZP_Sign_Company_Forms__c.classList.remove("slds-is-completed");
                ZP_Sign_Company_Forms__c.classList.remove("slds-is-active");
            }
        }

        if (this.ZP_Enter_Unpaid_Tax_Liabilities__c) {
            if (ZP_Enter_Unpaid_Tax_Liabilities__c) {
                ZP_Enter_Unpaid_Tax_Liabilities__c.classList.remove("slds-is-active");
                ZP_Enter_Unpaid_Tax_Liabilities__c.className += " slds-is-completed";
                this.needToIsActiveClassName = "ZP_Ran_Payroll__c";
            }
        } else {
            if (ZP_Enter_Unpaid_Tax_Liabilities__c) {
                ZP_Enter_Unpaid_Tax_Liabilities__c.classList.remove("slds-is-completed");
                ZP_Enter_Unpaid_Tax_Liabilities__c.classList.remove("slds-is-active");
            }
        }

        if (this.ZP_Ran_Payroll__c) {
            if (ZP_Ran_Payroll__c) {
                ZP_Ran_Payroll__c.classList.remove("slds-is-active");
                ZP_Ran_Payroll__c.className += " slds-is-completed";
                this.needToIsActiveClassName = null;
            }
        } else {
            if (ZP_Ran_Payroll__c) {
                ZP_Ran_Payroll__c.classList.remove("slds-is-completed");
                ZP_Ran_Payroll__c.classList.remove("slds-is-active");
            }
        }

        if (this.needToIsActiveClassName && this.template.querySelector("." + this.needToIsActiveClassName)) {
            this.template.querySelector("." + this.needToIsActiveClassName).className += " slds-is-active";
        }

    });
  }
}