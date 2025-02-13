import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

/* Imported Methods from FilesComponentController Class */
import returnFilesList from '@salesforce/apex/FilesComponentController.returnFilesList';
import renameFile from '@salesforce/apex/FilesComponentController.renameFile';
import getAttachmentRecord from '@salesforce/apex/FilesComponentController.getAttachmentRecord';

export default class Filespreviewlwc extends NavigationMixin(LightningElement) {
    
    /* Record Id fetched from Page */
    @api recordId;

    /* Flag to show spinner component - If set to true, will show spinner on the UI */
    @track blnIsLoading = false;    
    /* to store the values of files and display it on the UI */
    @track arr_Data = [];
    /* to store the count of files*/
    @track intDataSize = 0;
    /* to store the check for files*/
    @track blnHasData = false; 
    /* to store the check to show hide attachment*/
    @track bnlShowHideAttachment =false;
    /* to store the url of the file or attachemnt*/
    @track strUrl;
    // to store the intance of the org
    strInstance;
    // to store the checkbox value
    @track blnCheckboxChecked = true;
    // to check if the modal is open or not
    @track blnIsOpenModal = false;
    // to store the selected file name
    @track strSelectedFilename = '';
    // attach the case id for the upload file
    @track idCase;
    // to store the seleced file id
    @track idSelectedFile;
    // to get the new file name to save
    @track strNewfilename;
    // to keep a check whether the file is attachment or not
    blnIsfileAttachment;
    // to store the part of the record ID
    partrecordId;


    @track strFileTypeDynamic = '';
    @track strCurrentFilename = '';
    @track strCurrentFileContentType = '';
    @track strCurrentAttachmentBody = '';
    @track strCurrentAttachmentRecordId = '';
    
    // on load get the files records from the database and populate it to a variable to show it in UI.
    connectedCallback() {

        this.blnIsLoading = true
        returnFilesList({IdCaseRecord: this.recordId, checksize : this.blnCheckboxChecked})
        .then(result=>{
            if(result && result.blnIsSuccess) {
                this.arr_Data = result.map_ResponseData.attachments;
                //console.log('this.data>>'+ JSON.stringify(this.arr_Data));
                this.arr_Data.forEach(element => {
                    element.fileSize = parseInt(element.fileSize / 1024);
                    if(element.fileUrl.includes('servlet')){
                        element.fileAttachmentType = true;
                        element.contentType = element.fileType;
                        element.fileType = element.fileType.substring(element.fileType.indexOf('/') + 1, element.fileType.length);
                    }
                });
                this.intDataSize = (result.map_ResponseData.attachments).length;
                this.strInstance = result.map_ResponseData.strInstance;         
                this.blnHasData = true;
                this.blnIsLoading = false;                
            } else {
                this.blnIsLoading = false;
                this.blnHasData = false;
                this.intDataSize = 0; 
            }
            if(result) {
                this.idCase = result.idCase;
            }
        }).catch(error=>{
            this.blnIsLoading = false;
            console.error('Filespreviewlwc - connectedCallback -->'+error);
        }); 
    }

    /**? to handle the change event of the checkbox, to get the files of large size or small size */
    handleAttachmentSize(event) {
        this.blnCheckboxChecked = event.target.checked;
        this.bnlShowHideAttachment = false;
        this.connectedCallback();
    }
    
    /** This method is called when the file name is clicked to be previewed. 
     * It displays the file Preview by the Aura Component if file and LWC if attachment */
    handleUrlclick(event){
        let attachmentRecordId = event.target.dataset.attachid;
        let attachmentRecordURL = event.currentTarget.dataset.fileurl;
        if(attachmentRecordURL !== '' && !attachmentRecordURL.includes('servlet')) {
            const action = new CustomEvent('fileclick', {
                detail: { attachedfileId :  attachmentRecordId} 
            });
            this.dispatchEvent(action); 
        } else {
            this.strUrl = attachmentRecordURL;  
            this.bnlShowHideAttachment = true;
            this.blnIsLoading = false;
            this.strFileTypeDynamic = event.currentTarget.dataset.fileType;
            this.strCurrentFilename = event.currentTarget.dataset.filename;
            this.strCurrentFileContentType = event.currentTarget.dataset.contenttype;         
            this.strCurrentAttachmentBody = event.currentTarget.dataset.attachmentbody;       
            this.strCurrentAttachmentRecordId = event.currentTarget.dataset.attachid;          
        }
    }

    /**This method is called when we click on the download icon of attachment */
    handleDownloadAttachment(){
        this.blnIsLoading = true;
        getAttachmentRecord({attId : this.strCurrentAttachmentRecordId})
        .then(result => {
            if(result.blnIsSuccess) {
                let anchorTag = document.createElement('a');
                anchorTag.setAttribute('href', 'data:image/png;base64,' + result.strEncodedString);
                anchorTag.setAttribute('download', this.strCurrentFilename);
                document.body.appendChild(anchorTag);
                anchorTag.click();
                document.body.removeChild(anchorTag);
            } else {
                this.showToast(result.strMessage,' ','error');
            }
            this.blnIsLoading = false;
        });
    }
    /**This method is called when we click on the file icon to open the file record as a sub tab */
    handleOpenContentDocument(event){
        let attachmentRecordURL = event.currentTarget.dataset.fileurl;
        let attachmentRecordName = event.currentTarget.dataset.filename;
        if(attachmentRecordURL !== '' && !attachmentRecordURL.includes('servlet')) {
            attachmentRecordURL += '/lightning/r/ContentDocument/'+event.target.value+'/view';
            const action = new CustomEvent('tabOpen', {
                detail: { attachedfileurl : attachmentRecordURL, attachmentfileName : attachmentRecordName } 
            });
            this.dispatchEvent(action);
        } else {
            const action = new CustomEvent('attachtabopen', {
                detail: { attachmentRecId : event.target.value, attachRecUrl : attachmentRecordURL } 
            });
            this.dispatchEvent(action);
        }
        
    }

    /**This method is called to after the file is uploaded to rerender the list of the files dynamically */
    handleUploadFinished(event) {
        this.connectedCallback();
    }

    /**to open the modal of the selected file with all the current information.  */
    handleOpenModal(event) {
        this.blnIsOpenModal = true;
        this.strSelectedFilename = event.currentTarget.dataset.filename;
        this.idSelectedFile = event.currentTarget.dataset.fileid;        
        this.blnIsfileAttachment = event.currentTarget.dataset.filetype;        
    }
    /** to change the name of the selected file */
    handleNameChange(event) {
        this.strNewfilename = event.target.value;
        //console.log('>>>>>' + this.strNewfilename);
        this.strSelectedFilename = this.strNewfilename;
    }
    /**closes the modal */
    handleCloseModal(event) {
        this.blnIsOpenModal = false;
        this.bnlShowHideAttachment = false
    }
    /** to perform th save operation when a file is renamed from the dialog box */
    handleSave(event) {
        //console.log('this.strSelectedFilename>>>'+this.strSelectedFilename);
        if(this.strSelectedFilename !== '') {
            renameFile({strNewName : this.strSelectedFilename, idDoc : this.idSelectedFile, blnIsfileAttach : this.blnIsfileAttachment })
            .then(result=>{
                //console.log('result>>'+JSON.stringify(result));
                this.connectedCallback();
                this.showToast('Success','File renamed','success');
                
            })
            .catch(error=>{
                this.blnIsLoading = false;
                //console.log('error>>>'+ JSON.stringify(error));
            });
        } 
        this.strNewfilename = null;
        this.blnIsOpenModal = false;        
    }
    showToast(title,message,variantType) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variantType,
        }); 
        this.dispatchEvent(event);
    }
}