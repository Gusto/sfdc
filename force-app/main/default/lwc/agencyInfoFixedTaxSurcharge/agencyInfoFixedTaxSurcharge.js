import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FIXED_TAX_SUCHARGE_OBJ from '@salesforce/schema/Fixed_Tax_Surcharge__c';
import IS_SURCHARGE_FUTA_RECERT from '@salesforce/schema/Fixed_Tax_Surcharge__c.Is_Surcharge_FUTA_Recertifiable__c';//picklist
import FIXED_TAX_SURCH_NAME from '@salesforce/schema/Fixed_Tax_Surcharge__c.Fixed_Tax_Surcharge_Name__c';
import FIXED_TAX_SURCH_RATE from '@salesforce/schema/Fixed_Tax_Surcharge__c.Fixed_Tax_Surcharge_Rate__c';
import FIXED_TAX_SURCH_NOTES from '@salesforce/schema/Fixed_Tax_Surcharge__c.Fixed_Tax_Surcharge_Notes__c'; 
import APPLIES_TO_ALL_EMP from '@salesforce/schema/Fixed_Tax_Surcharge__c.Applies_To_All_Employers__c'; 
import EFFECTIVE_DATE from '@salesforce/schema/Fixed_Tax_Surcharge__c.Effective_Date__c';
import AGENCY_INFO from '@salesforce/schema/Fixed_Tax_Surcharge__c.Agency_Information__c';

import getChildFixedTaxSurcharge from '@salesforce/apex/AgencyInfo_ChildController.getChildFixedTaxSurcharge';//change
import upsertFixedTaxSurRecord from '@salesforce/apex/AgencyInfo_ChildController.upsertFixedTaxSurRecord';//change
import deleteChildRecord from '@salesforce/apex/AgencyInfo_ChildController.deleteChildRecord';
import getComplianceMetadata from '@salesforce/apex/AgencyInfo_ChildController.getComplianceMetadata';

import { getPicklistValues,getObjectInfo  } from 'lightning/uiObjectInfoApi';
import { refreshApex } from '@salesforce/apex';

export default class AgencyInfo_FixedTaxSurcharge extends LightningElement {
    
    objFormName;
    
    @api recordId ;

    isSurchargeFUTARecert = IS_SURCHARGE_FUTA_RECERT;
    fixedTaxSurchName = FIXED_TAX_SURCH_NAME;
    fixedTaxSurchRate = FIXED_TAX_SURCH_RATE ;
    fixedTaxSurchNotes = FIXED_TAX_SURCH_NOTES;
    appliesToAllEmp = APPLIES_TO_ALL_EMP;
    effectiveDate = EFFECTIVE_DATE;

    formNameObj = {
        Is_Surcharge_FUTA_Recertifiable__c :  this.isSurchargeFUTARecert,
        Fixed_Tax_Surcharge_Name__c : this.fixedTaxSurchName,
        Fixed_Tax_Surcharge_Rate__c : this.fixedTaxSurchRate,
        Fixed_Tax_Surcharge_Notes__c : this.fixedTaxSurchNotes,
        Applies_To_All_Employers__c : this.appliesToAllEmp,
        Effective_Date__c : this.effectiveDate,
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
    picklistVals_isSurchargeFUTARecert = [];

    defaultRecTypeId;
    /* GET OBJECT INFO */
    @wire (getObjectInfo, {objectApiName: FIXED_TAX_SUCHARGE_OBJ})//api name
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
        fieldApiName: IS_SURCHARGE_FUTA_RECERT,
    })
    getPicklistVals_isSurchargeFUTARecert({ data, error }) {
        this.picklistVals_isSurchargeFUTARecert = undefined;
        if (error) {
        console.error('>>>error in picklist isSurchargeFUTARecert ' +error);
        } else if (data) {
            this.picklistVals_isSurchargeFUTARecert = [...data.values];
        }
    }


    getRandomArbitrary(min, max) {
        return Math.random() * (max - min) + min;
    }

    /*Getting metadata for showing the number of forms in the UI # hardcoding obj name*/ 
    counter;
    @wire(getComplianceMetadata, {strObjName: 'Fixed_Tax_Surcharge__c'})
    complianceMetadata({error, data}){
        if(data){
            this.counter = data;
        }else if(error){
            console.error('error fetching complianceMetadata ...'+error);
        }        
    }

    childData;
    @wire(getChildFixedTaxSurcharge, {idAgencyInfoId: '$recordId',  intCounter: '$counter'})
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
                    "formLabel" : "Fixed Tax Surchange #"+(Number.parseInt(index)+1),
                    "form" : element
                });
                
            });
            /**Inserting Empty records in the List 
             * eg. if 1 record exists , it will enter metadata counter (5) - 1 = 4 new records
             * Give a ramdom number as Id, to differentiate between different forms being submited
             */
            for (let i = data.length+1; i <= this.counter; i++) {
                var randomNum = this.getRandomArbitrary(0, 9999);
                tempData.push({
                    "areDetailsVisible":false,
                    "formLabel" : "Fixed Tax Surchange #"+i,
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
                    delete item.newId;
                    delete item.Id;
                }
            })

            /*Delete the unchecked records which have a recordId*/
            if(this.chckBxLblToDeleteList.length > 0){
                //#2refreshApex update
                this.isShowModal = false;
                deleteChildRecord({list_ToDelete: this.chckBxLblToDeleteList, strObjName: 'Fixed_Tax_Surcharge__c'})
                .then(result => {
                     //#3 refreshApex
                     refreshApex(this.childData);
                     console.log('deleted records:'+JSON.stringify(result));
                     const evt = new ShowToastEvent({
                         title: 'Fixed Tax Surcharge',
                         message: 'Records Deleted',
                         variant: 'success',
                     });
                     this.dispatchEvent(evt);

                })
                .catch(error => {
                    console.log('error while deleting records:'+JSON.stringify(error));
                })
            }

            //console.log('updateFormNameObjList...'+JSON.stringify(this.updateFormNameObjList));
            /* #4Upsert the records submitted by the user, if updateFormNameObjList has data*/
            if(this.updateFormNameObjList.length > 0){
                upsertFixedTaxSurRecord({list_FixedTaxSur: this.updateFormNameObjList})
                .then(result => {
                    this.createdFormId = result;
                    this.error = undefined;

                    const evt = new ShowToastEvent({
                        title: 'Fixed Tax Surcharge',
                        message: 'Records upserted',
                        variant: 'success',
                    });
                    this.dispatchEvent(evt);
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
            this.checkBox_labelsList_Str = "Fixed Tax Surcharge "+this.checkBox_labelsList.join(" ,");
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