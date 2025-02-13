import { LightningElement, api,track } from 'lwc';

import getUserInformation from '@salesforce/apex/LWC_AccountUserInformationController.getUserInformation';
import queryCase from '@salesforce/apex/LWC_AccountUserInformationController.queryCase';
import updateContact from '@salesforce/apex/LWC_ContactUserInformationController.updateContactOnSave';

import { displayToast } from 'c/utilityService';

export default class CaseAccountHeaderPopover extends LightningElement {
    static delegatesFocus = true;
    @api caseRecordId;
    @track showSpinner = false;
    @track UserInformationfirmInfoHasValue = false;
    @track UserInformationFirmUserRoleMap = [];
    @track UserInformationcompanyInfoHasValue = false;
    @track UserInformationcompanyUserRoleMap = [];
    strWorkingRecordId;
    boolObjSupported = true;

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
                this.strContactEmail = result.CaseRec.Contact.Email;
                this.strAccountName = result.CaseRec.Account.Name;
                this.strAccountId = result.CaseRec.AccountId;             
            }
            return getUserInformation({idCase: this.caseRecordId});
        })        
        .then(result=>{
            if(result.list_FirmInfo !== null && result.list_FirmInfo !== undefined && result.list_FirmInfo.length !== 0) {
                this.UserInformationfirmInfoHasValue = true;
                if(result.map_FirmUserRole) {
                    for(let key in result.map_FirmUserRole) {
                        // Preventing unexcepted data
                        if (result.map_FirmUserRole.hasOwnProperty(key)) { // Filtering the data in the loop
                            this.UserInformationFirmUserRoleMap.push({value:result.map_FirmUserRole[key], key:key, uniqueHoverId: false});
                        }
                    }
                }
            } else {
                this.UserInformationfirmInfoHasValue = false;
            }
            if(result.list_CompanyInfo !== null && result.list_CompanyInfo !== undefined && result.list_CompanyInfo.length !== 0) {
                this.UserInformationcompanyInfoHasValue = true;
                if(result.map_CompanyUserRole) {
                    for(let key in result.map_CompanyUserRole) {
                        // Preventing unexcepted data
                        if (result.map_CompanyUserRole.hasOwnProperty(key)) { // Filtering the data in the loop
                            this.UserInformationcompanyUserRoleMap = [...this.UserInformationcompanyUserRoleMap, {value:result.map_CompanyUserRole[key], key:key, uniqueHoverId: false}];
                        }
                    }
                }
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
    showData(event){
        let tempArrr = [];
        let uniqueId = event.currentTarget.dataset.zpcompanyid;
        let strConciergeGroupId = event.currentTarget.dataset.conciergegroupid;
        let strPermission = event.currentTarget.dataset.permissionstr;
        this.UserInformationcompanyUserRoleMap.forEach(eachRecord => {            
            if(eachRecord.value.strZPCompanyId === uniqueId) {
                // console.log('eachRecord.strConciergeGroupId>>'+ JSON.stringify(eachRecord.value.strConciergeGroupId));
                // console.log('eachRecord.strPermission>>'+ JSON.stringify(eachRecord.value.strPermission));
                // console.log('eachRecord.conciergeGroupIdfujhvhj>>'+ JSON.stringify(strConciergeGroupId));
                // console.log('eachRecord.permissionStrkjhk>>'+ JSON.stringify(strPermission));
                if(eachRecord.value.strConciergeGroupId !== undefined || eachRecord.value.strPermission !== undefined) {
                    eachRecord.uniqueHoverId = true;
                } else {
                    eachRecord.uniqueHoverId = false;
                }
            } 
            tempArrr = [...tempArrr,eachRecord];
        });
        this.UserInformationcompanyUserRoleMap = [];
        this.UserInformationcompanyUserRoleMap = Array.from(tempArrr);
    }
    hideData(event){
        let tempArrr = [];
        this.UserInformationcompanyUserRoleMap.forEach(eachRecord => {
                eachRecord.uniqueHoverId = false;
            tempArrr = [...tempArrr,eachRecord];
        });
        this.UserInformationcompanyUserRoleMap = [];
        this.UserInformationcompanyUserRoleMap = Array.from(tempArrr);
    }

    handleUpdate(event) {
        this.showSpinner = true;
        updateContact({
            idCase: this.caseRecordId,
            strContactId: event.target.value
        }).then(result => {
            this.showSpinner = false;
            displayToast(this, 'Contact updated successfully!', '', 'success', 'sticky');
            const updateContactEvent = new CustomEvent('updatecontact', {
                detail: {},
            });
            // Fire the custom event
            this.dispatchEvent(updateContactEvent);


        }).catch(error => {
            this.showSpinner = false;
        })
    }


    handleOpenCompany(event){
    const accountChangeEvent = new CustomEvent('openlink', {detail: {originalContactId : event.currentTarget.dataset.contactrecid}});
                // Fire the custom event
        this.dispatchEvent(accountChangeEvent);
    }



    togglePopover() {

        const closePopOverEvent = new CustomEvent('closepopover', {
            detail: {},
        });
        // Fire the custom event
        this.dispatchEvent(closePopOverEvent);
    }
}