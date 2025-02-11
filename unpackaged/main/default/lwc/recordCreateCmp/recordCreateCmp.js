import { LightningElement, api, track, wire } from "lwc";
import { IsConsoleNavigation, getFocusedTabInfo, closeTab, EnclosingTabId, getTabInfo, openSubtab, getAllTabInfo, focusTab, openTab } from "lightning/platformWorkspaceApi";

import getRecordTypes from "@salesforce/apex/RecordCreateController.getRecordTypes";
import createRecord from "@salesforce/apex/RecordCreateController.createRecord";
import createLineItems from "@salesforce/apex/RecordCreateController.createLineItems";

import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class RecordCreateCmp extends LightningElement {
	// record Id passed from Aura
	// Id of the record where New button was clicked
	@api recordid;
	@track blnLoading = false;
	@track strSelectedRecordType = "";
	@track strSelectedRecordTypeDescription = "";
	// this is temporary list of fields to be displayed on the screen - will change for each record type selected
	@track list_RecordCreateFields = [];
	// list of total fields available for the object - will not be changed once loaded
	@track list_RecordCreateFieldsTotal = [];
	@track strObjectToCreate = "";
	// Couple of fields to show error message
	@track blnPageError = false;
	@track strErrorMessage = "";
	// If there are no fields added to a record type - show error message
	@track blnFieldsUnavailable = false;
	// Map of field name and field API name
	@track map_FieldTypes = {};
	// Boolean flag to indicate if there are no record types available for each object
	@track blnNoRecordTypesAvailable;
	// Indicate if its a console navigation
	@wire(IsConsoleNavigation) isConsoleNavigation;
	// List of record type option
	@track options = [];
	@track counter = 0;
	@track objRecordCreate = {};
	@track strTitle = "Create New ";
	@track blnAddProducts = false;
	@track strSaveButtonLabel = "Save";
	@track draftValues = [];
	@track map_RecordTypes = {};
	@wire(EnclosingTabId) tabId;

	@track productColumns = [
		{ label: "Product", fieldName: "name" },
		{ label: "Sales Price", fieldName: "unitPrice", type: "currency" },
		{ label: "Quantity", fieldName: "employees", type: "number", editable: true },
		{ label: "Total Price", fieldName: "totalPrice", type: "currency" }
	];
	@track productData = [];
	@track selectedProducts = [];

	// Method to close console tab
	async closeTab() {
		if (!this.isConsoleNavigation) {
			return;
		}
		const { tabId } = await getFocusedTabInfo();
		await closeTab(tabId);
	}

	// On load - show record types, fields accessible and default values
	connectedCallback() {
		this.handleOnLoad();
	}

	handleOnLoad() {
		this.blnLoading = true;
		// Parse data from record URL to know which object to create new record - pass it to apex to get metadata for that object
		this.strObjectToCreate = this.getObjectFromUrl(window.location.href);

		if (!this.strObjectToCreate) {
			this.blnLoading = false;
			this.counter = this.counter + 1;
			return;
		}
		this.strTitle = "Create New " + this.strObjectToCreate;

		getRecordTypes({
			strObjectName: this.strObjectToCreate,
			idRecord: this.recordid
		})
			.then((result) => {
				// in case of any exception from Apex - do not continue further and show error message
				if (result.blnSuccess == false) {
					this.blnPageError = true;
					this.strErrorMessage = "Error in loading this page. Please contact your administrator. Reason: " + result.strMessage;
					this.blnLoading = false;
					return;
				}
				// Initialize variales
				let list_temp = [];
				let idRecordCreate = "";
				let objRecordCreate = {};
				let map_Fields = new Map();
				let list_total = [];

				// Map data from Apex to local variables
				this.map_FieldTypes = result.map_FieldTypes;
				this.blnNoRecordTypesAvailable = result.blnNoRecordTypesAvailable;
				let recordCreateSize = result.list_RecordCreate.length;
				// Set selected record type on load - if not set, set it to default record
				if (!this.strSelectedRecordType) {
					this.strSelectedRecordType = result.strDefaultRecordTypeId;
				}
				this.map_RecordTypes = result.map_RecordTypes;
				this.list_RecordCreate = result.list_RecordCreate;
				// Set record type description
				if (this.strSelectedRecordType) {
					this.strSelectedRecordTypeDescription = this.map_RecordTypes[this.strSelectedRecordType] ? this.map_RecordTypes[this.strSelectedRecordType].Description : "";
				}

				// if there are no record types available for the object - show error message - Do not continue further
				if (recordCreateSize == 0) {
					this.blnPageError = true;
					this.strErrorMessage = "No record types configured for this object. Please contact your administrator.";
					this.blnLoading = false;
					return;
				}
				// At this point, there are no errors on the page - Build list of options to show in drop down
				result.list_RecordCreate.forEach((element) => {
					if (this.strSelectedRecordType == element.Record_Type_Id__c) {
						idRecordCreate = element.Id;
						objRecordCreate = element;
						this.objRecordCreate = element;
					}
					list_temp.push({
						label: element.MasterLabel,
						value: element.Record_Type_Id__c
					});
				});

				// Set dropdown options (list of record types)
				this.options = list_temp;

				// if there is Order configured from Record create - follow specifc order
				let list_Orders = objRecordCreate.Order__c ? objRecordCreate.Order__c.split(",") : [];

				// Set data for each field - set default values, field type and other attributes
				result.list_RecordCreateFields.forEach((element) => {
					// data manupation on default value
					if (element.Default_Field__c == "Id") {
						element.Default_Value__c = this.recordid;
					}
					let fieldType = this.map_FieldTypes[element.Field_API__c.toLowerCase()];

					// if field type is boolean - change type from text from boolean
					if (fieldType == "boolean") {
						if (element.Default_Value__c == "false") {
							element.Default_Value__c = false;
						} else if (element.Default_Value__c == "true") {
							element.Default_Value__c = true;
						}
					}

					// Set custom value from date and datetime fields
					if (fieldType == "date") {
						if (element.Default_Value__c) {
							element.Default_Value__c = element.Default_Value__c.split(" ")[0];
						} else if (element.Field_API__c == "CloseDate") {
							const today = new Date();
							const futureDate = new Date();
							futureDate.setDate(today.getDate() + 30); // Add 30 days

							const year = futureDate.getFullYear();
							const month = String(futureDate.getMonth() + 1).padStart(2, "0"); // Months are zero-based
							const day = String(futureDate.getDate()).padStart(2, "0");
							element.Default_Value__c = `${year}-${month}-${day}`;
						}
					} else if (fieldType == "datetime" && element.Default_Value__c) {
						let dateTimeString = this.getLocalTime(element.Default_Value__c);
						// Format to `YYYY-MM-DDTHH:mm`
						let datePart = dateTimeString.split(" ")[0]; // Extract "2024-09-30"
						let timePart = dateTimeString.split(" ")[1].slice(0, 5); // Extract "18:22"
						let localTime = `${datePart}T${timePart}`; // "2024-09-30T18:22"

						const dateObject = new Date(localTime); // Convert to Date object
						const isoDate = dateObject.toISOString(); // Convert to ISO 8601 format
						element.Default_Value__c = isoDate;
					}

					if (idRecordCreate == element.Record_Type__c || this.blnNoRecordTypesAvailable) {
						map_Fields.set(element.Field_API__c, element);
					}
					element.Default_Value__c = element.Default_Value__c ? element.Default_Value__c : "";
					list_total.push(element);
				});

				// arrange the fields in the right order
				list_temp = [];
				list_Orders.forEach((element) => {
					if (map_Fields.has(element)) {
						list_temp.push(map_Fields.get(element));
					}
					if (element == "BLANK_FIELD") {
						list_temp.push({
							isblank: true
						});
					}
				});

				// include other fields not part of the order in the end
				map_Fields.forEach((value, key) => {
					if (!list_Orders.includes(key)) {
						list_temp.push(value);
					}
				});

				// Set data back on track variables
				// Chunk array is method to split 1 array into multiple arrays of 2 elements each
				// 2 elements because to show 2 fields in 1 row
				this.list_RecordCreateFields = this.chunkArray(list_temp, 2);
				this.blnFieldsUnavailable = this.list_RecordCreateFields.length == 0;
				this.list_RecordCreateFieldsTotal = list_total;

				this.blnLoading = false;
			})
			.catch((error) => {
				// In case of exception - show error message in the UI
				this.blnPageError = true;
				this.strErrorMessage = "Error in loading this page. Please contact your administrator. Reason: " + error?.body?.message || "Unknown error.";
				this.blnLoading = false;
				console.log("error => ", error);
			});
	}

	// Chunk array is method to split 1 array into multiple arrays of 2 elements each
	chunkArray(array, size) {
		const chunks = [];
		for (let i = 0; i < array.length; i += size) {
			chunks.push(array.slice(i, i + size));
		}
		return chunks;
	}

	// Method to handle when record type is changed
	handleRecordTypeChange(event) {
		let list_temp = [];
		let idRecordCreate = "";
		let objRecordCreate = {};
		let map_Fields = new Map();
		// Find the record type selected - Get the Record Create data for that record type
		this.list_RecordCreate.forEach((element) => {
			if (element.Record_Type_Id__c == event.detail.value) {
				idRecordCreate = element.Id;
				objRecordCreate = element;
				this.objRecordCreate = element;
			}
		});
		// Find the order of fields to be displayed
		let list_Orders = objRecordCreate.Order__c ? objRecordCreate.Order__c.split(",") : [];
		this.strSelectedRecordType = event.detail.value;
		this.strSelectedRecordTypeDescription = this.map_RecordTypes[this.strSelectedRecordType] ? this.map_RecordTypes[this.strSelectedRecordType].Description : "";
		// Reset data before adding new fields
		this.list_RecordCreateFields = [];
		// Set default values, field type and other attributes
		this.list_RecordCreateFieldsTotal.forEach((element) => {
			if (idRecordCreate == element.Record_Type__c) {
				if (element.Default_Field__c == "Id") {
					element.Default_Value__c = this.recordid;
				}
				element.Default_Value__c = element.Default_Value__c == undefined ? "" : element.Default_Value__c;
				if (element.Default_Value__c == "false") {
					element.Default_Value__c = false;
				} else if (element.Default_Value__c == "true") {
					element.Default_Value__c = true;
				}
				map_Fields.set(element.Field_API__c, element);
			}
		});

		list_temp = [];
		// arrange the fields in the right order
		list_Orders.forEach((element) => {
			if (map_Fields.has(element)) {
				list_temp.push(map_Fields.get(element));
			}
			if (element == "BLANK_FIELD") {
				list_temp.push({
					isblank: true
				});
			}
		});

		// include other fields not part of the order in the end
		map_Fields.forEach((value, key) => {
			if (!list_Orders.includes(key)) {
				list_temp.push(value);
			}
		});

		// Set data back on track variables
		this.list_RecordCreateFields = this.chunkArray(list_temp, 2);
		this.blnFieldsUnavailable = this.list_RecordCreateFields.length == 0;
	}

	// Get object name from the record URL
	getObjectFromUrl(url) {
		try {
			// Parse the URL
			const urlObj = new URL(url);
			// Split the path to identify the object name
			const pathParts = urlObj.pathname.split("/");

			// Check if the URL includes 'lightning/o/{objectName}/new'
			const objectIndex = pathParts.indexOf("o");
			if (objectIndex !== -1 && pathParts[objectIndex + 2] === "new") {
				return pathParts[objectIndex + 1]; // Return the object name
			}
		} catch (error) {
			console.error("Invalid URL:", error);
		}
		return null; // Return null if no object is found
	}

	// Handles the save button click - creates new record
	handleSave() {
		if (!this.blnAddProducts) {
			const inputFields = this.template.querySelectorAll("lightning-input-field");
			let isValid = true;

			// Loop through each lightning-input-field and check validity
			inputFields.forEach((inputField) => {
				if (!inputField.reportValidity()) {
					isValid = false; // If any field is invalid, set isValid to false
				}
			});

			// if record type is not selected - show error message
			if (!isValid) {
				return;
			}
			// validate if a field is a text field and is required - check if its empty
			// build a list of field names with empty string
			let fieldNames = [];
			inputFields.forEach((inputField) => {
				let fieldType = typeof inputField.value;
				if (inputField.required && fieldType == "string") {
					inputField.value = inputField.value.trim();
					if (!inputField.value) {
						fieldNames.push(inputField.fieldName);
						isValid = false;
					}
				}
			});

			// build comma separated list of fields which are empty
			if (fieldNames.length > 0) {
				alert(" Fields (" + fieldNames.join(", ") + ") are required and cannot be empty.");
				return;
			}

			if (isValid) {
				let fieldValues = {};
				// Set object type and record type Id
				fieldValues["sObjectType"] = this.strObjectToCreate;
				fieldValues["RecordTypeId"] = this.strSelectedRecordType;

				// Set data from record edit form on Javascript object
				inputFields.forEach((inputField) => {
					const fieldName = inputField.fieldName; // field-name attribute (API name)
					const fieldValue = inputField.value; // field value
					// Store the field values in an object
					fieldValues[fieldName] = fieldValue;
				});

				this.blnLoading = true;
				// pass load from LWC to apex to create record
				createRecord({
					strPayload: JSON.stringify(fieldValues),
					blnAddProducts: this.objRecordCreate.Add_Products__c ? this.objRecordCreate.Add_Products__c : false
				})
					.then((result) => {
						// if success - show toast notification
						if (result.blnSuccess) {
							this.objRecordCreate.recordId = result.objRecord.Id;

							// Toast notification
							const toastEvent = new ShowToastEvent({
								title: "New " + this.strObjectToCreate + " created successfully",
								message: "",
								variant: "success"
							});
							this.dispatchEvent(toastEvent);

							// if record create has Add Products enabled - show products to add ONLY if products are available & quantity is greater than 0
							if (this.objRecordCreate.Add_Products__c && result.objProductsWrapper && result.objProductsWrapper.list_Products.length > 0) {
								this.objRecordCreate.objOppty = result.objProductsWrapper.objOppty;
								let employees = result.objProductsWrapper.objOppty.NumberOfEmployees__c ? result.objProductsWrapper.objOppty.NumberOfEmployees__c : 0;
								let contractors = result.objProductsWrapper.objOppty.Number_of_Contractors__c ? result.objProductsWrapper.objOppty.Number_of_Contractors__c : 0;
								let quantity = employees + contractors;
								// Update title
								this.strTitle = "Add Products on " + result.objRecord.Name + " Opportunity";
								// Change view to Add Products Mode
								this.blnAddProducts = true;
								// Update to new title
								this.strSaveButtonLabel = "Add Products";
								// build data table
								let productsList = [];
								quantity = Number(quantity);
								result.objProductsWrapper.list_Products.forEach((element) => {
									productsList.push({
										name: element.Product2.Name,
										unitPrice: element.UnitPrice,
										Id: element.Id,
										employees: quantity,
										totalPrice: Number(element.UnitPrice) * quantity
									});
								});
								this.productData = productsList;
								// Pre-select existing products
								let selectedProducts = [];
								if (result.objProductsWrapper.objOppty.OpportunityLineItems) {
									result.objProductsWrapper.objOppty.OpportunityLineItems.forEach((element) => {
										selectedProducts.push(element.PricebookEntryId);
									});
								}
								this.selectedProducts = selectedProducts;
							} else {
								// Take user to the record detail page
								this.closeTab();
								this.openSubtab(result.objRecord.Id);
							}
						} else {
							// In case of error, show error message
							const toastEvent = new ShowToastEvent({
								title: "Record create failed",
								message: "Reason - " + result.strMessage,
								variant: "error"
							});
							this.dispatchEvent(toastEvent);
						}
						this.blnLoading = false;
					})
					.catch((error) => {
						this.strErrorMessage = "Error in loading this page. Please contact your administrator. Reason: " + error?.body?.message || "Unknown error.";

						// In case of error, show error message
						const toastEvent = new ShowToastEvent({
							title: "Record create failed",
							message: "Reason - " + this.strErrorMessage,
							variant: "error"
						});
						this.dispatchEvent(toastEvent);
						this.blnLoading = false;
					});
			}
		} else {
			this.addProducts();
		}
	}
	// add products - creates opportunity line items
	addProducts() {
		// get selected rows from data table
		let selectedRows = this.refs.dataTable.getSelectedRows();
		let list_Products = [];
		let list_NoQuantity = [];
		selectedRows.forEach((element) => {
			let quantity = element.employees ? element.employees : 0;
			if (quantity == 0) {
				list_NoQuantity.push(element.name);
			}
			list_Products.push(element.Id + "," + quantity);
		});
		// if no products selected - show warning message and return
		if (list_Products.length == 0) {
			// Toast notification
			const toastEvent = new ShowToastEvent({
				title: "Please select atleast 1 product to add",
				message: "",
				variant: "warning"
			});
			this.dispatchEvent(toastEvent);
			return;
		}
		if (list_NoQuantity.length > 0) {
			// Toast notification
			const toastEvent = new ShowToastEvent({
				title: "Quantity for products (" + list_NoQuantity.join(", ") + ") cannot be 0",
				message: "",
				variant: "warning"
			});
			this.dispatchEvent(toastEvent);
			return;
		}

		// products are available - call apex to create opportunity line items
		this.blnLoading = true;
		createLineItems({
			list_EntryIds: list_Products,
			idRecord: this.objRecordCreate.recordId
		})
			.then((result) => {
				// apex method returns "SUCCESS" or the actual error message
				if (result == "SUCCESS") {
					// Toast notification
					const toastEvent = new ShowToastEvent({
						title: "Opportunity Products added successfully",
						message: "",
						variant: "success"
					});
					this.dispatchEvent(toastEvent);
					this.closeTab();
					// Take user to the record detail page
					this.openSubtab(this.objRecordCreate.recordId);
				} else {
					// Toast notification
					const toastEvent = new ShowToastEvent({
						title: "Unable to add products. Reason " + result + ". Please contact your administrator.",
						message: "",
						variant: "error"
					});
					this.dispatchEvent(toastEvent);
				}
				this.blnLoading = false;
			})
			.catch((error) => {
				this.blnLoading = false;
				console.log("error => ", error);
			});
	}
	// Handles key press - if enter key pressed, call handleSave method
	handleKeypress(event) {
		if (event.keyCode === 13) {
			this.handleSave();
		}
	}

	// Get local time from UTC time
	getLocalTime(dateString) {
		const utcDate = dateString; // Input UTC time
		const dateObject = new Date(utcDate + "Z"); // Append 'Z' to indicate UTC time

		// Get local time components
		const localYear = dateObject.getFullYear();
		const localMonth = String(dateObject.getMonth() + 1).padStart(2, "0"); // Months are 0-indexed
		const localDay = String(dateObject.getDate()).padStart(2, "0");
		const localHours = String(dateObject.getHours()).padStart(2, "0");
		const localMinutes = String(dateObject.getMinutes()).padStart(2, "0");
		const localSeconds = String(dateObject.getSeconds()).padStart(2, "0");

		// Format the local time to "YYYY-MM-DD HH:mm:ss"
		const localTime = `${localYear}-${localMonth}-${localDay} ${localHours}:${localMinutes}:${localSeconds}`;
		return localTime;
	}

	renderedCallback() {
		let object = this.getObjectFromUrl(window.location.href);
		if (!object && !this.strObjectToCreate) {
			this.handleOnLoad();
		} else if (object && !this.strObjectToCreate) {
			this.strObjectToCreate = object;
			this.strTitle = "Create New " + this.strObjectToCreate;
			this.handleOnLoad();
		}
	}

	handleDataTableSave(event) {
		let tempProducts = [];
		this.productData.forEach((element) => {
			let draftElement = event.detail.draftValues.find((draftElement) => draftElement.Id === element.Id);
			if (draftElement) {
				if (draftElement.employees && draftElement.employees > 0) {
					element.employees = draftElement.employees;
					element.totalPrice = Number(element.unitPrice) * Number(element.employees);
				} else {
					element.employees = 0;
					element.totalPrice = 0;
				}
			}
			tempProducts.push(element);
		});
		this.draftValues = [];
		this.productData = tempProducts;
	}

	handleFieldChange(event) {
		if (event.target.value && event.target.fieldName == "AccountId") {
			this.recordid = event.target.value;
			this.handleOnLoad();
		}
	}

	async openSubtab(recordId) {
		const tabInfo = await getTabInfo(this.tabId);
		const primaryTabId = tabInfo.isSubtab ? tabInfo.parentTabId : tabInfo.tabId;
		const { isSubtab } = await getFocusedTabInfo();
		let counter = 0;
		let focusComplete = false;

		if (isSubtab) {
			// Open a record as a subtab of the current tab
			await openSubtab(primaryTabId, { recordId: recordId, focus: true });
		} else {
			await openTab({
				pageReference: {
					type: "standard__recordPage",
					attributes: {
						recordId: recordId,
						objectApiName: this.strObjectToCreate,
						actionName: "view"
					}
				},
				focus: true
			});
		}

		const alltabInfo = await getAllTabInfo();

		// check every 0.6 seconds if the record is focused 
		// After 10 attempts, show an alert message
		let intervalId = setInterval(function () {
			counter = counter + 1;
			if (counter == 10) {
				alert("Unable to focus on the new record. Please contact your administrator");
				clearInterval(intervalId);
				return;
			}
			if (focusComplete) {
				console.log("tab focus complete");
				clearInterval(intervalId);
				return;
			}
			alltabInfo.forEach((element) => {
				if (isSubtab) {
					if (element.subtabs) {
						element.subtabs.forEach((subtab) => {
							if (subtab.recordId === recordId) {
								focusTab(subtab.tabId);
								focusComplete = true;
							}
						});
					}
				} else {
					if (element.recordId === recordId) {
						focusTab(element.tabId);
						focusComplete = true;
					}
				}
			});
		}, 600);
	}
}