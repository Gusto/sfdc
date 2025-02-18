/**
 * @name         : RecordCreateController
 * @author       : Praveen Sethu
 * @description  : Controller class to create a new record based on the data passed from LWC
 * @test
 *
 */
public without sharing class RecordCreateController {
	public static final String TAXCREDITS_TYPE_NEW_BUSINESS = 'New Business';
	public static final String TAXCREDITS_TYPE_PARTNERSHIP = 'Partnership';
	public static final String TAXCREDITS_PREFIX_RD = 'R&D';
	public class CustomException extends Exception {
	}

	/**
	 * @name         : ResponseWrapper
	 * @author       : Praveen Sethu
	 * @description  : Wrapper class to return the response back to LWC
	 * @test
	 *
	 */
	public class ResponseWrapper {
		// Declare all variables need to get list of available record types, accessible fields and default values
		@AuraEnabled
		public List<Record_Create__mdt> list_RecordCreate;

		@AuraEnabled
		public List<Record_Create_Fields__mdt> list_RecordCreateFields;

		@AuraEnabled
		public Boolean blnSuccess;

		@AuraEnabled
		public String strMessage;

		@AuraEnabled
		public String strDefaultRecordTypeId;

		@AuraEnabled
		public SObject objRecord;

		@AuraEnabled
		public Map<Id, RecordType> map_RecordTypes = new Map<Id, RecordType>();

		@AuraEnabled
		public Map<String, String> map_FieldTypes = new Map<String, String>();

		@AuraEnabled
		public Boolean blnNoRecordTypesAvailable = false;

		@AuraEnabled
		public ProductsWrapper objProductsWrapper;

		// Constructor
		public ResponseWrapper(
			List<Record_Create__mdt> list_RecordCreate,
			List<Record_Create_Fields__mdt> list_RecordCreateFields,
			String strDefaultRecordTypeId,
			Map<String, String> map_FieldTypes,
			Map<Id, RecordType> map_RecordTypes,
			Boolean blnNoRecordTypesAvailable,
			Boolean blnSuccess,
			String strMessage
		) {
			this.list_RecordCreate = list_RecordCreate;
			this.list_RecordCreateFields = list_RecordCreateFields;
			this.strDefaultRecordTypeId = strDefaultRecordTypeId;
			this.map_FieldTypes = map_FieldTypes;
			this.map_RecordTypes = map_RecordTypes;
			this.blnNoRecordTypesAvailable = blnNoRecordTypesAvailable;
			this.blnSuccess = blnSuccess;
			this.strMessage = strMessage;
		}

		public ResponseWrapper(SObject objRecord, Boolean blnSuccess, String strMessage) {
			this.objRecord = objRecord;
			this.blnSuccess = blnSuccess;
			this.strMessage = strMessage;
		}
	}

	public class ProductsWrapper {
		@AuraEnabled
		public List<PricebookEntry> list_Products;

		@AuraEnabled
		public Opportunity objOppty;

		public ProductsWrapper(List<PricebookEntry> list_Products, Opportunity objOppty) {
			this.list_Products = list_Products;
			this.objOppty = objOppty;
		}
	}

	/**
	 * @Description : Get all record types for the object and the fields that are accessible to the user and set default values by reading data from the parent object
	 * @Param        : strObjectName - Object API name of the record to be created
	 * @Param        : idRecord - Id of the parent object where the new button was clicked
	 * @Return      : Response wrapper that has all details to show in LWC
	 **/
	@AuraEnabled
	public static ResponseWrapper getRecordTypes(String strObjectName, Id idRecord) {
		// Declare all variables need to get list of available record types, accessible fields and default values
		Set<String> set_UserRoleNames = new Set<String>();
		Set<String> set_AvailableRecordTypeIds = new Set<String>();
		Set<String> set_FieldNames = new Set<String>();
		String strDefaultRecordTypeId = '';
		// parent object is the source object from where the record create is initiated
		String strParentObject = '';
		// Set of all available record typeIds for the user
		Set<Id> set_AllAvailableRecordTypeIds = new Set<Id>();
		List<SelectOption> recordTypes = new List<SelectOption>();
		Set<String> set_RecordTypeIds = new Set<String>();
		List<Record_Create__mdt> list_RecordCreate = new List<Record_Create__mdt>();
		List<Record_Create_Fields__mdt> list_RecordCreateFields = new List<Record_Create_Fields__mdt>();
		Map<String, String> map_FieldTypes = new Map<String, String>();
		List<Record_Create_Fields__mdt> list_AccessibleRecordCreateFields = new List<Record_Create_Fields__mdt>();
		Map<Id, RecordType> map_RecordTypes = new Map<Id, RecordType>();

		try {
			if (idRecord != null) {
				strParentObject = idRecord.getSObjectType().getDescribe().getName();
			}
			User objLoggedInUser = [SELECT Id, UserRole.Name FROM User WHERE Id = :UserInfo.getUserId()];
			String strLoggedInUserRole = objLoggedInUser?.UserRole?.Name;

			// strObjectName is the type of the object that is created
			Map<String, Schema.SObjectType> map_Schema = Schema.getGlobalDescribe();
			DescribeSObjectResult objDescribe = map_Schema.get(strObjectName).getDescribe();
			Map<String, Schema.SObjectField> map_Fields = objDescribe.fields.getMap();

			// build a map of field API name and field type
			for (String strField : map_Fields.keySet()) {
				map_FieldTypes.put(strField.toLowerCase(), String.valueOf(map_Fields.get(strField).getDescribe().getType()).toLowerCase());
			}

			for (RecordType objRecordType: [SELECT Id, Description FROM RecordType WHERE SObjectType = :strObjectName]) {
				map_RecordTypes.put(objRecordType.Id, objRecordType);
			}

			// get all record type for the object
			for (RecordTypeInfo info : objDescribe.getRecordTypeInfos()) {
				if (info.isAvailable() && info.getName() != 'Master') {
					recordTypes.add(new SelectOption(info.getRecordTypeId(), info.getName()));
					// Set default record type based on user's profile
					if (info.isDefaultRecordTypeMapping()) {
						strDefaultRecordTypeId = info.getRecordTypeId();
					}
					set_AllAvailableRecordTypeIds.add(info.getRecordTypeId());
				}
			}

			// Indicate a boolean flag if NO record type is available for the object
			Boolean blnNoRecordTypesAvailable = set_AllAvailableRecordTypeIds.isEmpty();

			// Include these next 3 lines to output the results during development and debugging
			for (SelectOption selopt : recordTypes) {
				set_RecordTypeIds.add(selopt.getValue());
			}

			// if record type is not available, get all the record create records for a specifc object
			// if not only specify object name and record type Ids that the user has access
			String strQuery = 'SELECT Id, Default_Roles__c, Record_Type_Id__c, DeveloperName, MasterLabel, Order__c, Add_Products__c FROM Record_Create__mdt WHERE Object_API__c = :strObjectName';

			if (blnNoRecordTypesAvailable) {
				list_RecordCreate = Database.query(strQuery);
			} else {
				list_RecordCreate = Database.query(strQuery + ' AND Record_Type_Id__c IN :set_RecordTypeIds');
			}

			for (Record_Create__mdt objRecordCreate : list_RecordCreate) {
				set_UserRoleNames = new Set<String>();
				if (String.isNotBlank(objRecordCreate.Default_Roles__c)) {
					set_UserRoleNames.addAll(objRecordCreate.Default_Roles__c.split(','));
				}
				// override default record type of the profile with record type configured for the role
				if (set_UserRoleNames.contains(strLoggedInUserRole) && set_AllAvailableRecordTypeIds.contains(objRecordCreate.Record_Type_Id__c)) {
					strDefaultRecordTypeId = objRecordCreate.Record_Type_Id__c;
				}

				if (String.isNotBlank(objRecordCreate.Record_Type_Id__c)) {
					set_AvailableRecordTypeIds.add(objRecordCreate.Record_Type_Id__c);
				}
			}

			// if still no default record type Id is found based on profile AND user roles, then set the first available record type Id
			if (!set_AvailableRecordTypeIds.contains(strDefaultRecordTypeId) && set_AvailableRecordTypeIds.size() > 0) {
				for (Id recordTypeId : set_AvailableRecordTypeIds) {
					if (set_AllAvailableRecordTypeIds.contains(recordTypeId)) {
						strDefaultRecordTypeId = recordTypeId;
						break;
					}
				}
			}

			// get all record create fields for the object (different queries based on whether record types are available or not)
			strQuery = 'SELECT Id, DeveloperName, MasterLabel, Default_Field__c, Default_Value__c, Is_Required__c, Is_Disabled__c, Record_Type__c, Field_API__c FROM Record_Create_Fields__mdt WHERE Record_Type__r.Object_API__c = :strObjectName';

			if (blnNoRecordTypesAvailable) {
				list_RecordCreateFields = Database.query(strQuery);
			} else {
				list_RecordCreateFields = Database.query(strQuery + ' AND Record_Type__r.Record_Type_Id__c IN :set_RecordTypeIds');
			}
			// get all field names to query from the parent object - used for setting default values
			for (Record_Create_Fields__mdt objRecordCreateField : list_RecordCreateFields) {
				// Default field is a comma separated list of fields (Format is source object-field api mame)
				if (String.isNotBlank(objRecordCreateField.Default_Field__c)) {
					// parse field name to query from the parent object
					String strDefaultField = getDefaultField(strParentObject, objRecordCreateField);
					// add to SET of field names to query to avoid duplicate fields
					if (String.isNotBlank(strDefaultField)) {
						set_FieldNames.add(strDefaultField);
					}
				} else {
					// if there is no default field, check if the field api is boolean - then set default value to false - IF default value is already not populated
					if (String.isNotBlank(objRecordCreateField.Field_API__c) && String.isBlank(objRecordCreateField.Default_Value__c) && map_Fields.containsKey(objRecordCreateField.Field_API__c)) {
						String strFieldType = String.valueOf(map_Fields.get(objRecordCreateField.Field_API__c).getDescribe().getType());
						if (strFieldType.equalsIgnoreCase('boolean')) {
							objRecordCreateField.Default_Value__c = 'false';
						}
					}
				}

				// check if the user has access to the field - display in LWC only the fields that the user has access to
				if (String.isNotBlank(objRecordCreateField.Field_API__c) && map_Fields.containsKey(objRecordCreateField.Field_API__c)) {
					if (map_Fields.get(objRecordCreateField.Field_API__c).getDescribe().isAccessible()) {
						list_AccessibleRecordCreateFields.add(objRecordCreateField);
					}
				}
			}

			// join the list of field names by comma - to use it in SOQL query
			String strFieldNamesToQuery = !set_FieldNames.isEmpty() ? String.join(new List<String>(set_FieldNames), ',') : '';

			// Default few fields for ardius opportunity record type - CUSTOM logic to populate default fields for tax credits
			if (strObjectName == 'Opportunity') {
				Boolean blnTaxCredits = false;
				Id idTaxCreditsRecordCreate = null;
				for (Record_Create__mdt objRecordCreate : list_RecordCreate) {
					if (objRecordCreate.Record_Type_Id__c == OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID) {
						blnTaxCredits = true;
						idTaxCreditsRecordCreate = objRecordCreate.Id;
					}
				}
				// Set default values on Tax Credits opportunity - default values are set on Tax Year, Name and Close Date
				if (blnTaxCredits) {
					Account objAccount;
					if (strParentObject == 'Account') {
						objAccount = [SELECT Id, Name FROM Account WHERE Id = :idRecord];
					}
					// Name default is set based on Opportunity Type
					// Tax Year default is set based on current date
					// Close Date default is set to last day of the month
					for (Record_Create_Fields__mdt objRecordCreateField : list_AccessibleRecordCreateFields) {
						if (objRecordCreateField.Record_Type__c == idTaxCreditsRecordCreate) {
							if (objRecordCreateField.Field_API__c == 'Tax_Year__c') {
								objRecordCreateField.Default_Value__c = String.ValueOf(opportunityNewExtension.calculateTaxYear(System.today()));
							}
						}
					}
				}
			}
			// Query fields from the parent obejct
			if (idRecord != null && String.isNotBlank(strFieldNamesToQuery)) {
				Sobject objParent = Database.query('SELECT ' + strFieldNamesToQuery + ' FROM ' + strParentObject + ' WHERE Id = :idRecord');
				for (Record_Create_Fields__mdt objRecordCreateField : list_AccessibleRecordCreateFields) {
					String strExistingDefaultValue = objRecordCreateField.Default_Value__c;
					if (String.isNotBlank(objRecordCreateField.Default_Field__c)) {
						// parse default field to get the field name
						String strDefaultField = getDefaultField(strParentObject, objRecordCreateField);
						if (String.isNotBlank(strDefaultField)) {
							// if field name contains . then it is a relationship field - get the value from the parent object
							if (!strDefaultField.contains('.')) {
								objRecordCreateField.Default_Value__c = String.valueOf(objParent.get(strDefaultField));
							} else {
								objRecordCreateField.Default_Value__c = returnFieldValue(strDefaultField, objParent);
							}

							// Use the default hard coded value from the metadata if the field is not populated in the parent object
							if (String.isBlank(objRecordCreateField.Default_Value__c) && String.isNotBlank(strExistingDefaultValue)) {
								objRecordCreateField.Default_Value__c = strExistingDefaultValue;
							}
						}
					}
				}
			}
			// Summary - accessible record types queried, accessible fields queried, default values set (inclucing custom logic for Tax credits)
			// All data available to show in LWC for dynamic record creation
			return new ResponseWrapper(list_RecordCreate, list_AccessibleRecordCreateFields, strDefaultRecordTypeId, map_FieldTypes, map_RecordTypes, blnNoRecordTypesAvailable, true, 'Success');
		} catch (Exception objEx) {
			// In case of exception log them in Exception Log table and show it in the UI
			ExceptionLogUtil.logException('RecordCreateController', 'getRecordTypes', null, objEx);
			return new ResponseWrapper(new List<Record_Create__mdt>(), new List<Record_Create_Fields__mdt>(), '', new Map<String, String>(), map_RecordTypes, false, false, objEx.getMessage());
		}
	}

	/**
	 * @Description : Get the default field name from comma separated list of default fields
	 * @Param        : strParentObject - parent object where the new button was clicked
	 * @Param        : objRecordCreateField - Each record create field record
	 * @Return      : Default field API name
	 **/
	public static String getDefaultField(String strParentObject, Record_Create_Fields__mdt objRecordCreateField) {
		// Default field on Record Create is a comma separated list of fields (Format is source object-field api mame)
		// Parse the text to get the field name based on the parent object
		String strFieldNameToReturn = '';
		List<String> list_FieldNames = objRecordCreateField.Default_Field__c.split(',');
		for (String strFieldName : list_FieldNames) {
			List<String> list_FieldNameParts = strFieldName.split('-');
			// split each default field by - (first parameter is the source object and second is the field name to return)
			if (list_FieldNameParts.get(0) == strParentObject) {
				strFieldNameToReturn = (list_FieldNameParts.get(1));
			}
		}
		return strFieldNameToReturn;
	}

	/**
	 * @Description : Create a new record based on the data passed from LWC
	 * @Param        : strPayload - Data received from LWC to create a new record
	 * @Return      : ResponseWrapper - Wrapper that has the record created and the status of the operation
	 **/
	@AuraEnabled
	public static ResponseWrapper createRecord(String strPayload, Boolean blnAddProducts) {
		try {
			// payload is a JSON string of field API name and field values - Desearlize the JSON to build a map of field API name and field values
			Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(strPayload);
			// strObjectName api name of the object to create a new record
			String strObjectName = (String) data.get('sObjectType');

			Map<String, Schema.SObjectType> map_Schema = Schema.getGlobalDescribe();
			DescribeSObjectResult objDescribe = map_Schema.get(strObjectName).getDescribe();
			Map<String, Schema.SObjectField> map_Fields = objDescribe.fields.getMap();
			Boolean blnOppty = false;
			Record_Create__mdt objRecordCreate;
			List<Pricebook2> list_PriceBook;

			Sobject objectToInsert = (Sobject) Type.forName('Schema.' + (String) data.get('sObjectType')).newInstance();
			// Set data from map of fields to Sobject (exclude sObjectType as it is only a reference field to know which object record to create)
			for (String key : data.keySet()) {
				if (key != 'sObjectType') {
					if (map_Fields.containsKey(key)) {
						String strFieldType = String.valueOf(map_Fields.get(key).getDescribe().getType());

						// build custom logic for date and date/time fields to set in the right format
						if (strFieldType.equalsIgnoreCase('date') && data.get(key) != null) {
							objectToInsert.put(key, Date.valueOf(String.valueOf(data.get(key))));
						} else if (strFieldType.equalsIgnoreCase('datetime') && data.get(key) != null) {
							String strDateTime = String.valueOf(data.get(key));
							strDateTime = strDateTime.split('\\.')[0].replace('T', ' ');
							if (String.isNotBlank(strDateTime)) {
								DateTime localTime = DateTime.valueOf(strDateTime);
								Datetime GMTDate = Datetime.newInstanceGmt(localTime.year(), localTime.month(), localTime.day(), localTime.hour(), localTime.minute(), localTime.second());
								objectToInsert.put(key, GMTDate);
							}
						} else if (strFieldType.equalsIgnoreCase('double')) {
							Decimal decValue = String.isNotBlank(String.valueOf(data.get(key))) ? Decimal.valueOf(String.valueOf(data.get(key))) : null;
							objectToInsert.put(key, decValue);
						} else {
							// if no date or date/time field, set the value as it is
							objectToInsert.put(key, data.get(key));
						}
						// if tax year field is present, validate the value and throw exception
						if (key == 'Tax_Year__c' && !opportunityNewExtension.validateTaxYear(String.valueOf(data.get(key)))) {
							throw new CustomException('Invalid Tax Year, Please enter a valid year value.');
						}
					}
				} else if (key == 'sObjectType' && String.valueOf(data.get(key)) == 'Opportunity') {
					blnOppty = true;
				}
			}

			// Add Default Pricebook and Pricebook entries if SobjectType is Opportunity
			if (blnOppty) {
				Id idRecordType = (Id) objectToInsert.get('RecordTypeId');
				// Query record create metadata
				List<Record_Create__mdt> list_RecordCreate = [
					SELECT Id, Add_Products__c, Default_Payment_Plan__c, Default_Products__c
					FROM Record_Create__mdt
					WHERE Object_API__c = 'Opportunity' AND Record_Type_Id__c = :idRecordType
				];

				if (!list_RecordCreate.isEmpty()) {
					objRecordCreate = list_RecordCreate[0];
					// If metadata is configured to add products, get the default pricebook and pricebook entries
					if (objRecordCreate.Add_Products__c && String.isNotBlank(objRecordCreate.Default_Payment_Plan__c)) {
						// Get the default pricebook
						list_PriceBook = [
							SELECT Id, Name, (SELECT Id, UnitPrice, Product2.Name FROM PriceBookEntries WHERE UnitPrice > 0)
							FROM Pricebook2
							WHERE Name = :objRecordCreate.Default_Payment_Plan__c AND IsActive = TRUE
							LIMIT 1
						];
						if (!list_PriceBook.isEmpty()) {
							objectToInsert.put('Pricebook2Id', list_PriceBook[0].Id);
						}
					}
				}
			}

			// All data from Payload is passed on to Sobject - Create a new record
			insert objectToInsert;
			Id idRecord = (Id) objectToInsert.get('Id');
			// Re query the inserted record and return Id and name back to LWC
			SObject sobjQuery = Database.query('SELECT Id, Name FROM ' + objectToInsert.getSObjectType().getDescribe().getName() + ' WHERE Id = :idRecord');
			String strObject = idRecord.getSObjectType().getDescribe().getName();

			ResponseWrapper objResponseWrapper = new ResponseWrapper(sobjQuery, true, 'Record created successfully');
			// If inserted object is Opportunity, create new Opportunity Contact Roles
			if (strObject == 'Opportunity') {
				opportunityNewExtension.createContactRoles(idRecord);
				if (blnAddProducts || Test.isRunningTest()) {

					// Re query the opportunity to get updated contractor and employee counts
					Opportunity objOppty = [
						SELECT Id, NumberOfEmployees__c, Number_of_Contractors__c,EE_Active_Count__c
						FROM Opportunity
						WHERE Id = :idRecord
					];
					// Create line items for default products
					if (objRecordCreate != null && String.isNotBlank(objRecordCreate.Default_Products__c) && list_PriceBook != null) {
						Decimal decNumberOfEmployees = 0;
						if (objOppty.EE_Active_Count__c != null) {
							decNumberOfEmployees = objOppty.EE_Active_Count__c;
						} else {
							decNumberOfEmployees = objOppty.NumberOfEmployees__c != null ? objOppty.NumberOfEmployees__c : 0;
						}
						//objOppty.NumberOfEmployees__c != null ? objOppty.NumberOfEmployees__c : 0;
						Decimal decNumberOfContractors = objOppty.Number_of_Contractors__c != null ? objOppty.Number_of_Contractors__c : 0;
						Decimal decQuantity = decNumberOfEmployees + decNumberOfContractors;

						if (decQuantity > 0) {
							List<String> list_DefaultProducts = objRecordCreate.Default_Products__c.split(',');
							List<String> list_EntryIds = new List<String>();
							for (PricebookEntry objEntry : list_PriceBook[0].PriceBookEntries) {
								if (list_DefaultProducts.contains(objEntry.Product2.Name)) {
									list_EntryIds.add(objEntry.Id + ',' + decQuantity);
								}
							}
							// Create line items for default products based on Default Products
							System.debug('list_EntryIds: ' + list_EntryIds);
							if (!list_EntryIds.isEmpty()) {
								createLineItems(list_EntryIds, idRecord);
							}
						}
					}
					// Query the opportunity and their line items
					objOppty = [
						SELECT Id, (SELECT Id, PricebookEntryId FROM OpportunityLineItems), Pricebook2Id, NumberOfEmployees__c, Number_of_Contractors__c,EE_Active_Count__c
						FROM Opportunity
						WHERE Id = :idRecord
					];
					List<PricebookEntry> list_Products;
					// Query all products related to Opportunity's Pricebook
					if (objOppty.Pricebook2Id != null) {
						list_Products = [SELECT Id, Product2Id, Product2.Name, UnitPrice,Base_Price__c,Product2.Description FROM PricebookEntry WHERE Pricebook2Id = :objOppty.Pricebook2Id ORDER BY Product2.Name];
					}
					objResponseWrapper.objProductsWrapper = new ProductsWrapper(list_Products, objOppty);
				}
			}
			return objResponseWrapper;
		} catch (Exception objEx) {
			// In case of exception show reason back in the LWC
			ExceptionLogUtil.logException('RecordCreateController', 'createRecord', null, objEx);
			return new ResponseWrapper(null, false, objEx.getMessage());
		}
	}

	/**
	 * @Description : Return value of the field on the parent object (applies only for relationship fields)
	 * @Param        : strDefaultField - Field API name to return the value
	 * @Return      : objParent - Parent object from where the field value is to be returned
	 **/
	public static String returnFieldValue(String strDefaultField, SObject objParent) {
		// Returns value from relationship fields (Example - Sold_By__r.Name)
		String strFieldValue = '';
		String[] list_FieldAPI = strDefaultField.split('\\.');
		String strFieldName = list_FieldAPI[list_FieldAPI.size() - 1];

		SObject soObjecTemp;
		Integer counter = 0;
		// Iterate over the relationship fields to get the value
		for (String strFieldAPI : list_FieldAPI) {
			if (counter != list_FieldAPI.size() - 1) {
				soObjecTemp = objParent.getSObject(strFieldAPI);
				// stop if the relationship field is null
				if (soObjecTemp == null) {
					break;
				}
				counter = counter + 1;
			} else if (soObjecTemp != null) {
				strFieldValue = String.valueOf(soObjecTemp.get(strFieldName));
			}
		}

		return strFieldValue;
	}

	/**
	 * @Description : Create line items for the opportunity based on the products selected
	 * @Param        : list_EntryIds - List of pricebook entry Ids to create line items (This is a comma separated list of pricebook entry Id and quantity)
	 * @Param        : idRecord - Opportunity record Id
	 * @Return      : String - Returns 'SUCCESS' if line items are created successfully
	 **/
	@AuraEnabled
	public static String createLineItems(List<String> list_EntryIds, Id idRecord) {
		Map<Id, OpportunityLineItem> map_ExistingProducts = new Map<Id, OpportunityLineItem>();
		Map<Id, PricebookEntry> map_Entries = new Map<Id, PricebookEntry>();
		List<OpportunityLineItem> list_LineItemsToInsert = new List<OpportunityLineItem>();
		List<OpportunityLineItem> list_LineItemsToUpdate = new List<OpportunityLineItem>();
		List<OpportunityLineItem> list_LineItemsToDelete = new List<OpportunityLineItem>();
		List<Id> selectedProductIds = new List<Id>();
		try {
			Opportunity objOppty = [SELECT Id, (SELECT Id, PricebookEntryId,Base_Price__c,Unit_Price__c FROM OpportunityLineItems), Pricebook2Id, NumberOfEmployees__c,EE_Active_Count__c FROM Opportunity WHERE Id = :idRecord];

			// Build a list of existing products on the opportunity
			for (OpportunityLineItem objLineItem : objOppty.OpportunityLineItems) {
				map_ExistingProducts.put(objLineItem.PricebookEntryId, objLineItem);
			}
			// list_EntryIds is a comma separated list of pricebook entry Id and quantity
			Set<Id> set_EntryIds = new Set<Id>();
			System.debug('list_EntryIds: ' + list_EntryIds);
			for (String strLineItem : list_EntryIds) {
				set_EntryIds.add(strLineItem.split(',')[0]);
			}

			System.debug('set_EntryIds: ' + set_EntryIds);
			// Map of pricebook entriy Id and pricebook entry
			for (PricebookEntry objEntry : [SELECT Id, UnitPrice,Base_Price__c,Product2Id FROM PricebookEntry WHERE Id IN :set_EntryIds]) {
				map_Entries.put(objEntry.Id, objEntry);
				selectedProductIds.add(objEntry.Product2Id);
			}

			String strProductValidation = OpportunityProductController.validateSelectedProducts(idRecord, selectedProductIds);
			if (String.isNotBlank(strProductValidation)) {
				return strProductValidation;
			}
			
			// Create line items ONLY when the number of employees is greater than 0
			for (String strLineItem : list_EntryIds) {
				System.debug('strLineItem: ' + strLineItem);
				String strEntryId = strLineItem.split(',')[0];
				Integer intQuantity = Integer.valueOf(strLineItem.split(',')[1]);
				System.debug('intQuantity: ' + intQuantity);
				String strDescription = '';
				if (strLineItem.split(',').size() > 2) {
					strDescription = strLineItem.split(',')[2];
				}
				// do not create line items for products that are already added
				// check if the product is available in the pricebook
				if (!map_ExistingProducts.containsKey(strEntryId) && map_Entries.containsKey(strEntryId)) {
					PricebookEntry objEntry = map_Entries.get(strEntryId);
					if (intQuantity > 0) {

						OpportunityLineItem objOpportunityLineItem = new OpportunityLineItem();
						objOpportunityLineItem.OpportunityId = idRecord;
						//objOpportunityLineItem.Product2Id = priceBookEntry.product2Id;
						objOpportunityLineItem.PricebookEntryId = strEntryId;
						objOpportunityLineItem.Unit_Price__c = objEntry.UnitPrice;
						objOpportunityLineItem.Base_Price__c = objEntry.Base_Price__c;
						objOpportunityLineItem.Quantity = intQuantity;
						objOpportunityLineItem.TotalPrice = objOpportunityLineItem.Unit_Price__c * objOpportunityLineItem.Quantity + objOpportunityLineItem.Base_Price__c;
						objOpportunityLineItem.Description = strDescription;

						list_LineItemsToInsert.add(objOpportunityLineItem);
					}
				} else if (map_ExistingProducts.containsKey(strEntryId)) {
					OpportunityLineItem objLineItem = map_ExistingProducts.get(strEntryId);
					if (intQuantity == 0) {
						list_LineItemsToDelete.add(objLineItem);
					} else {
						objLineItem.Quantity = intQuantity;
						objLineItem.UnitPrice = map_Entries.get(strEntryId).UnitPrice;
						list_LineItemsToUpdate.add(objLineItem);
					}
				}
			}
			System.debug('list_LineItemsToInsert: ' + list_LineItemsToInsert);
			System.debug('list_LineItemsToUpdate: ' + list_LineItemsToUpdate);
			System.debug('list_LineItemsToDelete: ' + list_LineItemsToDelete);
			if (!list_LineItemsToUpdate.isEmpty()) {
				update list_LineItemsToUpdate;
			}
			if (!list_LineItemsToInsert.isEmpty()) {
				insert list_LineItemsToInsert;
			}

			if (!list_LineItemsToDelete.isEmpty()) {
				delete list_LineItemsToDelete;
			}
			return 'SUCCESS';
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('RecordCreateController', 'createLineItems', null, objEx);
			return objEx.getMessage();
		}
	}
}