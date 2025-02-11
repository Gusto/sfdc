import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCaseRecordType from '@salesforce/apex/LWC_UnmergeCase.getCaseRecordType';
import unmergeCaseRecord from '@salesforce/apex/LWC_UnmergeCase.unmergeCaseRecord';

export default class Unmergecaselwc extends LightningElement {
    @api recordId;
    @track showHideUnmerge = false;
    @track caseRecord;
    @track isLoading = false;

    connectedCallback(){
        this.isLoading = true;
        getCaseRecordType({caseId : this.recordId})
        .then(result=>{
            console.log('result>>'+ JSON.stringify(result));
            if(result && result.isSuccess) {
                this.showHideUnmerge = true;
                this.caseRecord = result.responseData.caseRec;
                console.log('result>>'+ JSON.stringify(this.caseRecord));
                this.isLoading = false;
            } else {
                this.showHideUnmerge = false;
                this.isLoading = false;
            }
        })
    }
    handleUnMergeCase(event) {
        this.isLoading = true;
        console.log(this.caseRecord+ '::::caseRecord:":"'+JSON.stringify(event.target.value));
        unmergeCaseRecord({caseRec : event.target.value})
        .then(result=>{
            console.log('result>>'+ JSON.stringify(result));
            if(result && result.isSuccess) {
                console.log('result.response' + JSON.stringify(result.responseData));
                this.isLoading = false;
                this.showToast('Success','Case Unmerge Successful','success');
                const recordNavigation = new CustomEvent('handleUnMergeCase',{});
                console.log('dispatching custom event'+ JSON.stringify(recordNavigation));
                this.dispatchEvent(recordNavigation);
            } else {
                this.showToast('Error','Case Unmerge Unsuccessful','error');
                this.isLoading = false;
            }
        })
    }
    showToast(title,message,variantType) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variantType,
        }); 
        this.dispatchEvent(event);
    }
}