import { LightningElement, api } from 'lwc';
import { displayToast } from 'c/utilityService';
import getUrl from '@salesforce/apex/CommonAppOpenController.getUrl';

export default class CommonHippoQASheet extends LightningElement {
    @api recordId;
    @api async invoke() {
        getUrl({
            idRecord: this.recordId,
            strApp: 'Hippo',
            strPage: 'qa_sheet'
        })
        .then(result => {
            if (result.blnSuccess) {
                window.open(result.strUrl, '_blank');
            } else {
                displayToast(this, result.strMessage, '', 'error', '');
            }
        })
        .catch(error => {
            console.error('Error in opening company in hippo', error);
            displayToast(this, 'Error in opening company in hippo. ' + error, '', 'error', '');
        });
    }
}