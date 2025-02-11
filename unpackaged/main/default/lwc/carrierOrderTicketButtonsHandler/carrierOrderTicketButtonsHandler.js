import { LightningElement,api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
export default class CarrierOrderTicketButtonsHandler extends NavigationMixin (LightningElement) {
    _recordId;
    showRecord = false;

    @api set recordId(value) {
        this._recordId = value;
        this.showRecord = true;
    }

    get recordId() {
        return this._recordId;
    }

    newTicket(){
        let sr  = '/apex/CreateNewTicketPageCO?id='+this._recordId+'&from=Ticket';
        console.log('sr', sr);
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: sr
            }
        });
    }

    newQCError(){
        let sr  = '/apex/CreateNewQCErrorCO?id='+this._recordId+'&from=QCError';
        console.log('sr', sr);
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: sr
            }
        });
    }

    newTask() {
        const defaultValues = encodeDefaultFieldValues({
            WhatId: this._recordId
        });
        
        this[NavigationMixin.Navigate]( {
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