import { LightningElement, track } from 'lwc';
/* Import Apex Classes and Methods */
import fetchCasesOwnerByQueue from '@salesforce/apex/RoutingCaseController.fetchCasesRelatedToQueue';
import updateCase from '@salesforce/apex/RoutingCaseController.updateCaseInRoute';
import caseRoutingMessageLabel from '@salesforce/label/c.Engagement_Case_Detail_Routing_Message';
import caseDetailPlayRoutingLabel from '@salesforce/label/c.Case_Detail_Play_Routing';

export default class CaseRouterForPlay extends LightningElement {

    /* Flag to show spinner */
    @track blnIsLoading = false;
    /* list of case owner - fetched from custom label */
    @track list_CaseOwnerOptionList = [];
    /* Flag to indicate if error messages need to be visible */
    @track blnIsMessageVisible = false;
    /* Flag to make the case routing message to be visible */
    @track blnIsRoutingMessageVisible = false;

    /* Message displayed to the User */
    @track strMessage;
    /* Base Class String variable - error, warning and success classes will be appended to the end */
    @track strMessageClassBase = 'slds-notify_alert slds-theme_alert-texture ';
    @track strMessageClass = '';
    @track strRoutingMessageClass = '';
    /*Message shown when there are no more cases available for routing*/
    @track strRoutingMessage;

    /* list of cases to be routed */
    @track list_Cases = [];

    /* Is start button visible */
    @track blnIsStartRoutingButtonVisible = false;
    @track blnIsCaseListVisible = false;

    /* If navigation buttons are visible */
    @track blnIsPreviousButtonDisabled = true;
    @track blnIsNextButtonDisabled = false;
    @track blnIsStartButtonDisabled = true;
    @track blnIsSkip = false;

    @track idSelectedCase;
    @track idCurrentCase;
    intCounter = 0;

    connectedCallback() {
        // List of Comma separated owner fetched from Custom Label
        let list_CaseOwner = caseDetailPlayRoutingLabel.split(',');
        let list_CaseOwnerSplit = [];
        list_CaseOwner.forEach(strEachOwner => {
            list_CaseOwnerSplit.push({
                label: strEachOwner,
                value: strEachOwner
            });
        });
        this.list_CaseOwnerOptionList = list_CaseOwnerSplit;
    }

    // Whenever a queue is selected, number of cases to be routed in a particular queue is shown
    handleQueueChange(event) {
        this.blnIsLoading = true;
        this.blnIsRoutingMessageVisible = false;
        fetchCasesOwnerByQueue({
            strQueueName: event.detail.value.toString()
        }).then(result => {
            this.blnIsCaseListVisible = false;
            // Check if it is successful
            if (result.blnIsSuccess) {
                // Check if the length is greater than zero
                if (result.list_CasesToBeRouted.length > 0) {
                    // Show number of cases pending in a selected queue
                    this.showMessage('There are ' + result.list_CasesToBeRouted.length + ' pending cases to be routed.', 'slds-theme_success');
                    this.list_Cases = result.list_CasesToBeRouted;
                    this.blnIsStartRoutingButtonVisible = true;
                    this.blnIsStartButtonDisabled = false;
                    this.intCounter = 0;
                } else {
                    this.showMessage('No cases found. Please select a different queue', 'slds-theme_error');
                    this.blnIsStartRoutingButtonVisible = false;
                }
            } else {
                // Show error message if any
                this.showMessage(result.strMessage, 'slds-theme_error');
                this.blnIsStartRoutingButtonVisible = false;
            }
            this.blnIsLoading = false;
        }).catch(error =>{
            // In case of an exception, print exception message to the console
            console.error('Error in CaseRoutedForPlayCmp - handleQueueChange ', error);
            this.blnIsLoading = false;
            this.blnIsStartRoutingButtonVisible = false;
            this.blnIsCaseListVisible = false;
        })
    }

    // Showing Success or Failure Messages
    showMessage(strMessage, strClassName) {
        // strClassName determines whether it is success or error message
        this.blnIsMessageVisible = true;
        this.strMessageClass = this.strMessageClassBase + strClassName;
        this.strMessage = strMessage;
    }

    // Showing message when all cases are in routing
    showRoutingMessage(strMessage, strClassName) {
        // strClassName determines whether it is success or error message
        this.blnIsRoutingMessageVisible = true;
        this.strRoutingMessageClass = this.strMessageClassBase + strClassName;
        this.strRoutingMessage = strMessage;
    }

    // Hanlder for Start Routing Button
    handleStartRouting() {
        //Check if there any cases available for routing, else show message
        if (this.intCounter < this.list_Cases.length) {
            this.idSelectedCase = this.list_Cases[this.intCounter].Id;
            this.openNewCaseTab(this.list_Cases[this.intCounter].Id, this.intCounter + 1, null, 'start');
        } else {
            this.blnIsNextButtonDisabled = true;
            this.blnIsPreviousButtonDisabled = true;
            this.showRoutingMessage(caseRoutingMessageLabel, 'slds-theme_warning');
        }
        
    }

    // Handler for next button
    handleNext() {
        // get case list length
        let intCaseListLength = this.list_Cases.length - 1;
        let intCounter = 0;
        let blnCaseFound = false;
        // Iterate over cases, until you find a match with selected case
        this.list_Cases.forEach(objEachCase => {
            if (objEachCase.Id === this.idSelectedCase) {
                if (!blnCaseFound) {
                    if (intCounter !== intCaseListLength) {
                        blnCaseFound = true;
                        if (!this.blnIsSkip) {
                            this.idCurrentCase = this.list_Cases[intCounter].Id;
                        }
                        this.idSelectedCase = this.list_Cases[intCounter + 1].Id;
                        this.blnIsPreviousButtonDisabled = false;
                        let intCaseNumber = Number(intCounter) + 2;
                        this.openNewCaseTab(this.idSelectedCase, intCaseNumber, this.idCurrentCase, 'next');
                    } 
                }
            } 
            intCounter = intCounter + 1;
        });
        //If all the cases are currently in route show a message on the case detail play component.
        if (!blnCaseFound) {
            this.blnIsNextButtonDisabled = true;
            this.showRoutingMessage(caseRoutingMessageLabel, 'slds-theme_warning');
        }
    }

     // Handler for next button
    handlePrevious() {
        let intCounter = 0;
        let blnCaseFound = false;
        this.list_Cases.forEach(objEachCase => {
            if (objEachCase.Id === this.idSelectedCase) {
                if (!blnCaseFound) {
                    if (intCounter !== 0) {
                        blnCaseFound = true;
                        if (!this.blnIsSkip) {
                            this.idCurrentCase = this.list_Cases[intCounter].Id;
                        }
                        this.idSelectedCase = this.list_Cases[intCounter - 1].Id;
                        // this.template.querySelector('c-route-case-cmp').doInit(this.idSelectedCase);
                        this.blnIsPreviousButtonDisabled = false;
                        this.blnIsRoutingMessageVisible = false;
                        let intCaseNumber = Number(intCounter);
                        this.openNewCaseTab(this.idSelectedCase, intCaseNumber, this.idCurrentCase, 'previous');
                    } 
                }
            } 
            intCounter = intCounter + 1;
        });
        //If all the cases are currently in route show a message on the case detail play component.
        if (!blnCaseFound) {
            this.blnIsPreviousButtonDisabled = true;
            this.showRoutingMessage(caseRoutingMessageLabel, 'slds-theme_warning');
        }
    }

     // Opens a new case tab. Sends an aura event which opens case tabs using workspace api
    openNewCaseTab(idCase, intCaseNumber, idPreviousCase, strStage) {
        let objCase = {Id: idCase};
        let objPreviousCase = {};
        if (idPreviousCase) {
            objPreviousCase = {Id: idPreviousCase};
        }
        this.blnIsLoading = true;
        updateCase({
            objCase: objCase,
            isRoute: true,
            objPreviousCase: objPreviousCase
        }).then(result => {
            this.blnIsCaseListVisible = true;
            this.blnIsSkip = false;
            if (result.blnIsSkip) {
                this.blnIsSkip = true;
                if (strStage === 'start') {
                    this.intCounter = this.intCounter + 1;
                    this.handleStartRouting();
                } else if (strStage === 'next') {
                    this.handleNext();
                } else if (strStage === 'previous') {
                    this.handlePrevious();
                }
            } else if (result.blnIsSuccess) {
                let evtOpenCase = new CustomEvent('opencase', {
                    detail: { objCase:{
                        idCaseToOpen: idCase,
                        idCaseToClose: idPreviousCase
                    } },
                });
                this.dispatchEvent(evtOpenCase);
                this.showMessage('Viewing '+ intCaseNumber + ' of ' + this.list_Cases.length + ' pending cases to be routed', 'slds-theme_success');
                this.blnIsStartButtonDisabled = true;
                if (intCaseNumber === this.list_Cases.length) {
                    this.blnIsNextButtonDisabled = true;
                    this.blnIsPreviousButtonDisabled = this.list_Cases.length === 1 ? true : false;
                }  else if (intCaseNumber === 1) {
                    this.blnIsNextButtonDisabled = false;
                    this.blnIsPreviousButtonDisabled = true;
                }
            } else {
                this.showMessage(result.strMessage, 'slds-theme_error');
            }
            this.blnIsLoading = false;
        }).catch(error => {
            this.blnIsLoading = false;
        });
    }
}