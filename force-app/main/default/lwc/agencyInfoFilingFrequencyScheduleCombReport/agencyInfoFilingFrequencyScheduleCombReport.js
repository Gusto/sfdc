import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FILING_FREQUENCY_SCHEDULE_OBJ from '@salesforce/schema/Filing_Frequency_Schedule__c';
import FILING_FREQUENCY_SCHEDULE_TYPE from '@salesforce/schema/Filing_Frequency_Schedule__c.Filing_Frequency_Schedule_Type__c';//picklist
import FILING_SCHEDULE_BEHAVIOR from '@salesforce/schema/Filing_Frequency_Schedule__c.Filing_Schedule_Behavior__c';
import FILING_DUE_DATE from '@salesforce/schema/Filing_Frequency_Schedule__c.Filing_Due_Date_Info_Link__c';
import FILING_APPLICABLE_FORMS from '@salesforce/schema/Filing_Frequency_Schedule__c.Filing_Applicable_Forms__c';
import AGENCY_INFO from '@salesforce/schema/Filing_Frequency_Schedule__c.Agency_Information__c';

import getChildFilingFrequencyScheduleRecType from '@salesforce/apex/AgencyInfo_ChildController.getChildFilingFrequencyScheduleRecType';//change
import upsertFilingFrequencyRecord from '@salesforce/apex/AgencyInfo_ChildController.upsertFilingFrequencyRecord';//change
import deleteChildRecord from '@salesforce/apex/AgencyInfo_ChildController.deleteChildRecord';
import getComplianceMetadata from '@salesforce/apex/AgencyInfo_ChildController.getComplianceMetadata';

import { getPicklistValues,getObjectInfo  } from 'lightning/uiObjectInfoApi';
import { refreshApex } from '@salesforce/apex';

export default class AgencyInfo_FilingFrequencySchedule_CombReport extends LightningElement {
    
    objFormName;
    
    @api recordId ;

    /*FILING_FREQUENCY_SCHEDULE_OBJ,  FILING_FREQUENCY_SCHEDULE_TYPE : PICK, 
    FILING_SCHEDULE_BEHAVIOR,
FILING_DUE_DATE, FILING_APPLICABLE_FORMS*/

    /*Object Fields Reference */
    filingFrequencySchduleType= FILING_FREQUENCY_SCHEDULE_TYPE;
    filingScheduleBehavior = FILING_SCHEDULE_BEHAVIOR ;
    filingDueDate = FILING_DUE_DATE;
    filingAppForms = FILING_APPLICABLE_FORMS;

    /*Filing_Frequency_Schedule_Type__c
    Filing_Frequency_Schedule_Type__c, Filing_Schedule_Behavior__c, Filing_Due_Date_Info_Link__c, Filing_Applicable_Forms__c */

    formNameObj = {
        Filing_Frequency_Schedule_Type__c :  this.filingFrequencySchduleType,
        Filing_Schedule_Behavior__c : this.filingScheduleBehavior,
        Filing_Due_Date_Info_Link__c : this.filingDueDate,
        Filing_Applicable_Forms__c : this.filingAppForms,
        Agency_Information__c : '$recordId',
        
    }
    formNameObjList=[];
    createdFormId;
    error;

    showFormNameTemplate = false;
    getFormNameObjList=[];

    /*Modal */
    isShowModal = false;
    showModalBox() {  
        this.isShowModal = true;
    }
    hideModalBox() {  
        this.isShowModal = false;
    }
        
    /*Fetch Picklist Values */
    recordTypeIdForPicklist="";
    picklistVals_filingFrequencySchduleType = [];

    defaultRecTypeId;
    /* GET OBJECT INFO */
    @wire (getObjectInfo, {objectApiName: FILING_FREQUENCY_SCHEDULE_OBJ})
    gettObjectInfo
    ({error,data})
    {if(data){
        this.defaultRecTypeId =data.defaultRecordTypeId;
    } else if(error){
        console.log(error);
    }}  

    /*Get Picklist Info */
    @wire(getPicklistValues, {
        recordTypeId: '$defaultRecTypeId' ,
        fieldApiName: FILING_FREQUENCY_SCHEDULE_TYPE,
    })
    getPicklistVals_mainFilingFormat({ data, error }) {
        this.picklistVals_filingFrequencySchduleType = undefined;
        if (error) {
        console.error('>>>error in picklist filingFrequencySchduleType ' +error);
        } else if (data) {
            this.picklistVals_filingFrequencySchduleType = [...data.values];
        }
    }

    getRandomArbitrary(min, max) {
        return Math.random() * (max - min) + min;
    }

    /*Getting metadata for showing the number of forms in the UI # hardcoding obj name*/ 
    counter;
    @wire(getComplianceMetadata, {strObjName: 'Filing_Frequency_Schedule__c'})
    complianceMetadata({error, data}){
        if(data){
            this.counter = data;
        }else if(error){
            console.error('error fetching complianceMetadata ...'+error);
        }        
    }

    childData;
    @wire(getChildFilingFrequencyScheduleRecType, {idAgencyInfoId: '$recordId', strRecType: 'Combined-Reporting', intCounter: '$counter'})
    wiredFormNames(result){
        this.childData = result;
        const {error, data} = result
    
        if(data){
            //#1set the list to blank
            this.updateFormNameObjList = [];
            this.checkBox_labelsList = [];
            this.chckBxLblToDeleteList = [];

            let tempData = [];
            data.forEach((element, index) => {
                tempData.push({
                    "areDetailsVisible":true,
                    "formLabel" : "Filing Frequency/Schedule #"+(Number.parseInt(index)+1),
                    "form" : element
                });
                
            });
            console.log('Fetched Record Count..'+data.length);
            /**Inserting Empty records in the List 
             * eg. if 1 record exists , it will enter metadata counter (5) - 1 = 4 new records
             * Give a ramdom number as Id, to differentiate between different forms being submited
             */
            for (let i = data.length+1; i <= this.counter; i++) {
                var randomNum = this.getRandomArbitrary(0, 9999);
                tempData.push({
                    "areDetailsVisible":false,
                    "formLabel" : "Filing Frequency/Schedule #"+i,
                    "form" : {Id:randomNum, newId :randomNum , Agency_Information__c : this.recordId}
                });
            }

            this.getFormNameObjList = tempData; //#generic name for the list
        }else if(error){
            console.error('error fetching records in getChildFormNameRecType...'+error);
        } 
    }
    
    curformObj;
    curformObjList=[];
    getFormNameObjCopyList=[]; 
    updateFormNameObjList=[];
     
    /**lightning-input  on change Handler */
    handleOnChange(event) {
        /**On the on change handler we are saving the changes made directly in the list:updateFormNameObjList to be proecssed */
		if (event.detail.value !== undefined) {

            let currentRecordId = event.currentTarget.dataset.id;
            let fieldApiName = event.currentTarget.dataset.api;
            let currentRecord = this.getFormNameObjList.find(element => element.form.Id == currentRecordId);

            //get the current checkbox
            var checkBoxInp = document.getElementsByClassName("checkBoxLabel");

            /* newId signifies that a record is new.
            * Check if the record exists in updateFormNameObjList list
            * If does nto exist, create an entry in the list 
            * Else update the record in the list*/
            if ('newId' in currentRecord.form){
                let recIdx = this.updateFormNameObjList.findIndex(item => item.newId === currentRecord.form.newId);
                console.log('recIdx..'+recIdx);
                if(recIdx==-1){
                    var newRec =currentRecord.form;
                    newRec[fieldApiName] = event.detail.value;
                    this.updateFormNameObjList.push(newRec);
                }else{
                    let newRecord = this.updateFormNameObjList.find(item => item.newId === currentRecord.form.newId);
                    newRecord[fieldApiName] = event.detail.value;
                }   
            }/* * If no newId, its a existing record in the DB */
            else{
                if(currentRecord) { /*updated record */
                    
                    var copyRec= JSON.parse(JSON.stringify(currentRecord.form));
                    copyRec[fieldApiName] = event.detail.value;
                    let index = this.updateFormNameObjList.findIndex(item => item.Id === currentRecordId);

                    if (index !== -1) {
                        let existingRecord = this.updateFormNameObjList.find(item => item.Id === currentRecord.form.Id);
                        existingRecord[fieldApiName] = event.detail.value;
                    }else{
                        this.updateFormNameObjList.push(copyRec);
                    }
                }
            }

            console.log('updateFormNameObjList to be updated in the DB...'+JSON.stringify(this.updateFormNameObjList));

		} else if (event.detail.checked !== this.objCase[event.target.dataset.api]) {
			this.formNameObj[event.target.dataset.api] = event.detail.checked;
		}
        
      }

      executeDelete=false;

      /**Called from the Modal-Submit */
      handleSubmitButton(event){
        console.log('inside handleSubmitButton...');
        
            /*Delete the newId from updateFormNameObjList; 
            * they are identifying the record in the component from one another*/
            this.updateFormNameObjList.forEach(item => {
                if ('newId' in item){
                    console.log('newId in item');
                    delete item.newId;
                    delete item.Id;
                }
            })

            /*Delete the unchecked records which have a recordId*/
            if(this.chckBxLblToDeleteList.length > 0){
                 //#2refreshApex update
                 this.isShowModal = false;
                deleteChildRecord({list_ToDelete: this.chckBxLblToDeleteList, strObjName: 'Filing_Frequency_Schedule__c'})
                .then(result => {
                    //#3 refreshApex
                    refreshApex(this.childData);
                    console.log('deleted records:'+JSON.stringify(result));
                    const evt = new ShowToastEvent({
                        title: 'Deposit Frequency',
                        message: 'Records Deleted',
                        variant: 'success',
                    });
                    this.dispatchEvent(evt);

                })
                .catch(error => {
                    console.log('error while deleting records:'+JSON.stringify(error));
                })
            }

             /* #4Upsert the records submitted by the user, if updateFormNameObjList has data*/
             if(this.updateFormNameObjList.length > 0){
                upsertFilingFrequencyRecord({list_FileFreqSch: this.updateFormNameObjList, strRecType: 'Combined-Reporting', strObjName: 'Filing_Frequency_Schedule__c'})
                .then(result => {
                    this.createdFormId = result;
                    this.error = undefined;

                    const evt = new ShowToastEvent({
                        title: 'Form Name created',
                        message: 'Records upserted',
                        variant: 'success',
                    });
                    this.dispatchEvent(evt);
                    //location.reload();
                    refreshApex(this.childData);
                })
                .catch(error => {
                    console.log('error:'+JSON.stringify(error));
                    this.createdFormId = undefined;
                    this.error = error;
                })
            }
      }

      /*On the Submit of the LWC Component : 
       * check if the user has unselected already selected record -> those entries should be deleted ->
      * Prompt user with a Modal and take his confirmation*/
      handleFormSubmit(event){
        if(this.chckBxLblToDeleteList.length > 0){
            this.checkBox_labelsList_Str = "Filing Frequency/Schedule "+this.checkBox_labelsList.join(" ,");
            this.isShowModal = true;
        }else{
            console.log('calling handleSubmitButton ..');
            this.handleSubmitButton();
        }
      }
      
      chckBxLblToDeleteList=[];
      reloadForm = true;
      checkBox_labelsList=[];
      checkBox_labelsList_Str;

      /**Checkbox handler */
      handleInputCheckBoxChange(event){
            console.log("inside input checkbox handler..");

            let formLabel = event.currentTarget.dataset.api;//formNmeObj.formLabel
            let formId = event.currentTarget.dataset.id;//formNmeObj.form.Id

            let checkedVal = event.target.checked;
            this.reloadForm = false;
            this.reloadForm = true;            
            /*
            *find the entry in the list: getFormNameObjList by the form label, update areDetailsVisible to show/hide the form 
            */
            let currentRecord = this.getFormNameObjList.find(element => element.formLabel == formLabel);
            if(checkedVal){
                currentRecord.areDetailsVisible = checkedVal;
            }else{
                currentRecord.areDetailsVisible = checkedVal;
            }
            /*List: chckBxLblStatusObj stores the checkboxLabel and checked status: only for the form which has a recordId */
            /**
             * chckBxLblToDeleteList stores the user unchecked checkboxes
             * these needs to be deleted from the DB on Submit
             */
            if(formId!== undefined ){ 
                let chckBxIdx = this.chckBxLblToDeleteList.findIndex(itemId => itemId === formId);
                console.log('chckBxIdx..'+chckBxIdx);

                if(!checkedVal && chckBxIdx=== -1){/*if user unchecks and its not added in the TO be deleted List */
                    /*add the form label counter to checkBox_labels: to show in the modal popup*/
                    this.checkBox_labelsList.push(formLabel.substring(formLabel.length-2));
                    
                    this.chckBxLblToDeleteList.push(formId);
                }else if(checkedVal && chckBxIdx!==-1){ /*if user checks and we added that in the TO be deleted List */
                    this.checkBox_labelsList = this.checkBox_labelsList.filter(item => item!==formLabel.substring(formLabel.length-2));
                    
                    this.chckBxLblToDeleteList.splice(chckBxIdx, 1);
                }  
            }

      }
}