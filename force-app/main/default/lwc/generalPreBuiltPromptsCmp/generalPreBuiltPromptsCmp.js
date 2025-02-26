import { LightningElement, wire, api, track } from "lwc";
import RT_NAME from "@salesforce/schema/Case.Record_Type_Name__c";
import { getRecord } from "lightning/uiRecordApi";
import getPennyAcctions from "@salesforce/apex/HackathonJJAO.getPennyAcctions";
import callGTP from "@salesforce/apex/HackathonJJAO.callGTP";


import Name from '@salesforce/schema/User.Name'; //this scoped module imports the current user full name
import Id from '@salesforce/user/Id';


export default class GeneralPreBuiltPromptsCmp extends LightningElement {
    @api recordId;
    recordTypeName;
    @track actions;
    @track conversation;
    userName;
    showThinking = false;
    disableButtons = false;
    outboundClass = 'slds-chat-listitem slds-chat-listitem_outbound';
    outboundClass2 = 'slds-chat-message__text slds-chat-message__text_outbound';
    inboundClass = 'slds-chat-listitem slds-chat-listitem_inbound';
    inboundClass2 = 'slds-chat-message__text slds-chat-message__text_inbound';

	@wire(getRecord, { recordId: "$recordId", fields: [RT_NAME] })
	async getUserRecord({ error, data }) {
		if (error) {
			console.log("error", error);
		} else if (data) {
			console.log(data);
            this.recordTypeName = data.fields.Record_Type_Name__c.value;
            await this.getAcctions();
		}
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

    async getAcctions() {
        try {
            console.log('calling');
            this.actions = await getPennyAcctions({ recordId: this.recordId, strRecordTypeName: this.recordTypeName, strObjectName: 'Case' });
            console.log('res:',this.actions);
        } catch (error) {
            console.log("error", error);
        }
    }

    async handleAction(event) {
        console.log('event:',event.target.dataset.id);
        let actionId = event.target.dataset.id;
        let actionName = event.target.dataset.name;
        console.log('event:',event.target.dataset.name);
        this.conversation = this.conversation == undefined ? [] : this.conversation;
        this.conversation.push({
            class: this.outboundClass,
            class2: this.outboundClass2,
            user_name: this.userName,
            message: 'Requesting action: '+actionName,
            time: new Date().toLocaleTimeString()
        });
        this.showThinking = true;
        this.disableButtons = true;
        try {
            console.log('calling:',actionId);
            let response = await callGTP({ promptId: actionId, prevResponse: null });
            console.log('response:',response);
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

//            topDiv.scrollIntoView();
        } catch (e) {
            console.log();
        }
    }
}