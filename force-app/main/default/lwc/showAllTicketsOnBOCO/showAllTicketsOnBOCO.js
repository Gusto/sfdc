import { LightningElement, api, track } from 'lwc';
import getRelatedTickets from '@salesforce/apex/ShowAllTicketsOnBOCOCtrl.getRelatedTickets';
import { NavigationMixin } from 'lightning/navigation';
const COLUMNS = [
    {
        label: "Name", fieldName: "Link", type: "url", sortable: "true", typeAttributes: {
            label: { fieldName: 'Name' }, target: '_self'
        }
    },
    { label: 'Status', fieldName: 'Status__c' },
    { label: 'Ticket Reason', fieldName: 'Escalation_Reason__c', wrapText: true },
    { label: 'Owner', fieldName: 'Owner_Full_Name__c', wrapText: true }
];
export default class ShowAllTicketsOnBOCO extends NavigationMixin(LightningElement) {
    @api recordId;
    @api recordLimit;
    @track isNoTicket= false;
    @track tickets = [];
    @track paginatedData = [];
    columns = COLUMNS;

    isLoading = true;
    connectedCallback() {
        this.loadTickets();
    }

    loadTickets() {
        getRelatedTickets({ idCO: this.recordId })
            .then(result => {
                if (result) {
                    this.tickets = result.map((rec) => {
                        return { ...rec, "Link": '/' + rec.Id }
                    });
                }

                if (this.recordLimit !== undefined) {
                    this.paginatedData = this.tickets.slice(0, this.recordLimit);
                } else {
                    this.paginatedData = this.tickets;
                }
                if(this.tickets.length === 0){
                    this.isNoTicket = true;
                }
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                this.error = 'Error loading tasks: ' + error.body.message;
            });
    }

    handleShowMore() {
        this.isLoading = true;
        this.paginatedData = this.tickets;
        this.totalPages = 0;
        this.isLoading = false;
    }

    get showBar() {
        let showBar = false;
        if (this.recordLimit !== undefined && (this.tickets.length > this.recordLimit)) {
            showBar = true;
        }
        return showBar;
    }

    handleNavigate() {
        var compDefinition = {

            componentDef: 'c:showAllTicketsOnBOCO',
            attributes: {
                recordId: this.recordId,

            },
        };
        var encodedCompDef = btoa(JSON.stringify(compDefinition));
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/one/one.app#' + encodedCompDef,
                label: 'Hello'
            },
        });
    }
}