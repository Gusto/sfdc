public without sharing class HIBenefitsUtil {
	//final variables
	public final static Id COMPANY_ACCOUNT_RT_ID = Cache.getRecordTypeId('Account', 'Company');
	public final static String COMPANY_ID_NULL = 'CompanyId is null';
	public final static String COMPANY_DOES_NOT_EXIST = 'Company does not exist';
	public final static String USER_ID_NULL = 'UserId is null';
	public final static String ZPUSER_DOES_NOT_EXIST = 'ZPUser record does not exist.';
	public final static String ZPUSERROLE_DOES_NOT_EXIST = 'ZPUserRole record does not exist.';
	public final static String ZPUSERROLE_GUSTO_DOES_NOT_EXIST = 'ZPUserRole record does not exist and Email is Gusto.';
	public final static String ZPUSER_DOES_NOT_HAVE_EMAIL = 'UserId record does not have an email';
	public final static String BENEFIT_ADMIN = 'Benefits Admin';
	public final static String BENEFIT_SIGNATORY = 'Benefits Signatory';
	public final static String PROCESSED_MESSAGE = 'Processed';
	public final static String CHANGE_OPPORTUNITY_RT_ID = 'Benefits Change';
	public final static String NEW_PLAN_OPPORTUNITY_RT_ID = 'Benefits New Plan';
	public final static String RENEWAL_OPPORTUNITY_RT_ID = 'Benefits Renewal';
	public final static String BOR_OPPORTUNITY_RT_ID = 'Benefits BoR';
	public final static String BYOB_OPPORTUNITY_RT_ID = 'Benefits BYOB';

	public static map<String, Contact> getContacts(Set<String> set_EmailId, Set<String> set_ZpUserIds) {
		map<String, Contact> map_Contact = new Map<String, Contact>();

		for (Contact objContact : [
			SELECT Id, Name, Email, FirstName, LastName, ZP_User_Id__c
			FROM Contact
			WHERE (Email != NULL AND Email IN :set_EmailId) OR (ZP_User_Id__c != NULL AND ZP_User_Id__c IN :set_ZpUserIds)
		]) {
			map_Contact.put(objContact.Email, objContact);
			map_Contact.put(objContact.ZP_User_Id__c, objContact);
		}

		return map_Contact;
	}

	public static map<String, ZP_User_Role__c> getZPUserRoles(Set<String> set_UserId) {
		map<String, ZP_User_Role__c> map_ZPUserRole = new Map<String, ZP_User_Role__c>();

		if (!set_UserId.isEmpty()) {
			for (ZP_User_Role__c objZPUserRole : [SELECT Id, Company_Id__c, Id__c, First_Name__c, Last_Name__c, Type__c, User_Id__c FROM ZP_User_Role__c WHERE User_Id__c IN :set_UserId]) {
				map_ZPUserRole.put('' + objZPUserRole.User_Id__c, objZPUserRole);
			}
		}
		return map_ZPUserRole;
	}

	public static map<String, OpportunityContactRole> getOpportunityContactRelations(Set<String> set_EmailId, Map<Id, List<Opportunity>> map_AccountOpportunities, String strOppContactRole) {
		Map<String, OpportunityContactRole> map_OppContactRelation = new Map<String, OpportunityContactRole>();
		Set<Id> set_OppIds = new Set<Id>();
		if (!map_AccountOpportunities.isEmpty()) {
			for (Id objAccount : map_AccountOpportunities.keySet()) {
				for (Opportunity objOpp : map_AccountOpportunities.get(objAccount)) {
					if (objOpp.IsClosed == false) {
						set_OppIds.add(objOpp.Id);
					}
				}
			}
		}
		if (!set_OppIds.isEmpty() && !set_EmailId.isEmpty()) {
			for (OpportunityContactRole objContactRelation : [
				SELECT Id, OpportunityId, ContactId, Role, IsPrimary, Check_Additional_POC__c
				FROM OpportunityContactRole
				WHERE Contact.email IN :set_EmailId AND OpportunityId IN :set_OppIds AND Role = :strOppContactRole
			]) {
				map_OppContactRelation.put(objContactRelation.OpportunityId + '-' + objContactRelation.ContactId, objContactRelation);
			}
		}

		return map_OppContactRelation;
	}
	public static map<String, ZP_User__c> getZPUsers(Set<String> set_UserId) {
		map<String, ZP_User__c> map_ZPUser = new Map<String, ZP_User__c>();

		if (!set_UserId.isEmpty()) {
			for (ZP_User__c objZPUser : [SELECT Id, email__c, Id__c FROM ZP_User__c WHERE Id__c IN :set_UserId]) {
				map_ZPUser.put('' + objZPUser.Id__c, objZPUser);
			}
		}

		return map_ZPUser;
	}
	public static map<String, Account> getAccountInformation(Set<String> set_CompanyId) {
		map<String, Account> map_Account = new Map<String, Account>();
		if (!set_CompanyId.isEmpty()) {
			for (Account objAcc : [
				SELECT Id, Name, ZP_Company_ID__c, ZP_Company_Overall_Status__c, ZP_Company_Suspension_Date__c
				FROM Account
				WHERE ZP_Company_ID__c IN :set_CompanyId AND RecordTypeId = :HIBenefitsUtil.COMPANY_ACCOUNT_RT_ID
			]) {
				map_Account.put('' + objAcc.ZP_Company_ID__c, objAcc);
			}
		}
		return map_Account;
	}
	public static Map<Id, List<Opportunity>> getOpportunityIds(Set<String> set_CompanyId) {
		Map<Id, List<Opportunity>> map_AccountOpps = new Map<Id, List<Opportunity>>();
		List<Opportunity> list_Opportunities = new List<Opportunity>();
		Set<String> set_RecordType = new Set<String>{ CHANGE_OPPORTUNITY_RT_ID, NEW_PLAN_OPPORTUNITY_RT_ID, RENEWAL_OPPORTUNITY_RT_ID, BOR_OPPORTUNITY_RT_ID, BYOB_OPPORTUNITY_RT_ID };
		if (!set_CompanyId.isEmpty()) {
			for (Opportunity objOpp : [SELECT Id, AccountId, IsClosed FROM Opportunity WHERE RecordType.Name IN :set_RecordType AND Account.ZP_Company_ID__c IN :set_CompanyId]) {
				list_Opportunities = new List<Opportunity>();
				if (objOpp.AccountId != null) {
					if (!map_AccountOpps.isEmpty() && map_AccountOpps.containsKey(objOpp.AccountId)) {
						list_Opportunities = map_AccountOpps.get(objOpp.AccountId);
						list_Opportunities.add(objOpp);
					} else {
						list_Opportunities.add(objOpp);
					}
					map_AccountOpps.put(objOpp.AccountId, list_Opportunities);
				}
			}
		}
		return map_AccountOpps;
	}
}