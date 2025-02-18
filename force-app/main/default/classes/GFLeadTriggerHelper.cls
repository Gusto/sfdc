/**
Created by : Aurobind Ravichandran
Created Date : 5/27/2017
Modified Date: 12/01/2017- Include Rev code field mapping(BT-6) & Hi sign up(BT-242)
**/
public without sharing class GFLeadTriggerHelper {
	public static boolean skipTrigger = false;
	public static boolean queue = false;
	public static boolean blnFromGFLead = false;
	private map<String, Lead> companyLeadMap;
	private map<String, Lead> resellerLeadMap;
	private map<String, Contact> resellerContactMap;
	private map<String, Contact> companyContactMap;
	private map<String, Lead> accountantCompanyLeadMap;
	private map<String, Lead> accountantResellerLeadMap;
	private map<String, Lead> practiceIDLeadMap;
	private map<String, Contact> accountantContactMap;
	private map<Id, User> salesPartnerXeroRole;
	private List<String> xeroLandingPages = new List<String>{ 'Xero0719_Reduced', 'Xero0719PartnerSMB', 'Xero0719_Excluded', 'xero_partnership', 'xero' };
	private map<String, Account> map_Firms;
	private map<String, Account> map_Companies;
	public static List<String> list_Competitors = new List<String>();
	public static List<String> list_Partners = new List<String>();
	public static List<String> list_Employees = new List<String>();
	public static Map<Id, Account> map_AccountsUpdate = new Map<Id, Account>();

	// Constructor:
	public GFLeadTriggerHelper() {
		map_Firms = new Map<String, Account>();
		map_Companies = new Map<String, Account>();
	}

	public static Map<String, List<Task>> map_AccountIdToTasks = new Map<String, List<Task>>();

	public void processBeforeInsert(List<GF_Lead__c> list_Leads) {
		try {
			List<GF_Lead__c> list_GFLeadsToProcess = returnRecordsToProcess(list_Leads);
			if (!list_GFLeadsToProcess.isEmpty()) {
				if (queue) {
					processInformation(list_GFLeadsToProcess);
				}
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('GFLeadTriggerHelper', 'processBeforeInsert', objEx);
		}
	}

	public void processAfterInsert(Map<Id, GF_Lead__c> map_NewLeads) {
		if (!queue) {
			List<GF_Lead__c> list_GFLeadsToProcess = new List<GF_Lead__c>();

			for (GF_Lead__c objGFLead : map_NewLeads.values()) {
				if (objGFLead.Processing_State__c != IntegrationUtils.DEAD_STATE) {
					list_GFLeadsToProcess.add(objGFLead);
				}
			}
			if (!list_GFLeadsToProcess.isEmpty()) {
				System.enqueueJob(new GFLeadQueue(list_GFLeadsToProcess));
			}
		}
	}

	public void processBeforeUpdate(Map<Id, GF_Lead__c> map_OldLeads, Map<Id, GF_Lead__c> map_NewLeads) {
		try {
			List<GF_Lead__c> list_GFLeadsToProcess = returnRecordsToProcess(map_NewLeads.values());
			if (!list_GFLeadsToProcess.isEmpty()) {
				if (queue) {
					processInformation(list_GFLeadsToProcess);
				}
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('GFLeadTriggerHelper', 'processBeforeUpdate', objEx);
		}
	}

	public void processAfterUpdate(Map<Id, GF_Lead__c> map_OldLeads, Map<Id, GF_Lead__c> map_NewLeads) {
		if (!queue) {
			List<GF_Lead__c> list_GFLeadsToProcess = new List<GF_Lead__c>();

			for (GF_Lead__c objGFLead : map_NewLeads.values()) {
				if (objGFLead.Processing_State__c != IntegrationUtils.DEAD_STATE) {
					list_GFLeadsToProcess.add(objGFLead);
				}
			}

			if (!list_GFLeadsToProcess.isEmpty()) {
				System.enqueueJob(new GFLeadQueue(list_GFLeadsToProcess));
			}
		}
	}

	private Lead updateForXero(GF_Lead__c gfLead, Lead l, String type) {
		Group objGroup = [SELECT Id, Name FROM Group WHERE Type = :GFLeadUtil.GRP_TYPE_QUEUE AND Name = :GFLeadUtil.GRP_NAME_XERO_AE_ROTATOR];

		//lets check for Xero based on source and campaign combination. This is when creating new direct lead
		if (
			gfLead.Sold_By__c == null &&
			type == 'Company' &&
			gfLead.Source__c != null &&
			(gfLead.Source__c.equalsIgnoreCase('xero_migration_partner') || gfLead.Source__c.equalsIgnoreCase('xero_provisioning_partners'))
		) {
			if (practiceIDLeadMap.containskey(gfLead.External_Practice_Id__c)) {
				Lead lead = practiceIDLeadMap.get(gfLead.External_Practice_Id__c);
				if (lead != null && salesPartnerXeroRole.containsKey(lead.OwnerId)) {
					l.ownerId = lead.OwnerId;
				} else {
					l.OwnerId = objGroup.Id;
				}
			} else {
				l.OwnerId = objGroup.Id;
			}
		} else if (
			type == 'Company' &&
			gfLead.Campaign__c != null &&
			gfLead.Source__c != null &&
			((gfLead.Source__c.equalsIgnoreCase('xero_partnership') &&
			(gfLead.Campaign__c.equalsIgnoreCase('Xero0719_Reduced') ||
			gfLead.Campaign__c.equalsIgnoreCase('Xero0719PartnerSMB') ||
			gfLead.Campaign__c.equalsIgnoreCase('Xero0719_Excluded'))) ||
			(gfLead.Source__c.equalsIgnoreCase('xero') && (gfLead.Campaign__c.equalsIgnoreCase('Xero_Partner_Unknown') || gfLead.Campaign__c.equalsIgnoreCase('Xero0719New'))))
		) {
			if (gfLead.Sold_By__c == null && gfLead.External_Accountant_Email__c == null) {
				l.OwnerId = objGroup.Id; //assign to rotator
			} else if (gfLead.Sold_By__c == null && gfLead.External_Accountant_Email__c != null) {
				//check who is owner and if has particular partner role, else assign back to rotator
				if (accountantContactMap.containsKey(gfLead.External_Accountant_Email__c) || accountantCompanyLeadMap.containsKey(gfLead.External_Accountant_Email__c)) {
					if (accountantContactMap.containsKey(gfLead.External_Accountant_Email__c)) {
						Contact cnt = accountantContactMap.get(gfLead.External_Accountant_Email__c);
						if (cnt != null && salesPartnerXeroRole.containsKey(cnt.OwnerId)) {
							l.ownerId = cnt.OwnerId;
						} else {
							l.OwnerId = objGroup.Id;
						}
					} else if (accountantCompanyLeadMap.containsKey(gfLead.External_Accountant_Email__c)) {
						Lead lead = accountantCompanyLeadMap.get(gfLead.External_Accountant_Email__c);
						if (lead != null && salesPartnerXeroRole.containsKey(lead.OwnerId)) {
							l.ownerId = lead.OwnerId;
						} else {
							l.OwnerId = objGroup.Id;
						}
					}
				} else {
					//assign the AE rotator
					l.OwnerId = objGroup.Id;
				}
			}
		}

		return l;
	}

	public Lead getMappedNewLead(GF_Lead__c gfLead, String type) {
		Lead l = new Lead();
		l.Visitor_Id__c = gfLead.Visitor_Id__c;
		l.Session_Id__c = gfLead.Session_Id__c;
		if (gfLead.Company_Name__c == null || gfLead.Company_Name__c == '') {
			l.Company = 'NA';
		} else {
			l.Company = gfLead.Company_Name__c;
		}
		l.Email = gfLead.Email__c.tolowercase();
		l.RecordTypeId = Cache.getRecordTypeId('Lead', type);

		if (gfLead.First_Name__c != null && gfLead.First_Name__c != '' && gfLead.First_Name__c.length() > 40)
			l.FirstName = gfLead.First_Name__c.substring(0, 40);
		else
			l.FirstName = gfLead.First_Name__c;

		if (gfLead.Last_Name__c == null || gfLead.Last_Name__c == '') {
			l.LastName = 'NA';
		} else {
			l.LastName = gfLead.Last_Name__c;
		}

		l.Phone = gfLead.Phone__c;
		l.Pricing__c = gfLead.Pricing__c;
		l.Lead_States__c = gfLead.States__c;
		l.Referral_Token__c = gfLead.Referral_Token__c;

		setLeadReferralType(gfLead, l);

		if (type == 'Company') {
			l.ZP_Company_Lead_ID__c = gfLead.ZP_Legacy_Lead_ID__c;
			l.NumberOfEmployees = Integer.valueof(gfLead.Number_Of_Employees__c);
		} else if (type == 'Reseller') {
			l.ZP_Accountant_Lead_ID__c = gfLead.ZP_Legacy_Lead_ID__c;
			l.No_Firm_Employees__c = '' + Integer.valueof(gfLead.Number_Of_Employees__c);
		}

		if (gfLead.Referred_By_Accounting_Firm_Id__c != null && gfLead.Referred_By_Accounting_Firm_Id__c != '') {
			if (map_Firms.containsKey(gfLead.Referred_By_Accounting_Firm_Id__c)) {
				l.Referred_By__c = map_Firms.get(gfLead.Referred_By_Accounting_Firm_Id__c).Id;
			}
		} else if (gfLead.Referred_By_Company_Id__c != null && gfLead.Referred_By_Company_Id__c != '') {
			if (map_Companies.containsKey(gfLead.Referred_By_Company_Id__c)) {
				l.Referred_By__c = map_Companies.get(gfLead.Referred_By_Company_Id__c).Id;
			}
		}
		if (gfLead.Sold_By__c != null && gfLead.Sold_By__c != '') {
			if (map_Firms.containsKey(gfLead.Sold_By__c)) {
				l.Sold_By__c = map_Firms.get(gfLead.Sold_By__c).Id;
			}
		}
		if (gfLead.Created_At__c != null) {
			l.ZP_Lead_Created_At_Date__c = date.newinstance(gfLead.Created_At__c.year(), gfLead.Created_At__c.month(), gfLead.Created_At__c.day());
		}

		l.Submitted_From__c = gfLead.Submitted_From__c;
		l.Lead_Type__c = gfLead.Lead_Type__c;
		l.Ramp_Intent__c = gfLead.Ramp_Intent__c;
		l.Partner_Program_Request_Create_Date__c = gfLead.Partner_Program_Request_Create_Date__c;
		l.LeadSource = gfLead.Source__c;
		l.Corp_Signup_Interest__c = gfLead.Signup_Interest_Page__c;
		l.ZP_Lead_Promo__c = gfLead.Promo__c;
		l.ZP_Lead_Campaign__c = gfLead.Campaign__c;
		l.HI_Signup__c = gfLead.HI_Status__c;

		if (gfLead.No_Of_Clients__c != null && gfLead.No_of_Clients_Bucket__c == null) {
			l.No_of_Clients__c = Integer.valueOf(gfLead.No_Of_Clients__c);
		}

		l.No_Clients_Payroll__c = Integer.valueOf(gfLead.No_Clients_Payroll__c);
		l.Unique_Email_Address__c = type + '-' + gfLead.Email__c.tolowercase();
		l.No_of_Clients_Bucket__c = gfLead.No_of_Clients_Bucket__c;
		l.Payroll_Relationship__c = gfLead.Payroll_Relationship__c;
		l.No_Firm_Employees__c = gfLead.No_Firm_Employees__c;
		l.Company_Invite_Token__c = gfLead.Company_Invite_Token__c;
		l.Trk_creative__c = gfLead.Trk_creative__c;
		l.Trk_Device__c = gfLead.Trk_Device_c__c;
		l.Trk_gclid__c = gfLead.Trk_gclid__c;
		l.Trk_Keyword__c = gfLead.Trk_Keyword__c;
		l.Trk_matchtype__c = gfLead.Trk_matchtype__c;
		l.Trk_network__c = gfLead.Trk_network__c;
		l.Trk_Placement__c = gfLead.Trk_Placement__c;
		l.Trk_UTM_Medium__c = gfLead.Trk_UTM_Medium__c;
		l.Trk_UTM_Content__c = gfLead.Trk_UTM_Content__c;
		l.adgroup__c = gfLead.adgroup__c;
		l.msclkid__c = gfLead.msclkid__c;
		l.Landing_Page__c = gfLead.Landing_Page__c;
		l.HI_Deductions__c = gfLead.HI_Deductions__c;
		l.HI_Interest__c = gfLead.HI_Interest__c;
		l.Has_paid_W_2_or_1099_elsewhere__c = gfLead.Has_paid_W_2_or_1099_elsewhere__c;
		l.Contractor_Only__c = gfLead.Contractor_Only__c;
		l.System_Of_Origin__c = 'GFS';
		l.Growth_Experiments_when_lead_created__c = gfLead.Growth_Experiments_when_lead_created__c;
		l.External_Accountant_Email__c = gfLead.External_Accountant_Email__c;
		l.External_Accountant_Name__c = gfLead.External_Accountant_Name__c;
		l.External_Practice_Id__c = gfLead.External_Practice_Id__c;
		l.URL_of_Conversion__c = gfLead.URL_of_Conversion__c;
		l.Onboarding_Flow__c = gfLead.Onboarding_Flow__c;
		l.Website = gfLead.Website__c;
		l.Potential_Fraud_Lead__c = gfLead.Potential_Fraud__c;
		l.Lead_Rating__c = gfLead.Lead_Rating__c;

		return l;
	}

	/* Mod by : Yuvraj
	 * Date : 06-07-2020
	 * Desc: Added new field "SMS_Consent__c" in lead - gf lead mapping .
	 * Asana Ticket : https://app.asana.com/0/1165890935117693/1183250300356521
	 * Mod by 			Date 			Desc
	 * Yuvraj 			31-07-2020 		Moved the fields(mentioned in asana) above isconverted check.
	 * 									Asana: https://app.asana.com/0/1165890935117693/1181451070080315
	 */
	private Lead getMappedExistingLead(GF_Lead__c gfLead, String type, Lead ld, Boolean contactExists) {
		Lead l = ld;

		if (gfLead.Lead_Type__c == 'Company') {
			l.ZP_Company_Lead_ID__c = gfLead.ZP_Legacy_Lead_ID__c;
		}

		if (gfLead.Submitted_From__c != null && gfLead.Submitted_From__c != '')
			l.Submitted_From__c = gfLead.Submitted_From__c;

		if (gfLead.Onboarding_Flow__c != null && gfLead.Onboarding_Flow__c != '')
			l.Onboarding_Flow__c = gfLead.Onboarding_Flow__c;

		if (
			(l.Company == null ||
			l.Company == '' ||
			l.Company == 'NA' ||
			l.Company == 'N/A') &&
			gfLead.Company_Name__c != null &&
			gfLead.Company_Name__c != '' &&
			gfLead.Company_Name__c != 'NA' &&
			gfLead.Company_Name__c != 'N/A'
		) {
			l.Company = gfLead.Company_Name__c;
		}

		if (type == 'Company') {
			if (l.ZP_Company_Lead_ID__c == null || l.ZP_Company_Lead_ID__c == '') {
				l.ZP_Company_Lead_ID__c = gfLead.ZP_Legacy_Lead_ID__c;
			}
			if (l.NumberOfEmployees == null || l.NumberOfEmployees == 0) {
				l.NumberOfEmployees = Integer.valueof(gfLead.Number_Of_Employees__c);
			}
		} else if (type == 'Reseller') {
			if (String.isBlank(l.ZP_Accountant_Lead_ID__c)) {
				l.ZP_Accountant_Lead_ID__c = gfLead.ZP_Legacy_Lead_ID__c;
			}
		}

		if (l.ZP_Lead_Created_At_Date__c == null && gfLead.Created_At__c != null) {
			l.ZP_Lead_Created_At_Date__c = date.newinstance(gfLead.Created_At__c.year(), gfLead.Created_At__c.month(), gfLead.Created_At__c.day());
		}

		if (l.IsConverted || contactExists) {
			return l;
		}

		if (l.Pricing__c == null || l.Pricing__c == '') {
			l.Pricing__c = gfLead.Pricing__c;
		}

		if (l.Lead_States__c == null || l.Lead_States__c == '') {
			l.Lead_States__c = gfLead.States__c;
		}

		if (type == 'Reseller') {
			if (l.No_Firm_Employees__c == null || l.No_Firm_Employees__c == '') {
				l.No_Firm_Employees__c = '' + Integer.valueof(gfLead.Number_Of_Employees__c);
			}
		}

		l.Unique_Email_Address__c = type + '-' + gfLead.Email__c.tolowercase();

		if (l.Referred_By__c == null && map_Firms.containsKey(gfLead.Referred_By_Accounting_Firm_Id__c)) {
			l.Referred_By__c = map_Firms.get(gfLead.Referred_By_Accounting_Firm_Id__c).Id;
		}

		if (l.Sold_By__c == null && map_Firms.containsKey(gfLead.Sold_By__c)) {
			l.Sold_By__c = map_Firms.get(gfLead.Sold_By__c).Id;
		}
		if (l.Corp_Signup_Interest__c == null || l.Corp_Signup_Interest__c == '') {
			l.Corp_Signup_Interest__c = gfLead.Signup_Interest_Page__c;
		}
		if (l.ZP_Lead_Promo__c == null || l.ZP_Lead_Promo__c == '') {
			l.ZP_Lead_Promo__c = gfLead.Promo__c;
		}
		if (l.HI_Signup__c == null || l.HI_Signup__c == '') {
			l.HI_Signup__c = gfLead.HI_Status__c;
		}

		if (l.Payroll_Relationship__c == null || l.Payroll_Relationship__c == '' || l.Payroll_Relationship__c == 'null') {
			l.Payroll_Relationship__c = gfLead.Payroll_Relationship__c;
		}
		if (!l.Has_paid_W_2_or_1099_elsewhere__c) {
			l.Has_paid_W_2_or_1099_elsewhere__c = gfLead.Has_paid_W_2_or_1099_elsewhere__c;
		}

		if (!l.Contractor_Only__c) {
			l.Contractor_Only__c = gfLead.Contractor_Only__c;
		}

		if (l.No_Firm_Employees__c == null || l.No_Firm_Employees__c == '' || l.No_Firm_Employees__c == 'null') {
			l.No_Firm_Employees__c = gfLead.No_Firm_Employees__c;
		}
		if (l.Company_Invite_Token__c == null || l.Company_Invite_Token__c == '') {
			l.Company_Invite_Token__c = gfLead.Company_Invite_Token__c;
		}
		if (l.Trk_Device__c == null || l.Trk_Device__c == '') {
			l.Trk_Device__c = gfLead.Trk_Device_c__c;
		}
		if (l.Trk_gclid__c == null || l.Trk_gclid__c == '') {
			l.Trk_gclid__c = gfLead.Trk_gclid__c;
		}
		if (l.Trk_Keyword__c == null || l.Trk_Keyword__c == '') {
			l.Trk_Keyword__c = gfLead.Trk_Keyword__c;
		}
		if (l.Trk_matchtype__c == null || l.Trk_matchtype__c == '') {
			l.Trk_matchtype__c = gfLead.Trk_matchtype__c;
		}
		if (l.Trk_network__c == null || l.Trk_network__c == '') {
			l.Trk_network__c = gfLead.Trk_network__c;
		}
		if (l.Trk_Placement__c == null || l.Trk_Placement__c == '') {
			l.Trk_Placement__c = gfLead.Trk_Placement__c;
		}
		if (l.Trk_UTM_Medium__c == null || l.Trk_UTM_Medium__c == '') {
			l.Trk_UTM_Medium__c = gfLead.Trk_UTM_Medium__c;
		}
		if (l.Trk_UTM_Content__c == null || l.Trk_UTM_Content__c == '') {
			l.Trk_UTM_Content__c = gfLead.Trk_UTM_Content__c;
		}
		if (l.msclkid__c == null || l.msclkid__c == '') {
			l.msclkid__c = gfLead.msclkid__c;
		}
		if (l.adgroup__c == null || l.adgroup__c == '') {
			l.adgroup__c = gfLead.adgroup__c;
		}
		if (l.Trk_creative__c == null || l.Trk_creative__c == '') {
			l.Trk_creative__c = gfLead.Trk_creative__c;
		}

		if (l.Landing_Page__c == null || l.Landing_Page__c == '') {
			l.Landing_Page__c = gfLead.Landing_Page__c;
		}
		if (l.HI_Interest__c == null || l.HI_Interest__c == '') {
			l.HI_Interest__c = gfLead.HI_Interest__c;
		}

		if (String.isBlank(l.Growth_Experiments_when_lead_created__c)) {
			l.Growth_Experiments_when_lead_created__c = gfLead.Growth_Experiments_when_lead_created__c;
		}

		return l;
	}

	private void processInformation(List<GF_Lead__c> leadList) {
		//throw new BaseException('test');
		blnFromGFLead = true;
		Set<String> emailIdSet = new Set<String>();
		Set<String> accountEmailIdSet = new Set<String>();
		Set<String> externalPracticeIdSet = new Set<String>();
		Set<String> accountingFirmIdSet = new Set<String>();
		Set<String> companyIdSet = new Set<String>();
		Set<String> leadInsertEmailSet = new Set<String>();
		Set<String> set_ContactAccountId = new Set<String>();
		companyLeadMap = new Map<String, Lead>();
		resellerLeadMap = new Map<String, Lead>();
		accountantCompanyLeadMap = new Map<String, Lead>();
		accountantResellerLeadMap = new Map<String, Lead>();
		practiceIDLeadMap = new Map<String, Lead>();
		resellerContactMap = new Map<String, Contact>();
		companyContactMap = new Map<String, Contact>();
		accountantContactMap = new Map<String, Contact>();
		salesPartnerXeroRole = new Map<Id, User>();
		map_Firms = new Map<String, Account>();
		map_Companies = new Map<String, Account>();
		map_AccountIdToTasks = new Map<String, List<Task>>();
		list_Competitors = Label.Competitors.toLowerCase().split(',');
		list_Partners = Label.Partners.toLowerCase().split(',');
		list_Employees = Label.Employees.toLowerCase().split(',');

		for (GF_Lead__c gfLead : leadList) {
			if (gfLead.email__c != null && gfLead.email__c != '') {
				gfLead.email__c = gfLead.email__c.tolowercase();
				emailIdSet.add(gfLead.email__c.tolowercase());
			}
			if (gfLead.Referred_By_Accounting_Firm_Id__c != null && gfLead.Referred_By_Accounting_Firm_Id__c != '') {
				accountingFirmIdSet.add(gfLead.Referred_By_Accounting_Firm_Id__c);
			}
			if (gfLead.Sold_By__c != null && gfLead.Sold_By__c != '') {
				accountingFirmIdSet.add(gfLead.Sold_By__c);
			}
			if (gfLead.Referred_By_Company_Id__c != null && gfLead.Referred_By_Company_Id__c != '') {
				companyIdSet.add(gfLead.Referred_By_Company_Id__c);
			}
			if (gfLead.External_Accountant_Email__c != null && gfLead.Lead_Type__c == 'Company') {
				accountEmailIdSet.add(gfLead.External_Accountant_Email__c);
			}
			if (gfLead.External_Practice_Id__c != null && gfLead.Lead_Type__c == 'Company') {
				externalPracticeIdSet.add(gfLead.External_Practice_Id__c);
			}
		}

		if (emailIdSet.size() > 0) {
			setExistingEmailLeadMap(emailIdSet);
			setExistingEmailContactMap(emailIdSet);
			for (Contact c : companyContactMap.values()) {
				if (c.Account != null && c.Account.ZP_Company_id__c != null)
					companyIdSet.add(c.Account.ZP_Company_id__c);
				if (c.Account != null && c.Account.Zp_Firm_id__c != null)
					accountingFirmIdSet.add(c.Account.Zp_Firm_id__c);
				if (c.Account != null) {
					set_ContactAccountId.add(c.AccountId);
				}
			}
			for (Contact c : resellerContactMap.values()) {
				if (c.Account.ZP_Company_id__c != null)
					companyIdSet.add(c.Account.ZP_Company_id__c);
				if (c.Account.Zp_Firm_id__c != null)
					accountingFirmIdSet.add(c.Account.Zp_Firm_id__c);
				if (c.Account != null) {
					set_ContactAccountId.add(c.AccountId);
				}
			}
		}
		if (accountEmailIdSet.size() > 0 || externalPracticeIdSet.size() > 0) {
			//check on lead and contact for accountant email id
			setExistingAccontantEmailMap(accountEmailIdSet, externalPracticeIdSet);
		}

		if (!companyIdSet.isEmpty() || !accountingFirmIdSet.isEmpty()) {
			queryAccounts(companyIdSet, accountingFirmIdSet);
		}

		if (set_ContactAccountId.size() > 0) {
			setAccountIdToTasksMap(set_ContactAccountId);
		}

		List<Lead> leadListForUpdate = new List<Lead>();
		List<Lead> leadListForInsert = new List<Lead>();
		List<Contact> contactListForUpdate = new List<Contact>();
		for (GF_Lead__c gfLead : leadList) {
			if (gfLead.email__c != null && gfLead.email__c != '') {
				gfLead.Message__c = '';
				if (gfLead.Referred_By_Accounting_Firm_Id__c != null && gfLead.Referred_By_Accounting_Firm_Id__c != '' && map_Firms.containsKey(gfLead.Referred_By_Accounting_Firm_Id__c) == false) {
					setProcessingState(IntegrationUtils.ERROR_STATE, 'Referred by accounting firm does not exist', gfLead);
				}
				if (gfLead.Sold_By__c != null && gfLead.Sold_By__c != '' && map_Firms.containsKey(gfLead.Sold_By__c) == false) {
					setProcessingState(IntegrationUtils.ERROR_STATE, 'Sold by firm does not exist', gfLead);
				}
				if (gfLead.Referred_By_Company_Id__c != null && gfLead.Referred_By_Company_Id__c != '' && map_Companies.containsKey(gfLead.Referred_By_Company_Id__c) == false) {
					setProcessingState(IntegrationUtils.ERROR_STATE, 'Referred by company does not exist', gfLead);
				}

				if (gfLead.Lead_Type__c == 'Company') {
					if (companyLeadMap.containsKey(gfLead.Email__c)) {
						Lead l = companyLeadMap.get(gfLead.Email__c);
						Boolean contactExists = false;
						if (companyContactMap.containsKey(gfLead.Email__c)) {
							if (l.IsConverted) {
								Contact objContact = companyContactMap.get(gfLead.Email__c);
								if (String.isNotBlank(gfLead.Phone__c) && String.isBlank(objContact.Phone)) {
									objContact.Phone = gfLead.Phone__c;
									companyContactMap.put(gfLead.Email__c, objContact);
								}
							}
							contactExists = true;
						}
						if (!l.IsConverted) {
							l = getMappedExistingLead(gfLead, 'Company', l, contactExists);
							if (
								(l.Status == 'Future Opportunity' ||
								l.Status == 'Back to Nurture') &&
								String.isNotBlank(l.Phone) &&
								String.isNotBlank(l.Email) &&
								(l.MQL_DateTime__c == null ||
								l.MQL_DateTime__c < (System.today() - 7))
							) {
								l.Status = 'MQL';
								setMQLDate(l);
							}
						}
						// Stamping values from GF Lead to Lead irrespective of lead conversion status
						l = setCommonFieldsOnLead(gfLead, l);
						// Praveen's Changes to sync GF Lead to Lead ends here

						leadListForUpdate.add(l);

						if (string.isBlank(gfLead.Processing_Result__c))
							gfLead.Processing_Result__c = 'Lead Already Exists';
					} else if (!companyContactMap.containsKey(gfLead.Email__c)) {
						Lead l = getMappedNewLead(gfLead, 'Company');
						l.GF_Lead_Last_Updated_Date_Time__c = gfLead.Updated_At__c;
						//check if gflead is for Xero
						l = updateForXero(gfLead, l, 'Company');
						leadListForInsert.add(l);
						leadInsertEmailSet.add(gfLead.Email__c);
					}

					if (companyContactMap.containsKey(gfLead.Email__c)) {
						Contact c = getContactInfoForUpdate(companyContactMap.get(gfLead.Email__c), 'Lead form submission');
						contactListForUpdate.add(c);
						if (string.isBlank(gfLead.Processing_Result__c))
							gfLead.Processing_Result__c = 'Contact Already Exists';
					}
				} else if (gfLead.Lead_Type__c == 'Accountant') {
					if (resellerLeadMap.containsKey(gfLead.Email__c)) {
						Lead l = resellerLeadMap.get(gfLead.Email__c);
						Boolean contactExists = false;
						if (resellerContactMap.containsKey(gfLead.Email__c)) {
							if (l.IsConverted) {
								Contact objContact = resellerContactMap.get(gfLead.Email__c);
								if (String.isNotBlank(gfLead.Phone__c) && String.isBlank(objContact.Phone)) {
									objContact.Phone = gfLead.Phone__c;
									resellerContactMap.put(gfLead.Email__c, objContact);
								}
							}
							contactExists = true;
						}
						if (!l.IsConverted) {
							l = getMappedExistingLead(gfLead, 'Reseller', l, contactExists);
							if (
								(l.Status == 'Future Opportunity' ||
								l.Status == 'Back to Nurture') &&
								String.isNotBlank(l.Phone) &&
								String.isNotBlank(l.Email) &&
								(l.MQL_DateTime__c == null ||
								l.MQL_DateTime__c < (System.today() - 14))
							) {
								l.Status = 'MQL';
								setMQLDate(l);
							}
						}
						// Stamping values from GF Lead to Lead irrespective of lead conversion status
						l = setCommonFieldsOnLead(gfLead, l);
						// Praveen's Changes to sync GF Lead to Lead ends here

						leadListForUpdate.add(l);

						if (string.isBlank(gfLead.Processing_Result__c))
							gfLead.Processing_Result__c = 'Lead Already Exists';
					} else if (!resellerContactMap.containsKey(gfLead.Email__c)) {
						Lead l = getMappedNewLead(gfLead, 'Reseller');
						l.GF_Lead_Last_Updated_Date_Time__c = gfLead.Updated_At__c;
						leadListForInsert.add(l);
						leadInsertEmailSet.add(gfLead.Email__c);
					}

					if (resellerContactMap.containsKey(gfLead.Email__c)) {
						Contact c = getContactInfoForUpdate(resellerContactMap.get(gfLead.Email__c), 'Lead form submission');
						contactListForUpdate.add(c);
						if (string.isBlank(gfLead.Processing_Result__c))
							gfLead.Processing_Result__c = 'Contact Already Exists';
					}
				}
			}
		}

		Map<String, String> dmlUpdateErrorsMap = new Map<String, String>();
		if (leadListForUpdate.size() > 0) {
			List<Database.SaveResult> saveResult = Database.update(leadListForUpdate, false);
			dmlUpdateErrorsMap = Utils.processSaveResult(saveResult, leadListForUpdate, 'email', false, 'GFLeadTriggerHelper-processInformation-LeadUpdate');
		}

		Map<String, String> dmlInsertErrorsMap = new Map<String, String>();
		if (leadListForInsert.size() > 0) {
			List<Database.SaveResult> saveResult = Database.insert(leadListForInsert, false);
			dmlInsertErrorsMap = Utils.processSaveResult(saveResult, leadListForInsert, 'email', false, 'GFLeadTriggerHelper-processInformation-LeadInsert');
		}

		Map<String, String> dmlContactUpdateErrorsMap = new Map<String, String>();
		if (contactListForUpdate.size() > 0) {
			List<Database.SaveResult> saveResult = Database.update(contactListForUpdate, false);
			TriggerHandler.bypass('ContactTriggerHandler');
			dmlContactUpdateErrorsMap = Utils.processSaveResult(saveResult, contactListForUpdate, 'email', false, 'GFLeadTriggerHelper-processInformation-ConUpdate');
			TriggerHandler.clearBypass('ContactTriggerHandler');
		}

		Map<String, String> dmlAccountUpdateErrorsMap = new Map<String, String>();
		if (map_AccountsUpdate != null && map_AccountsUpdate.size() > 0) {
			TriggerHandler.bypass('AccountTriggerHandler');
			List<Database.SaveResult> saveResult = Database.update(map_AccountsUpdate.values(), false);
			dmlAccountUpdateErrorsMap = Utils.processSaveResult(saveResult, map_AccountsUpdate.values(), 'email', false, 'GFLeadTriggerHelper-processInformation-AccUpdate');
			TriggerHandler.clearBypass('AccountTriggerHandler');
		}

		//check for xero lead for linking
		map<Lead, Lead> directResellerMap = new Map<Lead, Lead>();
		List<Lead> directLeadToUpdate = new List<Lead>();
		set<Id> directLeadIds = new Set<Id>();
		for (Lead leadInserted : leadListForInsert) {
			if (leadInserted.id != null && leadInserted.External_Accountant_Email__c != null) {
				directLeadIds.add(leadInserted.id);
			}
		}
		if (directLeadIds.size() > 0) {
			map<id, Lead> updatedDirectOwnerMap = new Map<id, Lead>([SELECT id, OwnerId FROM Lead WHERE Id IN :directLeadIds]);
			for (Lead leadInserted : leadListForInsert) {
				//if the lead is not duplicate (not exists as company and contact and as well as reseller then create a reseller lead)
				if (
					leadInserted.id != null &&
					leadInserted.External_Accountant_Email__c != null &&
					!accountantResellerLeadMap.containsKey(leadInserted.External_Accountant_Email__c) &&
					!accountantContactMap.containsKey(leadInserted.External_Accountant_Email__c) &&
					!accountantCompanyLeadMap.containsKey(leadInserted.External_Accountant_Email__c)
				) {
					Lead reseller = new Lead();
					reseller.Email = leadInserted.External_Accountant_Email__c.tolowercase();
					reseller.RecordTypeId = Cache.getRecordTypeId('Lead', 'Reseller');
					reseller.LeadSource = 'Xero_Partnership';
					if (leadInserted.External_Accountant_Name__c != null) {
						reseller.LastName = leadInserted.External_Accountant_Name__c;
						reseller.Company = leadInserted.External_Accountant_Name__c;
					} else {
						reseller.LastName = 'Unknown';
						reseller.Company = 'Unknown';
					}
					//lead owner has assigned from dispatcher from rotator on insert assuming rotator has correct assignmnet
					if (updatedDirectOwnerMap != null && updatedDirectOwnerMap.containskey(leadInserted.id)) {
						reseller.OwnerId = updatedDirectOwnerMap.get(leadInserted.id).OwnerId;
						leadInserted.ownerid = updatedDirectOwnerMap.get(leadInserted.id).OwnerId;
					}
					directResellerMap.put(leadInserted, reseller);
					//if it already exists as reseller then get the lead and link to direct lead created above
				} else if (leadInserted.id != null && leadInserted.External_Accountant_Email__c != null && accountantResellerLeadMap.containsKey(leadInserted.External_Accountant_Email__c)) {
					leadInserted.ownerid = updatedDirectOwnerMap.get(leadInserted.id).OwnerId;
					leadInserted.External_Accountant_Lead__c = accountantResellerLeadMap.get(leadInserted.External_Accountant_Email__c).id;
					directLeadToUpdate.add(leadInserted);
				}
			}
		}
		// this map will be created when lead does not exists anywhere in system, a new reseller will get created and will be linked to direct lead
		if (directResellerMap.size() > 0) {
			try {
				insert directResellerMap.values();
				//update direct lead for linking
				for (Lead directLead : directResellerMap.keyset()) {
					Lead resellerLead = directResellerMap.get(directLead);
					if (resellerLead.id != null) {
						directLead.External_Accountant_Lead__c = resellerLead.id;
						directLeadToUpdate.add(directLead);
					}
				}
			} catch (Exception e) {
				System.debug('Error while inserting reseller leads!');
			}
		}
		//update it for linking the reseller lead whether existing or newly created
		if (directLeadToUpdate.size() > 0) {
			LeadTriggerHelper.skipTrigger = true;
			update directLeadToUpdate;
			LeadTriggerHelper.skipTrigger = false;
		}

		setExistingEmailLeadMap(emailIdSet);
		setExistingEmailContactMap(emailIdSet);

		// check for success results and create the reseller leads for those successful ids.

		for (GF_Lead__c gfLead : leadList) {
			if (gfLead.Processing_State__c == IntegrationUtils.ERROR_STATE || gfLead.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			if (gfLead.email__c != null && gfLead.email__c != '') {
				if (gflead.Lead_Type__c == 'Company' && companyLeadMap.containsKey(gfLead.email__c)) {
					gflead.Lead__c = companyLeadMap.get(gfLead.email__c).id;
				}
				if (gflead.Lead_Type__c == 'Accountant' && resellerLeadMap.containsKey(gfLead.email__c)) {
					gflead.Lead__c = resellerLeadMap.get(gfLead.email__c).id;
				}
				if (resellerContactMap.containsKey(gfLead.email__c)) {
					gflead.contact__c = resellerContactMap.get(gfLead.email__c).id;
				}
				if (companyContactMap.containsKey(gfLead.email__c)) {
					gflead.contact__c = companyContactMap.get(gfLead.email__c).id;
				}
				if (gflead.Lead__c != null && leadInsertEmailSet.contains(gfLead.Email__c)) {
					gfLead.Processing_Result__c = 'Lead Created';
				}

				if (dmlUpdateErrorsMap.containsKey(gfLead.email__c)) {
					// set record processing state to backlog if embedded contact exist with same email
					String strMessage = dmlUpdateErrorsMap.get(gfLead.email__c);

					System.debug('strMessage ' + strMessage);
					String strProcessingState = String.isNotBlank(strMessage) && (strMessage.trim() == LeadUtil.EMBEDDED_CON_EXIST_ERR_MESSAGE)
						? IntegrationUtils.BACKLOG
						: IntegrationUtils.ERROR_STATE;

					setProcessingState(strProcessingState, strMessage, gfLead);
				} else if (dmlInsertErrorsMap.containsKey(gfLead.email__c)) {
					setProcessingState(IntegrationUtils.ERROR_STATE, dmlInsertErrorsMap.get(gfLead.email__c), gfLead);
				} else if (dmlContactUpdateErrorsMap.containsKey(gfLead.email__c)) {
					setProcessingState(IntegrationUtils.ERROR_STATE, dmlContactUpdateErrorsMap.get(gfLead.email__c), gfLead);
				} else if (gfLead.Message__c == null || gfLead.Message__c == '') {
					setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Processed', gfLead);
				}

				// Mark record as Dead if invalid email address is found
				if (String.isNotBlank(gfLead.Message__c) && gfLead.Message__c.contains(GFLeadUtil.MSG_INVALID_EMAIL)) {
					setProcessingState(IntegrationUtils.DEAD_STATE, gfLead.Message__c, gfLead);
				}

				if (gfLead.Reprocess_Counter__c == null) {
					gfLead.Reprocess_Counter__c = 0;
				}

				if (gfLead.Processing_State__c == IntegrationUtils.ERROR_STATE && String.isNotBlank(gfLead.Message__c)) {
					Boolean blnErrorFound = false;
					for (String strErrMsg : GFLeadUtil.set_ReprocessErrMsgs) {
						blnErrorFound = gfLead.Message__c.toLowerCase().containsIgnoreCase(strErrMsg);
						if (blnErrorFound) {
							break;
						}
					}
					if (blnErrorFound) {
						Configuration_Settings__c objConfig = Configuration_Settings__c.getOrgDefaults();
						Integer intGfLeadReprocessingLimit = objConfig?.GF_Lead_Reprocessing_Limit__c?.intValue() != null ? objConfig.GF_Lead_Reprocessing_Limit__c.intValue() : 5;

						if (gfLead.Reprocess_Counter__c < intGfLeadReprocessingLimit) {
							// increment Reprocess Counter if Duplicate records are reprocessed within limit.
							gfLead.Reprocess_Counter__c += 1;
						} else {
							// Duplicate Records are backlogged after a Config limit times of reprocessing.
							setProcessingState(IntegrationUtils.BACKLOG, gfLead.Message__c, gfLead);
						}
					}
				}
			} else {
				setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Email is blank.', gfLead);
			}
		}

		//throw new BaseException('test');
	}

	public static Contact getContactInfoForUpdate(Contact c, String reason) {
		Boolean oppCreatedLast7Days = false;
		Boolean nonEEContractorExists = false;
		Boolean unworkableOppExists = false;
		Boolean activityExists = false;
		Boolean openOrderExists = false;
		Boolean AccountLastLogingIn30Days = false;
		Boolean blnIsClosedWonOpp = false;
		Boolean blnContactCreatedLast30Days = false;
		Boolean blnAccountHasFutureTask = false;
		Boolean bln_IsCohortDateBlank = true;

		for (ZP_User_Role__c zpUserRole : c.ZP_User_Roles__r) {
			nonEEContractorExists = true;
			break;
		}

		/* Checking if Contact created in last 30 days */
		if (c.CreatedDate >= (System.today() - 30)) {
			blnContactCreatedLast30Days = true;
		}

		if (c.opportunities != null && c.opportunities.size() > 0) {
			for (Opportunity opp : c.Opportunities) {
				String stageDetail = '';
				if (String.isNotEmpty(opp.Stage_Detail__c)) {
					stageDetail = opp.Stage_Detail__c.toLowerCase();
				}
				if (stageDetail == 'international' || stageDetail == 'gusto unable to serve' || stageDetail == 'unworkable opportunity' || stageDetail.indexOf('unqualified') > -1) {
					unworkableOppExists = true;
				}
				if (opp.CreatedDate >= (System.today() - 7)) {
					oppCreatedLast7Days = true;
				}
				if (String.isNotEmpty(Opp.Order__r.Status)) {
					if (Opp.Order__r.Status != 'Closed: Payroll Run' && Opp.Order__r.Status != 'Closed: Canceled' && Opp.Order__r.Status != 'Rejected') {
						openOrderExists = true;
					}
				}
				/* Checking if Contact is associated with Closed Won opportunity */
				if (opp.IsClosed == true && opp.IsWon == true) {
					blnIsClosedWonOpp = true;
				}
			}
		}
		if (
			c.Account.Last_Login_Time__c != null &&
			((c.Account.RecordType.name == 'Company' && c.Account.Last_Login_Time__c >= (System.today() - 30)) ||
			(c.Account.RecordType.name == 'Reseller' &&
			c.Account.Last_Login_Time__c >= (System.today() - 60)))
		) {
			AccountLastLogingIn30Days = true;
		}

		/* Checking if Account cohort date empty for partner Contacts*/
		if (c.Account.RecordType.name == 'Reseller' && c.Account.Cohort_Date__c != null)
			bln_IsCohortDateBlank = false;

		/* 06.24.2020 - Sean DesMarteau - Modified to a for loop as an Aggregate Query issue was
		 occuring for contacts with more than 200 Tasks */
		for (Task task : c.tasks) {
			Date activityDate = task.ActivityDate;
			if (c.Account.RecordType.name == 'Company' && activityDate >= (system.today() - 30)) {
				activityExists = true;
			} else if (c.Account.RecordType.name == 'Reseller' && activityDate >= (system.today() - 60)) {
				activityExists = true;
			}
			break;
		}
		List<Task> list_AccountTasks = new List<Task>();
		//Yuvraj  04-08-2020 Contains key check to resolve null pointer error in Zp user role test class.
		if (map_AccountIdToTasks.containsKey(c.AccountId))
			list_AccountTasks = map_AccountIdToTasks.get(c.AccountId);

		if (list_AccountTasks.size() > 0) {
			for (Task task : list_accountTasks) {
				Date accActivityDate = task.ActivityDate;
				if (accActivityDate >= (system.today() + 10)) {
					blnAccountHasFutureTask = true;
				}
			}
		}
		if (
			c.Lead_status__c != 'Unqualified' &&
			c.Lead_status__c != 'MQL' &&
			c.Phone != null &&
			c.Email != null &&
			c.account.Joined_Date_Panda__c == null &&
			nonEEContractorExists == true &&
			unworkableOppExists == false &&
			oppCreatedLast7Days == false &&
			activityExists == false &&
			openOrderExists == false &&
			AccountLastLogingIn30Days == false &&
			blnIsClosedWonOpp == false &&
			blnContactCreatedLast30Days == false &&
			blnAccountHasFutureTask == false &&
			bln_IsCohortDateBlank == true
		) {
			c.lead_status__c = 'MQL';
			c.MQL_Date__c = system.today();
			c.MQL_Reason__c = reason;
		}

		return c;
	}

	private void setExistingAccontantEmailMap(set<String> accountantEmailIdSet, set<String> externalPracticeIdSet) {
		set<Id> ownerId = new Set<Id>();
		for (Lead l : [
			SELECT
				Id,
				OwnerId,
				Status,
				MQL_Date__c,
				RecordType.Name,
				isConverted,
				email,
				External_Practice_Id__c,
				Company,
				External_Accountant_Email__c,
				RecordTypeId,
				FirstName,
				LastName,
				NumberOfEmployees,
				Phone,
				Pricing__c,
				Lead_States__c,
				Company_Invite_Token__c,
				ZP_Company_Lead_ID__c,
				Referred_By__c,
				ZP_Lead_Created_At_Date__c,
				Corp_Signup_Interest__c,
				ZP_Lead_Promo__c,
				ZP_Lead_Campaign__c,
				LeadSource,
				Referral_Token__c,
				HI_Deductions__c,
				HI_Interest__c,
				Landing_Page__c,
				Trk_creative__c,
				adgroup__c,
				msclkid__c,
				Trk_UTM_Content__c,
				Trk_UTM_Medium__c,
				Trk_Placement__c,
				Trk_network__c,
				Trk_matchtype__c,
				Trk_Keyword__c,
				Trk_gclid__c,
				Trk_Device__c,
				Partner_Program_Request_Create_Date__c,
				No_Firm_Employees__c,
				Sold_By__c,
				Has_paid_W_2_or_1099_elsewhere__c,
				Contractor_Only__c,
				Ramp_Intent__c,
				Payroll_Relationship__c,
				No_of_Clients_Bucket__c,
				No_of_Clients__c,
				No_Clients_Payroll__c,
				HI_Signup__c,
				Visitor_Id__c,
				Session_Id__c,
				ZP_Firm_ID__c,
				Submitted_From__c,
				URL_of_Conversion__c
			FROM Lead
			WHERE External_Accountant_Email__c IN :accountantEmailIdSet OR EMAIL IN :accountantEmailIdSet OR External_Practice_Id__c IN :externalPracticeIdSet
		]) {
			if (l.RecordType.Name == 'Company' && !accountantEmailIdSet.contains(l.email)) {
				accountantCompanyLeadMap.put(l.External_Accountant_Email__c, l);
			} else if (l.RecordType.Name == 'Reseller' && accountantEmailIdSet.contains(l.email)) {
				accountantResellerLeadMap.put(l.email, l);
			}
			if (externalPracticeIdSet.contains(l.External_Practice_Id__c)) {
				practiceIDLeadMap.put(l.External_Practice_Id__c, l);
			}
			ownerId.add(l.OwnerId);
		}
		for (Contact contact : [
			SELECT
				Id,
				External_Accountant_Email__c,
				OwnerId,
				AccountId,
				Account.Name,
				Account.RecordTypeId,
				Account.RecordType.Name,
				Normalized_Email_Domain__c,
				Normalized_Alternate_Email_Domain__c,
				FirstName,
				LastName
			FROM Contact
			WHERE External_Accountant_Email__c IN :accountantEmailIdSet
		]) {
			if (contact.AccountId != null) {
				accountantContactMap.put(contact.External_Accountant_Email__c, contact);
				ownerId.add(contact.OwnerId);
			}
		}
		//get user role for owner for which accountant email is found
		if (!ownerId.isEmpty()) {
			for (User objUser : [SELECT Id, UserRole.Name FROM User WHERE Id IN :ownerId AND UserRole.Name = :AccountUtil.SALES_PARTNER_AE_ROLE]) {
				salesPartnerXeroRole.put(objUser.id, objUser);
			}
		}
	}

	private void setExistingEmailLeadMap(Set<String> emailIdSet) {
		for (Lead l : [
			SELECT
				Id,
				OwnerId,
				RecordType.Name,
				isConverted,
				Company,
				Email,
				RecordTypeId,
				FirstName,
				LastName,
				NumberOfEmployees,
				Phone,
				Pricing__c,
				Lead_States__c,
				Company_Invite_Token__c,
				ZP_Company_Lead_ID__c,
				Referred_By__c,
				ZP_Lead_Created_At_Date__c,
				Status,
				GF_Lead_Last_Updated_Date_Time__c,
				Corp_Signup_Interest__c,
				ZP_Lead_Promo__c,
				ZP_Lead_Campaign__c,
				LeadSource,
				Referral_Token__c,
				HI_Deductions__c,
				HI_Interest__c,
				Landing_Page__c,
				Trk_creative__c,
				adgroup__c,
				MQL_Date__c,
				msclkid__c,
				Trk_UTM_Content__c,
				Trk_UTM_Medium__c,
				Trk_Placement__c,
				Trk_network__c,
				Trk_matchtype__c,
				Trk_Keyword__c,
				Trk_gclid__c,
				Trk_Device__c,
				Partner_Program_Request_Create_Date__c,
				No_Firm_Employees__c,
				Sold_By__c,
				Has_paid_W_2_or_1099_elsewhere__c,
				Contractor_Only__c,
				Ramp_Intent__c,
				Payroll_Relationship__c,
				No_of_Clients_Bucket__c,
				No_of_Clients__c,
				No_Clients_Payroll__c,
				HI_Signup__c,
				Visitor_Id__c,
				Session_Id__c,
				ZP_Firm_ID__c,
				Growth_Experiments_when_lead_created__c,
				URL_of_Conversion__c,
				Submitted_From__c,
				System_Of_Origin__c,
				External_Accountant_Email__c,
				External_Accountant_Name__c,
				External_Practice_Id__c,
				MQL_DateTime__c,
				Onboarding_Flow__c,
				Referral_Type__c,
				Lead_Creation_Offer__c,
				CreatedDate,
				Website,
				Lead_Type__c,
				ConvertedAccountId__c,
				ZP_Company_ID__c,
				ZP_Accountant_Lead_ID__c
			FROM Lead
			WHERE Email IN :emailIdSet
		]) {
			if (l.RecordType.Name == 'Company') {
				companyLeadMap.put(l.Email, l);
			} else if (l.RecordType.Name == 'Reseller') {
				resellerLeadMap.put(l.Email, l);
			}
		}
	}

	private void setExistingEmailContactMap(Set<String> emailIdSet) {
		for (Contact contact : [
			SELECT
				Id,
				email,
				OwnerId,
				AccountId,
				Account.Name,
				Account.RecordTypeId,
				Account.RecordType.Name,
				Account.ZP_Company_id__c,
				Account.ZP_Firm_id__c,
				Account.Cohort_Date__c,
				Normalized_Email_Domain__c,
				Normalized_Alternate_Email_Domain__c,
				FirstName,
				LastName,
				Phone,
				Lead_Status__c,
				Account.Joined_Date_Panda__c,
				Account.Last_Login_Time__c,
				CreatedDate,
				(
					SELECT Id, StageName, CreatedDate, Account.Last_Activity_Date__c, Order__r.Status, Isclosed, Order__c, Stage_Detail__c, IsWon, ContactId
					FROM Opportunities
					WHERE RecordTypeId = :OpportunityUtil.COMPANY_OPPTY_RT_ID OR RecordTypeId = :OpportunityUtil.ACQUISITION_OPPTY_RT_ID
				),
				(SELECT Id, Owner_Role_Formula__c, Status, Type, ActivityDate FROM Tasks WHERE Owner_Role_Formula__c LIKE 'sales%' AND ActivityDate >= LAST_N_DAYS:60 ORDER BY ActivityDate DESC),
				(SELECT Id, Type__c FROM ZP_user_roles__r WHERE Type__c NOT IN ('Role::Employee', 'Role::Contractor') LIMIT 1)
			FROM Contact
			WHERE Email IN :emailIdSet
		]) {
			if (contact.AccountId != null && contact.Account.RecordType.Name == 'Reseller') {
				resellerContactMap.put(contact.Email, contact);
			} else if (contact.AccountId != null && contact.Account.RecordType.Name == 'Company') {
				companyContactMap.put(contact.Email, contact);
			}
		}
	}

	public void queryAccounts(Set<String> set_CompanyIds, Set<String> set_FirmIds) {
		for (Account acc : [
			SELECT
				Id,
				Name,
				ZP_Company_ID__c,
				ZP_Company_Overall_Status__c,
				ZP_Company_Suspension_Date__c,
				ZP_Firm_ID__c,
				RecordTypeId,
				(
					SELECT Id, StageName, CreatedDate, Account.Last_Activity_Date__c, Order__r.Status, isclosed, Order__c, Stage_Detail__c
					FROM Opportunities
					WHERE (RecordTypeId = :OpportunityUtil.COMPANY_OPPTY_RT_ID OR RecordTypeId = :OpportunityUtil.ACQUISITION_OPPTY_RT_ID) AND Account.RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID
				)
			FROM Account
			WHERE
				(ZP_Company_ID__c IN :set_CompanyIds
				AND (RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID
				OR RecordTypeId = :AccountUtil.EMBEDDED_COMPANY_ACCOUNT_RT_ID))
				OR (ZP_Firm_ID__c IN :set_FirmIds
				AND RecordTypeId = :AccountUtil.RESELLER_ACCOUNT_RT_ID)
		]) {
			if (
				String.isNotBlank(acc.ZP_Company_ID__c) &&
				set_CompanyIds.contains(acc.ZP_Company_ID__c) &&
				(acc.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID ||
				acc.RecordTypeId == AccountUtil.EMBEDDED_COMPANY_ACCOUNT_RT_ID)
			) {
				map_Companies.put('' + acc.ZP_Company_ID__c, acc);
			} else if (String.isNotBlank(acc.ZP_Firm_ID__c) && set_FirmIds.contains(acc.ZP_Firm_ID__c) && acc.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID) {
				map_Firms.put('' + acc.ZP_Firm_ID__c, acc);
			}
		}
	}

	/* Created by : Chandrika
	 * Date : 06-07-2020
	 * Desc: To get the list of Tasks for the Contact's Account
	 * Asana Ticket : https://app.asana.com/0/1174111890866041/1180433268652226
	 */
	public void setAccountIdToTasksMap(Set<String> set_ContactAccountId) {
		if (map_AccountIdToTasks == null) {
			map_AccountIdToTasks = new Map<String, List<Task>>();
		}

		for (Task task : [SELECT Id, ActivityDate, WhatId FROM Task WHERE WhatId IN :set_ContactAccountId]) {
			List<Task> list_AccountTasks = map_AccountIdToTasks.get(task.WhatId);

			if (list_AccountTasks == null)
				list_AccountTasks = new List<Task>();

			list_AccountTasks.add(task);
			map_AccountIdToTasks.put(task.WhatId, list_AccountTasks);
		}
	}

	private GF_Lead__c setProcessingState(String state, String message, GF_Lead__c lead) {
		lead.Processing_State__c = state;
		lead.Message__c = message.left(255);
		lead.Last_Processed__c = System.now();
		return lead;
	}

	/** New method that stamps value on Lead irrespective of Lead's conversion statis */
	private Lead setCommonFieldsOnLead(GF_Lead__c gfLead, Lead l) {
		// Set ZP_Lead_Campaign on Lead is set only when it is blank.
		if (String.isNotBlank(gfLead.Campaign__c) && (String.isBlank(l.ZP_Lead_Campaign__c) || l.ZP_Lead_Campaign__c.equalsIgnoreCase(LeadUtil.LABEL_LEAD_CAMP_OTHER))) {
			l.ZP_Lead_Campaign__c = gfLead.Campaign__c;
		}

		if ((String.isBlank(l.LeadSource) || l.LeadSource == 'Sourcing Error' || l.LeadSource == 'Outbound') && String.isNotBlank(gfLead.Source__c)) {
			l.LeadSource = gfLead.Source__c;
		}

		// Check if overwrite happens within one hour of Lead Creation
		if ((l.LeadSource == 'Inbound Phone' || l.LeadSource == 'Inbound Chat' || l.LeadSource == 'Direct') && String.isNotBlank(gfLead.Source__c) && System.now() > l.CreatedDate) {
			// Find difference in hours between current time and lead created time
			Long intHours = (System.now().getTime() - l.CreatedDate.getTime()) / 1000 / 60 / 60;
			if (intHours <= 1)
				l.LeadSource = gfLead.Source__c;
		}

		if (String.isNotBlank(gfLead.Visitor_Id__c) && String.isBlank(l.Visitor_Id__c)) {
			l.Visitor_Id__c = gfLead.Visitor_Id__c;
		}

		if (gfLead.Session_Id__c != null && gfLead.Session_Id__c != '') {
			l.Session_Id__c = gfLead.Session_Id__c;
		}
		if (l.GF_Lead_Last_Updated_Date_Time__c == null || l.GF_Lead_Last_Updated_Date_Time__c < gfLead.Updated_At__c) {
			l.GF_Lead_Last_Updated_Date_Time__c = gfLead.Updated_At__c;
		}

		if (l.Referral_Token__c == null || l.Referral_Token__c == '' && gfLead.Referral_Token__c != null && gfLead.Referral_Token__c != '') {
			l.Referral_Token__c = gfLead.Referral_Token__c;
		}

		setLeadReferralType(gfLead, l);

		if (String.isBlank(l.Email) && String.isNotBlank(gfLead.Email__c)) {
			l.Email = gfLead.Email__c;
		}

		if (String.isBlank(l.FirstName) || l.FirstName == 'N/A' || l.FirstName.equalsIgnoreCase('na')) {
			if (String.isNotBlank(gfLead.First_Name__c) && gfLead.First_Name__c.length() > 40)
				l.FirstName = gfLead.First_Name__c.substring(0, 40);
			else
				l.FirstName = gfLead.First_Name__c;
		}

		if (String.isBlank(l.LastName) || l.LastName == 'N/A') {
			l.LastName = gfLead.Last_Name__c;
		}

		if (String.isBlank(l.ZP_Company_Lead_ID__c) && String.isNotBlank(gfLead.ZP_Legacy_Lead_ID__c) && gfLead.Lead_Type__c == 'Company') {
			l.ZP_Company_Lead_ID__c = gfLead.ZP_Legacy_Lead_ID__c;
		}

		if (String.isNotBlank(l.Referral_Type__c)) {
			if (l.Referral_Type__c.equalsIgnoreCase('user')) {
				l.Lead_Creation_Offer__c = 'Customer Referral';
			} else if (l.Referral_Type__c.equalsIgnoreCase('UserRole')) {
				l.Lead_Creation_Offer__c = 'Partner Referral';
			} else if (l.Referral_Type__c.equalsIgnoreCase('PartnerReferralUser')) {
				l.Lead_Creation_Offer__c = 'Partner to Partner Referral';
			}
		}

		if (String.isBlank(l.HI_Deductions__c) && String.isNotBlank(gfLead.HI_Deductions__c))
			l.HI_Deductions__c = gfLead.HI_Deductions__c;

		if (String.isBlank(l.Phone) && String.isNotBlank(gfLead.Phone__c)) {
			l.Phone = gfLead.Phone__c;
		}

		if (String.isBlank(l.URL_of_Conversion__c) && String.isNotBlank(gfLead.URL_of_Conversion__c))
			l.URL_of_Conversion__c = gfLead.URL_of_Conversion__c;

		if (String.isBlank(l.Website) && String.isNotBlank(gfLead.Website__c))
			l.Website = gfLead.Website__c;

		if (String.isBlank(l.No_of_Clients_Bucket__c) && String.isNotBlank(gfLead.No_of_Clients_Bucket__c))
			l.No_of_Clients_Bucket__c = gfLead.No_of_Clients_Bucket__c;

		if (l.No_of_Clients__c == null) {
			if (gfLead.No_Of_Clients__c != null && gfLead.No_of_Clients_Bucket__c == null) {
				l.No_of_Clients__c = Integer.valueOf(gfLead.No_Of_Clients__c);
			}
		}

		if (l.No_Clients_Payroll__c == null) {
			l.No_Clients_Payroll__c = Integer.valueOf(gfLead.No_Clients_Payroll__c);
		}

		if (l.Referred_By__c == null && map_Firms.containsKey(gfLead.Referred_By_Accounting_Firm_Id__c)) {
			l.Referred_By__c = map_Firms.get(gfLead.Referred_By_Accounting_Firm_Id__c).Id;
		}

		if (l.Ramp_Intent__c == false) {
			l.Ramp_Intent__c = gfLead.Ramp_Intent__c;
		}

		if (l.Partner_Program_Request_Create_Date__c == null) {
			l.Partner_Program_Request_Create_Date__c = gfLead.Partner_Program_Request_Create_Date__c;
		}

		if (gfLead.Lead_Rating__c != null) {
			l.Lead_Rating__c = gfLead.Lead_Rating__c;

			if (l.IsConverted) {
				Account objAcc = map_AccountsUpdate.containsKey(l.ConvertedAccountId__c)
					? map_AccountsUpdate.get(l.ConvertedAccountId__c)
					: map_Companies.containsKey(l.ZP_Company_Id__c) ? map_Companies.get(l.ZP_Company_Id__c) : null;

				if (objAcc != null) {
					objAcc.Lead_Rating_Account__c = gfLead.Lead_Rating__c;
					map_AccountsUpdate.put(objAcc.Id, objAcc);
				}
			}
		}

		l.Potential_Fraud_Lead__c = gfLead.Potential_Fraud__c;

		if (gfLead.Lead_Type__c == 'Accountant' && gfLead.Number_Of_Employees__c != null && (l.No_Firm_Employees__c == null || l.No_Firm_Employees__c == '')) {
			l.No_Firm_Employees__c = '' + Integer.valueof(gfLead.Number_Of_Employees__c);
		}

		return l;
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Sets Referral Type on Lead
	 * @Parm        : gfLead - GF Lead record
	 * @Parm        : l - Lead record
	 * @Return      : N/A
	 **/
	public void setLeadReferralType(GF_Lead__c gfLead, Lead l) {
		if ((gfLead.Lead_Type__c == 'Company' && l.RecordTypeId == LeadUtil.COMPANY_LEAD_RT_ID) || (gfLead.Lead_Type__c == 'Accountant' && l.RecordTypeId == LeadUtil.RESELLER_LEAD_RT_ID)) {
			if ((String.isBlank(l.Referral_Type__c) || l.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_US)) && String.isNotBlank(gfLead.Referral_Type__c)) {
				l.Referral_Type__c = gfLead.Referral_Type__c;
			}
		}
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Filters list of GF Leads and removes Fraudulent records
	 * @Parm        : List<GF_Lead__c> - Unfiltered List
	 * @Return      : List<GF_Lead__c> - Filtered List
	 **/
	public List<GF_Lead__c> returnRecordsToProcess(List<GF_Lead__c> list_GFLeads) {
		// List to contain filtered list of GF Leads to Process
		List<GF_Lead__c> list_GFLeadsToProcess = new List<GF_Lead__c>();
		Set<String> set_FraudEmails = new Set<String>();

		// Fetch all fraudulent email domains from custom metadata
		Map<String, Fraud_Settings__mdt> map_FraudSettings = Fraud_Settings__mdt.getAll();
		for (String strKey : map_FraudSettings.keySet()) {
			set_FraudEmails.add(map_FraudSettings.get(strKey).Email_Domain__c);
		}

		for (GF_Lead__c gfLead : list_GFLeads) {
			if (String.isNotBlank(gfLead.Email__c)) {
				gfLead.Email__c = gfLead.Email__c.toLowerCase();
			}
			gfLead.Processing_State__c = IntegrationUtils.QUEUED_STATE;

			if (String.isNotBlank(gfLead.Email__c) && gfLead.Email__c.length() > 80) {
				setProcessingStateAndMessage(gfLead, IntegrationUtils.DEAD_STATE, GFLeadUtil.ERR_MSG_EMAIL_TOO_LONG);
			}

			if (String.isNotBlank(gfLead.Last_Name__c) && gfLead.Last_Name__c.length() > GFLeadUtil.LIMIT_LAST_NAME_CHARACTERS) {
				gfLead.Last_Name__c = gfLead.Last_Name__c.substring(0, GFLeadUtil.LIMIT_LAST_NAME_CHARACTERS);
			}

			// Logic to remove fraudulent records and mark them as Dead
			for (String strFraudEmail : set_FraudEmails) {
				if (String.isNotBlank(gfLead.Email__c) && gfLead.Email__c.containsIgnoreCase(strFraudEmail)) {
					setProcessingStateAndMessage(gfLead, IntegrationUtils.DEAD_STATE, GFLeadUtil.ERR_MSG_FRAUDULENT_RECORD);
					break;
				}
			}
		}

		// Add anything record whose processing state is not Dead to list of GF Leads to Process
		for (GF_Lead__c gfLead : list_GFLeads) {
			if (gfLead.Processing_State__c != IntegrationUtils.DEAD_STATE) {
				list_GFLeadsToProcess.add(gfLead);
			}
		}

		// Return filtered list of records to process
		return list_GFLeadsToProcess;
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Set MQL Date & related fields
	 * @Parm        : objLead - Lead to be updated
	 * @Return      : NA
	 **/
	public void setMQLDate(Lead objLead) {
		objLead.MQL_Date__c = System.today();
		objLead.MQL_Flag__c = LeadUtil.MQL_FLAG_YES;
		objLead.MQL_DateTime__c = System.now();
	}

	/**
	 * @author      : Veeresh Kumar
	 * @description : Handles change in Processing_State__c & Message__c.
	 * @param       : objGFLead - New GFLead
	 * @return      : N/A
	 **/
	public void setProcessingStateAndMessage(GF_Lead__c objGFLead, String strProcessingState, String strMessage) {
		objGFLead.Processing_State__c = strProcessingState;
		objGFLead.Last_Processed__c = System.now();

		if (strProcessingState == IntegrationUtils.PROCESSED_STATE) {
			objGFLead.Message__c = strProcessingState;
		} else {
			objGFLead.Message__c = String.isNotBlank(objGFLead.Message__c) ? objGFLead.Message__c + ' - ' + strMessage : strMessage;
		}

		if (objGFLead.Message__c?.length() > 255) {
			objGFLead.Message__c = objGFLead.Message__c.substring(0, 255);
		}
	}
}