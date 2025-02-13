/*
    Common component used on order and order products layouts.
    Used to show related order products to a order and perform actions on selected product records.
*/
import { LightningElement, wire, api, track } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import USER_ID from '@salesforce/user/Id';
import RESULTS_ENTERED_FIELD from '@salesforce/schema/OrderItem.Results_Entered__c';
import RESULTS_ENTERED_BY_FIELD from '@salesforce/schema/OrderItem.Results_Entered_By__c';
import RESULTS_ENTERED_DATE_FIELD from '@salesforce/schema/OrderItem.Results_Entered_Date__c';
import FIRST_PASS_QA_COMPLETED_FIELD from '@salesforce/schema/OrderItem.First_Pass_QA_Completed__c';
import FIRST_PASS_QA_COMPLETED_BY_FIELD from '@salesforce/schema/OrderItem.First_Pass_QA_Completed_By__c';
import FIRST_PASS_QA_COMPLETED_DATE_FIELD from '@salesforce/schema/OrderItem.First_Pass_QA_Completed_Date__c';
import SECOND_PASS_QA_COMPLETED_FIELD from '@salesforce/schema/OrderItem.Second_Pass_QA_Completed__c';
import SECOND_PASS_QA_COMPLETED_BY_FIELD from '@salesforce/schema/OrderItem.Second_Pass_QA_Completed_By__c';
import SECOND_PASS_QA_COMPLETED_DATE_FIELD from '@salesforce/schema/OrderItem.Second_Pass_QA_Completed_Date__c';
import ID_FIELD from '@salesforce/schema/OrderItem.Id';
import ORDER_ID_FIELD from '@salesforce/schema/OrderItem.OrderId';

const ARRAY_COLUMNS = [  
    { label: 'Product Name', fieldName: 'OrderUrl', hideDefaultActions: true, initialWidth: 132, 
      type: 'url', typeAttributes: {label: { fieldName: 'Name' }, target: '_self'}},
    { label: 'Product Code', fieldName: 'ProductCode', hideDefaultActions: true, initialWidth: 127, },
    { label: 'Results Entered', fieldName: 'ResultsEntered', type:'boolean'},
    { label: 'QA First Pass', fieldName: 'FirstPass', type:'boolean'},
    { label: 'QA Second Pass', fieldName: 'SecondPass', type:'boolean'}
];

export default class OrderProductAction extends LightningElement {

    array_columns = ARRAY_COLUMNS;
    strError;
    @track arrayRecords = [];
    blnOrderProductsFetched = false;
    blnHideCheckbox = false;
    idRecordId = null;
    idOrderProductId = null;
    selectedRows = null;
    strCardTitle = 'Order Products';
    objProductsWire;
    @api recordId;
    @api objectApiName;
    get datatableHeight(){
        if (this.arrayRecords.length > 6){
            return 'height:200px;'
        }
        return '';
    }

    //initialize component acording to source record
    connectedCallback(){
        if (this.recordId && this.objectApiName){
            if (this.objectApiName == 'Order'){
                this.idRecordId = this.recordId;
            }
            else if (this.objectApiName == 'OrderItem'){
                this.idOrderProductId = this.recordId;
                for (let column of this.array_columns){
                    if (column.type!=null && column.type == 'button'){
                        if (column.typeAttributes.name == 'Complete Results'){
                            //column.initialWidth = 150;
                        }
                        if (column.typeAttributes.name == 'QA First Pass'){
                            //column.initialWidth = 124;
                        }
                        if (column.typeAttributes.name == 'QA Second Pass'){
                            //column.initialWidth = 142;
                        }
                    }
                }
            }
        }
    }

    //get related order data using ui api
    @wire(getRecord, { recordId: '$idOrderProductId', fields: [ORDER_ID_FIELD] })
    orderProductInfo({ error, data}){
        if (data){
            this.idRecordId = data.fields.OrderId.value;
        }
        else if (error) {
            this.strError = error;
            this.arrayRecords = undefined;
            console.log('error',this.strError);
        }
    }

    //get related order products to order using ui api 
    @wire(getRelatedListRecords, {
        parentRecordId: '$idRecordId',
        relatedListId: 'OrderItems',
        fields: ['OrderItem.Id','OrderItem.Quantity','OrderItem.Product2.Name','OrderItem.Product2.ProductCode',
                'OrderItem.Results_Entered__c','OrderItem.First_Pass_QA_Completed__c','OrderItem.Second_Pass_QA_Completed__c']
    })listInfo(value) {
        this.objProductsWire = value;
        const { error, data } = value;
        if (data) {
            this.strCardTitle = 'Order Products (' + data.records.length + ')';
            this.strError = undefined;
            //for each related record fetched form wrapper for display in data table
            for (let record of data.records)
            {
                let orderItem = {
                    Id : record.id,
                    OrderUrl : '/'+record.id,
                    Name : record.fields.Product2.value.fields.Name.value,
                    ProductCode : record.fields.Product2.value.fields.ProductCode.value,
                    ResultsEntered: record.fields.Results_Entered__c.value,
                    FirstPass: record.fields.First_Pass_QA_Completed__c.value,
                    SecondPass: record.fields.Second_Pass_QA_Completed__c.value
                }
                //If data fetched for first time create new data array, else update data array if data has updates
                if(!this.blnOrderProductsFetched)
                {
                    this.arrayRecords = this.arrayRecords.concat([orderItem]);
                }
                else{
                    let arrayRecordsDraft = [];
                    for (let arrayRecord of this.arrayRecords){
                        if (arrayRecord.Id == record.id){
                            arrayRecord.ResultsEntered = record.fields.Results_Entered__c.value;
                            arrayRecord.FirstPass = record.fields.First_Pass_QA_Completed__c.value;
                            arrayRecord.SecondPass = record.fields.Second_Pass_QA_Completed__c.value;
                        }
                        arrayRecordsDraft = arrayRecordsDraft.concat(arrayRecord);
                    }
                    this.arrayRecords = arrayRecordsDraft;
                }
            }
            this.selectedRows = [this.idOrderProductId];
            this.blnOrderProductsFetched = true;
        } else if (error) {
            this.strError = error;
            this.arrayRecords = undefined;
            console.log('error',this.strError);
        }
    }
    
    //Method to handle selection of multiple order products
    handleRowSelection(event){
        let selectedRows = event.detail.selectedRows;
        if (selectedRows.length){
            this.selectedRows = [];
            for (let row of selectedRows){
                this.selectedRows = this.selectedRows.concat([row.Id]);
            }
        }
        else {
            this.selectedRows = [];
        }
    }

    //Common method to handle action button click
    async handleAction(event){
        const action = event.target.label;
        let records = null;
        let newDate = new Date();
        let today = String(newDate.getFullYear()) + '-' + String(newDate.getMonth() + 1).padStart(2, '0')+'-'+String(newDate.getDate()).padStart(2, '0');
        if (this.selectedRows.length){
            //Form update record objects for each order product record selected based on button clicked.
            //Populate respective fields against action type of button
            if (action == 'Complete Results'){
                records = this.selectedRows.map(item =>{
                    const fields = {};
                    fields[ID_FIELD.fieldApiName] = item;
                    fields[RESULTS_ENTERED_FIELD.fieldApiName] = true;
                    fields[RESULTS_ENTERED_BY_FIELD.fieldApiName] = USER_ID;
                    fields[RESULTS_ENTERED_DATE_FIELD.fieldApiName] = today;
                    return { fields };
                });
            }
            if (action == 'QA First Pass'){
                records = this.selectedRows.map(item =>{
                    const fields = {};
                    fields[ID_FIELD.fieldApiName] = item;
                    fields[FIRST_PASS_QA_COMPLETED_FIELD.fieldApiName] = true;
                    fields[FIRST_PASS_QA_COMPLETED_BY_FIELD.fieldApiName] = USER_ID;
                    fields[FIRST_PASS_QA_COMPLETED_DATE_FIELD.fieldApiName] = today;
                    return { fields };
                });
            }
            if (action == 'QA Second Pass'){
                records = this.selectedRows.map(item =>{
                    const fields = {};
                    fields[ID_FIELD.fieldApiName] = item;
                    fields[SECOND_PASS_QA_COMPLETED_FIELD.fieldApiName] = true;
                    fields[SECOND_PASS_QA_COMPLETED_BY_FIELD.fieldApiName] = USER_ID;
                    fields[SECOND_PASS_QA_COMPLETED_DATE_FIELD.fieldApiName] = today;
                    return { fields };
                });
            }
        }
        //Perform all updates together using UI API.
        try {
            const recordUpdates = records.map((record) =>
                updateRecord(record)
            );
            await Promise.all(recordUpdates);

            //Show success/error toast message based on server response.
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Order Product updated',
                    variant: 'success'
                })
            );

            // Refresh data
            await refreshApex(this.objProductsWire);
        } catch (error) {
            this.strError = error;
            console.log('error',error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error updating records',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        }
    }

}