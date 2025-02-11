import { LightningElement, api } from 'lwc';
import queryCase from '@salesforce/apex/CareCaseButtons.queryCase';
export default class ContactDetailsPopover extends LightningElement {
    @api recordId;
    strContactId;
    strContactName;
    strContactEmail;
    strContactPhone;
    // connectedCallback() {
    //     this.doInit();
    // }

    doInit() {
        queryCase({
            strId: this.recordId
        })
        .then(result => {
            if(result) {
                this.strContactId = result.ContactId;
                this.strContactName = result.Contact.Name;
                this.strContactEmail = result.Contact.Email;
                this.strContactPhone = result.Contact.Phone;
            }
       })
       .catch(error => {
            console.log('!!! error', error);
       });
    }

    handleOpenContact() {
        // send Contact Id
        const idContact = this.strContactId;
        const openContactEvent = new CustomEvent('opencontact', {
            detail: { idContact },
        });
        // Fire the custom event
        this.dispatchEvent(openContactEvent);
    }

}