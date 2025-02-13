import { LightningElement, wire, track } from 'lwc';

import loadTicketConfigMetadata from '@salesforce/apex/TicketConfigController.loadTicketConfig';
import fetchTicketConfigInfo from '@salesforce/apex/TicketConfigController.getTicketConfigInfo';
import saveTicket from '@salesforce/apex/TicketConfigController.saveTicketConfig';
import { NavigationMixin } from 'lightning/navigation';

import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';

import { displayToast } from 'c/utilityService';

export default class TicketConfigCmp extends NavigationMixin(LightningElement) {
    @track blnIsLoading = false;

    @track blnIsOwnerQueue = false;
    @track strTicketReason = '';
    @track strTicketSubReason = '';

    @track list_SubReasons = [];

    @track list_TicketReasons = [];
    @track list_TicketSubReasons = [];
    @track list_Fields = [];
    @track list_TicketRecordTypes = [];
    @track list_OwnerQueues = [];
    @track list_OwnerQueueMaster = [];

    @track blnShowWarningMessage = false;

    @track objTicketConfig = {};

    @track map_ExistingFields = new Map();

    @track list_SelectedValues = [];

    @track list_TicketFields = [];
    @track list_TicketFieldMaster = [];

    @track strSelectedTicketField = '';
    @track strQueueLabel = 'Queue Name';

    @track list_Ownerships = [
        { label: 'Assign to a Queue', value: 'Assign to a Queue' },
        { label: 'Opportunity Owner', value: 'Opportunity Owner' },
        { label: 'Benefit Order Owner', value: 'Benefit Order Owner' },
        { label: 'Case Owner', value: 'Case Owner' }
    ];

    get sizeOptions() {
        return [
            { label: '3', value: '3' },
            { label: '6', value: '6' },
            { label: '9', value: '9' },
            { label: '12', value: '12' }
        ];
    }

    @track list_SelectedFields = [];
    @track blnFieldSelected = false;
    @track blnIsConfigFound = false;

    connectedCallback() {
        this.blnIsLoading = true;
        
        loadTicketConfigMetadata().then(result => {
            if (result.blnIsSuccess) {
                // Load Ticket Record Types
                let list_TicketRecordTypesTemp = [];
                result.list_TicketRecordTypes?.forEach(eachRecordType => {
                    list_TicketRecordTypesTemp.push({
                        label: eachRecordType,
                        value: eachRecordType
                    })
                });
                this.list_TicketRecordTypes = list_TicketRecordTypesTemp;

                // Load Ticket Fields
                let list_FieldsTemp = [];
                
                this.list_TicketFields = result.list_TicketFields;
                this.list_TicketFieldMaster = result.list_TicketFields;

                result.list_TicketFields?.forEach(eachField => {
                    list_FieldsTemp.push({
                        label: eachField,
                        value: eachField
                    })
                });
                this.list_Fields = list_FieldsTemp;

                // Load Ticket Reason List
                let list_TicketReasons = [];
                result.list_TicketReasons?.forEach(eachReason => {
                    list_TicketReasons.push({
                        label: eachReason,
                        value: eachReason
                    })
                });
                this.list_TicketReasons = list_TicketReasons;

                // Load Ticket Sub Reason List
                let list_TicketSubReasonsTemp = [];
                result.list_TicketSubReasons?.forEach(eachSubReason => {
                    list_TicketSubReasonsTemp.push({
                        label: eachSubReason,
                        value: eachSubReason
                    })
                });
                this.list_TicketSubReasons = list_TicketSubReasonsTemp;
                this.list_OwnerQueues = result.list_OwnerQueues;
                this.list_OwnerQueueMaster = result.list_OwnerQueues; 
            } else {
                displayToast(
                    this,
                    'Error loading field config. Reason: ' + result.strMessage, 
                    '', 
                    'error', 
                    ''
                );
            }
            this.blnIsLoading = false;
        }).catch(error => {
            console.error(error);
            this.blnIsLoading = false;
        })
    }

    handleTicketReasonSelected(event) {
        this.blnIsLoading = true;
        this.strTicketReason = event.detail.value;
        this.loadTicketConfig(event);
    }

    handleTicketSubReasonSelected(event) {
        this.blnIsLoading = true;
        this.strTicketSubReason = event.detail.value;
        this.objTicketConfig.Ticket_Sub_Reason__c = event.detail.value;
        this.loadTicketConfig(event);
    }

    loadTicketConfig() {
        fetchTicketConfigInfo({
            strTicketReason: this.strTicketReason,
            strTicketSubReason: this.strTicketSubReason,
            idCase: null
        }).then(result => {
            if (result.objTicketConfig) {
                let objTicketConfig = result.objTicketConfig;
                if (objTicketConfig) {
                    this.blnShowWarningMessage = false;
                    this.objTicketConfig = objTicketConfig;
                    this.list_SubReasons = objTicketConfig.Ticket_Sub_Reason_List__c ? objTicketConfig.Ticket_Sub_Reason_List__c.split(',') : [];
                    this.blnIsOwnerQueue = objTicketConfig.Owner_Type__c === 'Assign to a Queue' ? true : false;
                    this.objTicketConfig.Description__c = this.objTicketConfig.Description__c ? this.objTicketConfig.Description__c : '';
                    this.objTicketConfig.Talking_Points__c = this.objTicketConfig.Talking_Points__c ? this.objTicketConfig.Talking_Points__c : '';

                    // Load JSON array for fields
                    if (objTicketConfig.Configuration_Json__c) {
                        let list_SelectedValues = [];
                        let objJson = JSON.parse(objTicketConfig.Configuration_Json__c);
                        var list_SelectedValuesTemp = [];
                        objJson.forEach(eachValue => {
                            list_SelectedValues.push({
                                label: eachValue.label,
                                value: eachValue.label,
                                input: eachValue.input,
                                isRequired: eachValue.isRequired,
                                size: eachValue.size ? eachValue.size : '6',
                                overrideLabel: eachValue.overrideLabel
                            });
                            eachValue.value = eachValue.label;
                            this.map_ExistingFields.set(eachValue.label, eachValue);
                            list_SelectedValuesTemp.push(eachValue.label);
                        });
                        this.list_SelectedValues = list_SelectedValuesTemp;
                        this.list_SelectedFields = list_SelectedValues;
                        this.blnFieldSelected = true;
                    } else {
                        this.list_SelectedFields = this.list_SelectedValues = [];
                        this.blnFieldSelected = false;
                    }

                    this.strQueueLabel = this.blnIsOwnerQueue ? 'Queue Name' : 'Backup Queue Name';
                } 
            } else {
                this.blnShowWarningMessage = true;
                let objTicketConfig = {
                    Ticket_Reason__c: this.strTicketReason,
                    Ticket_Sub_Reason__c: this.strTicketSubReason,
                    Is_Active__c: true,
                    Name: this.strTicketReason,
                    Description__c: '',
                    Talking_Points__c: '',
                    Ticket_Record_Type__c: '',
                    Owner_Type__c: '',
                    Queue_Id__c: ''
                }; 
                this.list_SubReasons = [];
                this.objTicketConfig = objTicketConfig;
                this.blnIsOwnerQueue = false;
                this.list_SelectedFields = this.list_SelectedValues = [];
                this.blnFieldSelected = false;
                this.strQueueLabel = 'Queue Name';
                this.map_ExistingFields = new Map();
            }
            this.blnIsLoading = false;
            this.blnIsConfigFound = true;
        }).catch(error => {

        });
    }

    handleFieldChange(event) {
        let list_SelectValuesTemp = [];
        let strSelectedValue = String(event.detail.value);
        let list_SelectedValueSplit = strSelectedValue.split(',');

        if (strSelectedValue) {
            list_SelectedValueSplit?.forEach(eachValue => {
                if (this.map_ExistingFields.has(eachValue)) {
                    list_SelectValuesTemp.push(this.map_ExistingFields.get(eachValue));
                } else {
                    let option = {
                        label: eachValue,
                        value: eachValue,
                        isRequired: false,
                        size: '6',
                        overrideLabel: ''
                    };
                    list_SelectValuesTemp.push(option);
                    this.map_ExistingFields.set(eachValue, option);
                }
            });
        }
        this.list_SelectedFields = list_SelectValuesTemp;
        this.blnFieldSelected = strSelectedValue ? true : false;
    }

    handleOwnershipChange(event) {
        this.blnIsOwnerQueue = event.detail.value === 'Assign to a Queue' ? true : false;
        this.strQueueLabel = this.blnIsOwnerQueue ? 'Queue Name' : 'Backup Queue Name';
        this.handleDataChange(event);
    }

    handleSave() {
        const blnAllValid = [...this.template.querySelectorAll('lightning-combobox')]
        .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
        }, true);
        if (blnAllValid) {
            this.blnIsLoading = true;
            this.objTicketConfig.Configuration_Json__c = JSON.stringify(this.list_SelectedFields);
            saveTicket({
                objTicketConfig: this.objTicketConfig
            }).then(result => {
                if (result) {
                    this.objTicketConfig = result;
                    displayToast(
                        this, 
                        'Ticket Config successfully saved', 
                        '', 
                        'success', 
                        ''
                    );
                    this.blnShowWarningMessage = false;
                } else {
                    displayToast(
                        this, 
                        'Error saving ticket config record. Please try again later', 
                        '', 
                        'error', 
                        ''
                    );
                }
                window.scrollTo(0,0);
                this.blnIsLoading = false;
            }).catch(error => {
                console.log('Error in saving ticket configuration ', error);
            })
        }
    }

    handleDataChange(event) {
        if (event.detail.value) {
            let value = event.detail.value;
            if (event.target.dataset.api === 'Ticket_Sub_Reason_List__c') {
                value = value.toString();
            }
            this.objTicketConfig[event.target.dataset.api] = value;
        } 

        if (event.target.dataset.api === 'Stamp_Ticket_Reason__c') {
            this.objTicketConfig.Stamp_Ticket_Reason__c = event.detail.checked;
        }
    }

    handleFilterList(event) {
        let value = event.detail ? event.detail : '';
        this.list_OwnerQueues = this.list_OwnerQueueMaster.filter(function(eachQueue) {
            return eachQueue.toLowerCase().indexOf(value.toLowerCase()) !== -1
        });
    }

    handleFilterSelected(event) {
        this.objTicketConfig.Queue_Id__c = event.detail;
    }

    handleTicketSubReasonReset() {
        this.blnIsLoading = true;
        this.objTicketConfig.Ticket_Sub_Reason__c =  this.strTicketSubReason = '';
        this.loadTicketConfig(event);
    }

    handleOverrideLabelChange(event) {
        let strLabel = String(event.target.dataset.label);
        this.list_SelectedFields?.forEach(eachField => {
            if(eachField.label === strLabel) {
                eachField.overrideLabel = event.detail.value;
            }
        });

        if (this.map_ExistingFields.has(strLabel)) {
            this.map_ExistingFields.get(strLabel).overrideLabel = event.detail.value;
        }
    }

    handleRequiredChange(event) {
        let strLabel = String(event.target.dataset.label);
        this.list_SelectedFields?.forEach(eachField => {
            if (eachField.label === strLabel) {
                eachField.isRequired = event.detail.checked;
                if (event.detail.checked) {
                    eachField.input = true;
                }
            }
        });

        if (this.map_ExistingFields.has(strLabel)) {
            this.map_ExistingFields.get(strLabel).isRequired = event.detail.checked;
            if (event.detail.checked) {
                this.map_ExistingFields.get(strLabel).input = true;
            }
        }
    }

    handleSizeChange(event) {
        let strLabel = String(event.target.dataset.label);
        this.list_SelectedFields?.forEach(eachField => {
            if (eachField.label === strLabel) {
                eachField.size = event.detail.value;
            }
        });

        if (this.map_ExistingFields.has(strLabel)) {
            this.map_ExistingFields.get(strLabel).size = event.detail.value;
        }
    }

    handleCloneConfig() {
        const objDefaultValues = encodeDefaultFieldValues({
            Name: this.strTicketReason,
            Ticket_Sub_Reason__c: this.strTicketSubReason,
            Description__c: this.objTicketConfig.Description__c,
            Ticket_Reason__c: this.strTicketReason,
            Ticket_Record_Type__c: this.objTicketConfig.Ticket_Record_Type__c,
            Ticket_Sub_Reason_List__c: this.objTicketConfig.Ticket_Sub_Reason_List__c,
            Talking_Points__c: this.objTicketConfig.Talking_Points__c,
            Configuration_Json__c: this.objTicketConfig.Configuration_Json__c,
            Owner_Type__c: this.objTicketConfig.Owner_Type__c,
            Queue_Id__c: this.Queue_Id__c,
            Is_Active__c: true
        });

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Ticket_Config__c',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: objDefaultValues
            }
        });
    }

    handleTicketFieldFilterList(event) {
        let value = event.detail ? event.detail : '';
        this.list_TicketFields = this.list_TicketFieldMaster.filter(function(eachQueue) {
            return eachQueue.toLowerCase().indexOf(value.toLowerCase()) !== -1
        });
    }

    handleTicketFieldSelected(event) {
        if (event.detail) {
            this.strSelectedTicketField = event.detail;
            let list_SelectedValueSplit = [];

            // form a comma separated list of values
            this.list_SelectedValues?.forEach(eachField => {
                list_SelectedValueSplit.push(eachField);
            });

            if (!list_SelectedValueSplit.includes(this.strSelectedTicketField)) {
                list_SelectedValueSplit.push(this.strSelectedTicketField);
            }

            let list_SelectedValuesTemp = [];
            list_SelectedValueSplit?.forEach(objEachValue => {
                if (this.map_ExistingFields.has(objEachValue)) {
                    list_SelectedValuesTemp.push(this.map_ExistingFields.get(objEachValue));
                } else {
                    let objOption = {
                        label: this.strSelectedTicketField,
                        value: this.strSelectedTicketField,
                        isRequired: false,
                        size: '6',
                        overrideLabel: ''
                    };
                    list_SelectedValuesTemp.push(objOption);
                    this.map_ExistingFields.set(objEachValue, objOption);
                }
            });

            this.list_SelectedValues = list_SelectedValueSplit;
            this.blnFieldSelected = true;
            this.list_SelectedFields = list_SelectedValuesTemp;
        }
    }
}