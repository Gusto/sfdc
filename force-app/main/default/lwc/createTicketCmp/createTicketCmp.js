import { LightningElement, track, api, wire } from 'lwc';

import loadCreateTicketInfo from '@salesforce/apex/CreateTicketController.loadCreateTicketData';
import fetchTicketConfigInfo from '@salesforce/apex/TicketConfigController.getTicketConfigInfo';
import fetchTicketReasonInfo from '@salesforce/apex/TicketConfigController.getTicketReasonInfo';
import saveTicket from '@salesforce/apex/CreateTicketController.updateTicket';

import { displayToast, navigateToSObject, getQueryParameters } from 'c/utilityService';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from "lightning/uiRecordApi";
import {CloseActionScreenEvent} from 'lightning/actions';

export default class CreateTicketCmp extends NavigationMixin(LightningElement) {

    @api caseid;
    @api recordId;

    @track blnIsLoading = false;
    @track objNewTicket = {};
    @track objCase = {};
    @track list_Teams;
    @track list_TicketReasons;
    @track list_TicketReasonsMaster;

    @track strSelectedTeam;
    @track strSelectedTicketReason;
    @track strSelectedTicketSubReason;

    @track list_TicketReasons = [];
    @track list_TicketSubReasons = [];

    @track blnIsConfigFound = false;
    @track strShowWarningMessage = false;
    @track objTicketConfig = {};

    @track list_DynamicFields = [];
    @track blnIsDynamicFieldsAvailable = false;

    @track blnIsTicketReasonDisabled = true;
    @track blnIsticketSubReasonDisabled = true;
    @track idCase;

    @track list_BenefitOrders = [];
    @track list_Opportunities = [];
    @track list_RelatedCases = [];

    @track blnIsBenefitOrderMessageVisible = false;
    @track blnIsOpportunityMessageVisible = false;
    @track blnIsCaseMessageVisible = false;

    @track idAccount;
    @track idContact;
    @track idParentCase;
    list_TeamsMaster;

    @wire(getRecord, { recordId: "$recordId", fields: ["Case.Id", "Case.AccountId", "Case.ContactId"] })
    wiredRecord({ error, data }) {
        if (data) {
            this.objCase = data;
            this.idCase = this.objCase.fields.Id.value;
            this.idParentCase = this.objCase.fields.Id.value;
            this.idAccount = this.objCase.fields.AccountId.value;
            this.idContact = this.objCase.fields.ContactId.value;
        }
    }

    connectedCallback() {
        this.blnIsLoading = true;
        loadCreateTicketInfo().then(result => {
            this.blnIsLoading = false;
            this.list_Teams = result.list_Teams;
            this.list_TeamsMaster = result.list_Teams;
            let params = getQueryParameters();
            if (Object.keys(params).length !== 0 && params['c__caseId']) {
                this.idCase = params['c__caseId'];
                this.idParentCase = params['c__caseId'];
                this.idAccount = params['c__accountId'];
                this.idContact = params['c__contactId'];
            } else if (this.objCase) {
                this.idCase = this.objCase.fields.Id.value;
                this.idParentCase = this.objCase.fields.Id.value;
                this.idAccount = this.objCase.fields.AccountId.value;
                this.idContact = this.objCase.fields.ContactId.value;
            }
        }).catch(error => {
            this.blnIsLoading = false;
        });
    }

    handleTicketSubReasonSelected(event) {
        this.blnIsLoading = true;
        this.strSelectedTicketSubReason = event.detail.value;
        this.getTicketConfigData(false);
    }

    // Get related ticket reasons from active ticket config records based on the selected team
    getTicketReasonData() {
        fetchTicketReasonInfo({
            strTeam: this.strSelectedTeam,
        }).then(result => {
            if (result) {
                this.list_TicketReasons = result;
                this.list_TicketReasonsMaster = result;
            }
            this.blnIsLoading = false;
        }).catch(error => {
            displayToast(this, error, '', 'error', 'sticky');
        });
    }

    getTicketConfigData(blnIsHandleSubReason) {
        this.objNewTicket = {};
        fetchTicketConfigInfo({
            strTeam: this.strSelectedTeam,
            strTicketReason: this.strSelectedTicketReason,
            strTicketSubReason: this.strSelectedTicketSubReason,
            idCase: this.idCase
        }).then(result => {
            if (result.objTicketConfig) {
                let objTicketConfig = result.objTicketConfig;
                this.list_BenefitOrders = result.list_BenefitOrders;
                this.list_Opportunities = result.list_Opportunities;
                this.list_RelatedCases = result.list_RelatedCases;

                this.blnIsBenefitOrderMessageVisible = result.list_BenefitOrders.length > 0 ? false : true;
                this.blnIsOpportunityMessageVisible = result.list_Opportunities.length > 0 ? false : true;
                this.blnIsCaseMessageVisible = result.list_RelatedCases.length > 0 ? false : true;
                this.blnIsConfigFound = true;
                this.strShowWarningMessage = false;
                this.objTicketConfig = objTicketConfig;
                if (objTicketConfig.Configuration_Json__c) {
                    let list_Fields = JSON.parse(objTicketConfig.Configuration_Json__c);
                    list_Fields.forEach(objEachField => {
                        objEachField.size = objEachField.size ?? '6';
                        objEachField.label =  objEachField.overrideLabel ? objEachField.overrideLabel : objEachField.label;
                    });
                    this.list_DynamicFields = list_Fields;
                    this.blnIsDynamicFieldsAvailable = true;
                } else {
                    this.list_DynamicFields = [];
                    this.blnIsDynamicFieldsAvailable = false;
                }

                if (blnIsHandleSubReason) {
                    if (objTicketConfig.Ticket_Sub_Reason_List__c) {
                        let list_SubReasons = objTicketConfig.Ticket_Sub_Reason_List__c.split(',');
                        if (list_SubReasons?.length > 0) {
                            this.blnIsticketSubReasonDisabled = false;
                            let objSubReasonsArray = [];
                            list_SubReasons.forEach(eachSubReason => {
                                objSubReasonsArray.push({
                                    label: eachSubReason,
                                    value: eachSubReason
                                });
                            });
                            this.list_TicketSubReasons = objSubReasonsArray;
                        } else {
                            this.blnIsticketSubReasonDisabled = true;
                            this.list_TicketSubReasons = [];
                        }
                    } else {
                        this.list_TicketSubReasons = [];
                        this.blnIsticketSubReasonDisabled = true;
                        this.strSelectedTicketSubReason = '';
                    }
                }
            } else {
                this.blnIsConfigFound = false;
                this.strShowWarningMessage = true;
                this.objTicketConfig = {};
                if (blnIsHandleSubReason) {
                    this.blnIsticketSubReasonDisabled = true;
                    this.list_TicketSubReasons = [];
                    this.strSelectedTicketSubReason = '';
                }
            }
            this.blnIsLoading = false;
        }).catch(error => {
            console.error('Error in getting Ticket Config ', error);
        });
    }

    // Methods related to filtering data
    handleFilterList(event) {
        let value = event.detail ?? '';
        if (value) {
            this.list_TicketReasons = this.list_TicketReasonsMaster.filter(function (eachQueue) {
                return eachQueue.toLowerCase().indexOf(value.toLowerCase()) !== -1
            });
        }
        else {
            this.list_TicketReasons = this.list_TicketReasonsMaster;
        }
    }

    // Methods related to filtering data
    handleTeamFilterList(event) {
        let value = event.detail ?? '';
        if (value) {
            this.list_Teams = this.list_TeamsMaster.filter(function (eachQueue) {
                return eachQueue.toLowerCase().indexOf(value.toLowerCase()) !== -1
            });
        }
        else {
            this.list_Teams = this.list_TeamsMaster;
        }
    }

    //method called when team is selected
    handleTeamSelected(event) {
        this.strSelectedTeam = event.detail ?? '';
        this.strSelectedTicketReason = '';
        this.strSelectedTicketSubReason = '';

        if (!this.strSelectedTeam) {
            this.blnIsTicketReasonDisabled = true;
            this.strSelectedTeam = '';
            if (this.template.querySelector('c-auto-complete-cmp[data-id="selectteam"]')) {
                this.template.querySelector('c-auto-complete-cmp[data-id="selectteam"]').strTextInput = '';
            }
            
            if (this.template.querySelector('c-auto-complete-cmp[data-id="selectticketreason"]')) {
                this.template.querySelector('c-auto-complete-cmp[data-id="selectticketreason"]').strTextInput = '';
            }
        } else {
            this.getTicketReasonData();
            this.blnIsTicketReasonDisabled = false;
        }
        this.blnIsticketSubReasonDisabled = true;
        this.blnIsLoading = true;
        this.getTicketConfigData(true);
    }

    handleFilterSelected(event) {
        this.strSelectedTicketReason = event.detail;
        if (this.list_TicketSubReasons?.length > 0 ) {
            this.strSelectedTicketSubReason = '';
        }
        this.blnIsLoading = true;
        this.getTicketConfigData(true);
    }

    //method called when team is reset
    handleTeamReset() {
        this.strSelectedTeam = '';
        this.blnIsLoading = true;
    }

    //method called when the ticket reason is reset
    handleTicketReasonReset() {
        this.strSelectedTicketReason = '';
        this.blnIsLoading = true;
    }

    handleTicketSubReasonReset() {
        this.strSelectedTicketSubReason = '';
        this.blnIsLoading = true;
        this.getTicketConfigData(true);
    }

    handleDataChange(event) {
        this.objNewTicket[event.target.dataset.api] = event.detail.value ? 
                                                      event.detail.value.toString() : 
                                                      event.detail.checked;
    }

    handleTicketSave() {
        let blnIsValid = true;
        const allValid = [...this.template.querySelectorAll('lightning-input-field')]
        .reduce((validSoFar, inputCmp) => {
                    if (!inputCmp.reportValidity()) {
                        blnIsValid  = false;
                    }   
                    return validSoFar;
        }, true);

        if (blnIsValid) {
            this.blnIsLoading = true;
            this.objNewTicket.Contact__c = this.idContact;
            this.objNewTicket.Account__c = this.idAccount;
            this.objNewTicket.Case__c = this.idCase;
            this.objNewTicket.Team__c = this.strSelectedTeam;

            if (this.objTicketConfig.Stamp_Ticket_Reason__c) {
                this.objNewTicket.Escalation_Reason__c = this.strSelectedTicketReason;
                this.objNewTicket.Escalation_Reason_Detail__c = this.strSelectedTicketSubReason;
            }

            saveTicket({
                objTicket: this.objNewTicket,
                objTicketConfig: this.objTicketConfig
            }).then(result => {
                if (result.blnIsSuccess) {
                    this[NavigationMixin.GenerateUrl]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: result.objTicket.Id,
                            actionName: 'view',
                        },
                    }).then(url => {
                        const event = new ShowToastEvent({
                            "title": "Ticket Created!",
                            "variant": "success",
                            "message": "{1} created successfully!",
                            "mode": "sticky",
                            "messageData": [
                                result.objTicket.Name,
                                {
                                    url,
                                    label: result.objTicket.Name
                                }
                            ]
                        });
                        this.dispatchEvent(event);
                    });
                    this.handleCloseTab();
                } else {
                    displayToast(this, result.strMessage, '', 'error', 'sticky');
                }
                this.blnIsLoading = false;
            }).catch(error => {
                console.log('Error in creating tickets ', error);
                this.blnIsLoading = false;
            });
        }
    }

    handleCloseTab() {

        this.dispatchEvent(new CloseActionScreenEvent());//Added this line to close pop-up from quick action
        const closeTabEvent = new CustomEvent('closetab', {
            detail: {},
        });
        // Fire the custom event
        this.dispatchEvent(closeTabEvent);
    }

    navigateToOrder(event) {
        if (event.target.dataset.id) {
            navigateToSObject(
                this, 
                event.target.dataset.id, 
                'standard__recordPage', 
                'Benefit_Order__c' , 
                'view'
            ); 
        }
    }

    navigateToOpportunity(event) {
        if (event.target.dataset.id) {
            navigateToSObject(
                this, 
                event.target.dataset.id, 
                'standard__recordPage', 
                'Opportunity' , 
                'view'
            ); 
        }
    }

    navigateToCase(event) {
        if (event.target.dataset.id) {
            navigateToSObject(
                this, 
                event.target.dataset.id, 
                'standard__recordPage', 
                'Case' , 
                'view'
            ); 
        }
    }

    handleBenefitOrderSelected(event) {
        let blnOrderSelected = false;
        this.list_BenefitOrders?.forEach(eachOrder => {
            if (eachOrder.Id === event.target.dataset.id) {
                eachOrder.selected = true;
                blnOrderSelected = true;
                this.objNewTicket.Benefit_Order__c = eachOrder.Id;
            } else {
                eachOrder.selected = false;
            }
        });

        if (!blnOrderSelected) {
            this.objNewTicket.Benefit_Order__c = '';
        }

        this.list_DynamicFields?.forEach(eachField => {
            if (eachField.api === 'Benefit_Order__c') {
                eachField.value = event.target.dataset.id;
            }
        });
    }

    handleOpportunitySelected(event) {
        let blnOppSelected = false;
        this.list_Opportunities?.forEach(eachOpportunity => {
            if (eachOpportunity.Id === event.target.dataset.id) {
                eachOpportunity.selected = true;
                blnOppSelected = true;
                this.objNewTicket.Opportunity__c = eachOpportunity.Id;
            } else {
                eachOpportunity.selected = false;
            }
        });

        if (!blnOppSelected) {
            this.objNewTicket.Opportunity__c = '';
        }

        this.list_DynamicFields?.forEach(eachField => {
            if (eachField.api === 'Opportunity__c') {
                eachField.value = event.target.dataset.id;
            }
        });
    }

    handleCaseSelected(event) {
        let blnCaseSelected = false;
        this.list_RelatedCases?.forEach(eachCase => {
            if (eachCase.Id === event.target.dataset.id) {
                eachCase.selected = true;
                blnCaseSelected = true;
                this.idCase = eachCase.Id;

            } else {
                eachCase.selected = false;
            }
        });

        if (!blnCaseSelected) {
            this.idCase = this.idParentCase;
        }

        this.list_DynamicFields?.forEach(eachField => {
            if (eachField.api === 'Case__c') {
                eachField.value = event.target.dataset.id;
            }
        });
    }
}