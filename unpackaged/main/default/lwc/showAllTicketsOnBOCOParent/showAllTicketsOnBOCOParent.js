import { LightningElement, api } from 'lwc';
export default class ShowAllTicketsOnBOCOParent extends LightningElement {
    @api recordId;
    @api recordLimit;

    connectedCallback() {
        this.recordLimit = 3;
    }
}