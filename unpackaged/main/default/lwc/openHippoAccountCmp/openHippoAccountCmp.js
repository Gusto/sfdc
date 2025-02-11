import { LightningElement, api, track } from 'lwc';
import { sendAuraEvent, displayToast } from 'c/utilityService';

import getPandaURL from '@salesforce/apex/OpenAccountController.getAccountExternalURL';

export default class OpenHippoAccountCmp extends LightningElement {
    @api recordId;
    /* Indicates if component is loading (shows a spinner icon) */
    @track blnIsLoading;

    connectedCallback() {
        this.blnIsLoading = true;
        getPandaURL({
            idRecord: this.recordId,
            strAppName: 'Hippo'
        })
        .then(result => {
            if (!result.blnSuccess) {
                displayToast(this, result.strMessage, '', 'error', '');
            } else {
                window.open(result.strAccountURL, '_blank');
            }
            sendAuraEvent(this, '', 'closemodal');
            this.blnIsLoading = false;
        })
        .catch(error => {
            // If there is an Exception, Show Error Message on the UI
            console.error('Error in openPandaAccountCmp - handleSave ', error);
            displayToast(this, 'Error in opening account in panda. ' + error.body.message, '', 'error', '');
            sendAuraEvent(this, '', 'closemodal');
            this.blnIsLoading = false;
        });
    }
}