import { LightningElement, api, track } from 'lwc';
/* Apex Function Call to Fetch Config for Particular Lookup Relation */
import fetchConfiguration from '@salesforce/apex/RenderDynamicFieldsController.retrieveOutputConfig';

export default class RenderDynamicFieldsCmp extends LightningElement {

    /* Grouping all api variables together */

    /* Parent Id fetched from record page */
    @api recordId;
    /* Name of the object provided by the user from App Builder Config. Refer meta xml for more information */
    @api objectname;
    /* Name of the field provided by the user from App Builder Config. Refer meta xml for more information */
    @api fieldname;
    /* Indicates if fields need to be underlined */
    @api isfieldsunderlined;

    /* Grouping all track variables together */
    
    /* Shows spinner icon to indicate waiting state */
    @track isLoading = false;
    /* boolean flag to indicate if we found a matching configuration setting and also a lookup value */
    @track blnShowLayout = false;
    @track idParent;
    /* list of field names to be displayed by record view form */
    @track lst_fieldNames = [];
    /* if there are any error messages to be shown */
    @track strMessage;
    /* indicates if error message is visible. set to false by default */
    @track blnIsErrorMessageVisible = false;
    @track strOutputFieldClass = 'slds-form-element__control';

    connectedCallback() {
        this.loadConfig();
    }

    @api loadConfig() {
        /* Making sure if we have record id (fetched from record page), object name and field name (provided by the user) */
        if(this.recordId && this.objectname && this.fieldname) {
            const t0 = performance.now();
            /* Show spinner icon */
            this.isLoading = true;
            /* Apex call to fetch configuration  */
            fetchConfiguration({
                idRecord: this.recordId,
                strObjectType: this.objectname,
                strFieldName: this.fieldname
            }).then(result => {
                /* Check is success variable from result, if it is true, we were able to find a proper config */
                if(result.blnIsSuccess) {
                    /* Set id of the parent lookup relation */
                    this.idParent = result.idRecord;
                    /* deserialize json and set default size as 6. also check if there are any override labels */
                    let list_arrFieldList = JSON.parse(result.strConfigJson);
                    list_arrFieldList.forEach(objEachField => {
                        objEachField.size = objEachField.size ? objEachField.size : '6';
                        objEachField.label = objEachField.overrideLabel ? objEachField.overrideLabel : objEachField.label;
                        objEachField.customStyle = objEachField.api === 'RecordTypeId' ? 'pointer-events: none;' : ''; // If the record type ID is present, make it non-clickable because record types do not have a detail page.
                    });
                    /* set list of fields names */
                    this.lst_fieldNames = list_arrFieldList;
                    /* Check if user decided to show all fields to be underlined */
                    if(this.isfieldsunderlined) {
                        this.strOutputFieldClass = 'slds-form-element__control slds-border_bottom';
                    }
                    /* record view form is ready to be shown */
                    this.blnShowLayout = true;
                    const t1 = performance.now();
                    console.log(`Time taken to render ${this.objectname} dynamic fields ${t1 - t0} milliseconds.`);
                    this.blnIsErrorMessageVisible = false;
                } else {
                    /* If no config is found, do not show layout. show the error message  */
                    this.blnShowLayout = false;
                    this.strMessage = result.strMessage;
                    this.blnIsErrorMessageVisible = true;
                }
                /* set is loading back to false. no waiting state. */
                this.isLoading = false;
            }).catch(error => {
                /* in case of an exception. do not show any layout. set generic exception message */
                this.isLoading = false;
                this.blnShowLayout = false;
                this.strMessage = 'There was an error in fetching the fields. Please try again later.'
                this.blnIsErrorMessageVisible = true;
                console.error('render dynamic fields error ', error);
            });
        } else {
            /* indicates user hasn't configured object name and field name in the app builder */
            this.blnShowLayout = false;
            this.strMessage = 'Object relation is not configured in App Builder. Please edit page and update configuration';
            this.blnIsErrorMessageVisible = true;
            this.isLoading = false;
        }
    }
}