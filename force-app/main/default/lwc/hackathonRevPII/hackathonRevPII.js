import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import makeApiCallout from '@salesforce/apex/HackathonRevPII.makeApiCallout';
import makeURL from '@salesforce/apex/HackathonRevPII.makeURL';
import { CloseActionScreenEvent } from 'lightning/actions';
import {CurrentPageReference} from 'lightning/navigation';

export default class HackathonRevPII extends LightningElement {
    @api recordId;
    recordIdFetched;

    isLoading = true;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordIdFetched = currentPageReference.state.recordId;
            this.handleApiCallout(this.recordIdFetched);
        }
    }

    connectedCallback() {
        if (this.recordId != null) {
            this.handleApiCallout(this.recordId);
        }
    }

    handleApiCallout(recordIdParam) {
        this.isLoading = true;
        console.log(recordIdParam);
        makeURL({ recordId: recordIdParam }) 
            .then((data) => {
                makeApiCallout({ recordId: recordIdParam })
                .then(result => {
                    this.closeQuickAction();
                    this.showToast('Success', 'API callout completed successfully', 'success');
                })
                .catch(error => {
                    console.error('Error making API callout:', error);
                    this.closeQuickAction();
                    this.showToast('Error', this.extractErrorMessage(error), 'error');
                })
                .finally(() => {
                    this.isLoading = false;
                });
            })
            .catch((error) => {
                console.error('Error making API callout:', error);
                this.closeQuickAction();
                this.showToast('Error', this.extractErrorMessage(error), 'error');
            });
    }

    extractErrorMessage(error) {
        return error.body?.message || error.message || 'Unknown error occurred';
    }

    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toastEvent);
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}