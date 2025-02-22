import { LightningElement, api, track, wire } from "lwc";
import { CurrentPageReference } from "lightning/navigation";
import sendConfirmationEmailLWC from "@salesforce/apex/OEEmailAutomationHelper.sendConfirmationEmailLWC";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { displayToast } from "c/utilityService";
import { CloseActionScreenEvent } from "lightning/actions";

export default class SendFinalEmailAndFulfill extends LightningElement {
    TITLE = "Final Email Send!";
    VARIANT = "Success";
    MESSAGE = "Final Email Send Successfully!";
    BENEFIT_ORDER_URL = (recordId) => `/lightning/r/Benefit_Order__c/${recordId}&/view`;

    @api recordId;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            console.log("CurrentPageReference : ", currentPageReference);
            //it gets executed before the connected callback and avilable to use
            this.recordId = currentPageReference.state.recordId;
        }
    }

    connectedCallback() {
        console.log("BBO-2191 in the Connected Callback");
        console.log("Record Id : " + this.recordId);

        sendConfirmationEmailLWC({
            idBO: this.recordId
        })
            .then((result) => {
                console.log("result at 41----->" + JSON.stringify(result));
                if (result.blnIsSuccess) {
                    const benefitOrderUrl = this.BENEFIT_ORDER_URL;
                    //const benefitOrderUrl = "/lightning/r/Benefit_Order__c/" + result.objBenefitOrder.Id + "/view";
                    const event = new ShowToastEvent({
                        title: this.TITLE,
                        variant: this.VARIANT,
                        message: this.MESSAGE,
                        messageData: [
                            result.objBenefitOrder.Name,
                            {
                                url: benefitOrderUrl,
                                label: result.objBenefitOrder.Name
                            }
                        ]
                    });
                    this.dispatchEvent(event);
                    this.dispatchEvent(new CloseActionScreenEvent());
                } else {
                    displayToast(this, result.strMessage, "", "error", "sticky");
                    this.dispatchEvent(new CloseActionScreenEvent());
                }
            })
            .catch((error) => {
                console.log("Error in SendFinalEmailAndFulfill LWC Component----->" + error);
            });
    }
}