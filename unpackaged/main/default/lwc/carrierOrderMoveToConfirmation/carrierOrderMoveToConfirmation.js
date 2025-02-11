import { LightningElement, api, wire, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import moveToConfirmation from '@salesforce/apex/CarrierOrderMoveToConfirmationCtrl.moveToConfirmation';
import { IsConsoleNavigation, getFocusedTabInfo, closeTab } from 'lightning/platformWorkspaceApi';
import getCarrierOrderRecord from '@salesforce/apex/CarrierOrderMoveToConfirmationCtrl.getCarrierOrderRecord';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';

export default class CarrierOrderMoveToConfirmation extends LightningElement {
    _recordId;
    objCarrierOrder;
    blnIsLoading;
    textAreaValue;
    idLoginUser = Id;
    idCOOwner;
    idConfirmationOwner;

    @api set recordId(value) {
        this._recordId = value;
        this.handleGetOpts();
    }

    get recordId() {
        return this._recordId;
    }
    async handleGetOpts() {
        try {
            let response = await getCarrierOrderRecord({ idCarrierOrder: this._recordId });
            if (response.error !== undefined) {
                const evt = new ShowToastEvent({
                    title: "Error",
                    message: response.error,
                    variant: "error"
                });
                this.dispatchEvent(evt);
                this.closeQuickAction();
                return;
            }
            this.textAreaValue = response[0].Submission_Completion_Notes__c;
            this.idCOOwner = response[0].OwnerId;
            this.idConfirmationOwner = response[0].Confirmation_Owner__c;
        } catch (e) {
            console.log(e);
        } finally {
            this.blnIsLoading = false;
        }
    }


    @wire(IsConsoleNavigation) isConsoleNavigation;

    async closeTab() {
        if (!this.isConsoleNavigation) {
            return;
        }
        const { tabId } = await getFocusedTabInfo();
        await closeTab(tabId);
    }

    handleTextAreaChange(event) {
        this.textAreaValue = event.target.value;
    }

    handleSave(event) {
        this.blnIsLoading = true;
        if (this.textAreaValue === undefined || this.textAreaValue === '') {
            this.showToast('Error', 'Submission Completion Notes is required', 'error');
            this.blnIsLoading = false;
            return;
        }
        if (this.textAreaValue.length < 100) {
            this.showToast('Error', 'Submission Completion Notes must be at least 100 characters in length.', 'error');
            this.blnIsLoading = false;
            return;
        }
        if (this.idLoginUser != this.idCOOwner && this.idLoginUser != this.idConfirmationOwner) {
            this.showToast('Error', 'Only Owner or Confirmation Owner can move the Carrirer Order to Ready for Confirmation.', 'error');
            this.blnIsLoading = false;
            return;
        }
        moveToConfirmation({ carrierOrderId: this._recordId, strSubmissionNotes: this.textAreaValue })
            .then(result => {
                this.showToast('Success', 'Successfully Updated', 'success');
                this.blnIsLoading = false;
                this.handleCancelClick(event);
                getRecordNotifyChange([{recordId: this._recordId}]);
            })
            .catch(error => {
                this.showToast('Error', error, 'error');
                this.blnIsLoading = false;
            })
    }

    handleCancelClick(event) {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, msg, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}