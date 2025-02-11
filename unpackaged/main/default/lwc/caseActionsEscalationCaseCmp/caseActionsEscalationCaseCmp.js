import { LightningElement, api, track, wire } from 'lwc';

/* Import Apex Classes and Methods */
import updateCase from '@salesforce/apex/EngagementCaseViewExtension_LEX.saveCaseRecord';
import loadCaseInfo from '@salesforce/apex/EngagementCaseViewExtension_LEX.setCaseInfo';
import loadCurrentCaseInfo from '@salesforce/apex/EngagementCaseViewExtension_LEX.getCurrentCaseInfo';

import fetchSubCaseReasonList from '@salesforce/apex/EngagementCaseViewExtension_LEX.getConfirmSubCaseReason';
import fetchDynamicFieldList from '@salesforce/apex/EngagementCaseViewExtension_LEX.renderDynamicFields';
import assignCases from '@salesforce/apex/PlayModeCaseListControllerLightning.handleNextButton';

import { getRecord } from 'lightning/uiRecordApi';

/* Imported Methods from Utility Service */
import { displayToast, sendAuraEvent } from 'c/utilityService';

/* Import Standard Events */
import { NavigationMixin } from 'lightning/navigation';

export default class CaseActionsCmp extends NavigationMixin(LightningElement) {

    /* @api variables grouped together */
    @api recordId;

    /* @track variables grouped together */
    /* Indicates if component is loading (shows a spinner icon) */
    @track blnIsLoading;
    /* case object */
    @track objCase = {};
    
    /* List of Case Reasons to show for Auto Complete */
    @track list_caseReasons = [];
    /* Map of case Type and case reasons */
    @track map_caseReasonToGroupMap = [];
    /* Master Map of case Type and case reasons */
    @track map_totalCaseReasonToGroup = [];
    /* Decides whether to show auto complete options. else it shows that no case reasons are blnIsFound */
    @track blnIsCaseReasonFound = true;
    /* List of Case fields dynamically rendered based on case record type */
    @track list_dynamicFields = [];
    /* Boolean flag to show if dynamic fields need to be visible */
    @track blnIsDynamicFieldsAvailable = false;
    /* list of sub case reasons related to a particular confirm case reason */
    @track list_subCaseReasons = [];
    /* Decides whether solve button should be disabled. the button will be disabled if all required fields are not completed */
    @track blnIsSolveDisabled = true;
    /* Flag to indicate if component has completed rendering */
    @track blnIsRendered = false;
    /* Flag to check if the case is assigned via play mode */
    @track blnIsPlayMode = false;
    /* Flag to indicate if it is the last case on list cases assigned via play mode. if flag is true and users click Save and Next, more cases are served */
    @track blnIsLastCase = false;
    /* Id of the next case to be served */
    @track idNextCaseToServe;
    /* Id of the case that the user currently views */
    @track idCase;
    /* Flag to indicate if users selected "Other" as Confirm Case Reason */
    @track blnIsOtherCaseReasonAvailable = false;
     /* Flag to indicate if users selected "Other" is required. Confirm Case Reason = Other, Other Case Description is required. Sub Case Reason = Other, Other Case Description is not required */
    @track blnIsOtherCaseReasonRequired = false;
    /* Flag to indicate if sub case reason drop down value needs to be visible */
    @track blnIsSubCaseReasonVisible = false;
    /* Flag to indicate if chevron down button is clicked - this change is done to avoid lightning record view form refresh */
    @track blnIsChevronDownClicked = false;
    
    /* non-track variables grouped together */
    /* record type of the confirm case reason that user selects. It is used to re-render ui dynamic fields when record type changes */
    strCurrentRecordType;
    /* object that contains all the changes that user does from front end */
    objTrackedFieldChange = {};
    /* map of case reasons to record type map */
    map_caseReasonToRecordTypeMap = {};
    /* Decides whether to include slds-box wrapper surrounding the component */
    strBoxWrapperClass = '';
    /* Flag to check if case is read only - all fields are disabled for read only cases. all buttons are not visible */
    blnIsReadOnlyCase = false;

    /* wire methods grouped together */
    @wire(getRecord, { recordId: '$recordId', fields: ['Case.Status'] })
    getCaseRecord({ data, error }) {
        if (data) {
            this.objCase.Status = data.fields['Status'].value;
        }
    }

    

    connectedCallback() {
        this.objCase.Id = this.recordId;
        // Check if component is placed in LiveChatTranscript or Case Page
        if (window.location.href.includes('LiveChatTranscript')) {
            this.strBoxWrapperClass = 'slds-box slds-theme_default';
        } else {
            this.strBoxWrapperClass = 'slds-theme_default';
        }
        // Load Case Data
        this.loadCaseData();
    }

    // Load Case Info = get case reason classification, get sub case reasons, get case data etc
    loadCaseData() {
        // Show Spinner
        this.blnIsLoading = true;
        loadCaseInfo({
            idCase: this.recordId,
            blnIsCalledFromRoutingCmp: false
        })
            .then(result => {
                if (result) {
                    // Flag to check if the user has access to view all permission sets
                    let blnIsViewAllCaseReasonPermissionSetAccess = result.blnIsViewAllCaseReasonPermissionSetAccess;
                    this.objCase = result.objCase;
                    // Set current record type - Will be used when a confirm reason is selected
                    this.strCurrentRecordType = result.objCase.Record_Type_Name__c;
                    // If case record type ends with read only, set blnIsReadOnlyCase to True
                    if (this.strCurrentRecordType.endsWith('Read Only')) {
                        this.blnIsReadOnlyCase = true;
                    }
                    // Get Logged In User Profile
                    let strProfileName = result.strLoggedInUserProfile;
                    this.idCase = this.objCase.Id;
                    // Fetch case action config
                    if (result.list_caseActionField) {
                        // deserialize the list
                        let list_arrFields = JSON.parse(result.list_caseActionField.Configuration_Json__c);
                        // check if size is set, use override labels if required
                        list_arrFields.forEach(objEachField => {
                            objEachField.size = objEachField.size ? objEachField.size : '6';
                            objEachField.label = objEachField.overrideLabel ? objEachField.overrideLabel : objEachField.label;
                        });
                        // set to dynamic field list
                        this.list_dynamicFields = list_arrFields;
                        if (this.list_dynamicFields.length > 0) {
                            this.blnIsDynamicFieldsAvailable = true;
                        }
                    }
                    // Set list of sub reasons if available
                    if (result.list_subCaseReasons) {
                        let list_arrSubCaseReasons = [];
                        result.list_subCaseReasons.forEach(eachSubCaseReason => {
                            list_arrSubCaseReasons.push({
                                label: eachSubCaseReason,
                                value: eachSubCaseReason
                            })
                        });
                        this.list_subCaseReasons = list_arrSubCaseReasons;
                        // Conditionally decide to show sub case reasons
                        this.blnIsSubCaseReasonVisible = this.list_subCaseReasons.length > 0 ? true : false;
                    }
                    // Fetch total list of case reason classifications
                    console.log('--caseReasonslIst--' +result.list_caseReasons);
                    if (result.list_caseReasons) {
                        let resultCaseReasons = result.list_caseReasons;
                        let list_arrCaseReasons = [];
                        resultCaseReasons.forEach(objEachCaseReason => {
                            list_arrCaseReasons.push({
                                label: objEachCaseReason,
                                value: objEachCaseReason
                            });
                        });
                        console.log('-----arrcasereason--'+JSON.stringify(list_arrCaseReasons));
                        this.list_caseReasons = list_arrCaseReasons;
                    }
                    // Filtered list of case reason classification
                   // console.log('---debug--'+JSON.stringify(result.map_caseReasonToGroupMap))
                    if (result.map_caseReasonToGroupMap) {
                        let list_arrCaseReasons = [];
                        for (const strRecordType in result.map_caseReasonToGroupMap) {
                            // Load only record type specific cases if profile is not Zp Sys admin or Benefits Care
                            if (strProfileName === 'ZP System Administrator' || strProfileName === 'Benefits Care' || blnIsViewAllCaseReasonPermissionSetAccess) {
                                // Load only Benefits Care, Payroll Care and Modern Bank Record type Case Reason
                                if (strRecordType === 'Benefits Care' || strRecordType === 'Payroll Care' || strRecordType === 'Modern Bank') {
                                    let list_caseReasonClassifications =[];
                                    let objCaseReason = {};
                                    objCaseReason.group = strRecordType;
                                    for (let idCaseReason in result.map_caseReasonToGroupMap[strRecordType]) {
                                        list_caseReasonClassifications.push({
                                            label: result.map_caseReasonToGroupMap[strRecordType][idCaseReason],
                                            key: idCaseReason
                                        });
                                    }
        
                                    objCaseReason.value = list_caseReasonClassifications;

                                    list_arrCaseReasons.push(objCaseReason);
                                    if (objCaseReason.value) {
                                        objCaseReason.value.forEach(objValue => {
                                            this.map_caseReasonToRecordTypeMap[objValue] = strRecordType;
                                        });
                                    }
                                }
                            } else if (strProfileName === 'Payroll Care') {
                                // Load only Payroll Care and Modern Bank record type case reason classification
                                if (strRecordType === 'Payroll Care' || strRecordType === 'Modern Bank') {
                                    let list_caseReasonClassifications =[];
                                    let objCaseReason = {};
                                    objCaseReason.group = strRecordType;
                                    for (let idCaseReason in result.map_caseReasonToGroupMap[strRecordType]) {
                                        list_caseReasonClassifications.push({
                                            label: result.map_caseReasonToGroupMap[strRecordType][idCaseReason],
                                            key: idCaseReason
                                        });
                                    }
        
                                    objCaseReason.value = list_caseReasonClassifications;

                                    list_arrCaseReasons.push(objCaseReason);
                                    if (objCaseReason.value) {
                                        objCaseReason.value.forEach(objValue => {
                                            this.map_caseReasonToRecordTypeMap[objValue] = strRecordType;
                                        });
                                    }
                                }
                            }
                        }
                        
                        this.map_caseReasonToGroupMap = list_arrCaseReasons;
                        console.log('--map--'+JSON.stringify(this.map_caseReasonToGroupMap));
                        this.map_totalCaseReasonToGroup = list_arrCaseReasons;
                        if (list_arrCaseReasons.length === 0) {
                            this.blnIsCaseReasonFound = false;
                        }
                        // Conditionally decide to show if Other case reason needs to be displayed
                        this.blnIsOtherCaseReasonAvailable = this.objCase.Confirm_Case_Reason__c === 'Other' ? true : false;
                        if(this.blnIsOtherCaseReasonAvailable) {
                            this.blnIsOtherCaseReasonRequired = true;
                        }
                        // If Confirm Case Reason is not Other, Check if Sub Case Reason has Other
                        if(!this.blnIsOtherCaseReasonAvailable) {
                            let strSubCaseReason = this.objCase.Confirm_Sub_Case_Reason__c;
                            if(strSubCaseReason) {
                                this.blnIsOtherCaseReasonAvailable = strSubCaseReason.toLowerCase().includes('other') ? true : false;
                                if(this.blnIsOtherCaseReasonAvailable) {
                                    this.blnIsOtherCaseReasonRequired = false;
                                }
                            }
                        }
                    }

                    // Check user preference object and see if current record id matches user preference's case play selected cases field
                    if (result.objUserPreference) {
                        result.objUserPreference.Case_Play_Selected_Cases__c = result.objUserPreference.Case_Play_Selected_Cases__c ? result.objUserPreference.Case_Play_Selected_Cases__c : '';
                        this.blnIsPlayMode = result.objUserPreference.Case_Play_Selected_Cases__c.includes(this.recordId) ? true : false;
                        if (this.blnIsPlayMode) {
                            let intCounter = 1;
                            let list_casesSplit = result.objUserPreference.Case_Play_Selected_Cases__c.split(',');
                            list_casesSplit.forEach(objEachCase => {
                                if (objEachCase === this.recordId) {
                                    this.blnIsLastCase = intCounter === list_casesSplit.length ? true : false;
                                    this.idNextCaseToServe = list_casesSplit[intCounter];
                                }
                                intCounter = intCounter + 1;
                            });
                        }
                    }
                    // Check if all fields are valid
                    // this.checkValidity();
                }
                // End showing spinner
                this.blnIsLoading = false;
                console.log('wired no exception');
                this.blnIsRendered = false;
            })
            .catch(error => {
                // If there is an Exception, Show Error Message on the UI
                console.error('Error in caseActionsCmp - loadCaseData ', error);
                this.error = error;
                this.blnIsLoading = false;
                console.log('wired clone exception');
            });
    }
    
    // This method is responsible for showing filtered case reason for auto complete
    handleFilterCaseReason(event) {
        // Get input
        let strinput = event.detail;
        // Check if strinput has a value else set to blank
        strinput = strinput ? strinput : '';
        // If strinput is blank, solve button should be disabled
        if (strinput === '') {
            this.blnIsSolveDisabled = true;
        }
        let map_totalCaseReasons = this.map_totalCaseReasonToGroup;
        let list_arrCaseReasons = [];
        var t0 = performance.now();
        let intCounter = 0;
        map_totalCaseReasons.forEach(caseReason => {
            let objCaseReasonsToAdd = {};
            let list_sortedCaseReasons = [];
            let blnIsFound = false;
            objCaseReasonsToAdd.group = caseReason.group;
            caseReason.value.forEach(objEachValue => {
                if (objEachValue.label.toLowerCase().includes(strinput.toLowerCase())) {
                    if (intCounter < 30) {
                        list_sortedCaseReasons.push(objEachValue);
                        blnIsFound = true;
                    }
                    intCounter = intCounter + 1;
                }
            });
            if (blnIsFound) {
                objCaseReasonsToAdd.value = list_sortedCaseReasons.sort();
                list_arrCaseReasons.push(objCaseReasonsToAdd);
            }
        })
        this.map_caseReasonToGroupMap = list_arrCaseReasons;
        if (list_arrCaseReasons.length === 0) {
            this.blnIsCaseReasonFound = false;
        } else {
            this.blnIsCaseReasonFound = true;
        }
        var t1 = performance.now();
        console.log("time taken to filter " + (t1 - t0) + " milliseconds.")
    }
    
    // When a case reason is selected from auto complete
    handleCaseReasonSelected(event) {
        this.objCase.Confirm_Case_Reason__c = event.detail.reason;
     
        this.dispatchEvent(new CustomEvent('selectcasereason', {
            detail: { reason: event.detail.reason }
          }));
        // Check if all required fields are filled out
        //this.checkValidity();
        this.blnIsLoading = true;
        fetchSubCaseReasonList({
            strConfirmCaseReason: this.objCase.Confirm_Case_Reason__c,
            strRecordType: event.detail.type
        }).then(result => {
            let list_arrSubCaseReasons = [];
            result.forEach(objEachSubCaseReason => {
                list_arrSubCaseReasons.push({
                    label: objEachSubCaseReason,
                    value: objEachSubCaseReason
                })
            });
            this.list_subCaseReasons = list_arrSubCaseReasons;
            this.blnIsSubCaseReasonVisible = this.list_subCaseReasons.length > 0 ? true : false;
            this.blnIsOtherCaseReasonAvailable = this.objCase.Confirm_Case_Reason__c === 'Other' ? true : false;
            if(this.blnIsOtherCaseReasonAvailable) {
                this.blnIsOtherCaseReasonRequired = true;
            }

            // Check if Confirm Sub Case Reason is Other
            if(!this.blnIsOtherCaseReasonAvailable) {
                let strSubCaseReason = this.objCase.Confirm_Sub_Case_Reason__c;
                if(strSubCaseReason) {
                    this.blnIsOtherCaseReasonAvailable = strSubCaseReason.toLowerCase().includes('other') ? true : false;
                    if(this.blnIsOtherCaseReasonAvailable) {
                        this.blnIsOtherCaseReasonRequired = false;
                    }
                }
            }

           // this.checkValidity();
            this.blnIsLoading = false;
            this.blnIsRendered = false;
            let strRecordTypeToChange = event.detail.type;
            // If record type changes = re-render dynamic fields
            if (strRecordTypeToChange) {
                if (this.strCurrentRecordType !== strRecordTypeToChange) {
                    this.reRenderDynamicFields(strRecordTypeToChange);
                }
            }
        }).catch(error => {
            console.error('Error in CaseActionsCmp - handleCaseReasonSelected ', error);
            this.blnIsLoading = false;
        })

    }
    




    
}