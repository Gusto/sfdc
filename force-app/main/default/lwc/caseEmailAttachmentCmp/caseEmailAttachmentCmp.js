import { LightningElement, api, wire} from 'lwc';
import getEmailMessage from '@salesforce/apex/CaseEmailAttachmentCmp.getEmailMessage'; 
import EMAILMESSAGE_OBJ from '@salesforce/schema/EmailMessage';
import SUBJECT from '@salesforce/schema/EmailMessage.Subject';
import FROM_ADDRESS from '@salesforce/schema/EmailMessage.FromAddress';
import TO_ADDRESS from '@salesforce/schema/EmailMessage.ToAddress';
import ATTACHMENT from '@salesforce/schema/EmailMessage.AttachmentIds';
import MESSAGE_DATE from '@salesforce/schema/EmailMessage.MessageDate';

const columns = [
    { label: 'Subject', fieldName: 'Subject' },
    { label: 'From Address', fieldName: 'FromAddress' },
    { label: 'To Address', fieldName: 'ToAddress' },
    { label: 'Attachment', fieldName: 'AttachmentIds' },
    { label: 'Message Date', fieldName: 'MessageDate' },
];

export default class CaseEmailAttachmentCmp extends LightningElement {
    @api recordId;
    data = [];
    columns = columns;

    @wire(getEmailMessage, {caseId:'$recordId'})
    wiredEmailMessage({ error, data }) {
        if (data) {
            this.data = data;
        } else if (error) {
            console.error('Error fetching EmailMessages:', error);
        }
    }

}