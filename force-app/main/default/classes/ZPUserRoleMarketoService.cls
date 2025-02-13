@RestResource(urlMapping='/ZPUserRole/Marketo/GetData/*')
global with sharing class ZPUserRoleMarketoService {
	@HttpGet
	global static List<UserRoleInfo> doGet() {
		List<UserRoleInfo> roleInfoList = new List<UserRoleInfo>();
		map<String, Set<String>> ppcdMap = new Map<String, Set<String>>();
		map<String, primaryAdminInfo> primaryUserRoleMap = new Map<String, primaryAdminInfo>();
		map<String, String> funnelDataMap = new Map<String, String>();
		Set<String> companyIdSet = new Set<String>();
		Set<String> firmIdSet = new Set<String>();
		List<ZP_User_Role__c> userRoleList = new List<ZP_User_Role__c>(
			[
				SELECT
					id,
					Id__c,
					Company_id__c,
					Accounting_firm_id__c,
					Deleted_at__c,
					role_name__c,
					Marketo_id__c,
					Company_Account__r.Name,
					Company_Account__r.States__c,
					Company_Account__r.Number_of_Active_Employees__c,
					Company_Account__r.Tier__c,
					Company_Account__r.ZP_Company_Overall_Status__c,
					Company_Account__r.Joined_Date_Panda__c,
					Company_Account__r.Benefits_Email_Opt_Out__c,
					Company_Account__r.Anchor_pay_date__c,
					Company_Account__r.BillingStateCode,
					Company_Account__r.NumberOfEmployees,
					Company_Account__r.Number_of_Won_Benefits_Opps__c,
					Company_Account__r.Active_Benefit_Types__c,
					Company_Account__r.Medical_Deduction_Types__c,
					Accounting_Firm_Account__r.Name,
					ZP_User__r.Email__c
				FROM ZP_User_Role__c
				WHERE
					Type__c = 'Role::PayrollAdmin'
					AND (Marketo_id__c != NULL
					OR (Accounting_Firm_Account__c != NULL
					AND company_account__c != NULL))
					AND (Marketo_Sync_Date__c = NULL
					OR Marketo_Sync_Date__c < TODAY)
				LIMIT :Integer.valueOf(Label.ZPUserRoleMarketoServiceLimit)
			]
		);

		for (ZP_User_Role__c role : userRoleList) {
			companyIdSet.add(role.Company_id__c);
			firmIdSet.add(role.Accounting_firm_id__c);
		}
		ppcdMap = getProgramDataMap(firmIdSet);
		primaryUserRoleMap = primaryUserRoleMap(companyIdSet);
		funnelDataMap = getFunnelDataMap(companyIdSet);
		for (ZP_User_Role__c role : userRoleList) {
			boolean isActive = false;
			if (role.Deleted_At__c == null) {
				isActive = true;
			}
			UserRoleInfo roleInfo = new UserRoleInfo();
			roleInfo.id = role.id;
			roleInfo.user_role_id = role.Id__c;
			roleInfo.client_no_of_benefit_opportunities = (Integer) role.Company_Account__r.Number_of_Won_Benefits_Opps__c;
			roleInfo.client_no_of_employees = 0;
			if (role.Company_Account__r.NumberOfEmployees != null) {
				roleInfo.client_no_of_employees = (Integer) role.Company_Account__r.NumberOfEmployees;
			}
			roleInfo.client_product_tier = role.Company_Account__r.Tier__c;
			//roleInfo.no_of_clients_managed=null;
			if (ppcdMap.containsKey(role.Company_id__c)) {
				roleInfo.no_of_clients_managed = ppcdMap.get(role.Company_id__c).size();
			}
			roleInfo.no_of_eligible_clients_managed = null;
			roleInfo.accountant_active = isActive;
			roleInfo.client_apd = role.Company_Account__r.Anchor_pay_date__c;
			String benefitTypes = '';
			if (role.Company_Account__r.Active_Benefit_Types__c != null) {
				benefitTypes = role.Company_Account__r.Active_Benefit_Types__c;
			}
			if (role.Company_Account__r.Medical_Deduction_Types__c != null) {
				if (benefitTypes != '') {
					benefitTypes += ';';
				}
				benefitTypes = role.Company_Account__r.Medical_Deduction_Types__c;
			}
			roleInfo.client_benefits_adoption = benefitTypes;

			roleInfo.client_company_name = role.Company_Account__r.Name;
			roleInfo.client_company_setup_step = null;
			if (funnelDataMap.containsKey(role.Company_id__c)) {
				roleInfo.client_company_setup_step = funnelDataMap.get(role.Company_id__c);
			}
			roleInfo.client_company_state = role.Company_Account__r.BillingStateCode;
			roleInfo.client_is_benefits_opt_out = role.Company_Account__r.Benefits_Email_Opt_Out__c;
			roleInfo.client_company_overall_status = role.Company_Account__r.ZP_Company_Overall_Status__c;
			roleInfo.client_joined_date = role.Company_Account__r.Joined_Date_Panda__c;
			roleInfo.client_primary_contact = null;
			roleInfo.client_primary_contact_email = null;
			if (primaryUserRoleMap.containsKey(role.Company_id__c)) {
				roleInfo.client_primary_contact = primaryUserRoleMap.get(role.Company_id__c).userName;
				roleInfo.client_primary_contact_email = primaryUserRoleMap.get(role.Company_id__c).email;
			}
			roleInfo.email = role.ZP_User__r.Email__c;
			roleInfo.managed_client = null;
			roleInfo.client_company_id = role.Company_id__c; // ZP User Role : Company_id__c
			roleInfo.accounting_firm_id = role.Accounting_firm_id__c; // ZP User Role : Accounting_firm_id__c
			roleInfo.accounting_firm_name = role.Accounting_Firm_Account__r.Name; // Accounting Firm Account : Name
			roleInfo.role_inactive = isActive;
			roleInfo.role_name = role.role_name__c;
			roleInfo.marketo_id = role.Marketo_id__c;
			roleInfoList.add(roleInfo);
		}
		return roleInfoList;
	}

	private static map<String, Set<String>> getProgramDataMap(Set<String> firmIdSet) {
		map<String, Set<String>> programDataMap = new Map<String, Set<String>>();
		for (ZP_Company__c objCompany : [
			SELECT Id, Id__c, Managing_Accounting_Firm_Id__c
			FROM ZP_Company__c
			WHERE Deleted_at__c = NULL AND Managing_Accounting_Firm_Id__c IN :firmIdSet AND Managing_Accounting_Firm_Id__c != NULL
		]) {
			Set<String> companyIdSet = new Set<String>();
			if (programDataMap.containsKey(objCompany.Id__c)) {
				companyIdSet = programDataMap.get(objCompany.Id__c);
			}
			companyIdSet.add(objCompany.Id__c);
			programDataMap.put(objCompany.Managing_Accounting_Firm_Id__c, companyIdSet);
		}

		return programDataMap;
	}

	private static map<String, String> getFunnelDataMap(Set<String> companyIdSet) {
		map<String, String> funnelDataMap = new Map<String, String>();
		for (ZP_Company_Onboarding_Funnel__c zpof : [
			SELECT Id, Company_Id__c, Sign__c
			FROM ZP_Company_Onboarding_Funnel__c
			WHERE Deleted_at__c = NULL AND Company_Id__c IN :companyIdSet AND Company_Id__c != NULL
		]) {
			funnelDataMap.put(zpof.Company_Id__c, zpof.Sign__c);
		}

		return funnelDataMap;
	}

	@HttpPost
	global static void doPost(List<userRoleUpdateInfo> updateInfoList) {
		if (updateInfoList.size() > 0) {
			List<ZP_User_Role__c> uroleList = new List<ZP_User_Role__c>();
			for (userRoleUpdateInfo info : updateInfoList) {
				ZP_User_Role__c role = new ZP_User_Role__c(Id = info.id, Marketo_id__c = info.marketo_id);
				role.Marketo_Sync_Date__c = system.today();
				uroleList.add(role);
			}
			ZPUserRoleTriggerHelper.skipTrigger = true;
			update uroleList;
		}
	}

	private static map<String, primaryAdminInfo> primaryUserRoleMap(Set<String> companyIdSet) {
		map<String, primaryAdminInfo> adminInfoMap = new Map<String, primaryAdminInfo>();
		for (ZP_User_Role__c role : [
			SELECT User_Id__c, Company_Id__c, First_Name__c, Last_Name__c, ZP_User__r.Email__c
			FROM ZP_User_Role__c
			WHERE Company_Id__c IN :companyIdSet AND Company_Id__c != NULL AND Type__c = 'Role::PayrollAdmin' AND Is_Primary__c = TRUE AND Deleted_at__c = NULL
		]) {
			primaryAdminInfo info = new primaryAdminInfo();
			info.userId = role.User_Id__c;
			info.userName = role.First_Name__c + ' ' + role.Last_Name__c;
			info.email = role.ZP_User__r.Email__c;
			adminInfoMap.put(role.Company_Id__c, info);
		}

		return adminInfoMap;
	}

	global class primaryAdminInfo {
		global String userId;
		global String userName;
		global String email;
	}

	global class userRoleUpdateInfo {
		global String id;
		global String marketo_id;
	}

	global class UserRoleInfo {
		global String id; // ZP User Role : Id
		global String user_role_id; // ZP User Role : Id__c
		global Integer client_no_of_benefit_opportunities;
		global Integer client_no_of_employees; // Company Account: Number_of_Active_Employees__c
		global String client_product_tier; // Company Account: Tier__c
		global Integer no_of_clients_managed;
		global Integer no_of_eligible_clients_managed;
		global boolean accountant_active; // ZP User Role : Deleted_at__c = null
		global date client_apd;
		global string client_benefits_adoption;
		global string client_company_name; // Company Account: Name
		global string client_company_setup_step;
		global string client_company_state; // Company Account: States__c
		global string client_is_benefits_opt_out;
		global string client_company_overall_status; // Company Account: ZP_Company_Overall_Status__c
		global date client_joined_date; // Company Account: Joined_Date_Panda__c
		global string client_primary_contact;
		global string client_primary_contact_email;
		global string email;
		global boolean managed_client;
		global string client_company_id; // ZP User Role : Company_id__c
		global string accounting_firm_id; // ZP User Role : Accounting_firm_id__c
		global string accounting_firm_name; // Accounting Firm Account : Name
		global boolean role_inactive;
		global string role_name;
		global string marketo_id;
	}
}