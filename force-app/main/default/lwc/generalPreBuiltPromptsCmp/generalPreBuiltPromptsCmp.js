import { LightningElement, wire, api, track } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import getPennyAcctions from "@salesforce/apex/HackathonJJAO.getPennyAcctions";
import callGTP from "@salesforce/apex/HackathonJJAO.callGTP";

import Name from '@salesforce/schema/User.Name'; //this scoped module imports the current user full name
import Id from '@salesforce/user/Id';


export default class GeneralPreBuiltPromptsCmp extends LightningElement {
    @api recordId;
    recordTypeName;
    @track globalActions;
    showGlobalActions = false;
    showObjectActions = false;
    @track objectActions;
    @track globalChildActions;
    @api objectApiName;
    @track conversation;
    userName;
    showThinking = false;
    disableButtons = false;
    startChat = false;
    showSpinner = false;
    @track responses = [];
    @track recordTypeId;
    outboundClass = 'slds-chat-listitem slds-chat-listitem_outbound';
    outboundClass2 = 'slds-chat-message__text slds-chat-message__text_outbound';
    inboundClass = 'slds-chat-listitem slds-chat-listitem_inbound';
    inboundClass2 = 'slds-chat-message__text slds-chat-message__text_inbound';
    dynamicFields;
	@wire(getRecord, { recordId: "$recordId", fields:  "$dynamicFields"})
	async getUserRecord({ error, data }) {
		if (error) {
			console.log("error", error);
            this.recordTypeName = null;
            //await this.getAcctions();
		} else if (data) {
			console.log(data);
            this.recordTypeName = data.fields.RecordTypeId.value;
            await this.getAcctions();
		}
	}
        
    async connectedCallback() {
        this.showSpinner = true;
        console.log('objectApiName:', this.objectApiName);
        this.dynamicFields = this.objectApiName === 'Case' ? 'Case.RecordTypeId' : this.objectApiName === 'Account' ? 'Account.RecordTypeId' : 'Ticket__c.RecordTypeId';
        console.log('dynamicFields:', this.dynamicFields);
    }

    @wire(getRecord, { recordId: Id, fields: [Name] })
    userDetails({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            if (data.fields.Name.value != null) {
                this.userName = data.fields.Name.value;
            }
        }
    }

    startChatHandler() {
        this.startChat = true;
    }
    async getAcctions() {
        try {
            console.log('calling', this.objectApiName, this.recordTypeName);
            let response = await getPennyAcctions({ recordId: this.recordId, strRecordTypeName: this.recordTypeName, strObjectName: this.objectApiName });
            console.log('res:', response);
            let globalActions = [];
            let globalChildActions = [];
            let objectActions = [];
            for (let action of response) {
                //only parent actions
                if (action.Parent_Action_Name__c == undefined ){
                    if (action.Object__c != null) {
                        objectActions.push(action);
                    } else {
                        globalActions.push(action);
                    }
                }
            }
            for (let action of response) {
                if (action.Parent_Action_Name__c != undefined ){
                    //in case global child action, add it to all actions
                   if (action.Parent_Action_Name__c === 'Global') {
                        globalChildActions.push(action);
                   } else {
                    //TODO    handle child actions for object actions
                   }
                }
            }
            globalChildActions.push({
                Action_Name__c: 'Thanks! I have another question',
                Description__c: 'Thanks! I have another question',
            });
            console.log('globalActions:', globalActions);
            console.log('objectActions:', objectActions);
            console.log('globalChildActions:', globalChildActions);

            this.globalActions = globalActions;
            this.objectActions = objectActions;
            this.globalChildActions = globalChildActions;
            this.showGlobalActions = globalActions.length > 0;
            this.showObjectActions = objectActions.length > 0;
        } catch (error) {
            console.log("error", error);
        }
        this.showSpinner = false;
    }

    async handleAction(event) {
        console.log('event:',event.target.dataset.id);
        console.log('event:',event.target.dataset.global);

        let actionId = event.target.dataset.id;
        let actionName = event.target.dataset.name;
        let actionDescription = event.target.dataset.desc;
        if (actionName === 'Thanks! I have another question') {
            await this.getAcctions();
            //this.conversation = [];
            //this.responses = [];
            this.showThinking = false;
            this.disableButtons = false;
            this.conversation.push({
                class: this.outboundClass, 
                class2: this.outboundClass2,
                user_name: this.userName,
                message: 'Thanks! I have another question',
                time: new Date().toLocaleTimeString()
            });
            this.conversation.push({
                class: this.inboundClass, 
                class2: this.inboundClass2,
                user_name: 'Penny',
                message: 'Sure! Choose a new option from the Question Bank.',
                time: new Date().toLocaleTimeString()
            });
            return;
        }
        console.log('event:',event.target.dataset.name);
        this.conversation = this.conversation == undefined ? [] : this.conversation;
        this.conversation.push({
            class: this.outboundClass,
            class2: this.outboundClass2,
            user_name: this.userName,
            message: actionDescription,
            time: new Date().toLocaleTimeString()
        });
        this.showThinking = true;
        this.disableButtons = true;
        const topDiv = this.template.querySelector('[data-id="redDiv"]');
        console.log(topDiv.scrollHeight);
        topDiv.scrollTop = topDiv.scrollHeight;
        try {
            console.log('calling:',actionId);
            let response = await callGTP({ promptId: actionId, prevResponse: null});
            console.log('response:',response);
            this.responses.push(response);
            this.showThinking = false;
            this.disableButtons = false;
            this.conversation.push({
                class: this.inboundClass, 
                class2: this.inboundClass2,
                user_name: 'Penny',
                message: response,
                time: new Date().toLocaleTimeString()
            });
            const topDiv = this.template.querySelector('[data-id="redDiv"]');
            console.log(topDiv.scrollHeight);
            topDiv.scrollTop = topDiv.scrollHeight;
            this.globalActions = [];
            this.objectActions = this.globalChildActions;
            this.showObjectActions = true;
//            topDiv.scrollIntoView();
        } catch (e) {
            console.log();
        }
    }
}