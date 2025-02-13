import { LightningElement, track, api, wire } from 'lwc';

import displayTemplatebyName from '@salesforce/apex/SearchEmailTemplate_LEX.displayTemplatebyName';
import fetchLastEmailSubject from '@salesforce/apex/SearchEmailTemplate_LEX.fetchLastEmailSubject';
import fetchAllEmailTemplateFolders from '@salesforce/apex/SearchEmailTemplate_LEX.fetchAllEmailTemplateFolders';

export default class SearchEmailTemplateLwcCmp extends LightningElement {
    @api recordId;

    @track list_searchFieldsMaster = [];
    @track lst_folderOptions = [];
    @track strSelectedField;
    @track list_selectedCaseFields = [];
    @track blnIsLoading = false;    
    @track lst_allTemplateMasterRecords = [];
    @track lst_filteredEmailTemplateRecords = [];
    @track lst_allTemplateFoldersMasterRecords = [];
    @track bln_showRecords = false;
    @track strBody = '';    
    @track strBodyToSend; // To store the html value of email template    
    @track strSubject; // To store the subject for email template while modifying    
    @track strEncoding; // To store the encoding value for email template while creating a record in EmailMessage
    @track strEmailTemplateSelectedName; // To store the Name of the template selected
    @track strEmailTemplateSelected
    boolTemplateSelected = false;
    /* Flag to show email body */
    @track blnShowTemplateBody = false;
    @track blnShowTemplateOnHover = false;
    @track strSubjectValue='';
    @track mapfolderToTemplates=[];
    @track strSelectedFoldervalue ='All Templates';
    @track lst_allTemplateRecords = [];
    selectedEmailTemplateId ;
    lst_allEmailTemplates = [];
    strEmailTemplateName = '';
    map_emailTemplateIdVsEmailTemplateRecord = new Map();    

    connectedCallback() {
        this.allEmailTemplates();
    }

    handleBodyChange(event) {
        this.strBody = event.detail.value;
    }
    @api
    get blnShowTable() {
        return this.lst_filteredEmailTemplateRecords.length > 0 ? true : false;
    }

    allEmailTemplates() {
        this.blnIsLoading = true;
        fetchAllEmailTemplateFolders() 
        .then(result => {
            try {
                
                this.bln_showRecords = false;
                this.blnIsLoading = false; 
                let list_folders = [{ label: 'All Templates', value: 'All Templates' }];
                this.mapfolderToTemplates.push({ value: 'All Templates', key: 'All Templates' });

                let list_templates = [];
                if (result) {
                    for (let key in result) {
                        if (result.hasOwnProperty(key)) { 
                            let intIndex = key.indexOf("-"); 
                            let strFolderName = key.substr(intIndex + 1); 
                            list_folders.push({ label: strFolderName, value: key });
                            this.mapfolderToTemplates.push({ value: result[key], key: key });
                            let intResultKeyLength = result[key].length;
                            for (let i = 0; i < intResultKeyLength; i++) {
                                list_templates.push(result[key][i]);  
                            }
                        }
                    }

                    this.lst_allTemplateFoldersMasterRecords = list_folders;
                    this.lst_allTemplateMasterRecords = list_templates;
                    this.lst_allTemplateRecords = list_templates;
                    if(this.lst_allTemplateMasterRecords)
                        this.lst_filteredEmailTemplateRecords = this.lst_allTemplateMasterRecords.slice(0, 50);
               }
            } catch (error) {
                this.blnIsLoading = false;
                console.error('in catch Either data is not there or something is not right');
            }
        });        
    }

    handleFilterList(event) {
        this.blnIsLoading = true;
        let value = event.target.value ? event.target.value : '';           
        if (this.list_searchFieldsMaster && this.strSelectedFoldervalue) {
            this.lst_filteredEmailTemplateRecords = [];              
            if (value !=='') {
                let i = 0;
                this.lst_allTemplateMasterRecords.forEach(r=>{
                    if (r.Name.toLowerCase().includes(value.toLowerCase())) {
                        if (i < 50) {
                             this.lst_filteredEmailTemplateRecords.push(r);
                            i = i + 1;
                        }
                    }
                });
                this.blnShowTemplateBody = false;
                this.bln_showRecords = true;
                this.blnIsLoading = false;
            } else {
                console.log('I am here >>>')
                this.bln_showRecords = false;
                if(this.lst_allTemplateMasterRecords)
                    this.lst_filteredEmailTemplateRecords = this.lst_allTemplateMasterRecords.slice(0, 50);
                this.blnIsLoading = false;
                this.strBody = null;
            }            
        } else {      
                console.log('Folder not Selected >>>');
                this.bln_showRecords = false;
                this.blnIsLoading = false;
                this.strBody = null;
              }
        }
    

    handleLinkHover(event){
        let strTemplateId = event.currentTarget.dataset.idval;
        this.blnIsLoading = true;
        if (strTemplateId) {            
            displayTemplatebyName({strTemplateIdValue: strTemplateId})
            .then(result => {
                this.strBodyToSend = result.HtmlValue;
                this.strBody = result.HtmlValue;
                this.strSubject = result.Subject;
                this.strEncoding = result.Encoding;
                this.strEmailTemplateName = result.Name;
                this.selectedEmailTemplateId = result.Id;
            })
            .catch (error => {
                this.blnIsLoading = false;
                console.log('in catch Either data is not there or something is not right' + JSON.stringify(error));
            })
            this.blnShowTemplateBody = true;
            this.boolTemplateSelected = true;   
            this.blnShowTemplateOnHover = true;
            this.bln_showRecords = false;     
        } 
        this.blnIsLoading = false;        
    }  
    // Get email templates in selected Folder
    handleFolderNameChange(event) {
        this.strSelectedFoldervalue = event.detail.value;
        let strFolder = event.detail.value;
        this.blnIsLoading = true;

        if (strFolder) { 
            if (strFolder === 'All Templates'){
                let emailtemplate;
                this.lst_allTemplateMasterRecords = this.lst_allTemplateRecords;	
                let listTemplateRecordsLength = this.lst_allTemplateMasterRecords.length;
                for (let j = 0; j < listTemplateRecordsLength; j++) {
                    emailtemplate = this.lst_allTemplateMasterRecords[j];
                    this.list_searchFieldsMaster.push(emailtemplate.Name); 
                }
                if(this.lst_allTemplateMasterRecords)
                    this.lst_filteredEmailTemplateRecords = this.lst_allTemplateMasterRecords.slice(0, 50);
            } else {
                let value; 
                for (let i = 0; i < this.mapfolderToTemplates.length; i++) {
                    if (this.mapfolderToTemplates[i].key === strFolder) {
                        value=this.mapfolderToTemplates[i].value;
                    }
                } 

                if (value) {
                    this.lst_allTemplateMasterRecords = value;  
                    for (let j = 0; j < value.length; j++) {
                        this.list_searchFieldsMaster.push(value[j].Name);
                    }
                    if(this.lst_allTemplateMasterRecords)
                        this.lst_filteredEmailTemplateRecords = this.lst_allTemplateMasterRecords.slice(0, 50);
                }
            } 
        }

        this.blnIsLoading = false;        
    } 
    
    handleOpenEmailTemplatePusblisher(event) {        
        this.blnIsLoading = true;
        if (event.target.value !== undefined && event.target.value !== '') {
            this.selectedEmailTemplateId = event.target.value;
        }
        fetchLastEmailSubject({strRecordId: this.recordId})
        .then(result=>{
            this.strSubjectValue = result.strSubject;
            var strBodyFull = this.strBody;
            const evtOpenTab = new CustomEvent('opentab', {
                detail: {fullhtmlbody: strBodyFull, subjectstr: this.strSubjectValue, strId: result.strId},
            });
            // Fire the custom event
            this.dispatchEvent(evtOpenTab);
            this.blnIsLoading = false;
            this.strBody = '';
        }).catch (error => {
            this.blnIsLoading = false;
            console.log('fetchLastEmailSubject>>> ' + JSON.stringify(error));
        });
    }

    handleTemplateMouseOver(event) {
        this.blnShowTemplateOnHover = true;
    }
    handleTemplateMouseOut(event) {
        this.blnShowTemplateOnHover = false;
    }
}