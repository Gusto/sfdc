import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createRecord } from 'lightning/uiRecordApi';
import getCaseDetails from "@salesforce/apex/TaxResCreateNewCaseController.getCaseDetails";
import updateCaseAttachment from "@salesforce/apex/TaxResCreateNewCaseController.updateCaseAttachment";

export default class TaxResCreateNewCase extends LightningElement {

    @api recordId;
    blnIsLoading = true;
    list_EditableFieldAPINames;
    strRecordTypeId;
    strTaxResQueueId;
    @api strAccountId;
    @api strContactId;
    @api strCaseNumber;
    list_Attachments = [];
    attachmentValue = [];
    blnAttachmentExist = false;
    strCaseStatus;


    @wire (getCaseDetails, {idCase: '$recordId'})
    wiredCases({ error, data }) {
        if (data) {
            this.list_EditableFieldAPINames = data.list_APIName;
            this.strRecordTypeId = data.strRecordTypeId;
            this.strTaxResQueueId = data.strTaxResQueue;
            this.strAccountId = data.strParentCaseAccountId;
            this.strContactId = data.strParentCaseContactId;
            this.strCaseNumber = data.strParentCaseNumber;
            this.list_Attachments = data.list_Attachments;
            if (this.list_Attachments != null && this.list_Attachments.length > 0) {
                this.blnAttachmentExist = true;
            }
            this.strCaseStatus = data.strCaseStatus;
        }
    };

    handleCaseCreated(event) {
        event.preventDefault();  
        
        const fields = event.detail.fields; 
        fields.ParentId = this.recordId;
        fields.RecordTypeId = this.strRecordTypeId;
        fields.Status = this.strCaseStatus;
        fields.OwnerId = this.strTaxResQueueId;
        fields.Origin = 'Gusto';
        fields.Type = 'Tax Res';
        fields.Baby_Case_Identifier__c = "Baby Case for Parent Case #" + this.strCaseNumber;

        this.template.querySelector('lightning-record-edit-form').submit(fields); 
    }

    handleSuccess(event) {
        this.handleAttachments(event.detail.id);
    }

    async handleAttachments(childRecordId){
        let methodName = await this.updateSelectedAttachments(childRecordId);
    }

    updateSelectedAttachments(childRecordId){
        return new Promise((resolve, reject) => {
            const idChildCaseObj = childRecordId;
            var strAttachment = this.attachmentValue.join(',');

            if (strAttachment !=null && strAttachment.length > 0) {
                //Update Attachment Records
                updateCaseAttachment({strCaseId: idChildCaseObj, strAttachmentId: strAttachment})
                .then(result => {
                    const selectedEvent = new CustomEvent('linked', { detail: this.recordId });
                    this.dispatchEvent(selectedEvent);
                    const evt = new ShowToastEvent({
                        title: "Success!",
                        message: "The Case record has been successfully created.",
                        variant: "success",
                    });
                    this.dispatchEvent(evt);
                    this.closeModal();
                })
                .catch(error => {
                    console.log('error.body--->' + JSON.stringify(error));
                    const evt = new ShowToastEvent({
                        title: "Error!",
                        message: "Attachment not updated.",
                        variant: "error",
                    });
                    this.dispatchEvent(evt);
                })
                .finally(() => {
                    this.blnIsLoading = false;
                });    
            } else {
                const evt = new ShowToastEvent({
                    title: "Success!",
                    message: "The Case record has been successfully created.",
                    variant: "success",
                });
                this.dispatchEvent(evt);
                this.blnIsLoading = false;
            }  
        });
    }

    get selectedValues() {
        return this.attachmentValue.join(',');
    }

    selectAttachment(event) {
        this.attachmentValue = event.detail.value;
    }
    
    handleSubmitClick(){
        this.blnIsLoading = true;
    }

    handlePageLoading(){
        this.blnIsLoading = false;
    }

    closeModal(){        
        const evtCloseTab = new CustomEvent('closemodal');
        // Fire the custom event
        this.dispatchEvent(evtCloseTab);
    }
}