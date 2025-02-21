import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
export default class CarrierOrderTicketButtonsHandler extends NavigationMixin(LightningElement) {
    _recordId;
    showRecord = false;
    objectApiName;
    isBO = false;
    isCO = false;

    BENEFIT_ORDER_OBJECT = 'Benefit_Order__c';
    CARRIER_ORDER_OBJECT = 'Carrier_Order__c';
    BENEFIT_ORDER_TICKET_URL = (recordId) => `/apex/CreateNewTicketPage?id=${recordId}&from=Ticket`;
    BENEFIT_ORDER_QC_ERROR_URL = (recordId) => `/apex/CreateNewQCErrorBO?id=${recordId}&from=QCError`;
    CARRIER_ORDER_TICKET_URL = (recordId) => `/apex/CreateNewTicketPageCO?id=${recordId}&from=Ticket`;
    CARRIER_ORDER_QC_ERROR_URL = (recordId) => `/apex/CreateNewQCErrorCO?id=${recordId}&from=QCError`;

    @wire(getRecord, { recordId: '$recordId', layoutTypes: ['Full'], modes: ['View'] })
    wiredRecord({ error, data }) {
        if (data) {
            this.objectApiName = data.apiName;
            this.isBO = this.objectApiName === this.BENEFIT_ORDER_OBJECT;
            this.isCO = this.objectApiName === this.CARRIER_ORDER_OBJECT;
        } else if (error) {
            console.error('Error fetching record:', error);
        }
    }

    @api set recordId(value) {
        this._recordId = value;
        this.showRecord = true;
    }

    get recordId() {
        return this._recordId;
    }

    newTicket() {
        let newTicketURL = this.isBO
            ? this.BENEFIT_ORDER_TICKET_URL(this._recordId)
            : this.CARRIER_ORDER_TICKET_URL(this._recordId);

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: newTicketURL
            }
        });
    }

    newQCError() {
        let qcErrorURL = this.isBO
            ? this.BENEFIT_ORDER_QC_ERROR_URL(this._recordId)
            : this.CARRIER_ORDER_QC_ERROR_URL(this._recordId);

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: qcErrorURL
            }
        });
    }

    newTask() {
        const defaultValues = encodeDefaultFieldValues({
            WhatId: this._recordId
        });

        this[NavigationMixin.Navigate]({
            type: "standard__objectPage",
            attributes: {
                objectApiName: "Task",
                actionName: "new",
            },
            state: {
                defaultFieldValues: defaultValues,
                useRecordTypeCheck: 'true'
            }
        });
    }
}