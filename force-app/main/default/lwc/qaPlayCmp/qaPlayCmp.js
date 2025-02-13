import { LightningElement, track, api, wire } from 'lwc';
import queryUsers from '@salesforce/apex/QAPlayController.queryUsers';
import queryReasons from '@salesforce/apex/QAPlayController.queryReasons';
import queryCases from '@salesforce/apex/QAPlayController.queryCases';
export default class QaPlayCmp extends LightningElement {

    //selecting user
    blnShowUser = true;
    blnIsUserFound = false;
    userSelected;
    strUserSelectedId;
    list_FilteredUsers;
    list_UserRecs;
    blnDisabled = false;
    blnDirectReport = false;

    //filters for cases
    dtFrom;
    dtTo;
    strClass;
    strRecordType;
    strOrigin;
    strCSAT;
    strCaseReason;
    strAllOrEscalated = "All Cases";

    //selecting case reason
    blnIsCaseReasonFound = true;
    map_totalCaseReasonToGroup;
    map_caseReasonToGroupMap;

    //case playing
    idSelectedCase;
    list_Cases;
    blnIsRendered;
    blnIsLoading = false;
    blnQAInProgress = false;
    blnIsCaseListVisible = false;

    /* If navigation buttons are visible */
    @track blnIsPreviousButtonDisabled = true;
    @track blnIsNextButtonDisabled = false;

    /* Message displayed to the User */
    @track strMessage;
    /* Base Class String variable - error, warning and success classes will be appended to the end */
    @track strMessageClassBase = 'slds-notify_alert slds-theme_alert-texture ';
    @track strMessageClass = '';

    connectedCallback() {
        this.loadUsers(false);
    }

    handleFilterSelected(event){
        this.userSelected = event.detail.name;
    }

    //get the selected queue
    handleRecordSelected(event) {
        this.userSelected = event.detail.name;
        this.strUserSelectedId = event.detail.id;
    }

    get list_ClassOptions() {
        return [
            { label: 'Any', value: 'Any' },
            { label: 'Class 1', value: 'Class 1' },
            { label: 'Class 2', value: 'Class 2' },
            { label: 'Class 3', value: 'Class 3' }
        ];
    }

    get list_RecordTypeOptions() {
        return [
            { label: 'Any', value: 'Any' },
            { label: 'Benefits Care', value: 'Benefits Care' },
            { label: 'Payroll Care', value: 'Payroll Care' },
            { label: 'Modern Bank', value: 'Modern Bank' },
            { label: 'Tax Res', value: 'Tax Res' }
        ];
    }

    get list_OriginOptions() {
        return [
            { label: 'Any', value: 'Any' },
            { label: 'Chat', value: 'Chat' },
            { label: 'Email', value: 'Email' },
            { label: 'Phone', value: 'Phone' }
        ];
    }

    get list_CSATOptions() {
        return [
            { label: 'Any', value: 'Any' },
            { label: 'Good', value: 'Good' },
            { label: 'Bad', value: 'Bad' },
        ];
    }
    
    //toggle direct reports event
    handleDirectReportChange(event) {
        this.userSelected = '';
        this.loadUsers(event.detail.checked);
        this.blnDirectReport = event.detail.checked;
    }

    //load list of users
    loadUsers(blnDirectReports) {
        this.blnIsLoading = true;
        queryUsers({
            blnDirectReports : blnDirectReports
        })
            .then(result => {
                if (result) {
                    let resultUsers = result;
                    let list_tempUsers = [];
                    //console.log(JSON.stringify(result));
                    resultUsers.forEach(eachUser => {
                        if(eachUser.Profile) {
                            list_tempUsers.push({
                                label: eachUser.Name,
                                value: eachUser.Id,
                                subtext: eachUser.Profile.Name
                            });
                        }
                    });
                    this.list_UserRecs = list_tempUsers;
                    this.list_FilteredUsers = list_tempUsers;
                    if (this.list_FilteredUsers.length === 0) {
                        this.blnIsUserFound = false;
                    }
                }
                this.blnIsLoading = false;
            })
            .catch(error => {
                // If there is an Exception, Show Error Message on the UI
                this.error = error;
                this.blnIsLoading = false;
            });
    }

    //load list of case reasons
    loadReasons() {
        this.blnIsLoading = true;
        queryReasons()
        .then(result => {
            if (result) {
                let arrCaseReasons = [];
                for (const property in result) {
                    let caseReason = {};
                    caseReason.group = property;
                    caseReason.value = result[property];
                    arrCaseReasons.push(caseReason);
                }
                this.map_caseReasonToGroupMap = arrCaseReasons;
                this.map_totalCaseReasonToGroup = arrCaseReasons;
                if (arrCaseReasons.length === 0) {
                    this.blnIsCaseReasonFound = false;
                }
            }
            this.blnIsLoading = false;
        })
        .catch(error => {
            this.error = error;
            this.blnIsLoading = false;
        });
    }

    //filter the queues based on input
    handleFilterRecords(event) {
        let input = event.detail;
        let list_Users = [];
        let list_UserRecs = this.list_UserRecs;
        let intCounter = 0;
        //console.log('list_UserRecs ', JSON.stringify(list_UserRecs));
        list_UserRecs?.forEach(user => {
            let blnFound = false;
            //caseReasonToAdd.group = caseReason.group;
            if (user.label.toLowerCase().includes(input.toLowerCase())) {
                if(intCounter < 30) {
                    list_Users.push(user);
                    blnFound = true;
                }
                intCounter++;
            }
            
        });
        
        this.list_FilteredUsers = list_Users;
        if (list_Users.length === 0) {
            this.blnIsUserFound = false;
        } else {
            this.blnIsUserFound = true;
        }

    }

    // When a case reason is selected from auto complete
    handleCaseReasonSelected(event) {
        this.strCaseReason = event.detail.reason;
        //make sure confirm case reason is actually set to blank
        if(!this.strCaseReason) {
            this.strCaseReason = "";
        }
    }

    // This method is responsible for showing filtered case reason for auto complete
    handleFilterCaseReason(event) {
        // Get input
        let strinput = event.detail;
        // Check if strinput has a value else set to blank
        strinput = strinput ? strinput : '';
        let map_totalCaseReasons = this.map_totalCaseReasonToGroup;
        let list_arrCaseReasons = [];
        var t0 = performance.now();
        let intCounter = 0;
        map_totalCaseReasons.forEach(caseReason => {
            let objCaseReasonsToAdd = {};
            let list_sortedCaseReasons = [];
            let blnIsFound = false;
            objCaseReasonsToAdd.group = caseReason.group;
            for (const property in caseReason.value) {
                if (caseReason.value[property].toLowerCase().includes(strinput.toLowerCase())) {
                    if (intCounter < 10) {
                        
                        let reason = {};
                        reason.value = property;
                        reason.label = caseReason.value[property];
                        list_sortedCaseReasons.push(reason);
                        blnIsFound = true;
                    }
                    intCounter = intCounter + 1;
                }
            }
            if (blnIsFound) {
                objCaseReasonsToAdd.value = list_sortedCaseReasons.sort();
                list_arrCaseReasons.push(objCaseReasonsToAdd);
            }
        })
        this.map_caseReasonToGroupMap = list_arrCaseReasons;
        if (list_arrCaseReasons.length === 0) {
            this.blnIsCaseReasonFound = false;
        } else {
            this.blnIsCaseReasonFound = true;
        }
        var t1 = performance.now();
    }

    //query for cases according to the filters chosen
    handleStart() {
        this.blnDisabled = true;
        queryCases({
            strOwnerId: this.strUserSelectedId,
            dtFrom: this.dtFrom,
            dtTo: this.dtTo,
            strClass: this.strClass,
            strRecordType: this.strRecordType,
            strCaseReason: this.strCaseReason,
            strOrigin: this.strOrigin,
            strCSAT: this.strCSAT,
            strEscalated: this.strAllOrEscalated
        }).then(result => {
            if(result) {
                //console.log('result ', JSON.stringify(result));
                if(result.length > 0) {
                    this.blnIsCaseListVisible = true;
                    this.list_Cases = result;

                    let idPreviousCase = this.idSelectedCase;
                    this.idSelectedCase = this.list_Cases[0].Id;
                    this.openNewCaseTab(this.list_Cases[0].Id, 1, idPreviousCase);
                }
                else {
                    //no cases to show. Doing all of this because message isn't showing up when not displaying end qa button
                    this.blnIsCaseListVisible = true;
                    this.blnQAInProgress = true;
                    this.blnIsNextButtonDisabled = true;
                    this.showMessage('No Cases found under these filters.', 'slds-theme_success');
                }
            } else {
                this.showMessage(result.strMessage, 'slds-theme_error');
            }
            this.blnIsLoading = false;
        }).catch(error => {
            console.log(JSON.stringify(error));
            this.blnIsLoading = false;
        });
    }

    //open a new tab with the case
    openNewCaseTab(idCase, intCaseNumber, idPreviousCase) {
        this.blnQAInProgress = true;
        this.blnIsLoading = true;
        let evtOpenCase = new CustomEvent('openqacase', {
            detail: { objCase:{
                idCaseToOpen: idCase,
                idCaseToClose: idPreviousCase
            } },
        });
        this.dispatchEvent(evtOpenCase);
        this.showMessage('Viewing '+ intCaseNumber + ' of ' + this.list_Cases.length + ' cases', 'slds-theme_success');
        if(intCaseNumber === this.list_Cases.length) {
            this.blnIsNextButtonDisabled = true;
            this.blnIsPreviousButtonDisabled = this.list_Cases.length === 1 ? true : false;
        }  else if(intCaseNumber === 1) {
            this.blnIsNextButtonDisabled = false;
            this.blnIsPreviousButtonDisabled = true;
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
            if(objEachCase.Id === this.idSelectedCase) {
                if(!blnCaseFound) {
                    if(intCounter !== intCaseListLength) {
                        blnCaseFound = true;
                        this.idSelectedCase = this.list_Cases[intCounter + 1].Id;
                        this.blnIsPreviousButtonDisabled = false;
                        let intCaseNumber = Number(intCounter) + 2;
                        this.openNewCaseTab(this.idSelectedCase, intCaseNumber, this.list_Cases[intCounter].Id);
                        this.blnIsLoading = false;
                    } 
                }
            } 
            intCounter = intCounter + 1;
        });
    }

    // Handler for next button
    handlePrevious() {
        let intCounter = 0;
        let blnCaseFound = false;
        this.list_Cases.forEach(objEachCase => {
            if(objEachCase.Id === this.idSelectedCase) {
                if(!blnCaseFound) {
                    if(intCounter !== 0) {
                        blnCaseFound = true;
                        this.idSelectedCase = this.list_Cases[intCounter - 1].Id;
                        // this.template.querySelector('c-route-case-cmp').doInit(this.idSelectedCase);
                        this.blnIsPreviousButtonDisabled = false;
                        let intCaseNumber = Number(intCounter);
                        this.openNewCaseTab(this.idSelectedCase, intCaseNumber, this.list_Cases[intCounter].Id);
                        this.blnIsLoading = false;
                    } 
                }
            } 
            intCounter = intCounter + 1;
        });

    }

    // Showing Success or Failure Messages
    showMessage(strMessage, strClassName) {
        // strClassName determines whether it is success or error message
        this.blnIsMessageVisible = true;
        this.strMessageClass = this.strMessageClassBase + strClassName;
        this.strMessage = strMessage;
    }

    handleShowFilters() {
        this.blnShowUser = false;
        this.loadReasons();
        if(this.strAllOrEscalated == 'Escalated Cases') {
            setTimeout(() => {
                this.template.querySelector('lightning-input.escalatedCases').checked = this.strAllOrEscalated == 'Escalated Cases' ? true : false ;
            }, 500);
        }
    }

    handleEndQA() {
        this.blnQAInProgress = false;
        this.blnIsCaseListVisible = false;
        this.blnIsMessageVisible = false;
        this.list_Cases = [];
        this.blnDisabled = false;
    }

    handleSaveFilters() {
        this.blnShowUser = true;
        if(this.blnDirectReport) {
            setTimeout(() => {
                this.template.querySelector('lightning-input.directReport').checked = this.blnDirectReport;
            }, 500);
        }
    }

    //filters selected  
    get blnDatesSelected() {
        return this.dtFrom && this.dtTo ? true : false;
    }

    get blnClassSelected() {
        return this.strClass ? true : false;
    }

    get blnRecordTypeSelected() {
        return this.strRecordType ? true : false;
    }

    get blnCaseReasonSelected() {
        return this.strCaseReason ? true : false;
    }

    get blnOriginSelected() {
        return this.strOrigin ? true : false;
    }

    get blnCSATSelected() {
        return this.strCSAT ? true : false;
    }

    get blnUserSelected() {
        return this.userSelected ? true : false;
    }

    get blnStartButtonDisabled() {
        return this.blnUserSelected && this.blnDatesSelected && this.blnRecordTypeSelected && 
            this.blnOriginSelected && this.blnCSATSelected ? false : true;
    }

    //input changes
    handleFromChange(event) {
        this.dtFrom = event.detail.value;
    }

    handleToChange(event) {
        this.dtTo = event.detail.value;
    }

    handleClassChange(event) {
        this.strClass = event.detail.value;
    }

    handleRecordTypeChange(event) {
        this.strRecordType = event.detail.value;
    }

    handleOriginChange(event) {
        this.strOrigin = event.detail.value;
    }

    handleCSATChange(event) {
        this.strCSAT = event.detail.value;
    }

    handleEscalatedChange(event) {
        this.strAllOrEscalated = event.detail.checked ? "Escalated Cases" : "All Cases";
    }
}