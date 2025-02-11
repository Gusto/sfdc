import { LightningElement, track, api } from 'lwc';

import loadCaseMetadata from '@salesforce/apex/CaseActionsFieldConfigurationController.getCaseRecordTypeAndFieldNames';
import fetchCaseActionConfig from '@salesforce/apex/CaseActionsFieldConfigurationController.returnCaseFieldConfiguration';
import upsertFieldConfig from '@salesforce/apex/CaseActionsFieldConfigurationController.saveCaseFieldConfig';
import retrieveLookupFields from '@salesforce/apex/CaseActionsFieldConfigurationController.returnLookupFields';
import retrieveRelatedObjects from '@salesforce/apex/CaseActionsFieldConfigurationController.returnRelatedObjects';
import retrieveRecordTypeAndFieldList from '@salesforce/apex/CaseActionsFieldConfigurationController.returnRecordTypeAndFieldList';
import upsertRelatedConfig from '@salesforce/apex/CaseActionsFieldConfigurationController.saveRelatedConfig';
import fetchRelatedListConfig from '@salesforce/apex/CaseActionsFieldConfigurationController.getRelatedConfig';



/* Imported Methods from Utility Service */
import { displayToast, navigateToSObject } from 'c/utilityService';

export default class CaseActionFieldConfiguration extends LightningElement {
    
    @api recordId;

    /* Show Spinner Icon */
    @track blnIsLoading = false;
    /* Indicates if user has chosen record type. which means we can show other ui elements below */
    @track blnRecordTypeSelected = false;
    /* list of case record types */
    @track list_caseRecordType = [];
    /* list of case fields */
    @track list_caseFields = [];
    /* list of user selected fields */
    @track list_selectedCaseFields = [];

    /* If field is selected */
    @track blnFieldSelected = false;
    /* If filter criteria is visible */
    @track blnIsFilterCriteriaVisible = false;
    @track list_criteria = [];
    /* Record type that user selected */
    @track strSelectedRecordType = '';
    /* Criteria counter */
    @track intCriteriaCounter = 0;
    /* Warning message that is displayed when a field does not have filter criteria */
    @track blnNoFilterWarningMessage = true;
    /* Case action config record */
    @track objCaseActionFieldConfig = {};
    /* Flag to indicate if an active config is found */
    @track blnIsConfigFound = true;
    /* Selected fields on dual list box */
    @track list_selectedValues = [];
    /* Map of existing fields along with their config json object */
    @track map_existingFields = new Map();
    /* filter value */
    @track strFilterValue;

    /* list of all sObjects across the entire org */
    @track list_sObject = [
        {label: 'Case', value: 'Case'},
        {label: 'Contact', value: 'Contact'},
        {label: 'Account', value: 'Account'},
    ];
    /* Selected SObject Type */
    @track strSelectedSObjectType;

    get sizeOptions() {
        return [
            {label: '3', value: '3'},
            {label: '6', value: '6'},
            {label: '9', value: '9'},
            {label: '12', value: '12'}
        ];
    }

    /* Related List Config Related Track Variables */
    /* Indicates if user selected Related List */
    @track blnIsRelatedList = false;
    /* list of lookup fields related to a parent object */
    @track list_lookupFields = [];
    /* Lookup field */
    @track strLookupField;
    /* Map of related objects */
    @track map_relatedListObjects = [];
    /* flag to indicate if related object is visible */
    @track blnIsRelatedObjectVisible = false;
    /* list of related object for a parent sObject */
    @track list_relatedObjects = [];
    /* related object */
    @track strRelatedObject;
    /* related object label */
    @track strRelatedObjectLabel;

    /* Flag to indicate if user selected related object */
    @track blnIsRelatedObjectSelected = false;
    /* list of related fields */
    @track list_relatedFields = [];
    /* Related field label */
    @track strRelatedFieldLabel;
    
    @track strRelatedField;

    @track relatedFieldSelected = false;
    @track relatedOnFieldLabel;
    @track relatedOnFieldValue;


    @track list_relatedRecordType = [];
    @track list_relatedRecordFields = [];
    @track strSelectedRelatedRecordType;
    @track strSelectedRelatedField;

    @track list_relatedRecordFieldSearch = [];
    @track list_relatedRecordFieldMaster = [];

    @track selectedRelatedField;

    @track blnIsDisplayTypeOutput = false;

    @track strSelectedDisplayType = 'Action';
    @track list_displayTypes = [
        {label: 'Action', value: 'Action'},
        {label: 'Output', value: 'Output'},
        {label: 'Related List', value: 'Related List'}
    ]

    @track list_criteriaOptions = [
        {label: 'Equals', value: 'Equals'},
        {label: 'Not Equals', value: 'Not Equals'},
        {label: 'Contains', value: 'Contains'},
        {label: 'Not Contains', value: 'Not Contains'},
        {label: 'Contains Ignore Case', value: 'Contains Ignore Case'},
        {label: 'Not Contains Ignore Case', value: 'Not Contains Ignore Case'}
    ];


    /* Track fields related to generic auto complete */
    @track strSelectedField;
    @track list_searchFields = [];
    @track list_searchFieldsMaster = [];

    connectedCallback() {
        this.blnIsLoading = true;
        if(this.recordId) {
            loadCaseMetadata({
                idCase: this.recordId
            })
            .then(result => {
                let list_arrCaseRecordTypes = [];
                this.strSelectedSObjectType = result.strSObjectType;
                result.list_caseRecordType.forEach(eachRecordType => {
                    list_arrCaseRecordTypes.push({
                        label: eachRecordType,
                        value: eachRecordType
                    });
                });


                let list_sObjects = [];
                for (let property in result.map_SobjectLabelToApiName) {
                    list_sObjects.push({
                        label: result.map_SobjectLabelToApiName[property],
                        value: property
                    });
                }


                this.list_sObject = list_sObjects;
                this.list_caseRecordType = list_arrCaseRecordTypes;
                this.blnRecordTypeSelected = true;
                this.strSelectedRecordType = result.strRecordType;
                this.retrieveConfig();
                this.blnIsLoading = false;
            })
            .catch(error => {
                // If there is an Exception, Show Error Message on the UI
                this.error = error;
                this.blnIsLoading = false;
            });
        }
    }

    handleRecordTypeSelected(event) {
        this.strSelectedRecordType = event.detail.value;
        this.retrieveConfig();
    }

    handleSObjectTypeSelected(event) {
        this.strSelectedSObjectType = event.detail.value;
        if(!this.blnIsRelatedList) {
            this.retrieveConfig();
        } else {
            this.retrieveRelatedConfig();
            this.blnIsRelatedObjectVisible = false;
            this.strLookupField = '';
            this.list_relatedObjects = [];
            this.list_relatedFields = [];
        }
    }

    handleDisplayTypeSelected(event) {
        this.strSelectedDisplayType = event.detail.value;
        this.blnIsDisplayTypeOutput = this.strSelectedDisplayType === 'Output' ? true : false;
        this.blnIsRelatedList = this.strSelectedDisplayType === 'Related List' ? true : false;
        if(!this.blnIsRelatedList) {
            // Enter this block only when you are not configuring related list
            this.retrieveConfig();
        } else {
            this.retrieveRelatedConfig();
            this.blnIsRelatedObjectVisible = false;
            this.strLookupField = '';
            this.list_relatedObjects = [];
            this.list_relatedFields = [];
        }
    }


    retrieveConfig() {
        this.blnRecordTypeSelected = true;
        this.blnIsLoading = true;
        this.map_existingFields = new Map();
        fetchCaseActionConfig({
            strRecordType: this.strSelectedRecordType,
            strDisplayType: this.strSelectedDisplayType,
            strSObjectType: this.strSelectedSObjectType
        })
        .then(result => {
            if(result.objCaseActionField) {
                this.blnIsConfigFound = true;
                this.objCaseActionFieldConfig = result.objCaseActionField;
                let list_arrSelectedValue = [];
                let jsonArr = JSON.parse(this.objCaseActionFieldConfig.Configuration_Json__c);
                var list_selectedValues = [];
                jsonArr.forEach(eachValue => {
                    list_arrSelectedValue.push({
                        label: eachValue.label,
                        value: eachValue.label,
                        input: eachValue.input,
                        isVisible: eachValue.isVisible,
                        isRequired: eachValue.isRequired,
                        criteriaList: eachValue.criteriaList,
                        size: eachValue.size ? eachValue.size : '6',
                        overrideLabel: eachValue.overrideLabel
                    });
                    eachValue.value = eachValue.label;
                    this.map_existingFields.set(eachValue.label, eachValue);
                    list_selectedValues.push(eachValue.label);
                });
                this.list_selectedValues = list_selectedValues;
                this.list_selectedCaseFields = list_arrSelectedValue;
                this.blnFieldSelected = true;
            } else {
                this.blnIsConfigFound = false;
                this.blnFieldSelected = false;
                this.list_selectedValues = [];
                this.list_selectedCaseFields = [];
            }

            if(result.list_caseFields) {
                this.pouplateFieldList(result);
            }
            this.list_criteria = [];
            this.blnIsFilterCriteriaVisible = false;
            this.strFilterValue = '';
            this.blnIsLoading = false;
        })
        .catch(error => {
            this.blnIsLoading = false;
        });
    }

    handleFieldChange(event) {

        let list_arrSelectedValue = [];
        let strSelectedValue = String(event.detail.value);
        let list_selectedValueSplit = strSelectedValue.split(',');

        if(strSelectedValue) {
            list_selectedValueSplit.forEach(eachValue => {
                if(this.map_existingFields.has(eachValue)) {
                    list_arrSelectedValue.push(this.map_existingFields.get(eachValue));
                } else {
                    let option = {
                        label: eachValue,
                        value: eachValue,
                        input: true,
                        isVisible: true,
                        isRequired: false,
                        size: '6',
                        overrideLabel: ''
                    };
                    list_arrSelectedValue.push(option);
                    this.map_existingFields.set(eachValue, option);
                }
            });
        }
        this.list_selectedCaseFields = list_arrSelectedValue;
        this.blnFieldSelected = strSelectedValue ? true : false;
    }


    handleConditionalDisplayFields(event) {
        this.strFilterValue = event.detail.value;
        this.blnIsFilterCriteriaVisible = true;
        this.intCriteriaCounter = 0;
        this.list_criteria = [];

        if(this.strFilterValue) {
            this.list_selectedCaseFields.forEach(eachField => {
                    if(eachField.label === this.strFilterValue) {
                        if(eachField.criteriaList && eachField.criteriaList.length > 0) {
                            eachField.criteriaList.forEach(eachCriteria => {
                                eachCriteria.key = 'criteria ' + this.intCriteriaCounter;
                                this.intCriteriaCounter  = this.intCriteriaCounter + 1;
                            });

                            this.list_criteria = eachField.criteriaList;
                            this.blnNoFilterWarningMessage = false;
                        } else {
                            this.blnNoFilterWarningMessage = true;
                        }
                    }
            });
        }

        
    }

    handleFilterCriteriaClick() {
        this.blnNoFilterWarningMessage = false;
        let list_arrCriterias = this.list_criteria;
        let criteria = {
            name: '',
            operator: '',
            value:'',
            key: 'criteria ' + this.intCriteriaCounter
        };

        list_arrCriterias.push(criteria);
        this.list_criteria = list_arrCriterias;
        this.intCriteriaCounter  = this.intCriteriaCounter + 1;

        let fieldName = this.strFilterValue;
        this.list_selectedCaseFields.forEach(eachField => {

            if(eachField.label === fieldName) {
                eachField.criteriaList = this.list_criteria;
            }
        });
    }

    handleSubmit() {
        this.blnIsLoading = true;
        let strJSON = JSON.stringify(this.list_selectedCaseFields);
        upsertFieldConfig({
            strRecordType: this.strSelectedRecordType,
            strDisplayType: this.strSelectedDisplayType,
            strSObjectType: this.strSelectedSObjectType,
            strJson: strJSON
        }).then(result => {
            if(result){
                displayToast(this, 'Field configuration successfully saved!', '', 'success', '');
                this.blnIsConfigFound = true;
            } else {
                displayToast(this, 'Update failed. Please try again later', '', 'error', '');
            }
            this.blnIsLoading = false;
            
        }).catch(error => {
            this.blnIsLoading = false;
        })
    }

    handleCancel() {
        this.blnRecordTypeSelected = false;
        this.strSelectedRecordType = '';
    }

    handleToggleChange(event) {
        let label = String(event.target.dataset.label);
        this.list_selectedCaseFields.forEach(eachField => {
            if(eachField.label === label) {
                eachField.input = !event.detail.checked;
                if(event.detail.checked) {
                    eachField.isRequired = false;
                }
            }
        });

        if(this.map_existingFields.has(label)) {
            this.map_existingFields.get(label).input = !event.detail.checked;
            if(event.detail.checked) {
                this.map_existingFields.get(label).isRequired = false;
            }
        }
    }
    
    handleVisibilityChange(event) {
        let label = String(event.target.dataset.label);
        this.list_selectedCaseFields.forEach(eachField => {
            if(eachField.label === label) {
                eachField.isVisible = event.detail.checked;
            }
        });

        if(this.map_existingFields.has(label)) {
            this.map_existingFields.get(label).isVisible = event.detail.checked;
        }
    }

    handleRequiredChange(event) {
        let label = String(event.target.dataset.label);
        this.list_selectedCaseFields.forEach(eachField => {
            if(eachField.label === label) {
                eachField.isRequired = event.detail.checked;
                if(event.detail.checked) {
                    eachField.input = true;
                    eachField.isVisible = event.detail.checked;
                }
            }
        });

        if(this.map_existingFields.has(label)) {
            this.map_existingFields.get(label).isRequired = event.detail.checked;
            if(event.detail.checked) {
                this.map_existingFields.get(label).input = true;
                this.map_existingFields.get(label).isVisible = event.detail.checked;
            }
        }
    }

    handleDelete(event) {


        if(this.strFilterValue) {
            this.list_selectedCaseFields.forEach(eachField => {
                    if(eachField.label === this.strFilterValue) {
                        if(eachField.criteriaList) {
                            

                            let criteriaToDelete = String(event.target.dataset.api);
                            let list_arrCriterias = [];
                            this.list_criteria.forEach(eachCriteria => {
                                if(eachCriteria.key !== criteriaToDelete) {
                                    list_arrCriterias.push(eachCriteria);
                                }
                            });
                            this.list_criteria = list_arrCriterias;
                            if(list_arrCriterias.length > 0) {
                                this.blnNoFilterWarningMessage = false;
                            } else {
                                this.blnNoFilterWarningMessage = true;
                            }

                            eachField.criteriaList = this.list_criteria;
                        } 
                    }
            });
        }
    }

    handleFilterCriteriaChange(event) {
        let key = event.target.dataset.key;
        let name = event.target.dataset.api;
        let value = event.detail.value;

        if(this.strFilterValue) {
            this.list_selectedCaseFields.forEach(eachField => {
                    if(eachField.label === this.strFilterValue) {
                        if(eachField.criteriaList) {
                            eachField.criteriaList.forEach(eachCriteria => {
                                if(eachCriteria.key === key) {
                                    eachCriteria[name] = value;
                                } 
                            });
                        }
                    }
            });
        }
    }

    pouplateFieldList(result) {

        let arrCaseFieldList = [];
        result.list_caseFields.forEach(eachField => {
            arrCaseFieldList.push({
                label: eachField,
                value: eachField
            });
        });
        this.list_caseFields = arrCaseFieldList;
        this.list_searchFields = result.list_caseFields;
        this.list_searchFieldsMaster = result.list_caseFields;
        this.strSelectedField = '';
    }

    handleSizeChange(event) {

        let label = String(event.target.dataset.label);
        this.list_selectedCaseFields.forEach(eachField => {
            if(eachField.label === label) {
                eachField.size = event.detail.value;
            }
        });

        if(this.map_existingFields.has(label)) {
            this.map_existingFields.get(label).size = event.detail.value;
        }
    }

    handleOverrideLabelChange(event) {

        let label = String(event.target.dataset.label);
        this.list_selectedCaseFields.forEach(eachField => {
            if(eachField.label === label) {
                eachField.overrideLabel = event.detail.value;
            }
        });

        if(this.map_existingFields.has(label)) {
            this.map_existingFields.get(label).overrideLabel = event.detail.value;
        }
    }

    handleFilterList(event) {
        let value = event.detail ? event.detail : '';
        // Fields may have larger values. Implementing custom filter and limiting filter results to only 30 values
        // this.list_searchFields = this.list_searchFieldsMaster.filter(function(eachQueue) {
        //     return eachQueue.toLowerCase().indexOf(value.toLowerCase()) !== -1
        // });
        let arrFieldSearchList = [];
        let counter = 0;
        this.list_searchFieldsMaster.forEach(eachField => {
            if(eachField.toLowerCase().includes(value.toLowerCase())) {
                if(counter < 30) {
                    arrFieldSearchList.push(eachField);
                    counter = counter + 1;
                }
            }
        });
        this.list_searchFields = arrFieldSearchList;
    }


    handleRelatedFilterList(event) {
        let value = event.detail ? event.detail : '';
        // Fields may have larger values. Implementing custom filter and limiting filter results to only 30 values
        // this.list_searchFields = this.fieldSearchMasterList.filter(function(eachQueue) {
        //     return eachQueue.toLowerCase().indexOf(value.toLowerCase()) !== -1
        // });
        let arrFieldSearchList = [];
        let counter = 0;
        this.list_relatedRecordFieldMaster.forEach(eachField => {
            if(eachField.toLowerCase().includes(value.toLowerCase())) {
                if(counter < 30) {
                    arrFieldSearchList.push(eachField);
                    counter = counter + 1;
                }
            }
        });
        this.list_relatedRecordFieldSearch = arrFieldSearchList;
    }

    handleRelatedFilterSelected(event) {
        if(event.detail) {
            this.selectedRelatedField = event.detail;
            if(!this.strSelectedRelatedField.includes(this.selectedRelatedField)) {
                this.strSelectedRelatedField.push(this.selectedRelatedField);
            }
        }
    }


    handleFilterSelected(event) {

        if(event.detail) {
            
            this.strSelectedField = event.detail;
            let list_selectedValueSplit = [];
            // form a comma separated list of values
            this.list_selectedCaseFields.forEach(eachField => {
                list_selectedValueSplit.push(eachField.label);
            });
            if(!list_selectedValueSplit.includes(this.strSelectedField)) {
                list_selectedValueSplit.push(this.strSelectedField);
            }
            
            let list_arrSelectedValue = [];
            list_selectedValueSplit.forEach(objEachValue => {
                if(this.map_existingFields.has(objEachValue)) {
                    list_arrSelectedValue.push(this.map_existingFields.get(objEachValue));
                } else {
                    let objOption = {
                        label: objEachValue,
                        value: objEachValue,
                        input: true,
                        isVisible: true,
                        isRequired: false,
                        size: '6',
                        overrideLabel: ''
                    };
                    list_arrSelectedValue.push(objOption);
                    this.map_existingFields.set(objEachValue, objOption);
                }
            });

            this.list_selectedCaseFields = list_arrSelectedValue;
            this.blnFieldSelected = true;
            this.list_selectedValues = list_selectedValueSplit;
        }

    }

    retrieveRelatedConfig() {
        this.blnIsLoading = true;
        retrieveLookupFields({
            strSObject: this.strSelectedSObjectType
        }).then(result => {
            let arrLookupFieldList = [];
            result.forEach(eachLookupField => {
                if(eachLookupField) {
                    eachLookupField = eachLookupField.endsWith('__r') ? eachLookupField.replace('__r','__c') : eachLookupField;
                    arrLookupFieldList.push({
                        label: eachLookupField,
                        value: eachLookupField 
                    });
                }
                
            });
            this.list_lookupFields = arrLookupFieldList;
            this.blnIsLoading = false;
        }).catch(error => {
            this.blnIsLoading = false;
        })
    }

    handleLookupFieldSelected(event) {
        this.strLookupField = event.detail.value;
        this.blnIsLoading = true;
        retrieveRelatedObjects({
            strSObject: this.strLookupField
        }).then(result => {
            this.map_relatedListObjects = result;
            let arrRelatedObjectList = [];
            for (const property in result) {
                arrRelatedObjectList.push({
                    label: property,
                    value: property
                });
            }
            this.list_relatedObjects = arrRelatedObjectList;
            this.blnIsLoading = false;
            this.blnIsRelatedObjectVisible = true;
            this.strRelatedObjectLabel = this.strLookupField + ' related objects';
            
            this.strRelatedObject = '';
            this.strRelatedField = '';
            this.relatedOnFieldValue = '';
            this.relatedRecordTypeVisible = false;
            this.list_relatedRecordType = [];
            this.list_relatedRecordFields = [];
            
        }).catch(error => {
            this.blnIsLoading = false;
        })
    }

    handleRelatedObjectSelected(event) {
        this.blnIsLoading = true;
        this.strRelatedObject = event.detail.value;
        this.strRelatedFieldLabel = this.strLookupField + ' related ' + this.strRelatedObject;

        retrieveRecordTypeAndFieldList({
            strSObject: this.strRelatedObject
        }).then(result => {
            let arrFieldList = [];
            let fieldListFromMap = this.map_relatedListObjects[this.strRelatedObject];
            fieldListFromMap.forEach(eachValue => {
                arrFieldList.push({
                    label: 'Related ' + eachValue.relationshipName,
                    value: eachValue.relationshipName
                });
            });

            if(result.fieldList) {
                let arrFieldList = [];
                result.fieldList.forEach(eachField => {
                    arrFieldList.push({
                        label: eachField,
                        value: eachField
                    })
                });
                this.list_relatedRecordFields = arrFieldList;
                this.list_relatedRecordFieldSearch = result.fieldList;
                this.list_relatedRecordFieldMaster = result.fieldList;
            }

            if(result.recordTypeList) {
                let arrRecordTypeList = [];
                result.recordTypeList.forEach(eachRecordType => {
                    arrRecordTypeList.push({
                        label: eachRecordType,
                        value: eachRecordType
                    })
                });
                this.list_relatedRecordType = arrRecordTypeList;
            }

            this.list_relatedFields = arrFieldList;
            this.blnIsRelatedObjectSelected = true;
            this.relatedFieldSelected = false;
            this.relatedRecordTypeVisible = true;
            this.strSelectedRelatedRecordType = [];
            this.strSelectedRelatedField = [];

            this.blnIsLoading = false;

        }).catch(error => {
            this.blnIsLoading = false;
        });
    }

    handleRelatedFieldSelected(event) {
        this.strRelatedField = event.detail.value;
        this.relatedFieldSelected = true;
        this.relatedOnFieldLabel = 'Related field on ' + this.strRelatedObject;

        let fieldListFromMap = this.map_relatedListObjects[this.strRelatedObject];
        fieldListFromMap.forEach(eachValue => {
            if(eachValue.relationshipName === this.strRelatedField) {
                this.relatedOnFieldValue = eachValue.fieldName;
            }
        });

        this.blnIsLoading = true;
        fetchRelatedListConfig({
            strSObjectType: this.strSelectedSObjectType,
            strDisplayType: 'Related List',
            strLookupField: this.strLookupField,
            strRelatedObject: this.strRelatedObject,
            strRelatedField: this.strRelatedField,
            strRelationshipField: this.relatedOnFieldValue
        }).then(result => {
            if(result && result.length > 0 && result[0].Configuration_Json__c) {
                let wrapper = JSON.parse(result[0].Configuration_Json__c);
                if(wrapper.recordTypeList) {
                    this.strSelectedRelatedRecordType = wrapper.recordTypeList;
                }
                if(wrapper.fieldList) {
                    this.strSelectedRelatedField = wrapper.fieldList;
                }
            } else {
                this.strSelectedRelatedRecordType  = [];
                this.strSelectedRelatedField  = [];

            }
            this.blnIsLoading = false;
        }).catch(error => {
            this.blnIsLoading = false;
        });
    }


    handleSaveRelatedConfig() {

        const allValid = [...this.template.querySelectorAll('lightning-input,lightning-combobox,lightning-dual-listbox')]
        .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
        }, true);

        if(allValid) {
            this.strSelectedRelatedRecordType = this.strSelectedRelatedRecordType ? this.strSelectedRelatedRecordType : [];
            let wrapper = {
                recordTypeList: this.strSelectedRelatedRecordType,
                fieldList: this.strSelectedRelatedField
            };
            let configJson = JSON.stringify(wrapper);
            this.blnIsLoading = true;
            upsertRelatedConfig({
                strSObjectType: this.strSelectedSObjectType,
                strDisplayType: 'Related List',
                strLookupField: this.strLookupField,
                strRelatedObject: this.strRelatedObject,
                strRelatedField: this.strRelatedField,
                strConfigJson: configJson,
                strRelationshipField: this.relatedOnFieldValue
            }).then(result => {
                if(result){
                    displayToast(this, 'Field configuration successfully saved!', '', 'success', '');
                } else {
                    displayToast(this, 'Update failed. Please try again later', '', 'error', '');
                }
                this.blnIsLoading = false;
            }).catch(error => {
                this.blnIsLoading = false;
            });
        }
    }

    handleRelatedRecordTypeChange(event) {
        this.strSelectedRelatedRecordType = event.detail.value;
    }

    handleRelatedFieldChange(event) {
        this.strSelectedRelatedField = event.detail.value;
    }
}