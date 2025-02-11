import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CASE_OBJECT from '@salesforce/schema/Case';
import ERRORORIGIN_FIELD from "@salesforce/schema/Case.Error_Origin_New__c";
import ADMINVALUE_FIELD from "@salesforce/schema/Case.Did_Admin_Request_to_Speak_to_Manager__c";
import CUSTOMEROUTREACH_FIELD from "@salesforce/schema/Case.Preferred_Customer_Outreach__c";
import CONFIRM_CASE_REASON_FIELD from "@salesforce/schema/Case.Confirm_Case_Reason__c";
import createFollowEscalationCase from '@salesforce/apex/FollowUpEscalationCaseController_LEX.createFollowEscalationCase';
import insertChatterFeed from '@salesforce/apex/FollowUpEscalationCaseController_LEX.insertChatterFeed';

export default class FollowUpEscalationCaseCmp extends LightningElement {
  //TO get the Case Record Id
  @api strRecordId;
  // Flag for modal opening and closing
  @api blnOpenModal;
  //To get case object info
  @track objectInfo;
  // To store the selected value in customer outreach picklist
  @track strValue;
  //To store the subject value
  @track strSubject;
  //To store the description value
  @track strDescription;
  //To store the value of picklist
  @track strEscalationSteps;
  // Used for spinner
  @track blnIsLoading = false;
  //Flag for disabling create button
  @track blnIsCreateDisabled = true;
  //To check if Customer Outreach field is filled
  @track blnIsCustomerOutreachEntered;
  //To check if Error Origin field is filled
  @track blnIsErrorOriginEntered;
  //To check if Description field is filled
  @track blnIsDescriptionEntered;
  //To check if Confirm Case Reason field is filled
  @track strConfirmCaseReasonSelected;
  //To check if Escalation Steps field is filled
  @track blnIsEscalateStepsEntered;
  //To check if Request field is filled
  @track blnIsRequestEntered;
  //To store customer outreach values
  @track strPicklistValue;
  //To store error origin values
  @track strErrorOriginValue;
  //To store error origin selected values
  @track strErrorOriginSelected;
  @track strAdminValueSelected;
  @track strAdminValue;
  @track strAdminValueOptions;
  @track preferredTime;
  dtmPreferredTime;
  //To store the escalation type
  @api strEscalationType;
  //Case info for getting record type
  @track caseInfo;
  //Name of the queue that the case must be routed to.
  @api strEscalationQueueName;

  connectedCallback() {
    let today = new Date();
    let minuteData = (today.getMinutes() <= 9) ?'0'+today.getMinutes() :today.getMinutes();
    this.preferredTime = (today.getHours() + 1) + ":" + minuteData;
    if (this.preferredTime) {
      let list_TimeParts = this.preferredTime.split(":");
      let dtmChosenTime = new Date(today.getFullYear(), today.getMonth(), today.getDate(), list_TimeParts[0], list_TimeParts[1]);
      this.dtmPreferredTime = dtmChosenTime;
    }
  }

  //Method to get fields from the original case
  @wire(getRecord, { recordId: '$strRecordId', fields: [CONFIRM_CASE_REASON_FIELD] })
  originalCaseData({ error, data }) {
    if (data) {
      this.strSubject = 'Follow-up from Gusto';
      this.strConfirmCaseReasonSelected = data?.fields?.Confirm_Case_Reason__c?.displayValue;
    }
  }

  //get info about the Case object
  @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
  caseInfo;

  //getter for the Payroll Care record type id
  get caseRecordTypeId() {
    const objRecTypeIds = this.caseInfo.data.recordTypeInfos;
    return Object.keys(objRecTypeIds).find(rti => objRecTypeIds[rti].name === 'Payroll Care');
  }

  //Method to display values in preferred customer outreach picklist
  @wire(getPicklistValues, {
    recordTypeId: '$caseRecordTypeId',
    fieldApiName: CUSTOMEROUTREACH_FIELD
  })
  OutreachPicklistValues({ data, error }) {
    if (data) {
      this.strPicklistValue = data.values;
    }
    if (error) {
      console.log("error" + error);
    }
  }

  //Method to display values in preferred error origin picklist
  @wire(getPicklistValues, {
    recordTypeId: '$caseRecordTypeId',
    fieldApiName: ERRORORIGIN_FIELD
  })
  ErrorOriginPicklistValues({ data, error }) {
    if (data) {
      var objControllerIndex = data.controllerValues[this.strEscalationType];
      var optionsList = [];
      for (var index = 0; index < data.values.length; index++) {
        if (data.values[index]['validFor'].includes(objControllerIndex)) {
          var option = { label : data.values[index]['label'], value : data.values[index]['value'] };
          optionsList.push(option);
        }
      }
      this.strErrorOriginValue = optionsList;
    }
    if (error) {
      console.log("error" + error);
    }
  }

  //Method to display values in Admin Value picklist
  @wire(getPicklistValues, {
    recordTypeId: '$caseRecordTypeId',
    fieldApiName: ADMINVALUE_FIELD
  })
  AdminValuesPicklistValues({ data, error }) {
    if (data) {
      this.strAdminValueOptions = data.values;
    }
    if (error) {
      console.log("error" + error);
    }
  }

  //Method to handle values when customer outreach value is changed  
  handleChange(event) {
    this.strValue = event.detail.value;
    if (event.detail.value != null && event.detail.value != '') {
      this.blnIsCustomerOutreachEntered = true;
    }
    else {
      this.blnIsCustomerOutreachEntered = false;
    }

    if (this.blnIsCustomerOutreachEntered == true && this.blnIsDescriptionEntered == true && this.blnIsErrorOriginEntered == true && this.blnIsRequestEntered == true && this.blnIsEscalateStepsEntered == true) {
      this.blnIsCreateDisabled = false;
    }
    else {
      this.blnIsCreateDisabled = true;
    }
  }

  //Method to handle values when error origin value is changed 
  handleOriginChange(event) {
    this.strErrorOriginSelected = event.detail.value;
    if (event.detail.value != null && event.detail.value != '') {
      this.blnIsErrorOriginEntered = true;
    }
    else {
      this.blnIsErrorOriginEntered = false;
    }

    if (this.blnIsCustomerOutreachEntered == true && this.blnIsDescriptionEntered == true && this.blnIsErrorOriginEntered == true && this.blnIsRequestEntered == true && this.blnIsEscalateStepsEntered == true) {
      this.blnIsCreateDisabled = false;
    }
    else {
      this.blnIsCreateDisabled = true;
    }
  }

  //Method to handle values when admin value is changed 
  handleAdminValueChange(event) {
    this.strAdminValueSelected = event.detail.value;
    if (event.detail.value != null && event.detail.value != '') {
      this.blnIsRequestEntered = true;
    }
    else {
      this.blnIsRequestEntered = false;
    }

    if (this.blnIsCustomerOutreachEntered == true && this.blnIsDescriptionEntered == true && this.blnIsErrorOriginEntered == true && this.blnIsRequestEntered == true && this.blnIsEscalateStepsEntered == true) {
      this.blnIsCreateDisabled = false;
    }
    else {
      this.blnIsCreateDisabled = true;
    }
  }

  //Method to handle values when description value is changed 
  handleDescription(event) {
    this.strDescription = event.detail.value;
    if (event.detail.value != null && event.detail.value != '') {
      this.blnIsDescriptionEntered = true;
    }
    else {
      this.blnIsDescriptionEntered = false;
    }

    if (this.blnIsCustomerOutreachEntered == true && this.blnIsDescriptionEntered == true && this.blnIsErrorOriginEntered == true && this.blnIsRequestEntered == true && this.blnIsEscalateStepsEntered == true) {
      this.blnIsCreateDisabled = false;
    }
    else {
      this.blnIsCreateDisabled = true;
    }
  }

  //Method to handle values when escalation steps taken value is changed 
  handleStepsTaken(event) {
    this.strEscalationSteps = event.detail.value;
    if (event.detail.value != null && event.detail.value != '') {
      this.blnIsEscalateStepsEntered = true;
    }
    else {
      this.blnIsEscalateStepsEntered = false;
    }

    if (this.blnIsCustomerOutreachEntered == true && this.blnIsDescriptionEntered == true && this.blnIsErrorOriginEntered == true && this.blnIsRequestEntered == true && this.blnIsEscalateStepsEntered == true) {
      this.blnIsCreateDisabled = false;
    }
    else {
      this.blnIsCreateDisabled = true;
    }
  }


  //Method to Create a new Case
  handleCreate() {
    this.blnIsLoading = true;
    createFollowEscalationCase({ 
      idOriginalCase: this.strRecordId, 
      strErrorOrigin: this.strErrorOriginSelected, 
      strDescription: this.strDescription, 
      strSubject: this.strSubject, 
      strCustomOutreach: this.strValue, 
      strSteps: this.strEscalationSteps, 
      strAdminRequest: this.strAdminValueSelected, 
      strTime: this.dtmPreferredTime, 
      strCaseReasonSelected: this.strConfirmCaseReasonSelected,
      strCaseEscalationType: this.strEscalationType,
      strEscalationQueue: this.strEscalationQueueName })
      .then(result => {
        this.blnOpenModal = false;
        insertChatterFeed({ idParentCase: this.strRecordId, strCaseNumber: result.CaseNumber, strNewCaseId: result.Id })
          .then(result => {
          })
          .catch(error => {
          })
        const event = new ShowToastEvent({
          "title": "Case Created!",
          "mode": "sticky",
          "variant": "success",
          "message": "Case {1} created!",
          "messageData":
            [
              'Case',
              {
                url: location.origin + '/lightning/r/case/' + result.Id + '/view',
                label: result.CaseNumber
              }
            ]
        });
        this.dispatchEvent(event);

        this.dispatchEvent(new CustomEvent('closemodal', {
          detail: { closeModal: this.blnOpenModal }
        }));

        this.blnIsLoading = false;
      })

      .catch(error => {
        const toastEvent = new ShowToastEvent({
          "title": "error",
          "mode": "sticky",
          "variant": "error",
          "message": error.body.message
        });
        this.dispatchEvent(toastEvent);

      })

  }


  handleCaseReasonSelected(event) {
    this.strConfirmCaseReasonSelected = event.detail.reason;
  }
  handleCancel() {
    this.blnOpenModal = false;
    this.dispatchEvent(new CustomEvent('closemodal', {
      detail: { closeModal: this.blnOpenModal }
    }));
  }

  //Method to get Preferred Time
  // get time() {
  //   let today = new Date();
  //   let minuteData = (today.getMinutes() <= 9) ?'0'+today.getMinutes() :today.getMinutes();
  //   let time = (today.getHours() + 1) + ":" + minuteData;
  //   let today2 = new Date(today.getFullYear(), today.getMonth(), today.getDate(), (today.getHours() + 1), minuteData);
  //   this.testDate = today2;
  //   return time;
  // }

  handleTimeChange(event) {
    let today = new Date();
    let chosenTime = event.detail.value;
    if (chosenTime) {
      let list_TimeParts = chosenTime.split(":");
      let dtmChosenTime = new Date(today.getFullYear(), today.getMonth(), today.getDate(), list_TimeParts[0], list_TimeParts[1]);
      this.preferredTime = chosenTime;
      this.dtmPreferredTime = dtmChosenTime;
    }
  }
}