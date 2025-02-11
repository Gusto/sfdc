import { LightningElement, track, api } from 'lwc';

/* Import Apex Methods */
import fetchQueueList from '@salesforce/apex/PlayModeCaseListControllerLightning.getcaseQueueList';
import fetchPendingCaseList from '@salesforce/apex/PlayModeCaseListControllerLightning.getNumberOfPendingCases';
import assignCases from '@salesforce/apex/PlayModeCaseListControllerLightning.assignCaseFromQueue';
import { displayToast } from 'c/utilityService';

/* Imported Methods from Utility Service */
import {navigateToSObject } from 'c/utilityService';

/* Import Standard Events */
import { NavigationMixin } from 'lightning/navigation';

export default class PlayModeCaseCmp extends NavigationMixin(LightningElement) {

    /* All Boolean Variables */

    /* Flag to show spinner component - If set to true, will show spinner on the UI */
    @track blnIsLoading = false;
    /* Flag to indicate buttons need to be disabled. If Set to True, Buttons will be disabled */
    @track blnIsDisabled = false;
    /* Flag to indicate if error messages need to be visible */
    @track blnIsMessageVisible = false;

    /* All String Variables */

    /* Message displayed to the User */
    @track strMessage;
    /* Base Class String variable - error, warning and success classes will be appended to the end */
    @track strMessageClassBase = 'slds-notify_alert slds-theme_alert-texture ';
    @track strMessageClass = '';

    /* All List Variables */
    /* Different Queue Options Dynamically updated on RunTime */
    @track list_queueChoices = [];
    /* Indicates how many cases advocates can assign to themselves */
    @track list_numberToServeUp = [
        {label: '1', value: '1'},
        {label: '5', value: '5'},
        {label: '10', value: '10'}
    ];

    @track idQueue;
    @track intNumberToServeUp = '1';

    @api strCaseStatuses;

    /* connectedCallBack function runs 
     * on load of this lwc. It calls
     * Apex Controller and fetches
     * queues configured for logged in user
    */
    connectedCallback() {
        // Loads Queue Dropdown List
        this.loadCaseQueueList(false); 
    }

    /* loadCaseQueueList calls
     * Apex Controller and fetches
     * queues configured for logged in user
    */
    loadCaseQueueList(blnIsRefresh) {

        /* Sets blnIsLoading to True - Spinner(Loading) Icon will be displayed */
        this.blnIsLoading = true;
        /* Apex Callout to retrieve queue data for logged in user */
        fetchQueueList()
            .then(result => {
                /* Checks if the callout was successful */
                if(result.blnIsSuccess) {
                    /* intCounter variable to count number of queues */
                    let intCounter = 0;
                    this.list_queueChoices = [];
                
                    /* Iterate over queue map - map of queue id and names */
                    for (let strQueueName in result.map_caseQueueIdToName) {
                        /* increase intCounter variable by 1 */
                        intCounter = intCounter + 1;
                        /* creates a json object of nme and label */
                        let objOption = {
                            label: result.map_caseQueueIdToName[strQueueName],
                            value: strQueueName 
                        };
                        /* pushes them to queue options list */
                        this.list_queueChoices = [ ...this.list_queueChoices, objOption ];
                    }

                    /* If intCounter is greater than 0, display how many active queues were found */
                    if(intCounter > 0) {
                        let strMessage = blnIsRefresh ? 'Queues refreshed successfully!' : intCounter + ' active queues found. Please select a queue.';
                        if(blnIsRefresh) {
                            this.showMessage(false, strMessage, 'slds-theme_success');
                            this.idQueue = '';
                            this.intNumberToServeUp = '1';
                        }
                    } else if(intCounter == 0) {
                        /* If intCounter is equal to 0, display error message that no queues were found - set disabled flag to true */
                        this.showMessage(true, 'No active queues found. Please contact Admin.', 'slds-theme_error');
                        this.idQueue = '';
                        this.intNumberToServeUp = '1';
                    }

                    /* Sets blnIsLoading to False - Spinner(Loading) Icon will not be displayed */
                    this.blnIsLoading = false;
                } else {
                    this.blnIsLoading = false;
                    this.showMessage(true, result.message, 'slds-theme_error');
                }
            })
            .catch(error => {
                /* In case of Javascript exception, catch them and show error message */
                this.showMessage(true, 'Internal Server Error. Please try again later.', 'slds-theme_error');
                this.error = error;
                this.blnIsLoading = false;
                this.blnIsDisabled = true;
            });
    }


    /* showMessage displays
     * success, error or warning
     * messages. depending on the strClassName,
     * type fo messages will vary.
    */
    showMessage(blnIsError, strMessage, strClassName) {
        this.blnIsDisabled = blnIsError ? true : false;
        this.blnIsMessageVisible = true;
        this.strMessageClass = this.strMessageClassBase + strClassName;
        this.strMessage = strMessage;
    }

    /* Handles Queue value Changes.
     * Does an Apex Callout. Gets
     * number of pending cases unassigned
     * for a particular queue.
    */
    handleQueueChange(event) {
        /* Sets blnIsLoading to True - Shows Spinner component */
        this.blnIsLoading = true;
        /* Queue Id value from Event */
        this.idQueue = event.detail.value;
        /* Apex Call to fetch number of cases assigned for a particular queue */
        fetchPendingCaseList({
            idQueue: event.detail.value
        })
        .then(result => {
            /* If result is success, show number of cases assigned for a particular queue */
            if(result.blnIsSuccess) {
                /* Check if number is greater than 0, show success message */
                if(result.intPendingCases > 0) {
                    this.showMessage(false, 'There are ' + result.intPendingCases + ' pending cases to be assigned.', 'slds-theme_success');
                } else  if(result.intPendingCases === 0) {
                    /* If number is equal to 0, show error message that no cases found for this particular queue */
                    this.showMessage(true, 'No cases found. Please select a different queue', 'slds-theme_error');
                }
            }
            this.blnIsLoading = false;
        })
        .catch(error => {
            /* In case of Javascript exception, catch them and show error message */
            this.showMessage(true, 'Internal Server Error. Please try again later.', 'slds-theme_error');
            this.error = error;
            this.blnIsLoading = false;
        });
    }

    /*
     * Performs Apex Callout
     * and assigns x number of
     * cases to logged in user id
    */
    handleSubmit() {
        /* Checks if all required input elements have values */
        const allValid = [...this.template.querySelectorAll('lightning-combobox')]
        .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
        }, true);
        /* Performs Apex Call only when validations are successful */
        if (allValid) {
            /* Sets blnIsLoading to True - Shows Spinner component */
            this.blnIsLoading = true;
            let list_Statuses = [];

            if (this.strCaseStatuses) {
                let strStatusesValues = this.strCaseStatuses;
                list_Statuses = strStatusesValues.split(',');
            }

            /* Apex Call to Assign Cases */
            assignCases({
                idQueue: this.idQueue,
                intNumberToServeUp: this.intNumberToServeUp,
                list_CaseStatuses: list_Statuses
            })
            .then(result => {
                /* If result is successful, shows message on the UI */
                if(result.blnIsSuccess) {
                    this.showMessage(false, result.message, 'slds-theme_success');
                    /* Iterate over every case record and navigates to every record (opens a new tab in Console) */
                    let intCounter = result.list_cases.length;

                    const evtOpenTab = new CustomEvent('opentab', {
                        detail: {list_cases: result.list_cases},
                    });
                    // Fire the custom event
                    this.dispatchEvent(evtOpenTab);

                    const minimizeUtilityEvent = new CustomEvent('minimzeutility', {
                        detail: {},
                    });
                    // Fire the custom event
                    this.dispatchEvent(minimizeUtilityEvent);
                    if(intCounter === 1) {
                        displayToast(this, result.list_cases[0].CaseNumber + ' assigned to you successfully', '', 'success', 'sticky');
                    } else if(intCounter > 1) {
                        displayToast(this, result.list_cases[0].CaseNumber + ' and ' + (intCounter - 1) + ' other cases assigned to you successfully', '', 'success', 'sticky');
                    }
                } else {
                    /* If result is not a success, show error message on the UI */
                    this.showMessage(false, result.strMessage, 'slds-theme_error');
                }
                /* Hide Spinner Component */
                this.blnIsLoading = false;
            })
            .catch(error => {
                /* In case of Javascript exception, catch them and show error message */
                this.showMessage(true, 'Internal Server Error. Please try again later.', 'slds-theme_error');
                this.error = error;
                this.blnIsLoading = false;
            });

        }
    }

    /*
     * This method handles when
     * Refresh button is clicked.
     * Loads Queue records configured
     * to particular user
    */
    handleRefresh() {
        // Loads Queue Dropdown List
        this.loadCaseQueueList(true); 
    }

    /* handles "Number to Serve Up"
     * field value changes.
    */
    handleNumberToServeUpChange(event) {
        this.intNumberToServeUp = event.detail.value;
    }
}