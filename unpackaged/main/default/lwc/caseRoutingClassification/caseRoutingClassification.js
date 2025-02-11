import { LightningElement, track, api, wire } from 'lwc';


/* Imported Methods from Utility Service */
import { displayToast } from 'c/utilityService';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ROUTING_CASE_REASON_CLASSIFICATION from '@salesforce/schema/Case.Routing_Case_Reason_Classification__c';
import loadCaseInfo from '@salesforce/apex/EngagementCaseViewExtension_LEX.setCaseInfo';


import fetchCaseReasonClassification from '@salesforce/apex/CaseHighlightsPanelController.returnCaseReasonClassification';
import fetchCaseReasonClassificationFromLabel from '@salesforce/apex/CaseHighlightsPanelController.returnCaseReasonClassificationFromLabel';
import updateCase from '@salesforce/apex/CaseHighlightsPanelController.updateCaseRoutingClassification';

const fields = [ROUTING_CASE_REASON_CLASSIFICATION];

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
export default class CaseRoutingClassification extends LightningElement {

    /* Record Id fetched from Page */
    @api recordId;
    @api recordid;
    @api strCaseReasonsToSkip;

    @track isRouteToDisabled = true;
    @track routeToLabel = 'Route To';
    @track caseReasonClass;
    @track caseReasonType;
    @track caseReasonDoNotAutoSolve;
    @track caseReasonSurveyEligible;
    @track caseRoutingReason;
    @track caseReasonPriority;
    @track caseReasonTaskUs;

    /* Flag to show spinner component - If set to true, will show spinner on the UI */
    @track isLoading = false;
    /* Flag to indicate if error messages need to be visible */
    @track isMessageVisible;


    /* Base Class String variable - error, warning and success classes will be appended to the end */
    @track messageClassBase = 'slds-notify_alert slds-theme_alert-texture ';
    /* Indicates whether type of message is warning, error or success */
    @track messageClass;
    /* Message displayed to the User */
    @track message;

    @wire(getRecord, { recordId: '$recordId', fields })
    objCase;



    @track map_caseReasonToGroupMap = [];
    @track map_totalCaseReasonToGroup = [];
    @track isCaseReasonFound = true;
    @track routingReasonClassification;

    @track routingCaseReasonClassificationId;

    connectedCallback() {
        let recordid = this.recordId ? this.recordId : this.recordid;
        this.isLoading = true;
        loadCaseInfo({
            idCase: recordid,
            blnIsCalledFromRoutingCmp: true
        })
            .then(result => {
                if (result) {
                    let objCase = result.objCase;
                    let strCaseRecordTypeName = objCase.Record_Type_Name__c;

                    if (objCase.Routing_Case_Reason_Classification__c) {
                        //this.routingReasonClassification = objCase.Routing_Case_Reason_Classification__r.Name;
                        this.routingReasonClassification = '';
                    }
                    if (result.map_caseReasonToGroupMap) {
                        let arrCaseReasons = [];
                        let list_CaseReasonsToSkip = [];

                        if (this.strCaseReasonsToSkip) {
                            let map_CaseReasonsByRecordType = JSON.parse(this.strCaseReasonsToSkip);
                            let list_CaseRecordTypes = Object.keys(map_CaseReasonsByRecordType);

                            if (list_CaseRecordTypes.includes(strCaseRecordTypeName)) {
                                list_CaseReasonsToSkip = (map_CaseReasonsByRecordType[strCaseRecordTypeName]).split(",");
                            }
                        }

                        for (const strRecordType in result.map_caseReasonToGroupMap) {
                            let list_caseReasonClassifications = [];
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

                            arrCaseReasons.push(objCaseReason);
                        }
                        this.map_caseReasonToGroupMap = arrCaseReasons;
                        this.map_totalCaseReasonToGroup = arrCaseReasons;

                        if (arrCaseReasons.length === 0) {
                            this.isCaseReasonFound = false;
                        }
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

    handleDataChange(event) {
        if (event.detail.value) {
            this.isLoading = true;
            let param = event.detail.value.toString();
            fetchCaseReasonClassification({
                idCaseReason: param
            })
                .then(result => {
                    if (result) {
                        this.isRouteToDisabled = false;
                        this.caseReasonClass = result.Class__c;
                        this.caseReasonType = result.Type__c;
                        this.routeToLabel = 'Route to ' + this.caseReasonType;
                    } else {
                        this.isRouteToDisabled = true;
                        this.caseReasonClass = this.caseReasonType = '';
                        this.routeToLabel = 'Route to ';
                    }
                    this.isLoading = false;
                })
                .catch(error => {
                    // If there is an Exception, Show Error Message on the UI
                    this.error = error;
                    this.isLoading = false;
                    this.showMessage('There was an issue loading Case Highlights Panel. Please try again later', 'slds-theme_error');
                });
        } else {
            this.isRouteToDisabled = true;
            this.caseReasonClass = this.caseReasonType = '';
            this.routeToLabel = 'Route to ';
        }
    }

    get routingreason() {
        return getFieldValue(this.objCase.data, ROUTING_CASE_REASON_CLASSIFICATION);
    }


    handleRouteCase() {
        let recordid = this.recordId ? this.recordId : this.recordid;
        this.isLoading = true;
        let objCase = {
            Id: recordid
        };

        updateCase({
            objCase: objCase,
            strTypeName: this.caseReasonType,
            idRoutingCaseReasonClassification: this.routingCaseReasonClassificationId,
            strClassName: this.caseReasonClass,
            strRoutingReasonClassification: this.routingReasonClassification
        })
            .then(result => {
                if (result) {
                    displayToast(this, 'Case routed to ' + this.caseReasonType + ' successfully!', '', 'success', '');
                    this[NavigationMixin.GenerateUrl]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: result.Id,
                            actionName: 'view',
                        },
                    }).then(url => {
                        const event = new ShowToastEvent({
                            "title": "Routing Successful!",
                            "mode": "sticky",
                            "variant": "success",
                            "message": "Case {1} routed to " + result.Owner.Name + "!",
                            "messageData": [
                                'Case',
                                {
                                    url,
                                    label: result.CaseNumber
                                }
                            ]
                        });
                        this.dispatchEvent(event);
                    });
                    const refreshEvent = new CustomEvent('refreshview', {
                        detail: {},
                    });
                    // Fire the custom event
                    this.dispatchEvent(refreshEvent);
                } else {
                    displayToast(this, 'There was an issue in routing case. Please try again later', '', 'error', '');
                }
                this.isLoading = false;
            })
            .catch(error => {
                // If there is an Exception, Show Error Message on the UI
                this.error = error;
                this.isLoading = false;
                this.showMessage('There was an issue loading Case Highlights Panel. Please try again later', 'slds-theme_error');
            });
    }

    handleClose(event) {
        console.log('entered in routing');
        this.dispatchEvent(new CustomEvent('closed'));
    }


    /* Shows Success, Error and Warning Messages
     * Gets Class Variables that differentiates
     * the type of messages showed on the UI
    */
    showMessage(message, className) {
        // Set Message to be Visible
        this.isMessageVisible = true;
        // Appends Success, Error or Warning Class to the End
        this.messageClass = this.messageClassBase + className;
        // Sets the Message Value
        this.message = message;
    }

    handleCaseReasonSelected(event) {

        let value = event.detail.reason;
        this.routingReasonClassification = value;
        this.isLoading = true;
        let strRecordType = '';
        if (event.detail.type) {
            strRecordType = event.detail.type;
        }
        fetchCaseReasonClassification({
            idCaseReason: event.detail.id
        })
            .then(result => {
                try {
                    if (result) {
                        this.isRouteToDisabled = false;
                        this.caseReasonClass = result.Class__c;
                        this.caseReasonType = result.Type__c;
                        this.routeToLabel = 'Route to ' + this.caseReasonType;
                        this.caseRoutingReason = value;
                        this.routingCaseReasonClassificationId = result.Id;
                        this.caseReasonTaskUs = result.Task_Us__c;
                        this.caseReasonSurveyEligible = result.Survey_Eligible__c;
                        this.caseReasonPriority = result.Priority__c;
                        this.caseReasonDoNotAutoSolve = result.Do_not_Auto_Solve__c;
                    } else {
                        this.isRouteToDisabled = true;
                        this.caseReasonClass = this.caseReasonType = '';
                        this.routeToLabel = 'Route to ';
                    }
                    const casereasonselected = new CustomEvent('casereasonselected', {
                        detail: {
                            caseReasonClass: this.caseReasonClass, caseReasonType: this.caseReasonType, caseReasonTaskUs: this.caseReasonTaskUs,
                            caseReasonPriority: this.caseReasonPriority, caseReasonSurveyEligible: this.caseReasonSurveyEligible,
                            caseReasonDoNotAutoSolve: this.caseReasonDoNotAutoSolve, routingCaseReasonClassificationId: this.routingCaseReasonClassificationId,
                            caseRoutingReason: this.caseRoutingReason
                        }
                    });
                    this.dispatchEvent(casereasonselected);
                    this.isLoading = false;

                }
                catch (error) {
                    console.log('---error--' + error);
                }
            })
            .catch(error => {
                // If there is an Exception, Show Error Message on the UI
                this.error = error;
                this.isLoading = false;
                this.showMessage('There was an issue loading Case Highlights Panel. Please try again later', 'slds-theme_error');
            });
    }


    handleFilterCaseReason(event) {

        let input = event.detail;
        input = input ? input : '';
        let totalCaseReasonMap = this.map_totalCaseReasonToGroup;
        let arrCaseReasons = [];

        var t0 = performance.now();
        let counter = 0;

        totalCaseReasonMap.forEach(caseReason => {
            let caseReasonToAdd = {};
            let caseReasonValues = [];
            let found = false;
            caseReasonToAdd.group = caseReason.group;
            caseReason.value.forEach(eachValue => {
                if (eachValue.label.toLowerCase().includes(input.toLowerCase())) {
                    if (counter < 30) {
                        caseReasonValues.push(eachValue);
                        found = true;
                    }
                    counter = counter + 1;
                }
            });
            if (found) {
                caseReasonToAdd.value = caseReasonValues.sort();;
                arrCaseReasons.push(caseReasonToAdd);
            }
        })

        this.map_caseReasonToGroupMap = arrCaseReasons;
        if (arrCaseReasons.length === 0) {
            this.isCaseReasonFound = false;
        } else {
            this.isCaseReasonFound = true;
        }

        var t1 = performance.now();
        console.log("time taken to filter " + (t1 - t0) + " milliseconds.")
    }
}