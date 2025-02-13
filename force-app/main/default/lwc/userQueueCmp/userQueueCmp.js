import { LightningElement, wire, track, api } from "lwc";
import Id from '@salesforce/user/Id';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from "@salesforce/apex";
import getUserData from "@salesforce/apex/UserQueueComponentController_LEX.getUserData";
import updateUserData from "@salesforce/apex/UserQueueComponentController_LEX.updateUserData";
import retrieveUsers from '@salesforce/apex/UserQueueComponentController_LEX.retrieveUsers';
import retrieveRoles from '@salesforce/apex/UserQueueComponentController_LEX.retrieveRoles';
import getDirectReportUsers from '@salesforce/apex/UserQueueComponentController_LEX.getDirectReportUsers';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import CLASSQUEUE_FIELD from "@salesforce/schema/User.Class_Queue__c";
import DIRECTREPORT_FIELD from '@salesforce/schema/User.Direct_Report__c';
import BENEFITS_FIELD from "@salesforce/schema/User.Benefits_Class__c";
import ALLQUEUES_FIELD from "@salesforce/schema/User.All_Queues__c";
import INDIVIDUALQUEUES_FIELD from "@salesforce/schema/User.Individual_Queues__c";
import PRCDATE1_FIELD from "@salesforce/schema/User.On_The_Floor_Date_Care__c";
import PRCDATE2_FIELD from "@salesforce/schema/User.On_The_Floor_Date_PRC_Class_2__c";
import PRCDATE3_FIELD from "@salesforce/schema/User.On_The_Floor_Date_PRC_Class_3__c";
import FSCDATE1_FIELD from "@salesforce/schema/User.On_The_Floor_Date_FSC__c";
import FSCDATE2_FIELD from "@salesforce/schema/User.On_The_Floor_Date_FSC_Class_2__c";
import FSCDATE3_FIELD from "@salesforce/schema/User.On_The_Floor_Date_FSC_Class_3__c";
import DSPDATE1_FIELD from "@salesforce/schema/User.On_The_Floor_Date_DSP__c";
import DSPDATE2_FIELD from "@salesforce/schema/User.On_The_Floor_Date_DSP_Class_2__c";
import DSPDATE3_FIELD from "@salesforce/schema/User.On_The_Floor_Date_DSP_Class_3__c";
import PRCHOMEROOM_STARTDATE_FIELD  from "@salesforce/schema/User.PRC_Homeroom_Start_Date__c";
import FSCHOMEROOM_STARTDATE_FIELD  from "@salesforce/schema/User.FSC_Homeroom_Start_Date__c";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import USER_OBJECT from "@salesforce/schema/User";



export default class UserQueueComponent extends LightningElement {
  fields = [ALLQUEUES_FIELD, INDIVIDUALQUEUES_FIELD, CLASSQUEUE_FIELD, BENEFITS_FIELD, 
            PRCDATE1_FIELD, PRCDATE2_FIELD, PRCDATE3_FIELD, 
            FSCDATE1_FIELD, FSCDATE2_FIELD, FSCDATE3_FIELD, 
            DSPDATE1_FIELD, DSPDATE2_FIELD, DSPDATE3_FIELD, 
            PRCHOMEROOM_STARTDATE_FIELD, FSCHOMEROOM_STARTDATE_FIELD];
  userId = Id;
  @track strUserData;
  /* To store the change in picklist value of ClassQueue picklist field*/
  @track strClassQueueValues;
  /* To store the change in picklist value of Benefits Class picklist field*/
  @track strBenefitsValues;
  /* To store the change in picklist value of AllQueues picklist field*/
  @track strAllqueueValues;
  /* To store the Id of the user whose record is being edited*/
  @track strRedirectUserId;
  /* To store the Name of the user whose record is being edited*/
  @track strUserName;
  /*Flag to position the error message when no string is entered in Search User search bar*/
  @track strStyleUser = 'margin-top: 20px;';
  /*Flag to position the error message when no string is entered in Search Role search bar*/
  @track strStyleRole = 'margin-top: 20px;';
  /*Flag to resize the screen into two while editing the record */
  @track intLayoutSize = 12;
  /*To show the number or records in one page.*/
  @track intNumberOfRecords = 20;
  /* To store the change in picklist value of Individual Queue picklist field*/
  @track strIndividualqueueValues;
  /* To show Spinner */
  @track blnIsLoading = false;
  /* Show docker with save and cancel buttons */
  @track blnShowSaveCancel;
  /* Show docker with Update and cancel buttons */
  @track blnShowUpdateCancel = false;
  /*Flag to open modal */
  @track blnOpenModal = false;
  /*To check if there is any string entered in user and roles search bar */
  @track strSearchData;
  /*To get the direct reporting users of the logged in user */
  @track strDirectReport;
  /*To get the direct reporting users of the logged in user */
  @track strDirectReportDummy;
  /* String to capture the error message for user search bar*/
  @track strUserErrorMsg = '';
  /* String to capture the error message for role search bar*/
  @track strRoleErrorMsg = '';
  @track blnPanelShowHide = true;
  /* List to handle number of records */
  @track lst_usersCopy = [];
  /* Flag to cpature if row editable has been clicked */
  @track blnIsEditClicked = false;
  /*String to capture users */
  @track strUsers;
  /*Used for pagination */
  @track intLastIndex = 0;
  strSearchAccName = '';
  /* String entered to search users */
  strSearchUserName = '';
  /* String entered to search roles */
  strSearchRoleName = '';
  /* Map to capture inline edit data */
  map_editDataMap = new Map();
  /*List to capture inline edit data */
  lst_editDataList = [];


  @wire(getObjectInfo, { objectApiName: USER_OBJECT })
  objectInfo;
  
  
  @wire(getRecord, { recordId: Id, fields: [DIRECTREPORT_FIELD] })
  loggedInUser({ data, error }) {
    if (data) {
      this.strDirectReport = data.fields.Direct_Report__c.value;
      //this.directReportDummy = data.fields.Direct_Report__c.value;
      console.log('data---' + JSON.stringify(data));
    } else if (error) {
      console.log("error: " + error);
    }
  }



  // Method to get Class/Queue field Picklist Values
  @wire(getPicklistValues, {
    recordTypeId: "012000000000000AAA",
    fieldApiName: CLASSQUEUE_FIELD
  })
  wiredClassQueueValues({ data, error }) {
    if (data) {
      this.strClassQueueValues = data.values;
    } else if (error) {
      console.log("error: " + error);
    }
  }

  // Method to get Individual Queue field Picklist Values
  @wire(getPicklistValues, {
    recordTypeId: "012000000000000AAA",
    fieldApiName: INDIVIDUALQUEUES_FIELD
  })
  wiredIndividualQueueValues({ data, error }) {
    if (data) {
      this.strIndividualqueueValues = data.values;
    } else if (error) {
      console.log("error: " + error);
    }
  }


  // Method to get All Queues field Picklist Values
  @wire(getPicklistValues, {
    recordTypeId: "012000000000000AAA",
    fieldApiName: ALLQUEUES_FIELD
  })
  wiredAllQueueValues({ data, error }) {
    if (data) {
      this.strAllqueueValues = data.values;
    } else if (error) {
      console.log("error: " + error);
    }
  }


  // Method to get Benefits Class field Picklist Values
  @wire(getPicklistValues, {
    recordTypeId: "012000000000000AAA",
    fieldApiName: BENEFITS_FIELD
  })
  wiredbenefitsValues({ data, error }) {
    if (data) {
      this.strBenefitsValues = data.values;
    } else if (error) {
      console.log("error: " + error);
    }
  }

  //Method to fetch User Data
  @wire(getUserData)
  wiredUsers({ data, error }) {
    if (data) {
      this.strUsers = data;
      this.intLastIndex = 0;
      this.lst_usersCopy.length = 0;
      for (let i = this.intLastIndex; i < (this.intLastIndex + this.intNumberOfRecords); i++) {
        if (i < this.strUsers.length) {
          this.lst_usersCopy.push(this.strUsers[i]);
        } else {
          break;
        }
      }
      this.strDirectReportDummy = data;
    }
  }

  // To give options for number of records to be displayed
  get options() {
    return [
      { label: '20', value: '20' },
      { label: '50', value: '50' },
      { label: '100', value: '100' },
    ];
  }

  // Pagination on the basis of number of records selected
  handleNumberOfRecords(event) {
    this.intNumberOfRecords = parseInt(event.detail.value);
    this.blnIsLoading = true;
    new Promise(
      (resolve, reject) => {
        setTimeout(() => {
          this.lst_usersCopy.length = 0;
          for (let i = this.intLastIndex; i < (this.intLastIndex + this.intNumberOfRecords); i++) {
            if (i < this.strUsers.length) {
              this.lst_usersCopy.push(this.strUsers[i]);
            } else {
              break;
            }
          }
          resolve();
        }, 0);
      }).then(
        () => this.blnIsLoading = false
      );
  }

  //Method to handle inline editing of benefit class field
  handleBenefitChange(event) {
    this.blnShowSaveCancel = true;
    try {
      if (this.map_editDataMap.has(event.target.dataset.id)) {
            this.map_editDataMap.get(event.target.dataset.id).strBenefitsClass =
          event.detail.value;
      } else {
        let blnChecked = (event.target.dataset.checked === 'true');
        let obj = {
          Id: event.target.dataset.id,
          strBenefitsClass: event.detail.value,
          strClassQueue: event.target.dataset.classqueue,
          blnOutOfOffice: blnChecked
        };
        this.map_editDataMap.set(event.target.dataset.id, obj);
      }
    } catch (error) {
      console.log("error: " + error);
    }
  }

  //When any field on the edit panel is being edited
  handleInputField(event) {
    this.blnShowUpdateCancel = true;
  }

  ////Method to handle inline editing of benefit class field
  handleClassChange(event) {
    this.blnShowSaveCancel = true;
    try {
      if (this.map_editDataMap.has(event.target.dataset.id)) {
           this.map_editDataMap.get(event.target.dataset.id).strClassQueue =
          event.detail.value;
      } else {
        let blnChecked = (event.target.dataset.checked === 'true');
        let obj = {
          Id: event.target.dataset.id,
          strClassQueue: event.detail.value,
          strBenefitsClass: event.target.dataset.benefitclass,
          blnOutOfOffice: blnChecked
        };
        this.map_editDataMap.set(event.target.dataset.id, obj);

      }
    } catch (error) {
      console.log("error: " + error);
    }
  }

  //Method to handle inline editing of out of office field
  handleOfficeChange(event) {
    this.blnShowSaveCancel = true;
    try {
      if (this.map_editDataMap.has(event.target.dataset.id)) {
        this.map_editDataMap.get(event.target.dataset.id).blnOutOfOffice =
          event.detail.checked;
      } else {
        let obj = {
          Id: event.target.dataset.id,
          blnOutOfOffice: event.detail.checked,
          strBenefitsClass: event.target.dataset.benefitclass,
          strClassQueue: event.target.dataset.classqueue
        };
        this.map_editDataMap.set(event.target.dataset.id, obj);
      }
    } catch (error) {
      console.log("error: " + error);
    }
  }

  //Method to save the edited data in user record
  onSave() {
    this.blnShowSaveCancel = false;
    try {
      console.log(JSON.stringify(this.map_editDataMap.values()));
      for (let value of this.map_editDataMap.values()) {
        this.lst_editDataList.push(value);
      }

      updateUserData({
        strUserUpdateData: JSON.stringify(this.lst_editDataList)
      })
        .then((result) => {
          this.strUsers = result;
          this.lst_usersCopy.length = 0;
          for (let i = this.intLastIndex; i < (this.intLastIndex + this.intNumberOfRecords); i++) {
            if (i < this.strUsers.length) {
              this.lst_usersCopy.push(this.strUsers[i]);
            } else {
              break;
            }
          }
          this.map_editDataMap.clear();
          this.lst_editDataList = [];


        })
        .catch((error) => {
          console.log("error: " + JSON.stringify(error));
          this.map_editDataMap.clear();
          this.lst_editDataList = [];
        });
    } catch (error) {
      console.log("error: " + JSON.stringify(error));
    }
  }

  
  onCancel() {
    this.blnShowSaveCancel = false;
    window.location.reload();
  }

  //When edit panel is opened, first and last name are row editable
  handleEditClick(event) {

    console.log('event target ' + JSON.stringify(event.target));
    if (this.blnShowUpdateCancel == false) {
      this.blnIsEditClicked = true;
      this.intLayoutSize = 6;
      this.strRedirectUserId = event.target.dataset.id;
      this.strUserName = event.target.dataset.userfirstname + ' ' + event.target.dataset.userlastname;
      this.blnPanelShowHide = false;
    } else {
      this.blnOpenModal = true;
    }

  }

  // Method to capture the changed user value
  handleUserInput(event) {
    this.strSearchUserName = event.detail.value;
  }

  //Search users on click of search button
  handleSearch() {
    if (!this.strSearchUserName) {
      this.strUserErrorMsg = 'Please enter User Name to search.';
      this.strSearchData = undefined;
      this.strStyleUser = 'margin-top: 34px;';
      return;
    }
    this.searchUsers();
  }

  // Search users dynamically as string is being entered
  handleDynamicSearch() {
    this.searchUsers();
  }

  
  searchUsers() {
    this.strUserErrorMsg = undefined;
    this.strStyleUser = 'margin-top: 20px;';
    retrieveUsers({ strUserName: this.strSearchUserName, strUserRole: this.strSearchRoleName })
      .then(result => {
        this.strUsers = result;
        this.intLastIndex = 0;
        this.lst_usersCopy.length = 0;
        for (let i = this.intLastIndex; i < (this.intLastIndex + this.intNumberOfRecords); i++) {
          if (i < this.strUsers.length) {
            this.lst_usersCopy.push(this.strUsers[i]);
          } else {
            break;
          }
        }
      })
      .catch(error => {
        const errorMessage = new ShowToastEvent({
          title: 'Error',
          message: error.body.message,
          variant: 'error'
        });
        this.dispatchEvent(errorMessage);
      })

  }

  // Method to capture the changed role value
  handleRoleInput(event) {
    this.strSearchRoleName = event.detail.value;
  }

  //Search roles on click of search button
  handleSearchRole() {
    if (!this.strSearchRoleName) {
      this.strRoleErrorMsg = 'Please enter User Role to search.';
      this.strSearchData = undefined;
      this.strStyleRole = 'margin-top: 34px;';
      return;
    }
    this.searchRoles();
  }

  // Search roles dynamically as string is being entered
  handleDynamicRoleSearch() {
    this.searchRoles();
  }

  searchRoles() {
    this.strRoleErrorMsg = undefined;
    this.strStyleRole = 'margin-top: 20px;';
    retrieveRoles({ strRoleName: this.strSearchRoleName, strUserName: this.strSearchUserName })
      .then(result => {
        this.strUsers = result;
        this.intLastIndex = 0;
        this.lst_usersCopy.length = 0;
        for (let i = this.intLastIndex; i < (this.intLastIndex + this.intNumberOfRecords); i++) {
          if (i < this.strUsers.length) {
            this.lst_usersCopy.push(this.strUsers[i]);
          } else {
            break;
          }
        }
      })
      .catch(error => {
        const errorMessage = new ShowToastEvent({
          title: 'Error',
          message: error.body.message,
          variant: 'error'
        });
        this.dispatchEvent(errorMessage);
      })
  }

  //Method to display the direct report users to the logged in user when direct report checkbox is checked
  handleDirectReports(event) {
    let isChecked = event.target.checked;
    if (isChecked) {
      this.strUsers = [];
      getDirectReportUsers({ strLoggedInUserId: Id })
        .then(result => {
          this.strUsers = result;
          this.intLastIndex = 0;
          this.lst_usersCopy.length = 0;
          for (let i = this.intLastIndex; i < (this.intLastIndex + this.intNumberOfRecords); i++) {
            if (i < this.strUsers.length) {
              this.lst_usersCopy.push(this.strUsers[i]);
            } else {
              break;
            }
          }
        })
        .catch(error => {
          console.log('error--' + error);
          const errorMessage = new ShowToastEvent({
            title: 'Error',
            message: error.body.message,
            variant: 'error'
          });
          this.dispatchEvent(errorMessage);
        })
    } else {
      getUserData()
        .then(result => {
          this.strUsers = result;
          this.intLastIndex = 0;
          this.lst_usersCopy.length = 0;
          for (let i = this.intLastIndex; i < (this.intLastIndex + this.intNumberOfRecords); i++) {
            if (i < this.strUsers.length) {
              this.lst_usersCopy.push(this.strUsers[i]);
            } else {
              break;
            }
          }
        })

    }
  }


  // Method to close all panels and modal and redirect to users list
  handleReset(event) {
    this.blnOpenModal = false;
    this.blnShowUpdateCancel = false;
    this.blnPanelShowHide = true;
    this.blnIsEditClicked = false;
    this.intLayoutSize = 12;
    
  }


  handleUpdate(event) {
    this.blnOpenModal = false;
    this.blnShowUpdateCancel = false;
    const eventMessage = new ShowToastEvent({
      title: 'Success',
      message: 'The records have been updated.',
      variant: 'success'
    });
    this.dispatchEvent(eventMessage);
    const inputFields = this.template.querySelectorAll(
      'lightning-input-field'
    );
    if (inputFields) {
      inputFields.forEach(field => {
        field.reset();
      });
    }
  }

  //To get the previous users on the number of records selected
  handlePrevious() {
    this.blnIsLoading = true;
    new Promise(
      (resolve, reject) => {
        setTimeout(() => {
          let difference = this.intLastIndex - this.intNumberOfRecords;
          if (difference >= 0) {
            this.intLastIndex -= this.intNumberOfRecords;
            this.lst_usersCopy.length = 0;
            for (let i = this.intLastIndex; i < this.intLastIndex + this.intNumberOfRecords; i++) {
              if (i < this.strUsers.length) {
                this.lst_usersCopy.push(this.strUsers[i]);
              } else {
                break;
              }
            }
          }
          resolve();
        }, 0);
      }).then(
        () => this.blnIsLoading = false
      );
    
  }


  closeModalForChange() {
    this.blnOpenModal = false;
  }

  //To get the previous users on the number of records selected
  handleNext() {
    
    this.blnIsLoading = true;
    new Promise(
      (resolve, reject) => {
        setTimeout(() => {
          let sum = this.intLastIndex + this.intNumberOfRecords;
          if (sum < this.strUsers.length) {
            this.intLastIndex += this.intNumberOfRecords;
            this.lst_usersCopy.length = 0;
            for (let i = this.intLastIndex; i < this.intLastIndex + this.intNumberOfRecords; i++) {
              if (i < this.strUsers.length) {
                this.lst_usersCopy.push(this.strUsers[i]);
              } else {
                break;
              }
            }
          }
          resolve();
        }, 0);
      }).then(
        () => this.blnIsLoading = false
      );
  }

  handleRowClick(event) {
    alert('which row was clicked ' + event.target.dataset.key);
  }
  
}