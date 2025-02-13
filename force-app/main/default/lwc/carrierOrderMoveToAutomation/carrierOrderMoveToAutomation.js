import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import assignAutomationQueueWrapper from '@salesforce/apex/CarrierOrderMoveToRPACtrl.assignAutomationQueueWrapper';

export default class CarrierOrderMoveToAutomation extends LightningElement {
	_recordId;
	blnIsLoading = true;
	@api set recordId(value) {
		this._recordId = value;
		console.log(this._recordId);
		this.handleLoad();
	}

	get recordId() {
		return this._recordId;
	}
	async handleLoad() {
		let variant = '';
		let title = '';
		let message = '';
		try {
			let result = await assignAutomationQueueWrapper({ strCarrierOrderId: this._recordId });
			this.blnIsLoading = false;
			variant = result.includes('Successfully') ? 'success' : 'warning';
			title = 'Move to Automation';
			message = result;
		} catch (error) {
			title = 'Error';
			message = error;
			variant = 'error';
		}
		const evt = new ShowToastEvent({
			title: title,
			message: message,
			variant: variant
		});
		this.dispatchEvent(evt);
		this.dispatchEvent(new CloseActionScreenEvent());
	}
}