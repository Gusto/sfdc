/**
Created by : Aurobind Ravichandran
Created Date : 3/27/2017
**/

public class ZPAccountingFirmTriggerHelper {
	public static boolean skipTrigger = false;
	public static boolean queue = false;
	public static Map<String, Account> map_CompanyIdToAcc = new Map<String, Account>();
	public static Map<String, ZP_Company__c> map_matchingCompaniesByEmail = new Map<String, ZP_Company__c>();
	public static Map<String, Lead> map_AllResellerLeads = new Map<String, Lead>();

	public void OnBeforeInsert(List<ZP_Accounting_Firm__c> firms) {
		try {
			if (queue == true) {
				processInformation(firms);
			} else {
				for (ZP_Accounting_Firm__c firm : firms) {
					firm.Processing_State__c = IntegrationUtils.QUEUED_STATE;
				}
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('ZPAccountingFirmTriggerHelper', 'beforeInsert', 'Exception On Line ' + objEx.getLineNumber() + '-' + objEx.getMessage(), objEx.getStackTraceString());
		}
	}

	public void OnAfterInsert(Map<ID, ZP_Accounting_Firm__c> newFirmMap) {
		try {
			if (queue == false) {
				ZPAccountingFirmQueue updateJob = new ZPAccountingFirmQueue(newFirmMap.values());
				ID jobID = System.enqueueJob(updateJob);
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('ZPAccountingFirmTriggerHelper', 'afterInsert', 'Exception On Line ' + objEx.getLineNumber() + '-' + objEx.getMessage(), objEx.getStackTraceString());
		}
	}

	public void OnBeforeUpdate(Map<ID, ZP_Accounting_Firm__c> oldFirmMap, Map<ID, ZP_Accounting_Firm__c> newFirmMap) {
		try {
			if (queue == true) {
				processInformation(newFirmMap.values());
			} else {
				for (ZP_Accounting_Firm__c firm : newFirmMap.values()) {
					firm.Processing_State__c = IntegrationUtils.QUEUED_STATE;
				}
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('ZPAccountingFirmTriggerHelper', 'OnBeforeUpdate', 'Exception On Line ' + objEx.getLineNumber() + '-' + objEx.getMessage(), objEx.getStackTraceString());
		}
	}

	public void OnAfterUpdate(Map<ID, ZP_Accounting_Firm__c> oldFirmMap, Map<ID, ZP_Accounting_Firm__c> newFirmMap) {
		try {
			if (queue == false) {
				ZPAccountingFirmQueue updateJob = new ZPAccountingFirmQueue(newFirmMap.values());
				ID jobID = System.enqueueJob(updateJob);
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('ZPAccountingFirmTriggerHelper', 'OnAfterUpdate', 'Exception On Line ' + objEx.getLineNumber() + '-' + objEx.getMessage(), objEx.getStackTraceString());
		}
	}

	private Account mapAccountFields(ZP_Accounting_Firm__c firmInfo, Map<String, Account> map_FirmIdToAccounts, Lead objLead, Account account) {
		if (account == null) {
			account = new Account();
		}

		account.Type = (account.Type == AccountUtil.EMBEDDED_PARTNER_TYPE ? AccountUtil.EMBEDDED_PARTNER_TYPE :AccountUtil.RESELLER_ACCOUNT_TYPE);
		account.RecordTypeId = Cache.getRecordTypeId('Account', 'Reseller');
		account.Name = firmInfo.Name__c;
		account.AM_Tier__c = firmInfo.Partner_Level__c;
		account.ZP_Firm_ID__c = firmInfo.Id__c;
		account.Fast_Ach_Type__c = firmInfo.Fast_Ach_Type__c;
		account.Landing_Page_URL__c = firmInfo.Landing_Page_URL__c;
		//reward eligibility fields
		account.Customers_Reward_Eligible__c = firmInfo.Customers_Reward_Eligible__c;
		account.Customers_Reward_Ineligible__c = firmInfo.Customers_Reward_Ineligible__c;
		account.Setup_Customers_Reward_Eligible__c = firmInfo.Setup_Customers_Reward_Eligible__c;
		account.Setup_Customers_Reward_Ineligible__c = firmInfo.Setup_Customers_Reward_Ineligible__c;
		// Partner Directory Fields
		account.PD_Member_Status__c = firmInfo.PD_Member_Status__c;
		account.PD_Membership_Date__c = firmInfo.PD_Membership_Date__c;
		account.PD_Is_Accepting_New_Clients__c = firmInfo.PD_Is_Accepting_New_Clients__c;
		account.PD_Is_Accepting_Remote_Clients__c = firmInfo.PD_Is_Accepting_Remote_Clients__c;
		account.PD_Is_Account_Tech__c = firmInfo.PD_Is_Account_Tech__c;
		account.PD_Firm_Size__c = firmInfo.PD_firm_size__c;
		account.Referral_Type__c = firmInfo.Referral_Type__c;
		account.Referred_By__c = getReferredById(firmInfo, map_FirmIdToAccounts);

		account.PD_Software_Used__c = convertPDFieldToPicklist(firmInfo.PD_Software_Used__c);
		account.PD_Industries_Served__c = convertPDFieldToPicklist(firmInfo.PD_Industries_Served__c);
		account.PD_Services_Offered__c = convertPDFieldToPicklist(firmInfo.PD_Services_Offered__c);
		account.PD_Company_Sizes_Served__c = convertPDFieldToPicklist(firmInfo.PD_Company_Sizes_Served__c);
		if (objLead != null && String.isNotBlank(objLead.LeadSource)) {
			account.Lead_Source__c = objLead.LeadSource;
			account.AccountSource = objLead.LeadSource;
		}
		if (firmInfo.Merged_Firm_ID__c != null && String.isNotBlank(firmInfo.Merged_Firm_ID__c)) {
			account.Sales_Engagement_Status__c = AccountUtil.SALES_ENGMNT_STATUS_UNQUALIFIED;
			account.Sales_Engagement_Status_Detail__c = AccountUtil.SALES_ENGMNT_STATUS_DETAIL_DISCOVERY_DUPE;
			account.Is_Duplicate__c = true;
			account.Account_Priority__c = AccountUtil.ACCOUNT_PRIORITY_5;
			account.OwnerId = System.Label.Partner_House_Account;
			account.Possible_Duplicate_Account__c = map_FirmIdToAccounts.containsKey(firmInfo.Merged_Firm_ID__c) ? map_FirmIdToAccounts.get(firmInfo.Merged_Firm_ID__c).Id : null;
		}
		return account;
	}

	// Converts the input string value into an acceptable picklist string.
	private String convertPDFieldToPicklist(String strInputString) {
		String strConvertedString = '';

		if (String.isNotBlank(strInputString)) {
			strConvertedString = strInputString.replaceAll('\\[', '').replaceAll('\\]', '').replaceAll('",', ';').replaceAll('"', '');

			if (String.isNotBlank(strConvertedString)) {
				strConvertedString += ';';
			}
		}

		return strConvertedString;
	}

	public Id getReferredById(ZP_Accounting_Firm__c objFirm, Map<String, Account> map_ResellerAccs) {
		Id idReferredBy = null;
		if (String.isNotBlank(objFirm.Referred_by_Accounting_Firm_ID__c) && objFirm.Referred_by_Accounting_Firm_ID__c != objFirm.Id__c) {
			idReferredBy = map_ResellerAccs.containsKey(objFirm.Referred_by_Accounting_Firm_ID__c) ? map_ResellerAccs.get(objFirm.Referred_by_Accounting_Firm_ID__c).Id : null;
		} else if (String.isNotBlank(objFirm.Referred_by_Company_Id__c)) {
			idReferredBy = map_CompanyIdToAcc.containsKey(objFirm.Referred_by_Company_Id__c) ? map_CompanyIdToAcc.get(objFirm.Referred_by_Company_Id__c).Id : null;
		}
		return idReferredBy;
	}

	private void processInformation(List<ZP_Accounting_Firm__c> firmList) {
		Set<String> firmIdSet = new Set<String>();
		Set<String> set_CompanyIds = new Set<String>();
		Set<String> leadIdSet = new Set<String>();
		Set<String> leadCreatedByEmailSet = new Set<String>();
		Set<String> failedFirmEmailSet = new Set<String>();
		Set<String> newFirmIdNoLeadSet = new Set<String>();
		map<String, ZP_Accounting_Firm__c> firmMap = new Map<String, ZP_Accounting_Firm__c>();
		map<String, ZP_Accounting_Firm__c> firmIdMap = new Map<String, ZP_Accounting_Firm__c>();
		List<Account> accountList = new List<Account>();
		List<Lead> list_LeadsToCreate = new List<Lead>();
		List<ZP_Company__c> list_ZPCompanies = new List<ZP_Company__c>();
		Map<String, String> map_LeadInsertDMLErrors = new Map<String, String>();
		Set<String> set_LeadsToConvert = new Set<String>();
		Map<Id, List<Event>> map_LeadIdToTaksList = new Map<Id, List<Event>>();
		Set<Id> set_LeadIds = new Set<Id>();
		Set<String> set_AccountantLeadIds = new Set<String>();
		Set<String> set_NewFirmIds = new Set<String>();

		for (ZP_Accounting_Firm__c firm : firmList) {
			if (firm.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			//do not process if the processing state is not Queued
			if (firm.Processing_State__c != IntegrationUtils.QUEUED_STATE) {
				firm.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
			firmMap.put(firm.Created_By_Email__c, firm);
			if (String.isNotBlank(firm.Accountant_Lead_Id__c)) {
				firmMap.put(firm.Accountant_Lead_Id__c, firm);
				set_AccountantLeadIds.add(firm.Accountant_Lead_Id__c);
			}
			firmIdMap.put(firm.Id__c, firm);
			firmIdSet.add(firm.Id__c);
			if (firm.Created_By_Email__c != null && firm.Created_By_Email__c != '') {
				leadCreatedByEmailSet.add(firm.Created_By_Email__c);
			}
			firm.Message__c = '';
			if (String.isNotBlank(firm.Merged_Firm_ID__c)) {
				firmIdSet.add(firm.Merged_Firm_ID__c);
			}
			if (String.isNotBlank(firm.Referred_by_Accounting_Firm_ID__c)) {
				firmIdSet.add(firm.Referred_by_Accounting_Firm_ID__c);
			}
			if (String.isNotBlank(firm.Referred_by_Company_Id__c)) {
				set_CompanyIds.add(firm.Referred_by_Company_Id__c);
			}
		}

		//get matching ZP Companies by email and set the processing status to queued
		getCompaniesByEmail(leadCreatedByEmailSet);

		// get matching leads and convert them. If there are errors log them.
		Map<String, Lead> matchingLeadsMap = getResellerLeads(leadCreatedByEmailSet, set_AccountantLeadIds);
		Map<String, Contact> map_Contacts = getContactsByEmailId(leadCreatedByEmailSet);
		Map<String, Account> accountMap = getAccounts(firmIdSet, set_CompanyIds);
		Map<Id, Contact> map_ContactsToUpdate = new Map<Id, Contact>();

		/**
		 * Added by David (Dato) Tsamalashvili - May 12, 2020
		 * If lead doesn't exist - flag it for workato
		 */
		for (ZP_Accounting_Firm__c objFirm : firmList) {
			if (
				String.isNotBlank(objFirm.Created_By_Email__c) &&
				!matchingLeadsMap.containsKey(objFirm.Created_By_Email__c) &&
				!matchingLeadsMap.containsKey(objFirm.Accountant_Lead_Id__c) &&
				!map_Contacts.containsKey(objFirm.Created_By_Email__c) &&
				!accountMap.containsKey(objFirm.Id__c)
			) {
				Lead objNewLead = new Lead();
				objNewLead.RecordTypeId = Cache.getRecordTypeId('Lead', 'Reseller');
				objNewLead.Company = objFirm.Name__c;
				objNewLead.FirstName = objFirm.Lead_First_Name__c;
				objNewLead.LastName = objFirm.Lead_Last_Name__c;
				objNewLead.Email = objFirm.Created_By_Email__c;
				objNewLead.Phone = objFirm.Lead_Phone__c;
				objNewLead.No_of_Clients__c = objFirm.Lead_Number_Of_Clients__c;
				objNewLead.ZP_Accountant_Lead_ID__c = objFirm.Accountant_Lead_ID__c;
				objNewLead.Visitor_Id__c = objFirm.Created_By_Visitor_ID__c;
				objNewLead.LeadSource = objFirm.Lead_Source__c;
				objNewLead.ZP_Lead_Campaign__c = objFirm.Lead_Campaign__c;
				objNewLead.Referral_Type__c = objFirm.Referral_Type__c;
				objNewLead.ZP_Firm_ID__c = objFirm.Id__c;
				objNewLead.Referred_By__c = getReferredById(objFirm, accountMap);
				objNewLead.Status = LeadUtil.LEAD_STATUS_SAL;

				list_LeadsToCreate.add(objNewLead);
				set_LeadsToConvert.add(objFirm.Created_By_Email__c);
			}
		}

		// create reseller leads if they don't exist already
		if (!list_LeadsToCreate.isEmpty()) {
			List<Database.SaveResult> list_LeadInsertResults = Database.insert(list_LeadsToCreate, false);
			map_LeadInsertDMLErrors = Utils.processSaveResult(list_LeadInsertResults, list_LeadsToCreate, 'Email', true, 'ZPAccountingFirmTriggerHelper :: ProcessInformation :: Create Lead');
			if (map_LeadInsertDMLErrors.keySet().size() > 0) {
				for (ZP_Accounting_Firm__c objFirm : firmList) {
					if (map_LeadInsertDMLErrors.containsKey(objFirm.Created_By_Email__c)) {
						setProcessingState(IntegrationUtils.ERROR_STATE, 'Lead Creation Failed', objFirm);
					}
				}
			}
		}

		// query reseller leads again
		matchingLeadsMap = getResellerLeads(leadCreatedByEmailSet, set_AccountantLeadIds);
		for (ZP_Accounting_Firm__c objFirm : firmList) {
			// If no account exists, add it to list of new firms
			if (!accountMap.containsKey(objFirm.Id__c)) {
				set_NewFirmIds.add(objFirm.Id__c);
			}

			/**
			 * Added by Sandeep Golla - March 14, 2022
			 * If matching zp company found then set processing status to queued
			 */
			if (
				objFirm.Created_By_Email__c != null &&
				objFirm.Id__c != null &&
				!map_matchingCompaniesByEmail.isEmpty() &&
				map_matchingCompaniesByEmail.containsKey(objFirm.Created_By_Email__c) &&
				objFirm.Id__c == map_matchingCompaniesByEmail.get(objFirm.Created_By_Email__c)?.Managing_Accounting_Firm_Id__c
			) {
				ZP_Company__c objCompany = map_matchingCompaniesByEmail.get(objFirm.Created_By_Email__c);
				objCompany.Processing_State__c = IntegrationUtils.MANUAL_ENQUEUE;
				objCompany.Message__c = '';
				list_ZPCompanies.add(objCompany);
			}
		}

		if (!list_ZPCompanies.isEmpty()) {
			Map<String, String> map_dmlZPCompanyUpdateErrors = new Map<String, String>();
			List<Database.SaveResult> saveResult = Database.update(list_ZPCompanies, false);
			map_dmlZPCompanyUpdateErrors = Utils.processSaveResult(saveResult, list_ZPCompanies, 'Id', true, 'ZPAccountingFirmTriggerHelper-processInformation');
		}
		// update zp_firm_Id__c on reseller lead
		List<Lead> leadList = matchingLeadsMap.values();
		for (Lead l : leadList) {
			ZP_Accounting_Firm__c zpAccFim = firmMap.containsKey(l.ZP_Accountant_Lead_Id__c) ? firmMap.get(l.ZP_Accountant_Lead_Id__c) : firmMap.get(l.Email);

			if (zpAccFim != null) {
				l.ZP_Firm_ID__c = zpAccFim.Id__c;
				l.Company = zpAccFim.Name__c;
				l.Referred_By__c = getReferredById(zpAccFim, accountMap);
				if (String.isNotBlank(l.Status) && (l.Status == LeadUtil.LEAD_STATUS_RAW || l.Status == LeadUtil.LEAD_STATUS_AQL)) {
					l.Status = LeadUtil.LEAD_STATUS_MQL;
				}
				if (String.isBlank(l.MQL_Reason__c)) {
					l.MQL_Reason__c = 'Gusto for Partners';
				}
				// Update Accountant Lead Id if not already set on Reseller Lead
				// Set accountant lead Id only if there are no matching leads
				if (String.isBlank(l.ZP_Accountant_Lead_ID__c) && String.isNotBlank(zpAccFim.Accountant_Lead_ID__c) && !map_AllResellerLeads.containsKey(zpAccFim.Accountant_Lead_ID__c)) {
					l.ZP_Accountant_Lead_ID__c = zpAccFim.Accountant_Lead_ID__c;
				}
				set_LeadIds.add(l.Id);
			}
		}
		if (!leadList.isEmpty()) {
			update leadList;
		}

		//query lead tasks
		map_LeadIdToTaksList = queryLeadTasks(set_LeadIds);

		List<Account> tempAccountList = new List<Account>();
		for (ZP_Accounting_Firm__c firm : firmList) {
			if (String.isNotBlank(firm.Created_By_Email__c) && !set_LeadsToConvert.contains(firm.Created_By_Email__c)) {
				if (map_Contacts.containsKey(firm.Created_By_Email__c) && (matchingLeadsMap.containsKey(firm.Created_By_Email__c) || matchingLeadsMap.containsKey(firm.Accountant_Lead_Id__c))) {
					Lead l = matchingLeadsMap.get(firm.Accountant_Lead_Id__c) != null ? matchingLeadsMap.get(firm.Accountant_Lead_Id__c) : matchingLeadsMap.get(firm.Created_By_Email__c);
					Account acc = mapAccountFields(firm, accountMap, l, null);
					if (String.valueOf(l.OwnerId).startsWith('005') && (!accountMap?.containsKey(firm.Id__c) || !accountMap?.get(firm.Id__c)?.Owner?.UserRole?.Name.containsIgnoreCase('partner'))) {
						if (l?.Owner?.IsActive) {
							acc.OwnerId = l.OwnerId;
						}
						acc.Converted_Lead_Id__c = l.Id;
					}
					tempAccountList.add(acc);
				}
			}
		}
		if (tempAccountList.size() > 0) {
			upsert tempAccountList ZP_Firm_ID__c;
			for (Account acc : tempAccountList) {
				if (acc.Id != null) {
					ZP_Accounting_Firm__c firm = firmIdMap.get(acc.ZP_Firm_ID__c);
					Contact objContact = map_Contacts.get(firm.Created_By_Email__c);
					Lead objLead = matchingLeadsMap.get(firm.Accountant_Lead_Id__c);

					if (objContact != null && objLead != null) {
						objContact.AccountId = acc.Id;
						if (objLead?.Owner?.IsActive) {
							objContact.OwnerId = objLead.OwnerId;
						}
					}
					map_ContactsToUpdate.put(objContact.Id, objContact);
				}
			}
		}

		//Update Contact records
		if (!map_ContactsToUpdate.values().isEmpty()) {
			update map_ContactsToUpdate.values();
		}

		if (matchingLeadsMap.values().size() > 0) {
			LeadConversion.ConversionResult conversionResult = LeadConversion.convert(matchingLeadsMap.values());
			List<Database.LeadConvertResult> convertResults = conversionResult.convertResults;
			Map<Id, Database.LeadConvert> map_converts = conversionResult.map_converts;
			integer i = 0;
			for (Lead l : matchingLeadsMap.values()) {
				Database.LeadConvertResult result = convertResults[i];
				Database.LeadConvert leadConvert = map_converts.get(result.getLeadId());
				if (result.getErrors().size() > 0) {
					String error = Utils.ConsolidateErrors(result.getErrors());
					failedFirmEmailSet.add(l.Email);
					ZP_Accounting_Firm__c zpFirm = firmMap.containsKey(l.ZP_Accountant_Lead_Id__c) ? firmMap.get(l.ZP_Accountant_Lead_Id__c) : firmMap.get(l.Email); //change
					setProcessingState(IntegrationUtils.ERROR_STATE, error, zpFirm);
					if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
						System.enqueueJob(
							new LeadConvertQueueable(leadConvert.getLeadId(), leadConvert.getAccountId(), leadConvert.getContactId(), leadConvert.getOpportunityId(), null, zpFirm.Id, true)
						);
						zpFirm.Message__c = ZPCompanyUtil.ASYNC_LEAD_CONVERSION_PENDING;
					}
				}
				i = i + 1;
			}
		}

		accountMap = getAccounts(firmIdSet, new Set<String>());
		for (ZP_Accounting_Firm__c firm : firmList) {
			if (firm.Processing_State__c == IntegrationUtils.DEAD_STATE || firm.Message__c == ZPAccountingFirmUtil.ASYNC_LEAD_CONVERSION_PENDING) {
				continue;
			}
			if (failedFirmEmailSet.contains(firm.Created_By_Email__c) && !Test.isRunningTest()) {
				continue;
			}
			Account acc = new Account();
			if (accountMap.containsKey(firm.Id__c)) {
				acc = accountMap.get(firm.Id__c);
			}
			Lead objLead = map_AllResellerLeads.containsKey(firm.Accountant_Lead_Id__c) ? map_AllResellerLeads.get(firm.Accountant_Lead_Id__c) : map_AllResellerLeads.get(firm.Created_By_Email__c);
			// update sales engagement status based on different criteria
			if (!String.isBlank(firm.Created_By_Email__c) && objLead != null) {
				acc = validateFalseSAL(acc, objLead, firm, map_LeadIdToTaksList, set_NewFirmIds);
			}

			acc = mapAccountFields(firm, accountMap, objLead, acc);
			accountList.add(acc);
		}

		Map<String, String> dmlUpsertErrorsMap = new Map<String, String>();
		if (accountList.size() > 0) {
			List<Database.UpsertResult> saveResult = Database.upsert(accountList, Account.Fields.ZP_Firm_ID__c, false);
			dmlUpsertErrorsMap = Utils.processUpsertResult(saveResult, accountList, 'ZP_Firm_ID__c', true, 'ZPAccountingFirmTriggerHepler-processInformation');
		}

		accountMap = getAccounts(firmIdSet, new Set<String>());

		for (ZP_Accounting_Firm__c firm : firmList) {
			if (dmlUpsertErrorsMap.containsKey(firm.ID__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, dmlUpsertErrorsMap.get(firm.ID__c), firm);
			} else if (firm.processing_state__c == IntegrationUtils.QUEUED_STATE) {
				if (firm.Account__c == null && accountMap.containsKey(firm.Id__c)) {
					firm.Account__c = accountMap.get(firm.Id__c).Id;
				}

				setProcessingState(IntegrationUtils.PROCESSED_STATE, IntegrationUtils.PROCESSED_STATE, firm);
			}
		}
	}

	public Account validateFalseSAL(Account objAccount, Lead objLead, ZP_Accounting_Firm__c objZPFirm, Map<Id, List<Event>> map_LeadIdToTaksList, Set<String> set_NewFirmIds) {
		Boolean blnNewAccount = set_NewFirmIds.contains(objZPFirm.Id__c);
		if (blnNewAccount && objAccount.Reseller_Type__c != ZPAccountingFirmUtil.ACC_RESELLER_TYPE_STRATEGIC_ACC && String.isBlank(objAccount.Sales_Engagement_Status__c)) {
			objAccount.Sales_Engagement_Status__c = ZPAccountingFirmUtil.ACC_SALES_ENGMNT_PROSPECTIVE;
		}

		return objAccount;
	}

	public Map<Id, List<Event>> queryLeadTasks(Set<Id> set_LeadIds) {
		Map<Id, List<Event>> map_Result = new Map<Id, List<Event>>();
		if (set_LeadIds.size() > 0) {
			for (Event objEvent : [SELECT Id, WhoId FROM Event WHERE WhoId IN :set_LeadIds AND RecordTypeId = :Cache.getRecordTypeId('Event', 'AE Demo') AND Event_Status__c = 'Connect']) {
				List<Event> list_Events = map_Result.containsKey(objEvent.WhoId) ? map_Result.get(objEvent.WhoId) : new List<Event>();
				list_Events.add(objEvent);
				map_Result.put(objEvent.WhoId, list_Events);
			}
		}
		return map_Result;
	}

	private Map<String, Account> getAccounts(Set<String> firmIdSet, Set<String> set_CompanyIds) {
		Map<String, Account> accountMap = new Map<String, Account>();
		for (Account acc : [
			SELECT Id, Type, Name, ZP_Company_ID__c, ZP_Firm_ID__c, RecordTypeId, Sales_Engagement_Status__c, Sales_Engagement_Status_Detail__c, Reseller_Type__c, Owner.UserRole.Name
			FROM Account
			WHERE
				(ZP_Firm_ID__c IN :firmIdSet
				AND RecordTypeId = :Cache.getRecordTypeId('Account', 'Reseller'))
				OR (ZP_Company_ID__c IN :set_CompanyIds
				AND RecordTypeId = :Cache.getRecordTypeId('Account', 'Company'))
		]) {
			if (String.isNotBlank(acc.ZP_Firm_ID__c)) {
				accountMap.put('' + acc.ZP_Firm_ID__c, acc);
			} else if (String.isNotBlank(acc.ZP_Company_ID__c)) {
				map_CompanyIdToAcc.put('' + acc.ZP_Company_ID__c, acc);
			}
		}
		return accountMap;
	}

	private map<String, Contact> getContactsByEmailId(Set<String> emailIdSet) {
		Map<String, Contact> contactMap = new Map<String, Contact>();
		for (Contact c : [SELECT Id, Name, email, RecordTypeId, OwnerId, Owner.IsActive FROM Contact WHERE Email IN :emailIdSet AND Email != NULL]) {
			contactMap.put('' + c.email, c);
		}
		return contactMap;
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Query leads by accountant lead id and email address
	 * @Parm        : Set of created by emails
	 * @Parm        : Set of accountant lead ids
	 * @Return      : Map of either accountant lead id or email and leads
	 **/
	private map<String, Lead> getResellerLeads(Set<String> set_Emails, Set<String> set_AccountantLeadIds) {
		Map<String, Lead> map_Leads = new Map<String, Lead>();
		Id idResellerLeadRType = Cache.getRecordTypeId('Lead', 'Reseller');

		// Find unconverted reseller leads and match them based on accountant lead ids or email addresses
		List<Lead> list_MatchingLeads = [
			SELECT
				Id,
				Name,
				Email,
				IsConverted,
				RecordTypeId,
				OwnerId,
				Unique_Email_Address__c,
				ZP_Company_Lead_ID__c,
				ZP_Accountant_Lead_ID__c,
				ZP_Company_ID__c,
				ZP_Firm_ID__c,
				MQL_Reason__c,
				Status,
				LeadSource,
				Ramp_Intent__c,
				Partner_Program_Request_Create_Date__c,
				Owner.UserRole.Name,
				Owner.IsActive
			FROM Lead
			WHERE (Email IN :set_Emails OR ZP_Accountant_Lead_ID__c IN :set_AccountantLeadIds) AND RecordTypeId = :idResellerLeadRType
		];

		// Match based on Accountant Lead Id first and Email address second
		for (Lead objLead : list_MatchingLeads) {
			if (!objLead.IsConverted && String.isNotBlank(objLead.ZP_Accountant_Lead_ID__c) && set_AccountantLeadIds.contains(objLead.ZP_Accountant_Lead_ID__c)) {
				map_Leads.put(objLead.ZP_Accountant_Lead_ID__c, objLead);
			}
			map_AllResellerLeads.put(objLead.ZP_Accountant_Lead_ID__c, objLead);
		}
		// If accountant lead id match is not found, then match by email address
		for (Lead objLead : list_MatchingLeads) {
			if (!objLead.IsConverted && !map_Leads.containsKey(objLead.ZP_Accountant_Lead_ID__c) && String.isNotBlank(objLead.Email)) {
				map_Leads.put(objLead.Email, objLead);
			}
			map_AllResellerLeads.put(objLead.Email, objLead);
		}

		return map_Leads;
	}

	/**
	 * @Author      : Sandeep Golla
	 * @Description : Query ZP Companies by Created By Email and Deleted At blank
	 * @Parm        : Set of created by emails
	 * @Return      : Void
	 **/
	private static void getCompaniesByEmail(Set<String> emailIdSet) {
		for (ZP_Company__c objFirm : [
			SELECT Id, Name, Created_By_Email__c, Managing_Accounting_Firm_Id__c, Deleted_At__c
			FROM ZP_Company__c
			WHERE Created_By_Email__c IN :emailIdSet AND Deleted_At__c = NULL AND Managing_Accounting_Firm_Id__c != NULL
		]) {
			map_matchingCompaniesByEmail.put(objFirm.Created_By_Email__c, objFirm);
		}
	}

	private ZP_Accounting_Firm__c setProcessingState(String state, String message, ZP_Accounting_Firm__c firm) {
		firm.Processing_State__c = state;
		firm.Message__c = message;
		firm.Last_Processed__c = System.now();
		return firm;
	}
}