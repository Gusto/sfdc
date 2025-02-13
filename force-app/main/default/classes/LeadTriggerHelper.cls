/**
    @Author       :   David (Dato) Tsamalashvili
    @CreatedDate  :   10/06/2020
    @Desc         :   New Refactored LeadTriggerHelper Class
**/
public class LeadTriggerHelper {
	// ------------ EXISTING STATIC VARIABLES STARTS HERE ----------
	// Developer Notes - Not renaming static variable names as these could be used in so many places
	// Static Variable used to Lead Skip Triggers
	public static Boolean skipTrigger = false;
	public static Integer counter = 0;
	public static List<Contact> list_contacts;
	public static Map<String, Contact> map_EmailToContact;
	public static Map<String, Account_Email_Domain__c> map_ResellerDomainMap;
	public static Map<String, Account> map_ZPFrmIdToAccount;
	public static Map<String, Lead> map_EmailToLeads;
	public static String strCurrentUsrRoleName = '';
	public static String strOldOwnerUsrRoleName = '';
	public static List<Lead_Routing_Settings__mdt> list_LeadRoutingStngs;
	public static Map<Id, Account> map_RouterAccounts;
	public static Map<Id, String> map_LeadIdToSrcKey;
	public static Set<String> set_SourceKeys;
	public static Map<String, Id> map_CompanyMSKeyMap;
	public static Map<String, Id> map_ResellerMSKeyMap;
	public static List<Lead_Related_Tracking__c> list_LeadRelTracking; //to be used in DML
	public static Map<Id, Contact> map_ContactsForUpdate; //to be used in DML
	public static Map<Id, Opportunity> map_OppsForUpdate; //to be used in DML
	public static Map<Id, Account> map_AccountsForUpdate; //to be used in DML
	public static Map<Id, Lead> map_LeadsForUpdate; //to be used in DML
	public static Map<Id, Case> map_CaseForUpdate; //to be used in DML
	public static Map<Id, CampaignMember> map_CampMemberForUpdate; //to be used in DML
	public static Map<Id, LiveChatTranscript> map_ChatTranscriptsForUpdate; // to be used in DML
	public static Map<Id, Task> map_TasksForUpdate; // to be used in DML
	public static List<Outreach_Engagement__c> list_OutreachRecordsDML; //to be used in DML
	public static BusinessHours objBusinessHour;
	public static Map<String, Lead> map_RefTokenToLead;
	public static Map<String, ZP_User__c> map_RefTokenToZPUsr;
	public static Set<String> set_ReferralTokens;
	public static Set<String> set_ZPUserIdSet;
	public static Map<String, Contact> map_ZPUsrIdContact;
	public static Set<String> set_ReferralAccIds;
	public static Map<String, Account> map_CompIdToAccRefer; //company id to account map - for partner referral fields.
	public static Map<String, Account> map_FirmIdToAccRefer; //firm id to account map - for partner referral fields.
	public static Map<String, Account> map_CompanyIdToAccount; //all accounts associated with lead via zp company id
	public static Set<Id> set_ConvertedResAccIds; //converted account ids - for reseller
	public static Set<Id> set_MDRActivityResAccs; //captures converted reseller account ids for MDR Activity
	public static Set<Id> set_AllConvertedAccIds; //holds  acc ids post lead convertion - convertedAccountId
	public static Set<Id> set_AllConvertedOppIds; //holds  opp ids post lead convertion - convertedOpportunityId
	public static Set<Id> set_AllConvertedConIds; //holds  con ids post lead convertion - convertedContactId
	public static Set<Id> set_AllConvertedLeadIds; // holds  Lead Ids post Lead convertion.
	public static Map<Id, Account> map_ConvertedAccIdToAcc;
	public static Map<Id, Opportunity> map_ConvertedOppIdToOpp;
	public static Map<Id, Contact> map_ConvertedConIdToCon;
	public static Map<Id, List<Case>> map_LeadIdToRelCases;
	public static Set<Id> set_LeadIdForCases;
	public static Map<Id, List<CampaignMember>> map_LeadIdToCampaign;
	public static Map<Id, Lead_Related_Tracking__c> map_LeadIdToRelTrack;
	public static Map<Id, List<LiveChatTranscript>> map_LeadIdToChatTranscripts; //map of lead id to chat transcripts that need update
	public static Map<Id, Boolean> map_LeadIdToCUOutreach; //create a map of lead id to boolean (true if new record needs to be created / false for update)
	public static Set<Id> set_OutreachLeadIds; //store Lead ids for which query needs to be done.
	public static Map<Id, Outreach_Engagement__c> map_LeadIdToOutEng;
	public static Set<Id> set_LeadIdsForTasks; //collects lead ids when owner is changed - for Task Query
	public static Map<Id, List<Task>> map_LeadIdToTskList;
	Map<String, String> map_EmailToNormalizedValue;

	public static User objCurrentUser; //current user info
	public static Set<String> set_RoutedLeadsHash;
	public static List<String> list_Competitors = Label.Competitors.toLowerCase().split(',');
	public static List<String> list_Partners = Label.Partners.toLowerCase().split(',');
	public static List<String> list_Employees = Label.Employees.toLowerCase().split(',');
	public static Boolean blnIsRouting = false;
	public static String strSubscriptionFeatureFlag = System.Label.Subscription_Feature_Flag;
	public static String SALES_BUSINESS_HOURS = 'Gusto - Denver - Sales';
	public static String QUALIFIED_INTEGRATION_USERNAME = 'Qualified Integration';
	public static List<Lead> list_LeadsToCallout = new List<Lead>();
	public List<Account> list_AccountToUpdateAccuticsInfo = new List<Account>();
	// Normalization Object to Normalize Phone and Email Address
	NormalizationUtil objNormalization = new NormalizationUtil();

	// ------------ EXISTING STATIC VARIABLES END HERE ----------

	// Constructor:
	public LeadTriggerHelper() {
		set_AllConvertedLeadIds = new Set<Id>();

		map_LeadIdToCampaign = new Map<Id, List<CampaignMember>>();
		map_CampMemberForUpdate = new Map<Id, CampaignMember>();
	}

	//Before Insert functionality
	public void processBeforeInsert(List<Lead> list_Leads) {
		Set<String> set_EmailIds = new Set<String>();
		Set<String> set_AccFirmIds = new Set<String>();
		Set<String> set_EmailDomains = new Set<String>();
		Set<String> set_EmailRefToken = new Set<String>();
		Set<Id> set_SoldRefByAcc = new Set<Id>();
		Set<String> set_AllCompIds = new Set<String>();
		set_SourceKeys = new Set<String>();
		map_RefTokenToLead = new Map<String, Lead>();
		map_RefTokenToZPUsr = new Map<String, ZP_User__c>();
		set_ReferralTokens = new Set<String>();
		set_ZPUserIdSet = new Set<String>();
		set_ReferralAccIds = new Set<String>();
		map_ContactsForUpdate = new Map<Id, Contact>();
		map_LeadsForUpdate = new Map<Id, Lead>();
		objCurrentUser = new User();
		map_OppsForUpdate = new Map<Id, Opportunity>();
		map_AccountsForUpdate = new Map<Id, Account>();
		map_LeadIdToSrcKey = new Map<Id, String>();
		set_RoutedLeadsHash = new Set<String>();
		map_CompanyMSKeyMap = new Map<String, Id>();
		map_ResellerMSKeyMap = new Map<String, Id>();
		map_RouterAccounts = new Map<Id, Account>();
		map_ZPFrmIdToAccount = new Map<String, Account>();
		map_CompIdToAccRefer = new Map<String, Account>();
		map_FirmIdToAccRefer = new Map<String, Account>();
		map_CompanyIdToAccount = new Map<String, Account>();
		set_MDRActivityResAccs = new Set<Id>();
		map_ConvertedAccIdToAcc = new Map<Id, Account>();
		map_ConvertedOppIdToOpp = new Map<Id, Opportunity>();
		map_ConvertedConIdToCon = new Map<Id, Contact>();
		map_EmailToNormalizedValue = new Map<String, String>();

		//collect data
		for (Lead objLead : list_Leads) {
			//get lead Emails to query existing contacts
			if (String.isNotBlank(objLead.Email)) {
				set_EmailIds.add(objLead.Email);
				//check if valid email and generate Email Domain set
				if (objLead.Email.contains('@')) {
					String str_EmailDomain = objLead.Email.substring(objLead.Email.indexof('@'), objLead.Email.length()).replace('@', '').trim();
					if (!set_EmailDomains.contains(str_EmailDomain)) {
						set_EmailDomains.add(str_EmailDomain);
					}
				}

				if (String.isBlank(objLead.Referral_Token__c)) {
					set_EmailRefToken.add(objLead.Email);
				}
			}

			//get accouting firm ids - to run duplicate check // reseller record type id
			if (objLead.RecordTypeId == LeadUtil.RESELLER_LEAD_RT_ID && String.isNotBlank(objLead.ZP_Firm_ID__c)) {
				set_AccFirmIds.add(objLead.ZP_Firm_ID__c);
			}

			//check sold by/referred by ids for Routing
			if (String.isNotBlank(objLead.Sold_By__c)) {
				set_SoldRefByAcc.add(objLead.Sold_By__c);
			} else if (
				String.isNotBlank(objLead.Referred_By__c) &&
				((String.isNotBlank(objLead.LeadSource) && objLead.LeadSource == LeadUtil.LEADSOURCE_P2P) ||
				(String.isNotBlank(objLead.Referral_Type__c) &&
				(objLead.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_UR) || objLead.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_PRU))))
			) {
				set_SoldRefByAcc.add(objLead.Referred_By__c);
			}

			//collect source keys
			String strSourceKey = generateSourceKey(objLead, null, true);

			//collect referral data
			if (objLead.RecordTypeId == LeadUtil.COMPANY_LEAD_RT_ID && String.isNotBlank(objLead.Referral_Token__c)) {
				set_ReferralTokens.add(objLead.Referral_Token__c);
			}

			if (String.isNotBlank(objLead.ZP_Company_ID__c)) {
				set_AllCompIds.add(objLead.ZP_Company_ID__c);
			}
		}

		if (set_EmailDomains.size() > 0) {
			queryLeadEmailDomains(set_EmailDomains);
		}

		if (set_EmailRefToken.size() > 0) {
			queryExistingLeads(set_EmailRefToken, new Set<Id>());
		}

		queryLeadRouteSettngMdt();

		if (set_SourceKeys.size() > 0) {
			generateMktgSourceMap();
		}

		if (set_ReferralTokens.size() > 0) {
			queryLeadsWithToken(set_ReferralTokens);
			queryZPUserWithToken(set_ReferralTokens);
		}
		//to be executed after lead (with token) and zp user (with token) query to collect additional account ids
		if (set_AccFirmIds.size() > 0 || set_SoldRefByAcc.size() > 0 || set_AllCompIds.size() > 0) {
			queryAccountInfo(set_AccFirmIds, set_SoldRefByAcc, set_AllCompIds, new Set<Id>(), new Set<Id>());
		}

		//to be executed after zp user (with token) query to collect ZP User Ids
		if (set_EmailIds.size() > 0 || set_ZPUserIdSet.size() > 0) {
			queryContacts(set_EmailIds, set_ZPUserIdSet, new Set<Id>());
		}

		strCurrentUsrRoleName = UserUtils.getCurrentUserRoleName();
		objCurrentUser = UserUtils.getOwnerUsrInfo(LeadUtil.ID_CURRENT_USER);

		if (!set_EmailIds.isEmpty()) {
			// If not empty, get list of normalized email address and store them in a map
			map_EmailToNormalizedValue = objNormalization.normaliseDomainFieldBulkified(set_EmailIds);
		}

		//set values
		for (Lead objLead : list_Leads) {
			setDefaultFields(objLead, null);
			promoteLead(objLead, null);
			setDefaultInsertFields(objLead);
			normalizeEmailDomains(map_EmailToNormalizedValue, objLead);
			normalizeLeadPhoneFields(objLead, null);
			checkDomain(objLead, null);
			setSourceMap(objLead, null);
			setPartnerReferralFields(objLead);
			setLeadCreationOffer(objLead, null);
			setAccCreateDateByCompId(objLead);
			setAccCreateDateByFirmId(objLead);
			doLeadRouting(objLead, null);
			setSdrMdr(objLead, null);
			setMDRFields(objLead, null);
			setLeadAssignmentOwnerRole(objLead, null);
			setRandomCohort(objLead);
			setNumberOfClients(objLead, null);
			setReferralType(objLead);
			setLeadSource(objLead, null);
			setPotentialFraudLeadHistory(objLead, null);
			setAccountLeadRating(objLead, null);
			//should run after all updates
			postTriggerUpdates(objLead, null, true);
			// Set subscriptions based on dependencies
			setSubscriptionPreferencesOnLead(objLead, null, true);
			setLegacySubscriptionFields(objLead, null);
			setOutreachEmailOptOut(objLead, null);
		}

		setCampaignInfoInLead(list_Leads);
	}

	//After Insert functionality
	public void processAfterInsert(List<Lead> list_Leads) {
		Set<Id> set_OwnerIds = new Set<Id>();
		list_LeadRelTracking = new List<Lead_Related_Tracking__c>();
		objBusinessHour = GlobalQueryHelper.getBusinessHoursByName(SALES_BUSINESS_HOURS);

		//collect data
		for (Lead objLead : list_Leads) {
			//all lead owner ids - to business hour mapping
			set_OwnerIds.add(objLead.OwnerId);
		}

		//set values
		for (Lead objLead : list_Leads) {
			createLeadRelatedTracking(objLead);
		}

		doLeadRoutingCallout(new Map<Id, Lead>(list_Leads), null);

		//process all DML operations
		processDMLOperation(true);
	}

	//Before Update functionality
	public void processBeforeUpdate(List<Lead> list_Leads, Map<Id, Lead> map_OldLeads) {
		Set<String> set_EmailDomains = new Set<String>();
		Set<String> set_EmailRefToken = new Set<String>();
		Set<String> set_AccFirmIds = new Set<String>();
		Set<Id> set_SoldRefByAcc = new Set<Id>();
		Set<String> set_AllCompIds = new Set<String>();
		Set<String> set_EmailIds = new Set<String>();
		Set<Id> set_CurrentLeadIdExc = new Set<Id>();
		Set<Id> set_LeadIds = new Set<Id>();
		set_ConvertedResAccIds = new Set<Id>();
		set_AllConvertedAccIds = new Set<Id>();
		set_AllConvertedOppIds = new Set<Id>();
		set_AllConvertedConIds = new Set<Id>();
		set_LeadIdsForTasks = new Set<Id>();
		objCurrentUser = new User();
		set_SourceKeys = new Set<String>();
		set_ReferralTokens = new Set<String>();
		set_ReferralAccIds = new Set<String>();
		map_RefTokenToLead = new Map<String, Lead>();
		map_RefTokenToZPUsr = new Map<String, ZP_User__c>();
		set_ZPUserIdSet = new Set<String>();
		map_ContactsForUpdate = new Map<Id, Contact>();
		map_LeadsForUpdate = new Map<Id, Lead>();
		map_OppsForUpdate = new Map<Id, Opportunity>();
		map_AccountsForUpdate = new Map<Id, Account>();
		map_LeadIdToSrcKey = new Map<Id, String>();
		map_LeadIdToTskList = new Map<Id, List<Task>>();
		set_RoutedLeadsHash = new Set<String>();
		map_CompanyMSKeyMap = new Map<String, Id>();
		map_ResellerMSKeyMap = new Map<String, Id>();
		map_RouterAccounts = new Map<Id, Account>();
		map_ZPFrmIdToAccount = new Map<String, Account>();
		map_CompIdToAccRefer = new Map<String, Account>();
		map_FirmIdToAccRefer = new Map<String, Account>();
		map_CompanyIdToAccount = new Map<String, Account>();
		set_MDRActivityResAccs = new Set<Id>();
		map_ConvertedAccIdToAcc = new Map<Id, Account>();
		map_ConvertedOppIdToOpp = new Map<Id, Opportunity>();
		map_ConvertedConIdToCon = new Map<Id, Contact>();
		map_EmailToNormalizedValue = new Map<String, String>();

		//collect data
		for (Lead objLead : list_Leads) {
			set_LeadIds.add(objLead.Id);
			//get old lead
			Lead objOldLead = map_OldLeads.containsKey(objLead.Id) ? map_OldLeads.get(objLead.Id) : null;
			if (String.IsNotBlank(objLead.Email)) {
				set_EmailIds.add(objLead.Email);
				//check if valid email and generate Email Domain set
				if (objLead.Email.contains('@')) {
					String str_EmailDomain = objLead.Email.substring(objLead.Email.indexof('@'), objLead.Email.length()).replace('@', '').trim();
					if (!set_EmailDomains.contains(str_EmailDomain)) {
						set_EmailDomains.add(str_EmailDomain);
					}
				}

				if (String.isBlank(objLead.Referral_Token__c)) {
					set_EmailRefToken.add(objLead.Email);
				}

				//collect source keys
				String strSourceKey = generateSourceKey(objLead, objOldLead, true);
			}

			//get accouting firm ids - to run duplicate check // reseller record type id
			if (objLead.RecordTypeId == LeadUtil.RESELLER_LEAD_RT_ID && String.isNotBlank(objLead.ZP_Firm_ID__c)) {
				set_AccFirmIds.add(objLead.ZP_Firm_ID__c);
			}

			//check sold by/referred by ids for Routing
			if (String.isNotBlank(objLead.Sold_By__c)) {
				set_SoldRefByAcc.add(objLead.Sold_By__c);
			} else if (
				String.isNotBlank(objLead.Referred_By__c) &&
				((String.isNotBlank(objLead.LeadSource) && objLead.LeadSource == LeadUtil.LEADSOURCE_P2P) ||
				(String.isNotBlank(objLead.Referral_Type__c) &&
				(objLead.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_UR) || objLead.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_PRU))))
			) {
				set_SoldRefByAcc.add(objLead.Referred_By__c);
			}

			//get account ids for MDR activity
			if (objLead.RecordTypeId == LeadUtil.RESELLER_LEAD_RT_ID && String.isNotBlank(objLead.ConvertedAccountId) && objOldLead != null && String.isBlank(objOldLead.ConvertedAccountId)) {
				set_ConvertedResAccIds.add(objLead.ConvertedAccountId);
			}

			if (String.isNotBlank(objLead.ZP_Company_ID__c)) {
				set_AllCompIds.add(objLead.ZP_Company_ID__c);
			}

			if (String.isNotBlank(objLead.ConvertedAccountId)) {
				//collect account ids
				set_AllConvertedAccIds.add(objLead.ConvertedAccountId);
			}
			if (String.isNotBlank(objLead.ConvertedOpportunityId)) {
				//collect opportunity ids
				set_AllConvertedOppIds.add(objLead.ConvertedOpportunityId);
			}
			if (String.isNotBlank(objLead.ConvertedContactId)) {
				//collect  contact ids
				set_AllConvertedConIds.add(objLead.ConvertedContactId);
			}

			//collect all lead ids
			set_CurrentLeadIdExc.add(objLead.Id);

			// Set subscriptions based on dependencies
			setSubscriptionPreferencesOnLead(objLead, objOldLead, false);
			setLegacySubscriptionFields(objLead, objOldLead);
			setOutreachEmailOptOut(objLead, objOldLead);
		}

		queryLeadRouteSettngMdt();

		if (set_EmailDomains.size() > 0) {
			queryLeadEmailDomains(set_EmailDomains);
		}

		if (set_EmailRefToken.size() > 0) {
			queryExistingLeads(set_EmailRefToken, set_CurrentLeadIdExc);
		}

		if (set_AllConvertedOppIds.size() > 0) {
			queryOpportunities(set_AllConvertedOppIds);
		}

		if (set_ReferralTokens.size() > 0) {
			queryLeadsWithToken(set_ReferralTokens);
			queryZPUserWithToken(set_ReferralTokens);
		}
		//to be executed after lead (with token) and zp user (with token) query to collect additional account ids
		if (
			set_AccFirmIds.size() > 0 ||
			set_SoldRefByAcc.size() > 0 ||
			set_AllCompIds.size() > 0 ||
			set_ConvertedResAccIds.size() > 0 ||
			set_AllConvertedAccIds.size() > 0 ||
			set_CurrentLeadIdExc.size() > 0
		) {
			queryAccountInfo(set_AccFirmIds, set_SoldRefByAcc, set_AllCompIds, set_ConvertedResAccIds, set_AllConvertedAccIds);
		}

		//to be executed after zp user (with token) query to collect ZP User Ids
		if (set_EmailIds.size() > 0 || set_ZPUserIdSet.size() > 0) {
			queryContacts(set_EmailIds, set_ZPUserIdSet, set_AllConvertedConIds);
		}

		if (set_SourceKeys.size() > 0) {
			generateMktgSourceMap();
		}

		strCurrentUsrRoleName = UserUtils.getCurrentUserRoleName();
		objCurrentUser = UserUtils.getOwnerUsrInfo(LeadUtil.ID_CURRENT_USER);

		if (!set_EmailIds.isEmpty()) {
			// If not empty, get list of normalized email address and store them in a map
			map_EmailToNormalizedValue = objNormalization.normaliseDomainFieldBulkified(set_EmailIds);
		}

		/** Query Campaign Memebers */
		if (!set_LeadIds.isEmpty()) {
			queryCampaigns(set_LeadIds);
		}

		//set values
		for (Lead objLead : list_Leads) {
			//get previous version of lead
			Lead objOldLead = map_OldLeads.containsKey(objLead.Id) ? map_OldLeads.get(objLead.Id) : null;

			setDefaultFields(objLead, objOldLead);
			promoteLead(objLead, objOldLead);
			setDefaultUpdateFields(objLead, objOldLead);
			normalizeEmailDomains(map_EmailToNormalizedValue, objLead);
			normalizeLeadPhoneFields(objLead, objOldLead);
			setLeadCreationOffer(objLead, objOldLead);
			doLeadRouting(objLead, objOldLead);
			setSdrMdr(objLead, objOldLead);
			doPostRoutingValidation(objLead, objOldLead);
			setSourceMap(objLead, objOldLead);
			setPartnerReferralFields(objLead);
			updateLeadMDRActivity(objlead, objOldLead);
			checkDomain(objLead, objOldLead);
			setAccCreateDateByCompId(objLead);
			setAccCreateDateByFirmId(objLead);
			setMDRFields(objLead, objOldLead);
			validateLeadFrmTask(objLead, objOldLead);
			setLeadAssignmentOwnerRole(objLead, objOldLead);
			setNumberOfClients(objLead, objOldLead);
			setReferralType(objLead);
			setLeadSource(objLead, objOldLead);
			setAccountLeadRating(objLead, objOldLead);
			//should run after all updates
			postTriggerUpdates(objLead, objOldLead, false);
			// Reset Lead Source when changed
			resetLeadSource(objLead, objOldLead);
			setPotentialFraudLeadHistory(objLead, objOldLead);
			// BMM-493 - Once converted set Lead Status to 'Converted'
			setLeadStatus(objLead, objOldLead);
		}

		setCampaignInfoInLead(list_Leads);
	}

	//After Update functionality
	public void processAfterUpdate(List<Lead> list_Leads, Map<Id, Lead> map_OldLeads) {
		Set<Id> set_LeadIds = new Set<Id>();
		set_LeadIdForCases = new Set<Id>();
		Set<Id> set_OwnerIds = new Set<Id>();
		map_LeadIdToCUOutreach = new Map<Id, Boolean>();
		set_OutreachLeadIds = new Set<Id>();
		list_OutreachRecordsDML = new List<Outreach_Engagement__c>();
		list_LeadRelTracking = new List<Lead_Related_Tracking__c>();
		map_CaseForUpdate = new Map<Id, Case>();
		map_LeadIdToChatTranscripts = new Map<Id, List<LiveChatTranscript>>();
		map_ChatTranscriptsForUpdate = new Map<Id, LiveChatTranscript>();
		map_TasksForUpdate = new Map<Id, Task>();
		objBusinessHour = GlobalQueryHelper.getBusinessHoursByName(SALES_BUSINESS_HOURS);

		//collect data
		for (Lead objLead : list_Leads) {
			//get previous version of lead
			Lead objOldLead = map_OldLeads.containsKey(objLead.Id) ? map_OldLeads.get(objLead.Id) : null;

			if (objLead.isConverted && !objOldLead.isConverted) {
				set_AllConvertedLeadIds.add(objLead.Id);

				if (String.isNotBlank(objLead.ConvertedContactId)) {
					set_LeadIdForCases.add(objLead.Id);
				}
			}

			//collect all lead owner ids
			set_OwnerIds.add(objLead.OwnerId);
			//collect all lead ids
			set_LeadIds.add(objLead.Id);

			//valaidate if Outreach Create/Update appicable and generate set
			validateOutreach(objLead, objOldLead);
		}

		/**  Query Call Section */
		if (set_LeadIdForCases.size() > 0) {
			queryCases(set_LeadIdForCases);
		}

		/** Query Campaign Memebers */
		if (set_LeadIds.size() > 0) {
			queryCampaigns(set_LeadIds);
			queryLeadRelTracking(set_LeadIds);

			if (!set_AllConvertedLeadIds.isEmpty()) {
				queryChatTranscriptsWithActivities(set_AllConvertedLeadIds); //query chat transcripts for converted leads
			}
		}

		/** Query Outreach Engagement Records */
		if (set_OutreachLeadIds.size() > 0) {
			queryOutreachEngRecords(set_OutreachLeadIds);
		}

		//get current user role name
		strCurrentUsrRoleName = UserUtils.getCurrentUserRoleName();

		//set values
		for (Lead objLead : list_Leads) {
			//get previous version of lead
			Lead objOldLead = map_OldLeads.containsKey(objLead.Id) ? map_OldLeads.get(objLead.Id) : null;
			updateConvertedRecData(objLead, objOldLead); //updateOpportunitySourceIds
			updatedAccountAndOppPostConversion(objLead, objOldLead); //updateAccountAndOppPostConversion
			setSoldByReferredBy(objLead, objOldLead); //setOpptyReferredBy
			updateLeadRelatedCases(objLead, objOldLead); //updateCasesRelatedToLead
			updateCampaignMemberFields(objLead);
			updateLeadRelatedTracking(objLead, objOldLead);
			updateOutreachEngagementFields(objLead, objOldLead);
			updateChatTranscripts(objLead); //update chat transcripts for converted leads

			// send a callout to subscription apis in mulesoft when subscription changes on lead
			if (objOldLead != null && objLead.Customer_Subscriptions__c != objOldLead.Customer_Subscriptions__c) {
				list_LeadsToCallout.add(objLead);
			}
		}

		doLeadRoutingCallout(new Map<Id, Lead>(list_Leads), map_OldLeads);

		if (!list_LeadsToCallout.isEmpty()) {
			SubscriptionCenterUtil.calloutSubscription(list_LeadsToCallout, Lead.SObjectType);
		}

		if (!list_AccountToUpdateAccuticsInfo.isEmpty()) {
			AccountTriggerHelper.skipTrigger = true;
			update list_AccountToUpdateAccuticsInfo;
			AccountTriggerHelper.skipTrigger = false;
		}
		//process all DML operations
		processDMLOperation(false);
	}

	//before insert specific fields
	public void setDefaultInsertFields(Lead objLead) {
		setDefaultRecordType(objLead);
		setAQLDateTime(objLead, null);
		setG2CrowdEmployees(objLead);
		setLeadInitiatedDate(objLead, null);
		setFakeRecordDetails(objLead);
		setDefaultLeadSource(objLead);
		setDefaultZPCampaign(objLead);
		setDuplicateDetails(objLead);
	}

	//before update specific fields
	public void setDefaultUpdateFields(Lead objLead, Lead objOldLead) {
		setAQLDateTime(objLead, objOldLead);
		setLeadInitiatedDate(objLead, objOldLead);
		statusChangeValidation(objLead, objOldLead);
		setStandardFieldsFrom3rdParty(objLead);
		resetLeadStatusDet(objLead, objOldLead);
		resetLeadRecType(objLead);
		resetLeadCampaign(objLead, objOldLead);
	}

	/*** run post trigger updates ***/
	public void postTriggerUpdates(Lead objLead, Lead objOldLead, Boolean isInsert) {
		//default for before insert/update
		setUnqualifiedStatus(objLead, objOldLead);
		updateMQLReasonSalesGen(objLead, objOldLead);
		updateEmployeeCopy(objLead, objOldLead);
		updateLeadSourceDetailAffilateMQL(objLead, objOldLead);
		setOwnerAssignmentDate(objLead, objOldLead);
		setMQLReasonInAppJoinReq(objLead, objOldLead);
		setMQLFlag(objLead, objOldLead);
		setMQLReasonSignUpProgInterest(objLead, objOldLead);
		setRepNameSBGenHIOpp(objLead, objOldLead);
		setUniqueEmail(objLead, objOldLead);

		if (isInsert) {
			//before insert
			updateLeadStatusG2Crowd(objLead);
			setCreatedByRole(objLead);
			setInitialNumberOfEE(objLead);
		} else {
			//before update
			setMQLReasonSALConversion(objLead, objOldLead);
		}

		setMQLDate(objLead, objOldLead);
		setSALDate(objLead, objOldLead);
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Reset Lead Source when changed.
	 * @Parm        : objLead - New Lead
	 * @Parm        : objOldLead - Old Lead
	 * @Return      : N/A
	 **/
	public void resetLeadSource(Lead objLead, Lead objOldLead) {
		// Allow resetting Lead Source only if old or new value is Sourcing Error or Outbound
		if (
			(UserInfo.getProfileId() != LeadUtil.ID_ZP_SYSTEM_ADMINISTRATOR &&
			String.isNotBlank(objOldLead.LeadSource) &&
			objLead.LeadSource != objoldLead.LeadSource &&
			objOldLead.LeadSource != LeadUtil.LEADSOURCE_OUTBOUND &&
			objOldLead.LeadSource != LeadUtil.LEADSOURCE_SRC_ERROR &&
			objLead.LeadSource != LeadUtil.LEADSOURCE_OUTBOUND &&
			objLead.LeadSource != LeadUtil.LEADSOURCE_SRC_ERROR) ||
			(UserInfo.getUserId() == System.Label.ChiliPiper_UserId &&
			String.isNotBlank(objOldLead.LeadSource) &&
			objLead.LeadSource != objoldLead.LeadSource)
		) {
			// Reset Lead Source back to Old Value
			objLead.LeadSource = objOldLead.LeadSource;
		}
	}

	//sets fields that are common on before insert/before update
	public void setDefaultFields(Lead objLead, Lead objOldLead) {
		//set converted account id
		if (String.isNotBlank(objLead.ConvertedAccountId) && objLead.Converted_Account__c != objLead.ConvertedAccountId) {
			objLead.Converted_Account__c = objLead.ConvertedAccountId;
		}

		//if lead states is blank - get state code from state field
		if (String.isBlank(objLead.Lead_States__c) && String.isNotBlank(objLead.State)) {
			objLead.Lead_States__c = Utils.getStateCode(objLead.State);
		}

		//set default for tax fields
		objLead.Sales_Tax_Applicable__c = false;
		objLead.Sales_Tax_Info__c = '';

		if (String.isNotBlank(objLead.Lead_States__c)) {
			String[] strleadState = objLead.Lead_States__c.split(';');
			for (String strstate : strleadState) {
				String strTax = Utils.getTaxPct(strstate, '', '');
				if (String.isNotBlank(strTax)) {
					objLead.Sales_Tax_Applicable__c = true;
					objLead.Sales_Tax_Info__c = strTax;
					break;
				}
			}
		}

		//set next business day
		objLead.Next_Business_Day__c = Utils.getNextBusinessDay();

		//set Session Id First - to keep original value
		if (String.isBlank(objLead.Session_ID_First__c) && String.isNotBlank(objLead.Session_Id__c)) {
			objLead.Session_ID_First__c = objLead.Session_Id__c;
		}

		//set Visitor Id First - to keep original value
		if (String.isBlank(objLead.Visitor_Id_First__c) && String.isNotBlank(objLead.Visitor_Id__c)) {
			objLead.Visitor_Id_First__c = objLead.Visitor_Id__c;
		}

		//set lead stage change date - new lead and status update
		if (objOldLead == null || objOldLead.Status != objLead.Status) {
			objLead.Lead_Stage_Change_Date__c = System.now();
		}

		// Reset Company Lead Id if Lead Record Type is changed from Company to Reseller
		if (objOldLead != null && objOldLead.RecordTypeId != objLead.RecordTypeId && objLead.RecordTypeId == LeadUtil.RESELLER_LEAD_RT_ID) {
			objLead.ZP_Company_Lead_Id__c = null;
		}
	}

	/*** Set Default Record Type as Company - if missing ***/
	public void setDefaultRecordType(Lead objLead) {
		if (objLead.RecordTypeId == null) {
			//Company Record Typpe
			objLead.RecordTypeId = LeadUtil.COMPANY_LEAD_RT_ID;
			//Set Unique Email
			objLead.Unique_Email_Address__c = LeadUtil.map_RecordTypeToId.get(objLead.recordTypeId) + '-' + objLead.Email;
		}
	}

	public void setAQLDateTime(Lead objLead, Lead objOldLead) {
		if (objOldLead == null) {
			//set AQL date time if status is null or AQL during creation
			if (
				objLead.Status != null &&
				(objLead.Status ==
				LeadUtil.LEAD_STATUS_AQL || // AQL Status
				objLead.Status == LeadUtil.LEAD_STATUS_MQL) // If Lead is directly promoted to MQL, set AQL Date Time
			) {
				objLead.AQL_Date_Time__c = System.now();
			}
		} else {
			//set AQL date time if status is null or AQL during update
			if (
				String.isNotBlank(objLead.Status) &&
				objLead.Status != objOldLead.Status &&
				objLead.Status != LeadUtil.LEAD_STATUS_RAW &&
				objLead.AQL_Date_Time__c == null &&
				objLead.CreatedDate > LeadUtil.LEAD_CREATE_DATE
			) {
				objLead.AQL_Date_Time__c = System.now();
			}
		}
	}

	public void setG2CrowdEmployees(Lead objLead) {
		//G2 Crowd map
		if (String.isNotBlank(objLead.LeadSource) && String.isNotBlank(objLead.G2_Crowd_Company_Size__c) && objLead.LeadSource.equalsIgnoreCase(LeadUtil.G2_CROWD_LABEL)) {
			if (LeadUtil.map_G2CrowdLabelToEE.containsKey(objLead.G2_Crowd_Company_Size__c)) {
				objLead.NumberOfEmployees = LeadUtil.map_G2CrowdLabelToEE.get(objLead.G2_Crowd_Company_Size__c);
			}
		}
	}

	public void setLeadInitiatedDate(Lead objLead, Lead objOldLead) {
		if (objOldLead == null) {
			//set lead initiated timestamp if lead source not ABC -
			if (objLead.Lead_Initiated_Timestamp__c == null && (String.isNotBlank(objLead.LeadSource) && objLead.LeadSource != LeadUtil.LEADSOURCE_ABC)) {
				objLead.Lead_Initiated_Timestamp__c = System.now();
			}
		} else if (
			(objLead.Status != objOldLead.Status && objOldLead.Status == LeadUtil.LEAD_STATUS_RAW && objLead.Lead_Initiated_Timestamp__c == null && objLead.Status != LeadUtil.LEAD_STATUS_UNQ) ||
			(objLead.Lead_Initiated_Timestamp__c == null &&
			String.isNotBlank(objLead.LeadSource) &&
			objLead.LeadSource == LeadUtil.LEADSOURCE_ABC &&
			objLead.Status == LeadUtil.LEAD_STATUS_SAL &&
			objLead.isConverted)
		) {
			//update
			objLead.Lead_Initiated_Timestamp__c = System.now();
		}
	}

	public void setFakeRecordDetails(Lead objLead) {
		//track fake/test records
		if (objLead.Email != null || String.isNotBlank(objLead.Company)) {
			Boolean blnFakeLead = false;
			for (String str_email : LeadUtil.set_FakeEmails) {
				//set for Fake Emails
				if (objLead.Email != null && objLead.Email.contains(str_email)) {
					blnFakeLead = true;
				}
			}

			for (String str_compName : LeadUtil.set_TestCompanies) {
				if (String.isNotBlank(objLead.Company) && objLead.Company.contains(str_compName)) {
					blnFakeLead = true;
				}
			}

			if (blnFakeLead) {
				objLead.Fake_Record__c = true;
				objLead.Status = LeadUtil.LEAD_STATUS_UNQ; //Lead status "Unqualified"
				objLead.Lead_Status_Detail__c = LeadUtil.LEAD_STATUS_DET_TEST; //Lead Status detail "Test/Junk Record"
			}
		}
	}

	public void setDefaultLeadSource(Lead objLead) {
		//set lead source on creation
		if ((String.isBlank(objLead.LeadSource) || objLead.LeadSource == LeadUtil.LEADSOURCE_SRC_ERROR) && !UserUtils.isAdminIntgUser(LeadUtil.ID_CURRENT_USER)) {
			objLead.LeadSource = LeadUtil.LEADSOURCE_OUTBOUND; //Outbound
		}
	}

	public void setDefaultZPCampaign(Lead objLead) {
		//set default lead campaign
		if (String.isBlank(objLead.ZP_Lead_Campaign__c)) {
			objLead.ZP_Lead_Campaign__c = LeadUtil.LABEL_LEAD_CAMP_OTHER; //Other - Lead Campaign
		}
	}

	public void setDuplicateDetails(Lead objLead) {
		//set duplicate flag if email matching contact found
		if (String.isNotBlank(objLead.Email) && map_EmailToContact != null && map_EmailToContact.containsKey(objLead.Email)) {
			objLead.DuplicateConversionLead__c = true;
		}
	}

	/*** Set Number of Clients based on No_of_Clients_Bucket__c range ***/
	public void setNumberOfClients(Lead objLead, Lead objOldLead) {
		if (
			(objOldLead != null &&
			objOldLead.No_of_Clients_Bucket__c != objLead.No_of_Clients_Bucket__c) ||
			objOldLead == null ||
			(objLead.No_of_Clients__c == null ||
			objLead.No_of_Clients__c == 0)
		) {
			if (objLead.No_of_Clients__c == null || objLead.No_of_Clients__c == 0) {
				if (String.isNotBlank(objLead.No_of_Clients_Bucket__c) && LeadUtil.map_ClientsBucketRangeToNoOfClients.containsKey(objLead.No_of_Clients_Bucket__c)) {
					objLead.No_of_Clients__c = LeadUtil.map_ClientsBucketRangeToNoOfClients.get(objLead.No_of_Clients_Bucket__c);
				} else if (String.isNotBlank(objLead.No_of_Clients_Bucket__c)) {
					Integer intNoOfClient = 0;
					for (String strNoOfClientRange : objLead.No_of_Clients_Bucket__c.split('-')) {
						strNoOfClientRange = strNoOfClientRange.trim();
						if (strNoOfClientRange.isNumeric()) {
							intNoOfClient += Integer.valueOf(strNoOfClientRange);
						}
					}
					objLead.No_of_Clients__c = intNoOfClient / 2;
				}
			}
		}
	}

	/*** Set Consistent Referral Type ***/
	public void setReferralType(Lead objLead) {
		if (objLead.RecordTypeId == LeadUtil.COMPANY_LEAD_RT_ID && String.isNotBlank(objLead.Referral_Type__c) && objLead.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_PRU)) {
			objLead.Referral_Type__c = LeadUtil.REF_TYPE_USER_ROLE;
			objLead.Lead_Creation_Offer__c = LeadUtil.LEADCREATION_OFFER_PR;
		} else if (objLead.RecordTypeId == LeadUtil.RESELLER_LEAD_RT_ID && String.isNotBlank(objLead.Referral_Type__c) && objLead.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_UR)) {
			objLead.Referral_Type__c = LeadUtil.REF_TYPE_PARTNER_REF_USER;
			objLead.Lead_Creation_Offer__c = LeadUtil.LEADCREATION_OFFER_P2P;
		}
	}

	/*** Set Lead status to Unqualified ***/
	public void setUnqualifiedStatus(Lead objLead, Lead objOldLead) {
		if ((objOldLead == null || objLead.Status != objOldLead.Status) && objLead.Status == LeadUtil.LEAD_STATUS_UNQ) {
			objLead.Unqualified_Date__c = System.today();
		}
	}

	/*** Set MQL Date ***/
	public void setMQLDate(Lead objLead, Lead objOldLead) {
		if ((objOldLead == null || objLead.Status != objOldLead.Status) && objLead.Status == LeadUtil.LEAD_STATUS_MQL) {
			objLead.MQL_Date__c = System.today();
			objLead.MQL_Flag__c = LeadUtil.MQL_FLAG_YES;
			objLead.MQL_DateTime__c = System.now();
		}
	}

	/*** update MQL Reason for Sales Generated Conversations ***/
	public void updateMQLReasonSalesGen(Lead objLead, Lead objOldLead) {
		if (
			(objOldLead == null ||
			objLead.Status != objOldLead.Status) &&
			strCurrentUsrRoleName.contains(LeadUtil.SALES_ROLE) &&
			(objLead.Status == LeadUtil.LEAD_STATUS_SAL ||
			objLead.Status == LeadUtil.LEAD_STATUS_MQL)
		) {
			objLead.MQL_Reason__c = LeadUtil.MQL_REASON_SALES_GEN; //Sales Generated
		}
	}

	/*** update Number of Employee Copy - to be used for conversion later on ***/
	public void updateEmployeeCopy(Lead objLead, Lead objOldLead) {
		if (objOldLead == null || objLead.NumberOfEmployees != objOldLead.NumberOfEmployees) {
			objLead.Employees_Copy__c = objLead.NumberOfEmployees;
		}
	}

	/*** update Lead Source Detail and Lead status to MQL ***/
	public void updateLeadSourceDetailAffilateMQL(Lead objLead, Lead objOldLead) {
		if (
			!objLead.isConverted &&
			objLead.Expert_Market_Unique_ID__c != null &&
			(objLead.NumberOfEmployees != null &&
			objLead.NumberOfEmployees >= 10) &&
			(objOldLead == null || (objLead.NumberOfEmployees != objOldLead.NumberOfEmployees || objLead.Expert_Market_Unique_ID__c != objOldLead.Expert_Market_Unique_ID__c))
		) {
			objLead.Status = LeadUtil.LEAD_STATUS_MQL; //MQL
			objLead.Lead_Source_Detail__c = LeadUtil.LEAD_SRC_DET_AFFILIATES; //Affiliates
		}
	}

	/*** Set Lead Owner Assignment Date ***/
	public void setOwnerAssignmentDate(Lead objLead, Lead objOldLead) {
		if (objOldLead == null || objLead.OwnerId != objOldLead.OwnerId) {
			objLead.Lead_Owner_Assignment_Date__c = System.today();
		}
	}

	/*** Set MQL Reason for SAL Conversion ***/
	public void setMQLReasonSALConversion(Lead objLead, Lead objOldLead) {
		//if old status was "AQL", "RAW", "Back To Nurture", "Future Opportunity" or "Unqialified" and now is changed to SAL // for company leads only
		if (
			objLead.RecordTypeId == LeadUtil.COMPANY_LEAD_RT_ID &&
			objLead.Status != objOldLead.Status &&
			objLead.Status == LeadUtil.LEAD_STATUS_SAL &&
			(objOldLead.Status == LeadUtil.LEAD_STATUS_AQL ||
			objOldLead.Status == LeadUtil.LEAD_STATUS_RAW ||
			objOldLead.Status == LeadUtil.LEAD_STATUS_BACK_TO_NURT ||
			objOldLead.Status == LeadUtil.LEAD_STATUS_FUT_OPP ||
			objOldLead.Status == LeadUtil.LEAD_STATUS_UNQ)
		) {
			objLead.MQL_Reason__c = LeadUtil.MQL_REASON_SAL;
		}
	}

	/*** Set MQL Reason for In App Join Request ***/
	public void setMQLReasonInAppJoinReq(Lead objLead, Lead objOldLead) {
		Date dtMQLDateContact = objLead.MQL_Date__c != null ? objLead.MQL_Date__c : (objLead.isConverted ? objLead.ConvertedDate : null); //MQL Date (Contact) logic
		Boolean blnIsValid = validateInAppRequestMQL(objLead, objOldLead, true);

		if (objLead.Partner_Program_Request_Create_Date__c != null && blnIsValid && (dtMQLDateContact == null || dtMQLDateContact < LeadUtil.LAST_7_DAYS) && String.isBlank(objLead.Referral_Type__c)) {
			objLead.MQL_Reason__c = LeadUtil.MQL_REASON_IN_APP_JOIN_REQ; //In-App Join Request
		}
	}

	/*** Set MQL Reason for Sign Up Program Interest ***/
	public void setMQLReasonSignUpProgInterest(Lead objLead, Lead objOldLead) {
		Date dtMQLDateContact = objLead.MQL_Date__c != null ? objLead.MQL_Date__c : (objLead.isConverted ? objLead.ConvertedDate : null); //MQL Date (Contact) logic
		Boolean blnIsValid = validateInAppRequestMQL(objLead, objOldLead, false);

		if (objLead.Ramp_Intent__c && blnIsValid && (dtMQLDateContact == null || dtMQLDateContact < LeadUtil.LAST_7_DAYS) && String.isBlank(objLead.Referral_Type__c)) {
			objLead.MQL_Reason__c = LeadUtil.MQL_REASON_SIGN_UP_INT; //Sign-up program interest
		}
	}

	/*** Validate in app join request for MQL Reason ***/
	public Boolean validateInAppRequestMQL(Lead objLead, Lead objOldLead, Boolean isInApp) {
		//applies to both - In App Request and Sign Up Program Inerest
		if (objOldLead == null) {
			return true;
		}

		if (isInApp) {
			//In App Request
			if (objLead.Partner_Program_Request_Create_Date__c != objOldLead.Partner_Program_Request_Create_Date__c) {
				return true;
			}
			if (objLead.MQL_Date__c != objOldLead.MQL_Date__c) {
				return true;
			}
		} else {
			//Sign Up Program Interest
			if (objLead.Ramp_Intent__c != objOldLead.Ramp_Intent__c) {
				return true;
			}
		}

		return false;
	}

	/*** Set Initial Number Of Employees on Creation ***/
	public void setInitialNumberOfEE(Lead objLead) {
		if (objLead.NumberOfEmployees != null) {
			objLead.NumberOfEmployees_Lead__c = objLead.NumberOfEmployees;
		}
	}

	/*** Set MQL Flag ***/
	public void setMQLFlag(Lead objLead, Lead objOldLead) {
		if (objLead.Status == LeadUtil.LEAD_STATUS_SAL && objLead.MQL_Flag__c != LeadUtil.MQL_FLAG_YES && (objOldLead == null || objLead.Status != objOldLead.Status)) {
			objLead.MQL_Flag__c = LeadUtil.MQL_FLAG_YES; //MQL Flag => Yes
		}
	}

	/*** Set Rep name for Small Biz Generated HI Opportunity ***/
	public void setRepNameSBGenHIOpp(Lead objLead, Lead objOldLead) {
		Boolean blnIsValid = isValidRepName(objLead, objOldLead); //check if valid to run functionality

		if (
			objLead.RecordTypeId == LeadUtil.COMPANY_LEAD_RT_ID &&
			String.isBlank(objLead.Uncovered_HI_Opportunity__c) &&
			(objLead.Interested_In_Benefits__c == LeadUtil.LABEL_YES ||
			objLead.Offers_Small_Group_Benefits__c == LeadUtil.LABEL_YES) &&
			blnIsValid
		) {
			String strUncovHIOpp = !strCurrentUsrRoleName.contains(LeadUtil.SB_ROLE)
				? objOldLead.Uncovered_HI_Opportunity__c
				: (objCurrentUser != null ? objCurrentUser.Name : objOldLead.Uncovered_HI_Opportunity__c);
			objlead.Uncovered_HI_Opportunity__c = strUncovHIOpp;
		}
	}

	public Boolean isValidRepName(Lead objLead, Lead objOldLead) {
		if (objOldLead == null) {
			return true;
		} else if (objLead.Uncovered_HI_Opportunity__c != objOldLead.Uncovered_HI_Opportunity__c) {
			return true;
		} else if (objLead.Interested_In_Benefits__c != objOldLead.Interested_In_Benefits__c) {
			return true;
		} else if (objLead.Offers_Small_Group_Benefits__c != objOldLead.Offers_Small_Group_Benefits__c) {
			return true;
		}

		return false;
	}

	/*** Set Unique Email Id ***/
	public void setUniqueEmail(Lead objLead, Lead objOldLead) {
		if (objLead.Email != null && !LeadUtil.map_RecordTypeToId.isEmpty() && (objOldLead == null || objLead.Email != objOldLead.Email || objLead.RecordTypeId != objOldLead.RecordTypeId)) {
			objLead.Unique_Email_Address__c = LeadUtil.map_RecordTypeToId.get(objLead.recordTypeId) + '-' + objLead.Email;
		}
	}

	/*** update Lead Status to MQL for G2 Crowd ***/
	public void updateLeadStatusG2Crowd(Lead objLead) {
		if (
			String.isNotBlank(objLead.LeadSource) &&
			objLead.LeadSource.equalsIgnoreCase(LeadUtil.G2_CROWD_LABEL) &&
			!objLead.isConverted &&
			objLead.RecordTypeId == LeadUtil.COMPANY_LEAD_RT_ID &&
			(objLead.NumberOfEmployees > 4 &&
			objLead.NumberOfEmployees <= 100) &&
			UserUtils.isAdminIntgUser(LeadUtil.ID_CURRENT_USER)
		) {
			objLead.Status = LeadUtil.LEAD_STATUS_MQL; //MQL
		}
	}

	/*** set Created By Role ***/
	public void setCreatedByRole(Lead objLead) {
		if (String.isBlank(objLead.Created_by_Role__c)) {
			objLead.Created_by_Role__c = UserUtils.getCurrentOwnerRoleName(LeadUtil.ID_CURRENT_USER); //get created by user role name
		}
	}

	public void statusChangeValidation(Lead objLead, Lead objOldLead) {
		if (
			objLead.Status != objOldLead.Status &&
			!UserUtils.isAdminIntgUser(LeadUtil.ID_CURRENT_USER) &&
			objLead.Status != LeadUtil.LEAD_STATUS_BACK_TO_NURT &&
			objOldLead.Status != LeadUtil.LEAD_STATUS_FUT_OPP &&
			objOldLead.Status != LeadUtil.LEAD_STATUS_BACK_TO_NURT
		) {
			if (!LeadUtil.set_ExcludeStatusRevert.contains(objLead.Status)) {
				if (objLead.RecordTypeId == LeadUtil.COMPANY_LEAD_RT_ID && LeadUtil.map_CompLeadStatusOrder.get(objLead.Status) < LeadUtil.map_CompLeadStatusOrder.get(objOldLead.Status)) {
					//company lead
					objLead.Status = objOldLead.Status; //revert/do not allow status change - downgrade scenario
				} else if (objLead.RecordTypeId == LeadUtil.RESELLER_LEAD_RT_ID && LeadUtil.map_ResLeadStatusOrder.get(objLead.Status) < LeadUtil.map_ResLeadStatusOrder.get(objOldLead.Status)) {
					//Reseller lead
					objLead.Status = objOldLead.Status; //revert/do not allow status change - downgrade scenario
				}
			}
		}
	}

	public void resetLeadStatusDet(Lead objLead, Lead objOldLead) {
		if (
			objLead.Status == LeadUtil.LEAD_STATUS_SAL &&
			String.isNotBlank(objLead.Lead_Status_Detail__c) &&
			(objOldLead.Status == LeadUtil.LEAD_STATUS_FUT_OPP ||
			objOldLead.Status == LeadUtil.LEAD_STATUS_BACK_TO_NURT)
		) {
			objLead.Lead_Status_Detail__c = null;
		}
	}

	public void resetLeadRecType(Lead objLead) {
		//if company lead - and lead status detail is "Accountant/Bookkeeper"
		if (objLead.RecordTypeId == LeadUtil.COMPANY_LEAD_RT_ID && objLead.Lead_Status_Detail__c == LeadUtil.LEAD_STATUS_DET_ACC_BKR) {
			objLead.RecordTypeId = LeadUtil.RESELLER_LEAD_RT_ID;
			objLead.Status = LeadUtil.LEAD_STATUS_MQL;
		}

		//if reseller lead and lead status detail is  "Not an accountant"
		if (objLead.RecordTypeId == LeadUtil.RESELLER_LEAD_RT_ID && objLead.Lead_Status_Detail__c == LeadUtil.LEAD_STATUS_DET_NOT_ACC) {
			objLead.RecordTypeId = LeadUtil.COMPANY_LEAD_RT_ID;
			objLead.Status = LeadUtil.LEAD_STATUS_MQL;
		}
	}

	//prevent campaign change if it wasn't blank previously
	public void resetLeadCampaign(Lead objLead, Lead objOldLead) {
		if (
			(UserInfo.getProfileId() != LeadUtil.ID_ZP_SYSTEM_ADMINISTRATOR ||
			UserInfo.getUserId() == System.Label.ChiliPiper_UserId) &&
			String.isNotBlank(objOldLead.Zp_Lead_Campaign__c) &&
			objLead.Zp_Lead_Campaign__c != objOldLead.Zp_Lead_Campaign__c
		) {
			objLead.Zp_Lead_Campaign__c = objOldLead.Zp_Lead_Campaign__c;
		}
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Extract Domain from Email and Set it on Normalized Email Domain
	 * @Parm        : map_EmailToNormalizedValue - Map of Email and Normalized Domain values
	 * @Parm        : objLead - Trigger.new
	 * @Return      : NA
	 **/
	public void normalizeEmailDomains(Map<String, String> map_EmailToNormalizedValue, Lead objLead) {
		if (!map_EmailToNormalizedValue.isEmpty()) {
			if (map_EmailToNormalizedValue.containsKey(objLead.Email)) {
				objLead.Normalized_Email_Domain__c = map_EmailToNormalizedValue.get(objLead.Email);
			}
		}
	}

	/**** Normalize Phone Fields (Phone, Mobile Phone, Alternate Phone, Secondary Phone) ****/
	public void normalizeLeadPhoneFields(Lead objLead, Lead objOldLead) {
		if (objOldLead == null) {
			//lead insert
			// Normalization of Phone Fields (Phone, MobilePhone and OtherPhone)
			if (String.isNotBlank(objLead.Phone)) {
				objLead.Normalized_Phone__c = objNormalization.normalisePhoneField(objLead.Phone);
			}
			if (String.isNotBlank(objLead.MobilePhone)) {
				objLead.Normalized_Mobile_Phone__c = objNormalization.normalisePhoneField(objLead.MobilePhone);
			}
			if (String.isNotBlank(objLead.Alternate_Phone__c)) {
				objLead.Normalized_Alternate_Phone__c = objNormalization.normalisePhoneField(objLead.Alternate_Phone__c);
			}
			if (String.isNotBlank(objLead.Secondary_Phone__c)) {
				objLead.Normalized_Secondary_Phone__c = objNormalization.normalisePhoneField(objLead.Secondary_Phone__c);
			}
		} else {
			//lead update
			if (String.isBlank(objLead.Normalized_Phone__c) || (String.isNotBlank(objLead.Phone) && objLead.Phone != objOldLead.Phone)) {
				objLead.Normalized_Phone__c = objNormalization.normalisePhoneField(objLead.Phone);
			}
			if (String.isBlank(objLead.Normalized_Mobile_Phone__c) || (String.isNotBlank(objLead.MobilePhone) && objLead.MobilePhone != objOldLead.MobilePhone)) {
				objLead.Normalized_Mobile_Phone__c = objNormalization.normalisePhoneField(objLead.MobilePhone);
			}
			if (String.isBlank(objLead.Normalized_Alternate_Phone__c) || (String.isNotBlank(objLead.Alternate_Phone__c) && objLead.Alternate_Phone__c != objOldLead.Alternate_Phone__c)) {
				objLead.Normalized_Alternate_Phone__c = objNormalization.normalisePhoneField(objLead.Alternate_Phone__c);
			}
			if (String.isBlank(objLead.Normalized_Secondary_Phone__c) || (String.isNotBlank(objLead.Secondary_Phone__c) && objLead.Secondary_Phone__c != objOldLead.Secondary_Phone__c)) {
				objLead.Normalized_Secondary_Phone__c = objNormalization.normalisePhoneField(objLead.Secondary_Phone__c);
			}
		}

		// Set Phone number Exceptions if Phone not normalized properly
		if (String.isBlank(objLead.Normalized_Phone__c)) {
			objLead.Invalid_Field_Exceptions__c = LeadUtil.LABEL_INV_PHONE_EXC; //Invalid Phone Number Exception
		}
	}

	/**** set lead creation offer fields ****/
	public void setLeadCreationOffer(Lead objLead, Lead objOldLead) {
		if (objOldLead == null || String.isBlank(objLead.Lead_Creation_Offer__c)) {
			if (String.isNotBlank(objLead.LeadSource) && objLead.LeadSource.containsIgnoreCase(LeadUtil.LEADSOURCE_IB_PHONE)) {
				objLead.Lead_Creation_Offer__c = LeadUtil.LEADCREATION_OFFER_IB_PHONE; //lead ceration offer = "Inbound Phone"
			} else if (String.isNotBlank(objLead.LeadSource) && objLead.LeadSource == LeadUtil.LEADSOURCE_ABC) {
				objLead.Lead_Creation_Offer__c = LeadUtil.LEADCREATION_OFFER_ABC; //lead ceration offer = "Added By Client"
			} else if (
				String.isNotBlank(objLead.LeadSource) &&
				(objLead.LeadSource.containsIgnoreCase(LeadUtil.LEADCREATION_OFFER_G2) ||
				objLead.LeadSource.containsIgnoreCase(LeadUtil.LEADSOURCE_FT_SB) ||
				objLead.LeadSource.containsIgnoreCase(LeadUtil.LEADSOURCE_SOFTWARE_SUGGEST) ||
				objLead.LeadSource.containsIgnoreCase(LeadUtil.LEADSOURCE_SOFTWARESUGGEST))
			) {
				objLead.Lead_Creation_Offer__c = LeadUtil.LEADCREATION_OFFER_3RD_PARTY; //lead ceration offer = "3rd party integration"
			} else if (String.isNotBlank(objLead.Submitted_From__c) && objLead.Submitted_From__c.equalsIgnoreCase(LeadUtil.LEADCREATION_OFFER_INTR_DEMO)) {
				objLead.Lead_Creation_Offer__c = LeadUtil.LEADCREATION_OFFER_INTR_DEMO; //lead ceration offer = "interactive demo"
			} else if (String.isNotBlank(objLead.Referral_Type__c) && objLead.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_UR)) {
				objLead.Lead_Creation_Offer__c = LeadUtil.LEADCREATION_OFFER_PR; //lead ceration offer = "partner referral"
			} else if (String.isNotBlank(objLead.Referral_Type__c) && objLead.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_US)) {
				objLead.Lead_Creation_Offer__c = LeadUtil.LEADCREATION_OFFER_CR; //lead ceration offer = "customer referral"
			} else if (String.isNotBlank(objLead.Referral_Type__c) && objLead.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_PRU)) {
				objLead.Lead_Creation_Offer__c = LeadUtil.LEADCREATION_OFFER_P2P; //lead ceration offer = "p2p referral"
			} else if (String.isNotBlank(objLead.LeadSource) && objLead.LeadSource.containsIgnoreCase(LeadUtil.LEADSOURCE_API)) {
				objLead.Lead_Creation_Offer__c = LeadUtil.LEADCREATION_OFFER_API_PR; //lead ceration offer = "API Provisioning"
			} else if (String.isNotBlank(strCurrentUsrRoleName) && strCurrentUsrRoleName.containsIgnoreCase(LeadUtil.SALES_ROLE)) {
				objLead.Lead_Creation_Offer__c = LeadUtil.LEADCREATION_OFFER_SALES_GNR; //lead ceration offer = "sales generated"
			} else if (
				(LeadUtil.set_LeadCreationUserRoles.contains(UserInfo.getUserRoleId()) && UserInfo.getName() != LeadTriggerHelper.QUALIFIED_INTEGRATION_USERNAME) ||
				String.isNotBlank(objLead.ZP_Company_Lead_ID__c)
			) {
				objLead.Lead_Creation_Offer__c = LeadUtil.LEADCREATION_OFFER_PROD_GEN; //lead ceration offer = "Product Registration"
			}
		}
	}

	/**** run check domian functionality ****/
	public void checkDomain(Lead objLead, Lead objOldLead) {
		//execute functionality for before insert or before update - if Domain Match is false
		if (objLead.RecordtypeId == LeadUtil.RESELLER_LEAD_RT_ID && (objOldLead == null || (objOldLead != null && objOldLead.Domain_Match__c == false))) {
			//validate based on Email Domain
			if (String.isNotBlank(objLead.Email) && objLead.Email.contains('@')) {
				String str_EmailDomain = objLead.Email.substring(objLead.Email.indexof('@'), objLead.Email.length()).replace('@', '').trim();
				if (String.isNotBlank(str_EmailDomain) && map_ResellerDomainMap.containsKey(str_EmailDomain)) {
					objLead.Domain_Match__c = true;
					objLead.ABC_Match_Account__c = map_ResellerDomainMap.get(str_EmailDomain).Account__r.Id;
				}
			}

			//validate based on Accounting Firm Id
			if (objLead.Domain_Match__c == false && String.isNotBlank(objLead.ZP_Firm_ID__c) && map_ZPFrmIdToAccount.containsKey(objLead.ZP_Firm_ID__c)) {
				objLead.Domain_Match__c = true;
				objLead.ABC_Match_Account__c = map_ZPFrmIdToAccount.get(objLead.ZP_Firm_ID__c).Id;
			}
		}
	}

	/**** set partner referral fields ****/
	public void setPartnerReferralFields(Lead objLead) {
		if (set_ReferralTokens.size() > 0 && String.isNotBlank(objLead.Referral_Token__c)) {
			//if corresponding zp user exists
			if (map_RefTokenToZPUsr.containsKey(objLead.Referral_Token__c)) {
				ZP_User__c objZPUser = map_RefTokenToZPUsr.get(objLead.Referral_Token__c);

				//set referral account fields on lead
				setCurrentLeadRefFields(objLead, objZPUser);
				//set referred by contact on lead and update referral count on cont.
				setContactRefFields(objLead, objZPUser);
			}
			setLeadRefFields(objLead);
		}
	}

	/**** set Referred By Account ****/
	public void setCurrentLeadRefFields(Lead objLead, ZP_User__c objZPUser) {
		if (objZPUser.ZP_User_Roles__r != null) {
			for (ZP_User_Role__c objZPUsrRole : objZPUser.ZP_User_Roles__r) {
				//link to accounting firm
				if (
					String.isNotBlank(objZPUsrRole.Accounting_Firm_Id__c) &&
					objZPUsrRole.Collaborator_Type__c == LeadUtil.COLAB_TYPE_EXT_ACC &&
					map_FirmIdToAccRefer.containsKey(objZPUsrRole.Accounting_Firm_Id__c)
				) {
					objLead.Referred_by_Accounting_Firm__c = map_FirmIdToAccRefer.get(objZPUsrRole.Accounting_Firm_Id__c).Id;
				}
				//link to company account
				if (String.isNotBlank(objZPUsrRole.Company_Id__c) && objZPUsrRole.Collaborator_Type__c == LeadUtil.COLAB_TYPE_PAY_ADM && map_CompIdToAccRefer.containsKey(objZPUsrRole.Company_Id__c)) {
					objLead.Referred_by_Accounting_Firm__c = map_CompIdToAccRefer.get(objZPUsrRole.Company_Id__c).Id;
				}
			}
		}
	}

	/**** set Referred By Contact and update count on referral record ****/
	public void setContactRefFields(Lead objLead, ZP_User__c objZPUser) {
		//check contacts
		if (String.isNotBlank(objZPUser.Id__c) && map_ZPUsrIdContact.containsKey(objZPUser.Id__c)) {
			//by zp user id
			Contact objCon = map_ZPUsrIdContact.get(objZPUser.Id__c);
			if (map_ContactsForUpdate.containsKey(objCon.Id)) {
				//in case contact was added to map for update - get it/not to overwrite other updates
				objCon = map_ContactsForUpdate.get(objCon.Id);
			}

			objLead.Referred_by_Contact__c = objCon.Id;
			if (objCon.Number_of_Referred_Leads__c != null) {
				objCon.Number_of_Referred_Leads__c += 1; //increment
			} else {
				objCon.Number_of_Referred_Leads__c = 1; //set value
			}
			map_ContactsForUpdate.put(objCon.Id, objCon); //for DML
		} else if (String.isNotBlank(objZPUser.Email__c) && map_EmailToContact.containsKey(objZPUser.Email__c)) {
			//by email
			Contact objCon = map_EmailToContact.get(objZPUser.Email__c);
			if (map_ContactsForUpdate.containsKey(objCon.Id)) {
				//in case contact was added to map for update - get it/not to overwrite other updates
				objCon = map_ContactsForUpdate.get(objCon.Id);
			}

			objLead.Referred_by_Contact__c = objCon.Id;
			if (objCon.Number_of_Referred_Leads__c != null) {
				objCon.Number_of_Referred_Leads__c += 1; //increment
			} else {
				objCon.Number_of_Referred_Leads__c = 1; //set value
			}
			map_ContactsForUpdate.put(objCon.Id, objCon); //for DML
		}
	}

	/**** set Referred By Lead and update count on referral record ****/
	public void setLeadRefFields(Lead objLead) {
		//if corresponding lead exist
		if (map_RefTokenToLead.containsKey(objLead.Referral_Token__c)) {
			Lead objRefLead = map_RefTokenToLead.get(objLead.Referral_Token__c);
			if (map_LeadsForUpdate.containsKey(objRefLead.Id)) {
				//in case contact was added to map for update - get it/not to overwrite other updates
				objRefLead = map_LeadsForUpdate.get(objRefLead.Id);
			}

			objLead.Referred_by_Lead__c = objRefLead.Id;
			if (objRefLead.Number_of_Referred_Leads__c != null) {
				objRefLead.Number_of_Referred_Leads__c += 1; //increment
			} else {
				objRefLead.Number_of_Referred_Leads__c = 1; //set value
			}
			map_LeadsForUpdate.put(objRefLead.Id, objRefLead); //for DML
		}
	}

	/**** set Account Created Date by Company Id ****/
	public void setAccCreateDateByCompId(Lead objLead) {
		if (objLead.RecordTypeId == LeadUtil.COMPANY_LEAD_RT_ID) {
			if (
				String.isNotBlank(objLead.ZP_Company_ID__c) &&
				objLead.Account_Created_Date__c == null &&
				map_CompanyIdToAccount != null &&
				map_CompanyIdToAccount.containsKey(objLead.ZP_Company_ID__c)
			) {
				objLead.Account_Created_Date__c = map_CompanyIdToAccount.get(objLead.ZP_Company_ID__c).CreatedDate;
			}
		}
	}

	/**** set Account Created Date by Firm Id ****/
	public void setAccCreateDateByFirmId(Lead objLead) {
		if (objLead.RecordTypeId == LeadUtil.RESELLER_LEAD_RT_ID) {
			if (String.isNotBlank(objLead.ZP_Firm_ID__c) && objLead.Account_Created_Date__c == null && map_ZPFrmIdToAccount != null && map_ZPFrmIdToAccount.containsKey(objLead.ZP_Firm_ID__c)) {
				objLead.Account_Created_Date__c = map_ZPFrmIdToAccount.get(objLead.ZP_Firm_ID__c).CreatedDate;
			}
		}
	}

	/**** set Lead Source ****/
	public void setLeadSource(Lead objLead, Lead objOldLead) {
		//new lead or updated and lead source blank or Sourcing Error
		if (objOldLead == null || (objOldLead != null && (String.isBlank(objOldLead.LeadSource) || objOldLead.LeadSource == LeadUtil.LEADSOURCE_SRC_ERROR))) {
			if (String.isBlank(objLead.Referral_Token__c) && String.isNotBlank(objLead.Email)) {
				//if referral token is blank - but email exists
				if (map_EmailToLeads != null && !map_EmailToLeads.isEmpty() && map_EmailToLeads.containsKey(objLead.Email)) {
					//lead with same email exists
					Lead objInitialLead = map_EmailToLeads.get(objLead.Email);
					if (String.isNotBlank(objInitialLead.LeadSource) && String.isNotBlank(objInitialLead.ZP_Lead_Campaign__c) && String.isNotBlank(objInitialLead.Referral_Token__c)) {
						// ZP_Lead_Campaign__c should be set once i.e. when null
						if (String.isBlank(objLead.ZP_Lead_Campaign__c)) {
							objLead.ZP_Lead_Campaign__c = objInitialLead.ZP_Lead_Campaign__c;
						}
						objLead.Referral_Token__c = objInitialLead.Referral_Token__c;
					}
				}
			}
		}

		// set LeadSource strictly based on ReferralType.
		if (String.isNotBlank(objLead.Referral_Type__c)) {
			if (objLead.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_US)) {
				objLead.LeadSource = LeadUtil.LEADSOURCE_CR;
			} else if (objLead.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_UR)) {
				objLead.LeadSource = LeadUtil.LEADSOURCE_PR;
			} else if (objLead.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_PRU)) {
				objLead.LeadSource = LeadUtil.LEADSOURCE_P2P;
			}
		}
		// set lead source to "Sourcing Error" if value is blank
		if (objOldLead == null && String.isBlank(objLead.LeadSource)) {
			objLead.LeadSource = LeadUtil.LEADSOURCE_SRC_ERROR;
		}
	}

	/**** do lead routing ****/
	public void doLeadRouting(Lead objLead, Lead objOldLead) {
		String strCreatedByRole = UserUtils.getCurrentOwnerRoleName(objLead.CreatedById);
		String strUserInfoRole = UserUtils.getCurrentOwnerRoleName(UserInfo.getUserId());
		Set<String> set_RoleCreatedByUser = new Set<String>{
			'sales_sdr_mm_mgr_xx',
			'sales_sdr_mm_xx',
			'sales_bdr_xx_xx',
			'sales_sdr_partner_mgr_xx',
			'sales_sdr_partner_xx',
			'sales_mm_pr_xx',
			'sales_partner_ae_xx',
			'sales_partner_am_xx',
			'sales_partner_sam_xx'
		};
		if (objOldLead == null) {
			// lead insert
			if (
				String.isNotBlank(objLead.LeadSource) &&
				objLead.LeadSource != LeadUtil.LEADSOURCE_SRC_ERROR &&
				objLead.LeadSource != LeadUtil.LEADSOURCE_IB_PHONE &&
				!LeadUtil.set_ExcludeStatusRevert.contains(objLead.Status) &&
				(String.isBlank(strUserInfoRole) || (String.isNotBlank(strUserInfoRole) && !set_RoleCreatedByUser.contains(strUserInfoRole)))
			) {
				objLead.Lead_Route_Count__c = (objLead.Lead_Route_Count__c == null || objLead.Lead_Route_Count__c == 0) ? 1 : objLead.Lead_Route_Count__c + 1;
				objLead.UniqueEntry__RingLead_App_Field__c = null;
			}
		} else {
			String strOwnerRole = UserUtils.getCurrentOwnerRoleName(objLead.OwnerId);
			// if owner changes from rep from admin user, revert the change
			if (
				!LeadUtil.list_AllowStatus.contains(objLead.Status) &&
				objLead.OwnerId != objOldLead.OwnerId &&
				LeadUtil.INTEGRATION_USERS.contains(objLead.OwnerId) &&
				!LeadUtil.INTEGRATION_USERS.contains(objOldLead.OwnerId)
			) {
				objLead.OwnerId = objOldLead.OwnerId;
			}

			// if owner changes to Platform Integration User, revert the change
			if (objLead.OwnerId != objOldLead.OwnerId && objLead.OwnerId == LeadUtil.PLATFORM_INTEGRATION_USER_ID) {
				objLead.OwnerId = objOldLead.OwnerId;
			}

			if (
				(String.isBlank(strCreatedByRole) || (String.isNotBlank(strCreatedByRole) && !set_RoleCreatedByUser.contains(strCreatedByRole))) &&
				objLead.Route_to_Market__c == null &&
				(objLead.RecordTypeId != objOldLead.RecordTypeId ||
				((objLead.Status != objOldLead.Status && LeadUtil.list_AllowStatus.contains(objLead.Status)) ||
				(objLead.Status != objOldLead.Status &&
				LeadUtil.set_ExcludeRouting.contains(objOldLead.Status) &&
				!LeadUtil.set_ExcludeRouting.contains(objLead.Status) &&
				objLead.Status != LeadUtil.LEAD_STATUS_CONVERTED &&
				!strOwnerRole.containsIgnoreCase('sales'))))
			) {
				objLead.Lead_Route_Count__c = (objLead.Lead_Route_Count__c == null || objLead.Lead_Route_Count__c == 0) ? 1 : objLead.Lead_Route_Count__c + 1;
				objLead.UniqueEntry__RingLead_App_Field__c = null;
			}
		}

		// do not trigger flow that sends records to ring lead if code is run by test class
		if (Test.isRunningTest()) {
			objLead.Lead_Route_Count__c = 0;
		}
	}

	/**
	 * @Description : Helper method to find leads that need to be routed and call utility methods. This methods runs after insert/update.
	 * @Param       : Trigger new , Trigger old
	 * @Return      : N/A
	 **/
	public void doLeadRoutingCallout(Map<Id, Lead> map_newLeads, Map<Id, Lead> map_oldLeads) {
		try {
			Map<Id, Lead> map_LeadIdToLeadsNeedRouting = new Map<Id, Lead>();
			//Check if lead is meant to be routed (route count updated before insert/update) and add to collection.
			for (Id idLead : map_newLeads.keySet()) {
				Lead objOldLead = map_oldLeads?.get(idLead);
				Lead objNewLead = map_newLeads.get(idLead);
				if (objOldLead == null && objNewLead.Lead_Route_Count__c != null && objNewLead.Lead_Route_Count__c > 0) {
					map_LeadIdToLeadsNeedRouting.put(objNewLead.Id, objNewLead);
				} else if (objOldLead != null && objNewLead.Lead_Route_Count__c != objOldLead.Lead_Route_Count__c && objNewLead.Lead_Route_Count__c > 0) {
					map_LeadIdToLeadsNeedRouting.put(objNewLead.Id, objNewLead);
				}
			}
			//If this is triggered by GF lead queueable, call immediately (as context is already Queueable)
			if (GFLeadTriggerHelper.queue) {
				//collect remaining callouts
				map_LeadIdToLeadsNeedRouting = SendLeadToRingLead.doCallout(map_LeadIdToLeadsNeedRouting);
			}
			//if triggered by batch and callouts are remaining, call immediately.
			if (!map_LeadIdToLeadsNeedRouting.isEmpty() && System.isBatch() && (Limits.getLimitCallouts() - Limits.getCallouts() > 0)) {
				map_LeadIdToLeadsNeedRouting = SendLeadToRingLead.doCallout(map_LeadIdToLeadsNeedRouting);
				if (!map_LeadIdToLeadsNeedRouting.isEmpty()) {
					//if callouts are remaining, log exception.
					String strMessage = '*****SendLeadToRingLead - remaining callouts failed due to insufficient resources*****';
					ExceptionLogUtil.logExceptionWithId(
						'SendLeadToRingLead',
						'doLeadRoutingCallout',
						strMessage,
						null,
						new Set<String>((List<String>) new List<Id>(map_LeadIdToLeadsNeedRouting.keySet()))
					);
				}
			} else if (!map_LeadIdToLeadsNeedRouting.isEmpty() && System.isBatch() && (Limits.getLimitCallouts() - Limits.getCallouts() == 0)) {
				//if triggered by batch and callouts are remaining, log exception.
				String strMessage = '*****SendLeadToRingLead - remaining callouts failed due to insufficient resources*****';
				ExceptionLogUtil.logExceptionWithId(
					'SendLeadToRingLead',
					'doLeadRoutingCallout',
					strMessage,
					null,
					new Set<String>((List<String>) new List<Id>(map_LeadIdToLeadsNeedRouting.keySet()))
				);
			}
			//if triggered synchronously OR callouts are remaining post immediate processing and queuable resource available, enqueue new job to handle callouts.
			if (!map_LeadIdToLeadsNeedRouting.isEmpty() && (Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() > 0)) {
				Id idQueueJobId = System.enqueueJob(new SendLeadToRingLead(map_LeadIdToLeadsNeedRouting));
			} else if (!map_LeadIdToLeadsNeedRouting.isEmpty() && (Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() == 0)) {
				// if callouts are remaining and queuable resource unavailable, log exception.
				String strMessage = '*****SendLeadToRingLead - remaining callouts failed due to insufficient resources*****';
				ExceptionLogUtil.logExceptionWithId(
					'SendLeadToRingLead',
					'doLeadRoutingCallout',
					strMessage,
					null,
					new Set<String>((List<String>) new List<Id>(map_LeadIdToLeadsNeedRouting.keySet()))
				);
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('SendLeadToRingLead', 'doLeadRoutingCallout', objException.getMessage(), objException.getStackTraceString());
		}
	}

	/*** Collect lead ids if owner was changed ***/
	public void doPostRoutingValidation(Lead objLead, Lead objOldLead) {
		if (objLead.OwnerId != objOldLead.OwnerId) {
			set_LeadIdsForTasks.add(objLead.Id);
		}
	}

	/*** Sed MDR and SDR on ownership update ***/
	public void setSdrMdr(Lead objLead, Lead objOldLead) {
		if (objLead.OwnerId != null) {
			String strOwnerRole = UserUtils.getCurrentOwnerRoleName(objLead.OwnerId);

			if (objOldLead == null) {
				//insert
				if (String.isNotBlank(strOwnerRole) && strOwnerRole.containsIgnoreCase(LeadUtil.MDR_ROLE)) {
					objLead.MDR__c = objLead.OwnerId; //set MDR
				} else if (String.isNotBlank(strOwnerRole) && strOwnerRole.containsIgnoreCase(LeadUtil.SDR_ROLE)) {
					objLead.SDR__c = objLead.OwnerId; //set SDR
				}
			} else {
				//update
				if (objLead.OwnerId != objOldLead.OwnerId && String.isNotBlank(strOwnerRole)) {
					if (strOwnerRole.containsIgnoreCase(LeadUtil.MDR_ROLE)) {
						objLead.MDR__c = objLead.OwnerId; //set MDR
					} else if (strOwnerRole.containsIgnoreCase(LeadUtil.SDR_ROLE)) {
						objLead.SDR__c = objLead.OwnerId; //set SDR
					}
				}
			}
		}
	}

	/**** set MDR fields ****/
	public void setMDRFields(Lead objLead, Lead objOldLead) {
		if (objOldLead == null || (objOldLead != null && objLead.OwnerId != objOldLead.OwnerId)) {
			//generate current and previous owner user info
			User objCurOwnerUsr = objLead.OwnerId != null ? UserUtils.getOwnerUsrInfo(objLead.OwnerId) : null;
			User objOldOwnerUsr = objOldLead != null && objOldLead.OwnerId != null ? UserUtils.getOwnerUsrInfo(objOldLead.OwnerId) : null;

			//generate curret and previous owners role name
			String strCurOwnerRoleName = objCurOwnerUsr != null && objCurOwnerUsr.UserRoleId != null ? objCurOwnerUsr.UserRole.Name : '';
			String strOldOwnerRoleName = objOldOwnerUsr != null && objOldOwnerUsr.UserRole != null ? objOldOwnerUsr.UserRole.Name : '';

			//validate if current or previous owner was MDR rep
			Boolean strIsMDROwner = String.isBlank(strCurOwnerRoleName) ? false : strCurOwnerRoleName.contains(LeadUtil.MDR_ROLE);
			Boolean strWasMDROwner = String.isBlank(strOldOwnerRoleName) ? false : strOldOwnerRoleName.contains(LeadUtil.MDR_ROLE);

			if (objOldLead == null && strIsMDROwner && objLead.MDR_Received__c == null) {
				objLead.MDR_Received__c = System.now();
			}

			if (objOldLead != null) {
				if (strWasMDROwner && !strIsMDROwner) {
					objLead.MDR_Passed__c = System.now();
				}
				if (objLead.MDR_Received__c == null && !strWasMDROwner && strIsMDROwner) {
					objLead.MDR_Received__c = System.now();
				}
			}

			if (objOldLead != null) {
				//reset mdr fields on update - when owner changes.
				objLead.MDR_Activity__c = false;
				objLead.MDR_Demo_Booked__c = false;
			}
		}
	}

	/*** Generate random number and set it on random cohort field ***/
	public void setRandomCohort(Lead objLead) {
		if (objLead.Cohort_Random_Sample_1__c == null || objLead.Cohort_Random_Sample_1__c == 0) {
			objLead.Cohort_Random_Sample_1__c = RandomNumberGenerator.generateRandomNumber(1, 10);
		}
	}

	/**** set lead owner role ****/
	public void setLeadAssignmentOwnerRole(Lead objLead, Lead objOldLead) {
		if (objOldLead == null || (objOldLead != null && objLead.OwnerId != objOldLead.OwnerId)) {
			objLead.Lead_Owner_Role_at_assigned__c = objLead.OwnerId != null ? UserUtils.getCurrentOwnerRoleName(objLead.OwnerId) : '';
		}
	}

	/**** generate source keys ****/
	public static String generateSourceKey(Lead objLead, Lead objOldLead, Boolean isDataCollect) {
		String strSourceKey = '';

		if (String.isNotBlank(objLead.LeadSource) || String.isNotBlank(objLead.ZP_Lead_Campaign__c)) {
			if (objLead.RecordTypeId == LeadUtil.COMPANY_LEAD_RT_ID) {
				//Company Leads

				if (String.isNotBlank(objLead.LeadSource) && String.isNotBlank(objLead.ZP_Lead_Campaign__c) && String.isBlank(objLead.Referral_Token__c)) {
					strSourceKey = objLead.LeadSource + '#' + objLead.ZP_Lead_Campaign__c;
				} else if (String.isNotBlank(objLead.LeadSource) && String.isBlank(objLead.ZP_Lead_Campaign__c) && String.isBlank(objLead.Referral_Token__c)) {
					strSourceKey = objLead.LeadSource + '#';
				} else if (String.isNotBlank(objLead.ZP_Lead_Campaign__c) && String.isBlank(objLead.LeadSource) && String.isBlank(objLead.Referral_Token__c)) {
					strSourceKey = '#' + objLead.ZP_Lead_Campaign__c;
				} else if (
					String.isBlank(objLead.ZP_Lead_Campaign__c) &&
					String.isNotBlank(objLead.LeadSource) &&
					objLead.LeadSource.equalsIgnoreCase(LeadUtil.LEADSOURCE_PR) &&
					String.isNotBlank(objLead.Referral_Token__c)
				) {
					strSourceKey = objLead.LeadSource + '#';
				} else if (String.isNotBlank(objLead.Referral_Token__c) && (String.isBlank(objLead.LeadSource) || !objLead.LeadSource.equalsIgnoreCase(LeadUtil.LEADSOURCE_PR))) {
					strSourceKey = 'Referral' + '#' + 'Referral';
				} else {
					strSourceKey = '#';
				}

				set_SourceKeys.add(strSourceKey.toLowerCase());
				if (objOldLead != null) {
					//add map only on lead update - since on insert id isn't yet created.
					map_LeadIdToSrcKey.put(objLead.Id, strSourceKey.toLowerCase());
				}
			} else if (objLead.RecordTypeId == LeadUtil.RESELLER_LEAD_RT_ID) {
				//Reseller Leads
				if (String.isNotBlank(objLead.LeadSource) && String.isNotBlank(objLead.ZP_Lead_Campaign__c)) {
					strSourceKey = objLead.LeadSource + '#' + objLead.ZP_Lead_Campaign__c;
				} else if (String.isNotBlank(objLead.LeadSource) && String.isBlank(objLead.ZP_Lead_Campaign__c)) {
					strSourceKey = objLead.LeadSource + '#';
				} else if (String.isBlank(objLead.LeadSource) && String.isNotBlank(objLead.ZP_Lead_Campaign__c)) {
					strSourceKey = '#' + objLead.ZP_Lead_Campaign__c;
				} else if (String.isBlank(objLead.LeadSource) && String.isBlank(objLead.ZP_Lead_Campaign__c)) {
					strSourceKey = '#';
				} else {
					strSourceKey = '#';
				}

				if (isDataCollect) {
					set_SourceKeys.add(strSourceKey.toLowerCase());
					if (
						objOldLead !=
						null //add map only on lead update - since on insert id isn't yet created.
					) {
						map_LeadIdToSrcKey.put(objLead.Id, strSourceKey.toLowerCase());
					}
				}
			}
		}
		return strSourceKey;
	}

	/**** Generate maps for Marketing Source Maps ****/
	public void generateMktgSourceMap() {
		for (Marketing_Source_Map__c objMSM : [SELECT Id, Source_Key__c, Type__c, Has_Referral_Token__c FROM Marketing_Source_Map__c WHERE Source_Key__c IN :set_SourceKeys]) {
			if (
				objMSM.Type__c ==
				LeadUtil.LABEL_COMPANY //company type
			) {
				map_CompanyMSKeyMap.put(objMSM.Source_Key__c, objMSM.Id);
			} else if (
				objMSM.Type__c ==
				LeadUtil.LABEL_RESELLER //reseller type
			) {
				map_ResellerMSKeyMap.put(objMSM.Source_Key__c, objMSM.Id);
			}
		}
	}

	/**** Link Marketing Source Map to Lead ****/
	public void setSourceMap(Lead objLead, Lead objOldLead) {
		String strSourceKey = '';
		if (objOldLead == null) {
			strSourceKey = generateSourceKey(objLead, null, false);
			if (String.isNotBlank(strSourceKey)) {
				strSourceKey = strSourceKey.toLowerCase();
			}
		} else {
			strSourceKey = map_LeadIdToSrcKey.containsKey(objLead.Id) ? map_LeadIdToSrcKey.get(objLead.Id) : '';
		}
		if (String.isBlank(objLead.Accutics_ID__c)) {
			// if Accutics_ID__c does not exist in lead, then only run the SourceMap logic
			if (objLead.RecordTypeId == LeadUtil.COMPANY_LEAD_RT_ID) {
				if (String.isNotBlank(strSourceKey) && map_CompanyMSKeyMap.containsKey(strSourceKey)) {
					objLead.Source_Map__c = map_CompanyMSKeyMap.get(strSourceKey);
				} else {
					objLead.Source_Map__c = null;
				}
			} else if (objLead.RecordTypeId == LeadUtil.RESELLER_LEAD_RT_ID) {
				if (String.isNotBlank(strSourceKey) && map_ResellerMSKeyMap.containsKey(strSourceKey)) {
					objLead.Source_Map__c = map_ResellerMSKeyMap.get(strSourceKey);
				} else {
					objLead.Source_Map__c = null;
				}
			}
		}
	}

	/**** Create Lead Related Tracking ****/
	public void createLeadRelatedTracking(Lead objLead) {
		Lead_Related_Tracking__c objLeadRelTrack = new Lead_Related_Tracking__c();
		objLeadRelTrack.Lead__c = objLead.Id;
		objLeadRelTrack.Unique_Lead_Id__c = objLead.Id;
		objLeadRelTrack.Created_At__c = objLead.CreatedDate;

		if (objLead.Status == LeadUtil.LEAD_STATUS_MQL) {
			objLeadRelTrack.MQL_Datetime__c = System.now();

			//Lead_Owner_Role_at_assigned__c - is set in before insert, if owner not null
			if (String.isNotBlank(objLead.Lead_Owner_Role_at_assigned__c) && objLead.Lead_Owner_Role_at_assigned__c.containsIgnoreCase(LeadUtil.SDR_ROLE)) {
				objLeadRelTrack.MDR_Rep_assignment_date__c = System.now();
			}

			if (objBusinessHour != null) {
				objLeadRelTrack.Within_Business_Hours__c = BusinessHours.isWithin(objBusinessHour.Id, objLeadRelTrack.MQL_Datetime__c);
			}
		}

		list_LeadRelTracking.add(objLeadRelTrack);
	}

	/** Update Leaad related Tracking/ or create new if such doesn't exist */
	public void updateLeadRelatedTracking(Lead objLead, Lead objOldLead) {
		//map_LeadIdToRelTrack
		if (map_LeadIdToRelTrack.containsKey(objLead.Id)) {
			//if record exists - update
			Lead_Related_Tracking__c objLeadRelTrack = map_LeadIdToRelTrack.get(objLead.Id);
			// updated lead related tracking if lead owner changes or status changes to MQL
			// if lead owner changes, reset time to first call by owner
			// if lead status changes to MQL, set MQL date/time and within business hours flag
			if (objLead.OwnerId != objOldLead.OwnerId || objLead.Status != objOldLead.Status) {
				if (objLead.OwnerId != objOldLead.OwnerId) {
					objLeadRelTrack.Time_to_First_Call_by_Owner__c = null;
					String strOwnerRole = UserUtils.getCurrentOwnerRoleName(objLead.OwnerId); //get owner role
					if (objLead.Status == LeadUtil.LEAD_STATUS_MQL && String.isNotBlank(strOwnerRole) && strOwnerRole.containsIgnoreCase(LeadUtil.SDR_ROLE)) {
						objLeadRelTrack.MDR_Rep_assignment_date__c = System.now();
					}
				}

				if (objLead.Status != objOldLead.Status) {
					if (objLead.Status == LeadUtil.LEAD_STATUS_MQL) {
						objLeadRelTrack.MQL_Datetime__c = System.now();

						if (objBusinessHour != null) {
							objLeadRelTrack.Within_Business_Hours__c = BusinessHours.isWithin(objBusinessHour.Id, objLeadRelTrack.MQL_Datetime__c);
						}
					}
				}

				list_LeadRelTracking.add(objLeadRelTrack);
			}
		} else {
			//if record doesn't exist - create neww
			createLeadRelatedTracking(objLead);
		}
	}

	/**** Update MDR Activity ****/
	public void updateLeadMDRActivity(Lead objLead, Lead objOldLead) {
		if (objLead.RecordTypeId == LeadUtil.RESELLER_LEAD_RT_ID && String.isNotBlank(objLead.ConvertedAccountId) && objOldLead != null && String.isBlank(objOldLead.ConvertedAccountId)) {
			if (set_MDRActivityResAccs.contains(objLead.ConvertedAccountId)) {
				objLead.MDR_Activity__c = false;
			}
		}
	}

	public void validateLeadFrmTask(Lead objLead, Lead objOldLead) {
		//query task data - only 1 time.
		if (map_LeadIdToTskList.size() <= 0 || map_LeadIdToTskList == null) {
			map_LeadIdToTskList = queryLeadTasks();
		}

		if (map_LeadIdToTskList != null && map_LeadIdToTskList.size() > 0 && map_LeadIdToTskList.containsKey(objLead.Id)) {
			List<Task> list_Tasks = map_LeadIdToTskList.get(objLead.Id);
			for (Task objTask : list_Tasks) {
				String strTaskType = objTask.Type != null ? objTask.Type : '';
				if (
					(objTask.RecordTypeId == TaskUtil.TASK_DEMO_RT_ID || objTask.RecordTypeId == TaskUtil.TASK_CALL_RT_ID) &&
					(objTask.Status == TaskUtil.TASK_STATUS_CONNECT ||
					objTask.Status == TaskUtil.TASK_STATUS_COMPLETE)
				) {
					objLead.MDR_Activity__c = true;
				}

				if (objTask.RecordTypeId == TaskUtil.TASK_DEMO_RT_ID || strTaskType.indexOf(TaskUtil.TASK_DEMO_RT_ID) > -1) {
					objLead.MDR_Demo_Booked__c = true;
				}
			}
		}
	}

	/**** Update Sourcing on Converted records Account/Opportunity/Contact ****/
	public void updateConvertedRecData(Lead objLead, Lead objOldLead) {
		//Company Id, ZP Company Lead Id, Source Id - attribution update
		updateConvertedRecDataAttr(objLead, objOldLead);
		//SAL Reason Update
		updateConvertedRecDataSALReason(objLead, objOldLead);
		//Microdeposit Fraud updates
		updateConvertedRecDataFraud(objLead, objOldLead);
		//TBC fields update
		updateTBCDataOnAccount(objLead, objOldLead);
	}

	public void updatedAccountAndOppPostConversion(Lead objLead, Lead objOldLead) {
		if (objLead.IsConverted) {
			Boolean blnProcessAccUpdate = false;
			if (String.isNotBlank(objLead.ConvertedAccountId) && map_ConvertedAccIdToAcc.containsKey(objLead.ConvertedAccountId)) {
				Account objAcc = map_AccountsForUpdate.containsKey(objLead.ConvertedAccountId)
					? map_AccountsForUpdate.get(objLead.ConvertedAccountId)
					: map_ConvertedAccIdToAcc.get(objLead.ConvertedAccountId);
				if (objAcc != null) {
					if (objAcc.Accutics_ID__c == null) {
						objAcc.Accutics_ID__c = objLead.Accutics_ID__c;
						blnProcessAccUpdate = true;
					}

					if (objAcc.ZP_Lead_Campaign__c == null) {
						objAcc.ZP_Lead_Campaign__c = objLead.ZP_Lead_Campaign__c;
						blnProcessAccUpdate = true;
					}

					if (objAcc.Lead_Channel__c == null) {
						if (objLead.Lead_Channel__c != null) {
							objAcc.Lead_Channel__c = objLead.Lead_Channel__c;
							blnProcessAccUpdate = true;
						} else {
							objAcc.Lead_Channel__c = objLead.Marketing_Channel__c;
							blnProcessAccUpdate = true;
						}
					}

					if (objAcc.Lead_Medium__c == null) {
						if (objLead.Accutics_Lead_Medium__c != null) {
							objAcc.Lead_Medium__c = objLead.Accutics_Lead_Medium__c;
							blnProcessAccUpdate = true;
						} else {
							objAcc.Lead_Medium__c = objLead.Marketing_Program__c;
							blnProcessAccUpdate = true;
						}
					}

					if (objAcc.Lead_Source__c == null) {
						if (objLead.LeadSource != null) {
							objAcc.Lead_Source__c = objLead.LeadSource;
							blnProcessAccUpdate = true;
						}
					}
				}
				if (blnProcessAccUpdate) {
					//map_AccountsForUpdate.put(objAcc.Id, objAcc); //prepear for DML
					list_AccountToUpdateAccuticsInfo.add(objAcc);
				}
			}
			if (String.isNotBlank(objLead.ConvertedOpportunityId) && map_ConvertedOppIdToOpp.containsKey(objLead.ConvertedOpportunityId)) {
				Opportunity objOpp = map_OppsForUpdate.containsKey(objLead.ConvertedOpportunityId)
					? map_OppsForUpdate.get(objLead.ConvertedOpportunityId)
					: map_ConvertedOppIdToOpp.get(objLead.ConvertedOpportunityId);
				Boolean blnIsOppUpdated = false;
				if (objOpp != null) {
					if (objOpp.Accutics_ID__c == null) {
						objOpp.Accutics_ID__c = objLead.Accutics_ID__c;
						blnIsOppUpdated = true;
					}

					if (objOpp.Lead_Campaign__c == null) {
						objOpp.Lead_Campaign__c = objLead.ZP_Lead_Campaign__c;
						blnIsOppUpdated = true;
					}

					if (objOpp.Lead_Channel__c == null) {
						if (objLead.Lead_Channel__c != null) {
							objOpp.Lead_Channel__c = objLead.Lead_Channel__c;
							blnIsOppUpdated = true;
						} else {
							objOpp.Lead_Channel__c = objLead.Marketing_Channel__c;
							blnIsOppUpdated = true;
						}
					}

					if (objOpp.Lead_Medium__c == null) {
						if (objLead.Accutics_Lead_Medium__c != null) {
							objOpp.Lead_Medium__c = objLead.Accutics_Lead_Medium__c;
							blnIsOppUpdated = true;
						} else {
							objOpp.Lead_Medium__c = objLead.Marketing_Program__c;
							blnIsOppUpdated = true;
						}
					}

					if (objOpp.LeadSource == null) {
						if (objLead.LeadSource != null) {
							objOpp.LeadSource = objLead.LeadSource;
							blnIsOppUpdated = true;
						}
					}
				}

				if (blnIsOppUpdated) {
					map_OppsForUpdate.put(objOpp.Id, objOpp); //prepear for DML
				}
			}
		}
	}

	/**** update converted record attribution - source and company id ****/
	public void updateConvertedRecDataAttr(Lead objLead, Lead objOldLead) {
		if (
			objLead.ZP_Company_Lead_ID__c != objOldLead.ZP_Company_Lead_ID__c ||
			objLead.ZP_Company_ID__c != objOldLead.ZP_Company_ID__c ||
			objLead.Referral_Type__c != objOldLead.Referral_Type__c ||
			objLead.OwnerId != objOldLead.OwnerId
		) {
			if (String.isNotBlank(objLead.ConvertedAccountId) && map_ConvertedAccIdToAcc.containsKey(objLead.ConvertedAccountId)) {
				//account update
				//check if account already exists in DML map
				Account objAcc = map_AccountsForUpdate.containsKey(objLead.ConvertedAccountId)
					? map_AccountsForUpdate.get(objLead.ConvertedAccountId)
					: map_ConvertedAccIdToAcc.get(objLead.ConvertedAccountId);
				Boolean blnProcessAccUpdate = false;
				if (String.isNotBlank(objLead.ZP_Company_Lead_ID__c) && objAcc.ZP_Company_Lead_ID__c != objLead.ZP_Company_Lead_ID__c) {
					objAcc.ZP_Company_Lead_ID__c = objLead.ZP_Company_Lead_ID__c;
					blnProcessAccUpdate = true;
				}
				// Sync Company Id from Lead to Account ONLY if existing value on Account is blank
				if (String.isNotBlank(objLead.ZP_Company_ID__c) && String.isBlank(objAcc.ZP_Company_ID__c) && objAcc.ZP_Company_ID__c != objLead.ZP_Company_ID__c) {
					objAcc.ZP_Company_ID__c = objLead.ZP_Company_ID__c;
					blnProcessAccUpdate = true;
				}
				// Set Referral Information (Referral Type and Referred By)
				if (
					String.isNotBlank(objLead.Referral_Type__c) &&
					(objLead.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_UR) || objLead.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_PRU))
				) {
					objAcc.Referral_Type__c = objLead.Referral_Type__c;
					blnProcessAccUpdate = true;
				}

				// lead owner changes and does not match with account owner, re-route account
				if (objLead.OwnerId != objOldLead.OwnerId && !UserUtils.isAdminIntgUser(objLead.OwnerId) && objAcc.OwnerId != objLead.OwnerId && UserUtils.isAdminIntgUser(objAcc.OwnerId)) {
					objAcc.OwnerId = objLead.OwnerId;
					blnProcessAccUpdate = true;
				}
				if (blnProcessAccUpdate) {
					map_AccountsForUpdate.put(objAcc.Id, objAcc); //prepear for DML
				}
			}

			if (String.isNotBlank(objLead.ConvertedOpportunityId) && map_ConvertedOppIdToOpp.containsKey(objLead.ConvertedOpportunityId)) {
				//opp update
				//check if opportunity already exists in DML map
				Opportunity objOpp = map_OppsForUpdate.containsKey(objLead.ConvertedOpportunityId)
					? map_OppsForUpdate.get(objLead.ConvertedOpportunityId)
					: map_ConvertedOppIdToOpp.get(objLead.ConvertedOpportunityId);
				Boolean blnIsOppUpdated = false;

				if (objLead.ZP_Company_ID__c != objOpp.ZP_Company_ID__c || objLead.ZP_Company_ID__c != objOpp.Source_ID__c || objLead.Referral_Type__c != objOpp.Referral_Type__c) {
					objOpp.ZP_Company_ID__c = objLead.ZP_Company_ID__c;
					objOpp.Source_ID__c = objLead.ZP_Company_ID__c;
					// Set Referral Information (Referral Type and Referred By)
					if (
						String.isNotBlank(objLead.Referral_Type__c) &&
						(objLead.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_UR) || objLead.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_PRU))
					) {
						objOpp.Referral_Type__c = objLead.Referral_Type__c;
					}

					blnIsOppUpdated = true;
				}

				if (blnIsOppUpdated) {
					map_OppsForUpdate.put(objOpp.Id, objOpp); //prepear for DML
				}
			}
		}
	}

	/**** update converted record attribution - SAL Reason ****/
	public void updateConvertedRecDataSALReason(Lead objLead, Lead objOldLead) {
		//SAL Reason Update - Opportunity
		if (String.isNotBlank(objLead.ConvertedOpportunityId) && String.isBlank(objOldLead.ConvertedOpportunityId) && map_ConvertedOppIdToOpp.containsKey(objLead.ConvertedOpportunityId)) {
			//opp update
			if (objLead.Status == LeadUtil.LEAD_STATUS_SAL && String.isNotBlank(objLead.SAL_Reason__c) && objLead.isConverted) {
				//check if opportunity already exists in DML map
				Opportunity objOpp = map_OppsForUpdate.containsKey(objLead.ConvertedOpportunityId)
					? map_OppsForUpdate.get(objLead.ConvertedOpportunityId)
					: map_ConvertedOppIdToOpp.get(objLead.ConvertedOpportunityId);
				if (objLead.SAL_Reason__c != objOpp.SAL_Reason__c) {
					objOpp.SAL_Reason__c = objLead.SAL_Reason__c;

					map_OppsForUpdate.put(objOpp.Id, objOpp); //prepear for DML
				}
			}
		}

		//SAL Reason Update - Contact
		if (String.isNotBlank(objLead.ConvertedContactId) && String.isBlank(objOldLead.ConvertedContactId) && map_ConvertedConIdToCon.containsKey(objLead.ConvertedContactId)) {
			//contact update
			if (objLead.Status == LeadUtil.LEAD_STATUS_SAL && String.isNotBlank(objLead.SAL_Reason__c) && objLead.isConverted) {
				//check if contact already exists in DML map
				Contact objCon = map_ContactsForUpdate.containsKey(objLead.ConvertedContactId)
					? map_ContactsForUpdate.get(objLead.ConvertedContactId)
					: map_ConvertedConIdToCon.get(objLead.ConvertedContactId);
				if (objLead.SAL_Reason__c != objCon.SAL_Reason__c) {
					objCon.SAL_Reason__c = objLead.SAL_Reason__c;

					map_ContactsForUpdate.put(objCon.Id, objCon); //prepear for DML
				}
			}
		}

		// Set first name on contact if it is NA
		if (String.isNotBlank(objLead.ConvertedContactId) && map_ConvertedConIdToCon.containsKey(objLead.ConvertedContactId)) {
			Contact objCon = map_ConvertedConIdToCon.get(objLead.ConvertedContactId);
			if (String.isNotBlank(objCon.FirstName) && objCon.FirstName.equalsIgnoreCase(LeadUtil.STRING_NA) && String.isNotBlank(objLead.FirstName) && objLead.FirstName != LeadUtil.STRING_NA) {
				objCon.FirstName = objLead.FirstName;
				map_ContactsForUpdate.put(objCon.Id, objCon);
			}
		}
	}

	public void updateConvertedRecDataFraud(Lead objLead, Lead objOldLead) {
		if (objLead.Potential_Fraud_Lead__c != objOldLead.Potential_Fraud_Lead__c) {
			if (String.isNotBlank(objLead.ConvertedAccountId) && map_ConvertedAccIdToAcc.containsKey(objLead.ConvertedAccountId)) {
				//account update
				//check if account already exists in DML map
				Account objAcc = map_AccountsForUpdate.containsKey(objLead.ConvertedAccountId)
					? map_AccountsForUpdate.get(objLead.ConvertedAccountId)
					: map_ConvertedAccIdToAcc.get(objLead.ConvertedAccountId);

				objAcc.Potential_Fraud_Account__c = objLead.Potential_Fraud_Lead__c;

				if (!objAcc.Potential_Fraud_Account__c) {
					objAcc.Potential_Fraud_Account__c = objLead.Potential_Fraud_Lead__c;
					if (objLead.Potential_Fraud_Lead__c && !objAcc.Potential_Fraud_History__c) {
						objAcc.Potential_Fraud_History__c = objLead.Potential_Fraud_Lead__c;
					}
				}
				map_AccountsForUpdate.put(objAcc.Id, objAcc); //prepear for DML
			}
		}
	}

	/** Set Referred By on Account/Opp */
	public void setSoldByReferredBy(Lead objLead, Lead objOldLead) {
		//Opportunity
		if (String.isNotBlank(objLead.ConvertedOpportunityId) && map_ConvertedOppIdToOpp.containsKey(objLead.ConvertedOpportunityId)) {
			//check if opportunity is already in DML map
			Opportunity objOpp = map_OppsForUpdate.containsKey(objLead.ConvertedOpportunityId)
				? map_OppsForUpdate.get(objLead.ConvertedOpportunityId)
				: map_ConvertedOppIdToOpp.get(objLead.ConvertedOpportunityId);
			if (String.isNotBlank(objLead.Referred_By__c) && objLead.Referred_By__c != objOpp.Referred_By__c) {
				//referred by check

				objOpp.Referred_By__c = objLead.Referred_By__c;
				map_OppsForUpdate.put(objOpp.Id, objOpp); //prepear for DML
			} else if (String.isNotBlank(objLead.Sold_By__c) && objLead.Sold_By__c != objOpp.Sold_By__c) {
				//sold by check
				objOpp.Sold_By__c = objLead.Sold_By__c;
				map_OppsForUpdate.put(objOpp.Id, objOpp); //prepear for DML
			}
		}

		//Account
		if (String.isNotBlank(objLead.ConvertedAccountId) && map_ConvertedAccIdToAcc.containsKey(objLead.ConvertedAccountId)) {
			//check if opportunity is already in DML map
			Account objAcc = map_AccountsForUpdate.containsKey(objLead.ConvertedAccountId)
				? map_AccountsForUpdate.get(objLead.ConvertedAccountId)
				: map_ConvertedAccIdToAcc.get(objLead.ConvertedAccountId);
			if (String.isNotBlank(objLead.Referred_By__c) && objLead.Referred_By__c != objAcc.Referred_By__c) {
				//referred by check
				objAcc.Referred_By__c = objLead.Referred_By__c;

				map_AccountsForUpdate.put(objAcc.Id, objAcc); //prepear for DML
			} else if (String.isNotBlank(objLead.Sold_By__c) && objLead.Sold_By__c != objAcc.Sold_By__c) {
				//sold by check
				objAcc.Sold_By__c = objLead.Sold_By__c;

				map_AccountsForUpdate.put(objAcc.Id, objAcc); //prepear for DML
			}
		}
	}

	/** Update Associated Contact on Lead Related Cases */
	public void updateLeadRelatedCases(Lead objLead, Lead objOldLead) {
		if (set_LeadIdForCases.contains(objLead.Id) && map_LeadIdToRelCases.containsKey(objLead.Id)) {
			List<Case> list_Cases = map_LeadIdToRelCases.get(objLead.Id);

			for (Case objCase : list_Cases) {
				if (map_CaseForUpdate.containsKey(objCase.Id)) {
					//in case Case record exists in DML map
					Case objDMLCase = map_CaseForUpdate.get(objCase.Id);
					objDMLCase.ContactId = objLead.ConvertedContactId;
					map_CaseForUpdate.put(objDMLCase.Id, objDMLCase);
				} else {
					//if case isn't yet in DML map
					objCase.ContactId = objLead.ConvertedContactId;
					map_CaseForUpdate.put(objCase.Id, objCase);
				}
			}
		}
	}

	/**
	 * @description Update CampaignMember Info from Lead.
	 * @author      Veeresh Kumar
	 * @param       objContact - New Lead
	 * @return      NA
	 **/
	public void updateCampaignMemberFields(Lead objLead) {
		if (map_LeadIdToCampaign.containsKey(objLead.Id)) {
			for (CampaignMember objMember : map_LeadIdToCampaign.get(objLead.Id)) {
				CampaignMember objMemberToUpdate = map_CampMemberForUpdate.containsKey(objMember.Id) ? map_CampMemberForUpdate.get(objMember.Id) : objMember;
				Boolean blnIsUpdated = false;

				if (objMemberToUpdate.HasResponded && String.isNotBlank(objMemberToUpdate.Campaign.Type) && LeadUtil.set_RecentSourceCampaignTypes.contains(objMemberToUpdate.Campaign.Type)) {
					if (String.isNotBlank(objLead.Recent_Source__c) && String.isBlank(objMemberToUpdate.Recent_Source__c)) {
						objMemberToUpdate.Recent_Source__c = objLead.Recent_Source__c;
						blnIsUpdated = true;
					}

					if (String.isNotBlank(objLead.Recent_Campaign__c) && String.isBlank(objMemberToUpdate.Recent_Campaign__c)) {
						objMemberToUpdate.Recent_Campaign__c = objLead.Recent_Campaign__c;
						blnIsUpdated = true;
					}

					if (String.isNotBlank(objLead.Recent_Content__c) && String.isBlank(objMemberToUpdate.Recent_Content__c)) {
						objMemberToUpdate.Recent_Content__c = objLead.Recent_Content__c;
						blnIsUpdated = true;
					}
				}

				if (blnIsUpdated) {
					map_CampMemberForUpdate.put(objMemberToUpdate.Id, objMemberToUpdate);
				}
			}
		}
	}

	/**** validate outreach fields - create new record or update existing ****/
	public void validateOutreach(Lead objLead, Lead objOldLead) {
		if (String.isNotBlank(objLead.ID_of_Currently_Active_Sequence__c) && objLead.ID_of_Currently_Active_Sequence__c != objOldLead.ID_of_Currently_Active_Sequence__c) {
			//create new record
			map_LeadIdToCUOutreach.put(objLead.Id, true);
		} else {
			Boolean blnSetData = false;
			if (
				(objLead.Actively_Being_Sequenced__c != objOldLead.Actively_Being_Sequenced__c) ||
				(String.isNotBlank(objLead.Current_Sequence_ID__c) && objLead.Current_Sequence_ID__c != objOldLead.Current_Sequence_ID__c) ||
				(String.isNotBlank(objLead.Current_Sequence_Name__c) && objLead.Current_Sequence_Name__c != objOldLead.Current_Sequence_Name__c) ||
				(String.isNotBlank(objLead.Current_Sequence_Status__c) && objLead.Current_Sequence_Status__c != objOldLead.Current_Sequence_Status__c) ||
				(objLead.Current_Sequence_Step_Number__c != null &&
				objLead.Current_Sequence_Step_Number__c != objOldLead.Current_Sequence_Step_Number__c) ||
				(String.isNotBlank(objLead.Current_Sequence_Step_Type__c) && objLead.Current_Sequence_Step_Type__c != objOldLead.Current_Sequence_Step_Type__c) ||
				(objLead.Current_Sequence_Task_Due_Date__c != null &&
				objLead.Current_Sequence_Task_Due_Date__c != objOldLead.Current_Sequence_Task_Due_Date__c) ||
				(String.isNotBlank(objLead.Current_Sequence_User_Name__c) && objLead.Current_Sequence_User_Name__c != objOldLead.Current_Sequence_User_Name__c) ||
				(String.isNotBlank(objLead.Current_Sequence_User_Integration_ID__c) && objLead.Current_Sequence_User_Integration_ID__c != objOldLead.Current_Sequence_User_Integration_ID__c) ||
				(objLead.Number_of_Active_Sequences__c != null &&
				objLead.Number_of_Active_Sequences__c != objOldLead.Number_of_Active_Sequences__c) ||
				(objLead.Number_of_Active_Sequence_Tasks__c != null &&
				objLead.Number_of_Active_Sequence_Tasks__c != objOldLead.Number_of_Active_Sequence_Tasks__c) ||
				(String.isNotBlank(objLead.Finished_Sequence__c) && objLead.Finished_Sequence__c != objOldLead.Finished_Sequence__c)
			) {
				blnSetData = true;
			}

			if (blnSetData) {
				map_LeadIdToCUOutreach.put(objLead.Id, false);
				set_OutreachLeadIds.add(objLead.Id);
			}
		}
	}

	/**** create new/ or update Outreach Engagement Record ****/
	public void updateOutreachEngagementFields(Lead objLead, Lead objOldLead) {
		if (map_LeadIdToCUOutreach.containsKey(objLead.Id)) {
			Boolean blnCreateRec = map_LeadIdToCUOutreach.get(objLead.Id);

			if (blnCreateRec) {
				//create new record
				Outreach_Engagement__c objOutreachEng = mapOutreachEngFields(objLead, new Outreach_Engagement__c());
				list_OutreachRecordsDML.add(objOutreachEng);
			} else if (map_LeadIdToOutEng.containsKey(objLead.Id)) {
				//update existing record
				Outreach_Engagement__c objOutreachEng = map_LeadIdToOutEng.get(objLead.Id);
				if (objOutreachEng.ID_of_Currently_Active_Sequence__c == objLead.ID_of_Currently_Active_Sequence__c) {
					objOutreachEng = mapOutreachEngFields(objLead, objOutreachEng);
					list_OutreachRecordsDML.add(objOutreachEng);
				}
			}
		}
	}

	/**** Outreach Engagement field mapping - since same is used for create/update ****/
	public static Outreach_Engagement__c mapOutreachEngFields(Lead objLead, Outreach_Engagement__c objOutreachEng) {
		objOutreachEng.Current_Sequence_ID__c = objLead.Current_Sequence_ID__c;
		objOutreachEng.Current_Sequence_User_Name__c = objLead.Current_Sequence_User_Name__c;
		objOutreachEng.Actively_being_Sequenced__c = objLead.Actively_being_Sequenced__c;
		objOutreachEng.Current_Sequence_Name__c = objLead.Current_Sequence_Name__c;
		objOutreachEng.Current_Sequence_Status__c = objLead.Current_Sequence_Status__c;
		objOutreachEng.Current_Sequence_Step_Number__c = objLead.Current_Sequence_Step_Number__c;
		objOutreachEng.Current_Sequence_Step_Type__c = objLead.Current_Sequence_Step_Type__c;
		objOutreachEng.Current_Sequence_Task_Due_Date__c = objLead.Current_Sequence_Task_Due_Date__c;
		objOutreachEng.Current_Sequence_User_Integration_ID__c = objLead.Current_Sequence_User_Integration_ID__c;
		objOutreachEng.Number_of_Active_Sequences__c = objLead.Number_of_Active_Sequences__c;
		objOutreachEng.Number_of_Active_Sequence_Tasks__c = objLead.Number_of_Active_Sequence_Tasks__c;
		objOutreachEng.Finished_Sequence__c = objLead.Finished_Sequence__c;
		objOutreachEng.ID_of_Currently_Active_Sequence__c = objLead.ID_of_Currently_Active_Sequence__c;
		objOutreachEng.Lead__c = objLead.Id;

		//update record owner based on Current Sequence User Itegration Id (actual user id)
		if (String.isNotBlank(objOutreachEng.Current_Sequence_User_Integration_ID__c)) {
			objOutreachEng.OwnerId = objOutreachEng.Current_Sequence_User_Integration_ID__c;
		}

		return objOutreachEng;
	}

	/**** Process DML operations ****/
	public void processDMLOperation(Boolean isInsert) {
		if (isInsert) {
			if (list_LeadRelTracking != null && list_LeadRelTracking.size() > 0) {
				insert list_LeadRelTracking;
			}

			if (!map_ContactsForUpdate.isEmpty() && map_ContactsForUpdate.size() > 0) {
				Boolean blnSkipContTrigg = ContactTriggerHelper.skipTrigger;
				ContactTriggerHelper.skipTrigger = true;
				update map_ContactsForUpdate.values();
				ContactTriggerHelper.skipTrigger = blnSkipContTrigg;
			}

			if (!map_LeadsForUpdate.isEmpty() && map_LeadsForUpdate.size() > 0) {
				Boolean blnSkipLeadTrigg = LeadTriggerHelper.skipTrigger;
				LeadTriggerHelper.skipTrigger = true;
				update map_LeadsForUpdate.values();
				LeadTriggerHelper.skipTrigger = blnSkipLeadTrigg;
			}
		} else {
			if (list_LeadRelTracking != null && list_LeadRelTracking.size() > 0) {
				upsert list_LeadRelTracking Unique_Lead_Id__c;
			}

			if (!map_ContactsForUpdate.isEmpty() && map_ContactsForUpdate.size() > 0) {
				Boolean blnSkipContTrigg = ContactTriggerHelper.skipTrigger;
				ContactTriggerHelper.skipTrigger = true;
				update map_ContactsForUpdate.values();
				ContactTriggerHelper.skipTrigger = blnSkipContTrigg;
			}

			if (map_OppsForUpdate != null && map_OppsForUpdate.size() > 0) {
				Boolean blnSkipOppTrigg = OpportunityTriggerHelper.skipTrigger;
				OpportunityTriggerHelper.skipTrigger = true;
				update map_OppsForUpdate.values();
				OpportunityTriggerHelper.skipTrigger = blnSkipOppTrigg;
			}

			if (map_AccountsForUpdate != null && map_AccountsForUpdate.size() > 0) {
				update map_AccountsForUpdate.values();
			}

			if (!map_LeadsForUpdate.isEmpty() && map_LeadsForUpdate.size() > 0) {
				Boolean blnSkipLeadTrigg = LeadTriggerHelper.skipTrigger;
				LeadTriggerHelper.skipTrigger = true;
				update map_LeadsForUpdate.values();
				LeadTriggerHelper.skipTrigger = blnSkipLeadTrigg;
			}

			if (!map_CaseForUpdate.isEmpty() && map_CaseForUpdate.size() > 0) {
				Boolean blnSkipCaseTrigg = CaseTriggerHelper.skipTrigger;
				CaseTriggerHelper.skipTrigger = true;
				update map_CaseForUpdate.values();
				CaseTriggerHelper.skipTrigger = blnSkipCaseTrigg;
			}

			if (list_OutreachRecordsDML != null && list_OutreachRecordsDML.size() > 0) {
				upsert list_OutreachRecordsDML;
			}

			if (!map_CampMemberForUpdate.isEmpty()) {
				CampaignMemberTriggerHelper.skipTrigger = true;
				update map_CampMemberForUpdate.values();
				CampaignMemberTriggerHelper.skipTrigger = false;
			}

			if (!map_ChatTranscriptsForUpdate.isEmpty()) {
				LiveChatTranscriptTriggerHelper.skipTrigger = true;
				update map_ChatTranscriptsForUpdate.values();
				LiveChatTranscriptTriggerHelper.skipTrigger = false;
			}

			if (!map_TasksForUpdate.isEmpty()) {
				TaskTriggerHelper.skipTrigger = true;
				update map_TasksForUpdate.values();
				TaskTriggerHelper.skipTrigger = false;
			}
		}
	}

	/*** Set Lead Promotion  **/
	public void promoteLead(Lead objLead, Lead objOldLead) {
		if (validatePromotion(objLead)) {
			promoteInboundPhone(objLead);
			promoteXeroPartner(objLead);
			promoteSalesLead(objLead, objOldLead);
			promoteG2Crowd(objLead);
			promoteBizDevLead(objLead);
			setLeadPromotionLogicP2D(objLead);
			// moving promotion logic from GF Lead trigger to Lead trigger
			if (
				objOldLead == null ||
				(objOldLead != null && (objLead.ZP_Company_Lead_Id__c != objOldLead.ZP_Company_Lead_Id__c || objLead.ZP_Accountant_Lead_Id__c != objOldLead.ZP_Accountant_Lead_Id__c))
			) {
				setGFLeadPromotionLogic(objLead);
			}
			promoteChiliPiperLeads(objLead);
		}
	}

	/*** Set Lead Promotion for P2D **/
	public void setLeadPromotionLogicP2D(Lead objLead) {
		if (String.isNotBlank(objLead.Referral_Type__c) && objLead.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_UR)) {
			objLead.Status = LeadUtil.LEAD_STATUS_MQL;
			objLead.MQL_Reason__c = LeadUtil.LEADCREATION_OFFER_PR;
		}
	}

	/*** Set Lead Promotion for Inbound phone **/
	public void promoteInboundPhone(Lead objLead) {
		if (objLead.LeadSource == LeadUtil.LEADCREATION_OFFER_IB_PHONE) {
			objLead.Status = LeadUtil.LEAD_STATUS_MQL;
			objLead.MQL_Reason__c = LeadUtil.LEADCREATION_OFFER_IB_PHONE;
		}
	}

	/*** Set Lead Promotion If Lead is from Xero Migration Partner **/
	public void promoteXeroPartner(Lead objLead) {
		if (
			(objLead.LeadSource == LeadUtil.LEADSOURCE_XERO_MIGRATION_PARTNER || objLead.LeadSource == LeadUtil.LEADSOURCE_XERO_PROVISIONING_PARTNER) &&
			objLead.RecordtypeId == LeadUtil.COMPANY_LEAD_RT_ID
		) {
			objLead.Status = LeadUtil.LEAD_STATUS_MQL;
			objLead.MQL_Reason__c = LeadUtil.LEADCREATION_OFFER_PROD_GEN;
		}
	}

	/*** Set Lead Promotion if Lead is owned by Sales User **/
	public void promoteSalesLead(Lead objLead, Lead objOldLead) {
		if (objOldLead == null) {
			//insert
			if (objLead.Status == LeadUtil.LEAD_STATUS_MQL && String.isNotBlank(objLead.Owner_Role_Formula__c) && objLead.Owner_Role_Formula__c.containsIgnoreCase(LeadUtil.SALES_ROLE)) {
				objLead.MQL_Reason__c = LeadUtil.LEADCREATION_OFFER_SALES_GNR;
			}
		} else {
			//update
			if (
				objLead.Status != objOldLead.Status &&
				objLead.Status == LeadUtil.LEAD_STATUS_MQL &&
				String.isNotBlank(objLead.Owner_Role_Formula__c) &&
				objLead.Owner_Role_Formula__c.containsIgnoreCase(LeadUtil.SALES_ROLE)
			) {
				objLead.MQL_Reason__c = LeadUtil.LEADCREATION_OFFER_SALES_GNR;
			}
		}
	}

	/*** Set Lead Promotion If Lead Source is G2 crowd or Software Suggest **/
	public void promoteG2Crowd(Lead objLead) {
		if ((objLead.LeadSource == LeadUtil.LEADCREATION_OFFER_G2 || objLead.LeadSource == LeadUtil.LEADSOURCE_SOFTWARE_SUGGEST) && objLead.RecordtypeId == LeadUtil.COMPANY_LEAD_RT_ID) {
			objLead.Status = LeadUtil.LEAD_STATUS_MQL;
			objLead.MQL_Reason__c = LeadUtil.LEADCREATION_OFFER_3RD_PARTY;
		}
	}

	/** Set Lead Promotion if Lead Source belongs to a BizDev Partner */
	public void promoteBizDevLead(Lead objLead) {
		if (objLead.RecordtypeId == LeadUtil.COMPANY_LEAD_RT_ID && String.isNotBlank(objLead.LeadSource) && !list_LeadRoutingStngs.isEmpty()) {
			for (Lead_Routing_Settings__mdt objCMleadRouting : list_LeadRoutingStngs) {
				if (
					String.isNotBlank(objCMleadRouting.Lead_Source__c) &&
					(objLead.LeadSource.equalsIgnoreCase(objCMleadRouting.Lead_Source__c) || objLead.LeadSource.containsIgnoreCase(objCMleadRouting.Lead_Source__c))
				) {
					objLead.Status = LeadUtil.LEAD_STATUS_MQL;
					objLead.MQL_Reason__c = LeadUtil.LEADCREATION_OFFER_PROD_GEN;
				}
			}
		}
	}

	/**
	 * @description Promote leads based on different criteria if they are created from GF Lead
	 * @author      Praveen Sethu
	 * @param       Lead to be be promoted to MQL
	 * @return      NA
	 **/
	public void setGFLeadPromotionLogic(Lead objLead) {
		if ((String.isNotBlank(objLead.ZP_Company_Lead_Id__c) || String.isNotBlank(objLead.ZP_Accountant_Lead_Id__c))) {
			if (objLead.RecordTypeId == LeadUtil.COMPANY_LEAD_RT_ID) {
				// MQL Reason - Interactive Demo
				if (objLead.Submitted_From__c == LeadUtil.LEADCREATION_OFFER_INTR_DEMO) {
					objLead.Status = LeadUtil.LEAD_STATUS_MQL;
					objLead.MQL_Reason__c = LeadUtil.LEADCREATION_OFFER_INTR_DEMO;
				} else {
					// MQL Reason - Product Registration
					if (String.isBlank(objLead.Referral_Type__c)) {
						objLead.Status = LeadUtil.LEAD_STATUS_MQL;
						objLead.MQL_Reason__c = LeadUtil.LEADCREATION_OFFER_PROD_GEN;
						objLead.Lead_Creation_Offer__c = LeadUtil.LEADCREATION_OFFER_PROD_GEN;
					} else {
						// MQL Reason - Customer Referral
						if (objLead.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_US)) {
							objLead.Status = LeadUtil.LEAD_STATUS_MQL;
							objLead.MQL_Reason__c = LeadUtil.LEADCREATION_OFFER_CR;
						}
					}
				}
			} else if (objLead.RecordTypeId == LeadUtil.RESELLER_LEAD_RT_ID) {
				if (
					(String.isBlank(objLead.Referral_Type__c) ||
					(!objLead.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_PRU) && !objLead.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_UR)))
				) {
					if (objLead.Ramp_Intent__c) {
						// MQL Reason - Sign-Up Ramp Intent
						objLead.MQL_Reason__c = LeadUtil.MQL_REASON_SIGN_UP_RAMP_INTENT;
						objLead.Status = LeadUtil.LEAD_STATUS_MQL;
					} else if (objLead.Partner_Program_Request_Create_Date__c != null) {
						// MQL Reason - In-App Join Request
						objLead.MQL_Reason__c = LeadUtil.MQL_REASON_IN_APP_JOIN_REQ;
						objLead.Status = LeadUtil.LEAD_STATUS_MQL;
					} else if (objLead.LeadSource != LeadUtil.LEADSOURCE_ABC) {
						// MQL Reason - Product Registration
						objLead.MQL_Reason__c = LeadUtil.LEADCREATION_OFFER_PROD_GEN;
						objLead.Status = LeadUtil.LEAD_STATUS_MQL;
						objLead.Lead_Creation_Offer__c = LeadUtil.LEADCREATION_OFFER_PROD_GEN;
					}
				}
			}

			// Type Agnostic Promotion
			// P2P Referral
			if (String.isNotBlank(objLead.Referral_Type__c) && objLead.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_PRU)) {
				objLead.Status = LeadUtil.LEAD_STATUS_MQL;
				objLead.MQL_Reason__c = LeadUtil.LEADCREATION_OFFER_P2P;
			}
		}
	}

	/**
	 * @description Promote leads if created by user is Chilipiper
	 * @author      Praveen Sethu
	 * @param       Lead to be be promoted to MQL
	 * @return      NA
	 **/
	public void promoteChiliPiperLeads(Lead objLead) {
		if (UserInfo.getName() == LeadUtil.CHILIPIPER_USER) {
			objLead.Status = LeadUtil.LEAD_STATUS_MQL;
			objLead.MQL_Reason__c = LeadUtil.LEADCREATION_OFFER_PROD_GEN;
		}
	}

	/*** Entry Criteria for Lead Promotion ***/
	public static Boolean validatePromotion(Lead objLead) {
		if (String.isNotBlank(objLead.Email) && String.isNotBlank(objLead.Phone) && String.isNotBlank(objLead.Status)) {
			String strDomain = objLead.Email.toLowerCase().split('@')[1];
			Date dtMQLDate = objLead.MQL_Date__c;
			if (
				!list_Competitors.contains(strDomain) &&
				!list_Partners.contains(strDomain) &&
				!list_Employees.contains(strDomain) &&
				LeadUtil.list_AllowStatus.contains(objLead.Status) &&
				(dtMQLDate == null ||
				dtMQLDate < LeadUtil.LAST_7_DAYS)
			) {
				return true;
			}
		}
		return false;
	}

	/**** Query Section ****/
	/**** this query will execute only in before insert ****/
	public void queryContacts(Set<String> set_Emails, Set<String> set_ZPUserIdSet, Set<Id> set_AllConvertedConIds) {
		list_contacts = new List<Contact>();
		map_EmailToContact = new Map<String, Contact>();
		map_ZPUsrIdContact = new Map<String, Contact>();
		map_ConvertedConIdToCon = new Map<Id, Contact>();

		String strQuery = 'SELECT Id,Email, AccountId, Account.RecordTypeId, ZP_User_Id__c, Number_of_Referred_Leads__c, SAL_Reason__c, FirstName ';
		strQuery += ' FROM Contact WHERE Email IN: set_Emails OR ZP_User_Id__c IN: set_ZPUserIdSet OR Id IN: set_AllConvertedConIds';

		if (set_Emails.size() > 0 || set_ZPUserIdSet.size() > 0) {
			List<Contact> list_Result = Database.query(strQuery);
			for (Contact objCon : list_Result) {
				list_contacts.add(objCon);
				map_EmailToContact.put(objCon.Email, objCon);
				if (String.isNotBlank(objCon.ZP_User_Id__c) && set_ZPUserIdSet.contains(objCon.ZP_User_Id__c)) {
					map_ZPUsrIdContact.put(objCon.ZP_User_Id__c, objCon);
				}

				if (set_AllConvertedConIds.contains(objCon.Id)) {
					map_ConvertedConIdToCon.put(objCon.Id, objCon);
				}
			}
		}
	}

	/**** Query Lead Email Domains ****/
	public void queryLeadEmailDomains(Set<String> set_EmailDomains) {
		map_ResellerDomainMap = new Map<String, Account_Email_Domain__c>();

		for (Account_Email_Domain__c objAED : [
			SELECT Id, Name, Account__r.Id, Account__r.RecordTypeId
			FROM Account_Email_Domain__c
			WHERE Name IN :set_EmailDomains
			ORDER BY Account__r.RecordType.Name
		]) {
			if (objAED.Account__r.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID) {
				map_ResellerDomainMap.put(objAED.Name, objAED);
			}
		}
	}

	/**** Query Existing Leads to set attribution ****/
	public void queryExistingLeads(Set<String> set_EmailIds, Set<Id> set_CurrentLeadIdExc) {
		map_EmailToLeads = new Map<String, Lead>();
		for (Lead objResult : [
			SELECT Id, Email, LeadSource, ZP_Lead_Campaign__c, Referral_Token__c
			FROM Lead
			WHERE Email IN :set_EmailIds AND Id NOT IN :set_CurrentLeadIdExc
			ORDER BY CreatedDate ASC
		]) {
			map_EmailToLeads.put(objResult.Email, objResult);
		}
	}

	/**** Query Routing Settings ****/
	public void queryLeadRouteSettngMdt() {
		list_LeadRoutingStngs = new List<Lead_Routing_Settings__mdt>();
		list_LeadRoutingStngs = [SELECT MasterLabel, QualifiedApiName, Lead_Source__c, Lead_Source_Owner__c FROM Lead_Routing_Settings__mdt];
	}

	/**** Query Accounts for Routing ****/
	public void queryAccountInfo(Set<String> set_ZPFirmIds, Set<Id> set_AccountIds, Set<String> set_AllCompIds, Set<Id> set_ConvertedResAccIds, Set<Id> set_AllConvertedAccIds) {
		Set<String> set_AllZPFirmIds = new Set<String>();
		Set<String> set_CompanyIds = new Set<String>();

		if (set_ReferralAccIds.size() > 0) {
			set_AllZPFirmIds.addAll(set_ReferralAccIds);
			set_CompanyIds.addAll(set_ReferralAccIds);
		}

		if (set_AllCompIds.size() > 0) {
			set_CompanyIds.addAll(set_AllCompIds);
		}

		if (set_ZPFirmIds.size() > 0) {
			set_AllZPFirmIds.addAll(set_ZPFirmIds);
		}

		DateTime currentDateTime = LeadUtil.CURRENT_DATE_TIME;
		String strQuery = 'SELECT Id, OwnerId, Owner.UserRole.Name, Sold_By__c, Referred_By__c, ZP_Firm_ID__c, ZP_Company_ID__c, ZP_Company_Lead_ID__c, Lead_Rating_Account__c, Potential_Fraud_Account__c, No_of_Clients__c, No_Clients_Payroll__c, Total_Business_Clients_Payroll_by_Firm__c, ';
		strQuery += 'CreatedDate, RecordType.Name, Sold_By_Accountant_Lead__c, Sales_Engagement_Status__c, Sales_Engagement_Status_Detail__c,Accutics_ID__c,ZP_Lead_Campaign__c,Lead_Channel__c,Lead_Medium__c,Lead_Source__c FROM Account WHERE (ZP_Firm_ID__c IN: set_AllZPFirmIds OR Id IN: set_AccountIds OR ZP_Company_ID__c IN: set_CompanyIds)';
		strQuery += ' OR (Id IN: set_ConvertedResAccIds AND CreatedDate < :currentDateTime) OR (Id IN: set_AllConvertedAccIds)';

		if (set_AllZPFirmIds.size() > 0 || set_AccountIds.size() > 0 || set_CompanyIds.size() > 0 || set_AllConvertedAccIds.size() > 0) {
			List<Account> list_accounts = Database.query(strQuery);
			for (Account objAcc : list_accounts) {
				//map for ABC match
				if (String.isNotBlank(objAcc.ZP_Firm_ID__c) && set_ZPFirmIds.contains(objAcc.ZP_Firm_ID__c)) {
					map_ZPFrmIdToAccount.put(objAcc.ZP_Firm_ID__c, objAcc);
				}
				//Map for Lead Routing
				if (set_AccountIds.contains(objAcc.Id)) {
					map_RouterAccounts.put(objAcc.Id, objAcc);
				}
				//firm id to account
				if (String.isNotBlank(objAcc.ZP_Firm_ID__c) && set_ReferralAccIds.contains(objAcc.ZP_Firm_ID__c)) {
					map_FirmIdToAccRefer.put(objAcc.ZP_Firm_ID__c, objAcc);
				}
				//map company id to account
				if (String.isNotBlank(objAcc.ZP_Company_ID__c) && set_ReferralAccIds.contains(objAcc.ZP_Company_ID__c)) {
					map_CompIdToAccRefer.put(objAcc.ZP_Company_ID__c, objAcc);
				}

				//combine all company id to account
				if (String.isNotBlank(objAcc.ZP_Company_ID__c) && set_AllCompIds.contains(objAcc.ZP_Company_ID__c)) {
					map_CompanyIdToAccount.put(objAcc.ZP_Company_ID__c, objAcc);
				}

				//reseller converted lead account ids
				if (set_ConvertedResAccIds.contains(objAcc.Id)) {
					set_MDRActivityResAccs.add(objAcc.Id);
				}

				//all converted accounts
				if (set_AllConvertedAccIds.contains(objAcc.Id)) {
					map_ConvertedAccIdToAcc.put(objAcc.Id, objAcc);
				}
			}
		}
	}

	/**** Query Leads With Referral Token ****/
	public void queryLeadsWithToken(Set<String> set_ReferralTokens) {
		for (Lead objLead : [
			SELECT Id, Referral_Token__c, Number_of_Referred_Leads__c, LeadSource, Status, RecordTypeId
			FROM Lead
			WHERE Referral_Token__c IN :set_ReferralTokens AND RecordTypeId = :LeadUtil.RESELLER_LEAD_RT_ID
		]) {
			map_RefTokenToLead.put(objLead.Referral_Token__c, objLead);
		}
	}

	/**** Query ZP User (With user role) With Referral Token ****/
	public void queryZPUserWithToken(Set<String> set_ReferralTokens) {
		map_RefTokenToZPUsr = new Map<String, ZP_User__c>();
		for (ZP_User__c objZPUser : [
			SELECT Id, Id__c, Referral_Token__c, Email__c, (SELECT Id, Id__c, User_Id__c, Accounting_Firm_Id__c, Company_Id__c, Collaborator_Type__c FROM ZP_User_Roles__r)
			FROM ZP_User__c
			WHERE Referral_Token__c IN :set_ReferralTokens
		]) {
			map_RefTokenToZPUsr.put(objZPUser.Referral_Token__c, objZPUser);
			if (String.isNotBlank(objZPUser.Id__c)) {
				set_ZPUserIdSet.add(objZPUser.Id__c);
			}

			if (objZPUser.ZP_User_Roles__r != null) {
				for (ZP_User_Role__c objZPURole : objZPUser.ZP_User_Roles__r) {
					if (String.isNotBlank(objZPURole.Collaborator_Type__c)) {
						if (String.isNotBlank(objZPURole.Accounting_Firm_Id__c) && objZPURole.Collaborator_Type__c == LeadUtil.COLAB_TYPE_EXT_ACC) {
							set_ReferralAccIds.add(objZPURole.Accounting_Firm_Id__c);
						} else if (String.isNotBlank(objZPURole.Company_Id__c) && objZPURole.Collaborator_Type__c == LeadUtil.COLAB_TYPE_PAY_ADM) {
							set_ReferralAccIds.add(objZPURole.Company_Id__c);
						}
					}
				}
			}
		}
	}

	/**** Query Opportunities ****/
	public void queryOpportunities(Set<Id> set_AllConvertedOppIds) {
		map_ConvertedOppIdToOpp = new Map<Id, Opportunity>();
		for (Opportunity objOpp : [
			SELECT Id, Source_ID__c, ZP_Company_ID__c, Sold_By__c, Referred_By__c, SAL_Reason__c, Referral_Type__c, Accutics_ID__c, Lead_Channel__c, Lead_Medium__c, LeadSource, Lead_Campaign__c
			FROM Opportunity
			WHERE Id IN :set_AllConvertedOppIds AND RecordTypeId = :OpportunityUtil.COMPANY_OPPTY_RT_ID
		]) {
			map_ConvertedOppIdToOpp.put(objOpp.Id, objOpp);
		}
	}

	/** Query Lead Related Cases */
	public void queryCases(Set<Id> set_LeadIdForCases) {
		map_LeadIdToRelCases = new Map<Id, List<Case>>();
		for (Case objCase : [SELECT Id, ContactId, Lead__c, SuppliedEmail FROM Case WHERE Lead__c IN :set_LeadIdForCases AND ContactId = NULL]) {
			List<Case> list_Cases = map_LeadIdToRelCases.containsKey(objCase.Lead__c) ? map_LeadIdToRelCases.get(objCase.Lead__c) : new List<Case>();
			list_Cases.add(objCase);
			map_LeadIdToRelCases.put(objCase.Lead__c, list_Cases);
		}
	}

	/** Query Lead Related Campaign Members */
	public void queryCampaigns(Set<Id> set_LeadIds) {
		DateTime dtLastHour = System.now().addHours(-1);

		for (CampaignMember objCampMemb : [
			SELECT Id, LeadId, CampaignId, Campaign.IsActive, Campaign.Type, HasResponded, Recent_Source__c, Recent_Campaign__c, Recent_Content__c
			FROM CampaignMember
			WHERE LeadId IN :set_LeadIds AND CreatedDate >= :dtLastHour
		]) {
			if (map_LeadIdToCampaign.containsKey(objCampMemb.LeadId)) {
				map_LeadIdToCampaign.get(objCampMemb.LeadId).add(objCampMemb);
			} else {
				map_LeadIdToCampaign.put(objCampMemb.LeadId, new List<CampaignMember>{ objCampMemb });
			}
		}
	}

	/** Query Lead Related Tracking */
	public void queryLeadRelTracking(Set<Id> set_LeadIds) {
		map_LeadIdToRelTrack = new Map<Id, Lead_Related_Tracking__c>();
		for (Lead_Related_Tracking__c objLRT : [SELECT Id, Lead__c, Unique_Lead_Id__c, MQL_Datetime__c FROM Lead_Related_Tracking__c WHERE Lead__c IN :set_LeadIds]) {
			map_LeadIdToRelTrack.put(objLRT.Lead__c, objLRT);
		}
	}

	/** Query Outreach Engagement Records */
	public void queryOutreachEngRecords(Set<Id> set_OutreachLeadIds) {
		map_LeadIdToOutEng = new Map<Id, Outreach_Engagement__c>();
		for (Outreach_Engagement__c objOutEng : [
			SELECT
				Id,
				Actively_being_Sequenced__c,
				Lead__c,
				Current_Sequence_Name__c,
				Current_Sequence_Status__c,
				Current_Sequence_Step_Number__c,
				Current_Sequence_Step_Type__c,
				Current_Sequence_Task_Due_Date__c,
				Current_Sequence_User_Integration_ID__c,
				Current_Sequence_User_Name__c,
				Finished_Sequence__c,
				HI_Opportunity__c,
				ID_of_Currently_Active_Sequence__c,
				Number_of_Active_Sequences__c,
				Number_of_Active_Sequence_Tasks__c
			FROM Outreach_Engagement__c
			WHERE Lead__c = :set_OutreachLeadIds
		]) {
			map_LeadIdToOutEng.put(objOutEng.Lead__c, objOutEng);
		}
	}

	/** Query Task Records */
	public static Map<Id, List<Task>> queryLeadTasks() {
		Map<Id, List<Task>> map_Result = new Map<Id, List<Task>>();
		Set<String> set_UserRoleIds = UserUtils.getUserRoleIds(
			new Set<String>{ LeadUtil.LABEL_SDR_MM_MGR_USR_ROLE, LeadUtil.LABEL_SDR_MM_USR_ROLE, LeadUtil.LABEL_SDR_PARTNER_MGR_USR_ROLE, LeadUtil.LABEL_SDR_PARTNER_USR_ROLE }
		);
		for (Task objTask : [
			SELECT Id, WhoId, WhatId, OwnerId, Lead__c, IsClosed, Type, CreatedBy.UserRoleId, LastModifiedBy.UserRoleId, Status, RecordType.DeveloperName
			FROM Task
			WHERE RecordTypeId IN :TaskUtil.set_MDRTaskRecTypes AND WhoId IN :set_LeadIdsForTasks AND CreatedBy.UserRoleId IN :set_UserRoleIds
		]) {
			List<Task> list_ResulTask = map_Result.containsKey(objTask.WhoId) ? map_Result.get(objTask.WhoId) : new List<Task>();
			list_ResulTask.add(objTask);
			map_Result.put(objTask.WhoId, list_ResulTask);
		}
		return map_Result;
	}

	/*
	 * @See      	: LeadTriggerHelperTest.testConvertedLeadChatTranscriptUpdates
	 * @Description : Query Chat Transcripts by lead Id
	 * @param       : set_leadIds - Set of Lead Ids to query chat transcripts by.
	 * @return      : NA
	 */
	public static void queryChatTranscriptsWithActivities(Set<Id> set_leadIds) {
		for (LiveChatTranscript objChatTranscript : [
			SELECT Id, LeadId, AccountId, ContactId, (SELECT Id, WhoId, WhatId FROM Activities__r ORDER BY ActivityDate DESC, LastModifiedDate DESC LIMIT 500)
			FROM LiveChatTranscript
			WHERE LeadId IN :set_leadIds
		]) {
			if (map_LeadIdToChatTranscripts.containsKey(objChatTranscript.LeadId)) {
				map_LeadIdToChatTranscripts.get(objChatTranscript.LeadId).add(objChatTranscript);
			} else {
				map_LeadIdToChatTranscripts.put(objChatTranscript.LeadId, new List<LiveChatTranscript>{ objChatTranscript });
			}
		}
	}

	/*
	 * @author:         Debasmita Rawooth
	 * @description:    Set Potential_Fraud_Lead_History__c field on Lead
	 * @parm:           objLead - New Lead record, objOldLead - Old Lead record
	 * @return:         NA
	 */
	public void setPotentialFraudLeadHistory(Lead objLead, Lead objOldLead) {
		if (objOldLead == null) {
			objLead.Potential_Fraud_Lead_History__c = objLead.Potential_Fraud_Lead__c;
		} else if (objLead.Potential_Fraud_Lead__c && !objOldLead.Potential_Fraud_Lead_History__c) {
			objLead.Potential_Fraud_Lead_History__c = objLead.Potential_Fraud_Lead__c;
		}
	}

	/*
	 * @author:         David (Dato) Tsamalashvili
	 * @description:    Set Lead Rating Account field on converted account
	 * @parm:           objLead - New Lead record, objOldLead - Old Lead record
	 * @return:         NA
	 */
	public void setAccountLeadRating(Lead objLead, Lead objOldLead) {
		if (objLead.IsConverted && String.isNotBlank(objLead.ConvertedAccountId) && map_ConvertedAccIdToAcc.containsKey(objLead.ConvertedAccountId)) {
			//account update
			//check if account already exists in DML map
			Account objAccount = map_AccountsForUpdate.containsKey(objLead.ConvertedAccountId)
				? map_AccountsForUpdate.get(objLead.ConvertedAccountId)
				: map_ConvertedAccIdToAcc.get(objLead.ConvertedAccountId);

			if (objLead.Lead_Rating__c != objAccount.Lead_Rating_Account__c) {
				objAccount.Lead_Rating_Account__c = objLead.Lead_Rating__c;

				map_AccountsForUpdate.put(objAccount.Id, objAccount); //prepear for DML
			}
		}
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Set Standard Fields on Lead with 3rd party fields for Data Enrichment.
	 * @param        objLead - new Lead Record
	 **/
	public void setStandardFieldsFrom3rdParty(Lead objLead) {
		if (objLead.AnnualRevenue == null && objLead.X3rd_Party_Annual_Revenue__c != null) {
			objLead.AnnualRevenue = objLead.X3rd_Party_Annual_Revenue__c;
		}

		if (objLead.NumberOfEmployees == null && objLead.X3rd_Party_Num_Employees__c != null) {
			objLead.NumberOfEmployees = Integer.valueOf(objLead.X3rd_Party_Num_Employees__c);
		}

		if (String.isBlank(objLead.Industry) && String.isNotBlank(objLead.Data_Sourcing_Industry__c)) {
			objLead.Industry = objLead.Data_Sourcing_Industry__c;
		}

		if (
			String.isBlank(objLead.City) &&
			String.isBlank(objLead.State) &&
			String.isBlank(objLead.PostalCode) &&
			(String.isNotBlank(objLead.X3rd_Party_City__c) ||
			String.isNotBlank(objLead.X3rd_Party_State__c) ||
			String.isNotBlank(objLead.X3rd_Party_Postal__c))
		) {
			objLead.City = objLead.X3rd_Party_City__c;
			objLead.State = objLead.X3rd_Party_State__c;
			objLead.PostalCode = objLead.X3rd_Party_Postal__c;
		}
	}

	/**
	 * @Author      : Rushi Ravisaheb
	 * @Description : Set Lead Status as 'Converted' once it is Converted
	 * @Parm        : objLead - New Lead
	 * @Parm        : objOldLead - Old Lead
	 * @Return      : N/A
	 **/
	private void setLeadStatus(Lead objLead, Lead objOldLead) {
		if (objOldLead != null && !objOldLead.isConverted && objLead.isConverted) {
			// Set Lead Status to Converted
			objLead.Status = Config.LeadConversion.CONVERTED_LEAD_STATUS;
			//Set Closed Owner Role to owner's role during lead conversion
			objLead.Closed_Owner_Role__c = UserUtils.getUserRoleName(objLead.OwnerId);
		}
	}

	/**
	 * @Author      : Rushi Ravisaheb
	 * @Description : Set SAL Date once status changes to 'SAL'
	 * @Parm        : objLead - New Lead
	 * @Parm        : objOldLead - Old Lead
	 * @Return      : N/A
	 **/
	private void setSALDate(Lead objLead, Lead objOldLead) {
		if ((objOldLead == null || objLead.Status != objOldLead.Status) && objLead.Status == LeadUtil.LEAD_STATUS_SAL) {
			objLead.SAL_Date__c = Date.today();
		}
	}

	/**
	 * @Description : Set Subscription Preferences on Lead based on dependencies. Common method for before insert and update
	 * @Param        : Lead - Trigger new
	 * @Param        : Lead - Trigger old (if before update)
	 * @Return      : void
	 **/
	public void setSubscriptionPreferencesOnLead(Lead objNewLead, Lead objOldLead, Boolean blnIsInsert) {
		Set<String> set_newSubscriptionValues = new Set<String>();
		Set<String> set_oldSubscriptionValues = new Set<String>();
		Set<String> set_finalSubscriptionValues = new Set<String>();
		if (String.isNotBlank(objNewLead.Customer_Subscriptions__c)) {
			set_newSubscriptionValues.addAll(objNewLead.Customer_Subscriptions__c.split(';'));
		}
		//If new populate subscriptions factoring dependencies
		if (blnIsInsert) {
			objNewLead.Customer_Subscriptions__c = SubscriptionCenterUtil.getApplicableSubscriptionPreferences(set_newSubscriptionValues, set_oldSubscriptionValues, true);
		} else if (objOldLead != null && objNewLead.Customer_Subscriptions__c != objOldLead.Customer_Subscriptions__c) {
			// Check if Subscription Preferences are modified on Lead
			if (String.isNotBlank(objOldLead.Customer_Subscriptions__c)) {
				set_oldSubscriptionValues.addAll(objOldLead.Customer_Subscriptions__c.split(';'));
			}
			objNewLead.Customer_Subscriptions__c = SubscriptionCenterUtil.getApplicableSubscriptionPreferences(set_newSubscriptionValues, set_oldSubscriptionValues, false);
		} else if (objOldLead != null && objNewLead.Salesloft_Email_Opt_Out__c && !objOldLead.Salesloft_Email_Opt_Out__c) {
			// Check if Email Op Out - Outreach is being checked
			if (objNewLead.Customer_Subscriptions__c != null) {
				set_finalSubscriptionValues.addAll(objNewLead.Customer_Subscriptions__c.split(';'));
			}
			if (set_finalSubscriptionValues.contains(SubscriptionCenterUtil.OUTREACH)) {
				set_finalSubscriptionValues.remove(SubscriptionCenterUtil.OUTREACH);
			}
			objNewLead.Customer_Subscriptions__c = String.join(new List<String>(set_finalSubscriptionValues), ';');
		}
	}

	/**
	 * @Description : Set Legacy Subscription fields based on Subscription Preferences field
	 * @Param        : Lead - Trigger new
	 * @Return      : void
	 **/
	public void setLegacySubscriptionFields(Lead objNewLead, Lead objOldLead) {
		// If feature flag is set to false, do not fire automation to set subscription checkbox fields
		if (String.isNotBlank(strSubscriptionFeatureFlag) && strSubscriptionFeatureFlag.equals('false')) {
			return;
		}

		if (objOldLead == null || objNewLead.Customer_Subscriptions__c != objOldLead.Customer_Subscriptions__c) {
			objNewLead.Subscription_Center_Small_Biz_Newslet__c =
				String.isNotBlank(objNewLead.Customer_Subscriptions__c) && objNewLead.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.BIZ_NEWSLETTER);
			objNewLead.Subscription_Center_Feature_Announce__c =
				String.isNotBlank(objNewLead.Customer_Subscriptions__c) && objNewLead.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.FEATURE_ANNOUNCEMENTS);
			objNewLead.Subscription_Center_Benefits_Announce__c =
				String.isNotBlank(objNewLead.Customer_Subscriptions__c) && objNewLead.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.BENEFIT_ANNOUNCEMENTS);
			objNewLead.Subscription_Center_Deals_and_Promos__c =
				String.isNotBlank(objNewLead.Customer_Subscriptions__c) && objNewLead.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.DEALS_PROMOS);
			objNewLead.Subscription_Center_Financial_Products__c =
				String.isNotBlank(objNewLead.Customer_Subscriptions__c) && objNewLead.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.FINANCIAL_PRODUCTS);
			objNewLead.Subscription_Center_Acct_Partner_Newsl__c =
				String.isNotBlank(objNewLead.Customer_Subscriptions__c) && objNewLead.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.ACCOUNT_PARTNER_NEWS);
			objNewLead.Marketing_Email_Opt_Out__c =
				String.isNotBlank(objNewLead.Customer_Subscriptions__c) && objNewLead.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.MARKETING_EMAIL_OPT_OUT);
		}
	}

	/*
	 * @See      	: LeadTriggerHelperTest.testConvertedLeadChatTranscriptUpdates
	 * @Description : Set Lead Source and Lead Source Detail | BSS-1363
	 * @Parm        : objLead - New Lead
	 * @Return      : N/A
	 */
	public void updateChatTranscripts(Lead objLead) {
		if (map_LeadIdToChatTranscripts.containsKey(objLead.Id) && set_AllConvertedLeadIds.contains(objLead.Id)) {
			//update chat transcripts with converted contact and account ids
			for (LiveChatTranscript objTranscript : map_LeadIdToChatTranscripts.get(objLead.Id)) {
				LiveChatTranscript objTranscriptToUpdate = map_ChatTranscriptsForUpdate.containsKey(objTranscript.Id) ? map_ChatTranscriptsForUpdate.get(objTranscript.Id) : objTranscript;
				Boolean blnIsTranscriptUpdated = false;
				Boolean blnIsActivityUpdated = false;

				if (objTranscriptToUpdate.ContactId == null && String.isNotBlank(objLead.ConvertedContactId)) {
					objTranscriptToUpdate.ContactId = objLead.ConvertedContactId;
					blnIsTranscriptUpdated = true;
				}
				if (objTranscriptToUpdate.AccountId == null && String.isNotBlank(objLead.ConvertedAccountId)) {
					objTranscriptToUpdate.AccountId = objLead.ConvertedAccountId;
					blnIsTranscriptUpdated = true;
				}
				//update chat activities to relate to converted contact and account
				for (LookedUpFromActivity objChatActivity : (List<LookedUpFromActivity>) objTranscript.Activities__r) {
					Task objChatActivityToUpdate = map_TasksForUpdate.containsKey(objChatActivity.Id) ? map_TasksForUpdate.get(objChatActivity.Id) : new Task(Id = objChatActivity.Id);
					if (blnIsTranscriptUpdated) {
						if (String.isNotBlank(objLead.ConvertedContactId)) {
							objChatActivityToUpdate.WhoId = objLead.ConvertedContactId;
							blnIsActivityUpdated = true;
						}
						if (String.isNotBlank(objLead.ConvertedAccountId)) {
							objChatActivityToUpdate.WhatId = objLead.ConvertedAccountId;
							blnIsActivityUpdated = true;
						}
						if (blnIsActivityUpdated) {
							map_TasksForUpdate.put(objChatActivityToUpdate.Id, objChatActivityToUpdate);
						}
					}
				}
				if (blnIsTranscriptUpdated) {
					map_ChatTranscriptsForUpdate.put(objTranscriptToUpdate.Id, objTranscriptToUpdate);
				}
			}
		}
	}

	/**
	 * @Description : Set ContactTriggerHelperTest on Lead based on criteria. Common method for before insert and update
	 * @Param        : Lead - Trigger new
	 * @Param        : Lead - Trigger old (if before update)
	 * @Return      : void
	 **/
	public void setOutreachEmailOptOut(Lead objNewLead, Lead objOldLead) {
		Set<String> set_newSubscriptionValues = new Set<String>();
		Set<String> set_oldSubscriptionValues = new Set<String>();

		if (String.isNotBlank(objNewLead.Customer_Subscriptions__c)) {
			set_newSubscriptionValues.addAll(objNewLead.Customer_Subscriptions__c.split(';'));
		}
		if (objOldLead != null && String.isNotBlank(objOldLead.Customer_Subscriptions__c)) {
			set_oldSubscriptionValues.addAll(objOldLead.Customer_Subscriptions__c.split(';'));
		}
		if (
			objOldLead != null &&
			((!set_newSubscriptionValues.contains(SubscriptionCenterUtil.OUTREACH) && set_oldSubscriptionValues.contains(SubscriptionCenterUtil.OUTREACH)) ||
			(set_newSubscriptionValues.contains(SubscriptionCenterUtil.MARKETING_EMAIL_OPT_OUT) && !set_oldSubscriptionValues.contains(SubscriptionCenterUtil.MARKETING_EMAIL_OPT_OUT)))
		) {
			objNewLead.Salesloft_Email_Opt_Out__c = true;
		}
	}

	/**
	 * @Description : Method to update values on Account for the TBC fields if Lead is updated after conversion.
	 * @Param        : Lead - Trigger new
	 * @Param        : Lead - Trigger old
	 * @Return       : void
	 **/
	public void updateTBCDataOnAccount(Lead objLead, Lead objOldLead) {
		if (
			(objLead.No_of_Clients__c != objOldLead.No_of_Clients__c) ||
			(objLead.No_Clients_Payroll__c != objOldLead.No_Clients_Payroll__c) ||
			(objLead.Total_Business_Clients_Payroll_by_Firm__c != objOldLead.Total_Business_Clients_Payroll_by_Firm__c)
		) {
			if (String.isNotBlank(objLead.ConvertedAccountId) && map_ConvertedAccIdToAcc.containsKey(objLead.ConvertedAccountId)) {
				//account update
				//check if account already exists in DML map
				Account objAcc = map_AccountsForUpdate.containsKey(objLead.ConvertedAccountId)
					? map_AccountsForUpdate.get(objLead.ConvertedAccountId)
					: map_ConvertedAccIdToAcc.get(objLead.ConvertedAccountId);

				//Update Account only if the field value on Account is blank or 0
				if ((objLead.No_of_Clients__c != objOldLead.No_of_Clients__c) && (objAcc.No_of_Clients__c == null || objAcc.No_of_Clients__c == 0)) {
					objAcc.No_of_Clients__c = objLead.No_of_Clients__c;
				}
				if ((objLead.No_Clients_Payroll__c != objOldLead.No_Clients_Payroll__c) && (objAcc.No_Clients_Payroll__c == null || objAcc.No_Clients_Payroll__c == 0)) {
					objAcc.No_Clients_Payroll__c = objLead.No_Clients_Payroll__c;
				}
				if (
					(objLead.Total_Business_Clients_Payroll_by_Firm__c != objOldLead.Total_Business_Clients_Payroll_by_Firm__c) &&
					(objAcc.Total_Business_Clients_Payroll_by_Firm__c == null ||
					objAcc.Total_Business_Clients_Payroll_by_Firm__c == 0)
				) {
					objAcc.Total_Business_Clients_Payroll_by_Firm__c = objLead.Total_Business_Clients_Payroll_by_Firm__c;
				}

				map_AccountsForUpdate.put(objAcc.Id, objAcc);
			}
		}
	}

	/*
	 * @Author      : Deepak Dhakal
	 * @Description : Update Lead data with accutics campaign data
	 * @Parm        : List Object for  Lead
	 * @Return      : N/A
	 */
	public void setCampaignInfoInLead(List<Lead> list_Leads) {
		Map<String, Campaign> map_campaignData = new Map<String, Campaign>();
		set<String> set_accuticsIDs = new Set<String>();
		set<String> set_partnerIds = new Set<String>();
		for (Lead objLead : list_Leads) {
			if (objLead.accutics_id__c != null) {
				set_accuticsIDs.add(objLead.accutics_id__c);
			}
			if (objLead.Accutics_AffiliatePartner_ID__c != null) {
				set_partnerIds.add(objLead.Accutics_AffiliatePartner_ID__c);
			}
		}
		// Query for all the Campaign records needed
		List<Campaign> list_campaigns = [
			SELECT
				Accutics_ID__c,
				Accutics_AffiliatePartner_ID__c,
				Accutics_AffiliatePlatform__c,
				Accutics_AffiliateType__c,
				Accutics_BDPartner__c,
				Name,
				Accutics_LeadChannel__c,
				Accutics_LeadFunnelStage__c,
				Accutics_LeadSource__c,
				Accutics_LeadMedium__c
			FROM Campaign
			WHERE Accutics_ID__c IN :set_accuticsIDs OR Accutics_AffiliatePartner_ID__c IN :set_partnerIds
		];

		// Populate the Map with Campaign data
		for (Campaign objCamp : list_campaigns) {
			map_campaignData.put(objCamp.Accutics_ID__c, objCamp);
			map_campaignData.put(objCamp.Accutics_AffiliatePartner_ID__c, objCamp);
		}

		for (Lead objLead : list_Leads) {
			// Check if Lead is created by Qualified Integration and Accutics_ID__c is not blank
			if (UserInfo.getName() == QUALIFIED_INTEGRATION_USERNAME && (String.isNotBlank(objLead.Accutics_ID__c) || String.isNotBlank(objLead.Accutics_AffiliatePartner_ID__c))) {
				// Find the relevant Campaign based on Accutics_ID or Affiliate Partner ID
				Campaign objRelatedCampaign;
				if (String.isNotBlank(objLead.Accutics_ID__c)) {
					objRelatedCampaign = map_campaignData.get(objLead.Accutics_ID__c);
				} else if (String.isNotBlank(objLead.Accutics_AffiliatePartner_ID__c)) {
					objRelatedCampaign = map_campaignData.get(objLead.Accutics_AffiliatePartner_ID__c);
				}
				// Define the mapping from Campaign to Lead fields
				Map<String, String> map_CampaignToLeads = new Map<String, String>{
					'Accutics_ID__c' => 'Accutics_ID__c',
					'Accutics_LeadChannel__c' => 'Lead_Channel__c',
					'Accutics_AffiliatePlatform__c' => 'Accutics_Affiliate_Platform__c',
					'Accutics_LeadMedium__c' => 'Accutics_Lead_Medium__c',
					'Accutics_AffiliateType__c' => 'Accutics_Affiliate_Type__c',
					'Accutics_LeadSource__c' => 'LeadSource',
					'Accutics_BDPartner__c' => 'Accutics_BD_Partner__c',
					'Accutics_LeadFunnelStage__c' => 'Accutics_Lead_Funnel_Stage__c',
					'Accutics_AffiliatePartner_ID__c' => 'Accutics_AffiliatePartner_ID__c',
					'Name' => 'ZP_Lead_Campaign__c'
				};

				if (objRelatedCampaign != null) {
					for (String strCampaignField : map_CampaignToLeads.keySet()) {
						String strLeadField = map_CampaignToLeads.get(strCampaignField);
						if (objRelatedCampaign.get(strCampaignField) != objLead.get(strLeadField)) {
							objLead.put(strLeadField, objRelatedCampaign.get(strCampaignField));
						}
					}
				}
			}
		}
	}
}