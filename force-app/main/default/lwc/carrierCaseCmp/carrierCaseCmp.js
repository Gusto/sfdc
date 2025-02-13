import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import CASE_OBJECT from '@salesforce/schema/Case';
import ACCOUNTNAME_FIELD from "@salesforce/schema/Account.Name";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { updateRecord } from 'lightning/uiRecordApi';
import SKIPSURVEY_FIELD from "@salesforce/schema/Case.Skip_Survey__c";
import RECORDTYPEID_FIELD from "@salesforce/schema/Case.RecordTypeId";
import ORIGIN_FIELD from "@salesforce/schema/Case.Origin";
import SUBJECT_FIELD from "@salesforce/schema/Case.Subject";
import PARENTID_FIELD from "@salesforce/schema/Case.ParentId";
import DIRECTION_FIELD from "@salesforce/schema/Case.Direction__c";
import ACCOUNT_FIELD from "@salesforce/schema/Case.AccountId";
import CONTACT_FIELD from "@salesforce/schema/Case.ContactId";
import CASENUMBER_FIELD from "@salesforce/schema/Case.CaseNumber";
import CASEREASONTYPE_FIELD from "@salesforce/schema/Case.Type";
import Id from '@salesforce/user/Id';
import { createRecord } from 'lightning/uiRecordApi';

import carrierAccountId from '@salesforce/label/c.Carrier_Account_Id';
const ORIGINTEXT = 'Contact Carrier';

export default class CarrierCase extends LightningElement {
    @api blnOpenModal;
    @track objectInfo;
    @api strRecordId;
    //To store the subject for case created
    @track strSubject;
    //To store the account name for case created
    @track strAccountName;
    //Flag to show spinner
    @track blnIsLoading = false;
    //To store the case number for case created
    @track strCaseNumber;
    //To store the contact for case created
    @track strContactId;
    //To store the carrier account Id being fetched from custom label
    @track strAccountId = carrierAccountId;
    
    //To store contact email for case created
    @track strContactEmail;

    connectedCallback(){
        console.log('--recordId--' +this.strRecordId);
        console.log('--openmodal--' +this.blnOpenModal);
    }

    @wire(getRecord, { recordId: '$strRecordId', layoutTypes: 'Full'})
    originalCaseData({error, data}){
        if (data){
            console.log('--acc ID' +this.strAccountId);
            this.strCaseNumber = data.fields.CaseNumber.value;
            this.strAccountName = data.fields.Contact.displayValue;
            this.strSubject = 'On behalf of'+ ' '+ this.strAccountName + ' ' + this.strCaseNumber;
        }
    }


    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    objectInfo;

    getRecordTypeId(recordTypeName) {
        // Returns a map of record type Ids 
        const rtis = this.objectInfo.data.recordTypeInfos;
        return Object.keys(rtis).find(rti => rtis[rti].name === recordTypeName);
    }

   

    handleCreate(){
        //Method to create a new carrier contact case
        this.blnIsLoading = true;
        const fields = {};         
        fields[ORIGIN_FIELD.fieldApiName] = ORIGINTEXT;
        fields[DIRECTION_FIELD.fieldApiName] = 'Outbound';
        fields[SKIPSURVEY_FIELD.fieldApiName] = true;
        fields[RECORDTYPEID_FIELD.fieldApiName] = this.getRecordTypeId('Benefits Care');
        fields[CASEREASONTYPE_FIELD.fieldApiName] = 'Benefits Care';     
        fields[PARENTID_FIELD.fieldApiName] =  this.strRecordId;
        fields[SUBJECT_FIELD.fieldApiName] = this.strSubject;
        fields[CONTACT_FIELD.fieldApiName] = this.strContactId;
        const recordInput = { apiName: CASE_OBJECT.objectApiName, fields };
        
        createRecord(recordInput)
        .then(result => {
            this.blnOpenModal = false;
             try{
            let newCaseId = result.id;
            let newCaseNumber = result.fields.CaseNumber;
            const openprimarytab = new CustomEvent('openprimarytab', {
                    detail: {newCaseId,newCaseNumber,closeAfterCreate:this.blnOpenModal},
                });
                this.dispatchEvent(openprimarytab);
            }catch(error){
                console.log('Error in dispatching customevent'+ JSON.stringify(error));
            }
            this.blnIsLoading = false;
        })
        .then(result =>{
            console.log('success--');
        })
        .catch(error => {
            console.log('--error=='+JSON.stringify(error));
        })
    }

    handleCancel(){
        this.blnOpenModal = false;
        this.dispatchEvent(new CustomEvent('closemodal', {
            detail: {closeModal : this.blnOpenModal}
        }));
    }

    closeModalForChange(){
        this.blnOpenModal = false;
    }

    handleSelectedContact(event){
        this.strContactId = event.detail.contactId;
        this.strContactEmail = event.detail.contactEmail;
    }
}