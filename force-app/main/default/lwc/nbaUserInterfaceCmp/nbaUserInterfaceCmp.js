import { LightningElement, track, api } from "lwc";
import { displayToast, getQueryParameters, sendAuraEvent } from "c/utilityService";
import loadUserInterface from "@salesforce/apex/NBAUserInterfaceController.loadUserInterface";
import handleAddBaseObject from "@salesforce/apex/NBAUserInterfaceController.handleAddBaseObject";
import getAllFields from "@salesforce/apex/NBAUserInterfaceController.getAllFields";
import validateSOQL from "@salesforce/apex/NBAUserInterfaceController.validateSOQLQuery";
import handleSaveObjects from "@salesforce/apex/NBAUserInterfaceController.handleSaveObjects";
import getDisplayFieldsFromTemplate from "@salesforce/apex/NBAUserInterfaceController.getDisplayFieldsFromTemplate";
import getRuleData from "@salesforce/apex/NBAUserInterfaceController.getRuleData";

export default class NbaUserInterfaceCmp extends LightningElement {
	// Id of the NBA_Rule_Set__c record - this will be extracted from the URL
	@track idRuleSet;
	// Error message to show in the header
	@track strHeaderErrorMessage;
	// Flag to show/hide the error message in the header
	@track blnHeaderErrorMessageVisible = false;
	// Flag to show/hide the spinner
	@track blnLoading = false;
	// NBA Rule Set object
	@track objRuleSet = {};
	// list of available objects
	@track list_AllObjects = [];
	// list of chose objects
	@track list_ChosenObjects = [];
	// flag to indicate if user has view only access to the component
	@track blnViewOnlyAccess = false;
	// No available object flag
	@track blnNoAvailableObject = false;
	// flag to indicate if object selection is disabled
	@track blnDisableObjectSelection = false;
	// selected base object
	@track strSelectedBaseObject = "";
	@track activeSections = [];
	existingObjectsCount = 0;
	list_OldChosenObjects = [];
	@track isRendered = false;

	// all parameters needed for the auto save feature
	@track autoSaveTimerId = "";
	@track autoSaveMessage = "";
	@track autoSaveSuccessful = false;
	@track autoSaveDuration = 60;
	@track autoSaveEnabled = false;
	@track list_ViewRecordsTemplate = [];
	@track intDelayInMinutes;
	// this is JSON array to store user name and user Id
	@track list_ActiveUsers = [];
	// master list of strings with user names
	@track list_ActiveUsersMasterLabel = [];
	// this is a temporary list to show the top 10 search results
	@track list_ActiveUsersLabel = [];

	//user lookup fieds that needs to be skiped
	list_UserLookupsToSkip = ["ownerid", "createdbyid", "lastmodifiedbyid", "served_user__c"];

	// Filter type is Fields or SOQL query
	get filtertype() {
		return [
			{ label: "Fields", value: "Fields" },
			{ label: "SOQL Query", value: "SOQL Query" }
		];
	}

	// Order by options
	get orderbyoptions() {
		return [
			{ label: "Ascending", value: "ASC" },
			{ label: "Descending", value: "DESC" }
		];
	}

	// Nulls order by options
	get nullsorderby() {
		return [
			{ label: "None", value: "" },
			{ label: "Nulls First", value: "NULLS FIRST" },
			{ label: "Nulls Last", value: "NULLS LAST" }
		];
	}

	get getfieldmapping() {
		return [{ label: "Serving Record Field", value: "Serving Record Field" }];
	}

	get frequencyoptions() {
		return [
			{ label: "Real Time", value: "Real Time" },
			{ label: "Delay", value: "Delay" }
		];
	}

	// Set operator type
	get operatoroptions() {
		return [
			{ label: "Equals to", value: "Equals to" },
			{ label: "Not Equals to", value: "Not Equals to" },
			{ label: "Contains", value: "Contains" },
			{ label: "Does not contain", value: "Does not contain" },
			{ label: "Starts with", value: "Starts with" },
			{ label: "Ends with", value: "Ends with" },
			{ label: "Greater than", value: "Greater than" },
			{ label: "Greater than or equals to", value: "Greater than or equals to" },
			{ label: "Less than", value: "Less than" },
			{ label: "Less than or equals to", value: "Less than or equals to" }
		];
	}

	get usercustomfunctions() {
		return [{ label: "MYSELF", value: "MYSELF" }];
	}

	_fullDateTimeOptions = [
		{ label: "Yesterday", value: "YESTERDAY" },
		{ label: "Today", value: "TODAY" },
		{ label: "Tomorrow", value: "TOMORROW" },
		{ label: "Last Week", value: "LAST_WEEK" },
		{ label: "This Week", value: "THIS_WEEK" },
		{ label: "Next Week", value: "NEXT_WEEK" },
		{ label: "Last Month", value: "LAST_MONTH" },
		{ label: "This Month", value: "THIS_MONTH" },
		{ label: "Next Month", value: "NEXT_MONTH" },
		{ label: "Last 90 Days", value: "LAST_90_DAYS" },
		{ label: "Next 90 Days", value: "NEXT_90_DAYS" },
		{ label: "Last N Days", value: "LAST_N_DAYS:n" },
		{ label: "Next N Days", value: "NEXT_N_DAYS:n" },
		{ label: "N Days Ago", value: "N_DAYS_AGO:n" },
		{ label: "Next N Weeks", value: "NEXT_N_WEEKS:n" },
		{ label: "Last N Weeks", value: "LAST_N_WEEKS:n" },
		{ label: "N Weeks Ago", value: "N_WEEKS_AGO:n" },
		{ label: "Next N Months", value: "NEXT_N_MONTHS:n" },
		{ label: "Last N Months", value: "LAST_N_MONTHS:n" },
		{ label: "N Months Ago", value: "N_MONTHS_AGO:n" },
		{ label: "This Quarter", value: "THIS_QUARTER" },
		{ label: "Last Quarter", value: "LAST_QUARTER" },
		{ label: "Next Quarter", value: "NEXT_QUARTER" },
		{ label: "Next N Quarters", value: "NEXT_N_QUARTERS:n" },
		{ label: "Last N Quarters", value: "LAST_N_QUARTERS:n" },
		{ label: "N Quarters Ago", value: "N_QUARTERS_AGO:n" },
		{ label: "This Year", value: "THIS_YEAR" },
		{ label: "Last Year", value: "LAST_YEAR" },
		{ label: "Next Year", value: "NEXT_YEAR" },
		{ label: "Next N Years", value: "NEXT_N_YEARS:n" },
		{ label: "Last N Years", value: "LAST_N_YEARS:n" },
		{ label: "N Years Ago", value: "N_YEARS_AGO:n" },
		{ label: "This Fiscal Quarter", value: "THIS_FISCAL_QUARTER" },
		{ label: "Last Fiscal Quarter", value: "LAST_FISCAL_QUARTER" },
		{ label: "Next Fiscal Quarter", value: "NEXT_FISCAL_QUARTER" },
		{ label: "Next N Fiscal Quarters", value: "NEXT_N_FISCAL_​QUARTERS:n" },
		{ label: "Last N Fiscal Quarters", value: "LAST_N_FISCAL_​QUARTERS:n" },
		{ label: "N Fiscal Quarters Ago", value: "N_FISCAL_QUARTERS_AGO:n" },
		{ label: "This Fiscal Year", value: "THIS_FISCAL_YEAR" },
		{ label: "Last Fiscal Year", value: "LAST_FISCAL_YEAR" },
		{ label: "Next Fiscal Year", value: "NEXT_FISCAL_YEAR" },
		{ label: "Next N Fiscal Years", value: "NEXT_N_FISCAL_​YEARS:n" },
		{ label: "Last N Fiscal Years", value: "LAST_N_FISCAL_​YEARS:n" },
		{ label: "N Fiscal Years Ago", value: "N_FISCAL_YEARS_AGO:n" }
	];

	_dateTimeOptions = [
		{ label: "N Business Days Ago", value: "N_BUSINESS_DAYS_AGO:n" },
		{ label: "N Business Days Future", value: "N_BUSINESS_DAYS_FUTURE:n" }
	];

	_dateOptions = [
		{ label: "N Business Days Ago", value: "N_D_BUSINESS_DAYS_AGO:n" },
		{ label: "N Business Days Future", value: "N_D_BUSINESS_DAYS_FUTURE:n" }
	];

	@api
	handleOnLoad(afterSave) {
		// get url parameters
		let params = getQueryParameters();
		if (params) {
			this.idRuleSet = params.c__Id;
		}

		// check if rule set Id is available
		if (!this.idRuleSet) {
			this.strHeaderErrorMessage = "Rule set Id unavailable or invalid.";
			this.blnHeaderErrorMessageVisible = true;
		} else {
			this.list_AllObjects = [];
			this.list_ChosenObjects = [];
			this.strSelectedBaseObject = "";
			// Fetch data
			this.blnLoading = true;
			// apex to load user interface - pass NBA Rule Set Id
			loadUserInterface({
				strRuleSetId: this.idRuleSet
			})
				.then((result) => {
					this.blnLoading = false;
					if (result.blnError) {
						displayToast(this, "Error in loading user interface - Reason: " + result.strMessage, "", "error", "");
						return;
					}
					if (result.list_ViewRecordsTemplate) {
						this.list_ViewRecordsTemplate = result.list_ViewRecordsTemplate;
					}
					this.objRuleSet = result.objRuleSet;
					this.intDelayInMinutes = result.objRuleSet.Rule_Frequency_Minutes__c ? result.objRuleSet.Rule_Frequency_Minutes__c : 0;
					let list_tempObjects = [];
					let set_ExistingObjects = new Set();

					if (result.objRuleSet.NBA_Rule_Criteria__r) {
						result.objRuleSet.NBA_Rule_Criteria__r.forEach((criteria) => {
							set_ExistingObjects.add(criteria.Base_Object__c);
						});
					}
					// store object name and api name in a map (key = api name, value = label)
					for (const strObjectAPIName in result.map_AvailableObjects) {
						// create json object to be used in picklist
						if (set_ExistingObjects.has(strObjectAPIName)) {
							continue;
						}
						let object = {
							label: result.map_AvailableObjects[strObjectAPIName] + "",
							value: strObjectAPIName + ""
						};
						list_tempObjects.push(object);
					}

					this.list_AllObjects = list_tempObjects;
					this.blnViewOnlyAccess = !result.blnViewOnlyAccess;
					this.list_ActiveUsers = result.list_ActiveUsers;
					let counter = 0;
					this.list_ActiveUsers.forEach((user) => {
						this.list_ActiveUsersMasterLabel.push(user.Name);
						counter = counter + 1;
						if (counter < 10) {
							this.list_ActiveUsersLabel.push(user.Name);
						}
					});

					// show view only access error message
					if (this.blnViewOnlyAccess) {
						this.strHeaderErrorMessage = "You have view only access to this page.";
						this.blnHeaderErrorMessageVisible = true;
					}
					// disable object selection if no objects are available or if user has view only access
					this.blnDisableObjectSelection = this.list_AllObjects.length === 0 || this.blnViewOnlyAccess;
					// show no available object message
					this.blnNoAvailableObject = this.list_AllObjects.length === 0;

					// send aura event to set tab label as name of the rule set
					sendAuraEvent(this, result, "settablabel");

					if (set_ExistingObjects.size > 0) {
						this.existingObjectsCount = set_ExistingObjects.size;
						this.loadExistingObjects(result);
					}
					this.activeSections = [];

					if (afterSave) {
						displayToast(this, "Configuration saved successfully!", "", "success", "");
					}
				})
				.catch((error) => {
					// in case of error - show error message in the UI
					this.error = error;
					console.log("error", error);
					this.strHeaderErrorMessage = "Error in loading user interface - Reason: " + error?.body?.message || "Unknown error.";
					this.blnHeaderErrorMessageVisible = true;
					this.blnLoading = false;
				});
		}
	}

	addBaseObject(event) {
		// Remove selected object from list_AllObjects variable and add it to list_ChosenObjects
		// check if there objects that have more than 1 order by field
		let blnValidate = true;
		this.list_ChosenObjects.forEach((object) => {
			if (!object.list_OrderByFields) {
				object.list_OrderByFields = [];
			}
			if (object.list_OrderByFields.length > 1) {
				blnValidate = false;
			}
		});

		if (!blnValidate) {
			displayToast(this, "You cannot add a new object if existing base object is ordered by more than 1 field", "", "warning", "");

			let lst_input = [...this.template.querySelectorAll("lightning-combobox[data-field=Base_Object__c]")];
			lst_input.forEach((input) => {
				input.value = null;
			});
		} else {
			let list_tempObjects = [];
			let strSelectedLabel = "";
			this.list_AllObjects.forEach((object) => {
				if (object.value !== event.detail.value) {
					list_tempObjects.push(object);
				} else {
					strSelectedLabel = object.label;
				}
			});
			this.strSelectedBaseObject = event.detail.value;

			// Fetch all fields for the selected base object
			this.blnLoading = true;
			handleAddBaseObject({
				strObjectName: event.detail.value,
				strObjectLabel: strSelectedLabel,
				strRuleSetId: this.objRuleSet.Id
			})
				.then((result) => {
					this.blnLoading = false;

					if (!result.blnError) {
						this.objRuleSet = result.objRuleSet;
						// set value from local variable to track variable
						this.list_AllObjects = list_tempObjects;

						let list_ReferenceFields = [];
						let list_AllFields = [];
						let list_fieldLabels = [];
						let list_fieldMasterLabels = [];

						// reference fields
						for (const strFieldName in result.map_ReferenceFields) {
							// create json object to be used in picklist
							let object = {
								label: result.map_ReferenceFields[strFieldName] + "",
								value: strFieldName.toLowerCase()
							};
							list_ReferenceFields.push(object);
						}

						// all fields
						let counter = 0;
						for (const strFieldName in result.map_AllFields) {
							// create json object to be used in picklist
							let object = {
								label: result.map_AllFields[strFieldName].strFieldLabel + "",
								value: result.map_AllFields[strFieldName].strFieldAPIName + ""
							};

							// show only 10 auto complete options
							if (counter < 10) {
								list_fieldLabels.push(result.map_AllFields[strFieldName].strFieldLabel);
								counter = counter + 1;
							}
							list_fieldMasterLabels.push(result.map_AllFields[strFieldName].strFieldLabel);

							list_AllFields.push(object);
						}
						//add user lookup fields
						let list_userLookupFields = this.buildObjectUserLookupOptions(result.map_AllFields);

						//add field mapping fields
						let list_picklistFields = this.buildObjectPicklistOptions(result.map_AllFields);
						let list_pickListLabels = [];

						list_picklistFields.forEach((picklistField) => {
							list_pickListLabels.push(picklistField.label);
						});

						// show error message or success message
						let object = {
							baseObject: event.detail.value, // api name of the selected object
							objectLabel: strSelectedLabel, // label of the selected object
							referenceFields: list_ReferenceFields, // list of reference fields (lookup and master detail fields)
							title: "Configure filter criteria - " + strSelectedLabel, // title of the card
							filterFieldsList: [], // how many criteria are added
							allFieldsList: list_AllFields, // all fields for the selected object
							emptyFilterFields: true, // indicates if no filter criteria is added
							filterCount: 0, // how many criteria are added
							map_AllFields: result.map_AllFields, // map of api name and field object
							list_fieldLabels: list_fieldLabels, // list of field labels (this is a filtered list based on the search value)
							list_fieldMasterLabels: list_fieldMasterLabels, // this is the master list of field labels,
							criteriaLogic: "", // to store criteria formula (eg 1 AND 2 OR 3),
							selectedOperator: "", // selected operator (eg equals to, not equals to)
							selectedField: "", // API name of the selected field
							selectedValue: "null", // API name of the selected field
							criteriaUniqueId: event.detail.value + "_Criteria", // unique id for the filter
							list_userLookupFields: list_userLookupFields,
							userFieldsAssignment: [],
							list_picklistFields: list_picklistFields,
							blnAddFieldMapping: list_picklistFields.length > 0 && !this.blnViewOnlyAccess ? false : true,
							list_picklistFieldsLabelsMaster: list_pickListLabels,
							fieldMapping: [],
							blnShowFieldMappingTable: false,
							orderByField: {
								selectedField: "", // API name of the selected field
								selectedOrder: "DESC", // selected order (asc, desc)
								selectedFieldLabel: "", // label of the selected field
								list_fieldLabels: list_fieldLabels, // list of field labels (this is a filtered list based on the search value)
								list_fieldMasterLabels: list_fieldMasterLabels, // this is the master list of field labels
								uniqueId: event.detail.value + "_OrderBy", // unique id for the filter
								map_AllFields: result.map_AllFields, // map of api name and field object
								placeholderText: "Search " + strSelectedLabel + " fields", // default value for the placeholder text
								innerTableExists: false, // indicates if reference objects are added
								relationshipDepth: 0, // indicates how many reference objects are added
								innerTables: [], // inner tables list if user adds fields from a reference object
								selectedFieldType: "",
								orderNulls: "NULLS LAST"
							}, // order by field
							displayFieldsList: [], // list of fields to be displayed in the configuration
							displayField: {
								selectedField: "", // API name of the selected field
								selectedFieldLabel: "", // label of the selected field
								list_fieldLabels: list_fieldLabels, // list of field labels (this is a filtered list based on the search value)
								list_fieldMasterLabels: list_fieldMasterLabels, // this is the master list of field labels
								uniqueId: event.detail.value + "_Display", // unique id for the filter
								map_AllFields: result.map_AllFields, // map of api name and field object
								placeholderText: "Search " + strSelectedLabel + " fields", // default value for the placeholder text
								innerTableExists: false, // indicates if reference objects are added
								relationshipDepth: 0, // indicates how many reference objects are added
								innerTables: [] // inner tables list if user adds fields from a reference object
							},
							displayFieldsErrorMessage: true, // flag to show/hide error message for display fields
							talkingPoints: "", // talking points for the object
							soqlQuery: "", // soql query for the object,
							servingField: "id", // serving field for the object - Default it to Id field
							validated: true,
							blnShowCheatSheet: false,
							blnShowGeneratedSOQL: false,
							servingObject: "",
							tempData: {}, // temp data needed when validating and saving changes,
							timeTakentoValidate: 0,
							performanceStatus: "",
							performanceGreen: false,
							performanceRed: false,
							performanceBlue: false,
							orderbyFieldsVisible: true,
							assignRecordOwner: false,
							dblTimeTakenSeconds: 0,
							strPerformance: "",
							list_OrderByFields: [
								{
									selectedField: "", // API name of the selected field
									selectedOrder: "DESC", // selected order (asc, desc)
									selectedFieldLabel: "", // label of the selected field
									list_fieldLabels: list_fieldLabels, // list of field labels (this is a filtered list based on the search value)
									list_fieldMasterLabels: list_fieldMasterLabels, // this is the master list of field labels
									uniqueId: event.detail.value + "_OrderBy_1", // unique id for the filter
									map_AllFields: result.map_AllFields, // map of api name and field object
									placeholderText: "Search " + strSelectedLabel + " fields", // default value for the placeholder text
									innerTableExists: false, // indicates if reference objects are added
									relationshipDepth: 0, // indicates how many reference objects are added
									innerTables: [], // inner tables list if user adds fields from a reference object
									selectedFieldType: "",
									counter: 1,
									orderNulls: "NULLS LAST"
								}
							]
						};

						this.checkNBAFields(object, result);

						let list_ViewRecordsOptions = [];
						this.list_ViewRecordsTemplate.forEach((template) => {
							if (template.Object_API__c == object.baseObject) {
								list_ViewRecordsOptions.push({
									label: template.Label,
									value: template.DeveloperName
								});
							}
						});

						object.list_ViewRecordsOptions = list_ViewRecordsOptions;

						// push value to list of chosen objects to be used in the UI
						this.list_ChosenObjects.push(object);
						this.strHeaderErrorMessage = "";
						this.blnHeaderErrorMessageVisible = false;

						let list_ExistingServingFields = [];
						this.list_ChosenObjects.forEach((eachObj) => {
							if (eachObj.baseObject != object.baseObject) {
								let servingField = eachObj.servingField == "id" ? eachObj.baseObject : eachObj.map_AllFields[eachObj.servingField].strReferenceObject;
								list_ExistingServingFields.push(servingField);
							}
						});

						let objectName = object.baseObject;
						if (list_ExistingServingFields.includes(objectName)) {
							object.isMissingfields = true;
							object.missingFieldsErrorMessage = "Rule with serving object as " + objectName + " already exists.";
						}

						if (!object.isMissingfields) {
							object.servingObject = objectName;
						}
						this.setQueuesAvailable(object, result);
					} else {
						this.strHeaderErrorMessage = "Error in adding base object. Reason - " + result.strMessage;
						this.blnHeaderErrorMessageVisible = true;
					}
				})
				.catch((error) => {
					// in case of error - show error message in the UI
					this.error = error;
					console.log("error", error);
					this.strHeaderErrorMessage = "Error in handle base object add: " + error?.body?.message || "Unknown error.";
					this.blnHeaderErrorMessageVisible = true;
					this.blnLoading = false;
				});

			// show no available object message
			this.blnNoAvailableObject = this.list_AllObjects.length === 0;
			this.blnDisableObjectSelection = this.blnNoAvailableObject;
		}
	}

	// used when users clicks add criteria button
	handleAddFilterCriteria(event) {
		let list_TempChosenObjects = [];
		// iterate through the list of chosen objects and add filter criteria for the selected object
		this.list_ChosenObjects.forEach((object) => {
			if (object.baseObject == event.target.dataset.object) {
				let newFilterCount = object.filterCount + 1;
				object.filterFieldsList.push({
					filterType: "Fields", // filter type whether its fields or SOQL query
					filterId: newFilterCount, // unique id for the filter
					isFilterTypeFields: true, // if this is true, show fields, else show SOQL query
					allFieldsList: object.allFieldsList, // all fields for the selected object
					map_AllFields: object.map_AllFields, // map of api name and field object
					list_fieldLabels: object.list_fieldLabels, // list of field labels (this is a filtered list based on the search value)
					list_fieldMasterLabels: object.list_fieldMasterLabels, // this is the master list of field labels
					innerTables: [], // inner tables list if user adds fields from a reference object
					relationshipDepth: 0, // indicates how many reference objects are added
					innerTableExists: false, // indicates if reference objects are added
					selectedFieldLabel: "", // selected field label
					selectedFieldApiName: "", // api name of the selected field
					placeholderText: "Search " + object.objectLabel + " fields", // default value for the placeholder text
					uniqueId: object.baseObject + "_" + newFilterCount, // unique id for the filter
					operatorUniqueId: object.baseObject + "_Operator_" + newFilterCount, // unique id for the operator combo box
					soqlQuery: "", // soql query text area
					soqlQueryTextAreaUniqueId: object.baseObject + "_SOQL_" + newFilterCount, // unique id for the SOQL query text area
					valueUniqueId: object.baseObject + "_Value_" + newFilterCount // unique id for the value text box
				});
				// this will be used to show/hide error message that no filter criteria is added
				object.emptyFilterFields = false;
				object.filterCount = newFilterCount;
				// reset performance count back to 0 whenver add criteria is clicked
				object.dblTimeTakenSeconds = 0;

				// update criteria formula
				if (object.filterFieldsList.length == 1) {
					object.criteriaLogic = "1";
				} else {
					// if criteria logic does not end with AND + number of filter fields, add it
					if (!object.criteriaLogic.toLowerCase().endsWith("and " + object.filterFieldsList.length)) {
						object.criteriaLogic = object.criteriaLogic + " AND " + object.filterFieldsList.length;
					}
				}
			}
			list_TempChosenObjects.push(object);
		});
		// set value from local variable to track variable
		this.list_ChosenObjects = list_TempChosenObjects;
	}

	// used when users clicks delete criteria button
	handleDeleteFilterCriteria(event) {
		let selectedObject = event.target.dataset.object;
		// iterate through list of chosen objects
		this.list_ChosenObjects.forEach((object) => {
			if (object.baseObject == event.target.dataset.object) {
				let list_TempFilterFields = [];
				// event.target.dataset.id is the Id that we want to remove from the list
				// iterate over filterFieldsList and add all the elements except the one that we want to remove
				let counter = 1;
				let list_TempFieldsCopy = Array.from(object.filterFieldsList);
				list_TempFieldsCopy.forEach((filterField) => {
					if (filterField.filterId != event.target.dataset.id) {
						filterField.filterId = counter;
						filterField.uniqueId = object.baseObject + "_" + counter;
						filterField.operatorUniqueId = object.baseObject + "_Operator_" + counter;
						filterField.soqlQueryTextAreaUniqueId = object.baseObject + "_SOQL_" + counter;
						filterField.valueUniqueId = object.baseObject + "_Value_" + counter;
						counter = counter + 1;
						list_TempFilterFields.push(filterField);
					}
				});
				object.filterFieldsList = list_TempFilterFields;
				object.filterCount = list_TempFilterFields.length;

				// set emptyFilterFields flag to true if no filter criteria is added
				if (list_TempFilterFields.length == 0) {
					object.emptyFilterFields = true;
				}

				let criteriaLogicCmp = this.template.querySelector('[data-uniqueid="' + selectedObject + '_Criteria"]');

				if (!object.emptyFilterFields) {
					criteriaLogicCmp.setCustomValidity("Please adjust this formula to remove the deleted criteria.");
					criteriaLogicCmp.reportValidity();
				} else {
					criteriaLogicCmp.setCustomValidity("");
					criteriaLogicCmp.reportValidity();
				}
			}
		});
	}

	// used when users clicks deleted object button. object will be deleted only when there is no filter criteria added
	handleDeleteObject(event) {
		// delete chosen object from list_ChosenObjects and add them to list_AllObjects
		// delete only if filter list is empty
		let list_TemObjects = [];
		this.list_ChosenObjects.forEach((object) => {
			if (object.baseObject == event.target.dataset.object) {
				if (object.filterFieldsList.length == 0) {
					// add object back to the list of available objects
					list_TemObjects.push({
						label: object.objectLabel,
						value: object.baseObject
					});
					// remove object from list of chosen objects
					this.list_ChosenObjects = this.list_ChosenObjects.filter((obj) => obj.baseObject != event.target.dataset.object);
				} else {
					displayToast(this, "Please delete all filter criteria before removing the object.", "", "warning", "");
				}
			}
		});

		this.list_AllObjects.forEach((object) => {
			list_TemObjects.push(object);
		});

		this.list_AllObjects = list_TemObjects;
		this.strSelectedBaseObject = "";
	}

	// to hide and show soql query and fields based on the filter type
	handleFilterTypeChange(event) {
		// iterate over the chosen objects and update the filter type within the filterFieldsList array
		this.list_ChosenObjects.forEach((object) => {
			// find the base object
			if (object.baseObject == event.target.dataset.object) {
				// initialize an empty list in the beginning
				let list_TempFilterFields = [];
				object.filterFieldsList.forEach((filterField) => {
					// if id matches, set filter type and isFilterTypeFields
					if (filterField.filterId == event.target.dataset.id) {
						filterField.filterType = event.detail.value;
						filterField.isFilterTypeFields = event.detail.value == "Fields";
					}
					// add to temp list
					list_TempFilterFields.push(filterField);
				});
				// set value from local variable to track variable
				object.filterFieldsList = list_TempFilterFields;
			}
		});
	}

	// used to show hyperlinks of objects under the field - when user chooses a lookup field or a master detail field
	handleInnerTableChange(event) {
		if (this.blnViewOnlyAccess) {
			return;
		}
		let selectedUniqueId = event.target.dataset.uniqueid;
		let source = event.target.dataset.source;
		let object = this.list_ChosenObjects.find((object) => object.baseObject == event.target.dataset.object);
		let objFieldResult = {};

		if (source == "fields") {
			object.filterFieldsList.forEach((filterField) => {
				// if id matches, set filter type and isFilterTypeFields
				if (filterField.filterId == event.target.dataset.id) {
					objFieldResult = filterField;
				}
			});
		} else if (source == "orderby") {
			object.list_OrderByFields.forEach((orderByField) => {
				if (orderByField.uniqueId == selectedUniqueId) {
					objFieldResult = orderByField;
				}
			});
		} else if (source == "display") {
			objFieldResult = object.displayField;
		}

		let list_TempInnerTables = [];

		// remove values from inner tables list
		objFieldResult.innerTables.forEach((innerTable) => {
			if (innerTable.position <= event.target.dataset.position) {
				innerTable.selectedField = "Id";
				list_TempInnerTables.push(innerTable);
			}
		});
		// inner tables list is the path of objects that are shown as a hyperlink under the field
		objFieldResult.innerTables = list_TempInnerTables.length == 1 ? [] : list_TempInnerTables;
		objFieldResult.relationshipDepth = list_TempInnerTables.length - 1;
		objFieldResult.selectedFieldLabel = null;

		// find the auto complete component and reset text box
		let autoCompleteCmp = this.template.querySelector("c-auto-complete-cmp[data-uniqueid=" + selectedUniqueId + "]");
		if (autoCompleteCmp) {
			autoCompleteCmp.resetTextBox();
		}
		objFieldResult.innerTableExists = objFieldResult.innerTables.length > 1;
		if (!objFieldResult.innerTableExists) {
			objFieldResult.selectedField = "";
		}
		// change the placeholder text based on the relationship depth
		if (objFieldResult.relationshipDepth == 0) {
			objFieldResult.placeholderText = "Search " + object.objectLabel + " fields";
			objFieldResult.allFieldsList = object.allFieldsList;
			objFieldResult.map_AllFields = object.map_AllFields;
			objFieldResult.list_fieldLabels = object.list_fieldLabels;
			objFieldResult.list_fieldMasterLabels = object.list_fieldMasterLabels;
		} else {
			objFieldResult.placeholderText = "Search " + objFieldResult.innerTables[objFieldResult.innerTables.length - 1].strObjectLabel + " fields";

			objFieldResult.allFieldsList = objFieldResult.innerTables[objFieldResult.innerTables.length - 1].allFieldsList;
			objFieldResult.map_AllFields = objFieldResult.innerTables[objFieldResult.innerTables.length - 1].map_AllFields;
			objFieldResult.list_fieldLabels = objFieldResult.innerTables[objFieldResult.innerTables.length - 1].list_fieldLabels;
			objFieldResult.list_fieldMasterLabels = objFieldResult.innerTables[objFieldResult.innerTables.length - 1].list_fieldMasterLabels;
		}
	}

	// used when users enter a value in the auto complete field
	handleFilterList(event) {
		// variable declaration
		let value = event.detail ? event.detail : "";
		let selectedFilterId = event.target.dataset.id;
		let selectedObject = event.target.dataset.object;
		let source = event.target.dataset.source;
		let selectedUniqueId = event.target.dataset.uniqueid;
		// find the chosen object and the filter object
		let chosenObject = this.list_ChosenObjects.find((object) => object.baseObject == selectedObject);
		let filter = {};

		if (source == "fields") {
			filter = chosenObject.filterFieldsList.find((filter) => filter.filterId == selectedFilterId);
		} else if (source == "orderby") {
			chosenObject.list_OrderByFields.forEach((orderByField) => {
				if (orderByField.uniqueId == selectedUniqueId) {
					filter = orderByField;
				}
			});
		} else if (source == "display") {
			filter = chosenObject.displayField;
		} else if (source === "picklist") {
			filter = chosenObject;
		}

		let list_filterFields = [];
		let list_toSearch = source === "picklist" ? filter.list_picklistFieldsLabelsMaster : filter.list_fieldMasterLabels;
		if (source == "users") {
			let int_fieldId = Number(event.target.dataset.picklist);
			let field = chosenObject.fieldMapping.find((field) => field.fieldId === int_fieldId);
			let int_Index = Number(event.target.dataset.index);
			let mapping = field.mapping.find((mapValue) => mapValue.mappingId === int_Index);
			let option = event.target.dataset.option;
			if (option == "fromValue" && mapping.fromQueueEnabled) {
				list_toSearch = chosenObject.list_Queues;
			} else if (option == "toValue" && mapping.toQueueEnabled) {
				list_toSearch = chosenObject.list_Queues;
			} else {
				list_filterFields = ["[Logged In User]"];
				list_toSearch = this.list_ActiveUsersMasterLabel;
			}
			
			if (field && field.selectedField.toLowerCase() != "ownerid") {
				list_filterFields.push("[Blank/Empty Value]");
			}
			if (option == "fromValue") {
				list_filterFields.push("[Any Value]");
			}
		}

		if (value) {
			// not searching for every character. search only for every 3rd character
			if (value.length % 3 === 0) {
				value = value.trim();
				let counter = 0;
				list_toSearch.forEach((detail) => {
					if (detail.toLowerCase().includes(value.toLowerCase())) {
						if (counter < 10) {
							if (!list_filterFields.includes(detail)) {
								list_filterFields.push(detail);
							}
							counter = counter + 1;
						}
					}
				});
				if (source === "picklist") {
					filter.list_picklistFieldsLabels = list_filterFields;
				} else if (source == "users") {
					this.list_ActiveUsersLabel = list_filterFields;
				} else {
					filter.list_fieldLabels = list_filterFields;
				}
			}
		} else {
			// show only 10 auto complete options when no value is entered
			let counter = 0;
			list_toSearch.forEach((detail) => {
				if (counter < 10) {
					list_filterFields.push(detail);
					counter = counter + 1;
				}
			});
			if (source === "picklist") {
				filter.list_picklistFieldsLabels = list_filterFields;
			} else if (source == "users") {
				this.list_ActiveUsersLabel = list_filterFields;
			} else {
				filter.list_fieldLabels = list_filterFields;
			}
		}
	}

	// used when user selects a field from the auto complete list
	handleFilterSelected(event) {
		// variable declaration
		let value = event.detail ? event.detail : "";
		let selectedFilterId = event.target.dataset.id;
		let selectedObject = event.target.dataset.object;
		let selectedUniqueId = event.target.dataset.uniqueid;
		let source = event.target.dataset.source;
		let autoCompleteCmp = this.template.querySelector("c-auto-complete-cmp[data-uniqueid=" + selectedUniqueId + "]");
		// find the chosen object and the filter object
		let object = this.list_ChosenObjects.find((object) => object.baseObject == selectedObject);
		let filter = {};

		if (source == "fields") {
			filter = object.filterFieldsList.find((filter) => filter.filterId == selectedFilterId);
			object.dblTimeTakenSeconds = 0;
		} else if (source == "orderby") {
			object.list_OrderByFields.forEach((orderByField) => {
				if (orderByField.uniqueId == selectedUniqueId) {
					filter = orderByField;
				}
			});
			object.dblTimeTakenSeconds = 0;
		} else if (source == "display") {
			filter = object.displayField;
		}

		let objField = {};

		// find the field object based on field label.
		// event.detail returns the field label and not the field API name
		for (const strFieldName in filter.map_AllFields) {
			if (filter.map_AllFields[strFieldName].strFieldLabel == value) {
				objField = filter.map_AllFields[strFieldName];
			}
		}

		filter.isDateField = objField.strFieldType == "DATE" || objField.strFieldType == "DATETIME";
		filter.dateOptions =
			objField.strFieldType == "DATE"
				? [...this._fullDateTimeOptions, ...this._dateOptions]
				: objField.strFieldType == "DATETIME"
				? [...this._fullDateTimeOptions, ...this._dateTimeOptions]
				: [];
		filter.isPicklistField = objField.strFieldType == "PICKLIST" || objField.strFieldType == "MULTIPICKLIST";
		filter.isBooleanField = objField.strFieldType == "BOOLEAN";
		filter.list_filterChoices = [];

		if (filter.isPicklistField && objField.list_PicklistValues) {
			let list_filterChoices = [];
			objField.list_PicklistValues.forEach((eachVal) => {
				let obj = {
					label: eachVal,
					value: eachVal
				};
				list_filterChoices.push(obj);
			});
			filter.list_filterChoices = list_filterChoices;
		}

		// if its a reference field, fetch all fields for the selected object
		if (objField.strFieldType == "REFERENCE" && objField.strRelationshipName) {
			// show error message that you cannot add more than 5 levels of relationships
			if (filter.relationshipDepth == 5) {
				displayToast(this, "You have reached the maximum level of adding field relationships.", "", "warning", "");
				return;
			}
			filter.selectedFieldLabel = value;
			filter.selectedField = objField.strFieldAPIName;

			if (objField.list_Relationships && objField.list_Relationships.length > 2) {
				alert(
					"You have selected a reference field that can refer to multiple object types. Salesforce does not allow to add custom/standard fields from this type of reference field. Please select a reference field that refers to a single object type."
				);
				return;
			}

			// Fetch all fields for the selected base object
			this.blnLoading = true;
			getAllFields({
				strObjectName: objField.strReferenceObject
			})
				.then((result) => {
					this.blnLoading = false;
					let list_AllFields = [];
					let list_FieldLabels = [];
					let list_FieldMasterLabels = [];
					let counter = 0;

					for (const strFieldName in result.map_AllFields) {
						// create json object to be used in picklist
						let object = {
							label: result.map_AllFields[strFieldName].strFieldLabel + "",
							value: result.map_AllFields[strFieldName].strFieldAPIName + ""
						};
						list_AllFields.push(object);
						// show only 10 auto complete options
						if (counter < 10) {
							list_FieldLabels.push(result.map_AllFields[strFieldName].strFieldLabel);
							counter = counter + 1;
						}
						// add every field to the master label
						list_FieldMasterLabels.push(result.map_AllFields[strFieldName].strFieldLabel);
					}
					let objFilterResult = {};

					if (source == "fields") {
						// add values to innertables list to show a hyperlink of objects underneth the field
						object.filterFieldsList.forEach((filterField) => {
							// if id matches, set filter type and isFilterTypeFields
							if (filterField.filterId == selectedFilterId) {
								objFilterResult = filterField;
							}
						});
					} else if (source == "orderby") {
						object.list_OrderByFields.forEach((orderByField) => {
							if (orderByField.uniqueId == selectedUniqueId) {
								objFilterResult = orderByField;
							}
						});
					} else if (source == "display") {
						objFilterResult = object.displayField;
					}

					objFilterResult.allFieldsList = list_AllFields;
					objFilterResult.map_AllFields = result.map_AllFields;
					objFilterResult.list_fieldLabels = list_FieldLabels;
					objFilterResult.list_fieldMasterLabels = list_FieldMasterLabels;
					objFilterResult.placeholderText = "Search " + result.strObjectLabel + " fields";
					objFilterResult.isUserLookUpField = result.strObjectLabel == "User";
					filter.selectedField = "Id";
					objFilterResult.relationshipDepth = objFilterResult.relationshipDepth + 1;
					objFilterResult.innerTableExists = true;
					objFilterResult.selectedFieldLabel = null;

					// find the auto complete component and reset text box
					if (autoCompleteCmp) {
						autoCompleteCmp.resetTextBox();
						autoCompleteCmp.setErrorMessage("");
					}

					// if the depth is 1, add the selected object as the first object in the inner tables list
					if (objFilterResult.relationshipDepth == 1) {
						objFilterResult.innerTables.push({
							position: 0,
							strFieldLabel: object.objectLabel
						});
					}

					// add the reference object to the inner tables list
					objFilterResult.innerTables.push({
						position: objFilterResult.relationshipDepth,
						strRelationshipName: objField.strRelationshipName,
						strReferenceObject: objField.strReferenceObject,
						strObjectLabel: result.strObjectLabel,
						allFieldsList: list_AllFields,
						map_AllFields: result.map_AllFields,
						list_fieldLabels: list_FieldLabels,
						list_fieldMasterLabels: list_FieldMasterLabels,
						selectedField: "Id",
						strFieldLabel: objField.strFieldLabel
					});
				})
				.catch((error) => {
					// in case of error - show error message in the UI
					this.error = error;
					console.log("error", error);
					this.strHeaderErrorMessage = "Error in selecting value: " + error?.body?.message || "Unknown error.";
					this.blnHeaderErrorMessageVisible = true;
					this.blnLoading = false;
				});
		} else {
			filter.selectedFieldLabel = value;
			filter.selectedField = objField.strFieldAPIName;
			filter.selectedFieldType = objField.strFieldType;

			if (filter.innerTableExists) {
				filter.innerTables.forEach((innerTable) => {
					if (innerTable.position == filter.innerTables.length - 1) {
						innerTable.selectedField = objField.strFieldAPIName;
					}
				});
			}
			autoCompleteCmp.setErrorMessage("");

			if (source == "display" && objField.strFieldAPIName) {
				let counter = 0;
				let field = object.displayField.map_AllFields[objField.strFieldAPIName];
				if (!object.displayFieldsList) {
					object.displayFieldsList = [];
					counter = counter + 1;
				} else {
					counter = object.displayFieldsList.length + 1;
				}
				let fieldApiName = field.strFieldAPIName;
				let fieldPrefix = "";
				if (object.displayField.innerTableExists) {
					let fieldTemp = "";
					object.displayField.innerTables.forEach((innerTable) => {
						fieldPrefix = fieldPrefix + innerTable.strFieldLabel + " > ";

						if (innerTable.position != 0) {
							if (innerTable.position != object.displayField.innerTables.length - 1) {
								fieldTemp = fieldTemp + innerTable.strRelationshipName + ".";
							} else {
								fieldTemp = fieldTemp + innerTable.strRelationshipName + "." + innerTable.selectedField;
							}
						}
					});

					fieldApiName = fieldTemp;
				} else {
					fieldPrefix = object.objectLabel + " > ";
				}
				fieldApiName = fieldApiName.toLowerCase();
				let existingField = object.displayFieldsList.find((field) => field.selectedFieldAPI == fieldApiName);

				if (existingField) {
					displayToast(this, fieldPrefix + field.strFieldLabel + " is already added", "", "warning", "");
					return;
				}

				object.displayFieldsList.push({
					selectedField: fieldPrefix + field.strFieldLabel,
					selectedFieldAPI: fieldApiName,
					customText: field.strFieldLabel,
					uniqueId: object.baseObject + "_Display_" + counter,
					counter: counter
				});
				object.displayFieldsErrorMessage = object.displayFieldsList.length == 0;

				object.displayField = {
					selectedField: "",
					selectedFieldLabel: "",
					list_fieldLabels: object.list_fieldLabels,
					list_fieldMasterLabels: object.list_fieldMasterLabels,
					uniqueId: object.baseObject + "_Display",
					map_AllFields: object.map_AllFields,
					placeholderText: "Search " + object.objectLabel + " fields",
					innerTableExists: false,
					relationshipDepth: 0,
					innerTables: []
				};
			}
		}
	}

	// action is triggered when serving object is changed
	handleServingObjectChange(event) {
		let selectedObject = event.target.dataset.object;
		let fieldName = event.detail.value.toLowerCase();
		let object = this.list_ChosenObjects.find((object) => object.baseObject == selectedObject);
		let newServingField = "";
		let list_ExistingServingFields = [];
		this.list_ChosenObjects.forEach((eachObj) => {
			if (eachObj.baseObject != object.baseObject) {
				let servingField = eachObj.servingField == "id" ? eachObj.baseObject : eachObj.map_AllFields[eachObj.servingField].strReferenceObject;
				list_ExistingServingFields.push(servingField);
			}
		});

		let objectName = "";
		if (event.detail.value == "id") {
			objectName = object.baseObject;
			newServingField = event.detail.value;
		} else {
			objectName = object.map_AllFields[fieldName].strReferenceObject;
			newServingField = object.map_AllFields[fieldName].strFieldAPIName.toLowerCase();
		}
		let error = false;
		// if serving object already exist - show error message
		if (list_ExistingServingFields.includes(objectName)) {
			object.isMissingfields = true;
			object.missingFieldsErrorMessage = "Rule with serving object as " + objectName + " already exists.";
			error = true;
		}

		if (!error) {
			object.servingField = newServingField;
			object.servingObject = objectName;
			this.blnLoading = true;
			// get all fields from the serving object and check if nba fields are available
			getAllFields({
				strObjectName: objectName
			})
				.then((result) => {
					this.blnLoading = false;
					this.checkNBAFields(object, result);
					//replace the user lookup fieds with the serving object one
					object.list_userLookupFields = this.buildObjectUserLookupOptions(result.map_AllFields);

					let list_picklistFields = this.buildObjectPicklistOptions(result.map_AllFields);
					let list_pickListLabels = [];

					list_picklistFields.forEach((picklistField) => {
						list_pickListLabels.push(picklistField.label);
					});
					object.list_picklistFieldsLabelsMaster = list_pickListLabels;
					object.list_picklistFields = list_picklistFields;
					object.blnAddFieldMapping = object.list_picklistFields.length > 0 && !this.blnViewOnlyAccess ? false : true;
					object.userFieldsAssignment = [];

					this.setQueuesAvailable(object, result);
				})
				.catch((error) => {
					// in case of error - show error message in the UI
					this.error = error;
					console.log("error", error);
					this.strHeaderErrorMessage = "Error in selecting value: " + error?.body?.message || "Unknown error.";
					this.blnHeaderErrorMessageVisible = true;
					this.blnLoading = false;
				});
		}
	}

	// check if the serving object has the NBA fields (served up time, served user, served rule, served other rules and hold out record (if applicable))
	checkNBAFields(object, result) {
		let blnMissingFields = false;
		let list_missingFields = [];
		let missingFieldsErrorMessage = "";

		// check if the object has the right NBA fields and the right data type
		let servedUpField = result.map_AllFields["served_up_time__c"];
		if (!servedUpField || servedUpField.strFieldType != "DATETIME") {
			list_missingFields.push("Served Up Time");
		}

		let servedUserField = result.map_AllFields["served_user__c"];
		if (!servedUserField || (servedUserField.strFieldType != "REFERENCE" && servedUserField.strReferenceObject != "User")) {
			list_missingFields.push("Served User");
		}

		let servedUpRuleField = result.map_AllFields["served_up_rule__c"];
		if (!servedUpRuleField || servedUpRuleField.strFieldType != "PICKLIST") {
			list_missingFields.push("Served Up Rule");
		}

		let servedOtherRulesField = result.map_AllFields["served_other_rules__c"];
		if (servedOtherRulesField) {
			if (this.objRuleSet.NBA_Rule_Set_Configuration__r.Exclude_Served_Other_Rules__c == false && servedOtherRulesField.strFieldType != "MULTIPICKLIST") {
				list_missingFields.push("Served Other Rules");
			}
		}

		// check for hold out only when hold out percentage is greater than 0
		if (this.objRuleSet.Hold_Out_Percentage__c) {
			let holdOutPercentage = result.map_AllFields["hold_out_record__c"];
			if (!holdOutPercentage || holdOutPercentage.strFieldType != "MULTIPICKLIST") {
				list_missingFields.push("Hold Out Record");
			}
		}

		blnMissingFields = list_missingFields.length != 0;

		// if there are missing fields, show error message
		if (blnMissingFields) {
			missingFieldsErrorMessage = "You have chosen an object that has missing NBA fields (" + list_missingFields.join(", ") + ").";
		}

		// set value from local variable to track variable
		object.isMissingfields = blnMissingFields;
		object.missingFieldsErrorMessage = missingFieldsErrorMessage;
	}

	// used when user clicks validate button on each filter criteria
	handleValidateFilterCriteria(event) {
		let selectedFilterId = event.target.dataset.id;
		let selectedObject = event.target.dataset.object;

		let object = this.list_ChosenObjects.find((object) => object.baseObject == selectedObject);
		let filter = object.filterFieldsList.find((filter) => filter.filterId == selectedFilterId);

		if (filter.filterType == "Fields") {
			// first we are checkinf if the necessary fields are populated
			let blnValidate = this.validateEachFilter(selectedObject, filter);

			if (!blnValidate) {
				return;
			}

			// build the query and append LIMIT 0 to it
			let strQuery = "SELECT Id FROM " + selectedObject + " WHERE " + this.buildWhereClause(filter) + " LIMIT 0";
			let valueUniqueId = selectedObject + "_Value_" + event.target.dataset.id;
			let valueCmp = this.template.querySelector('[data-uniqueid="' + valueUniqueId + '"]');

			// Fetch all fields for the selected base object
			this.blnLoading = true;
			validateSOQL({
				strQuery: strQuery,
				strBaseObject: null,
				idRuleSet: null
			})
				.then((result) => {
					this.blnLoading = false;
					if (result.blnError) {
						valueCmp.setCustomValidity(result.strMessage);
						valueCmp.reportValidity();
						return;
					} else {
						valueCmp.setCustomValidity("");
						valueCmp.reportValidity();
					}
				})
				.catch((error) => {
					// in case of error - show error message in the UI
					this.error = error;
					console.log("error", error);
					this.strHeaderErrorMessage = "Error in validating filter criteria: " + error?.body?.message || "Unknown error.";
					this.blnHeaderErrorMessageVisible = true;
					this.blnLoading = false;
				});
		} else {
			// if it is a soql query - use the query directly
			let strQuery = "SELECT Id FROM " + event.target.dataset.object + " WHERE ";
			let uniqueId = selectedObject + "_SOQL_" + event.target.dataset.id;
			let soqlTextAreaCmp = this.template.querySelector('[data-uniqueid="' + uniqueId + '"]');

			let blnValidate = this.validateEachFilter(selectedObject, filter);
			if (!blnValidate) {
				return;
			}

			strQuery = strQuery + filter.soqlQuery + " LIMIT 0";

			// Fetch all fields for the selected base object
			this.blnLoading = true;
			validateSOQL({
				strQuery: strQuery,
				strBaseObject: null,
				idRuleSet: null
			})
				.then((result) => {
					this.blnLoading = false;
					if (result.blnError) {
						soqlTextAreaCmp.setCustomValidity(result.strMessage);
						soqlTextAreaCmp.reportValidity();
						return;
					} else {
						soqlTextAreaCmp.setCustomValidity("");
						soqlTextAreaCmp.reportValidity();
					}
				})
				.catch((error) => {
					// in case of error - show error message in the UI
					this.error = error;
					console.log("error", error);
					this.strHeaderErrorMessage = "Error in validating SOQL query: " + error?.body?.message || "Unknown error.";
					this.blnHeaderErrorMessageVisible = true;
					this.blnLoading = false;
				});
		}
	}

	handleDataTypesChange(event) {
		let selectedFilterId = event.target.dataset.id;
		let selectedObject = event.target.dataset.object;
		let attribute = event.target.dataset.attribute;
		let type = event.target.dataset.type;
		// find the chosen object and the filter object
		let object = this.list_ChosenObjects.find((object) => object.baseObject == selectedObject);
		object.dblTimeTakenSeconds = 0;
		let filter = object.filterFieldsList.find((filter) => filter.filterId == selectedFilterId);
		if (type && type == "checkbox") {
			filter[attribute] = event.target.checked;
		} else {
			filter[attribute] = event.detail.value;
		}
	}

	handleObjectChange(event) {
		let selectedObject = event.target.dataset.object;
		let selectedAttribute = event.target.dataset.attribute;
		let object = this.list_ChosenObjects.find((object) => object.baseObject == selectedObject);
		object[selectedAttribute] = event.detail.value;
		object.dblTimeTakenSeconds = 0;
	}

	// used when user clicks the help section of the object
	toggleCheatSheet(event) {
		let selectedObject = event.target.dataset.object;
		let selectedAttribute = event.target.dataset.attribute;
		let object = this.list_ChosenObjects.find((object) => object.baseObject == selectedObject);
		object[selectedAttribute] = event.target.checked;
	}

	// this is fired when user clicks validate button on the object
	handleValidateObject(event) {
		let selectedObject = event.target.dataset.object;
		let object = this.list_ChosenObjects.find((object) => object.baseObject == selectedObject);
		let type = event.target.dataset.type;
		this.validateObject(object, true, type);
	}

	// validate each filter criteria to check if required fields are populated
	validateObject(object, showNotification, type) {
		let selectedObject = object.baseObject;
		let criteriaLogicCmp = this.template.querySelector('[data-uniqueid="' + selectedObject + '_Criteria"]');
		let orderByCmp = this.template.querySelector('[data-uniqueid="' + selectedObject + '_OrderBy"]');

		// validate if criteria logic is populated
		if (object.criteriaLogic) {
			criteriaLogicCmp.setCustomValidity("");
			criteriaLogicCmp.reportValidity();

			let numberPattern = /[-]{0,1}[\d]*[.]{0,1}[\d]+/g;
			let list_Allnumbers = object.criteriaLogic.match(numberPattern);
			let list_UniqueNumbers = Array.from(new Set(list_Allnumbers));
			// sort in descending order
			list_UniqueNumbers = list_UniqueNumbers.sort(function (a, b) {
				return b - a;
			});

			// check if logic contains any numbers
			if (list_UniqueNumbers.length == 0) {
				criteriaLogicCmp.setCustomValidity("Logic does not contain any numbers.");
				criteriaLogicCmp.reportValidity();
				object.validated = false;
				return false;
			}

			let missingCriteria = false;
			list_UniqueNumbers.forEach((number) => {
				if (object.filterFieldsList.filter((filter) => filter.filterId == number).length == 0) {
					missingCriteria = true;
				}
			});

			// check if logic contains any numbers that do not match any criteria
			if (missingCriteria) {
				criteriaLogicCmp.setCustomValidity("Logic contains a number that does not match any criteria.");
				criteriaLogicCmp.reportValidity();
				object.validated = false;
				return false;
			}

			missingCriteria = false;
			object.filterFieldsList.forEach((filter) => {
				if (!object.criteriaLogic.includes(filter.filterId)) {
					missingCriteria = true;
				}
			});

			// check if logic contains all the criteria
			if (missingCriteria) {
				criteriaLogicCmp.setCustomValidity("Logic does not contain all the criteria.");
				criteriaLogicCmp.reportValidity();
				object.validated = false;
				return false;
			}

			// at thie point criteria logic is valid
			// validate each filter criteria to check if required fields are populated
			let filterValid = true;
			object.filterFieldsList.forEach((filter) => {
				let blnValidate = this.validateEachFilter(selectedObject, filter);
				if (!blnValidate) {
					filterValid = false;
				}
			});

			if (!filterValid) {
				object.validated = false;
				return false;
			}

			// validate if order by field is populated
			if (!object.list_OrderByFields) {
				object.list_OrderByFields = [];
			}

			if (object.list_OrderByFields.length == 0) {
				object.orderByFieldsErrorMessage = true;
				object.validated = false;
				return false;
			}
			object.orderByFieldsErrorMessage = false;

			let list_orderFieldsTemp = [];
			let list_OrderFields = [];
			let orderByValidation = true;
			object.list_OrderByFields.forEach((eachOrderBy) => {
				let orderByFieldCmp = this.template.querySelector('[data-uniqueid="' + eachOrderBy.uniqueId + '"]');

				let orderByField = "";
				if (eachOrderBy.selectedField) {
					orderByFieldCmp.setErrorMessage("");
					orderByField = eachOrderBy.selectedField;

					if (eachOrderBy.innerTableExists) {
						let fieldTemp = "";
						eachOrderBy.innerTables.forEach((innerTable) => {
							if (innerTable.position != 0) {
								if (innerTable.position != eachOrderBy.innerTables.length - 1) {
									fieldTemp = fieldTemp + innerTable.strRelationshipName + ".";
								} else {
									fieldTemp = fieldTemp + innerTable.strRelationshipName + "." + innerTable.selectedField;
								}
							}
						});
						orderByField = fieldTemp;
					}

					if (!list_OrderFields.includes(orderByField)) {
						list_OrderFields.push(orderByField);
						// if user choose to order nulls first or last
						if (eachOrderBy.orderNulls) {
							list_orderFieldsTemp.push(orderByField + " " + eachOrderBy.selectedOrder + " " + eachOrderBy.orderNulls);
						} else {
							list_orderFieldsTemp.push(orderByField + " " + eachOrderBy.selectedOrder);
						}
					} else {
						orderByValidation = false;
						orderByFieldCmp.setErrorMessage("Order by field already exists.");
						return false;
					}
				} else {
					orderByValidation = false;
					orderByFieldCmp.setErrorMessage("Order by field cannot be blank");
					return false;
				}
			});

			if (!orderByValidation) {
				if (showNotification) {
					displayToast(this, "Please fix error messages on highlighted order by fields.", "", "warning", "");
				}
				object.validated = false;
				return false;
			}

			let orderByField = list_orderFieldsTemp.join(", ");

			// at this point all filter critera are populated
			let criteria = object.criteriaLogic;
			criteria = criteria.replace(/\b(\d+)\b/g, "{!$1}");
			let doNotWrap = false;
			list_UniqueNumbers.forEach((number) => {
				let filter = object.filterFieldsList.find((filter) => filter.filterId == number);
				let whereClause = "";
				if (filter.filterType == "Fields") {
					whereClause = this.buildWhereClause(filter);
				} else {
					let queryPattern = /SELECT\s+.*?\s+FROM\s+\w+/i;
					// if query contains a sub query - do not nest it
					if (queryPattern.test(filter.soqlQuery)) {
						doNotWrap = true;
						whereClause = filter.soqlQuery;
					} else {
						whereClause = "(" + filter.soqlQuery + ")";
					}
				}
				criteria = criteria.replaceAll("{!" + number + "}", whereClause);
			});
			if (!doNotWrap) {
				criteria = object.servingField + " != null AND (" + criteria + ")";
			} else {
				criteria = object.servingField + " != null AND " + criteria;
			}

			let limit = type == "validate" ? " LIMIT 0" : " LIMIT 1";
			let strQuery = "SELECT Id FROM " + selectedObject + " WHERE " + criteria + " ORDER BY " + orderByField + " " + limit;

			if (showNotification) {
				this.blnLoading = true;
				this.validateSOQL(strQuery, object, criteriaLogicCmp, showNotification, criteria, orderByField);
			}
			object.tempData = {
				strQuery: strQuery,
				criteriaLogicCmp: criteriaLogicCmp,
				criteria: criteria,
				orderByField: orderByField
			};
			return true;
		} else {
			criteriaLogicCmp.setCustomValidity("Complete this field.");
			criteriaLogicCmp.reportValidity();
			object.validated = false;
			return false;
		}
	}

	// validating each object's soql query
	validateSOQL(strQuery, object, criteriaLogicCmp, showNotification, criteria, orderByField) {
		validateSOQL({
			strQuery: strQuery,
			strBaseObject: object.baseObject,
			idRuleSet: this.objRuleSet.Id
		})
			.then((result) => {
				if (result.blnError) {
					// if error - show error message in the UI
					criteriaLogicCmp.setCustomValidity(result.strMessage);
					criteriaLogicCmp.reportValidity();
					object.performanceStatus = null;
				} else {
					// if success - clear the error message (if any) in the UI and show success notification
					criteriaLogicCmp.setCustomValidity("");
					criteriaLogicCmp.reportValidity();
					if (showNotification) {
						let queryType = "validate";
						if (strQuery.includes("LIMIT 1")) {
							queryType = "performance";
						}
						if (queryType == "validate") {
							displayToast(this, object.objectLabel + " query is successfully validated!", "", "success", "");
						} else {
							object.performanceStatus = "success";
							object.timeTakentoValidate = result.dblTimeTakenSeconds;

							object.performanceGreen = false;
							object.performanceRed = false;
							object.performanceBlue = false;
							object.dblTimeTakenSeconds = result.dblTimeTakenSeconds;
							if (result.dblTimeTakenSeconds < 1) {
								object.performanceGreen = true;
								object.strPerformance = "Excellent";
							} else if (result.dblTimeTakenSeconds < 2) {
								object.performanceBlue = true;
								object.strPerformance = "Good";
							} else {
								object.performanceRed = true;
								object.strPerformance = "Poor";
							}
						}
					}
					object.soqlQuery = criteria + " ORDER BY " + orderByField;
				}

				if (showNotification) {
					this.blnLoading = false;
				}
			})
			.catch((error) => {
				// in case of error - show error message in the UI
				this.error = error;
				console.log("error", error);
				this.strHeaderErrorMessage = "Error in validating filter criteria: " + error?.body?.message || "Unknown error.";
				this.blnHeaderErrorMessageVisible = true;
				this.blnLoading = false;
			});
	}

	// this is used when user clicks save to validate all the changes
	async validateAllChanges(event, autoSave) {
		// there should at least be one object
		if (this.list_ChosenObjects.length == 0 && this.existingObjectsCount == 0) {
			if (!autoSave) {
				displayToast(this, "Please add at least one object.", "", "warning", "");
			} else {
				this.setAutoSaveFailed();
			}
			return;
		} else {
			let blnValidate = true;
			let errorObjectsList = [];
			let activeSectionsTemp = [];

			// if there are missing fields, show error message
			this.list_ChosenObjects.forEach((object) => {
				if (object.isMissingfields) {
					errorObjectsList.push(object.objectLabel);
					blnValidate = false;
				}
			});

			if (!blnValidate) {
				if (!autoSave) {
					displayToast(this, "Please fix the errors on the objects (" + errorObjectsList.join(",") + ")", "", "warning", "");
				} else {
					this.setAutoSaveFailed();
				}
				return;
			}

			blnValidate = true;
			errorObjectsList = [];

			// show error message if there objects with empty criteria
			this.list_ChosenObjects.forEach((object) => {
				if (object.filterFieldsList.length == 0) {
					errorObjectsList.push(object.objectLabel);
					blnValidate = false;
				}
			});

			if (!blnValidate) {
				if (!autoSave) {
					displayToast(this, "Please remove all objects with empty criteria (" + errorObjectsList.join(",") + ")", "", "warning", "");
				} else {
					this.setAutoSaveFailed();
				}
				return;
			}

			blnValidate = true;
			errorObjectsList = [];
			activeSectionsTemp = [];

			const blnValid = [...this.template.querySelectorAll("[data-uniqueid=delayInMinutes")].reduce((validSoFar, inputCmp) => {
				inputCmp.reportValidity();
				return validSoFar && inputCmp.checkValidity();
			}, true);

			if (!blnValid) {
				if (!autoSave) {
					displayToast(this, "Please check rule frequency in minutes", "", "warning", "");
				} else {
					this.setAutoSaveFailed();
				}
				return;
			}

			blnValidate = true;
			errorObjectsList = [];
			activeSectionsTemp = [];

			// show error message if there are labels are populated for the display fields
			this.list_ChosenObjects.forEach((object) => {
				object.displayFieldsList.forEach((field) => {
					if (!field.customText && !errorObjectsList.includes(object.objectLabel)) {
						errorObjectsList.push(object.objectLabel);
						activeSectionsTemp.push(object.baseObject);
						blnValidate = false;
					}
				});
			});

			if (!blnValidate) {
				if (!autoSave) {
					displayToast(this, "Please make sure all fields have a custom label populated to display in the configuration (" + errorObjectsList.join(",") + ")", "", "warning", "");
				} else {
					this.setAutoSaveFailed();
				}

				this.activeSections = activeSectionsTemp;
				return;
			}

			blnValidate = true;
			errorObjectsList = [];
			activeSectionsTemp = [];

			// show error message if there are no display fields selected
			this.list_ChosenObjects.forEach((object) => {
				let displayFieldsCmp = this.template.querySelector('[data-uniqueid="' + object.baseObject + '_Display"]');
				if (object.displayFieldsErrorMessage) {
					displayFieldsCmp.setErrorMessage("Please select atleast 1 field to display.");
					this.blnLoading = false;
					errorObjectsList.push(object.objectLabel);
					activeSectionsTemp.push(object.baseObject);
					blnValidate = false;
				} else {
					displayFieldsCmp.setErrorMessage("");
				}
			});

			if (!blnValidate) {
				if (!autoSave) {
					displayToast(this, "Please select atleast 1 field to display on the objects (" + errorObjectsList.join(",") + ")", "", "warning", "");
				} else {
					this.setAutoSaveFailed();
				}

				this.blnLoading = false;
				this.activeSections = activeSectionsTemp;
				return;
			}

			blnValidate = true;
			errorObjectsList = [];
			activeSectionsTemp = [];
			let orderByFields = new Set();

			this.list_ChosenObjects.forEach((object) => {
				if (object.list_OrderByFields.length == 1) {
					object.list_OrderByFields.forEach((eachOrderBy) => {
						if (eachOrderBy.selectedFieldType) {
							if (eachOrderBy.selectedFieldType && eachOrderBy.selectedOrder) {
								orderByFields.add(eachOrderBy.selectedFieldType + "-" + eachOrderBy.selectedOrder);
								activeSectionsTemp.push(object.baseObject);
							}
						}
					});
				}
			});

			// show error message if data type and sort direction are different for order by fields on all objects
			if (orderByFields.size > 1) {
				if (!autoSave) {
					displayToast(this, "Please make sure data type and the sort order for all order by fields are the same", "", "warning", "");
				} else {
					this.setAutoSaveFailed();
				}
				this.blnLoading = false;
				return;
			}

			const objRuleData = await getRuleData({ idRuleSet: this.objRuleSet.Id });

			blnValidate = true;
			errorObjectsList = [];
			activeSectionsTemp = [];
			let errorMessagePerformance = "";
			// check if performance feature is used before saving object
			this.list_ChosenObjects.forEach((object) => {
				if ((object.strPerformance == "Poor" && objRuleData.Is_Active__c) || !object.dblTimeTakenSeconds || object.dblTimeTakenSeconds == 0) {
					this.blnLoading = false;
					errorObjectsList.push(object.objectLabel);
					activeSectionsTemp.push(object.baseObject);
					blnValidate = false;
				}
			});

			if (!blnValidate) {
				if (!autoSave) {
					displayToast(
						this,
						"Rule Criteria cannot be saved. Performance is not established/updated after editing or Performance is Poor when the Rule is Active. Please refresh Performance and if the Rule is Active, adjust the Rule Criteria as needed until Performance is Good or Excellent for each serving object.",
						"",
						"warning",
						""
					);
				} else {
					this.setAutoSaveFailed();
				}

				this.blnLoading = false;
				this.activeSections = activeSectionsTemp;
				return;
			}

			blnValidate = true;
			errorObjectsList = [];
			activeSectionsTemp = [];

			// once all basic validations are completed - validate each filter criteria and make sure they are valid and populated
			this.list_ChosenObjects.forEach((object) => {
				let blnReturn = this.validateObject(object, false, "validate");
				if (!blnReturn) {
					errorObjectsList.push(object.objectLabel);
					activeSectionsTemp.push(object.baseObject);
					blnValidate = false;
				}

				let emptyFields = this.validateFieldMapping(object);

				if (!emptyFields && !errorObjectsList.includes(object.objectLabel)) {
					errorObjectsList.push(object.objectLabel);
					activeSectionsTemp.push(object.baseObject);
					blnValidate = false;
					return;
				}

				let blnReturnDuplicateFieldMapping = this.validateDuplicateFields(object);
				if (!blnReturnDuplicateFieldMapping && !errorObjectsList.includes(object.objectLabel)) {
					errorObjectsList.push(object.objectLabel);
					activeSectionsTemp.push(object.baseObject);
					blnValidate = false;
					return;
				}

				object.fieldMapping.forEach((field) => {
					let blnReturnFieldMapping = this.validateDuplicatePicklistFromValues(field);
					if (!blnReturnFieldMapping && !errorObjectsList.includes(object.objectLabel)) {
						errorObjectsList.push(object.objectLabel);
						activeSectionsTemp.push(object.baseObject);
						blnValidate = false;
						return;
					}
				});

				let blnReturnEmptyFieldMapping = this.validatePicklistEmptyMapping(object);
				if (!blnReturnEmptyFieldMapping && !errorObjectsList.includes(object.objectLabel)) {
					errorObjectsList.push(object.objectLabel);
					activeSectionsTemp.push(object.baseObject);
					blnValidate = false;
					return;
				}

				let blnDateEntryMapping = this.validateDateEntryMapping(object);
				if (!blnDateEntryMapping && !errorObjectsList.includes(object.objectLabel)) {
					errorObjectsList.push(object.objectLabel);
					activeSectionsTemp.push(object.baseObject);
					blnValidate = false;
					return;
				}

				let blnDateTimeEntryMapping = this.validateDateTimeMapping(object);
				if (!blnDateTimeEntryMapping && !errorObjectsList.includes(object.objectLabel)) {
					errorObjectsList.push(object.objectLabel);
					activeSectionsTemp.push(object.baseObject);
					blnValidate = false;
					return;
				}
			});

			if (!blnValidate) {
				if (!autoSave) {
					displayToast(this, "Please fix error messages on all the objects (" + errorObjectsList.join(",") + ")", "", "warning", "");
				} else {
					this.setAutoSaveFailed();
				}

				this.blnLoading = false;
				this.activeSections = activeSectionsTemp;
				return;
			}

			errorObjectsList = [];
			activeSectionsTemp = [];
			// once all filter criteria are validated, validate the SOQL query for each object
			let list_SuccessObjectsTemp = [];
			let list_CheckedObjects = [];
			if (!autoSave) {
				this.blnLoading = true;
			}

			if (this.list_ChosenObjects.length == 0) {
				this.saveAllChanges(autoSave);
			} else {
				this.list_ChosenObjects.forEach((object) => {
					let strQuery = object.tempData.strQuery;
					let criteriaLogicCmp = object.tempData.criteriaLogicCmp;
					let criteria = object.tempData.criteria;
					let orderByField = object.tempData.orderByField;

					validateSOQL({
						strQuery: strQuery,
						strBaseObject: null,
						idRuleSet: null
					})
						.then((result) => {
							if (result.blnError) {
								// if error - add to error objects list
								criteriaLogicCmp.setCustomValidity(result.strMessage);
								criteriaLogicCmp.reportValidity();

								errorObjectsList.push(object.objectLabel);
								activeSectionsTemp.push(object.baseObject);
							} else {
								// if success - build the query and add to success objects list
								criteriaLogicCmp.setCustomValidity("");
								criteriaLogicCmp.reportValidity();
								object.soqlQuery = criteria + " ORDER BY " + orderByField;
								list_SuccessObjectsTemp.push(object);
							}

							list_CheckedObjects.push(object);

							// if all objects are checked and all of them are successful. Save the changes and send success notificatio
							if (this.list_ChosenObjects.length == list_SuccessObjectsTemp.length) {
								this.blnLoading = false;
								this.saveAllChanges(autoSave);
							}
							// if all objects are checked and some of them failed. Show error message
							if (this.list_ChosenObjects.length == list_CheckedObjects.length && list_SuccessObjectsTemp.length != list_CheckedObjects.length) {
								if (!autoSave) {
									displayToast(this, "Please check and fix the query errors on the objects (" + errorObjectsList.join(",") + ")", "", "warning", "");
								} else {
									this.setAutoSaveFailed();
								}
								this.blnLoading = false;
							}
						})
						.catch((error) => {
							// in case of error - show error message in the UI
							this.error = error;
							console.log("error", error);
							this.strHeaderErrorMessage = "Error in validating filter criteria: " + error?.body?.message || "Unknown error.";
							this.blnHeaderErrorMessageVisible = true;
							this.blnLoading = false;
						});
				});
			}
		}
	}

	saveAllChanges(autoSave) {
		// create a list of minified objects without the fields list
		// below code is to delete all the list fields before saving them to the database
		// this method will be fired after all the validation is done
		let list_MinifiedObjects = JSON.parse(JSON.stringify(this.list_ChosenObjects));
		let intFrequency = 5;
		list_MinifiedObjects.forEach((object) => {
			delete object.allFieldsList;
			delete object.list_fieldLabels;
			delete object.list_fieldMasterLabels;
			delete object.list_userLookupFields;
			delete object.map_AllFields;
			delete object.referenceFields;

			delete object.displayField.innerTables;
			delete object.displayField.allFieldsList;
			delete object.displayField.map_AllFields;
			delete object.displayField.list_fieldLabels;
			delete object.displayField.list_fieldMasterLabels;

			//remove field map related attributes
			delete object.blnShowFieldMappingTable;
			delete object.blnAddFieldMapping;
			delete object.list_picklistFields;

			//remove fieldMapping unused fields
			object.fieldMapping.forEach((field) => {
				delete field.uniqueId;
				delete field.blnAddMapping;
				delete field.blnDisabledDelete;
				delete field.fieldId;
				delete field.fieldLabel;
				delete field.fromOptions;
				delete field.toOptions;
				delete field.mappingSize;
				field.mapping.forEach((mapping) => {
					if (field.strFieldType == "REFERENCE") {
						if (mapping.fromValue) {
							if (mapping.fromQueueEnabled) {
								for (const property in object.map_Queues) {
									if (object.map_Queues[property] == mapping.fromValue) {
										mapping.fromValue = property;
									}
								}
							} else {
								let userId = this.list_ActiveUsers.find((user) => user.Name == mapping.fromValue);
								if (userId) {
									mapping.fromValue = userId.Id;
								}
							}
						}
						if (mapping.toValue) {
							if (mapping.toQueueEnabled) {
								for (const property in object.map_Queues) {
									if (object.map_Queues[property] == mapping.toValue) {
										mapping.toValue = property;
									}
								}
							} else {
								let userId = this.list_ActiveUsers.find((user) => user.Name == mapping.toValue);
								if (userId) {
									mapping.toValue = userId.Id;
								}
							}
						}
					}
					delete mapping.mappingId;
					delete mapping.fromId;
					delete mapping.toId;
				});
			});

			object.list_OrderByFields.forEach((eachOrderBy) => {
				delete eachOrderBy.allFieldsList;
				delete eachOrderBy.map_AllFields;
				delete eachOrderBy.list_fieldLabels;
				delete eachOrderBy.list_fieldMasterLabels;
			});

			object.filterFieldsList.forEach((filter) => {
				delete filter.allFieldsList;
				delete filter.map_AllFields;
				delete filter.list_fieldLabels;
				delete filter.list_fieldMasterLabels;

				if (filter.innerTableExists) {
					filter.innerTables.forEach((eachTable) => {
						delete eachTable.allFieldsList;
						delete eachTable.map_AllFields;
						delete eachTable.list_fieldLabels;
						delete eachTable.list_fieldMasterLabels;
					});
				}
			});
		});

		if (!autoSave) {
			this.blnLoading = true;
		}

		handleSaveObjects({
			idRuleSet: this.objRuleSet.Id,
			strJson: JSON.stringify(list_MinifiedObjects),
			blnAutoSave: autoSave == undefined ? false : autoSave,
			intFrequency: this.intDelayInMinutes
		})
			.then((result) => {
				if (result.blnError) {
					if (!autoSave) {
						displayToast(this, "Error in saving changes: " + result.strMessage, "", "error", "");
					} else {
						this.setAutoSaveFailed();
					}
					return;
				}
				// if no error - call onload and set the notifications flag as true
				if (!autoSave) {
					this.handleOnLoad(true);
				} else {
					this.autoSaveMessage = "Last auto save successful at " + new Date().toLocaleTimeString();
					this.autoSaveSuccessful = true;
				}
			})
			.catch((error) => {
				// in case of error - show error message in the UI
				this.error = error;
				console.log("error", error);
				this.strHeaderErrorMessage = "Error in saving changes: " + error?.body?.message || "Unknown error.";
				this.blnHeaderErrorMessageVisible = true;
				this.blnLoading = false;
			});
	}

	// used when the user clicks on the reset button
	resetChanges() {
		this.handleOnLoad(false);
	}

	// this is used to validate each row of the filter criteria
	validateEachFilter(selectedObject, filter) {
		let blnValid = true;
		let autoCompleteCmp = this.template.querySelector("c-auto-complete-cmp[data-uniqueid=" + filter.uniqueId + "]");

		// if the filter type is fields - validate the operator and the field are populated
		if (filter.filterType == "Fields") {
			let uniqueId = selectedObject + "_Operator_" + filter.filterId;
			let operatorComboBox = this.template.querySelector('[data-uniqueid="' + uniqueId + '"]');

			if (!operatorComboBox.checkValidity()) {
				operatorComboBox.reportValidity();
				blnValid = false;
			}

			if (!filter.selectedField && autoCompleteCmp) {
				autoCompleteCmp.setErrorMessage("Please select a field.");
				blnValid = false;
			}
		} else {
			// if the filter type is SOQL - validate the SOQL query is populated and does not contain ORDER BY or LIMIT clause
			let uniqueId = selectedObject + "_SOQL_" + filter.filterId;
			let soqlTextAreaCmp = this.template.querySelector('[data-uniqueid="' + uniqueId + '"]');

			if (!filter.soqlQuery) {
				soqlTextAreaCmp.setCustomValidity("Complete this field.");
				soqlTextAreaCmp.reportValidity();
				blnValid = false;
			} else {
				let limitPattern = /limit \d+/g;
				// user provided SOQL query should not contain ORDER BY or LIMIT clause
				if (filter.soqlQuery.toLowerCase().includes("order by")) {
					soqlTextAreaCmp.setCustomValidity("SOQL query cannot contain ORDER BY clause.");
					soqlTextAreaCmp.reportValidity();
					blnValid = false;
				} else if (filter.soqlQuery.toLowerCase().match(limitPattern)) {
					soqlTextAreaCmp.setCustomValidity("SOQL query cannot contain LIMIT clause.");
					soqlTextAreaCmp.reportValidity();
					blnValid = false;
				} else {
					soqlTextAreaCmp.setCustomValidity("");
					soqlTextAreaCmp.reportValidity();
				}
			}
		}
		return blnValid;
	}

	// build where clause for the filter
	buildWhereClause(filter) {
		let selectedValue = filter.selectedValue ? filter.selectedValue : "null";
		let relationshipField = "";
		let selectedField = filter.selectedField;

		// if inner table exists - iterate over each record to build the relationship field
		if (filter.innerTableExists) {
			let fieldTemp = "";
			filter.innerTables.forEach((innerTable) => {
				if (innerTable.position != 0) {
					if (innerTable.position != filter.innerTables.length - 1) {
						fieldTemp = fieldTemp + innerTable.strRelationshipName + ".";
					} else {
						fieldTemp = fieldTemp + innerTable.strRelationshipName + "." + innerTable.selectedField;
					}
				}
			});
			relationshipField = fieldTemp;
		}

		let fieldType = filter.map_AllFields[filter.selectedField.toLowerCase()].strFieldType;

		if (fieldType == "BOOLEAN") {
			selectedValue = filter.selectedValue ? "true" : "false";
		}

		if (filter.innerTableExists) {
			selectedField = relationshipField;
		}

		let whereClause = selectedField;

		// add single quotes to the value if the field type is string or similar
		if (
			filter.selectedValue &&
			(fieldType == "STRING" ||
				fieldType == "PICKLIST" ||
				fieldType == "MULTIPICKLIST" ||
				fieldType == "TEXTAREA" ||
				fieldType == "EMAIL" ||
				fieldType == "COMBOBOX" ||
				fieldType == "ID" ||
				fieldType == "PHONE" ||
				fieldType == "URL")
		) {
			if ((selectedValue.includes(",") && (filter.selectedOperator == "Equals to" || filter.selectedOperator == "Not Equals to")) || fieldType == "MULTIPICKLIST") {
				// if field type is multi select picklist - enclose the values in ()
				let list_values = [];
				selectedValue.split(",").forEach(function (value) {
					value = "'" + value + "'";
					list_values.push(value);
				});
				selectedValue = "(" + list_values.join(",") + ")";
			} else {
				selectedValue = "'" + selectedValue + "'";
			}
		}
		// build the query based on the oeprator selected
		if (filter.selectedOperator == "Equals to" && !selectedValue.includes(",")) {
			// multi select picklist - if the value is not null - use includes
			if (fieldType == "MULTIPICKLIST" && selectedValue != "null") {
				whereClause = whereClause + " INCLUDES ";
			} else {
				whereClause = whereClause + " = ";
			}
			whereClause = whereClause + " " + selectedValue;
		} else if (filter.selectedOperator == "Equals to" && selectedValue.includes(",")) {
			// multi select picklist - if the value is not null - use includes
			if (fieldType == "MULTIPICKLIST" && selectedValue != "null") {
				whereClause = whereClause + " INCLUDES ";
			} else {
				whereClause = whereClause + " IN ";
			}
			whereClause = whereClause + " " + selectedValue;
		} else if (filter.selectedOperator == "Not Equals to" && !selectedValue.includes(",")) {
			if (fieldType == "MULTIPICKLIST" && selectedValue != "null") {
				whereClause = whereClause + " EXCLUDES ";
			} else {
				whereClause = whereClause + " != ";
			}
			whereClause = whereClause + " " + selectedValue;
		} else if (filter.selectedOperator == "Not Equals to" && selectedValue.includes(",")) {
			if (fieldType == "MULTIPICKLIST" && selectedValue != "null") {
				whereClause = whereClause + " EXCLUDES ";
			} else {
				whereClause = whereClause + " NOT IN ";
			}
			whereClause = whereClause + " " + selectedValue;
		} else if (filter.selectedOperator == "Contains") {
			whereClause = whereClause + " LIKE " + " '%" + filter.selectedValue + "%'";
		} else if (filter.selectedOperator == "Does not contain") {
			whereClause = " (NOT " + selectedField + " LIKE '%" + filter.selectedValue + "%')";
		} else if (filter.selectedOperator == "Starts with") {
			whereClause = whereClause + " LIKE " + " '" + filter.selectedValue + "%'";
		} else if (filter.selectedOperator == "Ends with") {
			whereClause = whereClause + " LIKE " + " '%" + filter.selectedValue + "'";
		} else if (filter.selectedOperator == "Greater than") {
			whereClause = whereClause + " > ";
			whereClause = whereClause + " " + selectedValue;
		} else if (filter.selectedOperator == "Greater than or equals to") {
			whereClause = whereClause + " >= ";
			whereClause = whereClause + " " + selectedValue;
		} else if (filter.selectedOperator == "Less than") {
			whereClause = whereClause + " < ";
			whereClause = whereClause + " " + selectedValue;
		} else if (filter.selectedOperator == "Less than or equals to") {
			whereClause = whereClause + " <= ";
			whereClause = whereClause + " " + selectedValue;
		}

		return whereClause;
	}

	// this is fired when user deletes a display field
	handleDeleteDisplayField(event) {
		let selectedObject = event.target.dataset.object;
		let counter = event.target.dataset.id;
		// find the object based on base object
		let object = this.list_ChosenObjects.find((object) => object.baseObject == selectedObject);

		// iterate over the display fields list and if the counter does not match the data that we recieve from the event, add it to the temp list
		let list_TempFields = [];
		object.displayFieldsList.forEach((field) => {
			if (field.counter != counter) {
				list_TempFields.push(field);
			}
		});

		// adjust the counter and the unique id after deleting a field
		let increment = 0;
		list_TempFields.forEach((field) => {
			increment = increment + 1;
			field.counter = increment;
			field.uniqueId = object.baseObject + "_Display_" + increment;
		});
		object.displayFieldsList = list_TempFields;
		object.displayFieldsErrorMessage = object.displayFieldsList.length == 0;

		// after deleting if only field is available - show error message
		let displayFieldsCmp = this.template.querySelector('[data-uniqueid="' + object.baseObject + '_Display"]');
		if (object.displayFieldsErrorMessage) {
			displayFieldsCmp.setErrorMessage("Please select at least one field to display.");
		} else {
			displayFieldsCmp.setErrorMessage("");
		}
	}

	// this is fired when users provides a custom label for the display field
	handleCustomLabelChange(event) {
		let selectedObject = event.target.dataset.object;
		let counter = event.target.dataset.id;
		// find the object based on base object
		let object = this.list_ChosenObjects.find((object) => object.baseObject == selectedObject);

		// set custom text that we get from the event to the display field
		object.displayFieldsList.forEach((field) => {
			if (field.counter == counter) {
				field.customText = event.detail.value;
			}
		});
	}

	// fires when ASC or DESC ahnges changes for order by field
	handleOrderByTypeChange(event) {
		let selectedObject = event.target.dataset.object;
		let selectedUniqueId = event.target.dataset.uniqueid;
		let object = this.list_ChosenObjects.find((object) => object.baseObject == selectedObject);

		object.list_OrderByFields.forEach((orderByField) => {
			if (orderByField.uniqueId == selectedUniqueId) {
				orderByField.selectedOrder = event.detail.value;
			}
		});
		object.dblTimeTakenSeconds = 0;
	}

	// fires when nulls first or nulls last changes changes for order by field
	handleOrderByNullsChange(event) {
		let selectedObject = event.target.dataset.object;
		let selectedUniqueId = event.target.dataset.uniqueid;
		let object = this.list_ChosenObjects.find((object) => object.baseObject == selectedObject);

		object.list_OrderByFields.forEach((orderByField) => {
			if (orderByField.uniqueId == selectedUniqueId) {
				orderByField.orderNulls = event.detail.value;
			}
		});
		object.dblTimeTakenSeconds = 0;
	}

	buildObjectUserLookupOptions(objectFields) {
		//getting User Lookups for the new base object
		let list_userLookupOptions = [];
		for (const fieldName in objectFields) {
			this.validateUserLookupField(objectFields[fieldName], list_userLookupOptions);
		}
		return list_userLookupOptions;
	}

	buildObjectsUserLookupOptions(objectsFields) {
		//getting User Lookups for all the objects
		let list_userLookupOptions = {};
		for (const obj in objectsFields) {
			list_userLookupOptions[obj] = [];
			for (const fieldName in objectsFields[obj]) {
				this.validateUserLookupField(objectsFields[obj][fieldName], list_userLookupOptions[obj]);
			}
		}
		return list_userLookupOptions;
	}

	validateUserLookupField(field, list_userLookupOptions) {
		if (field.strFieldType === "REFERENCE" && field.strReferenceObject === "User" && !this.list_UserLookupsToSkip.includes(field.strFieldAPIName)) {
			list_userLookupOptions.push({ label: field.strFieldLabel, value: field.strFieldAPIName });
		}
	}

	//build the picklist fields for an object
	buildObjectPicklistOptions(objectFields) {
		let list_picklistOptions = [];
		for (const fieldName in objectFields) {
			this.validatePicklistField(objectFields[fieldName], list_picklistOptions);
		}
		return list_picklistOptions;
	}

	//build the picklists fields for a list of objects
	buildObjectsPicklistOptions(objectsFields) {
		//getting Picklist fields for all the objects
		let list_picklistOptions = {};
		for (const obj in objectsFields) {
			list_picklistOptions[obj] = [];
			for (const fieldName in objectsFields[obj]) {
				this.validatePicklistField(objectsFields[obj][fieldName], list_picklistOptions[obj]);
			}
		}
		return list_picklistOptions;
	}

	//validate from a list of fields which ones are picklist and adds the Any and Empty value properly
	validatePicklistField(field, list_picklistOptions) {
		if (field.strFieldType === "PICKLIST" && field.strFieldAPIName != "served_up_rule__c") {
			let list_FromOptions = [];
			let list_ToOptions = [];
			list_FromOptions.push({ label: "[Any Value]", value: "[Any Value]" });
			list_FromOptions.push({ label: "[Blank/Empty Value]", value: "[Blank/Empty Value]" });
			list_ToOptions.push({ label: "[Blank/Empty Value]", value: "[Blank/Empty Value]" });
			field.list_PicklistValues.forEach((strOption) => {
				list_FromOptions.push({ label: strOption, value: strOption });
				list_ToOptions.push({ label: strOption, value: strOption });
			});
			list_picklistOptions.push({
				label: field.strFieldLabel,
				value: field.strFieldAPIName,
				fromOptions: list_FromOptions,
				toOptions: list_ToOptions,
				placeholder: "Select picklist value",
				strFieldType: field.strFieldType
			});
		} else if (field.strFieldType == "REFERENCE" && field.strReferenceObject == "User" && field.strFieldAPIName != "served_user__c" && field.blnUpdateable) {
			let list_FromOptions = [];
			let list_ToOptions = [];
			list_FromOptions.push({ label: "[Any Value]", value: "[Any Value]" });
			list_FromOptions.push({ label: "[Logged In User]", value: "[Logged In User]" });
			list_FromOptions.push({ label: "[Blank/Empty Value]", value: "[Blank/Empty Value]" });
			if (field.blnNillable) {
				list_ToOptions.push({ label: "[Blank/Empty Value]", value: "[Blank/Empty Value]" });
			}
			list_ToOptions.push({ label: "[Logged In User]", value: "[Logged In User]" });
			this.list_ActiveUsers.forEach((user) => {
				list_FromOptions.push({ label: user.Name, value: user.Id });
				list_ToOptions.push({ label: user.Name, value: user.Id });
			});
			list_picklistOptions.push({
				label: field.strFieldLabel,
				value: field.strFieldAPIName,
				fromOptions: list_FromOptions,
				toOptions: list_ToOptions,
				placeholder: "Select user value",
				strFieldType: field.strFieldType,
				strReferenceObject: field.strReferenceObject
			});
		} else if (field.strFieldType == "BOOLEAN" && field.blnUpdateable) {
			let list_FromOptions = [];
			let list_ToOptions = [];
			let list_options = ["[Any Value]", "true", "false"];
			list_options.forEach((strOption) => {
				list_FromOptions.push({ label: strOption, value: strOption });
				if (strOption != "[Any Value]") {
					list_ToOptions.push({ label: strOption, value: strOption });
				}
			});
			list_picklistOptions.push({
				label: field.strFieldLabel,
				value: field.strFieldAPIName,
				fromOptions: list_FromOptions,
				toOptions: list_ToOptions,
				placeholder: "Select boolean value",
				strFieldType: field.strFieldType
			});
		} else if (field.strFieldType == "DATE" && field.blnUpdateable) {
			let list_FromOptions = [];
			let list_ToOptions = [];
			let list_FromValues = ["[Any Value]", "[Blank/Empty Value]", "[Future Date]", "[Prior Date]", "[Today]"];
			let list_ToValues = ["[Blank/Empty Value]", "[Today]", "[Today + N Business Days]", "[Today - N Business Days]", "[Today + N Days]", "[Today - N Days]"];

			list_FromValues.forEach((strOption) => {
				list_FromOptions.push({ label: strOption, value: strOption });
			});

			list_ToValues.forEach((strOption) => {
				list_ToOptions.push({ label: strOption, value: strOption });
			});

			list_picklistOptions.push({
				label: field.strFieldLabel,
				value: field.strFieldAPIName,
				fromOptions: list_FromOptions,
				toOptions: list_ToOptions,
				placeholder: "Select date value",
				strFieldType: field.strFieldType
			});
		} else if (field.strFieldType == "DATETIME" && field.blnUpdateable && field.strFieldAPIName != "served_up_time__c") {
			let list_FromOptions = [];
			let list_ToOptions = [];
			let list_FromValues = ["[Any Value]", "[Blank/Empty Value]", "[Future Date]", "[Prior Date]", "[Today]", "[Now]"];
			let list_ToValues = ["[Blank/Empty Value]", "[Now]", "[Now + N Business Days/Hours]", "[Now - N Business Days/Hours]", "[Now + N Days/Hours]", "[Now - N Days/Hours]"];

			list_FromValues.forEach((strOption) => {
				list_FromOptions.push({ label: strOption, value: strOption });
			});

			list_ToValues.forEach((strOption) => {
				list_ToOptions.push({ label: strOption, value: strOption });
			});

			list_picklistOptions.push({
				label: field.strFieldLabel,
				value: field.strFieldAPIName,
				fromOptions: list_FromOptions,
				toOptions: list_ToOptions,
				placeholder: "Select date value",
				strFieldType: field.strFieldType
			});
		}
	}

	// load data for existing objects
	loadExistingObjects(result) {
		let list_TempObjects = result.list_Requests;
		let list_TempOldObjects = result.list_OldRequests;
		let map_Objects = new Map();

		// set data for current criteria and previous criteria
		list_TempObjects.forEach((object) => {
			//fieldMapping
			this.setExistingFieldMapping(object, result);
			this.setExistingData(object, result, map_Objects);
		});

		list_TempOldObjects.forEach((object) => {
			this.setExistingFieldMapping(object, result);
			this.setExistingData(object, result, map_Objects);
		});
		this.list_ChosenObjects = list_TempObjects;
		this.list_OldChosenObjects = list_TempOldObjects;
	}

	//creates the proper attributes for the Field Mapping tab
	setExistingFieldMapping(object, result) {
		//user lookup fields
		let list_userLookupFields = this.buildObjectsUserLookupOptions(result.map_ObjectFields);
		object.list_userLookupFields = list_userLookupFields[object.servingObject];
		object.userFieldsAssignment = object.userFieldsAssignment === undefined || object.userFieldsAssignment.length === 0 ? [] : object.userFieldsAssignment;
		//field mapping
		let list_picklistFields = this.buildObjectsPicklistOptions(result.map_ObjectFields);
		list_picklistFields[object.servingObject].sort((a, b) => a.label.localeCompare(b.label));
		object.list_picklistFields = list_picklistFields[object.servingObject];
		let picklistLabel = [];
		let picklistLabelMaster = [];
		let int_index = 0;
		list_picklistFields[object.servingObject].forEach((item) => {
			if (int_index <= 10) {
				picklistLabel.push(item.label);
			}
			picklistLabelMaster.push(item.label);
			int_index++;
		});
		object.list_picklistFieldsLabels = picklistLabel;
		object.list_picklistFieldsLabelsMaster = picklistLabelMaster;
		object.blnAddFieldMapping = object.list_picklistFields.length > 0 && !this.blnViewOnlyAccess ? false : true;
		object.blnQueuesAvailable = result.blnQueuesAvailable;
		this.setQueuesAvailable(object, result);
		let uniqueIndex = 1;
		//iterates over the existing field mapping to add the attributes needed for the UI
		if (object.fieldMapping !== undefined) {
			object.fieldMapping.forEach((field) => {
				let metaField = object.list_picklistFields.find((metaField) => metaField.value === field.selectedField);
				//attribute to be the uniqueId of the field
				field.uniqueId = "field-" + uniqueIndex;
				//attribute to disable the 'add mapping option'
				field.blnAddMapping = !this.blnViewOnlyAccess ? false : true;
				//attribute to disable the 'delete mapping'
				field.blnDisabledDelete = this.blnViewOnlyAccess ? true : field.mapping.length <= 1 ? true : false;
				//attribute to show the index of the table
				field.fieldId = uniqueIndex;
				//attribute to show the label field in the component
				field.fieldLabel = field.selectedField;
				//attribute to show the from options in each picklist value from
				field.fromOptions = object.list_picklistFields.find((picklist) => picklist.value === field.selectedField).fromOptions;
				//attribute to show the to options in each picklist value to
				field.toOptions = object.list_picklistFields.find((picklist) => picklist.value === field.selectedField).toOptions;
				//attribute for rowspan in the table
				field.mappingSize = field.mapping.length + 1;
				//attribute for persist in the DB
				field.selectedField = field.selectedField;
				//attribute for show the input label
				field.selectedFieldLabel = metaField.label;
				//attribute for the index mapping values
				let int_mappingSize = 0;
				//add the mapping attributes needed for the UI
				field.mapping.forEach((mapping) => {
					//attribute of the mapping
					mapping.mappingId = int_mappingSize;
					//attribute of the fromId for the combobox
					mapping.fromId = object.servingObject + "field-" + uniqueIndex + "-from-" + int_mappingSize;
					//attribute of the toId for the combobox
					mapping.toId = object.servingObject + "field-" + uniqueIndex + "-to-" + int_mappingSize;
					int_mappingSize++;
					if (metaField.strFieldType == "REFERENCE" && metaField.strReferenceObject == "User") {
						let list_options = ["fromValue", "toValue"];
						list_options.forEach((option) => {
							if (mapping[option]) {
								if (mapping[option].startsWith("005")) {
									let obj = this.list_ActiveUsers.find((user) => user.Id === mapping[option]);
									mapping[option] = obj ? obj.Name : "";
								} else if (mapping[option].startsWith("00G")) {
									for (const property in object.map_Queues) {
										if (property == mapping[option]) {
											mapping[option] = object.map_Queues[property];
										}
									}
								}
							}
						});
					}
					if ((metaField.strFieldType == "DATE" && mapping.toValue.includes("Today ")) || (metaField.strFieldType == "DATETIME" && mapping.toValue.includes("Now "))) {
						mapping.isDateField = true;
						mapping.isDateTimeField = metaField.strFieldType == "DATETIME";
					}
				});
				field.strFieldType = metaField.strFieldType;
				field.isSearchable = metaField.strFieldType == "REFERENCE";
				field.isCheckbox = metaField.strFieldType == "BOOLEAN";
				field.isQueueEligible = metaField.value.toLowerCase() == "ownerid" && object.blnQueuesAvailable;
				uniqueIndex++;
			});
		}
		//attribute list of all the existing mappings
		object.fieldMapping = object.fieldMapping !== undefined && object.fieldMapping.length > 0 ? object.fieldMapping : [];
		//attribute to show or not the field mapping
		object.blnShowFieldMappingTable = object.fieldMapping !== undefined && object.fieldMapping.length > 0 ? true : false;
	}

	setExistingData(object, result, map_Objects) {
		// show data from existing objects
		// json version in the backend is minified version. using this method to get data from the record and add more details
		if (object.baseObject) {
			let sObject = result.map_ObjectFields[object.baseObject];
			if (map_Objects.has(object.baseObject)) {
				let tempobject = map_Objects.get(object.baseObject);
				object = this.setExistingListFields(object, tempobject);
			} else {
				let tempobject = this.createNewListFields(object, sObject);
				map_Objects.set(object.baseObject, tempobject);
				object = this.setExistingListFields(object, tempobject);
			}

			// set talking points from the field to the json attribute
			if (result.objRuleSet.NBA_Rule_Criteria__r) {
				result.objRuleSet.NBA_Rule_Criteria__r.forEach((criteria) => {
					if (criteria.Base_Object__c == object.baseObject) {
						object.talkingPoints = criteria.Talking_Points__c;
						object.strPerformance = criteria.Performance__c;
					}
				});
			}

			// set template options to add fields for the view records section
			let list_ViewRecordsOptions = [];
			this.list_ViewRecordsTemplate.forEach((template) => {
				if (template.Object_API__c == object.baseObject) {
					list_ViewRecordsOptions.push({
						label: template.Label,
						value: template.DeveloperName
					});
				}
			});

			object.list_ViewRecordsOptions = list_ViewRecordsOptions;
		}

		// set attributes on the object
		object.validated = true;
		object.blnShowCheatSheet = false;
		object.blnShowGeneratedSOQL = false;
		object.title = "Configure filter criteria - " + object.objectLabel;
		object.filterFieldsList = object.filterFieldsList;
		object.emptyFilterFields = object.filterFieldsList.length == 0;
		object.filterCount = object.filterFieldsList.length;
		object.criteriaUniqueId = object.baseObject + "_Criteria";
		object.displayFieldsErrorMessage = object.displayFieldsList.length == 0;
		object.servingField = object.servingField.toLowerCase();

		// set data for each filter
		let counter = 1;
		object.filterFieldsList.forEach((filter) => {
			filter.filterId = counter;
			filter.isFilterTypeFields = filter.filterType == "Fields";
			filter.relationshipDepth = filter.innerTables.length == 0 ? 0 : filter.innerTables.length - 1;
			filter.innerTableExists = filter.innerTables.length > 1;
			filter.isDateField = filter.selectedFieldType == "DATE" || filter.selectedFieldType == "DATETIME";
			filter.dateOptions =
				filter.selectedFieldType == "DATE"
					? [...this._fullDateTimeOptions, ...this._dateOptions]
					: filter.selectedFieldType == "DATETIME"
					? [...this._fullDateTimeOptions, ...this._dateTimeOptions]
					: [];
			filter.isPicklistField = filter.selectedFieldType == "PICKLIST" || filter.selectedFieldType == "MULTIPICKLIST";

			if (filter.selectedFieldType == "BOOLEAN") {
				filter.isBooleanField = filter.selectedFieldType == "BOOLEAN";
				filter.selectedValue = filter.selectedValue == "true" ? true : false;
			}

			if (filter.innerTableExists) {
				let strObjectLabel = filter.innerTables[filter.innerTables.length - 1].strObjectLabel;
				filter.placeholderText = "Search " + strObjectLabel + " fields";
				filter.isUserLookUpField = strObjectLabel == "User";
				// set list fields for each row of the filter
				let innerTableCounter = 0;
				filter.innerTables.forEach((innerTable) => {
					innerTable.position = innerTableCounter;
					if (innerTableCounter != 0) {
						if (map_Objects.has(innerTable.strReferenceObject)) {
							let tempobject = map_Objects.get(innerTable.strReferenceObject);
							innerTable = this.setExistingListFields(innerTable, tempobject);
						} else {
							let sObject = result.map_ObjectFields[innerTable.strReferenceObject];
							let tempobject = this.createNewListFields(object, sObject);
							map_Objects.set(innerTable.strReferenceObject, tempobject);
							innerTable = this.setExistingListFields(innerTable, tempobject);
						}
					}
					innerTableCounter = innerTableCounter + 1;
				});
			} else {
				// if inner table does not exist, set the fields for the main object
				filter.placeholderText = "Search " + object.objectLabel + " fields";
				filter.allFieldsList = object.allFieldsList; // all fields for the selected object
				filter.map_AllFields = object.map_AllFields;
				filter.list_fieldLabels = object.list_fieldLabels;
				filter.list_fieldMasterLabels = object.list_fieldMasterLabels;
			}
			// set list fields
			if (filter.innerTableExists) {
				filter.allFieldsList = filter.innerTables[filter.innerTables.length - 1].allFieldsList; // all fields for the selected object
				filter.map_AllFields = filter.innerTables[filter.innerTables.length - 1].map_AllFields;
				filter.list_fieldLabels = filter.innerTables[filter.innerTables.length - 1].list_fieldLabels;
				filter.list_fieldMasterLabels = filter.innerTables[filter.innerTables.length - 1].list_fieldMasterLabels;
			}

			let objField = {};

			for (const strFieldName in filter.map_AllFields) {
				if (filter.map_AllFields[strFieldName].strFieldLabel == filter.selectedFieldLabel) {
					objField = filter.map_AllFields[strFieldName];
				}
			}

			if (filter.isPicklistField && objField.list_PicklistValues) {
				let list_filterChoices = [];
				objField.list_PicklistValues.forEach((eachVal) => {
					let obj = {
						label: eachVal,
						value: eachVal
					};
					list_filterChoices.push(obj);
				});
				filter.list_filterChoices = list_filterChoices;
			}

			// set unique id for each filter
			filter.uniqueId = object.baseObject + "_" + counter;
			filter.operatorUniqueId = object.baseObject + "_Operator_" + counter;
			filter.soqlQueryTextAreaUniqueId = object.baseObject + "_SOQL_" + counter;
			filter.valueUniqueId = object.baseObject + "_Value_" + counter;

			counter = counter + 1;
		});

		counter = 1;
		object.list_OrderByFields.forEach((eachOrderByField) => {
			eachOrderByField.counter = counter;
			eachOrderByField.relationshipDepth = eachOrderByField.innerTables.length == 0 ? 0 : eachOrderByField.innerTables.length - 1;
			eachOrderByField.innerTableExists = eachOrderByField.innerTables.length > 1;

			if (eachOrderByField.innerTableExists) {
				eachOrderByField.placeholderText = "Search " + eachOrderByField.innerTables[eachOrderByField.innerTables.length - 1].strObjectLabel + " fields";

				// set list fields for each row of the eachOrderByField
				let innerTableCounter = 0;
				eachOrderByField.innerTables.forEach((innerTable) => {
					innerTable.position = innerTableCounter;
					if (innerTableCounter != 0) {
						if (map_Objects.has(innerTable.strReferenceObject)) {
							let tempobject = map_Objects.get(innerTable.strReferenceObject);
							innerTable = this.setExistingListFields(innerTable, tempobject);
						} else {
							let sObject = result.map_ObjectFields[innerTable.strReferenceObject];
							let tempobject = this.createNewListFields(object, sObject);
							map_Objects.set(innerTable.strReferenceObject, tempobject);
							innerTable = this.setExistingListFields(innerTable, tempobject);
						}
					}
					innerTableCounter = innerTableCounter + 1;
				});
			} else {
				// if inner table does not exist, set the fields for the main object
				eachOrderByField.placeholderText = "Search " + object.objectLabel + " fields";
				eachOrderByField.allFieldsList = object.allFieldsList; // all fields for the selected object
				eachOrderByField.map_AllFields = object.map_AllFields;
				eachOrderByField.list_fieldLabels = object.list_fieldLabels;
				eachOrderByField.list_fieldMasterLabels = object.list_fieldMasterLabels;
			}
			// set list fields
			if (eachOrderByField.innerTableExists) {
				eachOrderByField.allFieldsList = eachOrderByField.innerTables[eachOrderByField.innerTables.length - 1].allFieldsList; // all fields for the selected object
				eachOrderByField.map_AllFields = eachOrderByField.innerTables[eachOrderByField.innerTables.length - 1].map_AllFields;
				eachOrderByField.list_fieldLabels = eachOrderByField.innerTables[eachOrderByField.innerTables.length - 1].list_fieldLabels;
				eachOrderByField.list_fieldMasterLabels = eachOrderByField.innerTables[eachOrderByField.innerTables.length - 1].list_fieldMasterLabels;
			}
			// set unique id for each eachOrderByField
			eachOrderByField.uniqueId = object.baseObject + "_OrderBy_" + counter;

			counter = counter + 1;
		});
		object.orderbyFieldsVisible = object.list_OrderByFields.length > 0;
		object.orderByFieldsErrorMessage = false;

		// set data on the display fields list
		let displayCounter = 1;
		object.displayFieldsList.forEach((field) => {
			field.counter = displayCounter;
			field.uniqueId = object.baseObject + "_Display_" + displayCounter;
			displayCounter = displayCounter + 1;
		});

		object.displayField = {
			selectedField: "",
			selectedFieldLabel: "",
			list_fieldLabels: object.list_fieldLabels,
			list_fieldMasterLabels: object.list_fieldMasterLabels,
			uniqueId: object.baseObject + "_Display",
			map_AllFields: object.map_AllFields,
			placeholderText: "Search " + object.objectLabel + " fields",
			innerTableExists: false,
			relationshipDepth: 0,
			innerTables: []
		};
		object.displayFieldsErrorMessage = object.displayFieldsList.length == 0;
	}

	// populate list fields for the object
	createNewListFields(object, sObject) {
		let list_fieldLabels = [];
		let list_fieldMasterLabels = [];
		let list_AllFields = [];
		let tempobject = {};
		let referenceFields = [];

		let counter = 0;
		// by default add id as a reference field
		referenceFields.push({
			label: object.objectLabel,
			value: "id"
		});

		for (const strFieldName in sObject) {
			// create json object to be used in picklist
			let object = {
				label: sObject[strFieldName].strFieldLabel + "",
				value: sObject[strFieldName].strFieldAPIName + ""
			};

			// show only 10 auto complete options
			if (counter < 10) {
				list_fieldLabels.push(sObject[strFieldName].strFieldLabel);
				counter = counter + 1;
			}
			// add it to master list of fields
			list_fieldMasterLabels.push(sObject[strFieldName].strFieldLabel);
			list_AllFields.push(object);
			// add to reference only when field type is reference
			if (sObject[strFieldName].strFieldType == "REFERENCE") {
				referenceFields.push({
					label: sObject[strFieldName].strFieldLabel + "",
					value: sObject[strFieldName].strFieldAPIName.toLowerCase()
				});
			}
		}
		// build a temp object to return
		tempobject = {
			allFieldsList: list_AllFields,
			list_fieldLabels: list_fieldLabels,
			list_fieldMasterLabels: list_fieldMasterLabels,
			map_AllFields: sObject,
			referenceFields: referenceFields
		};

		return tempobject;
	}

	// set list fields on the object
	setExistingListFields(object, tempobject) {
		// set reference fields only for the base object
		if (object.baseObject) {
			object.referenceFields = tempobject.referenceFields;
		}
		// list of all fields for the object
		object.allFieldsList = tempobject.allFieldsList;
		object.list_fieldLabels = tempobject.list_fieldLabels;
		object.list_fieldMasterLabels = tempobject.list_fieldMasterLabels;
		object.map_AllFields = tempobject.map_AllFields;
		return object;
	}

	// restore previous version of the object
	handleRestorePreviousVersion(event) {
		let selectedObject = event.target.dataset.object;
		let oldObject = this.list_OldChosenObjects.find((object) => object.baseObject == selectedObject);
		let newObject = this.list_ChosenObjects.find((object) => object.baseObject == selectedObject);
		// if old object is not found - show error message
		if (!oldObject) {
			displayToast(this, "Previous version of " + newObject.objectLabel + " criteria not found ", "", "warning", "");
		} else {
			// if old object is found - replace the new object with the old object
			let list_TempObjects = [];
			let userFieldsAssignment = [];
			this.list_ChosenObjects.forEach((object) => {
				if (object.baseObject == selectedObject) {
					list_TempObjects.push(oldObject);
					userFieldsAssignment = oldObject.userFieldsAssignment;
				} else {
					list_TempObjects.push(object);
				}
			});
			this.list_ChosenObjects = list_TempObjects;
			if (this.template.querySelector("c-multi-select-pick-list-cmp[data-object=" + selectedObject + "]")) {
				this.template.querySelector("c-multi-select-pick-list-cmp[data-object=" + selectedObject + "]").refreshSelectedValues(userFieldsAssignment);
			}
			displayToast(this, "Previous version of " + newObject.objectLabel + " criteria loaded successfully ", "", "success", "");
		}
	}

	// waiting for 50ms to make sure all the fields are loaded before calling onload method
	renderedCallback() {
		if (!this.isRendered) {
			setTimeout(() => {
				this.handleOnLoad(false);
			}, 50);
			// set isRendered to true to avoid multiple calls to onload method
			this.isRendered = true;
		}
	}

	// open external urls for help articles
	handleCustomFunctions() {
		window.open("https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select.htm");
	}

	handleCommonFunctions() {
		window.open("https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_date_functions.htm");
	}

	handleSOQLFunctions() {
		window.open("https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_comparisonoperators.htm");
	}

	handleAutoSave(event) {
		this.autoSaveEnabled = event.target.checked;
		if (event.target.checked) {
			let that = this;
			this.autoSaveTimerId = setInterval(function () {
				// do not trigger auto save if the page is loading (maybe due to validation or save process)
				if (!that.blnLoading) {
					that.validateAllChanges(null, true);
				}
			}, this.autoSaveDuration * 1000);
		} else if (this.autoSaveTimerId) {
			clearInterval(this.autoSaveTimerId);
			this.autoSaveMessage = "";
			this.autoSaveSuccessful = false;
			this.autoSaveMessageVisible = false;
		}
	}

	handleAutoSaveInterval(event) {
		if (this.autoSaveTimerId) {
			clearInterval(this.autoSaveTimerId);
		}
		let duration = event.target.value;
		this.autoSaveDuration = duration;

		if (isNaN(duration)) {
			this.autoSaveMessage = "Auto save interval should be a number.";
			this.autoSaveSuccessful = false;
			return;
		}

		if (!duration || duration < 15) {
			this.autoSaveMessage = "Auto save interval should be at least 15 seconds.";
			this.autoSaveSuccessful = false;
			return;
		}

		this.autoSaveMessage = "";
		this.autoSaveSuccessful = false;

		if (this.autoSaveTimerId) {
			let that = this;
			this.autoSaveTimerId = setInterval(function () {
				// do not trigger auto save if the page is loading (maybe due to validation or save process)
				if (!that.blnLoading) {
					that.validateAllChanges(null, true);
				}
			}, this.autoSaveDuration * 1000);
		}
	}

	setAutoSaveFailed() {
		this.autoSaveMessage = "Last auto save failed at " + new Date().toLocaleTimeString() + ". Please click Save to know more.";
		this.autoSaveSuccessful = false;
	}

	handleRearrangeDisplayFields(event) {
		let selectedObject = event.target.dataset.object;
		let object = this.list_ChosenObjects.find((object) => object.baseObject == selectedObject);
		let operation = event.target.dataset.type;
		let counter = event.target.dataset.id;

		if (operation == "up" && counter == "1") {
			return;
		} else if (operation == "down" && counter == object.displayFieldsList.length) {
			return;
		} else {
			// write logic to handle up and down scenario
			let list_TempFields = [];
			let field1 = object.displayFieldsList.find((field) => field.counter == counter);
			let field2 = {};

			if (operation == "up") {
				field2 = object.displayFieldsList.find((field) => field.counter == Number(counter) - 1);
			} else {
				field2 = object.displayFieldsList.find((field) => field.counter == Number(counter) + 1);
			}

			object.displayFieldsList.forEach((field) => {
				if (field.counter == counter) {
					list_TempFields.push({
						counter: field2.counter,
						selectedField: field.selectedField,
						selectedFieldAPI: field.selectedFieldAPI,
						customText: field.customText,
						uniqueId: field2.uniqueId
					});
				} else if (field.counter == Number(counter) + 1 && operation == "down") {
					list_TempFields.push({
						counter: field1.counter,
						selectedField: field.selectedField,
						selectedFieldAPI: field.selectedFieldAPI,
						customText: field.customText,
						uniqueId: field1.uniqueId
					});
				} else if (field.counter == Number(counter) - 1 && operation == "up") {
					list_TempFields.push({
						counter: field1.counter,
						selectedField: field.selectedField,
						selectedFieldAPI: field.selectedFieldAPI,
						customText: field.customText,
						uniqueId: field1.uniqueId
					});
				} else {
					list_TempFields.push(field);
				}
			});
			list_TempFields = this.sortByField(list_TempFields, "counter");
			object.displayFieldsList = list_TempFields;
		}
	}

	sortByField(arr, field) {
		return arr.sort((a, b) => Number(a[field]) - Number(b[field]));
	}

	addViewRecords(event) {
		let value = event.detail.value;
		let selectedObject = event.target.dataset.object;
		let object = this.list_ChosenObjects.find((object) => object.baseObject == selectedObject);

		// Fetch all fields for the selected base object
		this.blnLoading = true;
		getDisplayFieldsFromTemplate({
			strTemplate: value
		})
			.then((result) => {
				this.blnLoading = false;

				if (result && result.length > 0) {
					let counter = object.displayFieldsList.length;
					let map_ExistingFields = new Map();

					object.displayFieldsList.forEach((field) => {
						map_ExistingFields.set(field.selectedFieldAPI.toLowerCase(), field);
					});

					let list_Fields = object.displayFieldsList;
					let netNewFields = 0;
					result.forEach((field) => {
						if (!map_ExistingFields.has(field.selectedFieldAPI)) {
							netNewFields = netNewFields + 1;
							counter = counter + 1;
							field.uniqueId = selectedObject + "_Display_" + counter;
							field.counter = counter;

							list_Fields.push(field);
						}
					});
					object.displayFieldsList = list_Fields;
					object.displayFieldsErrorMessage = object.displayFieldsList.length == 0;

					// remove error message
					let displayFieldsCmp = this.template.querySelector('[data-uniqueid="' + object.baseObject + '_Display"]');
					if (object.displayFieldsErrorMessage) {
						displayFieldsCmp.setErrorMessage("Please select at least one field to display.");
					} else {
						displayFieldsCmp.setErrorMessage("");
					}

					if (netNewFields == 0) {
						displayToast(this, "All fields from this template are already added.", "", "warning", "");
					} else {
						let fieldsLabel = netNewFields == 1 ? " field " : " fields ";
						displayToast(this, netNewFields + fieldsLabel + "from this template added successfully!", "", "success", "");
					}
				} else {
					displayToast(this, "We could not add fields from this template. Plase contact admin.", "", "warning", "");
				}

				let lst_input = [...this.template.querySelectorAll("lightning-combobox[data-field=View_Records]")];
				lst_input.forEach((input) => {
					input.value = null;
				});
			})
			.catch((error) => {
				// in case of error - show error message in the UI
				this.error = error;
				console.log("error", error);
				this.strHeaderErrorMessage = "Error in displaying fields: " + error?.body?.message || "Unknown error.";
				this.blnHeaderErrorMessageVisible = true;
				this.blnLoading = false;
			});
	}

	handleReArrangeFilter(event) {
		let selectedObject = event.target.dataset.object;
		let object = this.list_ChosenObjects.find((object) => object.baseObject == selectedObject);
		let operation = event.target.dataset.type;
		let selectedFilterId = Number(event.target.dataset.id);

		if (operation == "up" && selectedFilterId == 1) {
			return;
		} else if (operation == "down" && selectedFilterId == object.filterFieldsList.length) {
			return;
		} else {
			// write logic to handle up and down scenario
			let list_TempFields = [];
			let field1 = object.filterFieldsList.find((field) => field.filterId == selectedFilterId);
			let field2 = {};

			if (operation == "up") {
				field2 = object.filterFieldsList.find((field) => field.filterId == selectedFilterId - 1);
			} else {
				field2 = object.filterFieldsList.find((field) => field.filterId == selectedFilterId + 1);
			}

			object.filterFieldsList.forEach((field) => {
				if (field.filterId == selectedFilterId) {
					let newField = JSON.parse(JSON.stringify(field));

					newField.filterId = field2.filterId;
					newField.uniqueId = object.baseObject + "_" + field2.filterId;
					newField.operatorUniqueId = object.baseObject + "_Operator_" + field2.filterId;
					newField.soqlQueryTextAreaUniqueId = object.baseObject + "_SOQL_" + field2.filterId;
					newField.valueUniqueId = object.baseObject + "_Value_" + field2.filterId;

					list_TempFields.push(newField);
				} else if (field.filterId == Number(selectedFilterId) + 1 && operation == "down") {
					let newField = JSON.parse(JSON.stringify(field));

					newField.filterId = field1.filterId;
					newField.uniqueId = object.baseObject + "_" + field1.filterId;
					newField.operatorUniqueId = object.baseObject + "_Operator_" + field1.filterId;
					newField.soqlQueryTextAreaUniqueId = object.baseObject + "_SOQL_" + field1.filterId;
					newField.valueUniqueId = object.baseObject + "_Value_" + field1.filterId;

					list_TempFields.push(newField);
				} else if (field.filterId == Number(selectedFilterId) - 1 && operation == "up") {
					let newField = JSON.parse(JSON.stringify(field));

					newField.filterId = field1.filterId;
					newField.uniqueId = object.baseObject + "_" + field1.filterId;
					newField.operatorUniqueId = object.baseObject + "_Operator_" + field1.filterId;
					newField.soqlQueryTextAreaUniqueId = object.baseObject + "_SOQL_" + field1.filterId;
					newField.valueUniqueId = object.baseObject + "_Value_" + field1.filterId;

					list_TempFields.push(newField);
				} else {
					list_TempFields.push(field);
				}
			});

			list_TempFields = this.sortByField(list_TempFields, "filterId");
			object.filterFieldsList = list_TempFields;

			let criteraReplacedText = this.replaceCharacters(object.criteriaLogic, field2.filterId.toString(), field1.filterId.toString());
			object.criteriaLogic = criteraReplacedText;
		}
	}

	replaceCharacters(text, char1, char2) {
		var regex = new RegExp("\\b" + char1 + "\\b|\\b" + char2 + "\\b", "g");
		var newText = text.replace(regex, function (match) {
			return match === char1 ? char2 : char1;
		});
		return newText;
	}

	handleAddOrderBy(event) {
		let selectedObject = event.target.dataset.object;
		let object = this.list_ChosenObjects.find((object) => object.baseObject == selectedObject);
		if (!object.list_OrderByFields) {
			object.list_OrderByFields = [];
		}
		let list_TempFields = object.list_OrderByFields;
		let counter = list_TempFields.length + 1;

		if (this.list_ChosenObjects.length > 1 && object.list_OrderByFields.length == 1) {
			displayToast(this, "You cannot order by more than 1 field if there are multiple base objects", "", "warning", "");
			return;
		}

		if (object.list_OrderByFields.length == 10) {
			displayToast(this, "You cannot order by more than 10 fields.", "", "warning", "");
			return;
		}

		let newField = {
			selectedField: "", // API name of the selected field
			selectedOrder: "DESC", // selected order (asc, desc)
			selectedFieldLabel: "", // label of the selected field
			list_fieldLabels: object.list_fieldLabels, // list of field labels (this is a filtered list based on the search value)
			list_fieldMasterLabels: object.list_fieldMasterLabels, // this is the master list of field labels
			uniqueId: object.baseObject + "_OrderBy_" + counter, // unique id for the filter
			map_AllFields: object.map_AllFields, // map of api name and field object
			placeholderText: "Search " + object.objectLabel + " fields", // default value for the placeholder text
			innerTableExists: false, // indicates if reference objects are added
			relationshipDepth: 0, // indicates how many reference objects are added
			innerTables: [], // inner tables list if user adds fields from a reference object
			selectedFieldType: "",
			counter: counter,
			orderNulls: "NULLS LAST"
		};
		list_TempFields.push(newField);
		object.list_OrderByFields = list_TempFields;
		object.orderbyFieldsVisible = object.list_OrderByFields.length > 0;
		object.orderByFieldsErrorMessage = false;
		// reset performance back to 0 when order by button is clicked
		object.dblTimeTakenSeconds = 0;
	}

	// this is triggered when user deletes a field from the order by section
	handleDeleteOrderByField(event) {
		let selectedObject = event.target.dataset.object;
		let selectedUniqueId = event.target.dataset.uniqueid;
		let object = this.list_ChosenObjects.find((object) => object.baseObject == selectedObject);

		let list_TempFields = [];
		object.list_OrderByFields.forEach((field) => {
			if (field.uniqueId != selectedUniqueId) {
				list_TempFields.push(field);
			}
		});

		// adjust the counter and the unique id after deleting order by field
		let increment = 0;
		list_TempFields.forEach((field) => {
			increment = increment + 1;
			field.counter = increment;
			field.uniqueId = object.baseObject + "_OrderBy_" + increment;
		});
		object.list_OrderByFields = list_TempFields;
		object.orderbyFieldsVisible = object.list_OrderByFields.length > 0;
		object.orderByFieldsErrorMessage = object.list_OrderByFields.length == 0;
		object.dblTimeTakenSeconds = 0;
	}

	handleReArrangeOrderByFields(event) {
		let selectedObject = event.target.dataset.object;
		let object = this.list_ChosenObjects.find((object) => object.baseObject == selectedObject);
		let operation = event.target.dataset.type;
		let counter = event.target.dataset.id;

		if (operation == "up" && counter == "1") {
			return;
		} else if (operation == "down" && counter == object.list_OrderByFields.length) {
			return;
		} else {
			// write logic to handle up and down scenario
			let list_TempFields = [];
			let field1 = object.list_OrderByFields.find((field) => field.counter == counter);
			let field2 = {};

			if (operation == "up") {
				field2 = object.list_OrderByFields.find((field) => field.counter == Number(counter) - 1);
			} else {
				field2 = object.list_OrderByFields.find((field) => field.counter == Number(counter) + 1);
			}

			object.list_OrderByFields.forEach((field) => {
				if (field.counter == counter) {
					let newField = JSON.parse(JSON.stringify(field));
					newField.counter = field2.counter;
					newField.uniqueId = object.baseObject + "_OrderBy_" + field2.counter;
					list_TempFields.push(newField);
				} else if (field.counter == Number(counter) + 1 && operation == "down") {
					let newField = JSON.parse(JSON.stringify(field));
					newField.counter = field1.counter;
					newField.uniqueId = object.baseObject + "_OrderBy_" + field1.counter;

					list_TempFields.push(newField);
				} else if (field.counter == Number(counter) - 1 && operation == "up") {
					let newField = JSON.parse(JSON.stringify(field));
					newField.counter = field1.counter;
					newField.uniqueId = object.baseObject + "_OrderBy_" + field1.counter;

					list_TempFields.push(newField);
				} else {
					list_TempFields.push(field);
				}
			});
			list_TempFields = this.sortByField(list_TempFields, "counter");
			object.list_OrderByFields = list_TempFields;
		}
	}

	dateFunctionsHelp() {
		window.open("https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_dateformats.htm");
	}

	handleAvailableChoices(event) {
		let selectedObject = event.target.dataset.object;
		let object = this.list_ChosenObjects.find((object) => object.baseObject == selectedObject);
		let selectedFilterId = event.target.dataset.id;
		let filter = object.filterFieldsList.find((filter) => filter.filterId == selectedFilterId);
		let action = event.target.dataset.action;

		if (!filter.selectedValue || action == "replace") {
			filter.selectedValue = event.detail.value;
		} else if (filter.selectedValue && !filter.selectedValue.includes(event.detail.value)) {
			filter.selectedValue = filter.selectedValue + "," + event.detail.value;
		}

		let lst_input = [...this.template.querySelectorAll("lightning-combobox[data-type=availableChoices]")];
		lst_input.forEach((input) => {
			input.value = null;
		});
		object.dblTimeTakenSeconds = 0;
	}

	handleFrequencyChange(event) {
		this.intDelayInMinutes = event.detail.value;
	}

	//Method to add a new Field Mapping to the table
	handleAddFieldMapping(event) {
		let object = this.list_ChosenObjects.find((obj) => obj.baseObject === event.target.dataset.object);
		object.blnShowFieldMappingTable = true;
		let int_mappingSize = object.fieldMapping.length;
		object.fieldMapping.push({
			fieldMappingType: "Serving Record Field",
			uniqueId: object.servingObject + "-field-" + (int_mappingSize + 1),
			blnAddMapping: !this.blnViewOnlyAccess ? false : true,
			blnDisabledDelete: !this.blnViewOnlyAccess ? true : false,
			fieldId: int_mappingSize + 1,
			fieldLabel: "",
			selectedField: "",
			selectedFieldLabel: "",
			fromOptions: [],
			toOptions: {},
			mappingSize: 2,
			mapping: [
				{
					mappingId: 0,
					fromId: object.servingObject + "-field-" + (int_mappingSize + 1) + "-from-0",
					fromValue: "",
					toValue: "",
					toId: object.servingObject + "-field-" + (int_mappingSize + 1) + "-to-0"
				}
			],
			strFieldType: "",
			isSearchable: false,
			isQueueEligible: false,
			isCheckbox: false
		});
		object.blnAddFieldMapping = object.fieldMapping.length >= object.list_picklistFields.length && !this.blnViewOnlyAccess ? true : false;
	}

	//method that handle when the field changes from the dropdown
	handleChangeFieldValue(event) {
		let object = this.list_ChosenObjects.find((obj) => obj.baseObject === event.target.dataset.object);
		let str_label = event.detail ? event.detail : "";
		let int_fieldId = Number(event.target.dataset.index);
		let field = object.fieldMapping.find((field) => field.fieldId === int_fieldId);
		let newField = {};
		if (str_label === "") {
			newField.label = "";
			newField.value = "";
			newField.fromOptions = [];
			newField.toOptions = [];
		} else {
			newField = object.list_picklistFields.find((field) => field.label === str_label);
		}
		field.blnAddMapping = !this.blnViewOnlyAccess ? false : true;
		field.blnDisabledDelete = !this.blnViewOnlyAccess ? true : false;
		field.fieldLabel = newField.label;
		(field.selectedField = newField.value), (field.selectedFieldLabel = str_label), (field.fromOptions = newField.fromOptions);
		field.toOptions = newField.toOptions;
		field.mappingSize = 2;
		field.mapping = [
			{
				mappingId: 0,
				fromId: field.uniqueId + "-from-0",
				fromValue: "",
				toValue: "",
				toId: field.uniqueId + "-to-0"
			}
		];
		field.strFieldType = newField.strFieldType;
		field.isSearchable = newField.strFieldType == "REFERENCE";
		field.isQueueEligible = newField.value.toLowerCase() == "ownerid" && object.blnQueuesAvailable;
		field.isCheckbox = newField.strFieldType == "BOOLEAN";
		this.validateDuplicateFields(object);
	}

	//method to add value mapping
	handleAddPicklistValueMapping(event) {
		let int_fieldId = Number(event.target.dataset.index);
		let object = this.list_ChosenObjects.find((obj) => obj.baseObject === event.target.dataset.object);
		let field = object.fieldMapping.find((field) => field.fieldId === int_fieldId);
		field.blnDisabledDelete = !this.blnViewOnlyAccess ? false : true;
		field.mappingSize = field.mappingSize + 1;
		field.mapping.push({
			mappingId: field.mappingSize - 2,
			fromId: field.uniqueId + "-from-" + (field.mappingSize - 2),
			fromValue: "",
			toValue: "",
			toId: field.uniqueId + "-to-" + (field.mappingSize - 2)
		});
		field.blnAddMapping = field.mapping.length >= field.fromOptions.length && !this.blnViewOnlyAccess ? true : false;
	}

	//method to remove value mapping
	handleRemoveMapping(event) {
		let int_mappingId = Number(event.target.dataset.index);
		let int_fieldId = Number(event.target.dataset.picklist);
		let object = this.list_ChosenObjects.find((obj) => obj.baseObject === event.target.dataset.object);
		let field = object.fieldMapping.find((field) => field.fieldId === int_fieldId);
		let list_NewMapping = [];
		let intNewIndex = 0;
		for (let i = 0; i < field.mapping.length; i++) {
			if (field.mapping[i].mappingId !== int_mappingId) {
				list_NewMapping.push({
					mappingId: intNewIndex,
					fromValue: field.mapping[i].fromValue,
					toValue: field.mapping[i].toValue,
					fromId: field.uniqueId + "-from-" + intNewIndex,
					toId: field.uniqueId + "-to-" + intNewIndex,
					isDateField: field.mapping[i].isDateField,
					isDateTimeField: field.mapping[i].isDateTimeField,
					toOperator: field.mapping[i].toOperator,
					toDays: field.mapping[i].toDays,
					fromQueueEnabled: field.mapping[i].fromQueueEnabled,
					toQueueEnabled: field.mapping[i].toQueueEnabled,
					toHours: field.mapping[i].toHours
				});
				intNewIndex++;
			}
		}
		field.mappingSize = list_NewMapping.length + 1;
		field.mapping = list_NewMapping;
		field.blnDisabledDelete = this.blnViewOnlyAccess ? true : field.mapping.length <= 1 ? true : false;
		field.blnAddMapping = field.mapping.length >= field.fromOptions.length && this.blnViewOnlyAccess ? true : false;
		this.validateDuplicatePicklistFromValues(field);
	}

	//method to handle when a value changes and runs validations
	handleChangeMapValue(event) {
		let str_newVal = event.detail.value;
		let int_Index = Number(event.target.dataset.index);
		let int_fieldId = Number(event.target.dataset.picklist);
		let str_mapOption = event.target.dataset.option;
		//validate already in mapping value
		let object = this.list_ChosenObjects.find((obj) => obj.baseObject === event.target.dataset.object);
		let field = object.fieldMapping.find((field) => field.fieldId === int_fieldId);
		let mapping = field.mapping.find((mapValue) => mapValue.mappingId === int_Index);
		if ((field.strFieldType == "DATE" || field.strFieldType == "DATETIME") && str_mapOption == "toValue") {
			if (str_newVal.includes("Today ") || str_newVal.includes("Now ")) {
				mapping.isDateField = true;
				mapping.isDateTimeField = str_newVal.includes("Now ");
			} else {
				mapping.isDateField = false;
				mapping.isDateTimeField = false;
				mapping.toOperator = "";
				mapping.toDays = "";
				mapping.toHours = "";
			}
		}
		mapping[str_mapOption] = str_newVal;
		this.validateDuplicatePicklistFromValues(field);
		this.validatePicklistEmptyMapping(object);
		this.validateDuplicateFields(object);
	}

	//validates if any picklist value mapping is empty
	validatePicklistEmptyMapping(obj) {
		let bln_isConfigurationValid = true;

		let list_comboToUpdate = [];
		let list_comboToReset = [];

		let list_searchBoxToUpdate = [];
		let list_SearchBoxesToReset = [];

		obj.fieldMapping.forEach((field) => {
			field.mapping.forEach((mapping) => {
				if (!mapping.fromValue) {
					bln_isConfigurationValid = false;
					list_comboToUpdate.push(this.template.querySelector('[data-uniqueid="' + mapping.fromId + '"]'));
					list_searchBoxToUpdate.push(this.template.querySelector('[data-searchid="' + mapping.fromId + '"]'));
				}
				if (!mapping.toValue) {
					bln_isConfigurationValid = false;
					list_comboToUpdate.push(this.template.querySelector('[data-uniqueid="' + mapping.toId + '"]'));
					list_searchBoxToUpdate.push(this.template.querySelector('[data-searchid="' + mapping.toId + '"]'));
				} else {
					list_comboToReset.push(this.template.querySelector('[data-uniqueid="' + mapping.toId + '"]'));
					list_SearchBoxesToReset.push(this.template.querySelector('[data-searchid="' + mapping.toId + '"]'));
				}
			});
		});
		this.setCustomValidityToList(list_comboToUpdate, "Value is required.");
		this.setCustomValidityToList(list_comboToReset, "");

		this.setSearchBoxCustomValidity(list_searchBoxToUpdate, "Value is required.");
		this.setSearchBoxCustomValidity(list_SearchBoxesToReset, "");
		return bln_isConfigurationValid;
	}

	validateFieldMapping(obj) {
		let valid = true;
		let list_searchBoxToUpdate = [];
		let list_SearchBoxesToReset = [];

		obj.fieldMapping.forEach((field) => {
			if (!field.selectedFieldLabel) {
				valid = false;
				list_searchBoxToUpdate.push(this.template.querySelector('[data-fieldid="' + field.uniqueId + '"]'));
			} else {
				list_SearchBoxesToReset.push(this.template.querySelector('[data-fieldid="' + field.uniqueId + '"]'));
			}
		});

		this.setSearchBoxCustomValidity(list_searchBoxToUpdate, "Value is required.");
		this.setSearchBoxCustomValidity(list_SearchBoxesToReset, "");
		return valid;
	}

	validateDateTimeMapping(obj) {
		let list_comboxToUpdate = [];
		let list_comboToReset = [];
		let valid = true;

		obj.fieldMapping.forEach((field) => {
			field.mapping.forEach((mapping) => {
				if (field.strFieldType == "DATETIME") {
					let mappingInvalid = mapping.toDays && mapping.toDays == 0 && !mapping.toHours;
					if (mappingInvalid) {
						let component = this.template.querySelector('[data-hours="' + mapping.toId + '"]');
						valid = false;
						list_comboxToUpdate.push(component);
					} else {
						list_comboToReset.push(this.template.querySelector('[data-hours="' + mapping.toId + '"]'));
					}
				}
			});
		});

		this.setCustomValidityToList(list_comboxToUpdate, "Value is required.");
		this.setCustomValidityToList(list_comboToReset, "");
		return valid;
	}

	validateDateEntryMapping(obj) {
		let bln_isConfigurationValid = true;
		obj.fieldMapping.forEach((field) => {
			field.mapping.forEach((mapping) => {
				if ((field.strFieldType == "DATE" || field.strFieldType == "DATETIME") && mapping.isDateField) {
					let component = this.template.querySelector('[data-todays="' + mapping.toId + '"]');
					if (component) {
						component.reportValidity();
						let validate = component.checkValidity();
						if (!validate) {
							bln_isConfigurationValid = false;
						}
					}
				}
			});
		});

		return bln_isConfigurationValid;
	}

	//validates if there is any duplicated field in the table
	validateDuplicateFields(obj) {
		let list_fields = [];
		let list_duplicatedFields = [];
		obj.fieldMapping.forEach((field) => {
			if (list_fields.includes(field.selectedField)) {
				list_duplicatedFields.push(field.selectedField);
			} else {
				list_fields.push(field.selectedField);
			}
		});
		let list_comboToUpdate = [];
		let list_comboToReset = [];
		obj.fieldMapping.forEach((field) => {
			if (list_duplicatedFields.includes(field.selectedField)) {
				list_comboToUpdate.push(this.template.querySelector('[data-uniqueid="' + field.uniqueId + '"]'));
				this.template.querySelector('[data-uniqueid="' + field.uniqueId + '"]').setErrorMessage("Duplicate Field.");
			} else {
				list_comboToReset.push(this.template.querySelector('[data-uniqueid="' + field.uniqueId + '"]'));
				this.template.querySelector('[data-uniqueid="' + field.uniqueId + '"]').setErrorMessage("");
			}
		});
		return list_comboToUpdate.length > 0 ? false : true;
	}

	//validates if there are any from value duplicated in the same field
	validateDuplicatePicklistFromValues(picklist) {
		let list_currentMappnig = [];
		let list_duplicatedValues = [];
		picklist.mapping.forEach((map) => {
			if (!list_currentMappnig.includes(map.fromValue)) {
				list_currentMappnig.push(map.fromValue);
			} else {
				list_duplicatedValues.push(map.fromValue);
			}
		});
		let list_comboxToUpdate = [];
		let list_comboToReset = [];

		let list_searchBoxToUpdate = [];
		let list_SearchBoxesToReset = [];

		picklist.mapping.forEach((map) => {
			if (list_duplicatedValues.includes(map.fromValue)) {
				list_comboxToUpdate.push(this.template.querySelector('[data-uniqueid="' + map.fromId + '"]'));
				list_searchBoxToUpdate.push(this.template.querySelector('[data-searchid="' + map.fromId + '"]'));
			} else {
				list_comboToReset.push(this.template.querySelector('[data-uniqueid="' + map.fromId + '"]'));
				list_SearchBoxesToReset.push(this.template.querySelector('[data-searchid="' + map.fromId + '"]'));
			}
		});
		this.setCustomValidityToList(list_comboxToUpdate, "Duplicate From Value.");
		this.setCustomValidityToList(list_comboToReset, "");

		this.setSearchBoxCustomValidity(list_searchBoxToUpdate, "Duplicate From Value.");
		this.setSearchBoxCustomValidity(list_SearchBoxesToReset, "");

		let validate = list_comboxToUpdate.length == 0 ? true : false;
		return validate;
	}

	//add the validation to a list of inputs
	setCustomValidityToList(list_inputs, message) {
		list_inputs.forEach((combo) => {
			if (combo) {
				combo.setCustomValidity(message);
				combo.reportValidity();
			}
		});
	}

	setSearchBoxCustomValidity(list_inputs, message) {
		list_inputs.forEach((combo) => {
			if (combo) {
				combo.setErrorMessage(message);
			}
		});
	}

	//method that handles the remove field fromt table
	handleRemoveField(event) {
		let fieldId = Number(event.target.dataset.index);
		let object = this.list_ChosenObjects.find((obj) => obj.baseObject === event.target.dataset.object);
		let list_tempFields = [];
		let intNewIndex = 1;
		//setting again the indexes
		for (let i = 0; i < object.fieldMapping.length; i++) {
			if (object.fieldMapping[i].fieldId !== fieldId) {
				let field = object.fieldMapping[i];
				field.fieldId = intNewIndex;
				list_tempFields.push(field);
				intNewIndex++;
			}
		}
		object.fieldMapping = list_tempFields;
		object.blnAddFieldMapping = object.fieldMapping.length >= object.list_picklistFields.length && !this.blnViewOnlyAccess ? true : false;
		object.blnShowFieldMappingTable = object.fieldMapping.length > 0 ? true : false;
	}

	handleReferenceFieldChange(event) {
		let str_label = event.detail ? event.detail : "";
		let object = this.list_ChosenObjects.find((obj) => obj.baseObject === event.target.dataset.object);
		let int_Index = Number(event.target.dataset.index);
		let int_fieldId = Number(event.target.dataset.picklist);
		let str_mapOption = event.target.dataset.option;
		let field = object.fieldMapping.find((field) => field.fieldId === int_fieldId);
		let mapping = field.mapping.find((mapValue) => mapValue.mappingId === int_Index);
		mapping[str_mapOption] = str_label;
		this.validateDuplicatePicklistFromValues(field);
		this.validatePicklistEmptyMapping(object);
		if (str_mapOption.includes("from")) {
			this.template.querySelector('[data-searchid="' + mapping.fromId + '"]').setTextBox(str_label);
		} else {
			this.template.querySelector('[data-searchid="' + mapping.toId + '"]').setTextBox(str_label);
		}
	}

	setQueuesAvailable(object, result) {
		object.map_Queues = result.map_Queues;
		if (result.map_Queues[object.servingObject]) {
			let queue = result.map_Queues[object.servingObject];
			object.map_Queues = queue;

			let list_Queues = [];

			for (const property in queue) {
				list_Queues.push(queue[property]);
			}
			object.list_Queues = list_Queues;
			object.blnQueuesAvailable = list_Queues.length > 0;
		}
	}

	handleQueueSelection(event) {
		let checked = event.target.checked;
		let object = this.list_ChosenObjects.find((obj) => obj.baseObject === event.target.dataset.object);
		let int_Index = Number(event.target.dataset.index);
		let int_fieldId = Number(event.target.dataset.picklist);
		let str_mapOption = event.target.dataset.option;
		let source = event.target.dataset.source;

		let field = object.fieldMapping.find((field) => field.fieldId === int_fieldId);
		let mapping = field.mapping.find((mapValue) => mapValue.mappingId === int_Index);
		mapping[str_mapOption] = checked;
		mapping[source] = "";

		let tempList = [];
		if (field && field.selectedField.toLowerCase() != "ownerid") {
			tempList.push("[Blank/Empty Value]");
		}

		if (str_mapOption.includes("from")) {
			tempList.push("[Any Value]");
		}

		this.list_ActiveUsersLabel = [];
		if (checked) {
			object.list_Queues.forEach((queue) => {
				tempList.push(queue);
			});
		} else {
			let counter = 0;
			this.list_ActiveUsersMasterLabel.forEach((user) => {
				counter = counter + 1;
				if (counter < 10) {
					tempList.push(user);
				}
			});
		}
		this.list_ActiveUsersLabel = tempList;
	}
}