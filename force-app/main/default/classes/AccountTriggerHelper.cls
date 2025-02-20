/**
 * @description Trigger helper for Account
 *
 * @author Aurobind Ravichandran
 * @since 10/01/2020
 * @group Account
 */
public without sharing class AccountTriggerHelper {
	public static boolean skipTrigger = false;
	private static Set<String> set_CompanyId;
	private static Set<String> set_FirmId;
	private static Set<Id> set_CompanyAccountIds;
	private static Set<Id> set_ResellerAccountIds;
	private static Set<Id> set_SoldByReferredByIds;
	private static Set<Id> set_AccountIds;
	private static Set<Id> set_UserIds;
	private static Set<Id> set_NormalizeAccountIds;
	private static Set<Id> set_OpptyBenefitOrderIds;
	private static Set<Id> set_UpsellOppIds;
	private static Set<String> set_CompanyIdForBillingState;
	private static Set<String> set_ConvertedLeadIds = new Set<String>();
	Map<String, ZP_HI_Deduction__c> map_CompanyIdsToDeductions;
	private static Map<Id, Account> map_ResellerAccountIdAccount;
	private static Map<Id, List<Account>> map_ResellerAccountCompanyList;
	private static Map<Id, User> map_Users;
	private static Set<String> set_HIStates;
	private static Set<String> set_NormalizedEmailDomains;
	private static Map<String, PriceBook2> map_ActivePriceBook;
	private static List<OpportunityLineItem> list_OpportunityLineItemsForDelete;
	private static List<Opportunity> list_UpsellOpp;
	private static BusinessHours objBusinessHour;
	private static Lead_Randomize__c objRandomize;
	private static Integer intNumberOfCompanyAccountHoldOut = 1;
	private static Integer intNumberOfResellerAccountHoldOut = 1;
	public static Map<Id, Account> map_AllAccountMap;
	public static Map<Id, Benefit_Order__c> map_BenefitOrders;
	public static Map<Id, User> map_AllUsers;
	public static Map<String, Account> map_AccountsNormailizedEmailDomains;
	public static Map<Id, List<Contact>> map_AccountIdsToContacts;
	public static Map<Id, List<Contact>> map_AccountIdToContactRecords = new Map<Id, List<Contact>>();
	public static Map<Id, Account> map_ResellerCohortAccts = new Map<Id, Account>();
	public static Map<String, Lead> map_ResellerAccountZPFirmIdToLead;
	public static Boolean blnIsRouting = false;
	public static List<String> list_CaseRecordTypeNames = new List<String>{ 'MF_Audit', 'MF_Cancellation', 'MF_Member_Group_Updates', 'MF_NHE', 'MF_QLE', 'MF_Termination' };
	public static List<String> list_CaseStatus = new List<String>{ 'Submitted', 'Closed' };
	public static final String strMemberOpsBYB = 'Member_Ops_BYB';
	public static final String strMemberFulfillment = 'Member_Fulfillment';
	public static Map<String, Id> map_Queues = GlobalQueryHelper.getQueueNameAndIdMap(new Set<String>{ strMemberOpsBYB, strMemberFulfillment });
	public static Map<Id, Boolean> map_AccIdToBrokerIntegration = new Map<Id, Boolean>();
	public static Map<Id, Case> map_CasesToUpdate = new Map<Id, Case>();
	public static Id idWorkatoIntegrationUserId = AccountUtil.getWorkatoIntegrationUserId();
	public static Configuration_Settings__c objConfigSettings = AccountUtil.objConfigSettings;
	public static Map<Id, Lead> map_ConvertedLeads = new Map<Id, Lead>();
	public static Map<String, ZP_Company__c> map_ZPCompanies = new Map<String, ZP_Company__c>();
	public static Set<Id> set_accountSubscriptionsChanged = new Set<Id>();
	public static Map<Id, Contact> map_contactsToUpdate = new Map<Id, Contact>();
	public static Map<Id, Contact> map_contactsToCallout = new Map<Id, Contact>();
	public static final String HI_SALES_ALL_ROLES = Test.isRunningTest() ? 'Integration Users' : System.Label.Benefits_Roles;
	public static final String ROLES_SKIP_HI_ROUTING_DEDUCTIONS_CHANGE = Test.isRunningTest() ? 'Integration Users' : 'sales_mm_fs_xx, sales_sb_fs_xx';
	public static Map<Id, List<UserAccountTeamMember>> map_UserAccountTeamMembers = new Map<Id, List<UserAccountTeamMember>>();
	public static Map<Id, Opportunity> map_OpptysToUpdate = new Map<Id, Opportunity>();
	public static Map<Id, Insurance_Quote__c> map_InsuranceQuotesToUpdate = new Map<Id, Insurance_Quote__c>();
	public static Map<Id, Account> map_AccountsToUpdate = new Map<Id, Account>();
	public static Set<Id> set_accountsCSMUpdated = new Set<Id>();
	public static Map<Id, List<AccountTeamMember>> map_AccountIdToATMRecords = new Map<Id, List<AccountTeamMember>>();
	public static List<AccountTeamMember> list_ATMsToInsert = new List<AccountTeamMember>();
	public static Map<Id, AccountTeamMember> map_ATMsToDelete = new Map<Id, AccountTeamMember>();
	public static String SALES_BUSINESS_HOURS = 'Gusto - Denver - Sales';
	public static Map<String, International_Payroll_Countries__mdt> map_InternationalPayrollCountries = International_Payroll_Countries__mdt.getAll();

	public static List<Opportunity> list_OpptysToInsert = new List<Opportunity>();
	public static Set<Id> set_DiscountAccountIds = new Set<Id>();
	public static CustomNotificationType objInternationalPayrollNotify = null;
	public static final String UPSELL_OPP_SUFFIX = ' - Cross sell EOR';
	public static final String TIER_UPSELL_OPP_SUFFIX = ' - Tier Upsell';
	public static Map<Id, User> map_UsersToCheckCSRole = new Map<Id, User>();
	public static Boolean blnCreateProductUpsellFromCompany = true;
	public static Map<Id, Account> map_AccountsForRouting = new Map<Id, Account>();
	public static List<Partnership_Interest__c> list_PartnershipInterestsToInsert;
	public Set<Id> set_ParentResellerIds = new Set<Id>();
	public Set<Id> set_OpportunityIdsToRoute = new Set<Id>();
	public Set<String> set_ClosedWonOpptyIDs = new Set<String>();
	public static final String PENDING_ROUTING = 'pending_routing';

	public static String strInternationalPayrollOnboardingTeam = System.Label.International_Payroll_Onboarding_Team;
	public AccountTriggerHelper() {
		list_OpportunityLineItemsForDelete = new List<OpportunityLineItem>();
		map_Users = new Map<Id, User>();
		set_NormalizedEmailDomains = new Set<String>();
		set_OpptyBenefitOrderIds = new Set<Id>();
		map_AccountsNormailizedEmailDomains = new Map<String, Account>();
		list_UpsellOpp = new List<Opportunity>();
	}

	/**
	 * @description         BeforeInsert handler
	 *
	 * @param list_Accounts Trigger.new (IDs have not been assigned, and Trigger.old does not exist)
	 */
	public void processBeforeInsert(List<Account> list_Accounts) {
		// Create data collections
		setDataCollections(list_Accounts, null);
		setAccountDataMaps();
		queryAccountsWithNormalizedEmailonCreate();
		queryConvertedLeads(true);

		if (!set_FirmId.isEmpty()) {
			queryLeads();
		}

		for (Account objAccount : list_Accounts) {
			// Set ZP Company Id if its not already set
			if (
				String.isBlank(objAccount.ZP_Company_ID__c) &&
				String.isNotBlank(objAccount.Converted_Lead_Id__c) &&
				map_ConvertedLeads.containsKey(objAccount.Converted_Lead_Id__c) &&
				map_ZPCompanies.containsKey(map_ConvertedLeads.get(objAccount.Converted_Lead_Id__c).Email) &&
				objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID
			) {
				objAccount.ZP_Company_ID__c = map_ZPCompanies.get(map_ConvertedLeads.get(objAccount.Converted_Lead_Id__c).Email).Id__c;
			}
			setDefaultsOnCreate(objAccount);
			if (
				String.isNotBlank(objAccount.Normalized_Email_Domain__c) && objAccount.Record_Type__c == AccountUtil.RESELLER_ACCOUNT_TYPE ||
				objAccount.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID
			) {
				queryNormalizedEmailDomain(objAccount, null);
			}
			doAccountRouting(objAccount, null);

			if (objAccount.RecordTypeId == AccountUtil.EMBEDDED_COMPANY_ACCOUNT_RT_ID) {
				objAccount.OwnerId = idWorkatoIntegrationUserId;
			}
			//for each new account, update subscription preferences
			setSubscriptionPreferencesOnAccount(objAccount, null, true);
		}

		populateGEPAccounts(list_Accounts, null);
	}

	/**
	 * @description Handle AfterInsert
	 *
	 * @param map_Accounts Trigger.newMap (note: Trigger.old does not exist in insert context)
	 */
	public void processAfterInsert(Map<Id, Account> map_Accounts) {
		List<Entitlement> list_Entitlements = new List<Entitlement>();

		// Create data collections
		setDataCollections(map_Accounts.values(), null);

		for (Account objAccount : map_Accounts.values()) {
			//create entitlement records for all company accounts
			Entitlement objEntitlement = getEntitlementInfo(objAccount);
			if (objEntitlement != null) {
				list_Entitlements.add(objEntitlement);
			}
			//update First Client Add date for reseller accounts
			setFirstClientAddDateOnReseller(objAccount, null);
		}

		if (!list_Entitlements.isEmpty()) {
			insert list_Entitlements;
		}

		if (!map_AccountsToUpdate.isEmpty()) {
			AccountTriggerHelper.skipTrigger = true;
			update map_AccountsToUpdate.values();
			AccountTriggerHelper.skipTrigger = false;
		}

		// reset static variables to free up heap storage - PLEASE PLACE THIS ALWAYS IN THE END
		resetStaticVariables();
	}

	/**
	 * @description           BeforeUpdate handler
	 *
	 * @param map_OldAccounts Trigger.oldMap
	 * @param map_Accounts    Trigger.new
	 */
	public void processBeforeUpdate(Map<Id, Account> map_OldAccounts, Map<Id, Account> map_Accounts) {
		List<String> list_OldOwnerId = new List<String>();

		// Create data collections
		setDataCollections(map_Accounts.values(), map_OldAccounts);
		queryConvertedLeads(false);
		for (Account objAccount : map_Accounts.values()) {
			if (objAccount.OwnerId != map_OldAccounts.get(objAccount.Id).OwnerId) {
				list_OldOwnerId.add(map_OldAccounts.get(objAccount.Id).OwnerId);
				set_UserIds.add(map_OldAccounts.get(objAccount.Id).OwnerId);
			}
			if (objAccount.CreatedById != null) {
				set_UserIds.add(objAccount.CreatedById);
			}
			if (objAccount.RecordTypeId == AccountUtil.EMBEDDED_COMPANY_ACCOUNT_RT_ID) {
				objAccount.OwnerId = idWorkatoIntegrationUserId;
			}

			// BTE-3527, When TAM is assigned, make CX_Engagement_Flag__c blank
			if (objAccount.Technical_Account_Manager__c != map_OldAccounts.get(objAccount.Id).Technical_Account_Manager__c && objAccount.Technical_Account_Manager__c != null) {
				objAccount.CX_Engagement_Flag__c = null;
			}
			//for each account, update subscription preferences if changed
			setSubscriptionPreferencesOnAccount(objAccount, map_OldAccounts.get(objAccount.Id), false);
			setFieldsOnCSMChange(objAccount, map_OldAccounts.get(objAccount.Id));
		}

		//Queries and sets account maps by company account id, firm account id, zp company id, zp firm id
		setAccountDataMaps();
		for (Account objAccount : map_Accounts.values()) {
			Account objOldAccount = map_OldAccounts.get(objAccount.Id);

			setDefaultsOnUpdate(objOldAccount, objAccount);
			if (String.isNotBlank(objAccount.Normalized_Email_Domain__c) && objAccount.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID) {
				set_NormalizedEmailDomains.add(objAccount.Normalized_Email_Domain__c);
			}
			// Set HI Owner only for non-suspended accounts
			if (objAccount.ZP_Company_Overall_Status__c != AccountUtil.ACCOUNT_OVERALL_STATUS_SUSPENDED && objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
				setHIOwner(objAccount, objOldAccount);
			}
		}

		queryAccountsWithNormalizedEmailonUpdate(set_ResellerAccountIds);
		getMapOfCompanyIdsToDeduction(set_CompanyIdForBillingState);
		ZPHIDeductionTriggerHelper objDeductionTriggerHelper = new ZPHIDeductionTriggerHelper();
		for (Account objAccount : map_Accounts.values()) {
			Account objOldAccount = map_OldAccounts.get(objAccount.Id);
			if (
				objAccount.Normalized_Email_Domain__c != objOldAccount.Normalized_Email_Domain__c &&
				String.isNotBlank(objAccount.Normalized_Email_Domain__c) &&
				objAccount.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID
			) {
				queryNormalizedEmailDomain(objAccount, objOldAccount);
			}
			doAccountRouting(objAccount, objOldAccount);

			// Set Account Fields Like Benefit Deduction Category
			if (
				String.isNotBlank(objAccount.ZP_Company_ID__c) &&
				objAccount.BillingStateCode != objOldAccount.BillingStateCode &&
				objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID &&
				map_CompanyIdsToDeductions != null &&
				map_CompanyIdsToDeductions.containsKey(objAccount.ZP_Company_ID__c)
			) {
				ZP_HI_Deduction__c objDeduction = map_CompanyIdsToDeductions.get(objAccount.ZP_Company_ID__c);
				objDeductionTriggerHelper.setAccountValues(objAccount, objDeduction);
			}
		}

		populateGEPAccounts(map_Accounts.values(), map_OldAccounts);
	}

	/**
	 * @description Get the Map of Company Id With ZP Deduction Object
	 * @author Nigam Goyal | 04-21-2023
	 * @param set_CompanyIdForBillingState
	 **/
	public void getMapOfCompanyIdsToDeduction(Set<String> set_CompanyIdForBillingState) {
		map_CompanyIdsToDeductions = new Map<String, ZP_HI_Deduction__c>();
		if (set_CompanyIdForBillingState.size() > 0) {
			for (ZP_HI_Deduction__c objZPHIDeduction : [
				SELECT Id, Company_ID__c, Carriers__c, Medical_Carriers_Supported__c, active_employee_count__c, descriptions__c, types__c, Carriers_Other__c
				FROM ZP_HI_Deduction__c
				WHERE Company_ID__c IN :set_CompanyIdForBillingState
			]) {
				map_CompanyIdsToDeductions.put(objZPHIDeduction.Company_ID__c, objZPHIDeduction);
			}
		}
	}

	/**
	 * @description           AfterUpdate handler
	 *
	 * @param map_OldAccounts Trigger.oldMap
	 * @param map_Accounts    Trigger.new
	 */
	public void processAfterUpdate(Map<Id, Account> map_OldAccounts, Map<Id, Account> map_Accounts) {
		List<Partnership_Interest__c> list_PartnershipInterests = new List<Partnership_Interest__c>();
		List<Case> list_Case = new List<Case>();
		List<Order> list_Order = new List<Order>();
		List<Account_Related_Tracking__c> list_AccountRelatedtracking = new List<Account_Related_Tracking__c>();
		List<Task> list_Task = new List<Task>();
		Set<Id> set_AccountIds = new Set<Id>();
		map_AllUsers = new Map<Id, User>();
		Set<Id> set_AccountIdForRecordTypeChange = new Set<Id>();
		list_OpptysToInsert = new List<Opportunity>();
		List<Account> list_AccountsToForAcquisition = new List<Account>();

		for (Account objAccount : map_Accounts.values()) {
			if (objAccount.OwnerId != null) {
				set_UserIds.add(objAccount.OwnerId);
			}
			if (objAccount.CreatedById != null) {
				set_UserIds.add(objAccount.CreatedById);
			}
			Account objOldAccount = map_OldAccounts.get(objAccount.Id);

			if (objAccount.Big_Desk_Pilot_Customer__c != objOldAccount.Big_Desk_Pilot_Customer__c) {
				map_AccIdToBrokerIntegration.put(objAccount.Id, objAccount.Big_Desk_Pilot_Customer__c);
			}

			if (objOldAccount.OwnerId != objAccount.OwnerId) {
				set_AccountIds.add(objAccount.Id);
			}

			if (
				(objOldAccount.RecordTypeId != objAccount.RecordTypeId) &&
				(objAccount.RecordTypeId == AccountUtil.EMBEDDED_COMPANY_ACCOUNT_RT_ID ||
				objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID ||
				objAccount.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID ||
				objAccount.RecordTypeId == AccountUtil.PARTNER_RT_ID)
			) {
				set_AccountIdForRecordTypeChange.add(objAccount.Id);
			}

			Partnership_Interest__c objPartnershpInterest = getPartnershpInterest(objOldAccount, objAccount);
			if (objPartnershpInterest != null) {
				list_PartnershipInterests.add(objPartnershpInterest);
			}

			Order objOrder = getOrderInformation(objOldAccount, objAccount);
			if (objOrder != null) {
				list_Order.add(objOrder);
			}

			Case objCase = getTaxAuditCaseInformation(AccountUtil.TAX_PAYER_AUDIT, objOldAccount, objAccount);
			if (objCase != null) {
				list_Case.add(objCase);
			}

			Account_Related_Tracking__c objAccountRelatedTracking = getAccountRelatedTracking(objOldAccount, objAccount);
			if (objAccountRelatedTracking != null) {
				list_AccountRelatedtracking.add(objAccountRelatedTracking);
			}

			Task objTask = getTaskInformation(objOldAccount, objAccount);
			if (objTask != null) {
				list_Task.add(objTask);
			}

			if (AccountUtil.blnHIOwnerRouting == true && objAccount.Skip_Validation_For_Routing__c == true) {
				Account objAccToUpdate = new Account(Id = objAccount.Id, Skip_Validation_For_Routing__c = false);
				map_AccountsToUpdate.put(objAccToUpdate.Id, objAccToUpdate);
			}

			//for each account, update its admin contacts if subscription preferences changed
			setSubscriptionPreferenceOnContacts(objAccount, objOldAccount);
			// Update HI Owner on Child Accounts and Open Benefits Opportunities
			updateHIOwnerOnRelatedRecords(objAccount, objOldAccount);
			addUpdateCSMAccountTeamMemberOnCSMChange(objAccount, objOldAccount);
			//update First Client Add date for reseller accounts
			setFirstClientAddDateOnReseller(objAccount, objOldAccount);
			checkOpportunitiesForRouting(objAccount, objOldAccount);
			

			if ((objAccount.Tier__c != objOldAccount.Tier__c || 
			objAccount.Additional_Services__c != objOldAccount.Additional_Services__c)) {
				list_AccountsToForAcquisition.add(objAccount);
			}
		}

		if (!list_AccountsToForAcquisition.isEmpty()) {
			System.debug('list_AccountsToForAcquisition: ' + list_AccountsToForAcquisition);
			//OpportunityHelper.createUpdateAcquisitionOpportunity(list_AccountsToForAcquisition);
		}

		//update company and reseller opportunities
		updateOpportunityInformation(map_oldAccounts, map_Accounts);
		processICPProductInterest(map_Accounts, map_oldAccounts);
		processInternationalPayroll(map_Accounts, map_oldAccounts);

		if (!list_PartnershipInterests.isEmpty()) {
			update list_PartnershipInterests;
		}

		if (!list_Case.isEmpty()) {
			insert list_Case;
		}

		if (!list_Order.isEmpty()) {
			update list_Order;
		}

		if (!list_Task.isEmpty()) {
			insert list_Task;
		}

		if (!list_AccountRelatedtracking.isEmpty()) {
			AccountRelatedTrackingTriggerHelper.skipTrigger = true;
			upsert list_AccountRelatedtracking Unique_Account_Id__c;
			AccountRelatedTrackingTriggerHelper.skipTrigger = false;
		}
		if (set_UserIds != null) {
			map_AllUsers = getUserMap(set_UserIds);
		}

		//update child partner company accounts for reseller accounts
		updatePartnerChildAccounts(map_OldAccounts, map_Accounts);

		if (!set_AccountIds.isEmpty()) {
			Integer intCounter = [SELECT COUNT() FROM Contact WHERE AccountId IN :set_AccountIds];
			if (intCounter > 0 && ((Limits.getLimitDMLRows() - Limits.getDMLRows()) >= intCounter) && ((Limits.getLimitQueryRows() - Limits.getQueryRows() >= intCounter))) {
				//Query Contacts related to Accounts
				if (map_AccountIdsToContacts == null || map_AccountIdsToContacts.isEmpty()) {
					map_AccountIdsToContacts = queryContact(set_AccountIds);
				}
				//update reseller contacts
				updateContactInformation(map_oldAccounts, map_Accounts);
			} else if (intCounter > 0 && Limits.getLimitDMLRows() >= intCounter && (Limits.getLimitQueryRows() >= intCounter)) {
				// Call future method
				updateContactOwnerFuture(set_AccountIds);
			}
		}

		if (!set_AccountIdForRecordTypeChange.isEmpty()) {
			updateContactRecordType(set_AccountIdForRecordTypeChange);
		}

		updateSoldByOpportunitiesOnUpdate(map_Accounts.values(), map_OldAccounts);

		if (blnCreateProductUpsellFromCompany) {
			createProductUpsell(map_Accounts.values(), map_OldAccounts);
		}

		if (list_PartnershipInterestsToInsert != null && !list_PartnershipInterestsToInsert.isEmpty()) {
			insert list_PartnershipInterestsToInsert;
		}

		if (!map_AccIdToBrokerIntegration.isEmpty()) {
			updateBYOBCustomerOnCaseRecords(map_AccIdToBrokerIntegration);
		}

		if (!map_CasesToUpdate.isEmpty()) {
			update map_CasesToUpdate.values();
		}
		if (!map_contactsToUpdate.isEmpty()) {
			TriggerHandler.bypass('ContactTriggerHandler');
			Map<String, String> map_dmlUpdateErrorsMap = new Map<String, String>();
			List<Database.SaveResult> saveResult = Database.update(map_contactsToUpdate.values(), false);
			map_dmlUpdateErrorsMap = Utils.processSaveResult(saveResult, map_contactsToUpdate.values(), 'Id', true, 'AccountTriggerHelper-processAfterUpdate Updating subscriptions on contacts');
			TriggerHandler.clearBypass('ContactTriggerHandler');
		}

		if (!map_contactsToCallout.isEmpty()) {
			SubscriptionCenterUtil.calloutSubscription(map_contactsToCallout.values(), Contact.SObjectType);
		}

		if (!map_OpptysToUpdate.isEmpty()) {
			// do not skip opportunity trigger here as we have logic in opp trigger that neeeds to run
			update map_OpptysToUpdate.values();
		}

		if (!map_InsuranceQuotesToUpdate.isEmpty()) {
			update map_InsuranceQuotesToUpdate.values();
		}

		if (!map_AccountsToUpdate.isEmpty()) {
			// Account update has to be done only after opportunities are updated
			AccountTriggerHelper.skipTrigger = true;
			update map_AccountsToUpdate.values();
			AccountTriggerHelper.skipTrigger = false;
		}
		if (!list_ATMsToInsert.isEmpty()) {
			Utils.processSaveResult(Database.insert(list_ATMsToInsert, false), list_ATMsToInsert, 'Id', true, 'AccountTriggerHelper-processAfterUpdate inserting ATMs on CSM change');
		}
		if (!map_ATMsToDelete.isEmpty()) {
			Utils.processDeleteResult(Database.delete(map_ATMsToDelete.values(), false), map_ATMsToDelete.values(), 'Id', true, 'AccountTriggerHelper-processAfterUpdate deleting ATMs on CSM change');
		}
		if (!list_OpptysToInsert.isEmpty()) {
			AccountTriggerHelper.skipTrigger = true;
			System.debug('list_OpptysToInsert2222: ' + list_OpptysToInsert);
			insert list_OpptysToInsert;
			AccountTriggerHelper.skipTrigger = false;

			// Send in-app notification about new cross-sell and upsell opportunity with Employer of Record
			for (Opportunity objOppty : list_OpptysToInsert) {
				sendCustomNotification(
					objOppty.Name + ' created',
					'Opportunity was created because there is Employer of Record Interest',
					UserInfo.getUserId(),
					objInternationalPayrollNotify.Id,
					objOppty.Id
				);
			}
			AccountTriggerHelper.skipTrigger = false;
		}

		if (!set_DiscountAccountIds.isEmpty()) {
			new ProductDiscountHelper().handleAccountantProductDiscounts(set_DiscountAccountIds, new Set<Id>());
		}

		if (!map_AccountsForRouting.isEmpty()) {
			if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
				System.enqueueJob(new HIRoutingQueueable(map_AccountsForRouting));
			}
		}

		// Send opportunties to Routing Tool for Routing
		if (!set_OpportunityIdsToRoute.isEmpty()) {
			new SendOpportunityToRingLead(set_OpportunityIdsToRoute).sendOpportunityToRingLead();
		}

		// reset static variables to free up heap storage - PLEASE PLACE THIS ALWAYS IN THE END
		resetStaticVariables();
	}

	/**
	 * @Author      : David (Dato) Tsamalashvili
	 * @Description : Handles Before Delete Context
	 * @Parm        : map_OldAccounts - Map of Account Id and Account Object from Trigger.oldMap
	 * @Return      : N/A
	 **/
	public void processBeforeDelete(Map<Id, Account> map_OldAccounts) {
		for (Account objOldAccount : map_OldAccounts.values()) {
			preventDeletion(objOldAccount);
		}
	}

	/**
	 * @Description : Reset static variables to free up heap size
	 * @Return      : N/A
	 **/
	public void resetStaticVariables() {
		map_AllAccountMap = new Map<Id, Account>();
		map_ResellerAccountIdAccount = new Map<Id, Account>();
		map_ResellerAccountCompanyList = new Map<Id, List<Account>>();
		set_CompanyId = new Set<String>();
		set_FirmId = new Set<String>();
		set_CompanyAccountIds = new Set<Id>();
		set_ResellerAccountIds = new Set<Id>();
		set_SoldByReferredByIds = new Set<Id>();
		set_AccountIds = new Set<Id>();
		set_NormalizeAccountIds = new Set<Id>();
		set_CompanyIdForBillingState = new Set<String>();
		map_OpptysToUpdate = new Map<Id, Opportunity>();
		map_AccountIdsToContacts = new Map<Id, List<Contact>>();
		map_ResellerAccountZPFirmIdToLead = new Map<String, Lead>();
		map_AccountIdToContactRecords = new Map<Id, List<Contact>>();
		map_ResellerCohortAccts = new Map<Id, Account>();
		map_CasesToUpdate = new Map<Id, Case>();
		map_InsuranceQuotesToUpdate = new Map<Id, Insurance_Quote__c>();
		map_AccountsToUpdate = new Map<Id, Account>();
		map_ATMsToDelete = new Map<Id, AccountTeamMember>();
		list_ATMsToInsert = new List<AccountTeamMember>();
		map_AccountsForRouting = new Map<Id, Account>();
		list_PartnershipInterestsToInsert = null;
	}

	/**
	 * @description         When the Broker Integration (BYB) Active field on the Account is updated, accordingly all the case owner belonging
	 * 						to 'MF_Audit','MF_Cancellation','MF_Member_Group_Updates','MF_NHE','MF_QLE','MF_Termination' record type
	 * 						should be set to Member Ops - BYOB queue if field on account is true and Owner to Member Fulfillment Queue if set to false
	 *
	 *
	 * @param map_AccIdToBrokerIntegration    Map of Account Ids to Broker Integration (BYB) Active field value
	 */
	private void updateBYOBCustomerOnCaseRecords(Map<Id, Boolean> map_AccIdToBrokerIntegration) {
		for (Case objCase : getBYOBCustomerCaseRecords(map_AccIdToBrokerIntegration.keySet())) {
			Boolean blnCaseUpdate = false;
			if (
				map_AccIdToBrokerIntegration.containsKey(objCase.AccountId) &&
				map_AccIdToBrokerIntegration.get(objCase.AccountId) &&
				map_Queues.containsKey(strMemberOpsBYB) &&
				map_Queues.get(strMemberOpsBYB) != null &&
				map_Queues.get(strMemberOpsBYB) != objCase.OwnerId
			) {
				objCase.OwnerId = map_Queues.get(strMemberOpsBYB);
				blnCaseUpdate = true;
			} else if (
				map_AccIdToBrokerIntegration.containsKey(objCase.AccountId) &&
				!map_AccIdToBrokerIntegration.get(objCase.AccountId) &&
				map_Queues.containsKey(strMemberFulfillment) &&
				map_Queues.get(strMemberFulfillment) != null &&
				map_Queues.get(strMemberOpsBYB) != objCase.OwnerId
			) {
				objCase.OwnerId = map_Queues.get(strMemberFulfillment);
				blnCaseUpdate = true;
			}
			if (blnCaseUpdate) {
				map_CasesToUpdate.put(objCase.Id, objCase);
			}
		}
	}

	/**
	 * @description         returns the list of open cases for given account ids and selected recprd types
	 *
	 * @param set_AccountIds    Set of Account Ids
	 */
	private List<Case> getBYOBCustomerCaseRecords(Set<Id> set_AccountIds) {
		return [
			SELECT Id, AccountId, RecordType.DeveloperName, Status, OwnerId
			FROM Case
			WHERE AccountId IN :set_AccountIds AND RecordType.DeveloperName IN :list_CaseRecordTypeNames AND Status NOT IN :list_CaseStatus
		];
	}

	/**
	 * @description         For Customer Accounts, check if Reward Eligible is changed, and recalculate OLI discounts
	 *                      <br>For Partner Accounts, check if Discount is changed, and recalculate as well
	 *
	 * @param list_newRecords    Trigger.new
	 * @param map_oldRecordsMap Trigger.oldMap
	 */
	private void updateSoldByOpportunitiesOnUpdate(List<Account> list_newRecords, Map<Id, Account> map_oldRecordsMap) {
		Set<Id> set_AccountIDs = new Set<Id>();
		// For Partner Accounts, check change in Discount__c field
		// For Customer Accounts, check change in Reward_Eligible__c field

		for (Account objAcct : list_newRecords) {
			if (objAcct.RecordTypeId == RecordTypes.getRecordTypeIdFromDeveloperName('Account', 'Reseller')) {
				if (objAcct.Discount__c != map_oldRecordsMap?.get(objAcct.Id).Discount__c) {
					set_AccountIDs.add(objAcct.Id);
				}
			} else if (objAcct.RecordTypeId == RecordTypes.getRecordTypeIdFromDeveloperName('Account', 'Company')) {
				if (objAcct.Reward_Eligible__c != map_oldRecordsMap?.get(objAcct.Id).Reward_Eligible__c) {
					set_AccountIDs.add(objAcct.Id);
				}
			}
		}
		if (!set_AccountIDs.isEmpty()) {
			new ProductDiscountHelper().handleAccountantProductDiscounts(set_AccountIDs, new Set<Id>());
		}
	}

	/**
	 * @description           Update partner Child Accounts
	 *
	 * @param map_OldAccounts Trigger.oldMap
	 * @param map_Accounts    Trigger.newMap
	 */
	private void updatePartnerChildAccounts(Map<Id, Account> map_OldAccounts, Map<Id, Account> map_Accounts) {
		List<Account> list_accountForUpdate = new List<Account>();
		Map<Account, List<Account>> map_AccountsToChildAccounts = new Map<Account, List<Account>>();
		List<Account> parentAccountsToUpdate = new List<Account>();
		for (Account objAccount : map_Accounts.values()) {
			Account objOldAccount = map_OldAccounts.get(objAccount.Id);
			if (
				objAccount.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID &&
				(objAccount.Benefits_Email_Opt_Out__c != objOldAccount.Benefits_Email_Opt_Out__c ||
				objAccount.Benefits_Opt_Out_Details__c != objOldAccount.Benefits_Opt_Out_Details__c ||
				objAccount.Apply_to_all_clients__c != objOldAccount.Apply_to_all_clients__c) &&
				objAccount.Apply_to_all_clients__c &&
				map_ResellerAccountCompanyList.containsKey(objAccount.Id)
			) {
				for (Account objChildAccount : map_ResellerAccountCompanyList.get(objAccount.Id)) {
					objChildAccount.Benefits_Opt_Out_Details__c = objAccount.Benefits_Opt_Out_Details__c;
					objChildAccount.Benefits_Email_Opt_Out__c = objAccount.Benefits_Email_Opt_Out__c;
					list_accountForUpdate.add(objChildAccount);
				}
				parentAccountsToUpdate.add(new Account(Id = objAccount.Id, Apply_to_all_clients__c = false));
				map_AccountsToChildAccounts.put(objAccount, map_ResellerAccountCompanyList.get(objAccount.Id));
			}
		}
		//if there are child accounts to update, call batch job if the data size is greater than the acceptable batch size else update immediately
		if (!list_accountForUpdate.isEmpty()) {
			Integer intChildSize = list_accountForUpdate.size();
			Configuration_Settings__c objConfig = Configuration_Settings__c.getOrgDefaults();
			Integer intBatch = objConfig?.Mark_Partner_Accounts_Opt_Out_Batch_Size__c?.intValue() != null &&
				objConfig?.Mark_Partner_Accounts_Opt_Out_Batch_Size__c?.intValue() != 0
				? objConfig.Mark_Partner_Accounts_Opt_Out_Batch_Size__c.intValue()
				: Test.isRunningTest() ? 20 : 50;
			if (intChildSize < intBatch) {
				if (!parentAccountsToUpdate.isEmpty()) {
					list_accountForUpdate.addAll(parentAccountsToUpdate);
				}
				TriggerHandler.bypass('AccountTriggerHandler');
				update list_accountForUpdate;
				TriggerHandler.clearBypass('AccountTriggerHandler');
			} else {
				Database.executeBatch(new AccountJobs(AccountJobs.UPDATE_PARTNER_CHILD_ACCOUNTS, map_AccountsToChildAccounts), Test.isRunningTest() ? intChildSize : intBatch);
			}
		}
	}

	/**** get Partnershp Interest information ****/
	private Task getTaskInformation(Account objOldAccount, Account objAccount) {
		if (
			objAccount.ZP_Company_Approval_Status__c != objOldAccount.ZP_Company_Approval_Status__c &&
			(objAccount.ZP_Company_Approval_Status__c == AccountUtil.ZP_COMP_APPROVAL_STATUS_APPROVED ||
			objAccount.ZP_Company_Approval_Status__c == AccountUtil.ZP_COMP_APPROVAL_STATUS_REQ_FOR_INFO) &&
			(objAccount.Sold_By__c != null ||
			objAccount.Referred_By__c != null)
		) {
			Account partnerAccount;
			if (objAccount.Sold_By__c != null && map_ResellerAccountIdAccount.containsKey(objAccount.Sold_By__c)) {
				partnerAccount = map_ResellerAccountIdAccount.get(objAccount.Sold_By__c);
			}

			if (objAccount.Referred_By__c != null && map_ResellerAccountIdAccount.containsKey(objAccount.Referred_By__c)) {
				partnerAccount = map_ResellerAccountIdAccount.get(objAccount.Referred_By__c);
			}

			if (partnerAccount != null) {
				Task objTask = new Task();
				objTask.WhatId = partnerAccount.Id;
				objTask.Subject = objAccount.Name + ' -  ' + AccountUtil.JUST_GOT_APPROVED;
				objTask.OwnerId = partnerAccount.OwnerId;
				objTask.RecordTypeId = TaskUtil.TASK_STANDARD_RT_ID;
				return objTask;
			}
		}
		return null;
	}

	/**** get Partnershp Interest information ****/
	private Account_Related_Tracking__c getAccountRelatedTracking(Account objOldAccount, Account objAccount) {
		Account_Related_Tracking__c objAccountRelatedTracking = new Account_Related_Tracking__c();
		if (objOldAccount.Account_Priority__c != objAccount.Account_Priority__c || objOldAccount.No_of_Clients__c != objAccount.No_of_Clients__c || objOldAccount.OwnerId != objAccount.OwnerId) {
			Map<Id, Account_Related_Tracking__c> map_accountIdToAccRelTracking = AccountUtil.getAccountRelatedTracking(set_accountIds);
			if (map_accountIdToAccRelTracking.containsKey(objAccount.Id)) {
				objAccountRelatedTracking = map_accountIdToAccRelTracking.get(objAccount.Id);
			} else {
				objAccountRelatedTracking = new Account_Related_Tracking__c();
				objAccountRelatedTracking.Account__c = objAccount.Id;
				objAccountRelatedTracking.Unique_Account_Id__c = objAccount.Id;
			}

			if (objOldAccount.Account_Priority__c != objAccount.Account_Priority__c) {
				Decimal oldPriorityValue = objAccountRelatedTracking.No_Of_Change_in_Account_Priority__c;
				if (oldPriorityValue == null) {
					oldPriorityValue = 0;
				}
				objAccountRelatedTracking.No_Of_Change_in_Account_Priority__c = oldPriorityValue + 1;
				objAccountRelatedTracking.Last_Account_Priority_Change_Date__c = System.now();
			}

			if (objOldAccount.No_of_Clients__c != objAccount.No_of_Clients__c) {
				Decimal oldNoClient = objAccountRelatedTracking.No_Of_Change_No_Of_Clients__c;
				if (oldNoClient == null) {
					oldNoClient = 0;
				}
				objAccountRelatedTracking.No_Of_Change_No_Of_Clients__c = oldNoClient + 1;
				objAccountRelatedTracking.Last_Client_Change_Date__c = System.now();
			}

			// Reset 'By Owner' fields when Account ownership changes
			if (objOldAccount.OwnerId != objAccount.OwnerId) {
				objAccountRelatedTracking.Attempts_By_Owner__c = 0;
				objAccountRelatedTracking.Connects_By_Owner__c = 0;
				objAccountRelatedTracking.Voicemails_By_Owner__c = 0;
			}
			return objAccountRelatedTracking;
		}
		return null;
	}

	/**** get Partnershp Interest information ****/
	private Partnership_Interest__c getPartnershpInterest(Account objOldAccount, Account objAccount) {
		if (objAccount.Tier__c != null && objOldAccount.Tier__c != objAccount.Tier__c) {
			Map<Id, Partnership_Interest__c> map_PartnershipInterests = AccountUtil.getCompanyPartnershipInterest(set_AccountIds);
			if (map_PartnershipInterests.containsKey(objAccount.Id)) {
				Partnership_Interest__c objPartnershipInterest = map_PartnershipInterests.get(objAccount.Id);
				if (objPartnershipInterest.Current_Tier__c == null || objPartnershipInterest.Current_Tier__c != objAccount.Tier__c) {
					objPartnershipInterest.Current_Tier__c = objAccount.Tier__c;
					objPartnershipInterest.Date_Tier_Changed__c = System.now();
					return objPartnershipInterest;
				}
			}
		}
		return null;
	}

	/**** Set data collections ****/
	private void setDataCollections(List<Account> list_Accounts, Map<Id, Account> map_OldAccounts) {
		set_CompanyId = new Set<String>();
		set_FirmId = new Set<String>();
		set_CompanyAccountIds = new Set<Id>();
		set_ResellerAccountIds = new Set<Id>();
		set_SoldByReferredByIds = new Set<Id>();
		set_AccountIds = new Set<Id>();
		set_UserIds = new Set<Id>{ UserInfo.getUserId() };
		set_NormalizeAccountIds = new Set<Id>();
		set_CompanyIdForBillingState = new Set<String>();
		map_OpptysToUpdate = new Map<Id, Opportunity>();

		for (Account objAccount : list_Accounts) {
			set_UserIds.add(objAccount.OwnerId);

			if (objAccount.HI_Owner__c != null) {
				set_UserIds.add(objAccount.HI_Owner__c);
			}
            
			if (objAccount.CSM_Owner__c != null) {
				set_UserIds.add(objAccount.CSM_Owner__c);
			}

			if (objAccount.Id != null) {
				set_AccountIds.add(objAccount.Id);
			}

			if (String.isNotBlank(objAccount.ZP_Company_ID__c)) {
				set_companyId.add(objAccount.ZP_Company_ID__c);
			}

			if (String.isNotBlank(objAccount.ZP_Firm_ID__c)) {
				set_FirmId.add(objAccount.ZP_Firm_ID__c);
			}

			if (objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
				set_CompanyAccountIds.add(objAccount.Id);
			}

			if (objAccount.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID) {
				set_ResellerAccountIds.add(objAccount.Id);
			}

			if (objAccount.Sold_By__c != null) {
				set_SoldByReferredByIds.add(objAccount.Sold_By__c);
			}

			if (objAccount.Referred_By__c != null) {
				set_SoldByReferredByIds.add(objAccount.Referred_By__c);
			}

			if (objAccount.Original_Firm__c != null) {
				set_SoldByReferredByIds.add(objAccount.Original_Firm__c);
			}

			//if reseller account is updated and apply to all clients is checked, add to set
			if (
				objAccount.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID &&
				(objAccount.Benefits_Email_Opt_Out__c != map_OldAccounts?.get(objAccount.Id)?.Benefits_Email_Opt_Out__c ||
				objAccount.Benefits_Opt_Out_Details__c != map_OldAccounts?.get(objAccount.Id)?.Benefits_Opt_Out_Details__c ||
				objAccount.Apply_to_all_clients__c != map_OldAccounts?.get(objAccount.Id)?.Apply_to_all_clients__c) &&
				objAccount.Apply_to_all_clients__c
			) {
				set_ParentResellerIds.add(objAccount.Id);
			}

			//create a map of normalized email domain and accounts

			if (
				String.isNotBlank(objAccount.Normalized_Email_Domain__c) &&
				(objAccount.Record_Type__c == AccountUtil.RESELLER_ACCOUNT_TYPE ||
				objAccount.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID)
			) {
				set_NormalizedEmailDomains.add(objAccount.Normalized_Email_Domain__c);
			}

			set_NormalizeAccountIds.add(objAccount.Id);

			if (map_OldAccounts != null && map_OldAccounts.containsKey(objAccount.Id)) {
				set_UserIds.add(map_OldAccounts.get(objAccount.Id).OwnerId);
			}

			if (String.isNotBlank(objAccount.Converted_Lead_Id__c)) {
				set_ConvertedLeadIds.add(objAccount.Converted_Lead_Id__c);
			}

			if (
				map_OldAccounts != null &&
				map_OldAccounts.containsKey(objAccount.Id) &&
				map_OldAccounts.get(objAccount.Id).BillingStateCode != objAccount.BillingStateCode &&
				objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID &&
				String.isNotBlank(objAccount.ZP_Company_ID__c)
			) {
				set_CompanyIdForBillingState.add(objAccount.ZP_Company_ID__c);
			}

			//if subscription preferences have been updated, add to set
			if (
				map_OldAccounts != null &&
				map_OldAccounts.containsKey(objAccount.Id) &&
				map_OldAccounts.get(objAccount.Id) != null &&
				objAccount.Customer_Subscriptions__c != map_OldAccounts.get(objAccount.Id).Customer_Subscriptions__c
			) {
				set_accountSubscriptionsChanged.add(objAccount.Id);
			}
			//if csm owner has been updated, add to set
			if (map_OldAccounts?.get(objAccount.Id) != null && objAccount.CSM_Owner__c != map_OldAccounts.get(objAccount.Id).CSM_Owner__c) {
				set_accountsCSMUpdated.add(objAccount.Id);
			}
		}
	}

	/**** get Order information ****/
	public Order getOrderInformation(Account objOldAccount, Account objAccount) {
		Boolean blnUpdateOrder = false;
		if (objAccount.ZP_Company_Id__c != null) {
			Map<String, ZP_Company_Onboarding_Funnel__c> map_CompanyOnboardingFunnel = AccountUtil.getCompanyOnboardingFunnel(set_CompanyId);
			Map<String, Order> map_Order = AccountUtil.getOrders(set_CompanyId);

			if (map_CompanyOnboardingFunnel.containsKey(objAccount.ZP_Company_Id__c) && map_Order.containsKey(objAccount.ZP_Company_Id__c)) {
				Order objOrder = map_Order.get(objAccount.ZP_Company_Id__c);
				ZP_Company_Onboarding_Funnel__c objOnboardingFunnel = map_CompanyOnboardingFunnel.get(objAccount.ZP_Company_Id__c);

				if (
					objOrder.Status == AccountUtil.ORDER_STATUS_CLO_PAYROLL_RUN ||
					objOrder.Status == AccountUtil.ORDER_STATUS_CLO_CANCELED ||
					(objOnboardingFunnel.ran_payroll_at__c != null &&
					objAccount.ZP_Company_Overall_Status__c == AccountUtil.ACCOUNT_OVERALL_STATUS_SUSPENDED)
				) {
					return null;
				}

				if (objAccount.Payroll_Processing_Status__c != objOldAccount.Payroll_Processing_Status__c || objAccount.ZP_Company_Approval_Status__c != objOldAccount.ZP_Company_Approval_Status__c) {
					if (objOrder.Status != AccountUtil.ORDER_STATUS_PAYROLL_SUBMIT) {
						//If Check list available for order then status will be changed
						if (objOrder.Total_Checklists_Count__c > 0) {
							objOrder.Status = AccountUtil.ORDER_STATUS_ONB_1_6;
							//After finish step 6 then move status 7
							if (checkOnboardingfunnelSteps1to6(objOnboardingFunnel) == true && objOrder.Opportunity.Is_Historical__c && objOnboardingFunnel.Payroll_Schedule_Completed__c) {
								objOrder.Status = AccountUtil.ORDER_STATUS_ONB_7;
							}
							//After completing step 7 move to Step 8
							if (
								objOnboardingFunnel.Payroll_Schedule_Completed__c &&
								((!objOrder.Opportunity.Is_Historical__c && checkOnboardingfunnelSteps1to6(objOnboardingFunnel) == true) ||
								(objOrder.Status == AccountUtil.ORDER_STATUS_ONB_7 && objOnboardingFunnel.Previous_Paystubs_Completed__c))
							) {
								objOrder.Status = AccountUtil.ORDER_STATUS_ONB_8_9;
							}
							//After completing steps 8 to 9 move to steps 10
							if (
								objOrder.Status == AccountUtil.ORDER_STATUS_ONB_8_9 &&
								objOnboardingFunnel.Sign_All_Forms_Completed__c &&
								objOnboardingFunnel.Add_Signatory_Completed__c &&
								objOrder.Opportunity.Is_Historical__c
							) {
								objOrder.Status = AccountUtil.ORDER_STATUS_ONB_10;
							}
							//After completing steps 10 move to Ready for Approval
							if (
								(objOrder.Status == AccountUtil.ORDER_STATUS_ONB_10 && objOnboardingFunnel.Verify_Bank_Info_Completed__c) ||
								(objOrder.Status == AccountUtil.ORDER_STATUS_ONB_8_9 &&
								objOnboardingFunnel.Sign_All_Forms_Completed__c &&
								objOnboardingFunnel.Add_Signatory_Completed__c &&
								!objOrder.Opportunity.Is_Historical__c)
							) {
								objOrder.Status = AccountUtil.ORDER_STATUS_READY_APPROVAL;
							}
							if (objOrder.Status == AccountUtil.ORDER_STATUS_READY_APPROVAL) {
								if (objOrder.Account.ZP_Company_Approval_Status__c == AccountUtil.ZP_COMP_APPROVAL_STATUS_APPROVED) {
									objOrder.Status = AccountUtil.ORDER_STATUS_ACC_APPROVED;
								}

								if (
									objOrder.Account.Payroll_Processing_Status__c == AccountUtil.PAYROLL_PROCC_STATUS_FUNDED ||
									objOrder.Account.Payroll_Processing_Status__c == AccountUtil.PAYROLL_PROCC_STATUS_PAID
								) {
									objOrder.Status = AccountUtil.ORDER_STATUS_CLO_PAYROLL_RUN;
								}

								if (objOrder.Account.Payroll_Processing_Status__c == AccountUtil.PAYROLL_PROCC_STATUS_PROCESSED) {
									objOrder.Status = AccountUtil.ORDER_STATUS_PAYROLL_SUBMIT;
								}
								if (objOrder.Account.ZP_Company_Approval_Status__c == AccountUtil.ZP_COMP_APPROVAL_STATUS_REQ_FOR_INFO) {
									objOrder.Status = AccountUtil.ORDER_STAUS_ASSURANCE_RFI;
								}
							}
						}
						//Check what are all steps has been completed track on associated order level
						objOrder.Onboarding_Steps_Completed__c = RetriveCompletedSteps(objOnboardingFunnel);
					}
					if (objOrder.Status == AccountUtil.ORDER_STATUS_PAYROLL_SUBMIT) {
						if (objOrder.Account.Payroll_Processing_Status__c == AccountUtil.PAYROLL_PROCC_STATUS_PROCESSED) {
							objOrder.Status = AccountUtil.ORDER_STATUS_PAYROLL_SUBMIT;
						}

						if (objOrder.Account.ZP_Company_Approval_Status__c == AccountUtil.ZP_COMP_APPROVAL_STATUS_REQ_FOR_INFO) {
							objOrder.Status = AccountUtil.ORDER_STAUS_ASSURANCE_RFI;
						}
					}
					if (objOrder.Status != AccountUtil.ORDER_STATUS_CLO_PAYROLL_RUN && objOnboardingFunnel.ran_payroll_at__c != null) {
						objOrder.Status = AccountUtil.ORDER_STATUS_CLO_PAYROLL_RUN;
					}
					blnUpdateOrder = true;
				}
				if (objAccount.ACH_Speed__c != objOldAccount.ACH_Speed__c && objAccount.ACH_Speed__c != null && objOrder.First_Check_Date__c != null) {
					//OrderTriggerHelper orderTriggerHelperController = new OrderTriggerHelper();
					objOrder.Payroll_Run_Date__c = AccountUtil.getNextPayrollRunDate(objOrder.First_Check_Date__c, objAccount.ACH_Speed__c);
					blnUpdateOrder = true;
				}
				if (blnUpdateOrder == true) {
					return objOrder;
				}
			}
		}
		return null;
	}

	/**** get a string of concatenated completed steps ****/
	public static String retriveCompletedSteps(ZP_Company_Onboarding_Funnel__c objOnboardingFunnel) {
		string strComplete = '';
		if (objOnboardingFunnel.Create_User_Account_Completed__c) {
			strComplete = 'Create User Account';
		}
		if (objOnboardingFunnel.Add_Addresses_Completed__c) {
			strComplete = strComplete + ',Add Addresses';
		}
		if (objOnboardingFunnel.Add_Employees_Completed__c) {
			strComplete = strComplete + ',Add Employees';
		}
		if (objOnboardingFunnel.Federal_Tax_Setup_Completed__c) {
			strComplete = strComplete + ',Federal Tax Setup';
		}
		if (objOnboardingFunnel.State_Setup_Completed__c) {
			strComplete = strComplete + ',State Setup';
		}
		if (objOnboardingFunnel.Add_Bank_Info_Completed__c) {
			strComplete = strComplete + ',Add Bank Info';
		}
		if (objOnboardingFunnel.Payroll_Schedule_Completed__c) {
			strComplete = strComplete + ',Payroll Schedule';
		}
		if (objOnboardingFunnel.Previous_Paystubs_Completed__c) {
			strComplete = strComplete + ',Previous Paystubs';
		}
		if (objOnboardingFunnel.Add_Signatory_Completed__c) {
			strComplete = strComplete + ',Add Signatory';
		}
		if (objOnboardingFunnel.Sign_All_Forms_Completed__c) {
			strComplete = strComplete + ',Sign All Forms';
		}
		if (objOnboardingFunnel.Verify_Bank_Info_Completed__c) {
			strComplete = strComplete + ',Verify Bank Info ';
		}
		if (objOnboardingFunnel.Historical_Liabilities_Completed__c) {
			strComplete = strComplete + ',Historical Liabilities';
		}
		//Remove comma from first positions
		if (strComplete.indexOf(',') == 0) {
			strComplete = strComplete.replaceFirst(',', '');
		}
		return strComplete;
	}

	/**** check if the funnel step is between 1 and 6 ****/
	public static Boolean checkOnboardingfunnelSteps1to6(ZP_Company_Onboarding_Funnel__c objOnboardingFunnel) {
		boolean isComplete = false;
		if (
			objOnboardingFunnel.Create_User_Account_Completed__c &&
			objOnboardingFunnel.Add_Addresses_Completed__c &&
			objOnboardingFunnel.Add_Employees_Completed__c &&
			objOnboardingFunnel.Federal_Tax_Setup_Completed__c &&
			objOnboardingFunnel.State_Setup_Completed__c &&
			objOnboardingFunnel.Add_Bank_Info_Completed__c
		) {
			isComplete = true;
		}
		return isComplete;
	}

	/**** Query Benefit Orders ****/
	public static map<Id, Benefit_Order__c> queryBenefitOrders(Set<Id> set_OpptyBenefitOrderIds) {
		Map<Id, Benefit_Order__c> map_BenefitOrder = new Map<Id, Benefit_Order__c>();
		try {
			for (Benefit_Order__c objBenefitOrder : [
				SELECT Id, OwnerId, Account__c, Opportunity__c, Order_Status__c, RecordTypeId, Closed__c, RecordType.Name, Coverage_Effective_Date__c, Push_Rate_Reason__c, Status_Detail__c
				FROM Benefit_Order__c
				WHERE Opportunity__c IN :set_OpptyBenefitOrderIds
				ORDER BY CreatedDate DESC
			]) {
				map_BenefitOrder.put(objBenefitOrder.Opportunity__c, objBenefitOrder);
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('AccountTriggerHelper', 'queryBenefitOrders', null, objEx);
		}
		return map_BenefitOrder;
	}
	/**
	 * @description          Collect and update child Opportunities
	 *
	 * @param map_oldAccount Trigger.oldMap
	 * @param map_Account    Trigger.newMap
	 */
	private void updateOpportunityInformation(Map<Id, Account> map_oldAccount, Map<Id, Account> map_Account) {
		List<Opportunity> list_Opportunity = new List<Opportunity>();
		List<Opportunity> list_TotalOpportunity = new List<Opportunity>();
		Map<Id, Integer> map_CountCallActivity = new Map<Id, Integer>();
		Set<String> set_AccountIds = (Set<String>) JSON.deserialize(JSON.serialize(map_Account.keySet()), Set<String>.class);

		try {
			if (map_ActivePriceBook == null || map_ActivePriceBook.isEmpty()) {
				map_ActivePriceBook = PricebookQueryHelper.getActivePricebooksMap();
			}
			list_TotalOpportunity = queryOpportunity(map_Account.keySet());
			if (!set_OpptyBenefitOrderIds.isEmpty()) {
				map_BenefitOrders = queryBenefitOrders(set_OpptyBenefitOrderIds);
			}
			if (!set_UpsellOppIds.isEmpty()) {
				map_CountCallActivity = queryCallActivity();
			}

			for (Opportunity objOpportunity : list_TotalOpportunity) {
				Boolean blnUpdateOpportunity = false;
				Account objAccount = new Account();
				if (map_Account.containsKey(objOpportunity.AccountId)) {
					objAccount = map_Account.get(objOpportunity.AccountId);
				}

				Account objOldAccount = new Account();
				if (map_OldAccount.containsKey(objOpportunity.AccountId)) {
					objOldAccount = map_OldAccount.get(objOpportunity.AccountId);
				}

				if (map_Account.containsKey(objOpportunity.AccountId)) {
					//BSS-65
					if (
						objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID &&
						objOpportunity.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID &&
						String.isNotBlank(objAccount.Offers_Health_Insurance__c) &&
						objAccount.Offers_Health_Insurance__c != objOldAccount.Offers_Health_Insurance__c
					) {
						objOpportunity.Offers_Health_Insurance__c = objAccount.Offers_Health_Insurance__c;
						blnUpdateOpportunity = true;
					}
					if (objOpportunity.IsClosed == false) {
						if (
							String.isNotBlank(objAccount.Benefits_Notes__c) &&
							objAccount.Benefits_Notes__c != objOldAccount.Benefits_Notes__c &&
							(objOpportunity.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID ||
							objOpportunity.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID ||
							objOpportunity.RecordTypeId == OpportunityUtil.BENEFITS_QSEHRA_OPPTY_RT_ID)
						) {
							objOpportunity.Benefits_Notes__c = objAccount.Benefits_Notes__c;
							blnUpdateOpportunity = true;
						}

						if (
							objOpportunity.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID &&
							AccountUtil.PAYROLL_PROCESSING_STATES.contains(objAccount.Payroll_Processing_Status__c) &&
							objOpportunity.Payroll_Processed_Date__c == null &&
							objAccount.Payroll_Processing_Last_Modified__c != null
						) {
							objOpportunity.Payroll_Processed_Date__c = objAccount.Payroll_Processing_Last_Modified__c;
							blnUpdateOpportunity = true;
						}

						if (
							objOpportunity.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID &&
							objOpportunity.Previous_Payroll_Provider__c == null &&
							objAccount.Previous_Payroll_Provider__c != null
						) {
							objOpportunity.Previous_Payroll_Provider__c = objAccount.Previous_Payroll_Provider__c;
							blnUpdateOpportunity = true;
						}

						// sync company opportunity owner with account owner
						if (objOpportunity.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID && objOpportunity.OwnerId != objAccount.OwnerId && UserUtils.isAdminIntgUser(objOpportunity.OwnerId)) {
							objOpportunity.OwnerId = objAccount.OwnerId;
							blnUpdateOpportunity = true;
						}

						if (objOpportunity.Sold_By__c == null && objOpportunity.Referred_By__c == null) {
							Boolean blnOpportunityLeadSournceUpdate = setOpportunityLeadSource(objOpportunity, objAccount);
							if (blnOpportunityLeadSournceUpdate) {
								blnUpdateOpportunity = true;
							}
						}

						if (OpportunityUtil.set_ArdiusRecordTypeIds.contains(objOpportunity.RecordTypeId) && objAccount?.Tier__c != objOldAccount?.Tier__c) {
							Id idExpectedPriceBook = OpportunityUtil.getTierPricebookId(objOpportunity.RecordTypeId, objAccount?.Tier__c, true);

							if (idExpectedPriceBook != objOpportunity.PriceBook2Id) {
								list_OpportunityLineItemsForDelete.addAll(objOpportunity.OpportunityLineItems);
								objOpportunity.PriceBook2Id = idExpectedPriceBook;
								blnUpdateOpportunity = true;
							}
						}
					}

					if (
						objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID &&
						objOpportunity.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID &&
						objAccount.Additional_Services__c != objOpportunity.Additional_Opportunity_Services__c &&
						objOldAccount != null &&
						objAccount.Additional_Services__c != objOldAccount.Additional_Services__c &&
						objOpportunity.Payment_Invoice__c == null
					) {
						// if upsell tier is Employer of Record then append the Employer of Record to additional services
						if (
							internationalPayrollInterestEligible(objAccount) &&
							String.isNotBlank(objOpportunity.Upsell_Tier__c) &&
							objOpportunity.Upsell_Tier__c.containsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD) &&
							(String.isBlank(strInternationalPayrollOnboardingTeam) ||
							(String.isNotBlank(strInternationalPayrollOnboardingTeam) && strInternationalPayrollOnboardingTeam.equalsIgnoreCase('Sales')))
						) {
							if (String.isBlank(objOpportunity.Additional_Opportunity_Services__c)) {
								objOpportunity.Additional_Opportunity_Services__c = AccountUtil.EMPLOYER_OF_RECORD;
								blnUpdateOpportunity = true;
							} else if (!objOpportunity.Additional_Opportunity_Services__c.contains(AccountUtil.EMPLOYER_OF_RECORD)) {
								objOpportunity.Additional_Opportunity_Services__c += ';' + AccountUtil.EMPLOYER_OF_RECORD;
								blnUpdateOpportunity = true;
							}
						} else {
							Set<String> set_AdditionalServices = String.isBlank(objAccount.Additional_Services__c) ? new Set<String>() : new Set<String>(objAccount.Additional_Services__c.split(';'));
							set_AdditionalServices.remove(AccountUtil.EMPLOYER_OF_RECORD);
							set_AdditionalServices.remove(AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT);
							objOpportunity.Additional_Opportunity_Services__c = String.join(new List<String>(set_AdditionalServices), ';');
							blnUpdateOpportunity = true;
						}
					}

					//cross-sell and upsell opp criteria
					if (
						(objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID &&
						objOpportunity.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID &&
						objOpportunity.StageName != OpportunityUtil.CLOSED_LOST_STAGE) && objOpportunity.Payment_Invoice__c == null
					) {
						if (
							(objAccount.Tier__c != objOldAccount.Tier__c ||
							objAccount.Additional_Services__c != objOldAccount.Additional_Services__c ||
							objAccount.Priority_Support__c != objOldAccount.Priority_Support__c ||
							objAccount.Premium_Tier_Discount__c != objOldAccount.Premium_Tier_Discount__c ||
							objAccount.Sold_By__c != objOldAccount.Sold_By__c ||
							objAccount.Reward_Eligible__c != objOldAccount.Reward_Eligible__c)
						) {
							objOpportunity.NumberOfEmployees__c = objAccount.Number_Of_Active_Employees__c;
							objOpportunity.Number_of_Contractors__c = objAccount.Number_of_Active_Contractors__c;
							objOpportunity.International_Employees__c = objAccount.International_Employees__c;
							objOpportunity.International_Contractors__c = objAccount.International_Contractors__c;
							objOpportunity.Sold_By__c = objAccount.Sold_By__c;
							String strPricebook = objOpportunity.Pricebook2?.Name;

							Boolean blnUpgrade = objAccount.Tier__c != objOldAccount.Tier__c || objAccount.Additional_Services__c != objOldAccount.Additional_Services__c;
							Boolean blnClosedWon = false;
							Boolean blnIntlTierUpsellClosedWon = false;

							Set<String> set_RolesToCloseUpselWOConnect = new Set<String>();
							String strCurrentUserRole = map_UsersToCheckCSRole?.get(objOpportunity.OwnerId)?.UserRole?.DeveloperName;
							for (String strRole : System.Label.Eligible_Roles_to_Close_Tier_Upsell_W_O_Connect_activity.split(';')) {
								set_RolesToCloseUpselWOConnect.add(strRole);
							}

							// only in case of an upgrade - close the cross-sell and upsell opportunity
							if (blnUpgrade) {
								// checking if internatinal payroll or normal cross-sell and upsell. connect is required for only non international cross-sell and upsell.
								if (objOpportunity.Upsell_Tier__c != null && objOpportunity.Upsell_Tier__c.containsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)) {
									if (
										objAccount.Additional_Services__c != null &&
										objAccount.Additional_Services__c.containsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD) &&
										(objOldAccount.Additional_Services__c == null || !objOldAccount.Additional_Services__c.containsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD))
									) {
										blnIntlTierUpsellClosedWon = true;
									}
								} else if (objOpportunity.Upsell_Tier__c != AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT) {
									// normal cross-sell and upsell
									String strCurrentTier = setTierValues(objAccount.Tier__c, objAccount.Additional_Services__c);
									String strOldTier = setTierValues(objOldAccount.Tier__c, objOldAccount.Additional_Services__c);
									if (
										AccountUtil.map_TierPriority.containsKey(strOldTier) &&
										AccountUtil.map_TierPriority.containsKey(strCurrentTier) &&
										(AccountUtil.map_TierPriority.get(strOldTier) < AccountUtil.map_TierPriority.get(strCurrentTier))
									) {
										if (
											(map_CountCallActivity.get(objOpportunity.Id) != null && map_CountCallActivity.get(objOpportunity.Id) > 0) ||
											(set_RolesToCloseUpselWOConnect != null && set_RolesToCloseUpselWOConnect.contains(strCurrentUserRole))
										) {
											blnClosedWon = true;
										}

										if (AccountUtil.map_UpsellTierLabelAndAPI.containsKey(strCurrentTier)) {
											objOpportunity.Upsell_Tier__c = AccountUtil.map_UpsellTierLabelAndAPI.get(strCurrentTier);
										} else {
											objOpportunity.Upsell_Tier__c = strCurrentTier;
										}

										objOpportunity.Pricebook2Id = AccountUtil.map_TierPaymentPlan?.containsKey(objAccount.Tier__c?.toLowerCase())
											? map_ActivePriceBook?.get(AccountUtil.map_TierPaymentPlan?.get(objAccount.Tier__c?.toLowerCase()))?.Id
											: null;
										strPricebook = AccountUtil.map_TierPaymentPlan?.containsKey(objAccount.Tier__c?.toLowerCase())
											? map_ActivePriceBook?.get(AccountUtil.map_TierPaymentPlan?.get(objAccount.Tier__c?.toLowerCase()))?.Name
											: null;
									}
								}
							}
							objOpportunity = applySpecialRulesForTierUpsell(objOpportunity, objAccount);
							// Get accountant discount from sold by reseller account
							Decimal decAccountantDiscount = 0;
							Decimal decPremiumTierDiscount = 0;

							if (objAccount.Sold_By__c != null && objAccount.Reward_Eligible__c && map_AllAccountMap.containsKey(objAccount.Sold_By__c)) {
								decAccountantDiscount = map_AllAccountMap.get(objAccount.Sold_By__c).Discount__c;
							}

							// add premium tier discount if account tier is premium
							if (String.isNotBlank(objOpportunity.Upsell_Tier__c) && objOpportunity.Upsell_Tier__c.containsIgnoreCase(AccountUtil.PREMIUM_TIER)) {
								decPremiumTierDiscount = objAccount.Premium_Tier_Discount__c != null ? objAccount.Premium_Tier_Discount__c : 0;
							}

							// if cross-sell and upsell goes closed won and account has Employer of Record interest, update upsell tier, additional services and international employees
							if (
								blnClosedWon &&
								internationalPayrollInterestEligible(objAccount) &&
								(String.isBlank(objOpportunity.Additional_Opportunity_Services__c) || !objOpportunity.Additional_Opportunity_Services__c.contains(AccountUtil.EMPLOYER_OF_RECORD)) &&
								String.isNotBlank(objOpportunity.Upsell_Tier__c) &&
								!objOpportunity.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)
							) {
								// update upsell tier to add Employer of Record
								objOpportunity.Upsell_Tier__c = appendInternationalPayrollToUpsellTier(objOpportunity.Upsell_Tier__c, objOpportunity.Additional_Opportunity_Services__c);
								Decimal decQuantity = objAccount.International_Employees__c != null && objAccount.International_Employees__c > 0 ? objAccount.International_Employees__c : 1;
								objOpportunity.International_Employees__c = decQuantity;

								// no need to add Employer of Record as an additional services for non Employer of Record cross-sell and upsell
								/**if (String.isBlank(objOpportunity.Additional_Opportunity_Services__c)) {
									objOpportunity.Additional_Opportunity_Services__c = AccountUtil.EMPLOYER_OF_RECORD;
								} else if (!objOpportunity.Additional_Opportunity_Services__c.contains(AccountUtil.EMPLOYER_OF_RECORD)) {
									objOpportunity.Additional_Opportunity_Services__c += ';' + AccountUtil.EMPLOYER_OF_RECORD;
								} **/
							}

							Decimal decSalesPrice = 0;

							// if upsell tier is Employer of Record then use upsell tier for the amount calculation or else use Additional_Opportunity_Services__c
							String strAdditionalServicesToCalculateAmount = '';
							if (objOpportunity.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)) {
								strAdditionalServicesToCalculateAmount = AccountUtil.EMPLOYER_OF_RECORD;
							} else {
								strAdditionalServicesToCalculateAmount = objOpportunity.Additional_Opportunity_Services__c;
							}

							decSalesPrice = OpportunityUtil.calculateMRROppNew(
								objOpportunity.NumberOfEmployees__c,
								objOpportunity.Number_of_Contractors__c,
								objOpportunity.International_Employees__c,
								objOpportunity.International_Contractors__c,
								strAdditionalServicesToCalculateAmount,
								decAccountantDiscount,
								decPremiumTierDiscount,
								strPricebook
							);

							objOpportunity.Amount = decSalesPrice - (objOpportunity.MRR__c != null ? objOpportunity.MRR__c : 0);

							if (objOpportunity.Amount > 0 && blnClosedWon) {
								objOpportunity.StageName = OpportunityUtil.CLOSED_WON_STAGE;
								objOpportunity.CloseDate = System.Today();
								set_ClosedWonOpptyIDs.add(objOpportunity.Id);
							}

							//closing the Employer of Record cross-sell and upsell when account's additional services has been changed/added to Employer of Record
							if (objOpportunity.Amount > 0 && blnIntlTierUpsellClosedWon) {
								objOpportunity.StageName = OpportunityUtil.CLOSED_WON_STAGE;
								objOpportunity.CloseDate = System.Today();
								set_ClosedWonOpptyIDs.add(objOpportunity.Id);
							}
							blnUpdateOpportunity = true;
						}
						if (objAccount.Sold_By__c != objOldAccount.Sold_By__c && !objOpportunity.IsClosed) {
							objOpportunity.Sold_By__c = objAccount.Sold_By__c;
							blnUpdateOpportunity = true;
						}
						// sync product experiments from account to cross-sell and upsell opportunity
						if (objAccount.Product_Experiments__c != objOldAccount.Product_Experiments__c && !objOpportunity.IsWon) {
							objOpportunity.Product_Experiments_Opportunity__c = objAccount.Product_Experiments__c;
							blnUpdateOpportunity = true;
						}
					}

					Boolean blnOwnerUpdate = setClosedOwnerDetails(objOpportunity, objOldAccount, objAccount);
					Boolean blnJoindDateUpdate = setOpportunityJoinDateInfo(objOpportunity, objOldAccount, objAccount);
					Boolean blnEmployeeInfoUpdate = setOpportunityEmployeeInfo(objOpportunity, objOldAccount, objAccount);
					Boolean blnPricingInfoUpdates = setOpportunityPricingInfo(objOpportunity, objOldAccount, objAccount);

					if (blnJoindDateUpdate || blnEmployeeInfoUpdate || blnPricingInfoUpdates || blnOwnerUpdate) {
						blnUpdateOpportunity = true;
					}

					// Move ICP opportunity to Closed Won if Additional Services is updated to include International Contractor Payment
					if (
						objOldAccount != null &&
						objAccount.Additional_Services__c != objOldAccount.Additional_Services__c &&
						String.isNotBlank(objAccount.Additional_Services__c) &&
						objAccount.Additional_Services__c.contains(AccountUtil.ADD_SERVICES_INTL_CONTRACTOR_PAID) &&
						objOpportunity.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID &&
						objOpportunity.Upsell_Tier__c == AccountUtil.ADD_SERVICES_INTL_CONTRACTOR_PAID &&
						objOpportunity.StageName != OpportunityUtil.CLOSED_WON_STAGE &&
						objOpportunity.StageName != OpportunityUtil.CLOSED_LOST_STAGE
					) {
						objOpportunity.StageName = OpportunityUtil.CLOSED_WON_STAGE;
						objOpportunity.Additional_Opportunity_Services__c = AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT;
						objOpportunity.CloseDate = System.today();
						blnUpdateOpportunity = true;
						set_ClosedWonOpptyIDs.add(objOpportunity.Id);
					}
				}

				if (blnUpdateOpportunity) {
					list_Opportunity.add(objOpportunity);
				}
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logExceptionWithId('AccountTriggerHelper', 'updateOpportunityInformation', objEx.getMessage(), objEx.getStackTraceString(), set_AccountIds);
		}

		if (list_OpportunityLineItemsForDelete.size() > 0) {
			Database.delete(list_OpportunityLineItemsForDelete, false);
		}

		list_OpportunityLineItemsForDelete = new List<OpportunityLineItem>();

		if (list_Opportunity.size() > 0) {
			Database.update(list_Opportunity, false);
		}
	}
	private String setTierValues(String strTier, String strAdditionalServices) {
		String strReturnTier;
		boolean blnSalesInternationalPayrollOnboardingTeam = false;
		if (String.isNotBlank(strInternationalPayrollOnboardingTeam) && strInternationalPayrollOnboardingTeam.contains('Sales')) {
			blnSalesInternationalPayrollOnboardingTeam = true;
		}
		if (String.isNotBlank(strTier)) {
			strReturnTier = strTier;

			if (String.isNotBlank(strAdditionalServices)) {
				if (strTier.equalsIgnoreCase(AccountUtil.SIMPLE_TIER) && strAdditionalServices.contains(AccountUtil.EMPLOYER_OF_RECORD) && blnSalesInternationalPayrollOnboardingTeam) {
					strReturnTier = AccountUtil.SIMPLE_AND_GUSTO_GLOBAL;
				} else if (strTier.equalsIgnoreCase(AccountUtil.PLUS_TIER)) {
					if (
						strAdditionalServices.contains(AccountUtil.EMPLOYER_OF_RECORD) &&
						strAdditionalServices.containsIgnoreCase(OpportunityUtil.ADD_SERVICES_PRIORITY_SUPPORT) &&
						blnSalesInternationalPayrollOnboardingTeam
					) {
						strReturnTier = AccountUtil.PLUS_PRIORITY_SUPPORT_AND_GUSTO_GLOBAL;
					} else if (strAdditionalServices.contains(AccountUtil.EMPLOYER_OF_RECORD) && blnSalesInternationalPayrollOnboardingTeam) {
						strReturnTier = AccountUtil.PLUS_AND_GUSTO_GLOBAL;
					} else if (strAdditionalServices.containsIgnoreCase(OpportunityUtil.ADD_SERVICES_PRIORITY_SUPPORT)) {
						strReturnTier = AccountUtil.PLUS_PRIORITY_SUPPORT;
					}
				} else if (strTier.equalsIgnoreCase(AccountUtil.CORE_TIER) && strAdditionalServices.contains(AccountUtil.EMPLOYER_OF_RECORD) && blnSalesInternationalPayrollOnboardingTeam) {
					strReturnTier = AccountUtil.CORE_AND_GUSTO_GLOBAL;
				} else if (strTier.equalsIgnoreCase(AccountUtil.COMPLETE_TIER) && strAdditionalServices.contains(AccountUtil.EMPLOYER_OF_RECORD) && blnSalesInternationalPayrollOnboardingTeam) {
					strReturnTier = AccountUtil.COMPLETE_AND_GUSTO_GLOBAL;
				} else if (strTier.equalsIgnoreCase(AccountUtil.CONCEIRGE_TIER) && strAdditionalServices.contains(AccountUtil.EMPLOYER_OF_RECORD) && blnSalesInternationalPayrollOnboardingTeam) {
					strReturnTier = AccountUtil.CONCEIRGE_AND_GUSTO_GLOBAL;
				} else if (strTier.containsIgnoreCase(AccountUtil.PREMIUM_TIER) && strAdditionalServices.contains(AccountUtil.EMPLOYER_OF_RECORD) && blnSalesInternationalPayrollOnboardingTeam) {
					strReturnTier = AccountUtil.PREMIUM_AND_GUSTO_GLOBAL;
				}
			}
		}
		return strReturnTier?.toLowercase();
	}
	/**
	 * @author         Prity Kumari
	 * @description    Set Closed Owner Role values on Opp when AO is updated
	 */
	private Boolean setClosedOwnerDetails(Opportunity objOpportunity, Account objOldAccount, Account objAccount) {
		if (objOldAccount != null && objOldAccount.OwnerId != objAccount.OwnerId && objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
			if (objOpportunity.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID && !objOpportunity.IsClosed && !objOpportunity.False_Sold_By__c) {
				objOpportunity.OwnerId = objAccount.OwnerId;
				User objOwner = map_AllUsers.containsKey(objAccount.OwnerId) ? map_AllUsers.get(objAccount.OwnerId) : null;
				if (objOwner != null) {
					// If Owner has a UserRole
					if (objOwner.UserRoleId != null) {
						objOpportunity.Owner_Role__c = objOwner.UserRole.Name;
						if (objOwner.UserRole.Name.containsIgnoreCase('mdr')) {
							objOpportunity.MDR__c = objOpportunity.OwnerId;
							objOpportunity.MDR_Lead_Owner_Role__c = objOwner.UserRole.Name;
							if (objOpportunity.MDR_Received__c == null) {
								objOpportunity.MDR_Received__c = Datetime.now();
							}
						}
					}
					objOpportunity.Owner_Department__c = objOwner.Department != null ? objOwner.Department : '';
					objOpportunity.Owner_Division__c = objOwner.Division != null ? objOwner.Division : '';
					objOpportunity.Owner_Title__c = objOwner.Title != null ? objOwner.Title : '';
				}
				return true;
			}
		}
		return false;
	}

	/**** set opportunity join date info if pricing changes ****/
	private Boolean setOpportunityJoinDateInfo(Opportunity objOpportunity, Account objOldAccount, Account objAccount) {
		if (objAccount.Joined_Date_Panda__c != null && objOpportunity.StageName != 'Closed Won') {
			if (
				(objOpportunity.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID || objOpportunity.RecordTypeId == OpportunityUtil.EMBEDDED_COMPANY_OPPTY_RT_ID) &&
				String.isNotBlank(objOpportunity.ZP_Company_ID__c)
			) {
				objOpportunity.StageName = 'Closed Won';
				objOpportunity.Joined_Date_Panda__c = objAccount.Joined_Date_Panda__c;
				//objOpportunity.CloseDate = objAccount.Joined_Date_Panda__c;
				return true;
			}
			if (objAccount.Joined_Date_Panda__c != null && objOpportunity.RecordType.Name.contains('Benefit') && objOpportunity.StageName == 'Pending PR') {
				objOpportunity.Closed_Won_Eligible__c = true;
				return true;
			}
		}
		return false;
	}

	/**** set opportunity Employee info if pricing changes ****/
	private Boolean setOpportunityEmployeeInfo(Opportunity objOpportunity, Account objOldAccount, Account objAccount) {
		Decimal decSalesPrice = 0;

		if (
			objAccount.Number_of_Active_Employees__c != objOldAccount.Number_of_Active_Employees__c ||
			objAccount.Number_of_Active_Contractors__c != objOldAccount.Number_of_Active_Contractors__c ||
			objAccount.International_Contractors__c != objOldAccount.International_Contractors__c ||
			objAccount.International_Employees__c != objOldAccount.International_Employees__c ||
			(objAccount.Joined_Date_Panda__c != null &&
			objOldAccount.Joined_Date_Panda__c == null)
		) {
			if (objOpportunity.RecordTypeId != OpportunityUtil.COMPANY_OPPTY_RT_ID && objOpportunity.RecordTypeId != OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID && !objOpportunity.IsClosed) {
				objOpportunity.NumberOfEmployees__c = objAccount.Number_Of_Active_Employees__c;
				objOpportunity.Number_of_Contractors__c = objAccount.Number_of_Active_Contractors__c;
				return true;
			}
			if (
				OpportunityUtil.set_BenefitRTChangeEmployees.contains(objOpportunity.RecordTypeId) &&
				objOpportunity.IsClosed &&
				(((objOpportunity.CloseDate != null && System.today() <= objOpportunity.CloseDate?.addDays(90)) &&
				map_BenefitOrders?.get(objOpportunity.Id)?.Order_Status__c != BenefitOrderUtil.STATUS_FULFILLED))
			) {
				objOpportunity.NumberOfEmployees__c = objAccount.Number_Of_Active_Employees__c;
				objOpportunity.Number_of_Contractors__c = objAccount.Number_of_Active_Contractors__c;
				return true;
			}
			// Set the employee and contract count for company opportunity
			if (
				(objOpportunity.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID ||
				objOpportunity.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID) &&
				objOpportunity.Payment_Invoice__c == null &&
				objOpportunity.StageName != OpportunityUtil.CLOSED_LOST_STAGE &&
				objOpportunity.StageName != OpportunityUtil.CLOSED_ADMIN_STAGE &&
				objOpportunity.StageName != 'Order Lost'
			) {
				if (
					(((objAccount.Number_Of_Active_Employees__c != null && objAccount.Number_Of_Active_Employees__c != 0) &&
					objOpportunity.NumberOfEmployees__c != objAccount.Number_Of_Active_Employees__c) ||
					((objAccount.Number_of_Active_Contractors__c != null && objAccount.Number_of_Active_Contractors__c != 0) &&
					objOpportunity.Number_of_Contractors__c != objAccount.Number_of_Active_Contractors__c) ||
					((objAccount.International_Contractors__c != null && objAccount.International_Contractors__c != 0) &&
					objOpportunity.International_Contractors__c != objAccount.International_Contractors__c) ||
					((objAccount.International_Employees__c != null && objAccount.International_Employees__c != 0) &&
					objOpportunity.International_Employees__c != objAccount.International_Employees__c))
				) {
					objOpportunity.NumberOfEmployees__c = (objAccount.Number_Of_Active_Employees__c != null &&
						objAccount.Number_Of_Active_Employees__c != 0)
						? objAccount.Number_Of_Active_Employees__c
						: 0;
					objOpportunity.Number_of_Contractors__c = objAccount.Number_of_Active_Contractors__c != null ? objAccount.Number_of_Active_Contractors__c : 0;
					objOpportunity.International_Contractors__c = objAccount.International_Contractors__c != null ? objAccount.International_Contractors__c : 0;
					objOpportunity.International_Employees__c = objAccount.International_Employees__c != null ? objAccount.International_Employees__c : 0;

					if (objOpportunity.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID) {
						if (String.isNotBlank(objAccount.Product_Interest__c) && objAccount.Product_Interest__c.containsIgnoreCase(AccountUtil.PROD_INTEREST_INTERNATIONAL_PAYROLL)) {
							objOpportunity.International_Employees__c = objAccount.International_Employees__c != null &&
								objAccount.International_Employees__c > 0
								? objAccount.International_Employees__c
								: 1;
						}
					}

					if (objOpportunity.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID) {
						// Get accountant discount from sold by reseller account
						Decimal decAccountantDiscount = 0;
						Decimal decPremiumTierDiscount = 0;
						if (objAccount.Sold_By__c != null && objAccount.Reward_Eligible__c && map_AllAccountMap.containsKey(objAccount.Id)) {
							decAccountantDiscount = map_AllAccountMap.get(objAccount.Id).Sold_By__r.Discount__c;
						}
						// add premium tier discount if account tier is premium
						if (String.isNotBlank(objOpportunity.Tier__c) && objOpportunity.Tier__c.containsIgnoreCase(AccountUtil.PREMIUM_TIER)) {
							decPremiumTierDiscount = objAccount.Premium_Tier_Discount__c != null ? objAccount.Premium_Tier_Discount__c : 0;
						}

						objOpportunity = applySpecialRulesForTierUpsell(objOpportunity, objAccount);
						// if upsell tier is Employer of Record then use upsell tier for the amount calculation or else use Additional_Opportunity_Services__c
						String strAdditionalServicesToCalculateAmount = '';
						if (objOpportunity.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)) {
							strAdditionalServicesToCalculateAmount = AccountUtil.EMPLOYER_OF_RECORD;
						} else {
							strAdditionalServicesToCalculateAmount = objOpportunity.Additional_Opportunity_Services__c;
						}

						decSalesPrice = OpportunityUtil.calculateMRROppNew(
							objOpportunity.NumberOfEmployees__c,
							objOpportunity.Number_of_Contractors__c,
							objOpportunity.International_Employees__c,
							objOpportunity.International_Contractors__c,
							strAdditionalServicesToCalculateAmount,
							decAccountantDiscount,
							decPremiumTierDiscount,
							objOpportunity.Pricebook2?.Name
						);
						objOpportunity.Amount = decSalesPrice - (objOpportunity.MRR__c != null ? objOpportunity.MRR__c : 0);
					}
					return true;
				} else {
					return false;
				}
			}
			return false;
		}
		return false;
	}

	/**** checks if any states has benefits available ****/
	private Boolean isBenefitsAvailable(String strStates) {
		if (String.isBlank(strStates)) {
			return false;
		}

		for (String strState : strStates.split(';')) {
			if (set_HIStates.contains(strState.trim())) {
				return true;
			}
		}
		return false;
	}

	/**** set opportunity pricing info if pricing changes ****/
	private Boolean setOpportunityPricingInfo(Opportunity objOpportunity, Account objOldAccount, Account objAccount) {
		if (map_ActivePriceBook == null || map_ActivePriceBook.isEmpty()) {
			map_ActivePriceBook = PricebookQueryHelper.getActivePricebooksMap();
		}
		if (
			objAccount.Pricing__c != null &&
			objOpportunity.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID &&
			map_ActivePriceBook.containsKey(objAccount.Pricing__c) &&
			objOpportunity.Payment_Invoice__c == null &&
			objOpportunity.StageName != OpportunityUtil.CLOSED_ADMIN_STAGE
		) {
			if (
				(objAccount.Pricing__c != objOldAccount.Pricing__c || objAccount.Joined_Date_Panda__c != objOldAccount.Joined_Date_Panda__c) &&
				objOpportunity.Pricebook2Id != map_ActivePriceBook.get(objAccount.Pricing__c).Id
			) {
				objOpportunity.Pricebook2Id = map_ActivePriceBook.get(objAccount.Pricing__c).Id;
				if (objOpportunity.OpportunityLineItems != null) {
					for (OpportunityLineItem objOppLineItem : objOpportunity.OpportunityLineItems) {
						list_OpportunityLineItemsForDelete.add(objOppLineItem);
					}
				}
				return true;
			}
		}
		return false;
	}

	/**** Set company opportunity information for update ****/
	private Boolean setOpportunityLeadSource(Opportunity objOpportunity, Account objAccount) {
		//If account lead source is bencch set the opportunity lead source to bench
		if (
			!objOpportunity.IsClosed &&
			objOpportunity.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID &&
			!String.isBlank(objAccount.Lead_Source__c) &&
			objOpportunity.LeadSource != objAccount.Lead_Source__c &&
			objAccount.Lead_Source__c.containsIgnoreCase('bench')
		) {
			objOpportunity.LeadSource = objAccount.Lead_Source__c;
			return true;
		}
		return false;
	}

	/**** Sets default values when creating a new Account ****/
	private void setDefaultsOnCreate(Account objAccount) {
		validateCompanyName(null, objAccount);
		setDefaultRecordType(objAccount);
		assignAccounts(null, objAccount);
		setResellerDefaultInfo(null, objAccount);
		normalizeAccountData(objAccount);
		setWebsiteInfo(objAccount);
		setSalesTaxInfo(objAccount);
		setCompanyFirmInfo(null, objAccount);
		setABTestInfo(objAccount);
		setOverAllCompanyStatus(objAccount);
		setOriginalTier(objAccount);
		setDefaultLeadEmployees(objAccount);
		setCompanyApprovalDate(null, objAccount);
		setBusinessHours(objAccount);
		setPartnerDiscountUpdate(objAccount, null);
		setSalesEngagementStatus(objAccount, null);
		setSalesEngagementDate(objAccount, null);
		setOwnerCalendarLink(objAccount);
		setPotentialFraudHistory(objAccount, null);
		setCompanyFirmId(objAccount);
		if (objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
			setCurrentMRR(objAccount, null);
		}
	}

	private void setCurrentMRR(Account objAccount, Account objOldAccount) {
		Decimal decAccountantDiscount = objAccount.Reward_Eligible__c &&
			objAccount.Sold_By__c != null &&
			map_ResellerAccountIdAccount.containsKey(objAccount.Sold_By__c)
			? map_ResellerAccountIdAccount.get(objAccount.Sold_By__c).Discount__c
			: 0;
		// Apply premium tier discount only when current tier is premium
		Decimal decPremiumTierDiscount = String.isNotBlank(objAccount.Tier__c) && objAccount.Tier__c.containsIgnoreCase(AccountUtil.PREMIUM_TIER) ? objAccount.Premium_Tier_Discount__c : 0;
		String strPricing = String.isNotBlank((objAccount.Tier__c)) && AccountUtil.map_TierPaymentPlan.containsKey(objAccount.Tier__c?.toLowerCase())
			? AccountUtil.map_TierPaymentPlan.get(objAccount.Tier__c.toLowerCase())
			: (objAccount.Pricing__c != null ? objAccount.Pricing__c : null);
		if (
			objOldAccount == null ||
			(objAccount.Number_of_Active_Employees__c != objOldAccount.Number_of_Active_Employees__c ||
			objAccount.Number_of_Active_Contractors__c != objOldAccount.Number_of_Active_Contractors__c ||
			objAccount.International_Employees__c != objOldAccount.International_Employees__c ||
			objAccount.International_Contractors__c != objOldAccount.International_Contractors__c ||
			objAccount.Additional_Services__c != objOldAccount.Additional_Services__c ||
			objAccount.Sold_By__c != objOldAccount.Sold_By__c ||
			objAccount.Tier__c != objOldAccount.Tier__c ||
			objAccount.Pricing__c != objOldAccount.Pricing__c ||
			objAccount.Reward_Eligible__c != objOldAccount.Reward_Eligible__c ||
			objAccount.Upsell_Opp_Open__c != objOldAccount.Upsell_Opp_Open__c ||
			objAccount.Premium_Tier_Discount__c != objOldAccount.Premium_Tier_Discount__c)
		) {
			objAccount.Current_MRR__c = OpportunityUtil.calculateMRROppNew(
				objAccount.Number_of_Active_Employees__c,
				objAccount.Number_of_Active_Contractors__c,
				objAccount.International_Employees__c,
				objAccount.International_Contractors__c,
				objAccount.Additional_Services__c,
				decAccountantDiscount,
				decPremiumTierDiscount,
				strPricing
			);
		}
	}

	/**
	 * @description Set Tracker to Recalculate the Firm MRR value
	 * Set the Tracker when The Firm is Not suspended and its Current MRR Changes
	 * Or The Firm is just got suspended.
	 * @author Ajay Krishna P U
	 */
	private void setFirmMRRRecalculationTracker(Account objAccount, Account objOldAccount) {
		if (
			(objAccount.ZP_Company_Suspension_Date__c == null && objAccount.Current_MRR__c != objOldAccount.Current_MRR__c) ||
			(objAccount.ZP_Company_Suspension_Date__c != null &&
			objOldAccount.ZP_Company_Suspension_Date__c == null)
		) {
			objAccount.Recalculate_Metrics_Tracker__c = Utils.addToMultiPicklistValue(objAccount.Recalculate_Metrics_Tracker__c, AccountUtil.TRACKER_FIRM_MRR);
		}
	}

	/**** assign account ownership ****/
	private void assignAccounts(Account objOldAccount, Account objAccount) {
		String strHIOwnerRole = '';
		String strHIOwnerName = '';
		String strOwnerName = '';

		if (objAccount.HI_Owner__c != null && map_Users.containsKey(objAccount.HI_Owner__c)) {
			strHIOwnerRole = map_Users.get(objAccount.HI_Owner__c).UserRole.Name;
			strHIOwnerName = map_Users.get(objAccount.HI_Owner__c).Name;
		}

		if (objAccount.OwnerId != null && map_Users.containsKey(objAccount.OwnerId)) {
			strOwnerName = map_Users.get(objAccount.OwnerId).Name;
		}

		String strBenefitsOptOut = (objAccount.Benefits_Email_Opt_Out__c == null ? '' : objAccount.Benefits_Email_Opt_Out__c);
	}

	/**
	 * @author         Praveen Sethu
	 * @description    Sets website info from Normalized Email Domain
	 * @param          objAccount Account record from Trigger.new
	 */
	private void setWebsiteInfo(Account objAccount) {
		if ((String.isBlank(objAccount.Website) || objAccount.Website.contains(AccountUtil.ACCOUNT_OBJ_PREFIX)) && String.isNotBlank(objAccount.Normalized_Email_Domain__c)) {
			objAccount.Website = 'www.' + objAccount.Normalized_Email_Domain__c;
		}
	}

	/**
	 * @description Sets Lead Employees from Standard Number of Employees field on create
	 * @param  objAccount Current Account
	 */
	private void setDefaultLeadEmployees(Account objAccount) {
		if (objAccount.NumberOfEmployees != null && objAccount.NumberOfEmployees_Lead__c == null) {
			objAccount.NumberOfEmployees_Lead__c = objAccount.NumberOfEmployees;
		}
	}

	/**** Sets default values when creating a new Account ****/
	private void setDefaultsOnUpdate(Account objOldAccount, Account objAccount) {
		map_ActivePriceBook = PricebookQueryHelper.getActivePricebooksMap();
		if (objAccount.OwnerId != objOldAccount.OwnerId) {
			objAccount.Account_Owner_Assignment_Date__c = System.today();

			setAccountOldOwner(objAccount, objOldAccount);
		}

		if (objAccount.Joined_Date_Panda__c == null && objAccount.Last_Login_Time__c != objOldAccount.Last_Login_Time__c) {
			if (objAccount.of_Logins__c == null) {
				objAccount.of_Logins__c = 1;
			} else {
				objAccount.of_Logins__c += 1;
			}
		}

		if (String.isNotBlank(objAccount.Pricing__c) && objAccount.Pricing__c != objOldAccount.Pricing__c && map_ActivePriceBook.containsKey(objAccount.Pricing__c)) {
			objAccount.Pricebook2__c = map_ActivePriceBook.get(objAccount.Pricing__c).Id;
		}

		if (objAccount.Tier__c != objOldAccount.Tier__c) {
			objAccount.Previous_Tier__c = objOldAccount.Tier__c;
			objAccount.Previous_Tier_Start_Date__c = objOldAccount.Previous_Tier_Start_Date__c;
			objAccount.Tier_Update_Status__c = 'Not Processed';
		}

		if (objAccount.Salesloft_Id_URL__c == null || objAccount.Salesloft_Id_URL__c == '') {
			objAccount.Salesloft_Id_URL__c = 'www.' + objAccount.Account_ID_18_Digit__c + '.com';
		}

		if (objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID && (objAccount.Concierge_Group_Id__c == null || objAccount.Concierge_Group_Id__c != objOldAccount.Concierge_Group_Id__c)) {
			objAccount.Tier_Update_Status__c = 'Not Processed';
		}

		if (
			objOldAccount.ZP_Company_Overall_Status__c != objAccount.ZP_Company_Overall_Status__c &&
			objAccount.ZP_Company_Overall_Status__c != '' &&
			objAccount.ZP_Company_Overall_Status__c != null &&
			objAccount.ZP_Company_Overall_Status__c == AccountUtil.ACCOUNT_OVERALL_STATUS_SUSPENDED &&
			objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID &&
			(objAccount.Sold_By__c != null ||
			objAccount.Referred_By__c != null)
		) {
			objAccount.Send_Company_Suspension_to_Partner__c = true;
		}

		// update Additional Services on Account if Product Interest is updated with International Contractor Payment Paid
		if (
			objOldAccount != null &&
			objAccount.Product_Interest__c != objOldAccount.Product_Interest__c &&
			String.isNotBlank(objAccount.Product_Interest__c) &&
			objAccount.Product_Interest__c.containsIgnoreCase(AccountUtil.PROD_INTEREST_INTL_CONT_PAID)
		) {
			List<String> list_AdditionalServices = String.isNotBlank(objAccount.Additional_Services__c) ? objAccount.Additional_Services__c.split(';') : new List<String>();
			if (!list_AdditionalServices.contains(AccountUtil.ADD_SERVICES_INTL_CONTRACTOR_PAID)) {
				list_AdditionalServices.add(AccountUtil.ADD_SERVICES_INTL_CONTRACTOR_PAID);
				objAccount.Additional_Services__c = String.join(list_AdditionalServices, ';');
			}
		}

		validateCompanyName(objOldAccount, objAccount);
		assignAccounts(objOldAccount, objAccount);
		setOriginalTier(objAccount);
		setOverAllCompanyStatus(objAccount);
		setSalesTaxInfo(objAccount);
		normalizeAccountData(objAccount);
		setWebsiteInfo(objAccount);
		clearHiDeductionsInfo(objOldAccount, objAccount);
		setResellerDefaultInfo(objOldAccount, objAccount);
		setCompanyFirmInfo(objOldAccount, objAccount);
		setCompanyApprovalDate(objOldAccount, objAccount);
		setHeldOutOfAccountComms(objOldAccount, objAccount);
		setPartnerDiscountUpdate(objAccount, objOldAccount);
		updateBenefitOptOutSync(objOldAccount, objAccount);
		setSalesEngagementStatus(objAccount, objOldAccount);
		setSalesEngagementDate(objAccount, objOldAccount);
		setOwnerCalendarLink(objAccount);
		setPotentialFraudHistory(objAccount, objOldAccount);
		setCompanyFirmId(objAccount);
		setStandardFieldsFrom3rdParty(objAccount);
		if (objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
			setCurrentMRR(objAccount, objOldAccount);
		}
		setFirmMRRRecalculationTracker(objAccount, objOldAccount);
	}

	/*** Set Held Out of Account Communications ***/
	public void setHeldOutOfAccountComms(Account objOldAccount, Account objAccount) {
		if (objOldAccount.Cohort_Date__c == null && objAccount.Cohort_Date__c != null && objAccount.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID) {
			objAccount.Cohort_Update_Date_Time__c = System.now();
			objAccount.First_Payroll_Run__c = true;

			map_ResellerCohortAccts.put(objAccount.Id, objAccount);

			if (map_ResellerCohortAccts.size() > intNumberOfResellerAccountHoldOut) {
				// Remove first element from array
				for (Id idAccount : map_ResellerCohortAccts.keyset()) {
					map_ResellerCohortAccts.remove(idAccount);
					break;
				}
			}
		}
	}

	/*** Set Sales Engagement Status based on different scenarios ****/
	public void setSalesEngagementStatus(Account objAccount, Account objOldAccount) {
		Boolean blnSalesEdit = false;
		String strCurrentUserRole = map_Users?.get(UserInfo.getUserId())?.UserRole?.Name;
		blnSalesEdit = String.isNotBlank(strCurrentUserRole) ? strCurrentUserRole.containsIgnoreCase(AccountUtil.SALES_ROLE) : false;
		if (objAccount.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID && !blnSalesEdit && objAccount.Reseller_Type__c != AccountUtil.RESELLER_TYPE_STRATEGIC_ACCOUNT) {
			if (objOldAccount != null) {
				// update
				if (objAccount.Sales_Engagement_Status__c != AccountUtil.SALES_ENGMNT_STATUS_ACTIVE && objOldAccount.Cohort_Date__c == null && objAccount.Cohort_Date__c != null) {
					// Reseller acconut has first client that runs payroll and calculate reseller metrics
					objAccount.Calculate_Reseller_Metrics__c = true;
					objAccount.Sales_Engagement_Status__c = AccountUtil.SALES_ENGMNT_STATUS_ACTIVE;
				}
			} else {
				// Insert - Set Default Sales Engagement Status When value is blank
				if (String.isBlank(objAccount.Sales_Engagement_Status__c)) {
					objAccount.Sales_Engagement_Status__c = AccountUtil.SALES_ENGMNT_STATUS_PROSPECTIVE;
				}
			}
		}
	}

	/*** Set Sales Engagement Date whenever Sales Engagement Status Changes ****/
	public void setSalesEngagementDate(Account objAccount, Account objOldAccount) {
		if (objOldAccount == null && objAccount.Sales_Engagement_Status__c != null || (objOldAccount != null && objAccount.Sales_Engagement_Status__c != objOldAccount.Sales_Engagement_Status__c)) {
			objAccount.Sales_Engagement_Date__c = Date.today();
		}
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Sets Old Account Owner
	 * @param        objAccount New Account
	 * @param        objOldAccount Old Account
	 **/
	public void setAccountOldOwner(Account objAccount, Account objOldAccount) {
		String strAccountOldOwnerRoleName = map_Users.get(objOldAccount.OwnerId)?.UserRole?.Name;
		String strAccountOwnerRoleName = map_Users.get(objAccount.OwnerId)?.UserRole?.Name;

		if (
			String.isNotBlank(strAccountOldOwnerRoleName) &&
			strAccountOldOwnerRoleName.equalsIgnoreCase(AccountUtil.SALES_PARTNER_AE_ROLE) &&
			String.isNotBlank(strAccountOwnerRoleName) &&
			(strAccountOwnerRoleName.equalsIgnoreCase(AccountUtil.SALES_PARTNER_AE_ROLE) ||
			strAccountOwnerRoleName.equalsIgnoreCase(AccountUtil.SALES_PARTNER_AM_ROLE) ||
			strAccountOwnerRoleName.equalsIgnoreCase(AccountUtil.SALES_PARTNER_SAM_ROLE) ||
			strAccountOwnerRoleName.equalsIgnoreCase(AccountUtil.SALES_PARTNER_MANAGER_ROLE))
		) {
			objAccount.Old_Owner__c = objOldAccount.OwnerId;
		}
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Sets Owner Calendar Link
	 * @param        objAccount New Account
	 **/
	public void setOwnerCalendarLink(Account objAccount) {
		String strOwnerCalendarLink = map_Users.get(objAccount.OwnerId)?.Calendar_Link__c;
		objAccount.Account_Owner_Calendar_Link__c = strOwnerCalendarLink;
	}

	/**** Sets company approval date with status is approved ****/
	private void setCompanyApprovalDate(Account objOldAccount, Account objAccount) {
		if (
			(objOldAccount == null || (objOldAccount.ZP_Company_Approval_Status__c != objAccount.ZP_Company_Approval_Status__c)) &&
			objAccount.ZP_Company_Approval_Status__c == AccountUtil.ZP_COMP_APPROVAL_STATUS_APPROVED &&
			objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID
		) {
			objAccount.Date_of_Approved__c = System.today();
		}

		if (
			(objOldAccount == null || (objOldAccount.ZP_Company_Approval_Status__c != objAccount.ZP_Company_Approval_Status__c)) &&
			objAccount.ZP_Company_Approval_Status__c == AccountUtil.ZP_COMP_APPROVAL_STATUS_REQ_FOR_INFO &&
			objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID
		) {
			objAccount.Date_of_RFI__c = System.today();
		}
	}

	/**** set overall company status ****/
	private void setOverAllCompanyStatus(Account objAccount) {
		if (
			objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID &&
			objAccount.ZP_Company_Overall_Status__c != AccountUtil.ACCOUNT_OVERALL_STATUS_SUSPENDED &&
			objAccount.Joined_Date_Panda__c != null &&
			String.isNotBlank(objAccount.ZP_Company_ID__c)
		) {
			objAccount.ZP_Company_Overall_Status__c = AccountUtil.ACCOUNT_OVERALL_STATUS_ACTIVE;
		}
	}

	/**** set original tier ****/
	private void setOriginalTier(Account objAccount) {
		if (String.isBlank(objAccount.Original_Tier__c) && String.isNotBlank(objAccount.Tier__c)) {
			objAccount.Original_Tier__c = objAccount.Tier__c;
		}
	}

	/**
	 * Normalize phone & email
	 */
	private void normalizeAccountData(Account objAccount) {
		NormalizationUtil normalizeController = new NormalizationUtil();
		objAccount.Normalized_Phone__c = normalizeController.normalisePhoneField(objAccount.Phone);
		setNormalizedEmail(objAccount);
	}

	/**
	 * @author       Praveen Sethu
	 * @description  Retrieves earliest created contact with normalized email address and updates Account
	 * @param        objAccount Trigger new
	 **/
	private void setNormalizedEmail(Account objAccount) {
		if (map_AllAccountMap.containsKey(objAccount.Id)) {
			objAccount.Normalized_Email_Domain__c = '';
			// Get earliest created contact with normalized email address
			for (Contact objContact : map_AllAccountMap.get(objAccount.Id).Contacts) {
				if (String.isNotBlank(objContact.Normalized_Email_Domain__c)) {
					objAccount.Normalized_Email_Domain__c = objContact.Normalized_Email_Domain__c;
					break;
				}
			}
		}
	}

	/**** Clear HI Deductions Info ****/
	private void clearHiDeductionsInfo(Account objOldAccount, Account objAccount) {
		if (objAccount.ZP_Company_ID__c != null && objAccount.ZP_Company_ID__c != objOldAccount.ZP_Company_ID__c && objOldAccount.ZP_Company_ID__c != null) {
			Map<String, ZP_HI_Deduction__c> map_CompanyIdZPHIDeductions = AccountUtil.getCompanyHIDeductions(set_companyId);
			if (!map_CompanyIdZPHIDeductions.containsKey(objAccount.ZP_Company_ID__c)) {
				objAccount.No_of_EE_with_Active_Benefits__c = 0;
				objAccount.Medical_Deduction_Descriptions__c = '';
				objAccount.Medical_Deduction_Types__c = '';
				objAccount.Medical_Deductions__c = false;
			}
		}
	}

	/**** Set Record Type default ****/
	private void setResellerDefaultInfo(Account objOldAccount, Account objAccount) {
		if (objAccount.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID) {
			if (objOldAccount == null || objAccount.Cohort_Date__c != objOldAccount.Cohort_Date__c) {
				if (objAccount.Cohort_Date__c != null) {
					objAccount.Account_Hand_off_Date__c = objAccount.Cohort_Date__c.adddays(AccountUtil.DEFAULT_COHORT_DAYS);
				} else {
					objAccount.Account_Hand_off_Date__c = null;
				}
			}
			//During creation set default to potential Partner
			if (objAccount.Id == null) {
				objAccount.Partner_Status__c = AccountUtil.PARTNER_STATUS_POTENTIAL_PARTNER;
			} else if (objAccount.Partner_Status__c == AccountUtil.PARTNER_STATUS_POTENTIAL_PARTNER && objAccount.Cohort_Date__c != null) {
				objAccount.Partner_Status__c = AccountUtil.PARTNER_STATUS_ACTIVE_PARTNER;
			}

			if (objAccount.Sales_Engagement_Status_Detail__c != null && (objOldAccount == null || objAccount.Sales_Engagement_Status_Detail__c != objOldAccount.Sales_Engagement_Status_Detail__c)) {
				objAccount.Last_Sales_Engagement_Status_Detail_Date__c = Date.today();
			}

			if (
				objOldAccount != null &&
				(objAccount.Customers_Reward_Eligible__c != objOldAccount.Customers_Reward_Eligible__c &&
				objAccount.Customers_Reward_Eligible__c != null &&
				objAccount.recordtypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID)
			) {
				if (objAccount.Customers_Reward_Eligible__c > objOldAccount.Customers_Reward_Eligible__c) {
					objAccount.Customers_Rewards_Gain_Loss__c = 'Increase';
				} else if (objAccount.Customers_Reward_Eligible__c < objOldAccount.Customers_Reward_Eligible__c) {
					objAccount.Customers_Rewards_Gain_Loss__c = 'Decrease';
				}
			}

			if (objOldAccount == null || objAccount.AM_Tier__c != objOldAccount.AM_Tier__c) {
				objAccount.Discount__c = (String.isNotBlank(objAccount.AM_Tier__c) && AccountUtil.map_PartnerTier.containsKey(objAccount.AM_Tier__c))
					? AccountUtil.map_PartnerTier.get(objAccount.AM_Tier__c)
					: 0;
			}
		}
	}

	/**** Set Company Firm Information ****/
	private void setCompanyFirmInfo(Account objOldAccount, Account objAccount) {
		if (
			(objOldAccount == null && (objAccount.Sold_By__c != null || objAccount.Referred_By__c != null)) ||
			(objOldAccount != null &&
			((objAccount.Sold_By__c != null && objOldAccount.Sold_By__c != objAccount.Sold_By__c) || (objAccount.Referred_By__c != null && objOldAccount.Referred_By__c != objAccount.Referred_By__c)))
		) {
			Account objParentAccount = new Account();
			if (map_ResellerAccountIdAccount.containsKey(objAccount.Sold_By__c)) {
				objParentAccount = map_ResellerAccountIdAccount.get(objAccount.Sold_By__c);
			}

			if (map_ResellerAccountIdAccount.containsKey(objAccount.Referred_By__c)) {
				objParentAccount = map_ResellerAccountIdAccount.get(objAccount.Referred_By__c);
			}

			if (objParentAccount.Benefits_Email_Opt_Out__c != null && objParentAccount.Apply_to_all_clients__c) {
				objAccount.Benefits_Opt_Out_Details__c = objParentAccount.Benefits_Opt_Out_Details__c;
				objAccount.Benefits_Email_Opt_Out__c = objParentAccount.Benefits_Email_Opt_Out__c;
			}
		}
	}

	/**
	 * @author      : David (Dato) Tsamalashvili
	 * @description : Change account name if it is email - PII security
	 * @param       : objOldAccount - old account info
	 * @param       : objAccount - new account info
	 * @return      : N/A
	 **/
	private void validateCompanyName(Account objOldAccount, Account objAccount) {
		if (Pattern.matches(AccountUtil.EMAIL_PATTERN, objAccount.Name)) {
			String strName = objAccount.Name.substringBefore('@') + ' - Payroll';
			objAccount.Name = strName;
		}
	}

	/**** Set Record Type default ****/
	private void setDefaultRecordType(Account objAccount) {
		//In leads record type value is set as Company or Reseller which is used to set the record type
		if (String.isNotBlank(objAccount.Record_Type__c)) {
			if (objAccount.Record_Type__c == AccountUtil.RESELLER_ACCOUNT_TYPE) {
				objAccount.RecordTypeId = AccountUtil.RESELLER_ACCOUNT_RT_ID;
			}
			if (objAccount.Record_Type__c == AccountUtil.COMPANY_ACCOUNT_TYPE) {
				objAccount.RecordTypeId = AccountUtil.COMPANY_ACCOUNT_RT_ID;
			}
			if (objAccount.Record_Type__c == AccountUtil.EMBEDDED_COMPANY_TYPE) {
				objAccount.RecordTypeId = AccountUtil.EMBEDDED_COMPANY_ACCOUNT_RT_ID;
			}
		}

		if (objAccount.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID && String.isBlank(objAccount.Record_Type__c)) {
			objAccount.Record_Type__c = AccountUtil.RESELLER_ACCOUNT_TYPE;
		}
		if (objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID && String.isBlank(objAccount.Record_Type__c)) {
			objAccount.Record_Type__c = AccountUtil.COMPANY_ACCOUNT_TYPE;
		}
		if (objAccount.RecordTypeId == AccountUtil.EMBEDDED_COMPANY_ACCOUNT_RT_ID && String.isBlank(objAccount.Record_Type__c)) {
			objAccount.Record_Type__c = AccountUtil.EMBEDDED_COMPANY_TYPE;
		}
	}

	/**** Set Sales Tax Info ****/
	private void setSalesTaxInfo(Account objAccount) {
		if ((objAccount.States__c == null || objAccount.States__c == '') && objAccount.BillingState != null && objAccount.BillingState != '') {
			objAccount.States__c = Utils.getStateCode(objAccount.BillingState);
		}

		objAccount.Sales_Tax_Applicable__c = false;
		if (objAccount.States__c != null && objAccount.States__c != '') {
			String[] stateArr = objAccount.States__c.split(';');
			for (String state : stateArr) {
				String tax = utils.getTaxPct(state.trim(), '', '');
				if (String.isNotBlank(tax)) {
					objAccount.Sales_Tax_Applicable__c = true;
					break;
				}
			}
		}
	}

	/**** Set AB Test Group and Name ****/
	private void setABTestInfo(Account objAccount) {
		if (objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID && (objAccount.Number_of_Active_Employees__c == null || objAccount.Number_of_Active_Employees__c < 10)) {
			if ((String.isBlank(objAccount.Lead_Source__c) || !objAccount.Lead_Source__c.equalsIgnoreCase('partner referral')) && objAccount.Sold_By__c == null && objAccount.Referred_By__c == null) {
				String str_lstChar = '';
				Integer int_string = 0;

				if (String.isNotBlank(objAccount.ZP_Company_ID__c)) {
					str_lstChar = objAccount.ZP_Company_ID__c.substring(objAccount.ZP_Company_ID__c.length() - 1);
					int_string = Integer.valueOf(str_lstChar);
				}

				if (int_string >= 0 && int_string <= 4 && String.isNotBlank(str_lstChar)) {
					objAccount.A_B_Test_Group__c = 'Control';
				} else if (int_string >= 5 && int_string <= 9 && String.isNotBlank(str_lstChar)) {
					objAccount.A_B_Test_Group__c = 'Test';
				} else {
					objAccount.A_B_Test_Group__c = 'Test';
				}
				objAccount.A_B_Test_Name__c = 'Simple Tier 9-';
			}
		}
	}

	/**** Set Business Hours ****/
	private void setBusinessHours(Account objAccount) {
		if (objBusinessHour != null) {
			objAccount.WithinBusinessHours__c = BusinessHours.isWithin(objBusinessHour.Id, System.now());
		}
	}

	/*** Set Run In Batch flag to be true when discount or ownership changes ***/
	public void setPartnerDiscountUpdate(Account objAccount, Account objOldAccount) {
		if (objAccount.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID && (objOldAccount == null || objAccount.OwnerId != objOldAccount.OwnerId) && objAccount.OwnerId != null) {
			objAccount.Run_Batch__c = true;
		}
	}

	/**** Set EntitlementInformation for Company account ****/
	private Entitlement getEntitlementInfo(Account objAccount) {
		Entitlement objEntitlement = new Entitlement();
		if (objAccount.RecordTypeId != AccountUtil.COMPANY_ACCOUNT_RT_ID) {
			return null;
		}

		if (String.isNotBlank(objConfigSettings?.AccountEntitlementId__c)) {
			objEntitlement.AccountId = objAccount.Id;
			objEntitlement.Name = 'MF Submission-' + objAccount.Name.left(49);
			objEntitlement.SlaProcessId = objConfigSettings.AccountEntitlementId__c;
			objEntitlement.StartDate = System.today();
			objEntitlement.EndDate = Date.newInstance(2099, 1, 1);
			objEntitlement.Type = 'MF Submission';
		}
		return objEntitlement;
	}

	/**** get Tax Audit Case information ****/
	private Case getTaxAuditCaseInformation(String strRequestType, Account objOldAccount, Account objAccount) {
		if (objAccount.Taxable_as_Scorp__c != objOldAccount.Taxable_as_Scorp__c && objAccount.Has_Benefits__c) {
			Database.DMLOptions dmo = new Database.DMLOptions();
			dmo.assignmentRuleHeader.useDefaultRule = true;
			Case objCase = new Case();
			objCase.setOptions(dmo);
			objCase.AccountId = objAccount.Id;
			if (strRequestType == 'taxPayerAudit') {
				objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits Care');
				objCase.Type = 'Company Taxability Audit';
			}
			objCase.Routing_Case_Reason__c = 'Internal Request';
			objCase.Confirm_Case_Reason__c = 'Internal Request';
			objCase.Answer_IQ_Processed__c = 'Yes';
			objCase.Subject =
				'[ER ' +
				objAccount.ZP_Company_ID__c +
				']: taxable_as_scorp has been updated from *' +
				objOldAccount.Taxable_As_SCorp__c +
				'* to *' +
				objAccount.Taxable_As_SCorp__c +
				'*';
			return objCase;
		}
		return null;
	}

	/**** do account routing ****/
	public void doAccountRouting(Account objAccount, Account objOldAccount) {
		System.debug('doAccountRouting1:');
		Set<String> set_RoleCreatedByUser = new Set<String>{
			'sales_mm_pr_xx',
			'sales_partner_ae_xx',
			'sales_partner_am_xx',
			'sales_partner_sam_xx',
			'sales_sdr_partner_xx',
			'sales_sdr_partner_mgr_xx',
			'sales_sdr_mm_xx',
			'sales_bdr_xx_xx',
			'sales_sdr_mm_mgr_xx'
		};
		String strUserInfoRole = map_Users?.get(UserInfo.getUserId())?.UserRole?.Name;
		System.debug('strUserInfoRole:' + strUserInfoRole);
		if (objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID || objAccount.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID) {
			System.debug('objOldAccount111:' + objOldAccount);
			if (objOldAccount == null) {
				// account insert

				if (String.isBlank(objAccount.Converted_Lead_Id__c) && (String.isNotBlank(strUserInfoRole) && !set_RoleCreatedByUser.contains(strUserInfoRole))) {
					// upon creation if account does not have converted lead & account has sold by or referred by or parent id, send account to routing
					if (
						objAccount.Original_Firm__c != null ||
						objAccount.Sold_By__c != null ||
						(objAccount.Referred_By__c != null &&
						objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) ||
						objAccount.ParentId != null
					) {
						objAccount.Account_Route_Count__c = (objAccount.Account_Route_Count__c == null || objAccount.Account_Route_Count__c == 0) ? 1 : objAccount.Account_Route_Count__c + 1;
						objAccount.UniqueEntry__RingLead_App_Field__c = PENDING_ROUTING;
						return;
					}
				} else if (String.isNotBlank(objAccount.Converted_Lead_Id__c) && map_ConvertedLeads.containsKey(objAccount.Converted_Lead_Id__c)) {
					// check if account is created via lead conversion and get converted lead
					Lead objLead = map_ConvertedLeads.get(objAccount.Converted_Lead_Id__c);

					// account created through lead conversion does not have routing owner id & account has parent account - send it for routing
					if (String.isBlank(objLead.Routing_Owner_Id__c) && objAccount.ParentId != null) {
						objAccount.Account_Route_Count__c = (objAccount.Account_Route_Count__c == null || objAccount.Account_Route_Count__c == 0) ? 1 : objAccount.Account_Route_Count__c + 1;
						objAccount.UniqueEntry__RingLead_App_Field__c = PENDING_ROUTING;
						return;
					}

					if (
						objLead.OwnerId != null &&
						!AccountUtil.set_PartnerRoles.contains(objLead?.Owner.UserRole?.Name) &&
						(objAccount.Original_Firm__c != null ||
						objAccount.Referred_By__c != null ||
						objAccount.Sold_By__c != null) &&
						objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID
					) {
						objAccount.Account_Route_Count__c = (objAccount.Account_Route_Count__c == null || objAccount.Account_Route_Count__c == 0) ? 1 : objAccount.Account_Route_Count__c + 1;
						objAccount.UniqueEntry__RingLead_App_Field__c = PENDING_ROUTING;
						return;
					}

					// check if lead owner is not admin or integration user. If not, set set owner as lead owner
					if (!UserUtils.isAdminIntgUser(objLead.OwnerId)) {
						objAccount.OwnerId = objLead.OwnerId;
						return;
					} else if (objLead.Lead_Route_Count__c > 0 && String.isBlank(objLead.UniqueEntry__RingLead_App_Field__c)) {
						// lead has been sent to ringlead for routing. account owner will be updated when lead is routed
						return;
					}
				}
				// send account to ringlead for routing if account is owned by admin or integration user
				if (UserUtils.isAdminIntgUser(objAccount.OwnerId) || UserUtils.isIntgUser(objAccount.OwnerId)) {
					objAccount.Account_Route_Count__c = (objAccount.Account_Route_Count__c == null || objAccount.Account_Route_Count__c == 0) ? 1 : objAccount.Account_Route_Count__c + 1;
					objAccount.UniqueEntry__RingLead_App_Field__c = PENDING_ROUTING;
				}
			} else {
				Boolean blnRouting = false;
				Boolean blnAccountRouting = false;
				Integer intSDRPercentage = Integer.valueOf(System.Label.SDR_to_MMPR_Percent);
				String strCreatedByRole = map_Users.get(objAccount.CreatedById)?.UserRole?.Name;
				// if owner changes from rep from admin user, revert the change
				if (
					!Test.isRunningTest() &&
					objAccount.OwnerId != objOldAccount.OwnerId &&
					AccountUtil.INTEGRATION_USERS.contains(objAccount.OwnerId) &&
					!AccountUtil.INTEGRATION_USERS.contains(objOldAccount.OwnerId)
				) {
					objAccount.OwnerId = objOldAccount.OwnerId;
				}

				String strOwnerRole = map_Users?.get(objAccount.OwnerId)?.UserRole?.Name;

				// if sold by changes and opportunity is false sold by, do not send it for routing
				if (objAccount.Sold_By__c != objOldAccount.Sold_By__c && map_AllAccountMap.containsKey(objAccount.Id)) {
					Account objAcc = map_AllAccountMap.get(objAccount.Id);

					for (Opportunity objOppty : objAcc.Opportunities) {
						System.debug('objOppty.False_Sold_By__c:' + objOppty.False_Sold_By__c);
						if (objOppty.False_Sold_By__c == true && objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID) {
							return;
						}
					}
				}

				// account update
				if (
					((String.isNotBlank(strCreatedByRole) && !set_RoleCreatedByUser.contains(strCreatedByRole)) &&
					objAccount.Route_to_Market__c == null &&
					(objAccount.RecordTypeId != objOldAccount.RecordTypeId ||
					objAccount.ParentId != objOldAccount.ParentId ||
					(objAccount.Original_Firm__c != objOldAccount.Original_Firm__c &&
					objAccount.Original_Firm__c != null &&
					objOldAccount.Original_Firm__c == null) ||
					(AccountUtil.INTEGRATION_USERS.contains(objAccount.OwnerId) &&
					String.isBlank(objAccount.Converted_Lead_Id__c) &&
					(objAccount.Account_Route_Count__c == null ||
					objAccount.Account_Route_Count__c == 0)) ||
					(objAccount.Set_Up_Steps_Completed__c != null &&
					objAccount.Set_Up_Steps_Completed__c != objOldAccount.Set_Up_Steps_Completed__c &&
					objAccount.Set_Up_Steps_Completed__c >= intSDRPercentage &&
					objOldAccount.Set_Up_Steps_Completed__c < intSDRPercentage &&
					String.isNotBlank(strOwnerRole) &&
					(!strOwnerRole.containsIgnoreCase(AccountUtil.PARTNER_ROLE) && !strOwnerRole.containsIgnoreCase(AccountUtil.SBIZ_ROLE)) &&
					strOwnerRole.containsIgnoreCase(AccountUtil.MDR_ROLE)))) || (checkPremiumTierRouting(objAccount, objOldAccount))
				) {
					objAccount.Account_Route_Count__c = (objAccount.Account_Route_Count__c == null || objAccount.Account_Route_Count__c == 0) ? 1 : objAccount.Account_Route_Count__c + 1;
					objAccount.UniqueEntry__RingLead_App_Field__c = PENDING_ROUTING;
					blnAccountRouting = true;
				} else if (
					(objOldAccount.Route_to_Market__c != objAccount.Route_to_Market__c) &&
					objAccount.Route_to_Market__c == AccountUtil.RTM_ACCOUNTANT &&
					(objAccount.Sold_By__c != null ||
					objAccount.Original_Firm__c != null)
				) {
					//account routing if RTM is updated to 'Accountant'
					objAccount.Account_Route_Count__c = (objAccount.Account_Route_Count__c == null || objAccount.Account_Route_Count__c == 0) ? 1 : objAccount.Account_Route_Count__c + 1;
					objAccount.UniqueEntry__RingLead_App_Field__c = PENDING_ROUTING;
					blnAccountRouting = true;
				}

				if (String.isNotBlank(objAccount.Converted_Lead_Id__c) && map_ConvertedLeads.containsKey(objAccount.Converted_Lead_Id__c) && blnRouting == false) {
					// check if account is created via lead conversion and get converted lead
					Lead objConvertedLead = map_ConvertedLeads.get(objAccount.Converted_Lead_Id__c);

					if (objConvertedLead.OwnerId != null && AccountUtil.INTEGRATION_USERS.contains(objAccount.OwnerId) && !AccountUtil.INTEGRATION_USERS.contains(objConvertedLead.OwnerId)) {
						// if account is owned by admin or integration user, change owner to lead owner
						objAccount.OwnerId = objConvertedLead.OwnerId;
					}
					if (
						objConvertedLead.OwnerId != null &&
						AccountUtil.INTEGRATION_USERS.contains(objAccount.OwnerId) &&
						AccountUtil.INTEGRATION_USERS.contains(objConvertedLead.OwnerId) &&
						objAccount.UniqueEntry__RingLead_App_Field__c != PENDING_ROUTING
					) {
						Integer intMinutes = Utils.getTimeStampDiff(objAccount.CreatedDate, System.now(), Utils.MINUTES);
						// Send account to routing if account is not routed 5 minutes after creation and lead is owned by integration user
						if (intMinutes >= 5) {
							// if account and lead are both owned by integration users, send account for routing
							objAccount.Account_Route_Count__c = (objAccount.Account_Route_Count__c == null || objAccount.Account_Route_Count__c == 0) ? 1 : objAccount.Account_Route_Count__c + 1;
							objAccount.UniqueEntry__RingLead_App_Field__c = PENDING_ROUTING;
						}
					}
				}
			}
		}
	}

	/**
	 * @description  Helper method to check if premium accounts need to be routed to CSMs
	 * @param        objOldAccount: Trigger.old
	 * @param        objAccount: Trigger.new
	 **/
	public Boolean checkPremiumTierRouting(Account objAccount, Account objOldAccount) {
		Boolean blnTierTrigger;
		Boolean blnAnchorPayTrigger;
		Boolean blnOverallStatusTrigger;
		Boolean doRouting = false;
		String strCSMOwnerRole = objAccount.CSM_Owner__c != null ? map_Users?.get(objAccount.CSM_Owner__c)?.UserRole?.Name : null;
		//If CSM owner is not set and Tier is not blank check for CSM routing triggers
		if (objAccount.CSM_Owner__c == null && objOldAccount.Tier__c != null && objAccount.Tier__c != null) {
			//Set if Tier is changing to Premium and Anchor pay date is filled and Overall status is not suspended
			blnTierTrigger =
				objAccount.Tier__c != objOldAccount.Tier__c &&
				objAccount.Tier__c.containsIgnoreCase(AccountUtil.PREMIUM_TIER) &&
				objAccount.Anchor_Pay_Date__c != null &&
				objAccount.ZP_Company_Overall_Status__c != AccountUtil.ACCOUNT_OVERALL_STATUS_SUSPENDED;
			//Set if Anchor pay date is being filled and Tier is Premium and Overall status is not suspended
			blnAnchorPayTrigger =
				objAccount.Anchor_Pay_Date__c != objOldAccount.Anchor_Pay_Date__c &&
				objAccount.Anchor_Pay_Date__c != null &&
				objAccount.Tier__c.containsIgnoreCase(AccountUtil.PREMIUM_TIER) &&
				objAccount.ZP_Company_Overall_Status__c != AccountUtil.ACCOUNT_OVERALL_STATUS_SUSPENDED;
			//Set if Overall status is being changed to non suspended, Tier is Premium and Anchor pay date is filled
			blnOverallStatusTrigger =
				objAccount.ZP_Company_Overall_Status__c != objOldAccount.ZP_Company_Overall_Status__c &&
				objAccount.ZP_Company_Overall_Status__c != AccountUtil.ACCOUNT_OVERALL_STATUS_SUSPENDED &&
				objAccount.Tier__c.containsIgnoreCase(AccountUtil.PREMIUM_TIER) &&
				objAccount.Anchor_Pay_Date__c != null;
			//If any of the triggers are true, return true
			doRouting = blnTierTrigger || blnAnchorPayTrigger || blnOverallStatusTrigger;
		}
		//If Tier is changing to Premium and CSM owner is not set or not a dedicated CSM, return true
		if (objAccount.Tier__c != objOldAccount.Tier__c &&
			objAccount.Tier__c.containsIgnoreCase(AccountUtil.PREMIUM_TIER)) {
			if (strCSMOwnerRole == null || !strCSMOwnerRole.containsIgnoreCase(AccountUtil.DEDICATED_CSM_ROLE)) {
				doRouting = true;
			}
		}
		return doRouting;
	}

	/**
	 * @author       Prashant Bhatt
	 * @description  Update Benefits Opt out Sync fields if Benefits opt out is updated
	 * @param        objOldAccount
	 * @param        objAccount
	 **/
	public void updateBenefitOptOutSync(Account objOldAccount, Account objAccount) {
		if (objAccount.Benefits_Email_Opt_Out__c != objOldAccount.Benefits_Email_Opt_Out__c && objAccount.Apply_to_all_clients__c && objAccount.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID) {
			objAccount.Benefit_Opt_Out_Sync__c = true;
		}
	}

	/**** Query Account and set data maps ****/
	private void setAccountDataMaps() {
		map_AllAccountMap = new Map<Id, Account>();
		map_ResellerAccountIdAccount = new Map<Id, Account>();
		map_ResellerAccountCompanyList = new Map<Id, List<Account>>();
		Set<Id> set_UserIdsQueryUserData = new Set<Id>();
		set_UserIdsQueryUserData = set_UserIds;
		setActiveHIStates();
		queryBusinessHours();
		setLeadRandomizeSettings();
		queryResellerAccountsWithCohortDate();
		//query admin contacts for accounts on which subscriptions have been updated
		queryContactsForSubscriptionsUpdate();
		queryAccountTeamMembers();

		for (
			Account objAccount : [
				SELECT
					Id,
					Name,
					Is_Active_Customer__c,
					ZP_Firm_ID__c,
					Apply_to_all_clients__c,
					Sold_By__c,
					Referred_By__c,
					Original_Firm__c,
					First_Client_Add_Date__c,
					Cohort_Date__c,
					Zp_Company_Id__c,
					Managing_Firm__c,
					Joined_Date_Panda__c,
					OwnerId,
					RecordTypeId,
					Benefits_Email_Opt_Out__c,
					Benefits_Opt_Out_Details__c,
					Discount__c,
					NumberOf_Closed_Payroll_Opps_Referred_By__c,
					NumberOf_Closed_Payroll_Opps_Sold_By__c,
					Number_Of_Open_Payroll_Opps_Sold_By__c,
					Number_Of_Open_Payroll_Opps_Referred_By__c,
					Reseller_Company__c,
					CreatedDate,
					SAL_to_First_Client_Add__c,
					First_Client_Create_Date__c,
					Owner.UserRole.Name,
					Priority_Support__c,
					International_Contractors__c,
					International_Employees__c,
					HI_Owner__c,
					HI_Owner__r.UserRole.Name,
					HI_Owner__r.IsActive,
					ParentId,
					Sold_By__r.Discount__c,
					Premium_Tier_Discount__c,
					Number_of_Active_Employees__c,
					Number_of_Active_Contractors__c,
					Additional_Services__c,
					Tier__c,
					Reward_Eligible__c,
					Product_Interest__c,
					Product_Interest_Countries__c,
					(
						SELECT Id, Normalized_Email_Domain__c
						FROM Contacts
						WHERE Normalized_Email_Domain__c != NULL
						ORDER BY CreatedDate ASC // Get earliest created contact first
						LIMIT 1
					),
					(
						SELECT
							Id,
							Name,
							False_Sold_By__c,
							RecordTypeId,
							IsClosed,
							OwnerId,
							Owner.IsActive,
							StageName,
							Payment_Invoice__c,
							Pricebook2Id,
							Additional_Opportunity_Services__c,
							Pricebook2.Name,
							Upsell_Tier__c,
							NumberOfEmployees__c,
							Number_of_Contractors__c,
							International_Employees__c,
							International_Contractors__c,
							MRR__c,
							IsWon,
							CloseDate,
							CreatedDate,
							ROE_Exception__c,
							Owner.UserRole.Name,
							Product_Interest__c,
							Product_Interest_Countries__c,
							Type
						FROM Opportunities
						ORDER BY CreatedDate DESC
					),
					(SELECT Id, Sales_Rep__c FROM Insurance_Quotes__r WHERE Processing_State__c = :IntegrationUtils.QUEUED_STATE)
				FROM Account
				WHERE
					Id IN :set_CompanyAccountIds
					OR Id IN :set_ResellerAccountIds
					OR Id IN :set_SoldByReferredByIds
					OR Id IN :set_NormalizeAccountIds
					OR Sold_By__c IN :set_ParentResellerIds
					OR Referred_By__c IN :set_ParentResellerIds
					OR Original_Firm__c IN :set_ParentResellerIds
					OR ZP_Company_id__c IN :set_CompanyId
					OR ZP_Firm_id__c IN :set_FirmId
			]
		) {
			map_AllAccountMap.put(objAccount.Id, objAccount);

			if (objAccount.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID) {
				map_ResellerAccountIdAccount.put(objAccount.Id, objAccount);
			}
			//adding queried child accounts for update in the map
			if (
				(objAccount.Sold_By__c != null && set_ParentResellerIds.contains(objAccount.Sold_By__c)) ||
				(objAccount.Referred_By__c != null && set_ParentResellerIds.contains(objAccount.Referred_By__c)) ||
				(objAccount.Original_Firm__c != null && set_ParentResellerIds.contains(objAccount.Original_Firm__c))
			) {
				if (objAccount.Sold_By__c != null && map_ResellerAccountCompanyList.containsKey(objAccount.Sold_By__c)) {
					map_ResellerAccountCompanyList.get(objAccount.Sold_By__c).add(objAccount);
				} else if (objAccount.Original_Firm__c != null && map_ResellerAccountCompanyList.containsKey(objAccount.Original_Firm__c)) {
					map_ResellerAccountCompanyList.get(objAccount.Original_Firm__c).add(objAccount);
				} else if (objAccount.Referred_By__c != null && map_ResellerAccountCompanyList.containsKey(objAccount.Referred_By__c)) {
					map_ResellerAccountCompanyList.get(objAccount.Referred_By__c).add(objAccount);
				} else {
					List<Account> list_CompanyAccount = new List<Account>();
					list_CompanyAccount.add(objAccount);
					if (objAccount.Sold_By__c != null) {
						map_ResellerAccountCompanyList.put(objAccount.Sold_By__c, list_CompanyAccount);
					} else if (objAccount.Original_Firm__c != null) {
						map_ResellerAccountCompanyList.put(objAccount.Original_Firm__c, list_CompanyAccount);
					} else if (objAccount.Referred_By__c != null) {
						map_ResellerAccountCompanyList.put(objAccount.Referred_By__c, list_CompanyAccount);
					}
				}
			}

			for (Opportunity objOpportunity : objAccount.Opportunities) {
				set_UserIdsQueryUserData.add(objOpportunity.OwnerId);
			}
		}

		map_Users = getUserMap(set_UserIdsQueryUserData);
		map_UsersToCheckCSRole = map_Users;

		// Build a map of user Id and list of user account team members (used in HI Sales Routing)
		for (UserAccountTeamMember objAccTeamMember : AccountUtil.queryUserAccountTeamMembers(set_UserIds)) {
			List<UserAccountTeamMember> list_UserAccTeamMembers = new List<UserAccountTeamMember>();
			if (map_UserAccountTeamMembers.containsKey(objAccTeamMember.OwnerId)) {
				list_UserAccTeamMembers = map_UserAccountTeamMembers.get(objAccTeamMember.OwnerId);
			}

			list_UserAccTeamMembers.add(objAccTeamMember);
			map_UserAccountTeamMembers.put(objAccTeamMember.OwnerId, list_UserAccTeamMembers);
		}

		objInternationalPayrollNotify = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'International_Payroll_added_to_Payroll_Opportunity'];
	}

	/**** Get Lead Randomize Settings for Account Holdout ****/
	private static void setLeadRandomizeSettings() {
		objRandomize = Lead_Randomize__c.getOrgDefaults();
		if (objRandomize != null && objRandomize.Number_of_Company_Accounts__c != null) {
			intNumberOfCompanyAccountHoldOut = Integer.valueOf(objRandomize.Number_of_Company_Accounts__c);
		}
		if (objRandomize != null && objRandomize.Number_of_Reseller_Accounts__c != null) {
			intNumberOfResellerAccountHoldOut = Integer.valueOf(objRandomize.Number_of_Reseller_Accounts__c) - 1;
		}
	}

	/**
	 * @author       Praveen Sethu
	 * @description  Query the last n reseller accounts that got cohort date in descending order
	 **/
	private static void queryResellerAccountsWithCohortDate() {
		for (Account objAccount : [
			SELECT Id
			FROM Account
			WHERE RecordTypeId = :AccountUtil.RESELLER_ACCOUNT_RT_ID AND Cohort_Update_Date_Time__c != NULL
			ORDER BY Cohort_Update_Date_Time__c DESC
			LIMIT :intNumberOfResellerAccountHoldOut
		]) {
			map_ResellerCohortAccts.put(objAccount.Id, objAccount);
		}
	}

	private void setActiveHIStates() {
		List<State_Name_to_abbreviations_Mapping__c> stateNameMappingList = State_Name_to_abbreviations_Mapping__c.getall().values();
		set_HIStates = new Set<String>();

		if (stateNameMappingList.size() > 0) {
			for (State_Name_to_abbreviations_Mapping__c objAbbreviation : stateNameMappingList) {
				if (objAbbreviation.Gusto_Benefits_Available__c) {
					set_HIStates.add(objAbbreviation.State_Abbreviation__c);
				}
			}
		}
	}

	/*** Query Default Business Hour ***/
	private void queryBusinessHours() {
		objBusinessHour = GlobalQueryHelper.getBusinessHoursByName(SALES_BUSINESS_HOURS);
	}

	/**** Query all opportunities ****/
	private static List<Opportunity> queryOpportunity(Set<Id> set_AccountId) {
		set_UpsellOppIds = new Set<Id>();
		List<Opportunity> list_Opportunties = [
			SELECT
				Id,
				LeadSource,
				Type,
				RecordType.Name,
				RecordTypeId,
				Joined_Date_Panda__c,
				CloseDate,
				StageName,
				AccountId,
				Sold_By__c,
				Referred_By__c,
				IsClosed,
				IsWon,
				Payment_Invoice__c,
				Previous_Payroll_Provider__c,
				Payroll_Processed_Date__c,
				Ran_Payroll_Date__c,
				Locked__c,
				NumberOfEmployees__c,
				Number_of_Contractors__c,
				MRR__c,
				Pricebook2Id,
				Pricebook2.Name,
				Discount__c,
				ZP_Company_ID__c,
				OwnerId,
				Owner_Department__c,
				Owner_Division__c,
				Owner_Role__c,
				Owner_Title__c,
				MDR__c,
				MDR_Lead_Owner_Role__c,
				MDR_Received__c,
				Additional_Opportunity_Services__c,
				False_Sold_By__c,
				International_Contractors__c,
				International_Employees__c,
				Tier__c,
				Upsell_Tier__c,
				(SELECT Id, Product2Id, Quantity, Discount, PricebookEntryId FROM OpportunityLineItems)
			FROM Opportunity
			WHERE AccountId IN :set_AccountId
		];
		for (Opportunity objOpp : list_Opportunties) {
			set_OpptyBenefitOrderIds.add(objOpp.Id);
			if (objOpp.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID && objOpp.Id != null) {
				set_UpsellOppIds.add(objOpp.Id);
			}
		}
		return list_Opportunties;
	}

	private Map<Id, Integer> queryCallActivity() {
		Map<Id, Integer> map_CountCallActivity = new Map<Id, Integer>();
		for (AggregateResult intCount : [
			SELECT WhatId, count(ID)
			FROM Task
			WHERE RecordTypeId = :TaskUtil.TASK_CALL_RT_ID AND WhatId IN :set_UpsellOppIds AND Status = :AccountUtil.TASK_STATUS_CONNECT
			GROUP BY WhatId
		]) {
			map_CountCallActivity.put((Id) intCount.get('WhatId'), (Integer) intCount.get('expr0'));
		}
		return map_CountCallActivity;
	}

	/**
	 * @author         Prity Kumari
	 * @description    Query Normalized Email Domain on update
	 */
	public void queryAccountsWithNormalizedEmailonCreate() {
		for (Account objAcc : [
			SELECT Id, RecordTypeId, Normalized_Email_Domain__c, Account_Owner_Role__c, OwnerId
			FROM Account
			WHERE Normalized_Email_Domain__c IN :set_NormalizedEmailDomains AND RecordTypeId = :AccountUtil.RESELLER_ACCOUNT_RT_ID
			ORDER BY CreatedDate
		]) {
			if (!map_AccountsNormailizedEmailDomains.containsKey(objAcc.Normalized_Email_Domain__c)) {
				map_AccountsNormailizedEmailDomains.put(objAcc.Normalized_Email_Domain__c, objAcc);
			}
		}
	}

	/**
	 * @author         Praveen Sethu
	 * @description    Query converted leads and set same owner as lead owner
	 */
	public void queryConvertedLeads(Boolean blnInsert) {
		Set<String> set_Emails = new Set<String>();
		for (Lead objLead : [
			SELECT Id, OwnerId, ConvertedAccountId, UniqueEntry__RingLead_App_Field__c, Lead_Route_Count__c, Sold_By__c, Referred_By__c, Routing_Owner_Id__c, Owner.UserRole.Name, Email
			FROM Lead
			WHERE Id IN :set_ConvertedLeadIds
		]) {
			map_ConvertedLeads.put(objLead.Id, objLead);
			if (String.isNotBlank(objLead.Email)) {
				set_Emails.add(objLead.Email);
			}
		}

		if (blnInsert) {
			for (ZP_Company__c objComp : [SELECT Id, Id__c, Created_By_Email__c FROM ZP_Company__c WHERE Created_By_Email__c IN :set_Emails]) {
				map_ZPCompanies.put(objComp.Created_By_Email__c, objComp);
			}
		}
	}

	/**
	 * @author         Prity Kumari
	 * @description    Query Normalized Email Domain on Update
	 * @param          set_AccountIds Set of new accounts Ids
	 */
	public void queryAccountsWithNormalizedEmailonUpdate(Set<Id> set_AccountIds) {
		for (Account objAcc : [
			SELECT Id, Onboarding_Flow__c, RecordTypeId, Normalized_Email_Domain__c, Account_Owner_Role__c, OwnerId
			FROM Account
			WHERE Normalized_Email_Domain__c IN :set_NormalizedEmailDomains AND RecordTypeId = :AccountUtil.RESELLER_ACCOUNT_RT_ID
			ORDER BY CreatedDate ASC
			LIMIT 10000
		]) {
			if (!map_AccountsNormailizedEmailDomains.containsKey(objAcc.Normalized_Email_Domain__c)) {
				map_AccountsNormailizedEmailDomains.put(objAcc.Normalized_Email_Domain__c, objAcc);
			}
		}
	}

	/**
	 * @author         Prity Kumari
	 * @description    Query Normalized Email Domain to check for duplicates and assign to Partner House Account
	 * @param          objAcc new Account
	 */
	public void queryNormalizedEmailDomain(Account objAcc, Account objOldAcc) {
		String strAccountOwnerRole;
		if (
			map_AccountsNormailizedEmailDomains.containsKey(objAcc.Normalized_Email_Domain__c) &&
			(objOldAcc == null ||
			objAcc.Id != map_AccountsNormailizedEmailDomains.get(objAcc.Normalized_Email_Domain__c).Id)
		) {
			objAcc.Sales_Engagement_Status__c = AccountUtil.SALES_ENGMNT_STATUS_UNQUALIFIED;
			objAcc.Sales_Engagement_Status_Detail__c = AccountUtil.SALES_ENGMNT_STATUS_DETAIL_DISCOVERY_DUPE;

			strAccountOwnerRole = String.isNotBlank(map_AccountsNormailizedEmailDomains.get(objAcc.Normalized_Email_Domain__c).Account_Owner_Role__c)
				? map_AccountsNormailizedEmailDomains.get(objAcc.Normalized_Email_Domain__c).Account_Owner_Role__c
				: '';
			objAcc.Possible_Duplicate_Acc_Owner__c = map_AccountsNormailizedEmailDomains.get(objAcc.Normalized_Email_Domain__c)?.OwnerId;
			objAcc.OwnerId = String.isNotBlank(strAccountOwnerRole)
				? (strAccountOwnerRole == AccountUtil.SALES_PARTNER_AE_ROLE ||
						strAccountOwnerRole == AccountUtil.SALES_PARTNER_AM_ROLE ||
						strAccountOwnerRole == AccountUtil.SALES_PARTNER_SAM_ROLE)
						? map_AccountsNormailizedEmailDomains.get(objAcc.Normalized_Email_Domain__c).OwnerId
						: Label.Partner_House_Account
				: Label.Partner_House_Account;
			objAcc.Is_Duplicate__c = true;
			objAcc.Possible_Duplicate_Account__c = map_AccountsNormailizedEmailDomains.get(objAcc.Normalized_Email_Domain__c).Id;
		}
	}

	private static Map<Id, User> mapSubsetUserMap;
	/**
	 * @author         Prity Kumari
	 * @description    Query Users and create a map
	 * @return         Map of selected Users by User.Id
	 */
	public static Map<Id, User> getUserMap(Set<Id> set_UserIds) {
		if (mapSubsetUserMap == null) {
			mapSubsetUserMap = new Map<Id, User>();
		}
		if (!mapSubsetUserMap.keyset().containsAll(set_UserIds)) {
			mapSubsetUserMap = new Map<Id, User>(
				[
					SELECT
						Id,
						Alias,
						Calendar_Link__c,
						Data_Migration_Validation__c,
						Department,
						Division,
						Email,
						Exempt_from_Validation_Rules__c,
						FirstName,
						Is_Api_Integration__c,
						IsActive,
						LastName,
						ManagerId,
						Name,
						Profile.Name,
						ProfileId,
						Secondary_Role__c,
						Slack_Id__c,
						TimeZoneSidKey,
						Title,
						UserRole.DeveloperName,
						UserRole.Name,
						UserRoleId
					FROM User
					WHERE Id IN :set_UserIds
				]
			);
		}
		return mapSubsetUserMap;
	}

	/**
	 * @description           Update Contact Owner when related owner changes
	 *
	 * @author                Sandeep Golla
	 * @param map_oldAccounts Trigger.oldMap
	 * @param map_Accounts    Trigger.newMap
	 */
	private void updateContactInformation(Map<Id, Account> map_oldAccounts, Map<Id, Account> map_Accounts) {
		List<Contact> list_Contacts = new List<Contact>();

		for (Id objAccountId : map_Accounts.keySet()) {
			if (map_AccountIdsToContacts.containsKey(objAccountId)) {
				for (Contact objContact : map_AccountIdsToContacts.get(objAccountId)) {
					objContact.OwnerId = map_Accounts.get(objAccountId).OwnerId;
					list_Contacts.add(objContact);
				}
			}
		}

		if (!list_Contacts.isEmpty()) {
			TriggerHandler.bypass('ContactTriggerHandler');
			Map<String, String> dmlUpdateErrorsMap = new Map<String, String>();
			List<Database.SaveResult> saveResult = Database.update(list_Contacts, false);
			dmlUpdateErrorsMap = Utils.processSaveResult(saveResult, list_Contacts, 'Id', true, 'AccountTriggerHelper-updateContactInformation');
			TriggerHandler.clearBypass('ContactTriggerHandler');
		}
	}

	/**
	 * @author       Sandeep Golla
	 * @description  Future method - Update Contact owner when account owner is changed
	 * @param        set_AccIds set of Account Ids
	 **/
	@future
	public static void updateContactOwnerFuture(Set<Id> set_AccIds) {
		// Variable Declaration
		List<Contact> list_ConsToUpdate = new List<Contact>();

		for (Contact objCon : [SELECT Id, Name, AccountId, Account.OwnerId, OwnerId FROM Contact WHERE AccountId IN :set_AccIds]) {
			if (objCon.OwnerId != objCon.Account.OwnerId) {
				objCon.OwnerId = objCon.Account.OwnerId;
				list_ConsToUpdate.add(objCon);
			}
		}
		if (!list_ConsToUpdate.isEmpty()) {
			TriggerHandler.bypass('ContactTriggerHandler');
			Map<String, String> dmlUpdateErrorsMap = new Map<String, String>();
			List<Database.SaveResult> saveResult = Database.update(list_ConsToUpdate, false);
			dmlUpdateErrorsMap = Utils.processSaveResult(saveResult, list_ConsToUpdate, 'Id', true, 'AccountTriggerHelper-updateContactOwnerFuture');
			TriggerHandler.clearBypass('ContactTriggerHandler');
		}
	}

	/**
	 * @author       Sandeep Golla
	 * @description  Query Contacts based on set of Account ids
	 * @param        set_AccountIds Set of Account Ids
	 * @return       `Map<Id, List<Contact>>` Queryied Contacts by AccountId
	 **/
	private static Map<Id, List<Contact>> queryContact(Set<Id> set_AccountIds) {
		Map<Id, List<Contact>> map_accountIdToContactRec = new Map<Id, List<Contact>>();
		for (Contact objContact : [SELECT Id, FirstName, LastName, Name, OwnerId, AccountId FROM Contact WHERE AccountId IN :set_AccountIds]) {
			//initialize new list
			List<Contact> list_Contacts = new List<Contact>();
			//check if map already contains group
			if (map_accountIdToContactRec.containsKey(objContact.AccountId)) {
				list_Contacts = map_accountIdToContactRec.get(objContact.AccountId);
			}

			list_Contacts.add(objContact);
			map_accountIdToContactRec.put(objContact.AccountId, list_Contacts);
		}
		return map_accountIdToContactRec;
	}

	/**
	 * @author       Sandeep Golla
	 * @description  Query Leads based on set of Reseller Account ids
	 **/
	private void queryLeads() {
		map_ResellerAccountZPFirmIdToLead = new Map<String, Lead>();
		for (Lead objLead : [SELECT Id, Name, OwnerId, RecordTypeId, ZP_Firm_ID__c FROM Lead WHERE ZP_Firm_ID__c IN :set_FirmId]) {
			if (!map_ResellerAccountZPFirmIdToLead.containsKey(objLead.ZP_Firm_ID__c)) {
				map_ResellerAccountZPFirmIdToLead.put(objLead.ZP_Firm_ID__c, objLead);
			}
		}
	}

	/**
	 * @author       Debasmita Rawooth
	 * @description  Set field on Account
	 * @param		 objOldAccount old Account record
	 * @param        objAccount new Account Record
	 **/
	public void setPotentialFraudHistory(Account objAccount, Account objOldAccount) {
		if (objOldAccount == null) {
			objAccount.Potential_Fraud_History__c = objAccount.Potential_Fraud_Account__c;
		} else if (objAccount.Potential_Fraud_Account__c && !objOldAccount.Potential_Fraud_History__c) {
			objAccount.Potential_Fraud_History__c = objAccount.Potential_Fraud_Account__c;
		}
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Set Company Id / Firm ID on Account
	 * @param        objAccount new Account Record
	 **/
	public void setCompanyFirmId(Account objAccount) {
		if (String.isBlank(objAccount.Company_Firm_ID__c)) {
			if (String.isNotBlank(objAccount.ZP_Firm_ID__c)) {
				objAccount.Company_Firm_ID__c = objAccount.ZP_Firm_ID__c;
			} else if (String.isNotBlank(objAccount.ZP_Company_ID__c)) {
				objAccount.Company_Firm_ID__c = objAccount.ZP_Company_ID__c;
			}
		}
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Set Standard Fields on Account with 3rd party fields for Data Enrinchment.
	 * @param        objAccount - new Account Record
	 **/
	public void setStandardFieldsFrom3rdParty(Account objAccount) {
		if (objAccount.AnnualRevenue == null && objAccount.X3rd_Party_Annual_Revenue__c != null) {
			objAccount.AnnualRevenue = objAccount.X3rd_Party_Annual_Revenue__c;
		}

		if (objAccount.NumberOfEmployees == null && objAccount.X3rd_Party_Num_Employees__c != null) {
			objAccount.NumberOfEmployees = Integer.valueOf(objAccount.X3rd_Party_Num_Employees__c);
		}

		if (String.isBlank(objAccount.Industry) && String.isNotBlank(objAccount.X3rd_Party_Industry__c)) {
			objAccount.Industry = objAccount.X3rd_Party_Industry__c;
		}

		if (
			String.isBlank(objAccount.BillingCity) &&
			String.isBlank(objAccount.BillingState) &&
			String.isBlank(objAccount.BillingPostalCode) &&
			(String.isNotBlank(objAccount.X3rd_Party_City__c) ||
			String.isNotBlank(objAccount.X3rd_Party_State__c) ||
			String.isNotBlank(objAccount.X3rd_Party_Postal__c))
		) {
			objAccount.BillingCity = objAccount.X3rd_Party_City__c;
			objAccount.BillingState = objAccount.X3rd_Party_State__c;
			objAccount.BillingPostalCode = objAccount.X3rd_Party_Postal__c;
		}
	}

	/**
	 * @Author      : David (Dato) Tsamalashvili
	 * @Description : If not admin tries to delete Account throw an error
	 * @Parm        : object of old Account record
	 * @Return      : N/A
	 **/
	public void preventDeletion(Account objOldAccount) {
		if (!UserUtils.isAdminIntgUser(UserInfo.getUserId()) || !Test.isRunningTest()) {
			//Add Error
			objOldAccount.addError(AccountUtil.DELETE_EXCEPTION);
		}
	}

	/**
	 * @Author      : Swati Arya
	 * @Description : Change the associated contacts record type based on the account record type
	 * @Parm        : set of account ids
	 * @Return      : N/A
	 **/
	public static void updateContactRecordType(Set<Id> set_AccountIdForRecordTypeChange) {
		List<Contact> lst_ContactsToUpdate = new List<Contact>();

		for (Contact objContact : [SELECT Id, RecordTypeId, AccountId, Account.RecordTypeId, Account.Type FROM Contact WHERE AccountId IN :set_AccountIdForRecordTypeChange]) {
			if (objContact.Account.RecordTypeId == AccountUtil.EMBEDDED_COMPANY_ACCOUNT_RT_ID) {
				objContact.RecordTypeId = ContactUtil.EMBEDDED_COMPANY_CONTACT_RT_ID;
			} else if (objContact.Account.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
				objContact.RecordTypeId = ContactUtil.COMPANY_CONTACT_RT_ID;
			} else if (objContact.Account.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID && objContact.Account.Type == AccountUtil.EMBEDDED_PARTNER_TYPE) {
				objContact.RecordTypeId = ContactUtil.EMBEDDED_COMPANY_CONTACT_RT_ID;
			} else if (objContact.Account.RecordTypeId == AccountUtil.PARTNER_RT_ID && objContact.Account.Type == AccountUtil.EMBEDDED_PARTNER_TYPE) {
				objContact.RecordTypeId = ContactUtil.EMBEDDED_COMPANY_CONTACT_RT_ID;
			}
			lst_ContactsToUpdate.add(objContact);
		}

		if (!lst_ContactsToUpdate.isEmpty()) {
			TriggerHandler.bypass('ContactTriggerHandler');
			Map<String, String> dmlUpdateErrorsMap = new Map<String, String>();
			List<Database.SaveResult> saveResult = Database.update(lst_ContactsToUpdate, false);
			dmlUpdateErrorsMap = Utils.processSaveResult(saveResult, lst_ContactsToUpdate, 'Id', true, 'AccountTriggerHelper-updateContactRecordType');
			TriggerHandler.clearBypass('ContactTriggerHandler');
		}
	}

	/**
	 * @Description : Set Subscription Preferences on Account based on dependencies. Common method for before insert and update.
	 * @Param        : Account - from Trigger.new
	 * @Param        : Account - from Trigger.old (if before update)
	 * @Return      : void
	 **/
	public void setSubscriptionPreferencesOnAccount(Account objNewAccount, Account objOldAccount, Boolean blnIsInsert) {
		Set<String> set_newSubscriptionValues = new Set<String>();
		Set<String> set_oldSubscriptionValues = new Set<String>();
		if (String.isNotBlank(objNewAccount.Customer_Subscriptions__c)) {
			set_newSubscriptionValues.addAll(objNewAccount.Customer_Subscriptions__c.split(';'));
		}
		//If new populate subscriptions factoring dependencies
		if (blnIsInsert) {
			objNewAccount.Customer_Subscriptions__c = SubscriptionCenterUtil.getApplicableSubscriptionPreferences(set_newSubscriptionValues, set_oldSubscriptionValues, true);
		} else if (objOldAccount != null && objNewAccount.Customer_Subscriptions__c != objOldAccount.Customer_Subscriptions__c) {
			// Check if Subscription Preferences are modified on Contact
			if (String.isNotBlank(objOldAccount.Customer_Subscriptions__c)) {
				set_oldSubscriptionValues.addAll(objOldAccount.Customer_Subscriptions__c.split(';'));
			}
			objNewAccount.Customer_Subscriptions__c = SubscriptionCenterUtil.getApplicableSubscriptionPreferences(set_newSubscriptionValues, set_oldSubscriptionValues, false);
		}
	}

	/**
	 * @Description : Query admin contacts if preferences have been updated on account and mark for update
	 * @Param       : NA (Uses static global variables)
	 * @Return      : void
	 **/
	public void queryContactsForSubscriptionsUpdate() {
		if (!set_accountSubscriptionsChanged.isEmpty()) {
			for (Contact objContact : queryContactsByAccountIdsAndRoles(set_accountSubscriptionsChanged, ContactTriggerHelper.LIST_ADMIN_ROLES).values()) {
				if (map_AccountIdToContactRecords.containsKey(objContact.AccountId)) {
					map_AccountIdToContactRecords.get(objContact.AccountId).add(objContact);
				} else {
					map_AccountIdToContactRecords.put(objContact.AccountId, new List<Contact>{ objContact });
				}
			}
		}
	}

	/**
	 * @Description : Query Account Team Members
	 * @Param       : NA (Uses static global variables)
	 * @Return      : void
	 **/
	public void queryAccountTeamMembers() {
		if (!set_accountsCSMUpdated.isEmpty()) {
			for (AccountTeamMember objATM : AccountUtil.queryAccountTeamMembers(set_accountsCSMUpdated)) {
				if (map_AccountIdToATMRecords.containsKey(objATM.AccountId)) {
					map_AccountIdToATMRecords.get(objATM.AccountId).add(objATM);
				} else {
					map_AccountIdToATMRecords.put(objATM.AccountId, new List<AccountTeamMember>{ objATM });
				}
			}
		}
	}

	/**
	 * @Description : Update subscription preferences on contacts if preferences have been updated on the account
	 * @Param       : Account - Trigger.New, Account - Trigger.Old
	 * @Return      : void
	 **/
	public void setSubscriptionPreferenceOnContacts(Account objNewAccount, Account objOldAccount) {
		if (
			map_AccountIdToContactRecords.containsKey(objNewAccount.Id) &&
			map_AccountIdToContactRecords.get(objNewAccount.Id) != null &&
			objNewAccount.Customer_Subscriptions__c != objOldAccount.Customer_Subscriptions__c
		) {
			for (Contact objContact : map_AccountIdToContactRecords.get(objNewAccount.Id)) {
				if (objContact.Customer_Subscriptions__c != objNewAccount.Customer_Subscriptions__c) {
					Contact objContactToUpdate = map_contactsToUpdate.containsKey(objContact.Id) && map_contactsToUpdate.get(objContact.Id) != null
						? map_contactsToUpdate.get(objContact.Id)
						: new Contact(Id = objContact.Id, ZP_User_Id__c = objContact.ZP_User_Id__c);
					objContactToUpdate.Customer_Subscriptions__c = objNewAccount.Customer_Subscriptions__c;
					map_contactsToUpdate.put(objContactToUpdate.Id, objContactToUpdate);
					if (!SubscriptionCenterUtil.INTEGRATION_USERS.contains(UserInfo.getUserId()) && !objContact.Inactive_ZP_User__c) {
						map_contactsToCallout.put(objContactToUpdate.Id, objContactToUpdate);
					}
				}
			}
		}
	}

	/**
	 * @Description : Update HI Owner from Parent Account to All Child Accounts & Open Opportunities
	 * @Param       : Account - Trigger.New, Account - Trigger.Old
	 * @Return      : void
	 **/
	public void updateHIOwnerOnRelatedRecords(Account objNewAccount, Account objOldAccount) {
		// Sync HI Owner to related Benefits Opportunities
		if (objOldAccount != null && objNewAccount.HI_Owner__c != objOldAccount.HI_Owner__c && objNewAccount.HI_Owner__c != null && map_AllAccountMap.containsKey(objNewAccount.Id)) {
			Account objAccMap = map_AllAccountMap.get(objNewAccount.Id);
			// iterate over open benefits opportunities and sync hi owner from account
			for (Opportunity objOppty : objAccMap.Opportunities) {
				if (objOppty.IsClosed == false && OpportunityUtil.set_BenefitRTChangeEmployees.contains(objOppty.RecordTypeId) && objOppty.OwnerId != objNewAccount.HI_Owner__c) {
					objOppty.OwnerId = objNewAccount.HI_Owner__c;
					map_OpptysToUpdate.put(objOppty.Id, objOppty);
				}
			}

			// iterate over all queued insurance quote records
			for (Insurance_Quote__c objInsuranceQuote : objAccMap.Insurance_Quotes__r) {
				if (objNewAccount.HI_Owner__c != objInsuranceQuote.Sales_Rep__c) {
					objInsuranceQuote.Sales_Rep__c = objNewAccount.HI_Owner__c;
					map_InsuranceQuotesToUpdate.put(objInsuranceQuote.Id, objInsuranceQuote);
				}
			}
		}
	}

	/**
	 * @Description : Send open cross-sell and upsell opportunities to routing tool if joined date is updated
	 * @Param       : Account - Trigger.New, Account - Trigger.Old
	 * @Return      : void
	 **/
	public void checkOpportunitiesForRouting(Account objNewAccount, Account objOldAccount) {
		if (
			objOldAccount != null &&
			objNewAccount.Joined_Date_Panda__c != objOldAccount.Joined_Date_Panda__c &&
			objNewAccount.Joined_Date_Panda__c != null &&
			map_AllAccountMap.containsKey(objNewAccount.Id)
		) {
			Account objAccount = map_AllAccountMap.get(objNewAccount.Id);

			for (Opportunity objOppty : objAccount.Opportunities) {
				if (objOppty.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID && objOppty.Upsell_Tier__c == AccountUtil.EMPLOYER_OF_RECORD && objOppty.IsClosed == false) {
					set_OpportunityIdsToRoute.add(objOppty.Id);
				}
			}
		}
	}

	/**
	 * @Description : On CSM update, insert new CSM Account Team Member if not existing else update
	 * @Param       : Account - Trigger.New, Account - Trigger.Old
	 * @Return      : void
	 **/
	public void addUpdateCSMAccountTeamMemberOnCSMChange(Account objNewAccount, Account objOldAccount) {
		//for each account in trigger checking if csm has been added/updated
		if (objOldAccount != null && objNewAccount.CSM_Owner__c != objOldAccount.CSM_Owner__c) {
			//if CSM has been added/updated define new Team member but don't initialize yet
			AccountTeamMember objCSMAccountTeamMember;
			List<AccountTeamMember> list_AccountTeamMembers = map_AccountIdToATMRecords.containsKey(objNewAccount.Id) ? map_AccountIdToATMRecords.get(objNewAccount.Id) : null;
			if (list_AccountTeamMembers != null && !list_AccountTeamMembers.isEmpty()) {
				for (AccountTeamMember objATM : list_AccountTeamMembers) {
					//if team members exist and CSM is found, delete old CSM and add new
					//Deletion is necessary since userId is a non writable field on AccountTeamMember
					if (objATM.TeamMemberRole == AccountUtil.ACCOUNT_TEAM_MEMBER_CSM_ROLE) {
						map_ATMsToDelete.put(objATM.Id, objATM); //add to delete map, if key already exists, it will be overwritten
						if (objNewAccount.CSM_Owner__c != null) {
							objCSMAccountTeamMember = new AccountTeamMember(
								AccountId = objNewAccount.Id,
								UserId = objNewAccount.CSM_Owner__c,
								TeamMemberRole = AccountUtil.ACCOUNT_TEAM_MEMBER_CSM_ROLE
							);
							list_ATMsToInsert.add(objCSMAccountTeamMember);
							break;
						}
					}
				}
			}
			//if team members don't exist or team members exist but CSM is not found, add new CSM member
			if (objCSMAccountTeamMember == null && objNewAccount.CSM_Owner__c != null) {
				objCSMAccountTeamMember = new AccountTeamMember(AccountId = objNewAccount.Id, UserId = objNewAccount.CSM_Owner__c, TeamMemberRole = AccountUtil.ACCOUNT_TEAM_MEMBER_CSM_ROLE);
				list_ATMsToInsert.add(objCSMAccountTeamMember);
			}
		}
	}

	/**
	 * @Description : Processing International Contractor Payment Interest - Creating/Updating Company or cross-sell and upsell opportunities.
	 * @Param       : map_NewAccounts - Trigger.NewMap
	 * @Param       : map_OldAccounts - Trigger.NewMap
	 * @Return      : void
	 **/
	public void processICPProductInterest(Map<Id, Account> map_NewAccounts, Map<Id, Account> map_OldAccounts) {
		// Initialize variables for ICP Product Interest processing
		for (Account objNewAccount : map_NewAccounts.values()) {
			// Initialize variables for ICP Product Interest processing
			List<String> list_NewICPProductInterest = new List<String>();
			List<String> list_OldICPProductInterest = new List<String>();
			Account objOldAccount = map_OldAccounts.get(objNewAccount.Id);
			Set<String> set_ICPProdInterest = new Set<String>();
			Set<String> set_ClosedLostICPProdInterest = new Set<String>();
			// check if there is a change in Product Interest or Product Interest Countries
			if (objOldAccount != null && objNewAccount.Product_Interest__c != objOldAccount.Product_Interest__c && map_AllAccountMap.containsKey(objNewAccount.Id)) {
				// Set Default eligibility to true
				Boolean blnEligible = true;
				Boolean blnNotHistoricalData = true;
				Boolean blnICPOnboardedAdded = false;
				// Initialize variables for ICP Product Interest processing
				if (String.isNotBlank(objNewAccount.Product_Interest__c)) {
					//	Iterate through ICP Product Interest and check if new Product Interest contains ICP Product Interest
					for (String strICPProdInterest : AccountUtil.ICP_PRODUCT_INTEREST) {
						// If new Product Interest contains ICP Product Interest and old Product Interest does not contain ICP Product Interest, add to list
						if (
							objNewAccount.Product_Interest__c.containsIgnoreCase(strICPProdInterest) &&
							(String.isBlank(objOldAccount.Product_Interest__c) || !objOldAccount.Product_Interest__c.containsIgnoreCase(strICPProdInterest))
						) {
							// Add ICP Product Interest to list
							list_NewICPProductInterest.add(strICPProdInterest);
							set_ICPProdInterest.add(strICPProdInterest);
						}
					}
				}

				// If new Product Interest is blank, set eligibility to false
				if (String.isNotBlank(objOldAccount.Product_Interest__c)) {
					//	Iterate through ICP Product Interest and check if old Product Interest contains ICP Product Interest
					for (String strICPProdInterest : AccountUtil.ICP_PRODUCT_INTEREST) {
						// If old Product Interest contains ICP Product Interest, add to list
						if (objOldAccount.Product_Interest__c.containsIgnoreCase(strICPProdInterest)) {
							// Add ICP Product Interest to list
							list_OldICPProductInterest.add(strICPProdInterest);
						}
					}
				}

				// If new Product Interest is blank, set eligibility to false
				if (String.isNotBlank(objNewAccount.Product_Interest__c)) {
					//	Iterate through ICP Product Interest and check if new Product Interest contains ICP Product Interest
					boolean blnICPProdInterestMatched = false;
					//	Iterate through ICP Product Interest and check if new Product Interest contains ICP Product Interest
					for (String strICPProdInterest : AccountUtil.ICP_PRODUCT_INTEREST) {
						// If new Product Interest contains ICP Product Interest and old Product Interest does not contain ICP Product Interest, add to list
						if (
							objNewAccount.Product_Interest__c.containsIgnoreCase(strICPProdInterest) &&
							(String.isBlank(objOldAccount.Product_Interest__c) || !objOldAccount.Product_Interest__c.containsIgnoreCase(strICPProdInterest))
						) {
							blnICPProdInterestMatched = true;
							break;
						}
					}
					// If new Product Interest is blank, set eligibility to false
					if (!blnICPProdInterestMatched) {
						blnEligible = false;
					}
				} else {
					blnEligible = false;
				}

				// If new Product Interest is blank, set eligibility to false
				if (!set_ICPProdInterest.isEmpty()) {
					// If new Product Interest is blank, set eligibility to false
					if (
						set_ICPProdInterest.size() == 1 &&
						(set_ICPProdInterest.contains(AccountUtil.PROD_INTEREST_INTL_CONT_PAID) || set_ICPProdInterest.contains(AccountUtil.PROD_INTEREST_INTERNATIONAL_CONTRACTOR_PAYMENT_ONBOARDED))
					) {
						blnNotHistoricalData = false;
					}

					// If new Product Interest is blank, set eligibility to false
					if (
						set_ICPProdInterest.size() == 2 &&
						set_ICPProdInterest.contains(AccountUtil.PROD_INTEREST_INTL_CONT_PAID) &&
						set_ICPProdInterest.contains(AccountUtil.PROD_INTEREST_INTERNATIONAL_CONTRACTOR_PAYMENT_ONBOARDED)
					) {
						blnNotHistoricalData = false;
					}

					if (set_ICPProdInterest.contains(AccountUtil.PROD_INTEREST_INTERNATIONAL_CONTRACTOR_PAYMENT_ONBOARDED)) {
						blnICPOnboardedAdded = true;
					}
				}

				// If eligible, create or update cross-sell and upsell opportunities
				if (blnEligible) {
					// Initialize variables for ICP Product Interest processing
					Account objAccount = map_AllAccountMap.get(objNewAccount.Id);
					Opportunity objICPOpp = null;
					boolean blnICPOppClosedWon = false;
					for (Opportunity objOppty : objAccount.Opportunities) {
						// cross-sell and upsell is opened for the Customer Success
						if (
							objOppty.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID &&
							objOppty.StageName != OpportunityUtil.CLOSED_LOST_STAGE &&
							objOppty.StageName != OpportunityUtil.CLOSED_WON_STAGE &&
							objOppty.Payment_Invoice__c == null &&
							objOppty.Upsell_Tier__c != null &&
							objOppty.Upsell_Tier__c.containsIgnoreCase(AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT) &&
							!set_ClosedWonOpptyIDs.contains(objOppty.Id)
						) {
							// Initialize variables for ICP Product Interest processing
							objICPOpp = objOppty;
							// Initialize variables for ICP Product Interest processing
							if (objOppty.Product_Interest__c != null) {
								list_NewICPProductInterest.addAll(objOppty.Product_Interest__c.split(';'));
							}
							// Initialize variables for ICP Product Interest processing
							list_NewICPProductInterest.addAll(list_OldICPProductInterest);
							// Initialize variables for ICP Product Interest processing
							Set<String> set_NewICPProductInterest = new Set<String>(list_NewICPProductInterest);
							// Initialize variables for ICP Product Interest processing
							list_NewICPProductInterest = new List<String>(set_NewICPProductInterest);
							// Initialize variables for ICP Product Interest processing
							objICPOpp.Product_Interest__c = String.join(list_NewICPProductInterest, ';');
							// Initialize variables for ICP Product Interest processing

							if (blnICPOnboardedAdded) {
								objICPOpp.StageName = OpportunityUtil.ONBOARDING_COMPLETED_STAGE;
							}
							map_OpptysToUpdate.put(objICPOpp.Id, objICPOpp);
						}

						// cross-sell and upsell is closed won for the Customer Success
						if (
							objOppty.StageName == OpportunityUtil.CLOSED_WON_STAGE &&
							objOppty.Upsell_Tier__c != null &&
							objOppty.Upsell_Tier__c.containsIgnoreCase(AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT)
						) {
							blnICPOppClosedWon = true;
						}

						// cross-sell and upsell is closed lost except if its from Log a Call
						if (
							objOppty.StageName == OpportunityUtil.CLOSED_LOST_STAGE &&
							objOppty.Upsell_Tier__c != null &&
							objOppty.Upsell_Tier__c.containsIgnoreCase(AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT)
						) {
							if (objOppty.Product_Interest__c != null && objOppty.Product_Interest__c != AccountUtil.ICP_LOGACALL_PI) {
								set_ClosedLostICPProdInterest.addAll(objOppty.Product_Interest__c.split(';'));
							}
						}
					}
					// Set quantity based on Account International Employees. If account value is null, set default value as 1
					Decimal decQuantity = objAccount.International_Contractors__c != null && objAccount.International_Contractors__c > 0 ? objAccount.International_Contractors__c : 1;

					// If no cross-sell and upsell opportunity is found, create new cross-sell and upsell opportunity
					if (objICPOpp == null && !blnICPOppClosedWon && blnNotHistoricalData && !blnICPOnboardedAdded) {
						Opportunity objICPOppToCreate = new Opportunity();
						objICPOppToCreate.AccountId = objAccount.Id;
						objICPOppToCreate.RecordTypeId = OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID;
						objICPOppToCreate.Upsell_Tier__c = AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT;
						objICPOppToCreate.Current_Tier__c = objAccount.Tier__c;
						objICPOppToCreate.International_Contractors__c = decQuantity;

						if (!set_ICPProdInterest.isEmpty() && set_ICPProdInterest.contains(AccountUtil.PROD_INTEREST_INTL_CONT_PAID)) {
							objICPOppToCreate.StageName = OpportunityUtil.CLOSED_WON_STAGE;
							objICPOppToCreate.CloseDate = Date.today();
							objICPOppToCreate.Additional_Opportunity_Services__c = AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT;
						} else {
							objICPOppToCreate.StageName = OpportunityUtil.NEW_STAGE;
						}

						objICPOppToCreate.Name = objAccount.Name + AccountUtil.ICP_OPP_SUFFIX;
						objICPOppToCreate.MRR__c = 0;
						objICPOppToCreate.Amount = 0;
						objICPOppToCreate.Type = AccountUtil.CROSS_SELL;
						List<String> list_ICPProductInterestToInsert = new List<String>();
						for (String strProdInterest : list_NewICPProductInterest) {
							if (!set_ClosedLostICPProdInterest.contains(strProdInterest)) {
								list_ICPProductInterestToInsert.add(strProdInterest);
							}
						}
						if (!list_ICPProductInterestToInsert.isEmpty()) {
							objICPOppToCreate.Product_Interest__c = String.join(list_ICPProductInterestToInsert, ';');
							//fixed bug where ICPs are getting created with no product interest
							list_OpptysToInsert.add(objICPOppToCreate);
						}
					}
				}

				// If not eligible, close all cross-sell and upsell opportunities
				List<String> list_EORProductInterestToUpdateAcc = new List<String>();
				Account objAccountToUpdate = new Account();
				// Initialize variables for ICP Product Interest processing
				if (String.isNotBlank(objNewAccount.Product_Interest__c)) {
					//	Iterate through ICP Product Interest and check if new Product Interest contains ICP Product Interest
					for (String strEORProdInterest : AccountUtil.EOR_PRODUCT_INTEREST) {
						// If new Product Interest contains ICP Product Interest and old Product Interest does not contain ICP Product Interest, add to list
						if (objNewAccount.Product_Interest__c.containsIgnoreCase(strEORProdInterest)) {
							list_EORProductInterestToUpdateAcc.add(strEORProdInterest);
						}
					}
				}

				// Initialize variables for ICP Product Interest processing
				if (map_AccountsToUpdate.containsKey(objNewAccount.Id)) {
					objAccountToUpdate = map_AccountsToUpdate.get(objNewAccount.Id);
				}

				// Initialize variables for ICP Product Interest processing
				if (!list_EORProductInterestToUpdateAcc.isEmpty()) {
					// Initialize variables for ICP Product Interest processing
					objAccountToUpdate.Id = objNewAccount.Id;
					objAccountToUpdate.Product_Interest__c = String.join(list_EORProductInterestToUpdateAcc, ';');
					map_AccountsToUpdate.put(objAccountToUpdate.Id, objAccountToUpdate);
				} else {
					// Initialize variables for ICP Product Interest processing
					objAccountToUpdate.Id = objNewAccount.Id;
					objAccountToUpdate.Product_Interest__c = '';
					map_AccountsToUpdate.put(objAccountToUpdate.Id, objAccountToUpdate);
				}
			}
		}
	}
	/**
	 * @Description : Processing Employer of Record Interest - Creating/Updating Company or cross-sell and upsell opportunities
	 * @Param       : map_NewAccounts - Trigger.NewMap
	 * @Param       : map_OldAccounts - Trigger.NewMap
	 * @Return      : void
	 **/
	public void processInternationalPayroll(Map<Id, Account> map_NewAccounts, Map<Id, Account> map_OldAccounts) {
		for (Account objNewAccount : map_NewAccounts.values()) {
			Account objOldAccount = map_OldAccounts.get(objNewAccount.Id);
			// Boolean variable to Indicate if company already has Employer of Record
			Boolean blnCompanyInternationalPayroll = String.isNotBlank(objNewAccount.Additional_Services__c) && objNewAccount.Additional_Services__c.contains(AccountUtil.EMPLOYER_OF_RECORD);
			List<String> list_NewEORProductInterest = new List<String>();
			List<String> list_OldEORProductInterest = new List<String>();
			// check if there is a change in Product Interest or Product Interest Countries
			if (
				objOldAccount != null &&
				(objNewAccount.Product_Interest__c != objOldAccount.Product_Interest__c ||
				objNewAccount.Product_Interest_Countries__c != objOldAccount.Product_Interest_Countries__c) &&
				internationalPayrollInterestEligible(objNewAccount) &&
				map_AllAccountMap.containsKey(objNewAccount.Id)
			) {
				Boolean blnNewEORAdded = false;
				Boolean blnNewCountryAdded = false;
				Account objAccount = map_AllAccountMap.get(objNewAccount.Id);
				// Company and cross-sell and upsell opportunity variables
				Opportunity objCompanyOppty = null;
				Opportunity objTierUpsellOpp = null;
				Opportunity objIntlPayrollTierUpsellOpp = null;

				if (String.isNotBlank(objNewAccount.Product_Interest__c)) {
					for (String strEORProdInterest : AccountUtil.EOR_PRODUCT_INTEREST) {
						if (
							objNewAccount.Product_Interest__c.containsIgnoreCase(strEORProdInterest) &&
							(String.isBlank(objOldAccount.Product_Interest__c) || !objOldAccount.Product_Interest__c.containsIgnoreCase(strEORProdInterest))
						) {
							list_NewEORProductInterest.add(strEORProdInterest);
							blnNewEORAdded = true;
						}
					}
				}

				if (objNewAccount.Product_Interest_Countries__c != objOldAccount.Product_Interest_Countries__c) {
					blnNewCountryAdded = true;
				}

				if (String.isNotBlank(objOldAccount.Product_Interest__c)) {
					for (String strEORProdInterest : AccountUtil.EOR_PRODUCT_INTEREST) {
						if (objOldAccount.Product_Interest__c.containsIgnoreCase(strEORProdInterest)) {
							list_oldEORProductInterest.add(strEORProdInterest);
						}
					}
				}

				for (Opportunity objOppty : objAccount.Opportunities) {
					// cross-sell and upsell is opened for the sales
					if (String.isNotBlank(strInternationalPayrollOnboardingTeam) && strInternationalPayrollOnboardingTeam.contains('Sales')) {
						// if open non-invoiced company opportunity is found, append International payoll to existing company opportunity
						if (objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID && objOppty.Payment_Invoice__c == null) {
							objCompanyOppty = objOppty;
						} else if (
							objOppty.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID &&
							objOppty.StageName != OpportunityUtil.CLOSED_WON_STAGE &&
							objOppty.StageName != OpportunityUtil.CLOSED_LOST_STAGE &&
							objOppty.Payment_Invoice__c == null
						) {
							// if open non-invoiced cross-sell and upsell opportunity is found, append Employer of Record to existing cross-sell and upsell opportunity
							objTierUpsellOpp = objOppty;
						}
					} else if (String.isNotBlank(strInternationalPayrollOnboardingTeam) && strInternationalPayrollOnboardingTeam.contains('Customer Success')) {
						// cross-sell and upsell is opened for the Customer Success
						if (
							objOppty.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID &&
							objOppty.StageName != OpportunityUtil.CLOSED_WON_STAGE &&
							objOppty.StageName != OpportunityUtil.CLOSED_LOST_STAGE &&
							objOppty.Payment_Invoice__c == null &&
							objOppty.Upsell_Tier__c != null &&
							objOppty.Upsell_Tier__c.containsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD) &&
							!set_ClosedWonOpptyIDs.contains(objOppty.Id)
						) {
							objIntlPayrollTierUpsellOpp = objOppty;
						}
					}
				}

				// Set quantity based on Account International Employees. If account value is null, set default value as 1
				Decimal decQuantity = objAccount.International_Employees__c != null && objAccount.International_Employees__c > 0 ? objAccount.International_Employees__c : 1;
				// cross-sell and upsell is opened for the sales
				if (String.isNotBlank(strInternationalPayrollOnboardingTeam) && strInternationalPayrollOnboardingTeam.contains('Sales')) {
					if (objCompanyOppty != null) {
						String strOpptyAdditionalService = objCompanyOppty.Additional_Opportunity_Services__c;
						Boolean blnClosedLost = false;
						if (objCompanyOppty.StageName == OpportunityUtil.CLOSED_LOST_STAGE) {
							// opportunity stage is closed lost  - reopen the opportunity and refresh merchandising data
							objCompanyOppty.StageName = OpportunityUtil.MQL_STAGE;
							objCompanyOppty.Stage_Detail__c = null;
							objCompanyOppty.Stage_Detail_2__c = null;
							objCompanyOppty.NumberOfEmployees__c = objAccount.Number_of_Active_Employees__c;
							objCompanyOppty.Number_of_Contractors__c = objAccount.Number_of_Active_Contractors__c;
							objCompanyOppty.International_Contractors__c = objAccount.International_Contractors__c;

							objCompanyOppty.Additional_Opportunity_Services__c = objAccount.Additional_Services__c;
							objCompanyOppty.Sold_By__c = objAccount.Sold_By__c;
							//  re-trigger discount calculation
							set_DiscountAccountIds.add(objAccount.Id);
							sendCustomNotification(
								objCompanyOppty.Name + ' was reopened from Closed Lost',
								'Opportunity has been updated because because there is Employer of Record interest',
								objCompanyOppty.OwnerId,
								objInternationalPayrollNotify.Id,
								objCompanyOppty.Id
							);
							blnClosedLost = true;
						}

						objCompanyOppty.International_Employees__c = decQuantity;
						// Append Employer of Record to Additional Opportunity Services
						if (String.isBlank(objCompanyOppty.Additional_Opportunity_Services__c)) {
							objCompanyOppty.Additional_Opportunity_Services__c = AccountUtil.EMPLOYER_OF_RECORD;
						} else if (!objCompanyOppty.Additional_Opportunity_Services__c.contains(AccountUtil.EMPLOYER_OF_RECORD)) {
							objCompanyOppty.Additional_Opportunity_Services__c += ';' + AccountUtil.EMPLOYER_OF_RECORD;
						}

						// send notification when including Employer of Record to open payroll opportunity
						if (!blnClosedLost && (String.isBlank(strOpptyAdditionalService) || !strOpptyAdditionalService.containsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD))) {
							sendCustomNotification(
								objCompanyOppty.Name + ' was updated to include Employer of Record',
								'Opportunity has been updated because because there is Employer of Record interest',
								objCompanyOppty.OwnerId,
								objInternationalPayrollNotify.Id,
								objCompanyOppty.Id
							);
						}
						map_OpptysToUpdate.put(objCompanyOppty.Id, objCompanyOppty);
					} else if (objTierUpsellOpp != null) {
						// if open cross-sell and upsell opportunity exists, calculate new MRR and update the amount
						// update cross-sell and upsell only if upsell tier does not contain Employer of Record
						if (String.isNotBlank(objTierUpsellOpp.Upsell_Tier__c) && !objTierUpsellOpp.Upsell_Tier__c.containsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)) {
							objTierUpsellOpp.Additional_Opportunity_Services__c = objAccount.Additional_Services__c;
							objTierUpsellOpp.Upsell_Tier__c = appendInternationalPayrollToUpsellTier(objTierUpsellOpp.Upsell_Tier__c, objAccount.Additional_Services__c);

							objTierUpsellOpp.International_Employees__c = decQuantity;
							// Append Employer of Record to Additional Opportunity Services
							if (String.isBlank(objTierUpsellOpp.Additional_Opportunity_Services__c)) {
								objTierUpsellOpp.Additional_Opportunity_Services__c = AccountUtil.EMPLOYER_OF_RECORD;
							} else if (!objTierUpsellOpp.Additional_Opportunity_Services__c.contains(AccountUtil.EMPLOYER_OF_RECORD)) {
								objTierUpsellOpp.Additional_Opportunity_Services__c += ';' + AccountUtil.EMPLOYER_OF_RECORD;
							}

							// Get Accountant Discount if account is reward eligible
							Decimal decAccountantDiscount = 0;

							if (objAccount.Sold_By__c != null && objAccount.Reward_Eligible__c && map_AllAccountMap.containsKey(objAccount.Sold_By__c)) {
								decAccountantDiscount = map_AllAccountMap.get(objAccount.Sold_By__c).Discount__c;
							}

							// if upsell tier is Employer of Record then use upsell tier for the amount calculation or else use Additional_Opportunity_Services__c
							String strAdditionalServicesToCalculateAmount = '';
							if (objTierUpsellOpp.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)) {
								strAdditionalServicesToCalculateAmount = AccountUtil.EMPLOYER_OF_RECORD;
							} else {
								strAdditionalServicesToCalculateAmount = objTierUpsellOpp.Additional_Opportunity_Services__c;
							}
							// Calculate New MRR
							Decimal decSalesPrice = OpportunityUtil.calculateMRROppNew(
								objTierUpsellOpp.NumberOfEmployees__c,
								objTierUpsellOpp.Number_of_Contractors__c,
								objTierUpsellOpp.International_Employees__c,
								objTierUpsellOpp.International_Contractors__c,
								strAdditionalServicesToCalculateAmount,
								decAccountantDiscount,
								objAccount.Premium_Tier_Discount__c,
								objTierUpsellOpp.Pricebook2?.Name
							);
							// Re-calculate Amount based on new MRR and add to map of opportunities to update
							objTierUpsellOpp.Amount = decSalesPrice - (objTierUpsellOpp.MRR__c != null ? objTierUpsellOpp.MRR__c : 0);

							sendCustomNotification(
								objTierUpsellOpp.Name + ' was updated to include Employer of Record',
								'Opportunity has been updated because because there is Employer of Record interest',
								objTierUpsellOpp.OwnerId,
								objInternationalPayrollNotify.Id,
								objTierUpsellOpp.Id
							);

							map_OpptysToUpdate.put(objTierUpsellOpp.Id, objTierUpsellOpp);
						}
					} else {
						// if no eligible company opp/cross-sell and upsell opp is found, create a new cross-sell and upsell opportunity
						list_OpptysToInsert.add(
							new Opportunity(
								AccountId = objAccount.Id,
								RecordTypeId = OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID,
								Upsell_Tier__c = appendInternationalPayrollToUpsellTier(objAccount.Tier__c, objAccount.Additional_Services__c),
								Current_Tier__c = objAccount.Tier__c,
								StageName = OpportunityUtil.QUALIFIED_STAGE,
								Name = objAccount.Name + TIER_UPSELL_OPP_SUFFIX
							)
						);
					}
				} else if (String.isNotBlank(strInternationalPayrollOnboardingTeam) && strInternationalPayrollOnboardingTeam.contains('Customer Success') && (blnNewEORAdded || blnNewCountryAdded)) {
					// cross-sell and upsell is opened for the Customer Success
					if (objIntlPayrollTierUpsellOpp == null) {
						//if there is no existing Open cross-sell and upsell Opportunity with Upsell Tier = Employer of Record
						list_OpptysToInsert.add(
							new Opportunity(
								AccountId = objAccount.Id,
								RecordTypeId = OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID,
								Upsell_Tier__c = 'Employer of Record',
								Current_Tier__c = objAccount.Tier__c,
								International_Employees__c = decQuantity,
								StageName = OpportunityUtil.NEW_STAGE,
								Name = objAccount.Name + UPSELL_OPP_SUFFIX,
								MRR__c = 0,
								Type = AccountUtil.CROSS_SELL,
								Additional_Opportunity_Services__c = AccountUtil.EMPLOYER_OF_RECORD,
								Product_Interest__c = String.join(list_NewEORProductInterest, ';'),
								Product_Interest_Countries__c = objNewAccount.Product_Interest_Countries__c
							)
						);
					} else {
						list_NewEORProductInterest.addAll(list_OldEORProductInterest);
						objIntlPayrollTierUpsellOpp.Product_Interest__c = String.join(list_NewEORProductInterest, ';');
						objIntlPayrollTierUpsellOpp.Product_Interest_Countries__c = objNewAccount.Product_Interest_Countries__c;
						map_OpptysToUpdate.put(objIntlPayrollTierUpsellOpp.Id, objIntlPayrollTierUpsellOpp);
					}
				}
			}
		}
	}

	/**
	 * @Description : Append Employer of Record. Also consider including Priority Support if account has Priority Support
	 * @Param       : Queried Account
	 * @Param       : Additional Services from Account or Opportunity
	 * @Return      : Returns new upsell tier with priority support and Employer of Record
	 **/
	public static String appendInternationalPayrollToUpsellTier(String strUpsellTier, String strAdditionalServices) {
		String strNewUpsellTier = strUpsellTier;
		if (String.isNotBlank(strInternationalPayrollOnboardingTeam) && strInternationalPayrollOnboardingTeam.contains('Sales')) {
			strNewUpsellTier = strUpsellTier + ' and ' + AccountUtil.EMPLOYER_OF_RECORD;
			if (
				strUpsellTier == AccountUtil.PLUS_TIER &&
				String.isNotBlank(strAdditionalServices) &&
				strAdditionalServices.contains(AccountUtil.ADD_SERVICES_PRIORITY_SUPPORT) &&
				!strNewUpsellTier.contains(AccountUtil.PRIORITY_SUPPORT)
			) {
				strNewUpsellTier = strUpsellTier + ' with ' + AccountUtil.PRIORITY_SUPPORT + ' and ' + AccountUtil.EMPLOYER_OF_RECORD;
			}
		}
		return strNewUpsellTier;
	}

	/**
	 * @Description : Deciding whether Product Interest and Countries field are populated and checks with validity of selected countries
	 * @Param       : Account - Trigger.New
	 * @Return      : Returns if account is eligible to add Employer of Record
	 **/
	public static Boolean internationalPayrollInterestEligible(Account objAccount) {
		// Set Default eligibility to true
		Boolean blnEligible = true;

		if (String.isNotBlank(objAccount.Product_Interest__c)) {
			boolean blnEORProdInterestMatched = false;
			for (String strEORProdInterest : AccountUtil.EOR_PRODUCT_INTEREST) {
				if (objAccount.Product_Interest__c.containsIgnoreCase(strEORProdInterest)) {
					blnEORProdInterestMatched = true;
					break;
				}
			}
			if (!blnEORProdInterestMatched) {
				blnEligible = false;
			}
		} else {
			blnEligible = false;
		}

		// Boolean variable to Indicate if company already has Employer of Record
		Boolean blnCompanyInternationalPayroll = String.isNotBlank(objAccount.Additional_Services__c) && objAccount.Additional_Services__c.contains(AccountUtil.EMPLOYER_OF_RECORD);
		// If company already has Employer of Record, set eligible to false
		if (blnCompanyInternationalPayroll) {
			blnEligible = false;
		} else if (String.isBlank(objAccount.Product_Interest__c) || String.isBlank(objAccount.Product_Interest_Countries__c)) {
			// if interest or interest countries are blank, set eligible to false
			blnEligible = false;
		} else if (String.isNotBlank(objAccount.Product_Interest__c) && !objAccount.Product_Interest__c.containsIgnoreCase(AccountUtil.PROD_INTEREST_INTERNATIONAL_PAYROLL)) {
			// If Product Interest does not contain Employer of Record
			blnEligible = false;
		} else if (String.isNotBlank(objAccount.Product_Interest_Countries__c)) {
			// Country should be eligible
			Boolean blnCountryEligible = false;
			for (String strCountry : objAccount.Product_Interest_Countries__c.split(';')) {
				for (String strKey : map_InternationalPayrollCountries.keySet()) {
					if (map_InternationalPayrollCountries.get(strKey).Label == strCountry) {
						blnCountryEligible = true;
						break;
					}
				}
			}
			blnEligible = blnCountryEligible;
		}
		return blnEligible;
	}

	/**
	 * @Description : On CSM change, set fields
	 * @Param       : Account - Trigger.New, Account - Trigger.Old
	 * @Return      : void
	 **/
	public void setFieldsOnCSMChange(Account objNewAccount, Account objOldAccount) {
		if (objOldAccount != null && objNewAccount.CSM_Owner__c != objOldAccount.CSM_Owner__c) {
			objNewAccount.Send_to_Catalyst__c = true;
		}
	}

	/**
	 * @Description : Query account contacts by zp user roles
	 * @Param       : Set of accountIds, List of roles
	 * @Return      : Map of AccountId to list of contacts
	 **/
	private static Map<Id, Contact> queryContactsByAccountIdsAndRoles(Set<Id> set_AccountIds, List<String> list_Roles) {
		Map<Id, Contact> map_contactIdToContactRec = new Map<Id, Contact>();
		String strContactQuery = 'SELECT Customer_Subscriptions__c, AccountId, Inactive_ZP_User__c, ZP_User_Id__c,ZP_User_Role__c FROM Contact ';
		strContactQuery += 'WHERE Inactive_ZP_User__c = False AND AccountId IN :set_accountSubscriptionsChanged AND ZP_User_Role__c INCLUDES (';
		for (String strRole : list_Roles) {
			strContactQuery += '\'' + strRole + '\',';
		}
		strContactQuery = strContactQuery.removeEnd(',');
		strContactQuery += ')';
		for (Contact objContact : Database.query(strContactQuery)) {
			map_contactIdToContactRec.put(objContact.Id, objContact);
		}
		return map_contactIdToContactRec;
	}

	/**
	 * @Description : Update HI Owner on Account based on Aligned Rep from User Account Teams or send to routing rool
	 * @Param       : Account - objNewAccount
	 * @Param       : Account - objOldAccount
	 * @Return      : Set HI Owner on Account
	 **/
	public void setHIOwner(Account objNewAccount, Account objOldAccount) {
		// Get lower and uppper threshold values from custom labels
		String strBrokerThreshold = System.Label.Broker_Threshold;
		String strNewPlanThreshold = System.Label.New_Plan_Threshold;
		List<String> list_RoutingTypes = new List<String>{ strBrokerThreshold, strNewPlanThreshold };

		Integer intBrokerLowerThreshold = Integer.valueOf(strBrokerThreshold.split('/')[0]);
		Integer intBrokerHigherThreshold = Integer.valueOf(strBrokerThreshold.split('/')[1]);
		Integer intNewPlanLowerThreshold = Integer.valueOf(strNewPlanThreshold.split('/')[0]);
		Integer intNewPlanHigherThreshold = Integer.valueOf(strNewPlanThreshold.split('/')[1]);

		// initialize boolean variables that trigger HI owner routing
		// medical deductions changes to true
		Boolean blnDeductionsChange = objOldAccount != null && (objNewAccount.Medical_Deductions__c != objOldAccount.Medical_Deductions__c && objNewAccount.Medical_Deductions__c == true);
		Boolean blnActiveEmployeeIncrease = false;
		Boolean blnActiveEmployeeDecrease = false;
		Boolean blnEmployeeIncrease = false;
		Boolean blnEmployeeDecrease = false;
		String strTypeOfEmployeeChange = '';

		for (String strRoutingType : list_RoutingTypes) {
			Integer intLowerThreshold = strRoutingType == strBrokerThreshold ? intBrokerLowerThreshold : intNewPlanLowerThreshold;
			Integer intHigherThreshold = strRoutingType == strBrokerThreshold ? intBrokerHigherThreshold : intNewPlanHigherThreshold;

			// number of employees increase from lower threshold to higher threshold
			blnEmployeeIncrease =
				objOldAccount != null &&
				objNewAccount.NumberOfEmployees != objOldAccount.NumberOfEmployees &&
				objNewAccount.ZP_Company_Overall_Status__c == AccountUtil.ACCOUNT_OVERALL_STATUS_NEW &&
				objNewAccount.Number_of_Active_Employees__c != null &&
				objNewAccount.Number_of_Active_Employees__c > 0 &&
				objNewAccount.NumberOfEmployees != null &&
				(objOldAccount.NumberOfEmployees == null ||
				objOldAccount.NumberOfEmployees <= intLowerThreshold) &&
				objNewAccount.NumberOfEmployees >= intHigherThreshold;
			// number of active employees increase from lower threshold to higher threshold
			blnActiveEmployeeIncrease =
				objOldAccount != null &&
				objNewAccount.Number_of_Active_Employees__c != objOldAccount.Number_of_Active_Employees__c &&
				(objNewAccount.ZP_Company_Overall_Status__c == AccountUtil.ACCOUNT_OVERALL_STATUS_ACTIVE ||
				objNewAccount.ZP_Company_Overall_Status__c == AccountUtil.ACCOUNT_OVERALL_STATUS_NEW) &&
				objNewAccount.Number_of_Active_Employees__c != null &&
				(objOldAccount.Number_of_Active_Employees__c == null ||
				objOldAccount.Number_of_Active_Employees__c <= intLowerThreshold) &&
				objNewAccount.Number_of_Active_Employees__c >= intHigherThreshold;
			// number of employees reduces from higher threshold to lower threshold
			blnEmployeeDecrease =
				objOldAccount != null &&
				objNewAccount.NumberOfEmployees != objOldAccount.NumberOfEmployees &&
				objNewAccount.ZP_Company_Overall_Status__c == AccountUtil.ACCOUNT_OVERALL_STATUS_NEW &&
				objNewAccount.Number_of_Active_Employees__c != null &&
				objNewAccount.Number_of_Active_Employees__c > 0 &&
				objOldAccount.NumberOfEmployees != null &&
				objOldAccount.NumberOfEmployees >= intHigherThreshold &&
				(objNewAccount.NumberOfEmployees == null ||
				objNewAccount.NumberOfEmployees <= intLowerThreshold);
			// number of active employees reduces from higher threshold to lower threshold
			blnActiveEmployeeDecrease =
				objOldAccount != null &&
				objNewAccount.Number_of_Active_Employees__c != objOldAccount.Number_of_Active_Employees__c &&
				(objNewAccount.ZP_Company_Overall_Status__c == AccountUtil.ACCOUNT_OVERALL_STATUS_ACTIVE ||
				objNewAccount.ZP_Company_Overall_Status__c == AccountUtil.ACCOUNT_OVERALL_STATUS_NEW) &&
				objOldAccount.Number_of_Active_Employees__c != null &&
				objOldAccount.Number_of_Active_Employees__c >= intHigherThreshold &&
				(objNewAccount.Number_of_Active_Employees__c == null ||
				objNewAccount.Number_of_Active_Employees__c <= intLowerThreshold);

			// Set type of employee change
			if (blnEmployeeIncrease || blnActiveEmployeeIncrease || blnEmployeeDecrease || blnActiveEmployeeDecrease) {
				if (strRoutingType == strNewPlanThreshold) {
					strTypeOfEmployeeChange = 'New Plan';
				} else if (strRoutingType == strBrokerThreshold) {
					strTypeOfEmployeeChange = 'Broker';
				}
				break;
			}
		}

		// active benefits changing from true to false
		Boolean blnActiveBenefitsChange = objOldAccount != null && (objNewAccount.HI_Active_Benefits__c != objOldAccount.HI_Active_Benefits__c && objNewAccount.HI_Active_Benefits__c == false);
		// overall status changing from suspended to anything else
		Boolean blnSuspendedStatusChange =
			objOldAccount != null &&
			String.isNotBlank(objNewAccount.ZP_Company_Overall_Status__c) &&
			String.isNotBlank(objOldAccount.ZP_Company_Overall_Status__c) &&
			objNewAccount.ZP_Company_Overall_Status__c != objOldAccount.ZP_Company_Overall_Status__c &&
			(objOldAccount.ZP_Company_Overall_Status__c == AccountUtil.ACCOUNT_OVERALL_STATUS_SUSPENDED &&
			objNewAccount.ZP_Company_Overall_Status__c != AccountUtil.ACCOUNT_OVERALL_STATUS_SUSPENDED);
		Boolean blnNewToActiveStatusChange =
			objOldAccount != null &&
			String.isNotBlank(objNewAccount.ZP_Company_Overall_Status__c) &&
			String.isNotBlank(objOldAccount.ZP_Company_Overall_Status__c) &&
			objNewAccount.ZP_Company_Overall_Status__c != objOldAccount.ZP_Company_Overall_Status__c &&
			(objOldAccount.ZP_Company_Overall_Status__c == AccountUtil.ACCOUNT_OVERALL_STATUS_NEW &&
			objNewAccount.ZP_Company_Overall_Status__c == AccountUtil.ACCOUNT_OVERALL_STATUS_ACTIVE);
		// filing state changing
		Boolean blnFilingStateChange = objOldAccount != null && objNewAccount.BillingStateCode != objOldAccount.BillingStateCode;
		// hi routing reason changing
		Boolean blnManualRouting =
			objOldAccount != null &&
			objNewAccount.HI_Routing_Reason__c != objOldAccount.HI_Routing_Reason__c &&
			String.isNotBlank(objNewAccount.HI_Routing_Reason__c) &&
			objNewAccount.HI_Routing_Reason__c.containsIgnoreCase(AccountUtil.MANUAL_HI_OWNER_ROUTING);

		// Setting HI Owner based on Aligned Rep
		if (
			blnManualRouting ||
			blnActiveEmployeeIncrease ||
			blnActiveEmployeeDecrease ||
			blnEmployeeIncrease ||
			blnEmployeeDecrease ||
			blnActiveBenefitsChange ||
			blnSuspendedStatusChange ||
			blnNewToActiveStatusChange ||
			blnFilingStateChange ||
			blnDeductionsChange
		) {
			Boolean blnBenefitsOpp = false;
			// assume aligned rep is not found
			Boolean blnAlignedRepFound = false;
			Boolean blnSendForRouting = false;
			// assign small biz rep and new plan rep based on which field changes on account
			String strSmallBizRep = '';
			String strMidMarketRep = '';
			String strRoutingReason = '';
			// type prefix before routing reason
			String strType = 'New Plan';
			// Boolean flag to store primary criteria - the ones that don't require Intent check
			Boolean blnPrimaryCriteria = blnActiveBenefitsChange || blnDeductionsChange;

			// set default hi owner unavailable to true
			Boolean blnHIOwnerUnavailable = true;
			Boolean blnHIOwnerUnavailableDeductionsChange = true;

			if (objNewAccount.HI_Owner__c != null && map_Users?.containsKey(objNewAccount.HI_Owner__c)) {
				User objHIOwner = map_Users.get(objNewAccount.HI_Owner__c);
				if (objHIOwner != null && objHIOwner.IsActive && String.isNotBlank(objHIOwner?.UserRole?.Name)) {
					if (HI_SALES_ALL_ROLES.containsIgnoreCase(objHIOwner.UserRole.Name)) {
						blnHIOwnerUnavailable = false;
					}
					if (ROLES_SKIP_HI_ROUTING_DEDUCTIONS_CHANGE.containsIgnoreCase(objHIOwner.UserRole.Name)) {
						blnHIOwnerUnavailableDeductionsChange = false;
					}
				}
			}

			Boolean blnOpenHIOpp = false;
			Boolean blnROEExceptionFound = false;
			// flag to indicate if account has open benefits opportunities owned by non sales
			Boolean blnOpenOppOwnedByNonSales = false;
			// check if account has open benefit opportunities, if yes do not set HI Owner
			Account objAcc = map_AllAccountMap.containsKey(objNewAccount.Id) ? map_AllAccountMap.get(objNewAccount.Id) : null;
			Opportunity objLatestOppty = null;
			if (objAcc != null && !objAcc.Opportunities.isEmpty()) {
				objLatestOppty = objAcc.Opportunities.get(0);
				for (Opportunity objOppty : objAcc.Opportunities) {
					if (OpportunityUtil.set_BenefitRTChangeEmployees.contains(objOppty.RecordTypeId)) {
						if (objOppty.Type == OpportunityUtil.OPPTY_TYPE_RENEWAL_BYB) {
							continue;
						}
						String strOwnerRole = objOppty.Owner?.UserRole?.Name;
						blnBenefitsOpp = true;
						// Check if there is a benefit oppty created in last 90 days which is closed won. If yes, do not route HI Owner
						if (objOppty.CloseDate != null && objOppty.CloseDate > System.today().addDays(-90) && objOppty.IsWon) {
							return;
						}
						// Check if there is open benefits opportunity, if found, do not route HI Owner
						if (!objOppty.IsClosed && !blnManualRouting) {
							blnOpenHIOpp = true;
						}
						// Check if ROE Exception is not blank on benefits opportunity
						if (!blnManualRouting && (objOppty.ROE_Exception__c == AccountUtil.ROE_EXCEPTION_REQUESTED || objOppty.ROE_Exception__c == AccountUtil.ROE_EXCEPTION_APPROVED)) {
							blnROEExceptionFound = true;
						}
						// If opp is open and owned by non sales, set flag to true
						if (!objOppty.IsClosed && (String.isBlank(strOwnerRole) || (strOwnerRole != null && !HI_SALES_ALL_ROLES.containsIgnoreCase(strOwnerRole)))) {
							blnOpenOppOwnedByNonSales = true;
						}
					}
				}
			}
			// If HI Owner is active and there are open HI opportunities - Keep existing HI Owner
			if (blnOpenHIOpp && !blnHIOwnerUnavailable) {
				return;
			}

			if (blnDeductionsChange && !blnHIOwnerUnavailable && !blnHIOwnerUnavailableDeductionsChange) {
				return;
			}

			// If latest oppty is BOR and HI Benefits is true - stop routing
			if (
				!blnManualRouting &&
				((objLatestOppty != null && objNewAccount.HI_Active_Benefits__c && objLatestOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID) || objNewAccount.Big_Desk_Pilot_Customer__c)
			) {
				return;
			}

			// if medical deductions change, reps to assign will be broker reps
			if (objNewAccount.Medical_Deductions__c || objNewAccount.Benefits_Effective_Date__c != null) {
				strType = 'Broker';
			}

			// determine hi intent if account owner or employees or overall status changes
			if (
				blnSuspendedStatusChange ||
				blnNewToActiveStatusChange ||
				blnActiveEmployeeIncrease ||
				blnActiveEmployeeDecrease ||
				blnEmployeeIncrease ||
				blnEmployeeDecrease ||
				blnFilingStateChange
			) {
				Boolean blnIntent =
					objNewAccount.Medical_Deductions__c ||
					objNewAccount.HI_Owner__c != null ||
					blnBenefitsOpp ||
					objNewAccount.Benefits_Effective_Date__c != null ||
					objNewAccount.ZP_Company_Overall_Status__c == AccountUtil.ACCOUNT_OVERALL_STATUS_ACTIVE;
				// if there is no intent, do not route HI Owner
				if (blnIntent == false && blnPrimaryCriteria == false) {
					return;
				}
			}

			// if employee changes - type of HI and type of employee change don't match - do not route HI Owner
			if (blnEmployeeIncrease || blnActiveEmployeeIncrease || blnEmployeeDecrease || blnActiveEmployeeDecrease) {
				if (strType == 'Broker' && strTypeOfEmployeeChange != 'Broker' && blnPrimaryCriteria == false) {
					return;
				} else if (strType == 'New Plan' && strTypeOfEmployeeChange != 'New Plan' && blnPrimaryCriteria == false) {
					return;
				}
			}

			// set routing reason based on boolean variables
			if (blnEmployeeIncrease || blnEmployeeDecrease) {
				strRoutingReason = 'Number of Employees';
			} else if (blnActiveEmployeeIncrease || blnActiveEmployeeDecrease) {
				strRoutingReason = 'Number of Active Employees';
			} else if (blnActiveBenefitsChange) {
				strRoutingReason = 'HI Active Benefits';
			} else if (blnSuspendedStatusChange || blnNewToActiveStatusChange) {
				strRoutingReason = 'Overall Status';
			} else if (blnFilingStateChange) {
				strRoutingReason = 'Filing State';
			} else if (blnDeductionsChange) {
				strRoutingReason = 'Has Benefits Deductions';
			} else if (blnManualRouting) {
				strRoutingReason = AccountUtil.MANUAL_HI_OWNER_ROUTING;
			}

			// If overall status changes from Suspended and HI owner is active - do not route HI Owner
			if (blnSuspendedStatusChange && !blnHIOwnerUnavailable) {
				return;
			}

			// When filing state changes, trigger routing only when any open opp is found and owned by non-sales rep
			if (blnFilingStateChange && !blnOpenOppOwnedByNonSales) {
				return;
			}

			// If filing state is changed by insurance quote trigger - do not trigger routing again in account trigger
			if (blnFilingStateChange && HIQuoteTriggerHelper.blnHIOwnerRouting) {
				return;
			}

			// override type of HI if mannually set by user
			if (blnManualRouting && String.isNotBlank(objNewAccount.HI_Routing_Reason__c)) {
				if (objNewAccount.HI_Routing_Reason__c.containsIgnoreCase(AccountUtil.HI_TYPE_NEW_PLAN)) {
					strType = AccountUtil.HI_TYPE_NEW_PLAN;
				} else if (objNewAccount.HI_Routing_Reason__c.containsIgnoreCase(AccountUtil.HI_TYPE_BROKER)) {
					strType = AccountUtil.HI_TYPE_BROKER;
				}
				// If routing reason contains Small Biz - do not check for alignment and send to RingLead
				if (objNewAccount.HI_Routing_Reason__c.containsIgnoreCase('SBIZ')) {
					blnSendForRouting = true;
				}
			}
			if (!blnSendForRouting) {
				// Look for aligned reps only if overall status is New
				if (objNewAccount.ZP_Company_Overall_Status__c == AccountUtil.ACCOUNT_OVERALL_STATUS_NEW) {
					// If existing HI Owner is active sales person - do not look for aligned rep
					if (!blnHIOwnerUnavailable && !blnManualRouting) {
						return;
					}
					if (map_UserAccountTeamMembers.containsKey(objNewAccount.OwnerId)) {
						// Iterate over account team members
						for (UserAccountTeamMember objAccTeamMember : map_UserAccountTeamMembers.get(objNewAccount.OwnerId)) {
							// Assign HI Owner based on type and Role Names
							if (
								strType == AccountUtil.HI_TYPE_BROKER &&
								objAccTeamMember.TeamMemberRole == AccountUtil.HI_BROKER_REP ||
								strType == AccountUtil.HI_TYPE_NEW_PLAN &&
								objAccTeamMember.TeamMemberRole == AccountUtil.HI_NEW_PLAN_REP
							) {
								// update hi routing reason based on current value of HI Owner field
								if (objNewAccount.HI_Owner__c == null) {
									objNewAccount.HI_Routing_Reason__c = strType + ' - ' + strRoutingReason + ' - HI Owner null value updated to aligned ' + objAccTeamMember.TeamMemberRole;
									objNewAccount.Skip_Validation_For_Routing__c = true;
									AccountUtil.blnHIOwnerRouting = true;
								} else if (objNewAccount.HI_Owner__c != objAccTeamMember.UserId) {
									objNewAccount.HI_Routing_Reason__c = strType + ' - ' + strRoutingReason + ' - HI Owner replaced and updated to aligned ' + objAccTeamMember.TeamMemberRole;
									objNewAccount.Skip_Validation_For_Routing__c = true;
									AccountUtil.blnHIOwnerRouting = true;
								}

								objNewAccount.HI_Owner__c = objAccTeamMember.UserId;
								blnAlignedRepFound = true;
								break;
							}
						}
					}
					// If no algined rep is found, send to RingLead for routing
					if (!blnAlignedRepFound) {
						blnSendForRouting = true;
					}
				} else if (objNewAccount.ZP_Company_Overall_Status__c == AccountUtil.ACCOUNT_OVERALL_STATUS_ACTIVE) {
					// If overall status is active - do not check for alignment and send for routing before checking few conditions
					if (
						blnManualRouting ||
						objNewAccount.Medical_Deductions__c ||
						objNewAccount.Benefits_Effective_Date__c != null ||
						HI_Oppty_Router_State__mdt.getInstance(objNewAccount.BillingStateCode) != null
					) {
						blnSendForRouting = true;
					}
				}
			}

			if (blnSendForRouting) {
				if (blnManualRouting && String.isNotBlank(objNewAccount.HI_Routing_Reason__c)) {
					if (objNewAccount.HI_Routing_Reason__c.containsIgnoreCase('SBIZ')) {
						strRoutingReason = strRoutingReason + ' SBIZ';
					} else if (objNewAccount.HI_Routing_Reason__c.containsIgnoreCase('MM')) {
						strRoutingReason = strRoutingReason + ' MM';
					}
				}
				// If no aligned rep is found, send account to ringlead and update hi routing reason
				if (objNewAccount.HI_Owner__c == null) {
					objNewAccount.HI_Routing_Reason__c = strType + ' - ' + strRoutingReason + ' - HI Owner null value and send to Routing Tool';
				} else {
					objNewAccount.HI_Routing_Reason__c = strType + ' - ' + strRoutingReason + ' - HI Owner replaced and send to Routing Tool';
				}
				map_AccountsForRouting.put(objNewAccount.Id, objNewAccount);
			}
		}
	}

	/**
	 * @description	Applies special rules to cross-sell and upsell when upsell tier contains Employer of Record and Priority Support
	 * @param objOpportunity - cross-sell and upsell opportunity
	 * @description	Populate Related GEP Account If Embedded Partner Account.
	 * @author Ajay Krishna P U
	 * @param list_NewAccounts New version of Accounts
	 * @param map_OldAccounts  Old Verison Of Accounts
	 */
	private void populateGEPAccounts(List<Account> list_NewAccounts, Map<Id, Account> map_OldAccounts) {
		List<Account> list_AccountsToProcess = new List<Account>();
		List<GEP_Accounts__c> list_GEPAccounts = new List<GEP_Accounts__c>();
		Boolean blnIsInsert = map_OldAccounts == null;

		//Identify Accounts to be processed
		for (Account objAccount : list_NewAccounts) {
			if (
				objAccount.GEP_Account__c == null &&
				objAccount.RecordTypeId == AccountUtil.PARTNER_RT_ID &&
				objAccount.Type == AccountUtil.EMBEDDED_PARTNER_TYPE &&
				(blnIsInsert ||
				map_OldAccounts.get(objAccount.Id).Type != objAccount.Type ||
				map_OldAccounts.get(objAccount.Id).RecordTypeId != objAccount.RecordTypeId)
			) {
				list_AccountsToProcess.add(objAccount);
				list_GEPAccounts.add(new GEP_Accounts__c(Name = objAccount.Name));
			}
		}
		if (list_AccountsToProcess.isEmpty()) {
			return;
		}

		try {
			//Create related GEP Account
			insert list_GEPAccounts;

			//Link GEP Accounts with Partner Accounts
			for (Integer intIndex = 0; intIndex < list_AccountsToProcess.size(); intIndex++) {
				list_AccountsToProcess[intIndex].GEP_Account__c = list_GEPAccounts[intIndex].Id;
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('AccountTriggerHelper', 'populateGEPAccounts', objEx);
		}
	}

	/**
	 * @description	Applies special rules to cross-sell and upsell when upsell tier contains Employer of Record and Priority Support
	 * @param objOpportunity - cross-sell and upsell opportunity
	 * @param objAccount  Company Account
	 */
	public Opportunity applySpecialRulesForTierUpsell(Opportunity objOpportunity, Account objAccount) {
		objOpportunity.Additional_Opportunity_Services__c = objAccount.Additional_Services__c;
		// special rules when upsell tier contains "Employer of Record"
		if (String.isNotBlank(objOpportunity.Upsell_Tier__c) && objOpportunity.Upsell_Tier__c.containsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)) {
			// if account does not have international employees, use 1 as default
			if (objAccount.International_Employees__c == null || objAccount.International_Employees__c == 0) {
				objOpportunity.International_Employees__c = 1;
			}

			// if upsell tier has Employer of Record but additional services is blank, set it to Employer of Record
			if (String.isBlank(objOpportunity.Additional_Opportunity_Services__c)) {
				objOpportunity.Additional_Opportunity_Services__c = AccountUtil.EMPLOYER_OF_RECORD;
			} else if (!objOpportunity.Additional_Opportunity_Services__c.containsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)) {
				// if additional services does not contain Employer of Record, add it
				objOpportunity.Additional_Opportunity_Services__c += ';' + AccountUtil.EMPLOYER_OF_RECORD;
			}
		}

		// special rules when upsell tier contains "Priority Support"
		if (String.isNotBlank(objOpportunity.Upsell_Tier__c) && objOpportunity.Upsell_Tier__c.containsIgnoreCase(AccountUtil.PRIORITY_SUPPORT)) {
			// if upsell tier contains Priority Support but additional services is blank, set it Priority Support and HR Services
			if (String.isBlank(objOpportunity.Additional_Opportunity_Services__c)) {
				objOpportunity.Additional_Opportunity_Services__c = OpportunityUtil.ADD_SERVICES_PRIORITY_SUPPORT;
			} else if (!objOpportunity.Additional_Opportunity_Services__c.containsIgnoreCase(OpportunityUtil.ADD_SERVICES_PRIORITY_SUPPORT)) {
				// if additional services does not contain priority support, add it
				objOpportunity.Additional_Opportunity_Services__c += ';' + OpportunityUtil.ADD_SERVICES_PRIORITY_SUPPORT;
			}
		}

		if (objOpportunity.Upsell_Tier__c == AccountUtil.PLUS_TIER) {
			// if tier is plus tier and additional services contains priority support but not Employer of Record, append priority support to upsell tier
			if (
				String.isNotBlank(objOpportunity.Additional_Opportunity_Services__c) &&
				objOpportunity.Additional_Opportunity_Services__c.containsIgnoreCase(AccountUtil.ADD_SERVICES_PRIORITY_SUPPORT) &&
				!objOpportunity.Additional_Opportunity_Services__c.containsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)
			) {
				objOpportunity.Upsell_Tier__c += ' with ' + AccountUtil.PRIORITY_SUPPORT;
			}
		}

		if (String.isNotBlank(strInternationalPayrollOnboardingTeam) && strInternationalPayrollOnboardingTeam.contains('Customer Success')) {
			if (
				String.isNotBlank(objOpportunity.Upsell_Tier__c) &&
				!objOpportunity.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD) &&
				!objOpportunity.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT)
			) {
				Set<String> set_AdditionalServices = String.isBlank(objOpportunity.Additional_Opportunity_Services__c)
					? new Set<String>()
					: new Set<String>(objOpportunity.Additional_Opportunity_Services__c.split(';'));
				set_AdditionalServices.remove(AccountUtil.EMPLOYER_OF_RECORD);
				objOpportunity.Additional_Opportunity_Services__c = String.join(new List<String>(set_AdditionalServices), ';');
			} else if (String.isNotBlank(objOpportunity.Upsell_Tier__c) && objOpportunity.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)) {
				objOpportunity.Additional_Opportunity_Services__c = AccountUtil.EMPLOYER_OF_RECORD;
			}
		}

		if (String.isNotBlank(objOpportunity.Upsell_Tier__c) && objOpportunity.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT)) {
			if (
				objOpportunity.Additional_Opportunity_Services__c != AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT &&
				objOpportunity.Additional_Opportunity_Services__c != AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT + ';'
			) {
				objOpportunity.Additional_Opportunity_Services__c = '';
			}
		}
		return objOpportunity;
	}

	/**
	 * @description	Utility method used to send in-app notifications
	 * @param objOpportunity - cross-sell and upsell opportunity
	 * @param strBody  Notification body
	 * @param strTitle Notification title
	 * @param idNotifier  Id of the user to be notified
	 * @param idNotification  Custom notification Id
	 * @param idTarget  Id of the user who will receive the notification
	 */
	public static void sendCustomNotification(String strTitle, String strBody, Id idNotifier, Id idNotification, Id idTarget) {
		if (!UserUtils.isAdminIntgUser(idNotifier) || Test.isRunningTest()) {
			Messaging.CustomNotification objCustomNotify = new Messaging.CustomNotification();
			objCustomNotify.setBody(strBody);
			objCustomNotify.setTitle(strTitle);
			objCustomNotify.setSenderId(UserInfo.getUserId());
			objCustomNotify.setNotificationTypeId(idNotification);
			objCustomNotify.setTargetId(idTarget);
			//objCustomNotify.send(new Set<String>{ idNotifier });
		}
	}

	/**
	 * Author: Anurag Gautam
	 * @description	Method used to create product upsell record
	 * @param list_NewAccounts - New account
	 * @param map_OldAccounts  - old values
	 */
	public static void createProductUpsell(List<Account> list_NewAccounts, Map<Id, Account> map_OldAccounts) {
		if (list_NewAccounts != null) {
			List<Account> list_AccountToProcessForProductUpsell = new List<Account>();
			Map<String, List<Contact>> map_AccountIdAndContacts = new Map<String, List<Contact>>();
			Map<String, Contact> map_ZPUserIdAndContact = new Map<String, Contact>();
			Set<Id> set_AccountIds = new Set<Id>();
			Set<String> set_CompanyIds = new Set<String>();

			Map<String, String> map_AccIdAndCompId = new Map<String, String>();
			Map<String, String> map_CompIdAndUserId = new Map<String, String>();
			Map<String, ZP_Company__c> map_CompIdAndZPCompany = new Map<String, ZP_Company__c>();

			//preparing set of account Ids to query contacts
			for (Account objAccount : list_NewAccounts) {
				set_AccountIds.add(objAccount.Id);
				set_CompanyIds.add(objAccount.ZP_Company_ID__c);
				map_AccIdAndCompId.put(objAccount.Id, objAccount.ZP_Company_ID__c);
			}

			if (!set_CompanyIds.isEmpty()) {
				for (ZP_Company__c objZPCompany : [SELECT Id, Product_Interest__c, Product_Interest_Countries__c, Id__c FROM ZP_Company__c WHERE Id__c IN :set_CompanyIds]) {
					if (String.isNotBlank(objZPCompany.Product_Interest__c) && objZPCompany.Product_Interest__c.contains('international_payroll_landing_page_consent')) {
						if (objZPCompany.Product_Interest__c.split('international_payroll_landing_page_consent_').size() > 1) {
							map_CompIdAndUserId.put(objZPCompany.Id__c, objZPCompany.Product_Interest__c.split('international_payroll_landing_page_consent_')[1].remove(';'));
						}
					}
					map_CompIdAndZPCompany.put(objZPCompany.ID__c, objZPCompany);
				}
			}

			// fetching contact where roles belong to LIST_ADMIN_ROLES
			for (Contact objContact : queryContacts(set_AccountIds, AccountUtil.LIST_ADMIN_ROLES).values()) {
				List<Contact> list_ContactsFromMap = map_AccountIdAndContacts.get(objContact.AccountId);
				if (list_ContactsFromMap == null) {
					list_ContactsFromMap = new List<Contact>();
				}
				list_ContactsFromMap.add(objContact);
				map_AccountIdAndContacts.put(objContact.AccountId, list_ContactsFromMap);
				if (String.isNotBlank(objContact.ZP_User_Id__c)) {
					map_ZPUserIdAndContact.put(objContact.ZP_User_Id__c, objContact);
				}
			}

			//iterating over the list of accounts
			for (Account objAccount : list_NewAccounts) {
				Account oldAccount = map_OldAccounts.get(objAccount.Id);
				Set<String> set_SupportedProdInterest = new Set<String>();
				Set<String> set_CurrentProdInterest = new Set<String>();
				Boolean blnHasProdInterestLogACall = false;
				Boolean blnCreateProductUpsell = false;
				if (String.isNotBlank(System.Label.Supported_Product_Interest_to_Create_Product_Upsell)) {
					set_SupportedProdInterest.addAll(System.Label.Supported_Product_Interest_to_Create_Product_Upsell.split(';'));
				}

				if (String.isNotBlank(objAccount.Product_Interest__c)) {
					set_CurrentProdInterest.addAll(objAccount.Product_Interest__c.split(';'));
				}

				for (String strCurrentAccProdInt : set_CurrentProdInterest) {
					if (set_SupportedProdInterest.contains(strCurrentAccProdInt)) {
						blnHasProdInterestLogACall = true;
						break;
					}
				}

				/**if (String.isNotBlank(objAccount.Product_Interest__c) && String.isNotBlank(System.Label.Supported_Product_Interest_to_Create_Product_Upsell) && System.Label.Supported_Product_Interest_to_Create_Product_Upsell.contains(objAccount.Product_Interest__c)) {
					blnHasProdInterestLogACall = true;
					
				}**/

				// if product interest already have a log a call
				if (blnHasProdInterestLogACall) {
					if (objAccount.Product_Interest_Countries__c != '' && oldAccount.Product_Interest_Countries__c != objAccount.Product_Interest_Countries__c) {
						list_AccountToProcessForProductUpsell.add(objAccount);
						Set<String> set_NewCountries = new Set<String>();
						Set<String> set_ExistingCountries = new Set<String>();
						List<String> list_EligibleCountriesForProductUpsell = new List<String>();
						Set<String> set_NewSupportedCountry = new Set<String>();
						Set<String> set_ExistingSupportedCountry = new Set<String>();

						if (oldAccount.Product_Interest_Countries__c != null) {
							set_ExistingCountries.addAll(oldAccount.Product_Interest_Countries__c.split(';'));
						}

						for (String strAccNewCountry : objAccount.Product_Interest_Countries__c.split(';')) {
							if (!set_ExistingCountries.contains(strAccNewCountry)) {
								set_NewCountries.add(strAccNewCountry);
							}
						}

						Boolean blnAtleastOneNewSupportedCountries = false;
						Boolean blnAtleastExistingSupportedCountries = false;

						Boolean blnAllNewSupportedCountries = false;
						Boolean blnAllExistingSupportedCountries = false;
						for (String strCountryName : map_InternationalPayrollCountries.keySet()) {
							//preparing set of newly added supported countries
							if (set_NewCountries.contains(map_InternationalPayrollCountries.get(strCountryName).Country_Name__c)) {
								set_NewSupportedCountry.add(map_InternationalPayrollCountries.get(strCountryName).Country_Name__c);
								blnAtleastOneNewSupportedCountries = true;
							}
							//preparing set of exisitng supported countries
							if (!set_ExistingCountries.isEmpty() && set_ExistingCountries.contains(map_InternationalPayrollCountries.get(strCountryName).Country_Name__c)) {
								set_ExistingSupportedCountry.add(map_InternationalPayrollCountries.get(strCountryName).Country_Name__c);
								blnAtleastExistingSupportedCountries = true;
							}
						}

						//preparing set of newly added countries
						for (String strNewCountry : set_NewCountries) {
							if (!set_ExistingCountries.isEmpty() && !set_ExistingCountries.contains(strNewCountry) && !set_NewSupportedCountry.contains(strNewCountry)) {
								list_EligibleCountriesForProductUpsell.add(strNewCountry);
							} else if (set_ExistingCountries.isEmpty() && !set_NewSupportedCountry.contains(strNewCountry)) {
								list_EligibleCountriesForProductUpsell.add(strNewCountry);
							}
						}

						// checking if only supported coutries are added.
						if (!set_NewCountries.isEmpty() && !set_NewSupportedCountry.isEmpty() && set_NewCountries.size() == set_NewSupportedCountry.size()) {
							blnAllNewSupportedCountries = true;
						}

						// checking if supported coutries are in the existing list.
						if (!set_ExistingCountries.isEmpty() && !set_ExistingSupportedCountry.isEmpty() && set_ExistingCountries.size() == set_ExistingSupportedCountry.size()) {
							blnAllExistingSupportedCountries = true;
						}

						/**
						Employer of Record - Log a Call is already in Account's Product Interest and all Product Interest Countries are not supported and are either updated/changed from Log a Call or zp company with a new non supported country. Then create Product Upsell and email for any countries not already sent in Product Upsell
						*/
						if (!blnAtleastOneNewSupportedCountries && !blnAtleastExistingSupportedCountries && !blnAllNewSupportedCountries && !blnAllExistingSupportedCountries) {
							blnCreateProductUpsell = true;
						}

						/**
						Employer of Record - Log a Call already exists in Product Interest and all Product Interest Countries are supported and an update is made to add a supported country. Do not create a Product Upsell and email
						*/
						if (blnAtleastOneNewSupportedCountries && blnAtleastExistingSupportedCountries && blnAllNewSupportedCountries && blnAllExistingSupportedCountries) {
							blnCreateProductUpsell = false;
						}

						/**
						Employer of Record - Log a Call is already in Product Interest and there are supported and non-supported Product Interest Countries and Product Interest Countries is updated/changed. Look to see if there is an Open or Closed Won/Not Invoiced Company Opportunity or cross-sell and upsell Opportunity with Employer of Record (Additional Opportunity Services contains Employer of Record). If yes, then don't created Product Upsell. If no opportunities with IP open or Closed Won/Invoiced, then create Product Upsell for countries not supported.
						*/
						if ((blnAtleastOneNewSupportedCountries || blnAtleastExistingSupportedCountries) && !blnAllNewSupportedCountries && !blnAllExistingSupportedCountries) {
							Boolean blnOpenOpptyFound = false;
							//check for the open opportunity
							for (Opportunity objOppty : map_AllAccountMap.get(objAccount.Id).Opportunities) {
								// if open non-invoiced company opportunity is found, don't create the product upsell
								if (objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID && objOppty.Payment_Invoice__c == null) {
									blnOpenOpptyFound = true;
									break;
								} else if (
									objOppty.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID &&
									objOppty.StageName != OpportunityUtil.CLOSED_WON_STAGE &&
									objOppty.StageName != OpportunityUtil.CLOSED_LOST_STAGE &&
									objOppty.Payment_Invoice__c == null
								) {
									// if open non-invoiced cross-sell and upsell opportunity is found,  don't create the product upsell
									blnOpenOpptyFound = true;
									break;
								}
							}

							if (!blnOpenOpptyFound) {
								blnCreateProductUpsell = true;
							}
						}

						Set<String> set_EligibleCountries = new Set<String>();
						if (list_EligibleCountriesForProductUpsell.isEmpty()) {
							blnCreateProductUpsell = false;
						} else {
							set_EligibleCountries.addAll(list_EligibleCountriesForProductUpsell);
						}

						Boolean blnSupportedCountryNotAdded = true;

						for (String strEligibleCountryName : map_InternationalPayrollCountries.keySet()) {
							if (set_EligibleCountries.contains(map_InternationalPayrollCountries.get(strEligibleCountryName).Label)) {
								blnSupportedCountryNotAdded = false;
								break;
							}
						}

						if (blnCreateProductUpsell && blnSupportedCountryNotAdded) {
							//create Product Upsell
							// product upsell details to create the record
							Partnership_Interest__c objProductUpsell = new Partnership_Interest__c();
							// by default value would be a picklist
							objProductUpsell.Product_Interest__c = AccountUtil.EMPLOYER_OF_RECORD;
							// adding countries to the Product upsell
							objProductUpsell.Product_Interest_Countries__c = String.join(list_EligibleCountriesForProductUpsell, ';');
							// assign contact from ZP User role.

							if (map_CompIdAndUserId.containsKey(objAccount.ZP_Company_ID__c) && map_ZPUserIdAndContact.containsKey(map_CompIdAndUserId.get(objAccount.ZP_Company_ID__c))) {
								objProductUpsell.Contact__c = map_ZPUserIdAndContact.get(map_CompIdAndUserId.get(objAccount.ZP_Company_ID__c)).Id;
							} else if (!map_AccountIdAndContacts.isEmpty()) {
								for (Contact objContact : map_AccountIdAndContacts.get(objAccount.Id)) {
									if (objContact.ZP_User_Role__c.contains(ZPUserRoleUtil.PRIMARY_PAYROLL_ADMIN)) {
										objProductUpsell.Contact__c = objContact.Id;
									} else if (objContact.ZP_User_Role__c.contains(ZPUserRoleUtil.PAYROLL_ADMIN)) {
										objProductUpsell.Contact__c = objContact.Id;
									}
								}
							}

							// Recordtype will be New Partenership interest
							objProductUpsell.RecordTypeId = LogSmartCallingUtil.PRODUCT_UPSELL_RT_ID_NEW_PARTNERSHIP_INTERESET;
							//associated account to product upsell
							objProductUpsell.Account__c = objAccount.Id;

							if (objProductUpsell.Contact__c != null) {
								if (list_PartnershipInterestsToInsert == null) {
									list_PartnershipInterestsToInsert = new List<Partnership_Interest__c>();
									list_PartnershipInterestsToInsert.add(objProductUpsell);
								} else {
									list_PartnershipInterestsToInsert.add(objProductUpsell);
								}
							}
						}
					}
				}
			}
		}
	}

	/**
	 * Author: Anurag Gautam
	 * @description	Method used to query Contacts
	 * @param set_AccountIds - Accound Ids
	 * @param list_Roles  - user roles
	 */
	private static Map<Id, Contact> queryContacts(Set<Id> set_AccountIds, List<String> list_Roles) {
		Map<Id, Contact> map_contactIdToContactRec = new Map<Id, Contact>();
		String strContactQuery = 'SELECT Customer_Subscriptions__c, AccountId, Inactive_ZP_User__c, ZP_User_Id__c,ZP_User_Role__c FROM Contact ';
		strContactQuery += 'WHERE Inactive_ZP_User__c = False AND AccountId IN :set_AccountIds AND ZP_User_Role__c INCLUDES (';
		for (String strRole : list_Roles) {
			strContactQuery += '\'' + strRole + '\',';
		}
		strContactQuery = strContactQuery.removeEnd(',');
		strContactQuery += ')';

		for (Contact objContact : Database.query(strContactQuery)) {
			map_contactIdToContactRec.put(objContact.Id, objContact);
		}
		return map_contactIdToContactRec;
	}

	/**
	 * @Description :  Update First Client Add Date field When Sold by, Referred by, or Original Firm field is first populated on a Client Account
	 * @Param        : objNewAccount - from Trigger.new
	 * @Param        : objOldAccount - from Trigger.old (if before update)
	 * @Return      : void
	 **/
	public void setFirstClientAddDateOnReseller(Account objNewAccount, Account objOldAccount) {
		if (objNewAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
			if (objOldAccount == null && (objNewAccount.Sold_By__c != null || objNewAccount.Referred_By__c != null || objNewAccount.Original_Firm__c != null)) {
				if (
					objNewAccount.Sold_By__c != null &&
					map_ResellerAccountIdAccount.containsKey(objNewAccount.Sold_By__c) &&
					map_ResellerAccountIdAccount.get(objNewAccount.Sold_By__c).First_Client_Add_Date__c == null
				) {
					Account objAccToUpdate = new Account(Id = objNewAccount.Sold_By__c, First_Client_Add_Date__c = System.today());
					map_AccountsToUpdate.put(objAccToUpdate.Id, objAccToUpdate);
				}
				if (
					objNewAccount.Referred_By__c != null &&
					map_ResellerAccountIdAccount.containsKey(objNewAccount.Referred_By__c) &&
					map_ResellerAccountIdAccount.get(objNewAccount.Referred_By__c).First_Client_Add_Date__c == null
				) {
					Account objAccToUpdate = new Account(Id = objNewAccount.Referred_By__c, First_Client_Add_Date__c = System.today());
					map_AccountsToUpdate.put(objAccToUpdate.Id, objAccToUpdate);
				}
				if (
					objNewAccount.Original_Firm__c != null &&
					map_ResellerAccountIdAccount.containsKey(objNewAccount.Original_Firm__c) &&
					map_ResellerAccountIdAccount.get(objNewAccount.Original_Firm__c).First_Client_Add_Date__c == null
				) {
					Account objAccToUpdate = new Account(Id = objNewAccount.Original_Firm__c, First_Client_Add_Date__c = System.today());
					map_AccountsToUpdate.put(objAccToUpdate.Id, objAccToUpdate);
				}
			} else if (
				objOldAccount != null &&
				((objOldAccount.Sold_By__c != objNewAccount.Sold_By__c) ||
				(objOldAccount.Referred_By__c != objNewAccount.Referred_By__c) ||
				(objOldAccount.Original_Firm__c != objNewAccount.Original_Firm__c))
			) {
				if (
					objNewAccount.Sold_By__c != null &&
					map_ResellerAccountIdAccount.containsKey(objNewAccount.Sold_By__c) &&
					map_ResellerAccountIdAccount.get(objNewAccount.Sold_By__c).First_Client_Add_Date__c == null
				) {
					Account objAccToUpdate = new Account(Id = objNewAccount.Sold_By__c, First_Client_Add_Date__c = System.today());
					map_AccountsToUpdate.put(objAccToUpdate.Id, objAccToUpdate);
				}
				if (
					objNewAccount.Referred_By__c != null &&
					map_ResellerAccountIdAccount.containsKey(objNewAccount.Referred_By__c) &&
					map_ResellerAccountIdAccount.get(objNewAccount.Referred_By__c).First_Client_Add_Date__c == null
				) {
					Account objAccToUpdate = new Account(Id = objNewAccount.Referred_By__c, First_Client_Add_Date__c = System.today());
					map_AccountsToUpdate.put(objAccToUpdate.Id, objAccToUpdate);
				}
				if (
					objNewAccount.Original_Firm__c != null &&
					map_ResellerAccountIdAccount.containsKey(objNewAccount.Original_Firm__c) &&
					map_ResellerAccountIdAccount.get(objNewAccount.Original_Firm__c).First_Client_Add_Date__c == null
				) {
					Account objAccToUpdate = new Account(Id = objNewAccount.Original_Firm__c, First_Client_Add_Date__c = System.today());
					map_AccountsToUpdate.put(objAccToUpdate.Id, objAccToUpdate);
				}
			}
		}
	}
}