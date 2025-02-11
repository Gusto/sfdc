import { LightningElement, track, api, wire } from 'lwc';
import queryQueues from '@salesforce/apex/MassEmail_LEX.queryQueues';
import fetchCaseReasons from '@salesforce/apex/MassEmail_LEX.fetchCaseReasons';
import fetchSearchResults from '@salesforce/apex/MassEmail_LEX.fetchSearchResults';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import fetchEmailFolderNames from '@salesforce/apex/MassEmail_LEX.fetchEmailFolderNames';
import fetchEmailTemplate from '@salesforce/apex/MassEmail_LEX.fetchEmailTemplate';
import displayTemplate from '@salesforce/apex/MassEmail_LEX.displayTemplate';
import sendEmail from '@salesforce/apex/MassEmail_LEX.sendEmail';
import fetchAllEmailTemplates from '@salesforce/apex/MassEmail_LEX.fetchAllEmailTemplates';
import ignoreCases from '@salesforce/apex/MassEmail_LEX.ignoreCases';


const actions = [
    { label: 'Open Case', name: 'open_case' }
];


// Fields to be shown in the data table
const columns = [
    { label: 'Case Number', fieldName: 'CaseNumber', type: 'string',wrapText: true,initialWidth: 100},
    { label: 'Subject', fieldName: 'Subject', type: 'string',wrapText: true},
    { label: 'Description', fieldName: 'Description', wrapText: true},
    { label: 'Type', fieldName: 'Type',initialWidth: 100,wrapText: true},
    { label: 'Confidence', fieldName: 'Confidence', type: 'number',initialWidth: 100,wrapText: true},
    { label: 'Owner', fieldName: 'OwnerName', type: 'text',initialWidth: 100,wrapText: true},
    { label: 'Contact', fieldName: 'ContactName', type: 'text',initialWidth: 10,wrapText: true},
    {
        type: 'action',
        typeAttributes: { rowActions: actions }
    }
];
export default class MassEmail extends LightningElement {
    //the sections of the page open on load
    activeSections = ['Case Filters', 'Template Preview', 'Cases'];

    //columns of the case list
    columns = columns;
    data = [];
    // To store the values of EmailTemplate Folder Names in picklist
    @track list_emailOptions = [];
    // To store the values of EmailTemplates based on the template folder selected
    @track list_emailTemplateoptions = [];
    @track lst_emailTemplateLabel = [];
    @track list_QueueRecs = [];
    /* Flag to show email template picklist */
    @track blnShowEmailTemplate = false;
    /* Flag to show email body */
    @track blnShowTemplateBody = false;
    // To store the Id and Name of Email Template
    @track templateNameMap = new Map();
    // To store the html value of email template
    @track strBodyToSend;
    // To store the values of selected cases to send email
    @track set_CaseWrapper = new Set();
    // To store the subject for email template while modifying
    @track strSubject;
    // To store the encoding value for email template while creating a record in EmailMessage
    @track strEncoding;
    // To check whether any queue is found on the basis of search string
    @track blnIsQueueFound = true;
    // To store the Id of the template selected
    @track strEmailTemplateFolderSelected;
    // To store the Name of the template selected
    @track strEmailTemplateSelectedName;
    @track strEmailTemplateSelected; //just the id, delete
    // To store the name of Case Reason Selected
    @track strCaseReasonSelected;
    @track blnKeepOpen = false;
    // To store the vlaue of Queue selected
    @track strQueueValueSelected;
    @track list_FilteredQueues = [];
    //boolViewTemplate = false;
    blnViewTemplate = false;
    boolTemplateSelected = false;
    // Flag to check whether the template is being modified or not
    blnModifying = false;
    strBody = '';
    emailTemplateToSend = { 'sobjectType': 'EmailTemplate' };
    strEmailTemplateName = '';
    // Flag for spinner
    blnSpin = false;
    list_Formats = ['font', 'size', 'bold', 'italic', 'underline',
        'strike', 'list', 'indent', 'align', 'link',
        'image', 'table', 'header', 'color'];
    //Flag to disable the Ignore button
    @track blnIsIgnoreButtonDisabled = true;
    //Flag to Show/ Hide modal when ignoring Case
    @track blnShowConfirmDialog = false;

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'open_case':
                this.openCase(row);
                break;
            default:
        }
    }

    openCase(row) {
        const { id } = row;
        const index = this.findRowIndexById(id);
        if (index !== -1) {
            var strId = row.Id;
            this.dispatchEvent(
                new CustomEvent('opencase', {
                    detail: { strId }
                })
            );
        }
    }

    findRowIndexById(id) {
        let ret = -1;
        this.data.some((row, index) => {
            if (row.id === id) {
                ret = index;
                return true;
            }
            return false;
        });
        return ret;
    }

    //handleFilterSelected(event) {
    handleQueueFilterSelected(event) {
        this.queue = event.detail;
    }

    handleOpenCases(event){
        console.log('-------------   '+event.target.checked);
        this.blnKeepOpen = event.target.checked;
    }

    connectedCallback() {
        this.loadQueues();
        this.allEmailTemplates();

    }
    //get all case queues
    loadQueues() {
        this.isLoading = true;
        queryQueues()
            .then(result => {
                if (result) {
                    let resultQueues = result;
                    let list_tempQueues = [];
                    //console.log('--resultqueue '+resultQueues);
                    resultQueues.forEach(eachQueue => {
                        list_tempQueues.push({
                            label: eachQueue.Name,
                            value: eachQueue.Id
                        });
                    });
                    this.list_QueueRecs = list_tempQueues;
                    this.list_FilteredQueues = list_tempQueues;
                    if (this.list_FilteredQueues.length === 0) {
                        this.blnIsQueueFound = false;
                    }
                }
                this.isLoading = false;
            })
            .catch(error => {
                // If there is an Exception, Show Error Message on the UI
                this.error = error;
                this.isLoading = false;
            });
    }

    //filter the queues based on input
    handleFilterRecords(event) {
        let input = event.detail;
        let list_Queues = [];
        let list_QueueRecs = this.list_QueueRecs;
        //console.log('--... '+list_QueueRecs);
        list_QueueRecs.forEach(queue => {
            let boolFound = false;
            //caseReasonToAdd.group = caseReason.group;
            if (queue.label.toLowerCase().includes(input.toLowerCase())) {
                list_Queues.push(queue);
                boolFound = true;
            }


        })

        this.list_FilteredQueues = list_Queues;
        if (list_Queues.length === 0) {
            this.blnIsQueueFound = false;
        } else {
            this.blnIsQueueFound = true;
        }

    }

    //get the cases selected
    getSelectedName(event) {
        const selectedRows = event.detail.selectedRows;
        this.blnIsIgnoreButtonDisabled = true;
        // Display that fieldName of the selected rows
        this.set_CaseWrapper = new Set();
        for (let i = 0; i < selectedRows.length; i++) {
            this.set_CaseWrapper.add(selectedRows[i].Id)
            this.blnIsIgnoreButtonDisabled = false;
            ////console.log("You selected: " + selectedRows[i].Id);
        }
    }

    //send email to cases
    sendEmail() {
        if (this.set_CaseWrapper.size < 1) {
            const event = new ShowToastEvent({
                title: '',
                variant: 'error',
                message: 'No case Selected',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
            return;
        } else if (this.strEmailTemplateSelected == null || this.strEmailTemplateSelected == undefined) {
            const event = new ShowToastEvent({
                title: '',
                variant: 'error',
                message: 'Please select a template',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
            return;
        }
        this.blnSpin = true;
        let list_CaseIdsToSend = Array.from(this.set_CaseWrapper);

        this.emailTemplateToSend.HtmlValue = this.strBodyToSend;
        this.emailTemplateToSend.Subject = this.strSubject;
        this.emailTemplateToSend.Encoding = this.strEncoding;
        this.emailTemplateToSend.Name = this.strEmailTemplateName;
        let strTemplateToSend = JSON.stringify(this.emailTemplateToSend);
        ////console.log('!! ' + strTemplateToSend);
        sendEmail({ strEmailTemplateJSON: strTemplateToSend, list_CaseIds: list_CaseIdsToSend , boolLetCaseBeOpen: this.blnKeepOpen})
            .then(result => {
                const event = new ShowToastEvent({
                    title: '',
                    variant: 'Success',
                    message: 'Email has been sent Successfully',
                    mode: 'dismissable'
                });
                this.blnSpin = false;
                this.dispatchEvent(event);
            })
            .catch(error => {
                console.log('!!! error' + JSON.stringify(error));
                const event = new ShowToastEvent({
                    title: '',
                    variant: 'error',
                    message: error.body.message,
                    mode: 'dismissable'
                });
                this.blnSpin = false;
                this.dispatchEvent(event);
            })
    }

    //get the selected queue
    handleRecordSelected(event) {
        this.strQueueValueSelected = event.detail.name;
        console.log('strQueueValueSelected::' + this.strQueueValueSelected);
        this.allCaseReasons();
    }

    //handle case reason selected
    handleChange(event) {
        this.strCaseReasonSelected = event.detail.value;
    }

    //handle template being modified
    handleModifyTemplate() {
        this.blnShowTemplateBody = true;
        this.blnModifying = true;
    }

    //handle cancel modify button clicked
    handleCancelModify() {
        this.strBody = this.strBodyToSend
        this.blnModifying = false;
        this.blnShowTemplateBody = false;
        ////console.log('! ', this.strBodyToSend);
    }

    //handle body of template is changed
    handleBodyChange(event) {
        this.strBody = event.detail.value;
    }
    //handle confirming the changes to the template
    handleSaveTemplate() {
        this.strBodyToSend = this.strBody;
        this.blnModifying = false;
        this.blnShowTemplateBody = false;
        ////console.log('! ', this.strBodyToSend);
    }

    //handle template being selected
    handleTemplateChange(event) {
        this.strEmailTemplateSelected = event.detail.value;
        this.strEmailTemplateSelectedName = this.templateNameMap.get(event.detail.value);
        displayTemplate({ strTemplateId: this.strEmailTemplateSelected })
            .then(result => {
                this.strBodyToSend = result.HtmlValue;
                this.strBody = result.HtmlValue;
                this.strSubject = result.Subject;
                this.strEncoding = result.Encoding;
                this.strEmailTemplateName = result.Name;
            })
        this.blnShowTemplateBody = false;
        this.boolTemplateSelected = true;
    }

    //search for cases
    handleSearch() {
        console.log('handleSearch method: ');
        console.log(this.strQueueValueSelected);
        console.log(this.strCaseReasonSelected);
        fetchSearchResults({ strQueueName: this.strQueueValueSelected, strCaseReason: this.strCaseReasonSelected })
            .then(result => {
                console.log('handleSearch()');
                console.log(result);
                this.data = [];
                if (result.length > 0) {
                    this.data = result.map(item => {
                        let caseObj = { ...item }
                        caseObj.OwnerName = item.Owner.Name;
                        caseObj.ContactName = item.Contact.Name;
                        return caseObj;
                    });
                    const event = new ShowToastEvent({
                        title: 'Search Successful',
                        variant: 'success',
                        message: '',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(event);
                }
                else {
                    const event = new ShowToastEvent({
                        title: 'No Records Found',
                        variant: 'error',
                        message: '',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(event);
                }
            })
            .catch(error => {

            })
    }


    @wire(fetchEmailFolderNames)
    emailTemplates({ data, error }) {
        if (data) {
            let templateNameList = [];
            try {
                for (let key in data) {
                    templateNameList.push({label: data[key], value: key});
                }
                //console.log('--templa' +this.list_emailOptions);
                this.list_emailOptions = [...templateNameList];
            }
            catch (error) {
                console.log('Error :'+ error);
            }
        }
        else {
        }
    }

    // store the list of emailTemplates
    @track list_searchFieldsMaster = [];
    // store the list of emailTemplate names from the org
    @track list_allEmailOptions = [];
    // stores the list of case reasons on the basis of queue selected
    list_allCaseReasons;
    strSelectedField;
    strSelectedCaseReason;
    list_allEmailTemplates;

    allEmailTemplates() {

        this.list_allEmailTemplates = [];
        //this.strSelectedField = '';
        fetchAllEmailTemplates()
            .then(result => {
                try {
                    let templateOptions = [];
                    let templateOptionsList = [];
                    this.templateNameMap.clear();
                    result.forEach(item => {
                        //console.log('JSON.stringify(item.Name)'+ JSON.stringify(item.Name));
                        templateOptionsList.push(item.Name);

                    })
                    //this.list_allEmailOptions = [...templateOptions];
                    this.list_allEmailOptions = [...templateOptionsList];
                    this.list_allEmailTemplates = [...templateOptionsList];
                    this.list_searchFieldsMaster = [...templateOptionsList];
                }
                catch (error) {
                    ////console.log('in catch Either data is not there or something is not right');
                }
            })
            .catch((error) =>{
                ////console.log('Error: '+error.body.message);
            });
    }

    allCaseReasons() {

        this.list_allCaseReasons = [];
        this.strSelectedCaseReason = '';
        fetchCaseReasons({ strQueueName: this.strQueueValueSelected })
            .then(result => {
                try {
                    //this.isAllCaseReason = true;
                    let templateOptions = [];
                    let templateOptionsList = [];
                    this.templateNameMap.clear();
                    this.selectedvalue = '';
                    console.log('--allCaseReasons() result---');
                    console.log(result);
                    if(result) {
                        result.forEach(item => {
                            if (!templateOptions.includes(item.Routing_Case_Reason_Classification__r.Name)) {
                                templateOptionsList.push(item.Routing_Case_Reason_Classification__r.Name);
                            }
                            templateOptions.push(item.Routing_Case_Reason_Classification__r.Name);
                        });
                        this.list_allCaseReasons = [...templateOptionsList];
                        this.originalCasereasonList = [...templateOptionsList];
                    }
                }

                catch (error) {
                    console.log('in catch Either data is not there or something is not right');
                }

            })
            .catch((error) => {
                ////console.log('Error: ' + error.body.message);
            });


    }
    // Store All Case Reason list in an array
    @track originalCasereasonList;
    handleFilteredCaseReasonList(event) {

        let value = (event.detail.length > 0) ? event.detail : '';
        this.strSelectedCaseReason = value;
        console.log('this.strSelectedCaseReason ::'+this.strSelectedCaseReason);

        let arrFieldSearchList = [];
        let counter = 0;
        if (this.originalCasereasonList) {
            if(value !== '') {
                arrFieldSearchList = this.originalCasereasonList.filter(eachField => {
                    return (eachField.toLowerCase().indexOf(value.toLowerCase()) !== -1);
                });
                this.list_allCaseReasons = arrFieldSearchList;
            }  else {
                this.list_allCaseReasons = this.originalCasereasonList;
            } 
        }
    }

    handleFilterCaseReasonSelected(event) {
        let varEvent = event.detail;
        this.strSelectedCaseReason = varEvent;
        this.strCaseReasonSelected = varEvent;
    }

    handleFilterList(event) {
        console.log('onmouseOver--:');
        console.log(event.detail);
        ////console.log('list_searchFieldsMaster>>>' + JSON.stringify(this.list_searchFieldsMaster));
        let value = event.detail ? event.detail : '';
        let arrFieldSearchList = [];
        let counter = 0;
        
        console.log(this.list_searchFieldsMaster);
        if (this.lst_emailTemplateLabel.length>0) {
            if(value !== '') {
                arrFieldSearchList = this.list_searchFieldsMaster.filter(eachField => {
                    return (eachField.toLowerCase().indexOf(value.toLowerCase()) !== -1);
                });
                this.lst_emailTemplateLabel = arrFieldSearchList;
            }  else {
                //this.strSelectedCaseReason = '';
                this.lst_emailTemplateLabel = this.list_searchFieldsMaster;
            } 
            //this.lst_emailTemplateLabel = arrFieldSearchList;
        }
        ////console.log('list_searchFieldsMaster>>>' + JSON.stringify(this.list_searchFieldsMaster));
    }

    handleFilterSelected(event) {
        console.log('onmouseOver1--:');
        console.log(event.detail);
        if (event.detail) {
            console.log(event.detail);
            this.strSelectedField = event.detail;
            this.list_emailTemplateoptions.forEach(item => {
                if (item.label === this.strSelectedField) {
                    this.strEmailTemplateSelectedName = this.strSelectedField;
                    this.strEmailTemplateSelected = item.value;
                    displayTemplate({ strTemplateId: this.strEmailTemplateSelected })
                        .then(result => {
                            this.strBodyToSend = result.HtmlValue;
                            this.strBody = result.HtmlValue;
                            this.strSubject = result.Subject;
                            this.strEncoding = result.Encoding;
                            this.strEmailTemplateName = result.Name;
                            // this.template.querySelector('.elementHoldingHTMLContent').value = result.HtmlValue;
                        })
                    //this.template.querySelector('.modifyTemplateClass').style.display='block';
                    this.blnShowTemplateBody = false;
                    this.boolTemplateSelected = true;
                }
            });
        }

    }


    //handle email template folder being changed
    handleEmailChange(event) {
        this.strEmailTemplateFolderSelected = event.detail.value;
        if (this.strEmailTemplateFolderSelected != '--None--') {
            fetchEmailTemplate({ idFolder: this.strEmailTemplateFolderSelected })
                .then(result => {
                    let templateOptions = [];
                    this.lst_emailTemplateLabel = [];
                    this.templateNameMap.clear();
                    //console.log('---result1 '+JSON.stringify(result));
                    result.forEach(item => {
                        if (!this.templateNameMap.has(item.Id)) {
                            let obj = {
                                label: item.Name, value: item.Id
                            }
                            templateOptions.push(obj);
                            this.lst_emailTemplateLabel.push(item.Name);
                            this.list_searchFieldsMaster = [...this.lst_emailTemplateLabel];
                        }
                        if (!this.templateNameMap.has(item.Id)) {
                            this.templateNameMap.set(item.Id, item.Name);
                        }
                    })
                    this.list_emailTemplateoptions = [...templateOptions];
                    this.blnShowEmailTemplate = true;
                    this.blnShowTemplateBody = false;
                })

        }
        else {
            this.blnShowEmailTemplate = false;
        }

    }
    //get cases from queue provided
    @wire(fetchCaseReasons, { strQueueName: '$strQueueValueSelected' })
    casereasons({ data, error }) {
        ////console.log(data);
        ////console.log('--data--');
        if (data) {
            try {
                let caseReason = [];
                let caseReasonOptions = [];
                //console.log('--data--- '+JSON.stringify(data));
                data.forEach(item => {

                    if (!caseReason.includes(item.Routing_Case_Reason_Classification__r.Name)) {
                        let obj = {
                            label: item.Routing_Case_Reason_Classification__r.Name,
                            value: item.Routing_Case_Reason_Classification__r.Name
                        }
                        caseReasonOptions.push(obj);
                    }

                    caseReason.push(item.Routing_Case_Reason_Classification__r.Name);

                });
                this.list_caseReasonOptions = [...caseReasonOptions];
            }
            catch (error) {
            }
        } else {
            ////console.log('--error--11' + JSON.stringify(error));
        }
    }

    //To show/hide the ignore case modal
    handleToggelModal() {
        this.blnShowConfirmDialog = !this.blnShowConfirmDialog;
    }

    //To ignore the selected cases
    handleIgnoreCases(event) {
        this.blnSpin = true;
        let list_CaseIdsToSend = Array.from(this.set_CaseWrapper);
        ignoreCases({ list_CaseIds: list_CaseIdsToSend })
            .then(result => {
                if (result === 'Success') {
                    this.blnShowConfirmDialog = false;
                    this.blnSpin = false;
                    this.showToastMessage(
                        'Success',
                        'success',
                        'Case(s) ignored successfully!'
                    );
                } else {
                    this.blnShowConfirmDialog = false;
                    this.blnSpin = false;
                    this.showToastMessage(
                        'Error',
                        'error',
                        result
                    );
                }
            })
            .catch(error => {
                this.error = error;
                this.blnShowConfirmDialog = false;
                this.blnSpin = false;
                this.showToastMessage(
                    'Error',
                    'error',
                    error
                );
            });
    }

    showToastMessage(strTitle, strVariant, strMessage) {
        const event = new ShowToastEvent({
            title: strTitle,
            variant: strVariant,
            message: strMessage
        });
        this.dispatchEvent(event);
    }
}