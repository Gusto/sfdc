import { LightningElement, api, track, wire } from 'lwc';

import getCaseInformation from '@salesforce/apex/CaseRoutingEmailPublisherController.getCaseInformation';
import queryReasons from '@salesforce/apex/CaseRoutingEmailPublisherController.queryReasons';
export default class CaseRoutingEmailPublisherCmp extends LightningElement {
    @api caseRecordId;
    @track blnIsLoading;
    /* routing case reason classification string */
    @track strRoutingReasonClassification;
    //if case reason has Auto Email Behavior, then make cmp visible
    @track blnShowHide;
    @track strBody;

    //selecting case reason
    @track blnIsCaseReasonFound = true;
    @track map_totalCaseReasonToGroup;
    @track map_caseReasonToGroupMap;
    @track map_ReasonNameToEmailContent = {};
    @track strHideOrShowLabel = 'Hide Email';
    @track blnShowTemplte = true;
    @track strIcon = 'utility:hide';
    connectedCallback(){
        getCaseInformation({idCaseRecord: this.caseRecordId})
        .then(result=>{
            if(result) {
                this.strRoutingReasonClassification = result.Name;
                this.strBody = result.EmailContent;
                if(result.EmailBehaviour){
                    this.blnShowHide = true;
                } else {
                    this.blnShowHide = false;
                }
            }
        });
        this.loadReasons();
    }

    //insert email content into email publisher
    handleInsertEmail(event){
        const evtOpenTab = new CustomEvent('opentab', {
            detail: {fullhtmlbody: this.strBody, caseId: this.caseRecordId},
        });
        // Fire the custom event
        this.dispatchEvent(evtOpenTab);
    }

    //load list of case reasons
    loadReasons() {
        this.blnIsLoading = true;
        queryReasons()
        .then(result => {
            if (result) {
                let list_arrCaseReasons = [];
                //loop through each group (payroll care, full-stack care, etc)
                for (const group in result) {
                    let list_caseReasonClassifications = [];
                    let objCaseReason = {};
                    objCaseReason.group = group;
                    //loop through each case reason in a group
                    for(let idCaseReason in result[group]) {
                        //label is reason's name from data
                        list_caseReasonClassifications.push({
                            label: result[group][idCaseReason].Name,
                            key: idCaseReason
                        });
                        //map reason name to reason's email content
                        this.map_ReasonNameToEmailContent[result[group][idCaseReason].Name] = result[group][idCaseReason].Email_Content__c;
                    }
                    objCaseReason.value = list_caseReasonClassifications;
                    list_arrCaseReasons.push(objCaseReason);
                }
                this.map_caseReasonToGroupMap = list_arrCaseReasons;
                this.map_totalCaseReasonToGroup = list_arrCaseReasons;
                if (list_arrCaseReasons.length === 0) {
                    this.blnIsCaseReasonFound = false;
                }
            }
            this.blnIsLoading = false;
        })
        .catch(error => {
            this.error = error;
            this.blnIsLoading = false;
        });
    }

    //filter the queues based on input
    handleFilterCaseReason(event) {
        let strInput = event.detail;
        strInput = strInput ? strInput : '';
        let totalCaseReasonMap = this.map_totalCaseReasonToGroup;
        let list_arrCaseReasons = [];
        let counter = 0;
        totalCaseReasonMap.forEach(objCaseReason => {
            let objCaseReasonToAdd = {};
            let list_sortedCaseReasonValues = [];
            let blnIsFound = false;
            objCaseReasonToAdd.group = objCaseReason.group;
            objCaseReason.value.forEach(strEachValue => {
                let strLabelName = strEachValue.label;
                if(!strLabelName)
                    strLabelName = "";
                if(strInput.Name)
                    strInput = strInput.Name;
                if(strLabelName.toLowerCase().includes(strInput.toLowerCase())) {
                    if(counter < 30) {
                        list_sortedCaseReasonValues.push(strEachValue);
                        blnIsFound = true;
                    }
                    counter = counter + 1;  
                }
            });
            if(blnIsFound) {
                objCaseReasonToAdd.value = list_sortedCaseReasonValues.sort();
                list_arrCaseReasons.push(objCaseReasonToAdd);
            }
        })

        this.map_caseReasonToGroupMap = list_arrCaseReasons;
        if(list_arrCaseReasons.length === 0) {
            this.blnIsCaseReasonFound = false;
        } else {
            this.blnIsCaseReasonFound = true;
        }

    }

    // When a case reason is selected from auto complete
    handleCaseReasonSelected(event) {
        if(!event.detail.reason) 
            this.strRoutingReasonClassification = "";
        else {
            //find email content from selected reason's name
            this.strRoutingReasonClassification = event.detail.reason;
            if(this.map_ReasonNameToEmailContent[this.strRoutingReasonClassification])
                this.strBody = this.map_ReasonNameToEmailContent[this.strRoutingReasonClassification];
        }
    }

    //When hide Email button is clicked, hide the Lightning-formatted-rich-text
    handleHideOrShowEmail(event) {
        
        this.strHideOrShowLabel = this.strHideOrShowLabel == 'Show Email' ? 'Hide Email' : 'Show Email' ;
        this.strIcon = this.strIcon == 'utility:preview' ? 'utility:hide' : 'utility:preview' ;
        this.blnShowTemplte = !(this.blnShowTemplte );
       
    }
}