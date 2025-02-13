/**
 * @name         ZPPayrollAuditTriggerHelper
 * @author       Sanjay Paryani
 * @date         11-24-2021
 * @description  Methods to execute on ZPPayrollAuditTrigger events
 * @test class   ZPPayrollAuditTriggerHelperTest
 */
public class ZPPayrollAuditTriggerHelper {
	public static Boolean skipTrigger = false;
	// Key: "Company ID;State", Value: Payroll_Audit__c record
	public static Map<String, Payroll_Audit__c> map_QueriedPayrollAuditRecords;
	public static Map<String, Quarterly_File__c> map_QueriedQuarterlyFileRecords;
	public static Map<String, Account> map_QueriedAccounts;
	public static Map<String, Contact> map_QueriedContacts;
	public static Set<Schema.sObjectField> set_QuarterlyFileFields = new Set<Schema.sObjectField>();
	public static Set<String> set_QuarterlyFileInsertFields = new Set<String>();
	public static Set<String> set_CommonFields = new Set<String>();
	public static Set<String> set_ManualLookupFields = new Set<String>();
	public static Set<Schema.sObjectField> set_PayrollAuditFields = new Set<Schema.sObjectField>();
	public Map<String, ZP_Payroll_Audit__c> map_SimilarZPPayrollAudits;
	public Map<String, ZP_Payroll_Audit__c> map_QuarterlyFilesToCreate;
	public static String PAYROLL_AUDIT_FIELDSET = 'Payroll_Audit_CSV_Fields';
	public static String QUARTERLY_FILE_INSERTCHECK_FIELDSET = 'Quarterly_File_Insert_Check_CSV_Fields';
	public static String QUARTERLY_FILE_FIELDSET = 'Quarterly_File_CSV_Fields';
	public static String PAYROLL_AUDIT_STATE_ADDED_AT_FIELD = 'State_Added_At__c';
	public static String PAYROLL_AUDIT_JOINED_AT_FIELD = 'joined_at__c';
	public static String PAYROLL_AUDIT_HAS_HISTORICAL_FIELD = 'has_historical__c';
	public static String PAYROLL_AUDIT_DELINQUENT_FIELD = 'delinquent__c';
	public static String PAYROLL_AUDIT_EXEMPT_FIELD = 'exempt__c';
	public static String PAYROLL_AUDIT_ACTIVE_SOFT_SUSPEND_FIELD = 'active_soft_suspend__c';
	public static String PAYROLL_AUDIT_HAS_EXTERNAL_FIELD = 'has_external__c';
	public static String PAYROLL_AUDIT_SUI_RATE_FIELD = 'SUI_Rate__c';
	public static String PAYROLL_AUDIT_SUI_SC_RATE_FIELD = 'SUI_SC_Rate__c';
	public static String QUARTERLY_FILE_QUARTER_NAME_FIELD = 'Quarter_Name__c';
	public static String QUARTERLY_FILE_PAYROLL_AUDIT_FIELD = 'Payroll_Audit__c';
	public static String QUARTERLY_FILE_QUARTERLY_GROSS_WAGES_FIELD = 'Quarterly_Gross_Wages__c';
	public static String QUARTERLY_FILE_QUARTERLY_SUBJECT_WAGES_FIELD = 'Quarterly_Subject_Wages__c';
	public static String QUARTERLY_FILE_QUARTERLY_TAXES_FIELD = 'Quarterly_Taxes__c';
	public static String QUARTERLY_FILE_UPDATED_GROSS_WAGES_FIELD = 'Updated_Gross_Wages__c';
	public static String QUARTERLY_FILE_UPDATED_QUARTERLY_TAXES_FIELD = 'Updated_Quarterly_Taxes__c';
	public static String QUARTERLY_FILE_UPDATED_SUBJECT_WAGES_FIELD = 'Updated_Subject_Wages__c';
	public static String PAYROLL_AUDIT_TYPE_STATE_ADDITION = 'State Addition';
	public static String PAYROLL_AUDIT_TYPE_ONBNG = 'Onboarding';
	public static String ZP_PAYROLL_AUDIT_TYPE_SUI_ONBNG = 'SUI Onboarding';
	public static String ZP_PAYROLL_AUDIT_TYPE_WH_ONBNG = 'WH Onboarding';
	public static String ZP_PAYROLL_AUDIT_TYPE_SUI_STATE_ADDITION = 'SUI State Addition';
	public static String ZP_PAYROLL_AUDIT_TYPE_WH_STATE_ADDITION = 'WH State Addition';
	public final static ID PAYROLL_AUDIT_SUI_RT_ID = Cache.getRecordTypeId('Payroll_Audit__c', 'SUI');
	public final static ID PAYROLL_AUDIT_WH_RT_ID = Cache.getRecordTypeId('Payroll_Audit__c', 'WH');
	public static Map<String, ID> map_ZPPayrollAuditTypes = new Map<String, ID>{
		ZP_PAYROLL_AUDIT_TYPE_SUI_ONBNG => PAYROLL_AUDIT_SUI_RT_ID,
		ZP_PAYROLL_AUDIT_TYPE_SUI_STATE_ADDITION => PAYROLL_AUDIT_SUI_RT_ID,
		ZP_PAYROLL_AUDIT_TYPE_WH_ONBNG => PAYROLL_AUDIT_WH_RT_ID,
		ZP_PAYROLL_AUDIT_TYPE_WH_STATE_ADDITION => PAYROLL_AUDIT_WH_RT_ID
	};
	public static Map<String, String> map_PayrollAuditTypes = new Map<String, String>{
		ZP_PAYROLL_AUDIT_TYPE_SUI_ONBNG => PAYROLL_AUDIT_TYPE_ONBNG,
		ZP_PAYROLL_AUDIT_TYPE_WH_ONBNG => PAYROLL_AUDIT_TYPE_ONBNG,
		ZP_PAYROLL_AUDIT_TYPE_SUI_STATE_ADDITION => PAYROLL_AUDIT_TYPE_STATE_ADDITION,
		ZP_PAYROLL_AUDIT_TYPE_WH_STATE_ADDITION => PAYROLL_AUDIT_TYPE_STATE_ADDITION
	};
	public Map<String, String> map_DMLInsertErrors = new Map<String, String>();

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Handles After Insert Context
	 * @Parm        : list_ZPPayrollAudits - List of Payroll Audit rows from CSV
	 * @Return      : N/A
	 **/
	public void processBeforeInsert(List<ZP_Payroll_Audit__c> list_ZPPayrollAudits) {
		for (ZP_Payroll_Audit__c objZPPayrollAudit : list_ZPPayrollAudits) {
			setProcessingState(IntegrationUtils.QUEUED_STATE, '', objZPPayrollAudit);
		}

		createCollectionsBefore(list_ZPPayrollAudits);
		processPayrollAuditCSV();

		// Handle the dml errors via addError
		for (ZP_Payroll_Audit__c objZPPayrollAudit : list_ZPPayrollAudits) {
			//Ignore records with Dead processing state
			if (objZPPayrollAudit.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}

			if (map_DMLInsertErrors.containsKey(objZPPayrollAudit.Event_Id__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, map_DMLInsertErrors.get(objZPPayrollAudit.Event_Id__c), objZPPayrollAudit);
			} else if (objZPPayrollAudit.Processing_State__c == IntegrationUtils.QUEUED_STATE) {
				setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Information is successfully processed', objZPPayrollAudit);
			}
		}
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Handles Before Update Context
	 * @Parm        : list_ZPPayrollAudits - List of Payroll Audit rows from CSV
	 * @Return      : N/A
	 **/
	public void processBeforeUpdate(Map<Id, ZP_Payroll_Audit__c> map_ZPPayrollAudits, Map<Id, ZP_Payroll_Audit__c> map_OldZPPayrollAudits) {
		for (ZP_Payroll_Audit__c objZPPayrollAudit : map_ZPPayrollAudits.values()) {
			ZP_Payroll_Audit__c objOldZPPayrollAudit = map_OldZPPayrollAudits.get(objZPPayrollAudit.Id);

			objZPPayrollAudit.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			objZPPayrollAudit.Message__c = '';
		}

		createCollectionsBefore(map_ZPPayrollAudits.values());
		processPayrollAuditCSV();

		// Handle the dml errors via addError
		for (ZP_Payroll_Audit__c objZPPayrollAudit : map_ZPPayrollAudits.values()) {
			//Ignore records with Dead processing state
			if (objZPPayrollAudit.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}

			if (map_DMLInsertErrors.containsKey(objZPPayrollAudit.Event_Id__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, map_DMLInsertErrors.get(objZPPayrollAudit.Event_Id__c), objZPPayrollAudit);
			} else if (objZPPayrollAudit.Processing_State__c == IntegrationUtils.QUEUED_STATE) {
				setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Information is successfully processed', objZPPayrollAudit);
			}
		}
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Processes Payroll_Audit__c records
	 * @Parm        : objZPPayrollAudit - Instance of ZP_Payroll_Audit__c
	 * @Return      : N/A
	 **/
	public void processPayrollAuditCSV() {
		Map<String, Payroll_Audit__c> map_PayrollAuditsToInsert = new Map<String, Payroll_Audit__c>();
		insertPayrollAudit(map_PayrollAuditsToInsert);
		insertQuartelyFiles(map_PayrollAuditsToInsert);
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : To create collections to be used across various methods.
	 * @Parm        : list_ZPPayrollAudits - List of new v records
	 * @Return      : N/A
	 **/
	public void createCollectionsBefore(List<ZP_Payroll_Audit__c> list_ZPPayrollAudits) {
		Set<String> set_CompanyIds = new Set<String>();
		Set<String> set_UserIds = new Set<String>();
		Set<Id> set_QueriedPayrollAudits = new Set<Id>();
		Boolean blnCreateQuarterlyFileInsert = false;
		// Key: Company ID + State, Value: Row
		map_SimilarZPPayrollAudits = new Map<String, ZP_Payroll_Audit__c>();
		map_QuarterlyFilesToCreate = new Map<String, ZP_Payroll_Audit__c>();
		map_QueriedAccounts = new Map<String, Account>();
		map_QueriedContacts = new Map<String, Contact>();
		map_QueriedPayrollAuditRecords = new Map<String, Payroll_Audit__c>();
		map_QueriedQuarterlyFileRecords = new Map<String, Quarterly_File__c>();

		Schema.FieldSet objZPPAFieldSet = Schema.SObjectType.ZP_Payroll_Audit__c.fieldSets.getMap().get(PAYROLL_AUDIT_FIELDSET);

		Schema.FieldSet objQFInsertCheckFieldSet = Schema.SObjectType.Quarterly_File__c.fieldSets.getMap().get(QUARTERLY_FILE_INSERTCHECK_FIELDSET);

		Schema.FieldSet objZPQFFieldSet = Schema.SObjectType.ZP_Payroll_Audit__c.fieldSets.getMap().get(QUARTERLY_FILE_FIELDSET);

		// Inserting QF Insert Check fields into set_QuarterlyFileInsertFields
		for (Schema.FieldSetMember objFieldMember : objQFInsertCheckFieldSet.getFields()) {
			set_QuarterlyFileInsertFields.add(objFieldMember.getFieldPath());
		}

		// Inserting All Payroll Audit CSV fields from Payroll Audit into set_PayrollAuditFields
		for (Schema.FieldSetMember objFieldMember : objZPPAFieldSet.getFields()) {
			set_PayrollAuditFields.add(objFieldMember.getSObjectField());
		}

		// Inserting QF CSV fields into set_QuarterlyFileFields
		for (Schema.FieldSetMember objFieldMember : objZPQFFieldSet.getFields()) {
			set_QuarterlyFileFields.add(objFieldMember.getSObjectField());
		}

		for (ZP_Payroll_Audit__c objZPPayrollAudit : list_ZPPayrollAudits) {
			String strMapIdentifier = '';
			String strCompanyId = '';
			String strState = '';
			String strZPUserId = '';
			String strAgencyName = '';

			if (String.isNotBlank(objZPPayrollAudit.Company_Id__c)) {
				set_CompanyIds.add(objZPPayrollAudit.Company_Id__c);
				strCompanyId = objZPPayrollAudit.Company_Id__c;
			}

			if (String.isNotBlank(objZPPayrollAudit.Admin_User_ID__c)) {
				set_UserIds.add(objZPPayrollAudit.Admin_User_ID__c);
				strZPUserId = objZPPayrollAudit.Admin_User_ID__c;
			}

			if (String.isNotBlank(objZPPayrollAudit.State__c)) {
				strState = objZPPayrollAudit.State__c;
			}

			if (String.isNotBlank(objZPPayrollAudit.Agency_Name__c)) {
				strAgencyName = objZPPayrollAudit.Agency_Name__c;
			}

			// Check if company id, state values are present, but not for SUI Or WH state addition payroll audits
			// State Additions will not need Quarterly files created
			if (String.isNotBlank(strCompanyId) && String.isNotBlank(strState) && String.isNotBlank(strAgencyName)) {
				strMapIdentifier = strCompanyId + ';' + strState + ';' + strAgencyName;
				map_SimilarZPPayrollAudits.put(strMapIdentifier, objZPPayrollAudit);

				if (
					((objZPPayrollAudit.Quarterly_Gross_Wages__c != 0 &&
					objZPPayrollAudit.Quarterly_Gross_Wages__c != null) ||
					(objZPPayrollAudit.Quarterly_Subject_Wages__c != 0 &&
					objZPPayrollAudit.Quarterly_Subject_Wages__c != null) ||
					(objZPPayrollAudit.Quarterly_Taxes__c != 0 &&
					objZPPayrollAudit.Quarterly_Taxes__c != null)) &&
					objZPPayrollAudit.Type__c != ZP_PAYROLL_AUDIT_TYPE_SUI_STATE_ADDITION &&
					objZPPayrollAudit.Type__c != ZP_PAYROLL_AUDIT_TYPE_WH_STATE_ADDITION
				) {
					blnCreateQuarterlyFileInsert = true;
					map_QuarterlyFilesToCreate.put(strMapIdentifier, objZPPayrollAudit);
				}
			}
		}

		for (Payroll_Audit__c objAudit : [
			SELECT Id, Company_ID__c, Id__c, State__c, Admin_User_ID__c, Type__c, Agency_Name__c
			FROM Payroll_Audit__c
			WHERE Company_ID__c != NULL AND Company_ID__c IN :set_CompanyIds AND State__c != NULL AND Agency_Name__c != NULL
		]) {
			String strKey = objAudit.Company_ID__c + ';' + objAudit.State__c + ';' + objAudit.Agency_Name__c;
			map_QueriedPayrollAuditRecords.put(strKey, objAudit);
			set_QueriedPayrollAudits.add(objAudit.Id);
		}

		for (Account objAccount : [SELECT Id, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c != NULL AND ZP_Company_ID__c IN :set_CompanyIds]) {
			map_QueriedAccounts.put(objAccount.ZP_Company_ID__c, objAccount);
		}

		for (Contact objContact : [SELECT ID, ZP_User_Id__c FROM Contact WHERE ZP_User_Id__c != NULL AND ZP_User_Id__c IN :set_UserIds]) {
			map_QueriedContacts.put(objContact.ZP_User_Id__c, objContact);
		}

		if (!set_CompanyIds.isEmpty() && !set_QueriedPayrollAudits.isEmpty()) {
			for (Quarterly_File__c objQuarterlyFile : [
				SELECT Id, Company_ID__c, State__c, Quarter_Name__c, Payroll_Audit__c
				FROM Quarterly_File__c
				WHERE Company_ID__c != NULL AND Company_ID__c IN :set_CompanyIds AND State__c != NULL AND Payroll_Audit__c != NULL AND Payroll_Audit__c IN :set_QueriedPayrollAudits
			]) {
				String strKey = objQuarterlyFile.Company_ID__c + ';' + objQuarterlyFile.State__c + ';' + objQuarterlyFile.Quarter_Name__c;
				map_QueriedQuarterlyFileRecords.put(strKey, objQuarterlyFile);
			}
		}
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Inserting Payroll_Audit__c and/or Quarterly_File__c records based off CSV
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	public void insertPayrollAudit(Map<String, Payroll_Audit__c> map_PayrollAuditsToInsert) {
		if (map_SimilarZPPayrollAudits?.keySet().size() > 0) {
			for (String strKey : map_SimilarZPPayrollAudits.keySet()) {
				if (!map_QueriedPayrollAuditRecords.containsKey(strKey)) {
					Payroll_Audit__c objPayrollAudit = new Payroll_Audit__c();
					String strCompanyID = map_SimilarZPPayrollAudits.get(strKey).Company_ID__c;
					String strZPUserID = map_SimilarZPPayrollAudits.get(strKey).Admin_User_ID__c;
					ID IdRecordTypeId = map_ZPPayrollAuditTypes.get(map_SimilarZPPayrollAudits.get(strKey).Type__c);
					String strType = map_PayrollAuditTypes.get(map_SimilarZPPayrollAudits.get(strKey).Type__c);

					// Get Account from ZP Company ID
					objPayrollAudit.Account__c = map_QueriedAccounts?.containsKey(strCompanyID) ? map_QueriedAccounts?.get(strCompanyID).Id : null;

					// Get Contact from Admin User ID
					objPayrollAudit.Contact__c = map_QueriedContacts?.containsKey(strZPUserID) ? map_QueriedContacts?.get(strZPUserID).Id : null;

					// Assign recordtype id based on ZP Payroll Audit's Type
					objPayrollAudit.RecordTypeId = IdRecordTypeId;

					// Assign type based on ZP Payroll Audit's Type and mapping defined above
					objPayrollAudit.Type__c = strType;

					for (Schema.sObjectField objField : set_PayrollAuditFields) {
						String strFieldName = objField.getDescribe().getName();
						if (strFieldName.equalsIgnoreCase(PAYROLL_AUDIT_JOINED_AT_FIELD) || strFieldName.equalsIgnoreCase(PAYROLL_AUDIT_STATE_ADDED_AT_FIELD)) {
							Date dtFieldValue = (Date) map_SimilarZPPayrollAudits.get(strKey).get(objField);
							objPayrollAudit.put(strFieldName, dtFieldValue);
						} else if (
							strFieldName.equalsIgnoreCase(PAYROLL_AUDIT_HAS_HISTORICAL_FIELD) ||
							strFieldName.equalsIgnoreCase(PAYROLL_AUDIT_DELINQUENT_FIELD) ||
							strFieldName.equalsIgnoreCase(PAYROLL_AUDIT_EXEMPT_FIELD) ||
							strFieldName.equalsIgnoreCase(PAYROLL_AUDIT_ACTIVE_SOFT_SUSPEND_FIELD) ||
							strFieldName.equalsIgnoreCase(PAYROLL_AUDIT_HAS_EXTERNAL_FIELD)
						) {
							Boolean blnFieldValue = (Boolean) map_SimilarZPPayrollAudits.get(strKey).get(objField);
							objPayrollAudit.put(strFieldName, blnFieldValue);
						} else if (strFieldName.equalsIgnoreCase(PAYROLL_AUDIT_SUI_RATE_FIELD) || strFieldName.equalsIgnoreCase(PAYROLL_AUDIT_SUI_SC_RATE_FIELD)) {
							Decimal decFieldValue = (Decimal) map_SimilarZPPayrollAudits.get(strKey).get(objField);
							if (decFieldValue != null) {
								objPayrollAudit.put(strFieldName, decFieldValue);
							} else {
								continue;
							}
						} else {
							String strFieldValue = (String) map_SimilarZPPayrollAudits.get(strKey).get(objField);
							objPayrollAudit.put(strFieldName, strFieldValue);
						}
					}
					map_PayrollAuditsToInsert.put(strKey, objPayrollAudit);
				}
			}
		}

		if (map_PayrollAuditsToInsert?.size() > 0) {
			List<Database.SaveResult> list_SaveResult = Database.insert(map_PayrollAuditsToInsert.values(), false);
			map_DMLInsertErrors = Utils.processSaveResult(list_SaveResult, map_PayrollAuditsToInsert.values(), 'Event_Id__c', true, 'ZPPayrollAuditTriggerHelper-insertPayrollAudit');
		}
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Inserting Quarterly_File__c records based off CSV
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	public void insertQuartelyFiles(Map<String, Payroll_Audit__c> map_PayrollAuditsToInsert) {
		List<Quarterly_File__c> list_QuarterlyFilesToInsert = new List<Quarterly_File__c>();
		Boolean blnSkipQFCreation = false;

		if (map_QuarterlyFilesToCreate?.keySet().size() > 0) {
			for (String strQFKey : map_QuarterlyFilesToCreate.keySet()) {
				Quarterly_File__c objQuarterlyFile = new Quarterly_File__c();
				blnSkipQFCreation = false;
				for (Schema.sObjectField objField : set_QuarterlyFileFields) {
					String strQFFieldName = objField.getDescribe().getName();
					if (strQFFieldName.equalsIgnoreCase(QUARTERLY_FILE_QUARTER_NAME_FIELD)) {
						String strQFFieldValue = (String) map_QuarterlyFilesToCreate.get(strQFKey).get(objField);
						if (map_QueriedQuarterlyFileRecords.containsKey(strQFKey + ';' + strQFFieldValue)) {
							blnSkipQFCreation = true;
							break;
						} else {
							objQuarterlyFile.put(strQFFieldName, strQFFieldValue);
						}
					} else if (strQFFieldName.equalsIgnoreCase(QUARTERLY_FILE_PAYROLL_AUDIT_FIELD)) {
						objQuarterlyFile.Payroll_Audit__c = map_QueriedPayrollAuditRecords?.containsKey(strQFKey)
							? map_QueriedPayrollAuditRecords.get(strQFKey).Id
							: map_PayrollAuditsToInsert?.get(strQFKey).Id;
					} else if (
						strQFFieldName.equalsIgnoreCase(QUARTERLY_FILE_QUARTERLY_GROSS_WAGES_FIELD) ||
						strQFFieldName.equalsIgnoreCase(QUARTERLY_FILE_QUARTERLY_SUBJECT_WAGES_FIELD) ||
						strQFFieldName.equalsIgnoreCase(QUARTERLY_FILE_QUARTERLY_TAXES_FIELD) ||
						strQFFieldName.equalsIgnoreCase(QUARTERLY_FILE_UPDATED_GROSS_WAGES_FIELD) ||
						strQFFieldName.equalsIgnoreCase(QUARTERLY_FILE_UPDATED_QUARTERLY_TAXES_FIELD) ||
						strQFFieldName.equalsIgnoreCase(QUARTERLY_FILE_UPDATED_SUBJECT_WAGES_FIELD)
					) {
						Decimal decFieldValue = (Decimal) map_QuarterlyFilesToCreate.get(strQFKey).get(objField);
						if (decFieldValue != null) {
							objQuarterlyFile.put(strQFFieldName, decFieldValue);
						} else {
							continue;
						}
					} else {
						String strQFFieldValue = (String) map_QuarterlyFilesToCreate.get(strQFKey).get(objField);
						objQuarterlyFile.put(strQFFieldName, strQFFieldValue);
					}
				}

				// Insertion
				if (objQuarterlyFile?.Payroll_Audit__c != null && !blnSkipQFCreation) {
					list_QuarterlyFilesToInsert.add(objQuarterlyFile);
				}
			}
		}

		if (list_QuarterlyFilesToInsert?.size() > 0) {
			List<Database.SaveResult> list_SaveResult = Database.insert(list_QuarterlyFilesToInsert, false);
			map_DMLInsertErrors = Utils.processSaveResult(list_SaveResult, list_QuarterlyFilesToInsert, 'Event_Id__c', true, 'ZPPayrollAuditTriggerHelper-insertQuartelyFiles');
		}
	}

	public static ZP_Payroll_Audit__c setProcessingState(String strProcessingState, String strMessage, ZP_Payroll_Audit__c objZPPayrollAudit) {
		objZPPayrollAudit.Processing_State__c = strProcessingState;
		objZPPayrollAudit.Message__c = strMessage;
		objZPPayrollAudit.Processed_At__c = System.now();
		return objZPPayrollAudit;
	}
}