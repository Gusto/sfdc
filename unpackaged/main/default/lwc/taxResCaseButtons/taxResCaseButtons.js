import { LightningElement,track, wire, api } from 'lwc';
import queryPandaURL from '@salesforce/apex/TaxResCaseButtons.queryCase';
import USER_ID from '@salesforce/user/Id';
export default class TaxResCaseButtons extends LightningElement {
    @api recordId;
    strPandaURL;
    currentCase;

    connectedCallback() {
        this.doInit();
    }

    doInit() {
        queryPandaURL({
            strId: this.recordId
        })
        .then(result => {
            if(result) {
                this.currentCase = result;
            }
       })
       .catch(error => {
            console.log('!!! error', error);
       });
    }

    goToPandaURL() {
        window.open('https://app.gusto.com/panda/' + this.currentCase.Panda_Company_URL__c, '_blank');
    }

}