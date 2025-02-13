import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getUserInformation from '@salesforce/apex/LWC_ContactUserInformationController.getUserInformation';
import updateAccount from '@salesforce/apex/LWC_ContactUserInformationController.updateAccount';

export default class CaseContactHeaderPopOver extends NavigationMixin(LightningElement) {

    @api recordId;

    @track blnShowPopover;
    @track blnUserInfoFirmHasValue = false;
    @track map_UserInfoFirmuser = [];
    @track blnUserInfoCompanyHasValue = false;
    @track map_UserInfoCompanyUserRole = [];

    @track blnShowSpinner = false;
    blnShowMoreDetails = false;
    strMoreDetails = "slds-popover__body-list";

    connectedCallback() {

        getUserInformation({
            idCase: this.recordId
        }).then(result => {
            if(result.list_FirmInfo && result.list_FirmInfo.length !== 0) {
                this.blnUserInfoFirmHasValue = true;
                if(result.map_FirmUserRole) {
                    for(let key in result.map_FirmUserRole) {
                        if (result.map_FirmUserRole.hasOwnProperty(key)) { // Filtering the data in the loop
                            this.map_UserInfoFirmuser = [...this.map_UserInfoFirmuser, {value:result.map_FirmUserRole[key], key:key, uniqueHoverId: false}];
                        }
                    }
                }
            } else {
                this.blnUserInfoFirmHasValue = false;
            }
            if(result.list_CompanyInfo &&  result.list_CompanyInfo.length !== 0) {
                this.blnUserInfoCompanyHasValue = true;
                if(result.map_CompanyUserRole) {
                    for(let key in result.map_CompanyUserRole) {
                        if (result.map_CompanyUserRole.hasOwnProperty(key)) { // Filtering the data in the loop
                            this.map_UserInfoCompanyUserRole = [...this.map_UserInfoCompanyUserRole, {value:result.map_CompanyUserRole[key], key:key, uniqueHoverId: false}];
                        }
                    }
                }
            } else {
                this.blnUserInfoCompanyHasValue = false;
            }
        }).catch(error => {
            console.error('error in caseContactHeaderPopOver ', error);
        });
    }

    togglePopover() {

        const closePopOverEvent = new CustomEvent('closepopover', {
            detail: {},
        });
        // Fire the custom event
        this.dispatchEvent(closePopOverEvent);
    }

    showData(event){        
        let idUnique = event.currentTarget.dataset.zpcompanyid;
        let strConciergeGroupId = event.currentTarget.dataset.conciergegroupid;
        let permissionStr = event.currentTarget.dataset.permissionstr;
        let strTier = event.currentTarget.dataset.tier; 
        let strBlockName = event.currentTarget.dataset.blockname;
        if(strBlockName === "company") {
            let tempCompArrr = [];
            this.map_UserInfoCompanyUserRole.forEach(eachRecord => {            
                if(eachRecord.value.strZPCompanyId === idUnique) {
                    if(eachRecord.value.strConciergeGroupId !== undefined || 
                        eachRecord.value.strPermission !== undefined || 
                        event.currentTarget.dataset.tier !== undefined) {
                        eachRecord.uniqueHoverId = true;
                    } else {
                        eachRecord.uniqueHoverId = false;
                    }
                } 
                tempCompArrr = [...tempCompArrr,eachRecord];
            });
            this.map_UserInfoCompanyUserRole = [];
            this.map_UserInfoCompanyUserRole = Array.from(tempCompArrr);

            let tempFirmArrr = [];
            this.map_UserInfoFirmuser.forEach(eachRecord => {
                    eachRecord.uniqueHoverId = false;
                    tempFirmArrr = [...tempFirmArrr,eachRecord];
            });
            this.map_UserInfoFirmuser = [];
            this.map_UserInfoFirmuser = Array.from(tempFirmArrr);
        } else if(strBlockName === "firm") {
            let tempCompArrr = [];
            this.map_UserInfoFirmuser.forEach(eachRecord => {            
                if(eachRecord.value.strZPCompanyId === idUnique) {
                    if(eachRecord.value.strConciergeGroupId !== undefined || 
                        eachRecord.value.strPermission !== undefined || 
                        event.currentTarget.dataset.tier !== undefined) {
                        eachRecord.uniqueHoverId = true;
                    } else {
                        eachRecord.uniqueHoverId = false;
                    }
                } 
                tempCompArrr = [...tempCompArrr,eachRecord];
            });
            this.map_UserInfoFirmuser = [];
            this.map_UserInfoFirmuser = Array.from(tempCompArrr);

            let tempFirmArrr = [];
            this.map_UserInfoCompanyUserRole.forEach(eachRecord => {
                    eachRecord.uniqueHoverId = false;
                    tempFirmArrr = [...tempFirmArrr,eachRecord];
            });
            this.map_UserInfoCompanyUserRole = [];
            this.map_UserInfoCompanyUserRole = Array.from(tempFirmArrr);
        }
    }
    hideData(event){
        let tempArrr = [];
        this.map_UserInfoCompanyUserRole.forEach(eachRecord => {
                eachRecord.uniqueHoverId = false;
            tempArrr = [...tempArrr,eachRecord];
        });
        this.map_UserInfoCompanyUserRole = [];
        this.map_UserInfoCompanyUserRole = Array.from(tempArrr);

        let tempFirmArrr = [];
        this.map_UserInfoFirmuser.forEach(eachRecord => {
                eachRecord.uniqueHoverId = false;
                tempFirmArrr = [...tempFirmArrr,eachRecord];
        });
        this.map_UserInfoFirmuser = [];
        this.map_UserInfoFirmuser = Array.from(tempFirmArrr);
    }

    handleUpdate(event) {

        this.blnShowSpinner = true;
        let isRerouteValue;
        let company_FirmIdValue = event.target.value;
        if(event.target.value !== undefined && event.target.label ==='Update Account' ){
            isRerouteValue = false;
        } else {
            isRerouteValue = true;
        }
        updateAccount({blnIsReroute: isRerouteValue, idCase: this.recordId, strCompanyFirmId: company_FirmIdValue})
        .then(result=>{
            if(result) {
                this[NavigationMixin.GenerateUrl]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result.Id,
                        actionName: 'view',
                    },
                }).then(url => {
                    const event = new ShowToastEvent({
                        "title": "Update Successful!",
                        "mode": "sticky",
                        "variant": "success",
                        "message": "Case {1} routed to " + result.Owner.Name + "!",
                        "messageData": [
                            'Case',
                            {
                                url,
                                label: result.CaseNumber
                            }
                        ]
                    });
                    this.dispatchEvent(event);
                });
                const accountChangeEvent = new CustomEvent('accountchange', {detail: {}});
                // Fire the custom event
                this.dispatchEvent(accountChangeEvent);
                this.blnShowSpinner = false;
            } 
            if(!isRerouteValue) {

                this.blnShowSpinner = false;
                this.showToast('Success !','Update successful','success');

                const accountChangeEvent = new CustomEvent('accountchange', {detail: {}});
                // Fire the custom event
                this.dispatchEvent(accountChangeEvent);
                this.blnShowSpinner = false;
            }
            // this.showSpinner = false;
            // this.showToast('Account updated successfully!',' ','success');
        })
        .catch(error=>{
            console.log('result>>' + JSON.stringify(error));
            this.blnShowSpinner = false;
            this.showToast('Error !', 'Please contact the system admin' ,'Error');
        });
    }

    handleOpenCompany(event){
        //const accountChangeEvent = new CustomEvent('openlink', {detail: {originalContactId : event.currentTarget.dataset.contactrecid}});
        const accountChangeEvent = new CustomEvent('openlink', {detail: {strPandaURL : event.currentTarget.dataset.strpandaurl}});
                // Fire the custom event
        this.dispatchEvent(accountChangeEvent);
    }
    showToast(title,message,variantType) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variantType,
        });
        this.dispatchEvent(event);
    }

    handleShowMoreDetails() {
        this.blnShowMoreDetails = true;
        this.strMoreDetails = "slds-popover__body-list slds-m-bottom_medium";
    }
}