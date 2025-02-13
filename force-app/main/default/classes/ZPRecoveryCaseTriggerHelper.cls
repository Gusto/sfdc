public class ZPRecoveryCaseTriggerHelper {
	public static Boolean skipTrigger = false;
	private static Integer counter = 0;
	public static Boolean queue = false;
	public Id caseTeamRoleId;
	public Map<String, List<Zp_User_Role__c>> accountIdZpUserRoleMap;
	public static final String PAYROLL_PREFIX = 'zenpayroll-payroll-';
	public static final String CONTRACTOR_PAYMENT_PREFIX = 'zenpayroll-contractor-payment-';
	public static final String INT_CONTRACTOR_PAYMENT_PREFIX = 'zenpayroll-international-contractor-payment-';
	public static final String INT_EMPLOYEE_PAYMENT_PREFIX = 'zenpayroll-international-employee-payment-';
	public static final String PAYROLL = 'Payroll';
	public static final String CONTRACTOR_PAYMENT = 'ContractorPayment';
	public static final String INT_CONTRACTOR_PAYMENT = 'InternationalContractorPayment';
	public static final String INT_EMPLOYEE_PAYMENT = 'InternationalEmployeePayroll';

	public ZPRecoveryCaseTriggerHelper() {
	}

	public void OnBeforeInsert(List<ZP_Recovery_Case__c> ZPRecoveryCases) {
		counter++;
		if (queue == true) {
			processInformation(ZPRecoveryCases);
		} else {
			for (ZP_Recovery_Case__c ZPobjrecoveryCase : ZPRecoveryCases) {
				ZPobjrecoveryCase.Processing_State__c = IntegrationUtils.QUEUED_STATE;
				ZPobjrecoveryCase.Message__c = '';
			}
		}
	}

	public void OnAfterInsert(Map<ID, ZP_Recovery_Case__c> newZPRecoveryCases) {
		if (queue == false) {
			ZPRecoveryCaseQueue updateJob = new ZPRecoveryCaseQueue(newZPRecoveryCases.values());
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	public void OnBeforeUpdate(Map<ID, ZP_Recovery_Case__c> oldZPRecoveryMap, Map<ID, ZP_Recovery_Case__c> newZPRecoveryMap) {
		counter++;

		if (queue == true) {
			processInformation(newZPRecoveryMap.values());
		} else {
			for (ZP_Recovery_Case__c objZPRecovery : newZPRecoveryMap.values()) {
				objZPRecovery.Processing_State__c = IntegrationUtils.QUEUED_STATE;
				objZPRecovery.Message__c = '';
			}
		}
	}

	public void OnAfterUpdate(Map<ID, ZP_Recovery_Case__c> oldZPRecoveryMap, Map<ID, ZP_Recovery_Case__c> newZPRecoveryMap) {
		if (queue == false) {
			ZPRecoveryCaseQueue updateJob = new ZPRecoveryCaseQueue(newZPRecoveryMap.values());
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	private void processInformation(List<ZP_Recovery_Case__c> ZPRecoveryCaseEntries) {
		Set<String> zPcompanyIDSet = new Set<String>();
		Set<String> recoveryInvestigationIdSet = new Set<String>();
		caseTeamRoleId = [SELECT Id, Name FROM CaseTeamRole WHERE Name = 'Customer Contact'].Id;
		set<string> set_R01EventIds = new Set<string>();

		//Get ZPCompanyIds. Throw error if this field not present.
		for (ZP_Recovery_Case__c zPRecoveryEntry : ZPRecoveryCaseEntries) {
			if (zPRecoveryEntry.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			if (zPRecoveryEntry.Company_Id__c == null || zPRecoveryEntry.Company_Id__c == '') {
				setProcessingZPRecoveryCase(IntegrationUtils.ERROR_STATE, 'Company record does not exit.', zPRecoveryEntry);
				continue;
			}

			zPcompanyIDSet.add(zPRecoveryEntry.Company_Id__c);
			if (String.isNotBlank(zPRecoveryEntry.External_Key__c)) {
				recoveryInvestigationIdSet.add(zPRecoveryEntry.External_Key__c);
			}

			if (String.isNotBlank(zPRecoveryEntry.Event_Id__c)) {
				set_R01EventIds.add(zPRecoveryEntry.Event_Id__c);
			}
		}
		Map<String, Account> mapZPCompanyIdToAccount = getCompanyData(zPcompanyIDSet); //Get Account for ZPCompanyIds

		Set<Id> setAccIds = new Set<Id>();
		for (Account objAcc : mapZPCompanyIdToAccount.values()) {
			setAccIds.add(objAcc.Id);
		}

		accountIdZpUserRoleMap = getAccountZpUserRoleMap(setAccIds);

		Map<String, Case> mapRecoveryIdToCaseRecord = getCaseRecord(recoveryInvestigationIdSet);

		//Create new Case and nacha entries request
		List<Case> listUpsertCase = new List<Case>();
		Set<String> newCaseRecoveryIDSet = new Set<String>();

		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;

		set<string> set_firstTimeR01EventIds = new Set<string>();
		if (set_R01EventIds.size() > 0) {
			set_firstTimeR01EventIds = getFirstTimeDebitFailureNachaIds(set_R01EventIds);
		}

		for (ZP_Recovery_Case__c zPRecoveryEntry : ZPRecoveryCaseEntries) {
			if (zPRecoveryEntry.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}

			//By: PR, Date: 9/16/19, Desc: Asked by @Brandon, introduced "recovery status" filter for 'awaiting_tax_recovery'
			if (
				(string.isBlank(zPRecoveryEntry.Recovery_Status__c) ||
				(zPRecoveryEntry.Recovery_Status__c != 'awaiting_tax_recovery' &&
				zPRecoveryEntry.Recovery_Status__c != 'awaiting_manual_recovery')) &&
				string.isNotBlank(zPRecoveryEntry.Event_Id__c) &&
				set_firstTimeR01EventIds.contains(zPRecoveryEntry.Event_Id__c)
			) {
				setProcessingZPRecoveryCase(IntegrationUtils.PROCESSED_STATE, 'Only first time nacha is present.', zPRecoveryEntry);
				continue;
			}

			//No account found for given zpCompanyId
			if (!mapZPCompanyIdToAccount.containsKey(zPRecoveryEntry.Company_Id__c) || mapZPCompanyIdToAccount.get(zPRecoveryEntry.Company_Id__c) == null) {
				setProcessingZPRecoveryCase(IntegrationUtils.ERROR_STATE, 'Company record does not exit.', zPRecoveryEntry);
				continue;
			}

			//Upsert Case entries
			if (!mapZPCompanyIdToAccount.isEmpty() && mapZPCompanyIdToAccount.containsKey(zPRecoveryEntry.Company_Id__c)) {
				Account objAccount = mapZPCompanyIdToAccount.get(zPRecoveryEntry.Company_Id__c);
				Case objCase;
				if (
					zPRecoveryEntry.External_Key__c != null &&
					!mapRecoveryIdToCaseRecord.isEmpty() &&
					mapRecoveryIdToCaseRecord.containsKey(zPRecoveryEntry.External_Key__c) &&
					mapRecoveryIdToCaseRecord.get(zPRecoveryEntry.External_Key__c) != null
				) {
					objCase = mapRecoveryIdToCaseRecord.get(zPRecoveryEntry.External_Key__c);
				} else {
					objCase = new Case();
					objCase.setOptions(dmo);
					objCase.Company_Id__c = zPRecoveryEntry.Company_Id__c;
					objCase.Recovery_Case_Id__c = zPRecoveryEntry.Recovery_Case_Id__c;
					objCase.Subject = 'Recovery Case Created for ' + objAccount.Name;
					objCase.AccountId = objAccount.Id;
					objCase.Integration_Id__c = zPRecoveryEntry.Payment_Investigation_ID__c;

					String strPrefix = '';
					if (zPRecoveryEntry.Event_Type__c == PAYROLL) {
						strPrefix = PAYROLL_PREFIX;
					} else if (zPRecoveryEntry.Event_Type__c == CONTRACTOR_PAYMENT) {
						strPrefix = CONTRACTOR_PAYMENT_PREFIX;
					} else if (zPRecoveryEntry.Event_Type__c.contains(INT_CONTRACTOR_PAYMENT)) {
						strPrefix = INT_CONTRACTOR_PAYMENT_PREFIX;
					} else if (zPRecoveryEntry.Event_Type__c == INT_EMPLOYEE_PAYMENT) {
						strPrefix = INT_EMPLOYEE_PAYMENT_PREFIX;
					}
					objCase.Integration_Key__c = strPrefix + zPRecoveryEntry.Event_Id__c;

					if (accountIdZpUserRoleMap.containsKey(objAccount.Id) && objCase?.ContactId == null) {
						objCase.ContactId = accountIdZpUserRoleMap.get(objAccount.Id)[0].Contact__c;
					}

					objCase.Origin = 'Panda';
					objCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Recovery Cases').getRecordTypeId();

					newCaseRecoveryIDSet.add(zPRecoveryEntry.External_Key__c);
				}

				objCase.Payment_Investigation_ID__c = zPRecoveryEntry.Payment_Investigation_ID__c;
				objCase.Company_Name__c = zPRecoveryEntry.Company_Name__c;
				objCase.Event_ID__c = zPRecoveryEntry.Event_ID__c;
				objCase.Event_Check_Date__c = zPRecoveryEntry.Event_Check_Date__c;
				objCase.Event_Type__c = zPRecoveryEntry.Event_Type__c;
				objCase.Recovery_Status__c = zPRecoveryEntry.Recovery_Status__c;
				objCase.Initial_Recovery_Amount__c = zPRecoveryEntry.Initial_Recovery_Amount__c;
				objCase.Outstanding_Balance__c = zPRecoveryEntry.Outstanding_Balance__c;
				objCase.Created_At_Date__c = zPRecoveryEntry.Created_At_Date__c;
				listUpsertCase.add(objCase);
			}
		}

		Map<String, String> dmlUpsertErrorsMap = new Map<String, String>();
		if (listUpsertCase.size() > 0) {
			List<Database.UpsertResult> saveResult = database.upsert(listUpsertCase, Case.Fields.Integration_Key__c, false);
			dmlUpsertErrorsMap = Utils.processUpsertResult(saveResult, listUpsertCase, 'Integration_Key__c', true, 'ZPRecoveryCaseTriggerHelper-processInformation');

			for (ZP_Recovery_Case__c recoveryCase : ZPRecoveryCaseEntries) {
				String externalKey = 'zenpayroll-' + recoveryCase.Event_Type__c.tolowercase() + '-' + recoveryCase.Event_Id__c;
				if (dmlUpsertErrorsMap.containsKey(externalKey)) {
					setProcessingZPRecoveryCase(IntegrationUtils.ERROR_STATE, dmlUpsertErrorsMap.get(externalKey), recoveryCase);
				} else {
					setProcessingZPRecoveryCase(IntegrationUtils.PROCESSED_STATE, 'Information is successfully processed', recoveryCase);
				}
			}
		}

		mapRecoveryIdToCaseRecord = getCaseRecord(recoveryInvestigationIdSet);

		List<CaseTeamMember> listNewCaseTeam = new List<CaseTeamMember>();

		Map<Id, Set<Id>> map_AccountIdsByCaseId = new Map<Id, Set<Id>>();
		Map<Id, Account> map_AccountById = new Map<Id, Account>();
		for (ZP_Recovery_Case__c objZPRecoveryEntry : ZPRecoveryCaseEntries) {
			if (
				newCaseRecoveryIDSet.contains(objZPRecoveryEntry.External_Key__c) &&
				!mapZPCompanyIdToAccount.isEmpty() &&
				!mapRecoveryIdToCaseRecord.isEmpty() &&
				mapZPCompanyIdToAccount.containsKey(objZPRecoveryEntry.Company_Id__c) &&
				mapRecoveryIdToCaseRecord.containsKey(objZPRecoveryEntry.External_Key__c)
			) {
				Id idCaseId = mapRecoveryIdToCaseRecord.get(objZPRecoveryEntry.External_Key__c).Id;
				Set<Id> set_AccountIds = new Set<Id>();

				if (map_AccountIdsByCaseId.containsKey(idCaseId)) {
					set_AccountIds = map_AccountIdsByCaseId.get(idCaseId);
				}

				Account objAccount = mapZPCompanyIdToAccount.get(objZPRecoveryEntry.Company_Id__c);
				set_AccountIds.add(objAccount.Id);
				map_AccountIdsByCaseId.put(idCaseId, set_AccountIds);

				map_AccountById.put(objAccount.Id, objAccount);
			}
		}

		for (Id idCaseId : map_AccountIdsByCaseId.keySet()) {
			List<Id> list_AccountIds = new List<Id>();
			list_AccountIds.addAll(map_AccountIdsByCaseId.get(idCaseId));
			for (Id idAccountId : list_AccountIds) {
				List<CaseTeamMember> list_CaseTeamMembers = createCaseTeam(idCaseId, map_AccountById.get(idAccountId));
				listNewCaseTeam.addAll(list_CaseTeamMembers);
			}
		}

		if (!listNewCaseTeam.isEmpty()) {
			insert listNewCaseTeam;
		}
	}
	// By: Gaurav : 31-Oct-2019 : Zp User Redesign : AccontContactRelationShip is now Obslete so using Zp_User_Role
	private Map<String, List<ZP_User_Role__c>> getAccountZpUserRoleMap(Set<Id> set_AccountIds) {
		Set<String> set_AllowedRoles = Utils.getRolesSet('Company', 'ZPRecoveryCaseTriggerHelper');
		Map<String, List<ZP_User_Role__c>> map_ZPUserRoles = new Map<String, List<ZP_User_Role__c>>();

		for (ZP_User_Role__c objZPUserRole : [
			SELECT Company_Account__c, Accounting_Firm_Account__c, Contact__c, Type__c, Deleted_At__c, Is_Primary__c, Role_Name__c
			FROM ZP_User_Role__c
			WHERE (Company_Account__c IN :set_AccountIds OR Accounting_Firm_Account__c IN :set_AccountIds) AND Role_Name__c IN :set_AllowedRoles AND Contact__c != NULL AND Deleted_At__c = NULL
		]) {
			if (objZPUserRole.Company_Account__c != null) {
				if (!map_ZPUserRoles.containsKey(objZPUserRole.Company_Account__c)) {
					map_ZPUserRoles.put(objZPUserRole.Company_Account__c, new List<ZP_User_Role__c>());
				}

				map_ZPUserRoles.get(objZPUserRole.Company_Account__c).add(objZPUserRole);
			} else if (objZPUserRole.Accounting_Firm_Account__c != null) {
				if (!map_ZPUserRoles.containsKey(objZPUserRole.Accounting_Firm_Account__c)) {
					map_ZPUserRoles.put(objZPUserRole.Accounting_Firm_Account__c, new List<ZP_User_Role__c>());
				}

				map_ZPUserRoles.get(objZPUserRole.Accounting_Firm_Account__c).add(objZPUserRole);
			}
		}

		return map_ZPUserRoles;
	}
	//Create Case Team members
	private List<CaseTeamMember> createCaseTeam(Id caseId, Account objAcc) {
		List<CaseTeamMember> listCaseTeam = new List<CaseTeamMember>();
		if (accountIdZpUserRoleMap.containsKey(objAcc.Id) && accountIdZpUserRoleMap.get(objAcc.Id).size() > 0) {
			Set<Id> contactIdSet = new Set<Id>();
			for (Zp_User_Role__c objzpUserRole : accountIdZpUserRoleMap.get(objAcc.Id)) {
				if (!contactIdSet.contains(objzpUserRole.Contact__c)) {
					// to avoid any duplicates
					CaseTeamMember objCaseTeam = new CaseTeamMember(MemberId = objzpUserRole.Contact__c, ParentId = caseId, TeamRoleId = caseTeamRoleId);
					listCaseTeam.add(objCaseTeam);
					contactIdSet.add(objzpUserRole.Contact__c);
				}
			}
		}
		return listCaseTeam;
	}

	//querying Case object
	private Map<String, Case> getCaseRecord(Set<String> set_RecoveryIds) {
		Map<String, Case> map_RecoveryIdToCase = new Map<String, Case>();

		if (set_RecoveryIds != null && !set_RecoveryIds.isEmpty()) {
			for (Case objCase : [SELECT Id, ContactId, Recovery_Case_Id__c, Integration_Key__c FROM Case WHERE Integration_Key__c IN :set_RecoveryIds]) {
				map_RecoveryIdToCase.put(objCase.Integration_Key__c, objCase);
			}
		}

		return map_RecoveryIdToCase;
	}

	//querying Account object
	private Map<string, Account> getCompanyData(Set<String> accountIdSet) {
		Map<String, Account> toReturnIdAccountRecMap = new Map<String, Account>();
		if (accountIdSet != null && accountIdSet.size() > 0) {
			for (Account accRec : [SELECT id, Name, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c IN :accountIdSet AND ZP_Company_ID__c != NULL]) {
				toReturnIdAccountRecMap.put(accRec.ZP_Company_ID__c, accRec);
			}
		}
		return toReturnIdAccountRecMap;
	}

	//populating  ZP_Recovery_Case__c  object fields
	private ZP_Recovery_Case__c setProcessingZPRecoveryCase(String ProcessingState, String message, ZP_Recovery_Case__c ZPRecoveryCase) {
		ZPRecoveryCase.Processing_State__c = ProcessingState;
		ZPRecoveryCase.Message__c = message;
		ZPRecoveryCase.Last_Processed__c = System.now();
		return ZPRecoveryCase;
	}

	//By: PR, Date:7/9/19, Desc: This method Returns set of eventIds for which only have first Nacha
	public set<string> getFirstTimeDebitFailureNachaIds(set<string> set_eventIds) {
		set<string> secondTimeDebitFailureNachaIdSet = new Set<string>();

		if (set_eventIds != null && set_eventIds.size() > 0) {
			for (AggregateResult aggresult : [
				SELECT Event_ID__c, count(Id) tcount
				FROM Nacha_Entry_Return__c
				WHERE Event_ID__c IN :set_eventIds AND Error_Code__c LIKE '%R01%' AND First_Debit_Failure_Nacha__c = FALSE
				GROUP BY Event_ID__c
			]) {
				integer numberOfNachasAlreadyInOrg = integer.valueof(aggresult.get('tcount'));
				if (numberOfNachasAlreadyInOrg > 0) {
					secondTimeDebitFailureNachaIdSet.add(string.valueOf(aggresult.get('Event_ID__c')));
				}
			}
		}

		set<string> nonEligibleNachaSet = set_eventIds;
		nonEligibleNachaSet.removeAll(secondTimeDebitFailureNachaIdSet);

		return nonEligibleNachaSet;
	}
}