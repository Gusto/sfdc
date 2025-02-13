import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import {CurrentPageReference} from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import getUserInformation from '@salesforce/apex/LWC_ContactUserInformationController.getUserInformation';
import gustoUrlPrefix from '@salesforce/label/c.gusto_url_prefix';
import updateAccount from '@salesforce/apex/LWC_ContactUserInformationController.updateAccount';
import updateContact from '@salesforce/apex/LWC_ContactUserInformationController.updateContactOnSave';
import queryCase from '@salesforce/apex/LWC_ContactUserInformationController.queryCase';

 
export default class ContactUserInfoPopover extends LightningElement {
    @api caseRecordId;
    @track showSpinner = false;
    @track UserInformationfirmInfoHasValue = false;
    @track UserInformationFirmUserRoleMap;
    @track UserInformationcompanyInfoHasValue = false;
    @track UserInformationcompanyUserRoleMap = [];
    @track strViewCompanyInPandaUrl = gustoUrlPrefix + '/panda/accountants/';
    @track showHide = false;
    @track left= 50;
    @track top= 50;
    @track Testing;
    boolShowPopover;
    boolViewContact = true;
    strWorkingRecordId;
    @track strContactName;
    strContactId;
    strPandaEE;
    strPandaURL;
    boolObjSupported = true;
    
    get boxClass() { 
        return `background-color:white; top:${this.top - 280}px; left:${this.left}px`;
    }

    connectedCallback() {
        this.showSpinner=true; 
        this.strWorkingRecordId = this.caseRecordId;
        if(this.caseRecordId.startsWith('570')) {
            this.boolObjSupported = false;
        }
        queryCase({
            strId: this.caseRecordId
        })
        .then(result => {
            if (result) {
                this.strWorkingRecordId = result.CaseRec.Id;
                this.strContactId = result.CaseRec.ContactId;
                //this.strContactName =  data.fields.Contact.Name;
                //this.strOrigContactId = result.CaseRec.ContactId;
                this.strPandaEE = result.CaseRec.Contact_Employee_Id__c;
                this.strPandaURL = result.CaseRec.Panda_Company_URL__c;
                this.strContactName = result.CaseRec.Contact.Name;
                this.strContactEmail = result.CaseRec.Contact.Email;
                if(!this.strContactId) {
                    this.boolViewContact = false;
                }                
            }
            return getUserInformation({caseId: this.caseRecordId});
        })        
        .then(result=>{
            console.log('i am here in then'+ JSON.stringify(result));
            if(result.firmInfo !== null && result.firmInfo !== undefined && result.firmInfo.length !== 0) {
                this.UserInformationfirmInfoHasValue = true;
                console.log('i am here in firmInfo'+ JSON.stringify(result));
                //this.UserInformationFirmUserRoleMap = result.firmUserRoleMap;
                if(result.firmUserRoleMap) {
                    console.log('wqe');
                    for(let key in result.firmUserRoleMap) {
                        // Preventing unexcepted data
                        console.log('xvsd');
                        if (result.firmUserRoleMap.hasOwnProperty(key)) { // Filtering the data in the loop
                            this.UserInformationFirmUserRoleMap.push({value:result.firmUserRoleMap[key], key:key, uniqueHoverId: false});
                        }
                    }
                }
            } else {
                this.UserInformationfirmInfoHasValue = false;
            }
            if(result.companyInfo !== null && result.companyInfo !== undefined && result.companyInfo.length !== 0) {
                this.UserInformationcompanyInfoHasValue = true;
                console.log('i am here in companyInfo1'+ JSON.stringify(result));
                //this.UserInformationcompanyUserRoleMap = result.companyUserRoleMap;
                console.log('i am here in companyInfo2'+ JSON.stringify(result.companyUserRoleMap));
                if(result.companyUserRoleMap) {
                    console.log('wqe');
                    for(let key in result.companyUserRoleMap) {
                        // Preventing unexcepted data
                        console.log('xvsd');
                        if (result.companyUserRoleMap.hasOwnProperty(key)) { // Filtering the data in the loop
                            this.UserInformationcompanyUserRoleMap = [...this.UserInformationcompanyUserRoleMap, {value:result.companyUserRoleMap[key], key:key, uniqueHoverId: false}];
                        }
                    }
                }
                console.log('i am here in companyInfo3'+ JSON.stringify(this.UserInformationcompanyUserRoleMap));
            } else {
                this.UserInformationcompanyInfoHasValue = false;
            }
            this.showSpinner=false; 
        })
        .catch(error=>{
            console.log('i am here in catch' + error);
            this.showSpinner=false; 
        });
    }

    handleOpenCompany(event) {
        const companyId = event.target.value;
        console.log('companyId>>>'+companyId);
        this.strViewCompanyInPandaUrl = this.strViewCompanyInPandaUrl + companyId;
        console.log('this.strViewCompanyInPandaUrl>>>'+this.strViewCompanyInPandaUrl);      
        event.preventDefault();
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: this.strViewCompanyInPandaUrl
            },
        });  
    }
    handleUpdate(event) {
        console.log('in updateAccount::'+event.target.label);
        this.showSpinner = true;
        let isRerouteValue;
        let company_FirmIdValue = event.target.value;
        if(event.target.value !== undefined && event.target.label ==='Update Account' ){
            isRerouteValue = false;
        } else {
            isRerouteValue = true;
        }
        updateAccount({isReroute: isRerouteValue, caseId: this.caseRecordId, company_FirmId: company_FirmIdValue})
        .then(result=>{
            console.log('result>>' + JSON.stringify(result));
            
            const closeclickedevt = new CustomEvent('UpdateRecord', {
                detail: {},
            });
            // Fire the custom event
            this.dispatchEvent(closeclickedevt);
            this.showSpinner = false;
            this.showToast('Success !','Update Successfull','success');
        })
        .catch(error=>{
            console.log('result>>' + JSON.stringify(error));
            this.showSpinner = false;
            this.showToast('Error !', 'Please contact the system admin' ,'Error');
        });
    }
    showToast(title,message,variantType) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variantType,
        });
        this.dispatchEvent(event);
    }
    showData(event){
        console.log('inshow>>>');
        console.log('event.currentTarget.dataset.conciergeGroupId>>'+event.currentTarget.dataset.conciergeGroupId);
        console.log('event.currentTarget.dataset.tier>>'+event.currentTarget.dataset.tier);
        console.log('event.currentTarget.dataset.permissionstr>>'+event.currentTarget.dataset.permissionstr);
        //this.Testing = 'testing';
        console.log('event.currentTarget.dataset.zpcompanyid>>'+event.currentTarget.dataset.zpcompanyid);
        let tempArrr = [];
        let uniqueId = event.currentTarget.dataset.zpcompanyid;
        this.UserInformationcompanyUserRoleMap.forEach(eachRecord => {
            console.log(uniqueId+ 'eachRecord.eachRecord.value.zpcompanyid>>>'+eachRecord.value.zpCompanyId);
            if(eachRecord.value.zpCompanyId === uniqueId) {
                eachRecord.uniqueHoverId = true;
                console.log('eachRecord.uniqueHoverId>>>'+eachRecord.uniqueHoverId);
            } 
            tempArrr = [...tempArrr,eachRecord];
        });
        this.UserInformationcompanyUserRoleMap = [];
        this.UserInformationcompanyUserRoleMap = Array.from(tempArrr);
        console.log('eachRecord.this.UserInformationcompanyUserRoleMap>>>'+JSON.stringify(this.UserInformationcompanyUserRoleMap));
        
    }
    hideData(event){
        console.log('inhide>>>');
        console.log('event.currentTarget.dataset.rangerid>>'+event.currentTarget.dataset.rangerid);
        console.log('event.currentTarget.dataset.tier>>'+event.currentTarget.dataset.tier);
        console.log('event.currentTarget.dataset.permissionstr>>'+event.currentTarget.dataset.permissionstr);
        console.log('event.currentTarget.dataset.permissionstr>>'+event.currentTarget.dataset.zpcompanyid);
        let tempArrr = [];
        this.UserInformationcompanyUserRoleMap.forEach(eachRecord => {
                eachRecord.uniqueHoverId = false;
            tempArrr = [...tempArrr,eachRecord];
        });
        this.UserInformationcompanyUserRoleMap = [];
        this.UserInformationcompanyUserRoleMap = Array.from(tempArrr);
        console.log('eachRecord.this.UserInformationcompanyUserRoleMap>in hide>>'+JSON.stringify(this.UserInformationcompanyUserRoleMap));
    }

    togglePopover() {
        this.boolShowPopover = !this.boolShowPopover;
    }

    toggleViewContact() {
        this.boolViewContact = !this.boolViewContact;
    }

}