import { LightningElement, track, api, wire } from 'lwc';


/* Imported Methods from Utility Service */
import { displayToast } from 'c/utilityService';
import { getRecord } from 'lightning/uiRecordApi';
import ROUTING_CASE_REASON_CLASSIFICATION from '@salesforce/schema/Case.Routing_Case_Reason_Classification__c';
import loadCaseInfo from '@salesforce/apex/EngagementCaseViewExtension_LEX.setCaseInfo';



import fetchCaseReasonClassification from '@salesforce/apex/CaseHighlightsPanelController.returnCaseReasonClassification';
import fetchCaseReasonClassificationFromLabel from '@salesforce/apex/CaseHighlightsPanelController.returnCaseReasonClassificationFromLabel';
import updateCase from '@salesforce/apex/CaseHighlightsPanelController.updateCaseRoutingClassification';

const fields = [ROUTING_CASE_REASON_CLASSIFICATION];

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';


export default class CaseRoutingCmp extends NavigationMixin(LightningElement) {

    /* Record Id fetched from Page */
    @api recordId;
    @api recordid;
    @api strCaseReasonsToSkip;


    /* Flag to indicate if the buttons are disabled */
    @track blnIsRouteToDisabled = true;
    /* Auto populates case reason class based on case reason selected */
    @track strCaseReasonClass;
    /* Auto populates case reason type based on case reason selected */
    @track strCaseReasonType;
    /* Flag to show spinner component - If set to true, will show spinner on the UI */
    @track blnIsLoading = false;
    /* Flag to indicate if error messages need to be visible */
    @track blnIsMessageVisible;
    /* Base Class String variable - error, warning and success classes will be appended to the end */
    @track strMessageClassBase = 'slds-notify_alert slds-theme_alert-texture ';
    /* Indicates whether type of message is warning, error or success */
    @track strMessageClass;
    /* Message displayed to the User */
    @track strMessage;

    @wire(getRecord, { recordId: '$recordId', fields })
    objCase;

    /* list of case reasons available for auto complete */
    @track list_caseReasons = [];
    /* map of case reason to group */
    @track map_caseReasonToGroupMap = [];
    /* master list of case reason to group */
    @track map_totalCaseReasonToGroup = [];
    /* indicates if auto complete options can be shown */
    @track blnIsCaseReasonFound = true;
    /* routing case reason classification string */
    @track strRoutingReasonClassification;
    /* id of routing case reason classification */
    @track idRoutingCaseReasonClassification;

    @track objCaseRecord;

    // Loads case auto complete information
    connectedCallback() {
        let idRecord = this.recordId ? this.recordId : this.recordid;
        // Load Case Info
        this.blnIsLoading = true;
        loadCaseInfo({
            idCase: idRecord,
            blnIsCalledFromRoutingCmp: true
        })
            .then(result => {
                if (result) {
                    this.objCaseRecord = result.objCase;
                    // get case info
                    let objCase = result.objCase;
                    let strCaseRecordTypeName = objCase.Record_Type_Name__c;
                    
                    // if case has routing case reason classification, auto populate them on text box
                    if(objCase.Routing_Case_Reason_Classification__c) {
                        this.strRoutingReasonClassification = objCase.Routing_Case_Reason_Classification__r.Name;
                    }
                    if (result.map_caseReasonToGroupMap) {
                        let list_arrCaseReasons = [];
                        let list_CaseReasonsToSkip = [];

                        if (this.strCaseReasonsToSkip) {
                            let map_CaseReasonsByRecordType = JSON.parse(this.strCaseReasonsToSkip);
                            let list_CaseRecordTypes = Object.keys(map_CaseReasonsByRecordType);

                            if (list_CaseRecordTypes.includes(strCaseRecordTypeName)) {
                                list_CaseReasonsToSkip = (map_CaseReasonsByRecordType[strCaseRecordTypeName]).split(",");
                            }
                        }

                        // Map of Record Type and List of Case Reason Classification
                        for (let strRecordType in result.map_caseReasonToGroupMap) {
                            let list_caseReasonClassifications =[];
                            let objCaseReason = {};
                            objCaseReason.group = strRecordType;

                            for (let idCaseReason in result.map_caseReasonToGroupMap[strRecordType]) {
                                let strCaseReasonLabel = result.map_caseReasonToGroupMap[strRecordType][idCaseReason];
                                if (list_CaseReasonsToSkip.includes(strCaseReasonLabel)) {
                                    break;
                                }

                                list_caseReasonClassifications.push({
                                    label: strCaseReasonLabel,
                                    key: idCaseReason
                                });
                            }
                            objCaseReason.value = list_caseReasonClassifications;
                            list_arrCaseReasons.push(objCaseReason);
                        }
                        this.map_caseReasonToGroupMap = list_arrCaseReasons;
                        this.map_totalCaseReasonToGroup = list_arrCaseReasons;
                        if (list_arrCaseReasons.length === 0) {
                            this.blnIsCaseReasonFound = false;
                        }
                    }
                }
                this.blnIsLoading = false;
            })
            .catch(error => {
                // If there is an Exception, Show Error Message on the UI
                console.error('Error in caseRoutingCmp - Connected Call back ', error);
                this.error = error;
                this.blnIsLoading = false;
            });
    }

    // This method is fired when user types case reason classification
    handleDataChange(event) {
        // Check if event has value
        if (event.detail.value) {
            // set is loading to true
            this.blnIsLoading = true;
            let strParam = event.detail.value.toString();
            fetchCaseReasonClassification({
                idCaseReason: strParam
            })
                .then(result => {
                    if (result) {
                        this.blnIsRouteToDisabled = false;
                        this.strCaseReasonClass = result.Class__c;
                        this.strCaseReasonType = result.Type__c;
                    } else {
                        this.blnIsRouteToDisabled = true;
                        this.strCaseReasonClass = this.strCaseReasonType = '';
                    }
                    this.blnIsLoading = false;
                })
                .catch(error => {
                    // If there is an Exception, Show Error Message on the UI
                    console.error('Error in caseRoutingCmp - handleDataChange ', error);
                    this.error = error;
                    this.blnIsLoading = false;
                    this.showMessage('There was an issue in retrieving case reason classification. Please try again later', 'slds-theme_error');
                });
        } else {
            this.blnIsRouteToDisabled = true;
            this.strCaseReasonClass = this.strCaseReasonType = '';
        }
    }

    // This method is triggered when users select a case reason and click Route button
    handleRouteCase() {
        let idRecord = this.recordId ? this.recordId : this.recordid;
        let objCase = this.objCaseRecord;
        objCase.Re_Route_Count__c = objCase.Re_Route_Count__c ? objCase.Re_Route_Count__c + 1 : 1;
        this.blnIsLoading = true;

        console.log('this.strRoutingReasonClassification ' + this.strRoutingReasonClassification);
        updateCase({
            objCase: objCase,
            strTypeName: this.strCaseReasonType,
            idRoutingCaseReasonClassification: this.idRoutingCaseReasonClassification,
            strClassName: this.strCaseReasonClass,
            strRoutingReasonClassification: this.strRoutingReasonClassification
        })
            .then(result => {
                if (result.blnIsSuccess) {
                    let objCase = result.objCase;
                    this[NavigationMixin.GenerateUrl]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: objCase.Id,
                            actionName: 'view',
                        },
                    }).then(url => {
                        const event = new ShowToastEvent({
                            "title": "Routing Successful!",
                            "mode": "dismissable",
                            "variant": "success",
                            "message": "Case {1} routed to " + objCase.Owner.Name + "!",
                            "messageData": [
                                'Case',
                                {
                                    url,
                                    label: objCase.CaseNumber
                                }
                            ]
                        });
                        this.dispatchEvent(event);
                    });
                    // Once routing is successful, close focus tab
                    const evtCloseFocusTab = new CustomEvent('closefocustab', {
                        detail: {},
                    });
                    // Fire the custom event
                    this.dispatchEvent(evtCloseFocusTab);

                } else {
                    displayToast(this, 'Error: ' + result.strErrorMessage, '', 'error', '');
                }
                this.blnIsLoading = false;
            })
            .catch(error => {
                // If there is an Exception, Show Error Message on the UI
                this.error = error;
                this.blnIsLoading = false;
                this.showMessage('There was an issue loading Case Highlights Panel. Please try again later', 'slds-theme_error');
            });
    }


    /* Shows Success, Error and Warning Messages
     * Gets Class Variables that differentiates
     * the type of messages showed on the UI
    */
    showMessage(message, className) {
        // Set Message to be Visible
        this.blnIsMessageVisible = true;
        // Appends Success, Error or Warning Class to the End
        this.strMessageClass = this.strMessageClassBase + className;
        // Sets the Message Value
        this.strMessage = message;
    }

    // When case reason is selected from auto complete options
    handleCaseReasonSelected(event) {

        let strSelectedValue = event.detail.reason;
        let idCaseReasonClassification = event.detail.id;
        let strRecordType = '';
        if(event.detail.type) {
            strRecordType = event.detail.type;
        }
        this.strRoutingReasonClassification = strSelectedValue;
        this.blnIsLoading = true;
        fetchCaseReasonClassification({
            idCaseReason: idCaseReasonClassification
        })
            .then(result => {
                if (result) {
                    this.blnIsRouteToDisabled = false;
                    this.strCaseReasonClass = result.Class__c;
                    this.strCaseReasonType = result.Type__c;
                    this.idRoutingCaseReasonClassification = result.Id;
                } else {
                    this.blnIsRouteToDisabled = true;
                    this.strCaseReasonClass = this.strCaseReasonType = '';
                }
                this.blnIsLoading = false;
                let list_buttonIcon = [...this.template.querySelectorAll('lightning-button-icon')];
                if(list_buttonIcon) {
                    list_buttonIcon[0].focus();
                    console.log('button focussed ');
                }
            })
            .catch(error => {
                // If there is an Exception, Show Error Message on the UI
                console.error('Error in caseRoutingCmp handleCaseReasonSelected ' , error);
                this.error = error;
                this.blnIsLoading = false;
                this.showMessage('There was an issue loading Case Routing Component. Please try again later', 'slds-theme_error');
            });
    }


    handleFilterCaseReason(event) {

        let strInput = event.detail;
        strInput = strInput ? strInput : '';
        let totalCaseReasonMap = this.map_totalCaseReasonToGroup;
        let list_arrCaseReasons = [];
        var t0 = performance.now();
        let counter = 0;
        totalCaseReasonMap.forEach(objCaseReason => {
            let objCaseReasonToAdd = {};
            let list_sortedCaseReasonValues = [];
            let blnIsFound = false;
            objCaseReasonToAdd.group = objCaseReason.group;
            objCaseReason.value.forEach(strEachValue => {
                if(strEachValue.label.toLowerCase().includes(strInput.toLowerCase())) {
                    if(counter < 30) {
                        list_sortedCaseReasonValues.push(strEachValue);
                        blnIsFound = true;
                    }
                    counter = counter + 1;  
                }
            });
            if(blnIsFound) {
                objCaseReasonToAdd.value = list_sortedCaseReasonValues.sort();
                list_arrCaseReasons.push(objCaseReasonToAdd);
            }
        })

        this.map_caseReasonToGroupMap = list_arrCaseReasons;
        if(list_arrCaseReasons.length === 0) {
            this.blnIsCaseReasonFound = false;
        } else {
            this.blnIsCaseReasonFound = true;
        }
        var t1 = performance.now();
        console.log("time taken to filter " + (t1 - t0) + " milliseconds.")

    }
}