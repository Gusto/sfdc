import { LightningElement } from 'lwc';


import TICKET_REASON_FIELD from '@salesforce/schema/Ticket__c.UI_Ticket_Reason__c';
import TICKET_SUB_REASON_FIELD from '@salesforce/schema/Ticket__c.UI_Ticket_Sub_Reason__c';

export default class CreateTicketModal extends LightningElement {

    fields = [TICKET_REASON_FIELD, TICKET_SUB_REASON_FIELD];

    closeModal() {

        const modalCloseEvent = new CustomEvent('closemodal', {
            detail: {},
        });
        this.dispatchEvent(modalCloseEvent);
    }
}