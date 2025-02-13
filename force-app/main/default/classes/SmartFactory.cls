/*
   Copyright 2011 Mavens Consulting, Inc.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

public class SmartFactory {
	private static System.LoggingLevel OBJECT_NAME_LOGGING_LEVEL = LoggingLevel.FINE;
	private static System.LoggingLevel FIELD_NAME_LOGGING_LEVEL = LoggingLevel.FINE;
	public static boolean FillAllFields = false;
	public static Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'ZP System Administrator'];
	public static UserRole objUserRole = [SELECT Id FROM UserRole WHERE Name = 'Core & Complete'];
	public static UserRole objAdminRole = [SELECT Id FROM UserRole WHERE Name = 'admin'];
	public static UserRole objEnagagementRole = [SELECT Id FROM UserRole WHERE Name = 'Engagement'];
	static final Map<String, Map<String, Schema.SObjectField>> FieldMapCache = new Map<String, Map<String, Schema.SObjectField>>();

	public static string defaultCountry = 'United States';
	public static string defaultCountryCode = 'US';
	public static string defaultState = 'California';
	public static string defaultStateCode = 'CA';
	static final Map<String, String> defaultPicklistValue = new Map<String, String>();

	// can't map by Schema.sObjectType, use object name String instead
	public static Map<String, Set<String>> ExcludedFields = new Map<String, Set<String>>{
		'All' => new Set<String>{ 'LastModifiedById', 'CreatedById', 'LastModifiedDate', 'CreatedDate', 'OwnerId', 'External_Key__c' },
		'Account' => new Set<String>{ 'Account_Manager__c', 'infer3__Score_Object_ID__c', 'Pricebook2__c', 'SIC_Id__c' },
		'Lead' => new Set<String>{ 'Unsupported_State__c' },
		'User' => new Set<String>{ 'IsActive', 'DelegatedApproverId', 'CallCenterId', 'ContactId', 'DelegatedApproverId', 'ManagerId', 'UserRoleId', 'FederationIdentifierId' },
		'Opportunity' => new Set<String>{
			'ContractId',
			'Pricebook2Id',
			'CampaignId',
			'Company_Migration__c',
			'infer3__Score_Object_ID__c',
			'LeadName__c',
			'Referred_By__c',
			'Sold_By__c',
			'Payment_Invoice__c',
			'Order__c'
		},
		'Lead' => new Set<String>{
			'CampaignId',
			'Infer_Score_ID_2__c',
			'infer3__Score_Object_ID__c',
			'mkto_si__MSIContactId__c',
			'NAICS_Id__c',
			'Referred_By__c',
			'SIC_Id__c',
			'Sold_By__c'
		},
		'Order' => new Set<String>{
			'ActivatedById',
			'BillToContactId',
			'CompanyAuthorizedById',
			'Company_Migration__c',
			'ContractId',
			'CustomerAuthorizedById',
			'OriginalOrderId',
			'ShipToContactId',
			'Specialist__c',
			'Pricebook2Id',
			'OpportunityId'
		},
		'OrderItem' => new Set<String>{ 'OriginalOrderItemId', 'QA_Completed_By__c', 'Results_Entered_By__c' },
		'Task' => new Set<String>{ 'WhoId', 'WhatId' }
	};

	// include nillable fields
	public static Map<String, Set<String>> IncludedFields = new Map<String, Set<String>>{
		'All' => new Set<String>{ 'Name' },
		'Account' => new Set<String>{ 'BillingState', 'BillingStateCode' },
		'Product2' => new Set<String>{ 'Family', 'ProductCode' },
		'PricebookEntry' => new Set<String>{ 'Product2Id', 'Pricebook2Id', 'UnitPrice', 'Maintain__c' },
		'Opportunity' => new Set<String>{ 'AccountId' },
		'Benefit_Order__c' => new Set<String>{ 'Opportunity__c', 'Account__c' },
		'Company_Migration__c' => new Set<String>{ 'Account__c' },
		'Order' => new Set<String>{ 'AccountId' },
		'OrderItem' => new Set<String>{ 'OrderId', 'UnitPrice', 'Quantity' }
	};

	public static SObject createSObject(String objectType) {
		return createSObject(objectType, false);
	}

	public static List<SObject> createSObjectList(String objectType, boolean cascade, Integer numberOfObjects) {
		List<SObject> sos = new List<SObject>();
		for (Integer i = 0; i < numberOfObjects; i++)
			sos.add(createSObject(objectType, cascade, i));
		return sos;
	}

	public static SObject createSObject(String objectType, boolean cascade, Integer counter) {
		Type objType = Type.forName(objectType) ;
		if (objType == null) {
			throw new UnsupportedObjectTypeException('Unsupported ObjectType ' + objectType);
		}
		Schema.sObjectType token = ((SObject)objType.newInstance()).getSObjectType();
		if (token == null) {
			throw new UnsupportedObjectTypeException('Unsupported ObjectType ' + objectType);
		}

		SObject obj = token.newSObject();

		for (Schema.SObjectField field : fieldMapFor(objectType).values()) {
			setFieldValue(obj, field, cascade, counter);
		}

		return obj;
	}

	public static SObject createSObject(String objectType, boolean cascade) {
		return createSObject(objectType, cascade, 1);
	}

	/**
        Returns a field map for a given sobject.

        Note : this method is kept public for Test cases to share the same field map info, without requiring a field desribe.

        @param objectType sobject api name for ex. Account
        @returns FieldMap [Key:FieldName,Value:Schema.SObjectField]
    */
	public static Map<String, Schema.SObjectField> fieldMapFor(String objectType) {
		Map<String, Schema.SObjectField> fieldMap = null;
		String normalizedObjectType = objectType.toLowerCase();

		if (FieldMapCache.containsKey(normalizedObjectType)) {
			fieldMap = FieldMapCache.get(normalizedObjectType);
		} else {
			fieldMap = Utils.getSObjectDescribe(objectType).fields.getMap();
			// cache it for next use
			FieldMapCache.put(normalizedObjectType, fieldMap);
		}

		return fieldMap;
	}

	static String getDefaultPicklistValue(SObject obj, Schema.DescribeFieldResult fieldDescribe) {
		String key = obj.getSObjectType() + '.' + fieldDescribe.getName();

		if (!DefaultPicklistValue.containsKey(key)) {
			List<Schema.PicklistEntry> entries = fieldDescribe.getPicklistValues();
			String value = entries.size() > 0 ? entries[0].getValue() : null;
			DefaultPicklistValue.put(key, value);
		}
		return DefaultPicklistValue.get(key);
	}

	static boolean isExcludedField(Schema.DescribeFieldResult fieldDescribe) {
		return ExcludedFields.get('All').contains(fieldDescribe.getName());
	}

	static boolean isExcludedField(SObject obj, Schema.DescribeFieldResult fieldDescribe) {
		Set<String> fields = ExcludedFields.get(obj.getSObjectType().getDescribe().getName());
		return fields == null ? false : fields.contains(fieldDescribe.getName());
	}

	static boolean isIncludedField(SObject obj, Schema.DescribeFieldResult fieldDescribe) {
		Set<String> fields = includedFields.get(obj.getSObjectType().getDescribe().getName());
		return fields == null ? false : fields.contains(fieldDescribe.getName());
	}

	static void setFieldValue(SObject obj, Schema.SObjectField field, boolean cascade, Integer counter) {
		Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

		if (
			fieldDescribe.isCreateable() &&
			(isIncludedField(obj, fieldDescribe) ||
			(((!fieldDescribe.isNillable() || FillAllFields) || (fieldDescribe.getType() == Schema.DisplayType.Reference && cascade)) &&
			!isExcludedField(fieldDescribe) &&
			!isExcludedField(obj, fieldDescribe)))
		) {
			if (fieldDescribe.getName().endsWith('Country')) {
				obj.put(field, defaultCountry);
			} else if (fieldDescribe.getName().endsWith('State')) {
				obj.put(field, defaultState);
			} else if (fieldDescribe.getName().endsWith('CountryCode')) {
				obj.put(field, defaultCountryCode);
			} else if (fieldDescribe.getName().endsWith('StateCode')) {
				obj.put(field, defaultStateCode);
			} else if (fieldDescribe.getType() == Schema.DisplayType.base64) {
				obj.put(field, blob.valueOf(counter.format()));
			} else if (fieldDescribe.getType() == Schema.DisplayType.Boolean) {
				obj.put(field, false);
			} else if (fieldDescribe.getType() == Schema.DisplayType.Combobox) {
				obj.put(field, counter.format());
			} else if (fieldDescribe.getType() == Schema.DisplayType.Currency) {
				obj.put(field, counter);
			} else if (fieldDescribe.getType() == Schema.DisplayType.Date) {
				obj.put(field, Date.today());
			} else if (fieldDescribe.getType() == Schema.DisplayType.DateTime) {
				obj.put(field, DateTime.now());
			} else if (fieldDescribe.getType() == Schema.DisplayType.Double) {
				obj.put(field, counter);
			} else if (fieldDescribe.getType() == Schema.DisplayType.Email) {
				obj.put(field, 'test' + counter.format() + '@test.com');
			} else if (fieldDescribe.getType() == Schema.DisplayType.EncryptedString) {
				obj.put(field, 's');
			} else if (fieldDescribe.getType() == Schema.DisplayType.Integer) {
				obj.put(field, counter);
			} else if (fieldDescribe.getType() == Schema.DisplayType.MultiPicklist) {
				obj.put(field, getDefaultPicklistValue(obj, fieldDescribe));
			} else if (fieldDescribe.getType() == Schema.DisplayType.Percent) {
				obj.put(field, counter);
			} else if (fieldDescribe.getType() == Schema.DisplayType.Phone) {
				obj.put(field, '123-456-7890');
			} else if (fieldDescribe.getType() == Schema.DisplayType.Picklist) {
				obj.put(field, getDefaultPicklistValue(obj, fieldDescribe));
			} else if (fieldDescribe.getName() == 'CommunityNickname' && fieldDescribe.getType() == Schema.DisplayType.String) {
				obj.put(field, 'test' + string.valueof(math.roundtolong(math.random() * 1000000)));
			} else if (fieldDescribe.getName() == 'UserName' && fieldDescribe.getType() == Schema.DisplayType.String) {
				obj.put(
					field,
					'test' +
					string.valueof(Userinfo.getOrganizationId()) +
					string.valueof(math.roundtolong(math.random() * 1000000)) +
					string.valueof(Datetime.now()).replace('-', '').replace(':', '').replace(' ', '') +
					'@test.com'
				);
			} else if (fieldDescribe.getType() == Schema.DisplayType.String) {
				obj.put(field, counter.format());
			} else if (fieldDescribe.getType() == Schema.DisplayType.Reference) {
				String referenceObjectType = fieldDescribe.getReferenceTo()[0].getDescribe().getName();
				if (referenceObjectType == 'RecordType') {
					setRecordType(obj);
				} else if (referenceObjectType == 'Profile') {
					obj.put(field, userProfile.Id);
				} else if (cascade && referenceObjectType != obj.getSObjectType().getDescribe().getName() && referenceObjectType != 'BusinessHours' && referenceObjectType != 'User') {
					// TODO avoid infinite loop for same-type references
					SObject reference = createSObject(referenceObjectType);
					insertObject(reference);
					obj.put(field, reference.Id);
				}
			} else if (fieldDescribe.getType() == Schema.DisplayType.TextArea) {
				obj.put(field, counter.format());
			} else if (fieldDescribe.getType() == Schema.DisplayType.Time) {
				obj.put(field, Time.newInstance(0, 0, 0, 0));
			} else if (fieldDescribe.getType() == Schema.DisplayType.URL) {
				obj.put(field, 'http://test' + counter + '.com');
			}
		}
	}

	static void setRecordType(SObject obj) {
		List<Schema.RecordTypeInfo> recordTypes = obj.getSObjectType().getDescribe().getRecordTypeInfos();
		if (recordTypes.size() > 1) {
			// all objects have default Master type
			for (Schema.RecordTypeInfo recordType : recordTypes) {
				if (recordType.isAvailable() && recordType.isDefaultRecordTypeMapping()) {
					obj.put('RecordTypeId', recordType.getRecordTypeId());
				}
			}
		}
	}

	static void insertObject(SObject reference) {
		addToLog(reference.getSObjectType().getDescribe().getName());
		Database.SaveResult result = Database.insert(reference, true);
		if (result.isSuccess())
			return;

		List<String> fields;
		String message, statusCode;
		String INDENT = '  ';
		String BR = '\n';

		List<Database.Error> errors = result.getErrors();
		for (Database.Error error : errors) {
			statusCode = error.getStatusCode().Name();
			message = error.getMessage();
			fields = error.getFields();
		}
	}

	static Map<String, Integer> objectTypeLog = new Map<String, Integer>();

	static void addToLog(String objectType) {
		Integer objCount;
		if (objectTypeLog.containsKey(objectType)) {
			objCount = objectTypeLog.get(objectType);
			objCount += 1;
		} else {
			objCount = 0;
		}
		objectTypeLog.put(objectType, objCount);
	}

	public static GF_Ticket__c createGFTicket(
		String strExternalId,
		String strCompanyId,
		String strSubject,
		String strEmail,
		String strTicketType,
		String strAdditionalData,
		String strDIVR,
		String strTags,
		String strReason
	) {
		GF_Ticket__c objGFTicket = new GF_Ticket__c(
			Id__c = strExternalId,
			Company_Id__c = strCompanyId,
			Subject__c = strSubject,
			Requester_Email__c = strEmail,
			Ticket_Type__c = strTicketType,
			Additional_Data__c = strAdditionalData,
			DIVR_Id__c = strDIVR,
			Tags__c = strTags,
			Reason__c = strReason,
			Requester_User_Id__c = '7756613826678425',
			Requester_User_Name__c = 'Test Requester',
			Processing_State__c = 'Queued',
			Body__c = 'Test body',
			Support_Request_Created_At__c = System.today()
		);
		return objGFTicket;
	}

	public class RecordTypeException extends Exception {
	}
}