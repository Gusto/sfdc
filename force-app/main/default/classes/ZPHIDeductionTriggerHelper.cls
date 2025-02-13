/***************************************************
Test Classes : ZPHIDeductionTriggerHelperTest  
****************************************************/

public class ZPHIDeductionTriggerHelper extends TriggerHandler {
	public static Boolean skipTrigger = false;
	public static final String STR_STATUS_ACTIVE = 'Active';
	public static final String STR_STATUS_INACTIVE = 'Inactive';
	public static final String PROCESSING_STATE_ERROR = 'Error';
	public static final String PROCESSING_STATE_PROCESSED = 'Processed';
	public static final String COMPANY_DOES_NOT_EXIST = 'Company does not exist.';
	public static final String BYB = 'BYB';
	public static final String BOR = 'BoR';
	public static final String BOR_PARTIAL = 'BoR Partial';
	public static final Set<String> set_InactiveStatus = new Set<String>{ IntegrationUtils.ERROR_STATE, IntegrationUtils.DEAD_STATE, IntegrationUtils.BACKLOG };
	public static final List<String> set_AllowChangeFields = 'processing_state__c'.split(',');

	public static final Set<String> set_HIOpptyStates = new Set<String>();

	public ZPHIDeductionTriggerHelper() {
		super('ZPHIDeductionTriggerHelper');

		for (HI_Oppty_Router_State__mdt objRouterState : HI_Oppty_Router_State__mdt.getAll().values()) {
			set_HIOpptyStates.add(objRouterState.Label);
		}
	}

	public override void beforeInsert() {
		for (ZP_HI_Deduction__c objDeduction : (List<ZP_HI_Deduction__c>) Trigger.new) {
			objDeduction.Processing_State__c = IntegrationUtils.QUEUED_STATE;
		}
	}

	public override void beforeUpdate() {
		List<ZP_HI_Deduction__c> list_DeductionsToProcess = returnRecordsToProcess((List<ZP_HI_Deduction__c>) Trigger.new, (Map<Id, ZP_HI_Deduction__c>) Trigger.oldMap);

		for (ZP_HI_Deduction__c objDeduction : list_DeductionsToProcess) {
			objDeduction.Processing_State__c = IntegrationUtils.QUEUED_STATE;
		}
	}

	public override void beforeDelete() {
		processInformation((List<ZP_HI_Deduction__c>) Trigger.old, null);
	}

	public void processInformation(List<ZP_HI_Deduction__c> list_Deductions, Map<Id, ZP_HI_Deduction__c> map_oldDeductionsMap) {
		List<Account> list_AccountToReset = new List<Account>();
		Map<String, Account> map_ToUpdateAccounts = new Map<String, Account>();
		Map<String, Account> map_ZPCompanyIdAccount = getExistingAccountsForDeductions(list_Deductions);

		for (ZP_HI_Deduction__c objDeduction : list_Deductions) {
			ZP_HI_Deduction__c objZPHIDeductionRec = null;
			if (map_oldDeductionsMap != null && map_oldDeductionsMap.containsKey(objDeduction.id)) {
				objZPHIDeductionRec = map_oldDeductionsMap.get(objDeduction.id);
			}

			// set default state as Queued
			objDeduction.Processing_State__c = IntegrationUtils.QUEUED_STATE;

			if (!map_ZPCompanyIdAccount.containsKey(objDeduction.Company_ID__c)) {
				objDeduction.Processing_State__c = PROCESSING_STATE_ERROR;
				objDeduction.Message__c = COMPANY_DOES_NOT_EXIST;
				continue;
			} else {
				objDeduction.Account__c = map_ZPCompanyIdAccount.get(objDeduction.Company_ID__c)?.Id;
			}

			if (
				map_ZPCompanyIdAccount.containsKey(objDeduction.Company_ID__c) &&
				(objZPHIDeductionRec == null || (objZPHIDeductionRec != null && objDeduction.Company_ID__c == objZPHIDeductionRec.Company_ID__c))
			) {
				Account objAccount = map_ZPCompanyIdAccount.get(objDeduction.Company_ID__c);
				if (objDeduction.Status__c == STR_STATUS_INACTIVE) {
					list_AccountToReset.add(objAccount);
				} else {
					setAccountValues(objAccount, objDeduction);
				}
				map_ToUpdateAccounts.put(objDeduction.Company_ID__c, objAccount);
			}

			if (objZPHIDeductionRec != null) {
				if (objDeduction.Company_ID__c != objZPHIDeductionRec.Company_ID__c) {
					if (map_ZPCompanyIdAccount.containsKey(objZPHIDeductionRec.Company_ID__c)) {
						list_AccountToReset.add(map_ZPCompanyIdAccount.get(objZPHIDeductionRec.Company_ID__c));
					}
				}
			}
		}

		if (!list_AccountToReset.isEmpty()) {
			for (Account objAccount : list_AccountToReset) {
				setAccountValues(objAccount, null);
				map_ToUpdateAccounts.put(objAccount.ZP_Company_ID__c, objAccount);
			}
		}

		if (map_ToUpdateAccounts != null && map_ToUpdateAccounts.size() > 0) {
			List<Account> accountList = map_ToUpdateAccounts.values();

			Map<String, String> dmlSaveErrorsMap = new Map<String, String>();
			List<Database.SaveResult> saveResult = database.update(accountList, false);
			dmlSaveErrorsMap = Utils.processSaveResult(saveResult, accountList, 'ZP_Company_ID__c', true, 'ZPHIDeductionTriggerHelper-processInformation');
			for (ZP_HI_Deduction__c objDeduction : list_Deductions) {
				if (dmlSaveErrorsMap.containsKey(objDeduction.Company_ID__c)) {
					objDeduction.Processing_State__c = PROCESSING_STATE_ERROR;
					objDeduction.Message__c = dmlSaveErrorsMap.get(objDeduction.Company_ID__c);
				} else if (objDeduction.Processing_State__c != PROCESSING_STATE_ERROR) {
					objDeduction.Processing_State__c = PROCESSING_STATE_PROCESSED;
					objDeduction.Message__c = '';
				}
			}
		}
	}

	/**
	 * @description  Sets or resets Account record based on Deduction
	 * @param        Account Object
	 *               ZP HI Deduction object or NULL
	 **/
	public void setAccountValues(Account objAccount, ZP_HI_Deduction__c objDeduction) {
		String strCarriers = null;
		List<String> list_trimCarriers = new List<String>();
		if (objDeduction != null && String.isNotBlank(objDeduction.Carriers__c)) {
			for (String strCarrier : objDeduction.Carriers__c.split(',')) {
				list_trimCarriers.add(strCarrier.trim());
			}
		}
		strCarriers = String.join(list_trimCarriers, '; ');

		String strCategory = null;
		Boolean blnHasSupportedCarriers = (objDeduction != null) && objDeduction.Medical_Carriers_Supported__c;
		Boolean blnValidFilingState = (set_HIOpptyStates != null) && String.isNotBlank(objAccount.BillingStateCode) && set_HIOpptyStates.contains(objAccount.BillingStateCode);
		String strTrimedCarriers = strCarriers?.replaceAll('Other', '').replaceAll(',', '').trim();
		Boolean blnHasNonOtherCarriers = String.isNotBlank(strTrimedCarriers);

		if (blnHasSupportedCarriers && !strCarriers.Contains('Other') && blnValidFilingState) {
			strCategory = BOR;
		} else if (blnHasSupportedCarriers && blnHasNonOtherCarriers && blnValidFilingState) {
			strCategory = BOR_PARTIAL;
		} else {
			strCategory = BYB;
		}

		objAccount.Medical_Deductions__c = (objDeduction != null) ? true : false;
		objAccount.No_of_EE_with_Active_Benefits__c = (objDeduction != null) ? objDeduction.active_employee_count__c : null;
		objAccount.Medical_Deduction_Descriptions__c = (objDeduction != null) ? objDeduction.descriptions__c : null;
		objAccount.Medical_Deduction_Types__c = (objDeduction != null) ? objDeduction.types__c : null;
		objAccount.Has_Medical_Deductions_Timestamp__c = (objDeduction != null) ? System.now() : null;
		objAccount.Carriers_Other__c = (objDeduction != null) ? objDeduction.Carriers_Other__c : null;
		objAccount.Carriers__c = (objDeduction != null) ? strCarriers : null;
		objAccount.Benefit_Deduction_Category__c = (objDeduction != null) ? strCategory : null;
	}

	/**
	 * @description  Returns existing Account for the ZP Company
	 * @param        List of ZP_HI_Deduction__c
	 * @return       Map ZP Company Id and Account
	 **/
	private static Map<String, Account> getExistingAccountsForDeductions(List<ZP_HI_Deduction__c> list_Deductions) {
		Set<String> set_companyIds = new Set<String>();
		Map<String, Account> map_zpCompanyIdAccount = new Map<string, Account>();
		for (ZP_HI_Deduction__c objDeduction : list_Deductions) {
			if (String.isNotBlank(objDeduction.Company_ID__c)) {
				set_companyIds.add(objDeduction.Company_ID__c);
			}
		}

		if (!set_companyIds.isEmpty()) {
			for (Account objAcc : [
				SELECT
					Id,
					ZP_Company_ID__c,
					No_of_EE_with_Active_Benefits__c,
					Medical_Deductions__c,
					Medical_Deduction_Descriptions__c,
					Medical_Deduction_Types__c,
					Benefit_Deduction_Category__c,
					BillingState,
					BillingStateCode
				FROM Account
				WHERE
					ZP_Company_ID__c != NULL
					AND ZP_Company_ID__c IN :set_companyIds
					AND (RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID
					OR RecordTypeId = :AccountUtil.EMBEDDED_COMPANY_ACCOUNT_RT_ID)
			]) {
				map_zpCompanyIdAccount.put(objAcc.ZP_Company_ID__c, objAcc);
			}
		}

		return map_zpCompanyIdAccount;
	}

	/**
	 * @author      : Praveen Sethu
	 * @description : Filters list of zp hi deduction records for which field values changed. If no fields changed, then mark the record as processed
	 * @param        : List<ZP_HI_Deduction__c> - Unfiltered List
	 * @return      : List<ZP_HI_Deduction__c> - Filtered List
	 **/
	public List<ZP_HI_Deduction__c> returnRecordsToProcess(List<ZP_HI_Deduction__c> list_Deductions, Map<ID, ZP_HI_Deduction__c> map_OldDeductions) {
		// List to contain filtered list of ZP HI deduction records to process
		List<ZP_HI_Deduction__c> list_DeductionsToProcess = new List<ZP_HI_Deduction__c>();

		List<String> list_DeductionFields = new List<String>(ZP_HI_Deduction__c.SObjectType.getDescribe().fields.getMap().keySet());

		for (ZP_HI_Deduction__c objDeduction : list_Deductions) {
			Boolean blnChanged = false;

			// if processing state is already Queued, then skip the record
			if (objDeduction.Processing_State__c == IntegrationUtils.QUEUED_STATE) {
				continue;
			}
			if (!set_InactiveStatus.contains(objDeduction.Processing_State__c)) {
				objDeduction.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}

			// Take all fields and compare old/new values and set boolean flag to true only if at aleast one field has changed
			if (map_OldDeductions != null) {
				ZP_HI_Deduction__c objOldDeduction = map_OldDeductions.containsKey(objDeduction.Id) ? map_OldDeductions.get(objDeduction.Id) : null;
				if (!blnChanged && objOldDeduction != null) {
					for (String strField : list_DeductionFields) {
						if (objDeduction.get(strField) != objOldDeduction.get(strField) && !set_AllowChangeFields.contains(strField.toLowerCase())) {
							blnChanged = true;
						}
					}
				}

				if (!blnChanged && !set_InactiveStatus.contains(objDeduction.Processing_State__c)) {
					objDeduction.Processing_State__c = IntegrationUtils.PROCESSED_STATE;
					objDeduction.Message__c = IntegrationUtils.PROCESSED_STATE;
				}
			}
		}

		// Add anything record whose processing state is not Dead to list of ZP HI Deduction to Process
		for (ZP_HI_Deduction__c objDeduction : list_Deductions) {
			if (objDeduction.Processing_State__c != IntegrationUtils.DEAD_STATE && objDeduction.Processing_State__c != IntegrationUtils.PROCESSED_STATE) {
				list_DeductionsToProcess.add(objDeduction);
			}
		}

		// Return filtered list of records to process
		return list_DeductionsToProcess;
	}
}