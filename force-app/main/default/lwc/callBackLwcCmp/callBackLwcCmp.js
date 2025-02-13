import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import submitCallBack from '@salesforce/apex/LWC_SubmitCallBackController.submitCallBack';
import callBackLoad from '@salesforce/apex/LWC_SubmitCallBackController.callBackLoad';

import {  sendAuraEvent } from 'c/utilityService';

export default class CallBackLwcCmp extends LightningElement {

    /** Declaring variables */

    /* Record Id fetched from Page */
    @api recordId;
    // it handles the display of the Call back form.
    @track blnIsSuccess = false;
    @track error;
    /* Flag to show spinner component - If set to true, will show spinner on the UI */
    @track blnShowSpinner = false;
    /** To hold the phone value */
    @track strPhone = '';
    /** To hold the Name value */
    @track strName = '';
    /** To hold the Requested date value */
    @track dtRequestedDate;
    /** To hold the checkbox call back value from UI */
    @track blnUserCallBack = true;
    /** capture the phone number from database */
    @track strWebPhone;
    /** capture the queue values from database */
    queueMap;
    @track strQueueOption;
    @track strQueueId;
    @track objcs;
    @track strLoggedInUserName;
    @track strLoggedInUserSkillId;
    @track objTempCase;
    blnEnableRoute = false;
    blnDisableButton = true;
    connectedCallback(){
        this.blnShowSpinner=true; 

        /** This method provide all the user related information */
        callBackLoad({idCase: this.recordId})
        .then(result=>{
            if(result) {
                if(result.setAttributes) {
                    if(result.setAttributes.Phone) {
                        let strLintedPhone = result.setAttributes.Phone.replace(/[`~!@#$%^&*()_|+\-=?;:'",.<>\{\}\[\]\\\/]/gi, '');
                        this.strPhone = strLintedPhone;
                    }
                    
                    if(result.setAttributes.name) 
                        this.strName = result.setAttributes.name;
                    
                    if(result.setAttributes.cs) {
                        this.objcs = result.setAttributes.cs;
                        if(result.setAttributes.cs.Origin === 'Chat' || (result.setAttributes.cs.Origin === 'Gusto' && result.setAttributes.cs.Channel__c === 'Chat') || result.setAttributes.cs.Origin === 'Gusto') {
                            this.blnEnableRoute = true;
                        }
                        if(result.setAttributes.cs.SuppliedPhone) {
                            this.strWebPhone = result.setAttributes.cs.SuppliedPhone;
                        }
                    }   

                    if(result.setAttributes.isSuccess) {
                        this.blnIsSuccess = true;
                        this.blnShowSpinner = false;
                        this.showToast('Info !','Callback has already been successfully scheduled','info');
                    } else {
                        this.blnIsSuccess = false;
                    }
                }
                if(result.firstMethod) {
                    this.dtRequestedDate = result.firstMethod.tempCase.Auto_Close_Date_Time__c;
                    this.blnUserCallBack = result.firstMethod.bool_UserCallBack;
                    this.objTempCase = result.firstMethod.tempCase;
                    this.strLoggedInUserName = result.firstMethod.strLoggedInUserName;
                    this.strLoggedInUserSkillId = result.firstMethod.strLoggedInUserSkillId;
                }
                this.strQueueOption = [{ label: '--None--', value: ''}];
                if(result.getQueueList) {
                    this.queueMap = result.getQueueList.queueMap;                    
                    if(this.queueMap) {
                        for (let singlekey in this.queueMap) {
                            //console.log('!! singlekey ' + singlekey + this.queueMap[singlekey] );
                            this.strQueueOption.push({ label: singlekey, value: this.queueMap[singlekey]});
                        } 
                    }
                }
                this.blnShowSpinner = false;
            } else {
                this.error=error;
                this.blnShowSpinner = false;
                this.showToast('Error !',JSON.stringify(this.error),'error');
            }
        })
        .catch(error=>{
            let showToastMessage='';
            this.error=error;
            this.blnShowSpinner = false;
            this.showToast('Error !',JSON.stringify(this.error),'error');
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
    /** captures the changed phone value */
    handlePhoneChange(event) {
        this.strPhone = event.target.value;
        this.objcs.SuppliedPhone = this.strPhone;
    }
    handleKeyPress(event) {
        const strAllowedChars = /[0-9\/]+/;
        if (!strAllowedChars.test(event.key)) {
            event.preventDefault();
        }
    }
    /** captures the changed name value */
    handleNameChange(event) {
        this.strName = event.target.value;
    }
    /** captures the changed requested date value */
    handleRequestedDateChange(event) {
        this.dtRequestedDate = event.target.value;
        this.objTempCase.Auto_Close_Date_Time__c = this.dtRequestedDate;
    }
    /** captures the changed checkbox value */
    handleCheckboxChange(event) {
        this.blnUserCallBack = event.target.checked;
    }
    /** captures the changed queue value */
    handleQueueChange(event) {
        this.strQueueId = event.target.value;
        if(this.strQueueId !== '') {
            this.blnDisableButton = false;
        }
        else this.blnDisableButton = true;
    }

    /** call the method of the apex to perform the DML operation and Integration */
    handleSubmit(){
        if(this.strPhone.length < 10 || !this.strPhone || this.strPhone === '' ) {
            this.showToast('Error', 'Phone number is invalid. Please enter a valid 10 digit phone number', 'error');
        }
        else if(!this.strName || this.strName === ''){
            this.showToast('Error', 'Name is required.', 'error');
        }
        else {
            var strLintedPhone = this.strPhone.replace(/[`~!@#$%^&*()_|+\-=?;:'",.<>\{\}\[\]\\\/]/gi, '');
            this.blnShowSpinner=true; 
            submitCallBack({idQueue: this.strQueueId,
                            strPhone: strLintedPhone,
                            strName: this.strName,
                            strLoggedInUserName : this.strLoggedInUserName,
                            ObjtempCase: this.objTempCase,
                            objCase: this.objcs,
                            blnUserCallBack: this.blnUserCallBack, 
                            strLoggedInUserSkillId: this.strLoggedInUserSkillId})
            
            //submit response: {"Status":"Success","WaitTimeMin":10,"WaitTimeMax":20}
    
            .then(result=>{
                var objResponse = JSON.parse(result.response.toString());
                if(objResponse.Status === 'Success') {
                    this.blnIsSuccess = true;
                    this.blnShowSpinner=false; 
                    this.showToast('Success!',JSON.stringify(result.msg),'success');
                    sendAuraEvent(this, '' , 'closetab');
                } else {
                    console.log('error response: ', result);
                    this.blnIsSuccess = false;
                    this.blnShowSpinner=false; 
                    this.showToast('Error !',JSON.stringify(result.msg),'error');
                }            
            })
            .catch(error=>{
                console.log('catch response: ', error);
                this.error=error;
                this.blnShowSpinner = false;
                this.showToast('Error !',JSON.stringify(this.error),'error');
            })
        }

    }
}