import { LightningElement, api, wire, track } from 'lwc';
import {getRecord,getFieldValue} from 'lightning/uiRecordApi';
import getAttachmentRecord from '@salesforce/apex/FilesComponentController.getAttachmentRecord';

import { displayToast } from 'c/utilityService';

export default class ShowAttachmentRecordLwcCmp extends LightningElement {
    @api recordId ;
    /** to hold the attachment preview URL */
    @api attachurl;
    /** to hold the attachment record */
    @track objRecord;
    /** to hold the attachment name */
    @track strAttachName;
    /** to hold the attachment Description */
    @track strAttachDesc;
    /** to hold the attachment Type */
    @track strAttachtype;
    /** to hold the attachment Size */
    @track strAttachsize;
    connectedCallback(){
        //** This method gets the selected attachment record and populates the data on the UI */
        getAttachmentRecord({attId: this.recordId})
        .then(res=>{
            if(res.blnIsSuccess) {
                this.objRecord = res.objAttachment;
                this.strAttachName = res.objAttachment.Name;
                this.strAttachDesc = res.objAttachment.Description;
                this.strAttachtype = res.objAttachment.ContentType;
                this.strAttachtype = this.strAttachtype.substring(this.strAttachtype.indexOf('/') + 1, this.strAttachtype.length);
                this.strAttachsize = ((res.objAttachment.BodyLength / 1024).toFixed(0)) + ' KB';
            } else {
                console.log('error>>>');
                displayToast(this, res.strMessage, '', 'error', 'sticky');
            }
        })
        .catch(error=>{
            //this.isLoading = false;
            console.log('error>>>'+ JSON.stringify(error));
        }); 
    }

}