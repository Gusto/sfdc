import { LightningElement,api,wire } from 'lwc';

import { getRecord } from 'lightning/uiRecordApi';

export default class CaseSubjectHeader extends LightningElement {
    @api recordId;
    strCaseSubject;
    strCaseNumber;

    @wire(getRecord, { recordId: '$recordId', fields: [ 'Case.CaseNumber' ,'Case.Subject' ] })
    getCaseRecord({ data, error }) {
        if (data) {
            this.strCaseSubject = data.fields['Subject'].value;
            this.strCaseNumber = data.fields['CaseNumber'].value;
        }
    }
}