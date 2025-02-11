import { LightningElement, track, api, wire } from 'lwc';
import { navigateToSObject, displayToast } from 'c/utilityService';

/* Import Apex Classes and Methods */
import retrieveBonWorkInProgressCases from '@salesforce/apex/BenOpsWorkInProgressCasesController.returnBenOpsWorkInProgressCases';

/* Import Standard Events */
import { NavigationMixin } from 'lightning/navigation';

export default class BenOpsWorkInProgressCasesCmp extends NavigationMixin(LightningElement) {
    @track blnIsNotificationVisible = false;
    @track blnIsWarningMessage = false;
    @track blnIsCommaVisible = true;
    @track blnIsLessThanSeven = false;
    @track blnIsLengthLessThanSeven;
    @track strView = 'View All';
    @track blnIsLoading = false;

    @track strRecordType = 'Payroll Care';
    @track strContactName = '';
    @track list_inProgressCases = [];

    @api recordId;

    @track blnIsPopOverVisible = false;

    handleCloseNotification() {
        this.blnIsNotificationVisible = false;
        this.blnIsWarningMessage = true;
    }

    handleOpenNotification() {
        this.blnIsNotificationVisible = true;
        this.blnIsWarningMessage = false;
    }

    handleCloseAllNotification() {
        this.blnIsNotificationVisible = false;
        this.blnIsWarningMessage = false;
    }

    connectedCallback() {
        this.handleDoInit();
    }

    @api handleDoInit() {
        this.blnIsLoading = true;
        retrieveBonWorkInProgressCases({
            idCase: this.recordId
        })
            .then(result => {
                if (result.blnIsSuccess) {
                    if (result.objCase) {
                        let parentCase = result.objCase;
                        this.strRecordType = parentCase.Record_Type_Name__c;
                        if (parentCase.Contact) {
                            this.strContactName = parentCase.Contact.Name;
                        }
                    }
                    if (result.list_Cases && result.list_Cases.length > 0) {
                        result.list_Cases.forEach((caseObj, intIndex) => {
                            caseObj.blnIsPopOverVisible = false;
                            caseObj.blnIsCommaVisible = true;
                            if (intIndex <= 2) {
                                caseObj.blnIsLessThanSeven = true;
                            } else {
                                caseObj.blnIsLessThanSeven = false;
                            }
                            let d = new Date(caseObj.CreatedDate);
                            caseObj.CreatedDate = (d.getMonth() + 1) + '/' + d.getDate() + '/' + d.getFullYear();
                            this.list_inProgressCases.push(caseObj);

                        })
                        this.blnIsNotificationVisible = true;

                        try {
                            if (this.list_inProgressCases.length > 3) {
                                this.blnIsLengthLessThanSeven = false;
                            }
                            else {
                                this.blnIsLengthLessThanSeven = true;
                                this.list_inProgressCases[this.list_inProgressCases.length - 1].blnIsCommaVisible = false;
                            }
                        } catch (e) {
                            console.log('--error--' + e);
                        }
                    } else {
                        this.list_inProgressCases = [];
                        this.blnIsNotificationVisible = false;
                    }

                } else {
                    displayToast(this, 'Failed to load work in progress cases. Error ' + result.strMessage, '', 'error', '');
                }
                this.blnIsLoading = false;
            })
            .catch(error => {
                // If there is an Exception, Show Error Message on the UI
                this.error = error;
                this.blnIsLoading = false;
            });
    }

    accessHyperLink(event) {
        navigateToSObject(this, event.target.dataset.id, 'standard__recordPage', 'Case', 'view');
    }

    displayPopOver(event) {
        this.list_inProgressCases.forEach(caseObj => {
            if (caseObj.Id === event.target.dataset.id) {
                if (!caseObj.blnIsPopOverVisible) {
                    caseObj.blnIsPopOverVisible = true;

                }
            }
        })
    }

    hidePopOver() {
        this.list_inProgressCases.forEach(caseObj => {
            caseObj.blnIsPopOverVisible = false;
        });
    }

    handleViewAll() {
        try {
            this.strView = (this.strView == 'View All') ? 'View Less' : 'View All';
            if (this.strView == 'View Less') {
                this.list_inProgressCases.forEach(caseObj => {
                    caseObj.blnIsLessThanSeven = true;
                });
            } else {
                this.list_inProgressCases.forEach((caseObj, intIndex) => {
                    if (intIndex <= 2) {
                        caseObj.blnIsLessThanSeven = true;
                    } else {
                        caseObj.blnIsLessThanSeven = false;
                    }
                });
            }
        }
        catch (e) {
            console.log('----error view===' + e);
        }

    }

    togglePopover(event) {
        this.list_inProgressCases.forEach(caseObj => {
            if (caseObj.Id === event.target.dataset.id) {
                if (caseObj.blnIsPopOverVisible) {
                    caseObj.blnIsPopOverVisible = false;
                }
            }
        })
    }
}