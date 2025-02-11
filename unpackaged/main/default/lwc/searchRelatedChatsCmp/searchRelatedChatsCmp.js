import { LightningElement, track, api } from 'lwc';

/* Import Apex classes and methods*/
import fetchRelatedChats from "@salesforce/apex/SearchRelatedChatsController.fetchRelatedChats";

/* Import Methods from Utility Service */
import { displayToast } from 'c/utilityService';

const list_Columns = [
    {
        label: 'Name', fieldName: 'Name', type: 'button',
        typeAttributes: { label: { fieldName: 'Name' }, name: "View_Record", variant: "base" }
    },
    { label: 'Question', fieldName: 'Question__c', type: 'text' },
    { label: 'Requested By', fieldName: 'RequestedBy', type: 'text' },
    { label: 'Owner', fieldName: 'OwnerName', type: 'text' }
];

export default class SearchRelatedChatsCmp extends LightningElement {
    /* To store the question entered by the agent */
    @api strQuestion;
    /* To store the list of ChatTranscripts retrieved */
    @track list_Chats;
    /* Columns for the datatable */
    list_DatatableColumns = list_Columns;
    /* Flag to indicate that matching chats were found */
    blnShowChats = false;
    /* Flag to indicate that no matching chats were found */
    blnNoChatsFound;
    /* Flag toggle spinner */
    blnShowSpinner;

    connectedCallback() {
        this.getRelatedChats();
    }

    /* To fetch related ChatTranscripts */
    getRelatedChats() {
        this.blnShowSpinner = true;
        this.blnNoChatsFound = false;
        fetchRelatedChats({
            strQuestion: this.strQuestion
        }).then((result) => {
            if (result?.length > 0) {
                let list_Temp = [];
                for (var i = 0; i < result.length; i++) {
                    let objTemp = Object.assign({}, result[i]);
                    objTemp.OwnerName = result[i].Owner.Name;
                    objTemp.RequestedBy = result[i].Requested_By__r?.Name;
                    list_Temp.push(objTemp);
                }
                this.list_Chats = list_Temp;
                this.blnShowChats = true;
                this.blnShowSpinner = false;
            } else {
                this.blnShowChats = false;
                this.blnNoChatsFound = true;
                this.blnShowSpinner = false;
            }
        })
            .catch((error) => {
                this.blnShowSpinner = false;
                displayToast(this, 'Error', error, 'error', 'sticky');
            });
    }

    /* Handle value change for entered search key */
    handleKeyChange(event) {
        this.strQuestion = event.target.value;
    }

    /* To handle when the Name is clicked on the datatable */
    handleRowAction(event) {
        var strAction = event?.detail?.action?.name;
        switch (strAction) {
            case 'View_Record':
                const selectedEvent = new CustomEvent('rowclick', { detail: { chatId: event?.detail?.row?.Id } });
                this.dispatchEvent(selectedEvent);
                break;
            default:
        }
    }
}