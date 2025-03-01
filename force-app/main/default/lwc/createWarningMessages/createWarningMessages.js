import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import showEmailWarningMessages from "@salesforce/apex/CreateWarningMessagesLwc.showEmailWarningMessages";

export default class CreateWarningMessages extends LightningElement {
    @api recordId;
    set_WarningMessages = [];
    blnIsWarning = false;
    strObjectApiName = '';
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            //it gets executed before the connected callback and avilable to use
            this.recordId = currentPageReference.attributes.recordId;
            this.strObjectApiName = currentPageReference.attributes.objectApiName;
        }
    }

    connectedCallback() {
        showEmailWarningMessages({
            idObjectId: this.recordId,
            strObjApiName : this.strObjectApiName,
        })
        .then((result) => {
            this.set_WarningMessages = result.list_Message;
            this.blnIsWarning = result.blnIsSuccess;
        })
        .catch((error) => {
            console.log("Error in CreateWarningMessagesLwc LWC Component----->" + error);
        });
    }
}