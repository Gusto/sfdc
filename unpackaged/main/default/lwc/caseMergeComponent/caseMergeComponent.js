import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import activateCaseAssignmentRules from '@salesforce/apex/CaseMergeLightningController.activateCaseAssignmentRules';
import setCaseOwner from '@salesforce/apex/CaseMergeLightningController.setCaseOwner';
import insertChatterFeed from '@salesforce/apex/CaseMergeLightningController.insertChatterFeed';
import getCaseData from '@salesforce/apex/CaseMergeLightningController.getCaseData';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACCOUNT_FIELD from "@salesforce/schema/Case.AccountId";
import CONTACT_FIELD from "@salesforce/schema/Case.ContactId";
import ORIGIN_FIELD from "@salesforce/schema/Case.Origin";
import DIRECTION_FIELD from "@salesforce/schema/Case.Direction__c";
import SUBJECT_FIELD from "@salesforce/schema/Case.Subject";
import DESCRIPTION_FIELD from "@salesforce/schema/Case.Description";
import RECORDTYPEID_FIELD from "@salesforce/schema/Case.RecordTypeId";
import CASEREASONTYPE_FIELD from "@salesforce/schema/Case.Type";
import CASEREASONCLASS_FIELD from "@salesforce/schema/Case.Class__c";
import CASEREASONSURVEYELIGIBLE_FIELD from "@salesforce/schema/Case.Send_Survey__c";
import CASEROUTINGCASEREASON_FIELD from "@salesforce/schema/Case.Routing_Case_Reason__c";
import CASEROUTINGCASEREASONCLASSIFICATION_FIELD from "@salesforce/schema/Case.Routing_Case_Reason_Classification__c";
import CASEREASONTASKUS_FIELD from "@salesforce/schema/Case.Task_Us__c";
import CASEREASONDONOTAUTOSOLVE_FIELD from "@salesforce/schema/Case.Do_not_Auto_Solve__c";
import CASEREASONPRIORITY_FIELD from "@salesforce/schema/Case.Priority";
import SKIPSURVEY_FIELD from "@salesforce/schema/Case.Skip_Survey__c";
import OWNERID_FIELD from "@salesforce/schema/Case.OwnerId";
import PARENTID_FIELD from "@salesforce/schema/Case.ParentId";
import CASESTATUS_FIELD from "@salesforce/schema/Case.Status";
import ID_FIELD from '@salesforce/schema/Case.Id';
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import { createRecord } from 'lightning/uiRecordApi';
import CASE_OBJECT from '@salesforce/schema/Case';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { updateRecord } from 'lightning/uiRecordApi';


export default class CaseMergeComponent extends NavigationMixin(LightningElement) {
    @api openModal;
    @track subject;
    @track description;
    @track caseNumber;
    @track loggedInUserId = Id;
    @api recordId;
    @track isToggle;
    @track isMergeToggle;
    @track isLoading = false;
    @track caseReasonClass;
    @track isCreateDisabled = true;
    @track caseReasonType;
    @track caseRecordType;
    @track isSubjectEntered;
    @track isRoutingEntered = false;
    @track isDescriptionEntered;
    @track caseReasonDoNotAutoSolve;
    @track caseReasonSurveyEligible;
    @track caseRoutingReason;
    @track caseReasonRoutingClassClassification;
    @track caseReasonPriority;
    @track caseReasonTaskUs;
    @track objectInfo;

    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_FIELD, CONTACT_FIELD] })
    originalCaseData;

    get account() {
        return getFieldValue(this.originalCaseData.data, ACCOUNT_FIELD);
    }

    get contact() {
        return getFieldValue(this.originalCaseData.data, CONTACT_FIELD);
    }



    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    objectInfo;

    getRecordTypeId(recordTypeName) {
        // Returns a map of record type Ids 
        const rtis = this.objectInfo.data.recordTypeInfos;
        return Object.keys(rtis).find(rti => rtis[rti].name === recordTypeName);
    }



    handleCreate() {


        //Submit information on Server
        this.isLoading = true;

        console.log('--we are here=--');
        const fields = {};
        fields[ACCOUNT_FIELD.fieldApiName] = this.account;
        fields[CONTACT_FIELD.fieldApiName] = this.contact;
        fields[SUBJECT_FIELD.fieldApiName] = this.subject;
        fields[DESCRIPTION_FIELD.fieldApiName] = this.description;
        fields[ORIGIN_FIELD.fieldApiName] = 'Follow Up Email';
        fields[DIRECTION_FIELD.fieldApiName] = 'Outbound';
        if (this.isToggle == false) {
            fields[OWNERID_FIELD.fieldApiName] = this.loggedInUserId;
        }
        fields[RECORDTYPEID_FIELD.fieldApiName] = this.caseRecordType;
        fields[CASEREASONCLASS_FIELD.fieldApiName] = this.caseReasonClass;
        fields[CASEREASONTYPE_FIELD.fieldApiName] = this.caseReasonType;
        fields[CASEREASONPRIORITY_FIELD.fieldApiName] = this.caseReasonPriority;
        fields[CASEREASONDONOTAUTOSOLVE_FIELD.fieldApiName] = this.caseReasonDoNotAutoSolve;
        fields[CASEREASONTASKUS_FIELD.fieldApiName] = this.caseReasonTaskUs;
        fields[CASEREASONSURVEYELIGIBLE_FIELD.fieldApiName] = this.caseReasonSurveyEligible;
        fields[CASEROUTINGCASEREASONCLASSIFICATION_FIELD.fieldApiName] = this.caseReasonRoutingClassClassification;
        fields[CASEROUTINGCASEREASON_FIELD.fieldApiName] = this.caseRoutingReason;
        const recordInput = { apiName: CASE_OBJECT.objectApiName, fields };
        console.log(JSON.stringify(recordInput));

        createRecord(recordInput)
            .then(result => {

                try {

                    console.log('---result---' + JSON.stringify(result));
                    if (this.isToggle == true) {
                        console.log('--came to rules method' +result.id);
                        activateCaseAssignmentRules({ caseId: result.id })
                            .then(result => {
                                console.log('--success--rules');
                            })
                            .catch(error => {
                                console.log('error--' + JSON.stringify(error));
                            })
                    }
                }
                catch (error) {
                    console.log('rules error' + JSON.stringify(error));
                }

                this.openModal = false;
                console.log('---navigation--');
                console.log(JSON.stringify(result));
                console.log(result);

                try {
                    const fields = {};
                    fields[ID_FIELD.fieldApiName] = this.recordId;
                    fields[PARENTID_FIELD.fieldApiName] = result.id;
                    if (this.isMergeToggle == true) {
                        console.log('--entered in merge case--');
                        fields[CASESTATUS_FIELD.fieldApiName] = 'Closed';
                        fields[SKIPSURVEY_FIELD.fieldApiName] = true;
                    }

                    const originalCaseInput = { fields };
                    console.log('---' + JSON.stringify(originalCaseInput));
                    updateRecord(originalCaseInput)
                    .then(result =>{
                        console.log('-merge case done--'+JSON.stringify(result));
                    })
                    .catch(error =>{
                        console.log('--merge case error--'+JSON.stringify(error));
                    })


                   
                    let newCaseId = result.id;
                    let newCaseNumber = result.fields.CaseNumber;
                    console.log('--newId' + JSON.stringify(result.fields.CaseNumber));
                    insertChatterFeed({caseId : this.recordId , caseNumber : newCaseNumber, strNewCaseId : newCaseId})
                    .then(result =>{
                        const openprimarytab = new CustomEvent('openprimarytab', {
                            detail: { newCaseId, newCaseNumber, closeAfterCreate: this.openModal },
                        });
                        this.dispatchEvent(openprimarytab);
                        console.log('--entered for feed' + JSON.stringify(result));
                        const evt = new ShowToastEvent({
                            title: 'Case Merged',
                            message: JSON.stringify(result),
                            variant: 'success',
                            mode: 'sticky',
                        });
                        this.dispatchEvent(evt);
                    })
                    .catch(error =>{
                        console.log('--feed error--'+JSON.stringify(error));
                    })
                    
                } catch (error) {
                    console.log('---' + error);
                }
                this.isLoading = false;
            })

            .catch(error => {
                console.log('--error==' + JSON.stringify(error));
            })


    }

    handleCancel() {
        this.openModal = false;

        this.dispatchEvent(new CustomEvent('closemodal', {
            detail: { closeModal: this.openModal }
        }));
    }

    handleDescription(event) {
        this.description = event.detail.value;
        if (event.detail.value != null && event.detail.value != '') {
            this.isDescriptionEntered = true;
        }
        else {
            this.isDescriptionEntered = false;
        }

        if (this.isSubjectEntered == true && this.isDescriptionEntered == true && this.isRoutingEntered == true) {
            this.isCreateDisabled = false;
        }
        else {
            this.isCreateDisabled = true;
        }

    }

    handleClosed(event) {
        this.isCreateDisabled = true;
    }

    handleSubject(event) {
        this.subject = event.detail.value;
        if (event.detail.value != null && event.detail.value != '') {
            this.isSubjectEntered = true;
        }
        else {
            this.isSubjectEntered = false;
        }

        if (this.isSubjectEntered == true && this.isDescriptionEntered == true && this.isRoutingEntered == true) {
            this.isCreateDisabled = false;
        }
        else {
            this.isCreateDisabled = true;
        }
    }

    connectedCallback() {
        console.log('--' + this.recordId);
    }
    closeModalForChange() {
        this.openModal = false;
    }

    handleToggle(event) {
        console.log('----' + event.target.checked);
        if (event.target.checked == true) {
            this.isToggle = true;
        }
        else {
            this.isToggle = false;
        }
    }

    handleMergeToggle(event) {

        if (event.target.checked == true) {
            this.isMergeToggle = true;
        } else {
            this.isMergeToggle = false;
        }
    }

    handleCaseReason(event) {
        this.isRoutingEntered = true;
        this.caseReasonClass = event.detail.caseReasonClass;
        this.caseReasonType = event.detail.caseReasonType;
        this.caseReasonTaskUs = event.detail.caseReasonTaskUs;
        this.caseReasonSurveyEligible = event.detail.caseReasonSurveyEligible;
        this.caseReasonDoNotAutoSolve = event.detail.caseReasonDoNotAutoSolve;
        this.caseReasonPriority = event.detail.caseReasonPriority;
        this.caseReasonRoutingClassClassification = event.detail.routingCaseReasonClassificationId;
        this.caseRoutingReason = event.detail.caseRoutingReason;
        this.caseRecordType = this.getRecordTypeId(event.detail.caseReasonType);

        if (this.isSubjectEntered == true && this.isDescriptionEntered == true && this.isRoutingEntered == true) {
            this.isCreateDisabled = false;
        }
        else {
            this.isCreateDisabled = true;
        }
    }
}