import { LightningElement, track, api, wire } from 'lwc';

import skipCase from '@salesforce/apex/CaseSkipController.skipCaseRecord';
import assignCases from '@salesforce/apex/PlayModeCaseListControllerLightning.handleNextButton';
import retrieveUserPreference from '@salesforce/apex/CaseSkipController.getUserPreference';
import { getRecord } from "lightning/uiRecordApi";
import CASE_RECORDTYPEID_FIELD from '@salesforce/schema/Case.RecordTypeId';

import { displayToast, sendAuraEvent } from 'c/utilityService';

/* Import Standard Events */
import { NavigationMixin } from 'lightning/navigation';
import takeIt from '@salesforce/apex/EngagementCaseViewExtension_LEX.acceptCase';

export default class CaseSkipCmp extends NavigationMixin(LightningElement) {


    /* All @api variables grouped together */
    @api idLoggedInUserId;
    @api recordId;

    /* All @track variables grouped together */
    /* Indicate if a case is assigned via play mode */
    @track blnIsPlayMode = false;
    /* Flag to indicate skip case modal is open */
    @track blnIsSkipCaseModalOpen = false;
    /* Skip comment user provides */
    @track strSkipComment = '';
    /* If it is skip case or skip and next */
    @track blnIsSkipCase;
    /* If the label is skip case or skip and next */
    @track strSkipLabel;

    /* If logged in user is different from case owner Id */
    @track blnIsTakeItButtonVisible = false;
     /* Flag to show spinner component - If set to true, will show spinner on the UI */
    @track blnIsLoading = false;
    /* To track record type name for Case */
    @track recordTypeId;
    @wire(getRecord, { recordId: '$recordId', fields: [CASE_RECORDTYPEID_FIELD] })
    getCase({ error, data }) {
        if (data) {
            var result = JSON.parse(JSON.stringify(data));
            this.recordTypeId = result.fields.RecordTypeId.value;
        } else if (error) {
            var result = JSON.parse(JSON.stringify(error));
        }
    };

    /* All non track, non api variables grouped together */
    strViewLabel = '';
    idNextCaseToServe;
    blnIsLastCase = false;
    
    connectedCallback() {
        /* Simple Query to Fetch User Preference Record */
        retrieveUserPreference({
            idCase: this.recordId
        }).then(result => {
            let list_userPreference = result.list_userPreference;
            let objCase = result.objCase;
                if(list_userPreference && list_userPreference.length == 1) {
                    list_userPreference[0].Case_Play_Selected_Cases__c = list_userPreference[0].Case_Play_Selected_Cases__c ? list_userPreference[0].Case_Play_Selected_Cases__c : '';
                    // Checks if case play selected cases from user preference contains record id from record page
                    this.blnIsPlayMode = list_userPreference[0].Case_Play_Selected_Cases__c.includes(this.recordId) ? true : false;
                    if(this.blnIsPlayMode) {
                        // Logic to show which case they are viewing
                        let intCounter = 1;
                        let list_caseSplit = list_userPreference[0].Case_Play_Selected_Cases__c.split(',');
                        list_caseSplit.forEach(objEachCase => {
                            if(objEachCase === this.recordId) {
                                this.blnIsLastCase = intCounter === list_caseSplit.length ? true : false;
                            // this.strViewLabel = `Viewing ${intCounter} of ${list_caseSplit.length} case(s) assigned via play mode.`
                                this.strViewLabel = `${intCounter} / ${list_caseSplit.length} cases`;
                                this.idNextCaseToServe = list_caseSplit[intCounter];
                            }
                            intCounter = intCounter + 1;
                        });
                    }
                }

                this.blnIsTakeItButtonVisible = this.idLoggedInUserId !== objCase.OwnerId ? true : false;
                console.log('case owner Id ', objCase.OwnerId);
                if(!this.blnIsPlayMode && !this.blnIsTakeItButtonVisible) {
                    sendAuraEvent(this, '', 'hidecomponent');
                } 
        }).catch(error => {
            console.error('Error in caseSkipCmp - connectedCallback ' , error);
        })
    }

    /* Open skip case modal - sets the label */
    openSkipCaseModal() {
        this.blnIsSkipCase = true;
        this.strSkipLabel = 'Skip Case';
        this.blnIsSkipCaseModalOpen = true;
    }

    /* Open skip and next case modal - sets the label */
    openSkipAndNextCaseModal() {
        this.blnIsSkipCase = false;
        this.strSkipLabel = 'Skip and Next Case';
        this.blnIsSkipCaseModalOpen = true;
    }

    /* Close skip case modal */
    closeSkipCaseModal() {
        this.blnIsSkipCaseModalOpen = false;
    }
    /* Updates skip comment */
    handleDataChange(event) {
        this.strSkipComment = event.detail.value;
    }

    /* handles when user clicks skip or skip and next. validates if user entered skip comment */
    handleSkipCaseClick() {
        const allValid = [...this.template.querySelectorAll('lightning-textarea')]
        .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
        }, true);
        if(allValid) {
            // If user presssed skip and next on the last case. assign more cases
            if(!this.blnIsSkipCase && this.blnIsLastCase) {
                this.blnIsSkipCaseModalOpen = false;
                this.blnIsLoading = true;
                assignCases().then(result => {
                    this.blnIsLoading = false;
                    if(result.blnIsSuccess) {
                        let intCounter = result.list_cases.length;
                        if(intCounter === 1) {
                            displayToast(this, result.list_cases[0].CaseNumber + ' assigned to you successfully', '', 'success', 'sticky');
                        } else if(intCounter > 1) {
                            displayToast(this, result.list_cases[0].CaseNumber + ' and ' + (intCounter - 1) + ' other cases assigned to you successfully', '', 'success', 'sticky');
                        }
                        this.idNextCaseToServe = result.list_cases[0].Id;
                    } else {
                        if(result.strMessage) {
                            if(result.strMessage.startsWith('No cases found')) {
                                result.strMessage = 'No more cases left in the queue. Please select a different queue from play mode';
                            }
                            displayToast(this, result.strMessage, '', 'warning', 'sticky');
                        }
                    }
                    this.fireCloseTabEvent();
                }).catch(error => {
                    this.blnIsLoading = false;
                });
            } else {
                this.fireCloseTabEvent();
            } 
        }
    }

    fireCloseTabEvent() {
        // Fire custom event to Aura. Mention which tab needs to be closed. Which tabs need to be opened.
        const closeTabEvent = new CustomEvent('closetab', {
            detail: {
                idNextCaseToServe: this.idNextCaseToServe,
                idTabToClose: this.recordId,
                strSkipComment: this.strSkipComment
            },
        });
        // Fire the custom event
        this.dispatchEvent(closeTabEvent);
    }

    handleTakeIt() {
        this.blnIsLoading = true;
        let objLocalCase = {Id: this.recordId, OwnerId: this.idLoggedInUserId, RecordTypeId: this.recordTypeId};
        takeIt({
            objCaseToUpdate: objLocalCase
        })
        .then(result => {
            if(result.blnIsSuccess) {
                displayToast(this, 'Case assigned successfully!', '', 'success', '');
                sendAuraEvent(this, '', 'refreshview');
                this.blnIsTakeItButtonVisible = false;
                if(!this.blnIsPlayMode && !this.blnIsTakeItButtonVisible) {
                    sendAuraEvent(this, '', 'hidecomponent');
                } 
            } else {
                displayToast(this, result.strMessage, '', 'error', '');
            }
            this.blnIsLoading = false;
        })
        .catch(error => {
            // If there is an Exception, Show Error Message on the UI
            this.error = error;
            this.blnIsLoading = false;
        });
    }


    /* Apex call to create Case Skip History Records */
    @api async handleSkip(recordId, strSkipComment) {
        skipCase({
            idCase: recordId,
            strSkipComment: strSkipComment
        }).then(result => {
            displayToast(this, 'Case skipped successfully!', '', 'success', '');
        }).catch(error => {
            console.error('Error in caseSkipCmp - handleSkip ', error);
        });
    }
}