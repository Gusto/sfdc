import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

/** importing the methods from the class */
import returnCaseList from '@salesforce/apex/LWC_MergeCaseController.returnCaseList';
import mergeSeletedCase from '@salesforce/apex/LWC_MergeCaseController.mergeSeletedCase';
import getSelectedCaseRecord from '@salesforce/apex/LWC_MergeCaseController.getSelectedCaseRecord';

export default class MergeCaseLwcCmp extends LightningElement {
    /** Declaring Variables */

    /** getting the current record Id from the Parent component */
    @api recordId; 
    /** capturing current case number to show on UI */
    @track strCurrentCaseNumber;
    /** capturing current Case record */
    @track objCurrentCase;
    /** checking the list of open cases*/
    @track blnOnlyOpenCases = true;
    /** store the list of cases related with the current Case*/
    @track arrData = [];
    /* Flag to show spinner component - If set to true, will show spinner on the UI */
    @track blnIsLoading = false;
    /** check if the current case has case related to it or not */
    @track blnHasData;
    /** storing case values from the UI that needs to be searched */
    @track strCaseNumber = '';
    @track strInputChecked = true;
    /** Storing the list of case ids that needs to be merged with another case */
    list_CaseIds = [];
    /** Storing the list of case numbers that needs to be merged with another case */
    list_CaseNumbers = [];
    /** selected case numbers in string to be shown on the UI */
    @track strSelectedCaseNumbers = '';
    /** to check whether to show the case numbers on the UI or Not */
    @track blnShowCaseNumberCount = false;
    /** to enable disble the buttons after some logic check */
    @track blnDisableMergeAndCloseCurrentCaseButton = false;
    @track blnDisableMergeAndCloseSelectedCaseButton = false;
    // label to be displayed on the button
    @track strMergeandCloseCaseLabel = '';
    
    @track strSelectedCaseRecordNumber;
    // getting selected case record to perform operation
    arrSelectedCaseRecord = [];
    // storing case numbers to perform some operation
    strSelectedCaseNumbersDummy = '';
    // storing the data from the database to perfrom some logic and store back to the main list
    arrDataArray = [];

    connectedCallback() { 
        this.callCaseList();
    }

    /** called when the Case Number to be searched from text box is changed */
    handleCaseNumberChange(event) {        
        this.strCaseNumber = event.target.value;
        if(this.strCaseNumber !== '' ) {
            this.strCaseNumber = this.strCaseNumber.trim();
            this.strInputChecked = false;
            this.blnOnlyOpenCases = false;
        }

        var inputCaseNumber = this.template.querySelector('.case-number-input');
        var blnIsValid = inputCaseNumber.reportValidity();
        if (blnIsValid) {
            setTimeout(this.callCaseList.bind(this), 500);
        }
    }

    /** called when we only want non closed cases or all of the cases. The true will give the list of cases which are not closed. */
    handleInputChange(event) {
        this.strInputChecked = event.target.checked;
        this.blnOnlyOpenCases = this.strInputChecked;
        this.callCaseList();
    }
    
    callCaseList() {
        
        this.blnIsLoading = true;
        this.arrData = null;
        this.arrData = [];
        this.arrDataArray = [];
        this.list_CaseNumbers = [];
        this.strSelectedCaseNumbers = '';
        this.list_CaseIds = [];
        this.blnShowCaseNumberCount = false;

        /** It return the list of all the cases related to a particular Case's Contact*/
        returnCaseList({idCaseRecord: this.recordId, strCaseNumber : this.strCaseNumber, blnOpenCases : this.blnOnlyOpenCases})
        .then(result=>{
            if(result && result.blnIsSuccess) {
                //console.log('>>>>>'+JSON.stringify(result.map_ResponseData.list_CaseRecords));
                for (let i = 0; i < (result.map_ResponseData.list_CaseRecords.length); i++) {
                    //console.log('>>>>>'+JSON.stringify(result.map_ResponseData.list_CaseRecords[i].CaseNumber));
                    //console.log('>>>>>'+JSON.stringify(result.map_ResponseData.list_CaseRecords[i].Id));
                    //console.log('>>>>>'+JSON.stringify(result.map_ResponseData.list_CaseRecords[i].RecordTypeId));
                    //console.log('>>>>>'+JSON.stringify(result.map_ResponseData.list_CaseRecords[i].AccountId));
                    //console.log('>>>>>'+JSON.stringify(result.map_ResponseData.list_CaseRecords[i].Subject));
                    //console.log('>>>>>'+JSON.stringify(result.map_ResponseData.list_CaseRecords[i].OwnerId));
                    ////console.log('>>contact>>>'+JSON.stringify(result.map_ResponseData.list_CaseRecords[i].ContactId));

                    let boolIsParent = result.map_ResponseData.list_CaseRecords[i].Id === result.map_ResponseData.currentCase.ParentId ? true : false;

                    this.arrDataArray.push({CaseNumber : result.map_ResponseData.list_CaseRecords[i].CaseNumber,
                                    CaseUrl : '/' + result.map_ResponseData.list_CaseRecords[i].Id,
                                    Id : result.map_ResponseData.list_CaseRecords[i].Id, 
                                    RecordTypeName : result.map_ResponseData.list_CaseRecords[i].RecordTypeId !== undefined && result.map_ResponseData.list_CaseRecords[i].RecordTypeId ? result.map_ResponseData.list_CaseRecords[i].RecordType.Name: '',
                                    AccountName : result.map_ResponseData.list_CaseRecords[i].AccountId !== undefined && result.map_ResponseData.list_CaseRecords[i].AccountId !== null ? result.map_ResponseData.list_CaseRecords[i].Account.Name: '',
                                    ContactName : result.map_ResponseData.list_CaseRecords[i].ContactId !== undefined && result.map_ResponseData.list_CaseRecords[i].ContactId !== null ? result.map_ResponseData.list_CaseRecords[i].Contact.Name: '',
                                    Subject : result.map_ResponseData.list_CaseRecords[i].Subject,
                                    Status : result.map_ResponseData.list_CaseRecords[i].Status,
                                    OwnerName : result.map_ResponseData.list_CaseRecords[i].OwnerId !== undefined && result.map_ResponseData.list_CaseRecords[i].OwnerId ? result.map_ResponseData.list_CaseRecords[i].Owner.Name: '',
                                    IsParent : boolIsParent
                                });
                }
                this.arrData = this.arrDataArray;
                this.strCurrentCaseNumber = result.map_ResponseData.currentCase.CaseNumber;
                this.strMergeandCloseCaseLabel = 'Merge and Close Case : ' + this.strCurrentCaseNumber;
                this.objCurrentCase = result.map_ResponseData.currentCase;
                this.blnHasData = true; 
                this.blnIsLoading = false;
            } else if (result && !result.blnIsSuccess) {
                this.strMergeandCloseCaseLabel = 'Merge and Close Case : ' + this.strCurrentCaseNumber;
                this.strCurrentCaseNumber = result.map_ResponseData.currentCase.CaseNumber;
                this.objCurrentCase = result.map_ResponseData.currentCase;
                if(!result.map_ResponseData.currentCase.ContactId && this.strCaseNumber === '') {
                    this.showToast('Info ', 'No related case is found. Feel free to Search any case number.' ,'warning','dismissable');
                } else {
                    this.showToast('Info ',JSON.stringify(result.strMessage),'error','sticky');
                }
                this.blnHasData = false;
                this.blnIsLoading = false;
            } else {
                this.blnIsLoading = false;
                this.blnHasData = false;
            }
        }).catch(error=>{
            this.blnIsLoading = false;
            //console.log('error>>>'+ JSON.stringify(error));
            this.showToast('Error',JSON.stringify(error.body.message),'error','sticky');
        }); 
    }

    /** this Method is to perform logical operation on the selected cases */
    handleSelectedCases(event) {

        this.blnIsLoading = true;        
        this.strSelectedCaseNumbers = '';

        /** capturing the case number details that is selected from the UI */ 
        let strSelectedCaseNumber = event.currentTarget.dataset.casenumber;
        let idSelectedCase = event.target.value;
        let blnIsSelected = event.target.checked;
        this.strSelectedCaseRecordNumber = event.currentTarget.dataset.casenumber;
        
        try{
        /** preparing the arrayy of case ids and case numbers selected */
            if(blnIsSelected) {
                this.list_CaseIds.push(idSelectedCase);
                this.list_CaseNumbers.push(strSelectedCaseNumber);
            } else {
                const index = this.list_CaseIds.indexOf(idSelectedCase);
                if (index > -1) {
                    this.list_CaseIds.splice(index, 1);
                }
                const casenum = this.list_CaseNumbers.indexOf(strSelectedCaseNumber);
                if (casenum > -1) {
                    this.list_CaseNumbers.splice(casenum, 1);
                }
            }

            /** performing the disabe/ enable of buttons on the UI and casenumbers to be shown on the UI */
            if(this.list_CaseNumbers !== undefined && this.list_CaseNumbers.length > 0) {
                this.blnShowCaseNumberCount = true;     
                if(this.list_CaseNumbers.length > 1) {
                    this.blnDisableMergeAndCloseCurrentCaseButton = true;
                } else {
                    this.blnDisableMergeAndCloseCurrentCaseButton = false;
                }     
                if(this.list_CaseNumbers.length <= 3) {
                    this.strSelectedCaseNumbers = this.list_CaseNumbers.join(', ');
                    this.strSelectedCaseNumbersDummy = this.strSelectedCaseNumbers;
                    this.blnDisableMergeAndCloseSelectedCaseButton = false;
                } else {
                    this.strSelectedCaseNumbers = this.strSelectedCaseNumbersDummy;
                    this.blnDisableMergeAndCloseSelectedCaseButton = true;
                }
            } else {
                this.blnShowCaseNumberCount = false;
            }

            if(this.list_CaseNumbers.length > 3) {
                this.blnIsLoading = false;
                return;
            }
        } catch (error) {
            this.showToast('Error',JSON.stringify(error.body.message),'error','sticky');
            console.error('MergeCaseLwcCmp--handleSelectedCases-->>>'+ error);
            this.blnIsLoading = false;
        }
        this.blnIsLoading = false;
    }
    
    showToast(title,message,variantType,mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variantType,
            mode: mode,
        }); 
        this.dispatchEvent(event);
    }

    /** Tehis method is  called to perfom the merge operation on the selected case.
     * The selected case will be merged on the current case and 
     * all its chatter feed and chatter comments will also be merged on the current case record.
     * Maximum three cases be merged at a time.
     */
    handleMergeAndCloseSelectedCase(event) {   
        
        this.blnIsLoading = true; 
        try{
            if(this.list_CaseIds !== undefined) {
                if(this.list_CaseIds.length == 0) {
                    this.showToast('Warning','Please select a record','warning','dismissable');
                    this.blnIsLoading = false;
                } 
                else {
                    /** this method is called to merge the selected cases in the current case with all the relative information */
                    
                    mergeSeletedCase({list_CaseIds: this.list_CaseIds, caseToMerge: this.objCurrentCase, list_CaseNumbers: this.list_CaseNumbers})
                    .then(result=> {                    
                        if(result && result.blnIsSuccess === true){
                            this.strCaseNumber = '';
                            this.blnOnlyOpenCases = false;
                            this.closeMergePage();
                            this.refreshpage();
                            this.showToast('Success ',JSON.stringify(result.strMessage),'success','dismissable');
                            this.blnIsLoading = false; 
                        } else if (result && result.blnIsSuccess === false) {
                            this.showToast('Error 1',JSON.stringify(result.strMessage),'error','dismissable');
                            this.blnIsLoading = false;
                        }                   
                    }) 
                    .catch(error=>{
                        this.blnIsLoading = false;
                        console.error('MergeCaseLwcCmp--handleMergeAndCloseSelectedCase-->>>'+ JSON.stringify(error));
                        this.showToast('Error',JSON.stringify(error.body.message),'error','sticky');
                        this.blnIsLoading = false;
                    });
                }
            }
        } catch (error) {
            console.error('MergeCaseLwcCmp--handleMergeAndCloseSelectedCase-->>>'+ error);
            this.showToast('Error',JSON.stringify(error.body.message),'error','sticky');
            this.blnIsLoading = false;
        }
    }

    // /** close the current mergecase tab when the case is merged */
    // closeCurrentTab(currentCaseId) {
    //     if(currentCaseId) {
    //         this[NavigationMixin.GenerateUrl]({
    //             type: 'standard__recordPage',
    //             attributes: {
    //                 recordId: currentCaseId.Id,
    //                 actionName: 'view',
    //             },
    //         })
    //         const refreshEvent = new CustomEvent('casemergesuccesfull', {detail: {}});
    //         // Fire the custom event
    //         this.dispatchEvent(refreshEvent);
    //         this.showSpinner = false;
    //     }
    // }
    /** This method is called when 
     * the current case record is to be merged selected case record 
     * Only One record can be selected and merged in this operation*/
    handleMergeAndCloseCurrentCase(event) {
        this.blnIsLoading = true; 

        try{
            let arr_CurrentCaseIds = []; 
            this.list_CaseNumbers = [];

            this.arrData.find( r => {
                if(r.CaseNumber === this.strSelectedCaseRecordNumber) {
                    this.arrSelectedCaseRecord.push(r);
                }
            })
            
            arr_CurrentCaseIds.push(this.objCurrentCase.Id); 
            this.list_CaseNumbers.push(this.objCurrentCase.CaseNumber);
            
            if(this.list_CaseIds !== undefined) {
                if(this.list_CaseIds.length == 0) {
                    this.showToast('Warning','Please select a record','warning','dismissable');
                    this.blnIsLoading = false;
                } 
                else {
                    
                    console.log('this.strSelectedCaseRecordNumber>>>'+this.strSelectedCaseRecordNumber);
                    
                    getSelectedCaseRecord({strCaseNumber : this.strSelectedCaseRecordNumber})
                    .then(cRec=>{
                        if(cRec) {
                            console.log('this.arr_CurrentCaseIds>>>'+ arr_CurrentCaseIds);
                            console.log('this.cRec>>>'+cRec);
                            console.log('this.list_CaseNumbers>>>'+this.list_CaseNumbers);
                            return mergeSeletedCase({list_CaseIds: arr_CurrentCaseIds, caseToMerge: cRec, list_CaseNumbers: this.list_CaseNumbers});
                        } else {
                            this.showToast('Success ', 'Selected Case is not fit to be merged' ,'success','dismissable');
                            return;
                        }
                    })                
                    .then(result=> {                    
                        if(result && result.blnIsSuccess === true){
                            this.strCaseNumber = '';
                            this.blnOnlyOpenCases = false;
                            this.closeMergePage();
                            this.refreshpage();
                            this.blnIsLoading = false;
                            this.showToast('Success ',JSON.stringify(result.strMessage),'success','dismissable'); 
                        } else if (result && result.blnIsSuccess === false) {
                            this.showToast('Error 1',JSON.stringify(result.strMessage),'error','dismissable');
                            this.blnIsLoading = false;
                        }                   
                    }) 
                    .catch(error=>{
                        this.blnIsLoading = false;
                        this.showToast('Error',JSON.stringify(error.body.message),'error','sticky');
                        console.error('MergeCaseLwcCmp--handleMergeAndCloseCurrentCase-->>>>>>'+ JSON.stringify(error));
                        this.blnIsLoading = false;
                    });
                }
            }
        } catch (error) {
            console.error('MergeCaseLwcCmp--handleMergeAndCloseCurrentCase-->>>'+ error);
            this.showToast('Error',JSON.stringify(error.body.message),'error','sticky');
            this.blnIsLoading = false;
        }
    } 

    /** it is called when the case is merged to refresh the data of the page */
    refreshpage() {
        const recordNavigation = new CustomEvent('refpage',{});
        this.dispatchEvent(recordNavigation);
    }
    /** it is called when the case is merged and case merge functionality is to be closed */
    closeMergePage() {
        const recordNavigation = new CustomEvent('closeCurrentTab',{});
        this.dispatchEvent(recordNavigation);
    }

    /** this method is called when the case no is clicked to open the clicked case */
    handleUrlclick(event) {
        let strCaseNumber = event.target.dataset.casenumber;
        let idCase = event.target.dataset.id;
        
        if(idCase !== undefined) {
            const recordNavigation = new CustomEvent('ClickCaseNumber',{
                detail : {detailRecordId : idCase, newCaseNumber : strCaseNumber}
            });
            this.dispatchEvent(recordNavigation);
        } else {
            this.showToast('Error','Unable to access record','error','dismissable');
        }
    }
}