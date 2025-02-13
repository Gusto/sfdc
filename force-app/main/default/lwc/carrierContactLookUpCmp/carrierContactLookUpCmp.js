import { LightningElement, track, wire,api } from 'lwc';
import getContacts from '@salesforce/apex/CarrierContactLookupController_LEX.getContacts';
const DELAY = 300;
//loadStyle(this, myResource + '/noHeader.css');
export default class CarrierContactLookupComponent extends LightningElement {
    /* To store the search string for contact */
    @track strSearch = '';
    @track error;
    /* Carrier Account Id being fetched from Custom Label */
    @api idAccount;
    /* list of realted contacts*/
    @track lst_contact = [];
    /* To store the selected contact searched*/
    @track strSelectedContact;
    /*Flag to see if contact list visible or not */
    @track blnShowContactsListFlag = false;
    

    connectedCallback(){
        console.log('--recordId--' +this.idAccount);
    }
    //Method to fetch contacts based on search string and account Id
    @wire(getContacts, { strSearchText: '$strSearch', idAccount:'$idAccount' })
    contacts({data,error}){
        if(data){
            console.log('=----data--'+JSON.stringify(data));
            this.lst_contact = data;
        }else{
            console.log('---error--'+JSON.stringify(error));
        }
    }

    //Method to show contacts as string is being entered
    handleKeyUp(event) {
        if (!this.blnShowContactsListFlag) {
            this.blnShowContactsListFlag = true;
            this.template .querySelector('.contacts_list').classList.remove('slds-hide');
        }
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            this.strSearch = searchKey;
        }, DELAY);
    }

    //Method to select contact from searched dropdown
    handleOptionSelect(event) {
        this.strSelectedContact = event.currentTarget.dataset.name;
        const sendContactId = new CustomEvent('selectedcontact',{detail:{contactId: event.currentTarget.dataset.id, contactEmail:event.currentTarget.dataset.email}});
        this.dispatchEvent(sendContactId);
        this.template.querySelector('.selectedOption').classList.remove('slds-hide');
        this.template.querySelector('.contacts_list').classList.add('slds-hide');
        this.template.querySelector('.slds-combobox__form-element').classList.add('slds-input-has-border_padding');
    }


    //Method to remove the selected option
    handleRemoveSelectedOption() {
        this.template.querySelector('.selectedOption').classList.add('slds-hide');
        this.template.querySelector('.slds-combobox__form-element').classList.remove('slds-input-has-border_padding');
        this.blnShowContactsListFlag = false;
    }

    /*handleBlur(){
        this.template.querySelector('.contacts_list').classList.add('slds-hide');
        this.showContactsListFlag = false;
    }*/

    handleFocus(event){
        this.template .querySelector('.contacts_list').classList.remove('slds-hide');
    }
}