public without sharing class ContactUserInformationController {
	public String userId { get; set; }
	public String email { get; set; }
	public String caseId { get; set; }
	public List<userRoleInfo> companyInfo { get; set; }
	public List<userRoleInfo> firmInfo { get; set; }
	public String company_FirmId { get; set; }
	public Map<String, userRoleInfo> companyUserRoleMap { get; set; }
	public Map<String, userRoleInfo> firmUserRoleMap { get; set; }

	public userRoleInformation getUserInformation() {
		companyInfo = new List<userRoleInfo>();
		firmInfo = new List<userRoleInfo>();
		Set<String> companySet = new Set<String>();
		Set<String> accountantSet = new Set<String>();
		ZP_User__c user = new ZP_User__c();
		if (userId == '' && String.isNotBlank(email)) {
			user = [SELECT Id, Email__c, Deleted_At__c FROM ZP_User__c WHERE Email__c != NULL AND Email__c = :email];
		}
		//map<String,userRoleInfo> companyUserRoleMap = new map<String,userRoleInfo>();
		//map<String,userRoleInfo> firmUserRoleMap = new map<String,userRoleInfo>();

		// SJay - 03/23/2020 - Added the maps to userRoleInformation class
		//Jira: BT-7264 - Collection size issue when opening email case
		companyUserRoleMap = new Map<String, userRoleInfo>();
		firmUserRoleMap = new Map<String, userRoleInfo>();

		if (user != null) {
			List<ZP_User_Role__c> list_ZPuserRole = new List<ZP_User_Role__c>();
			//Dato - April 10, 2020 - added Deleted_At__c filter in ZP User Role query to avoid displaying inactive role info.
			for (ZP_User_Role__c role : [
				SELECT
					Id,
					Type__c,
					First_Name__c,
					Last_name__c,
					Accounting_Firm_Id__c,
					Employee_Id__c,
					Contractor_Id__c,
					Billing_Admin__c,
					Company_Id__c,
					Is_Primary__c,
					Collaborator_Type__c,
					User_Permissions__c
				FROM ZP_User_Role__c
				WHERE User_Id__c = :userId AND Deleted_At__c = NULL
			]) {
				if (role.Company_Id__c != null && role.Company_Id__c != '') {
					companySet.add(role.Company_Id__c);
				}
				if (role.Accounting_Firm_Id__c != null && role.Accounting_Firm_Id__c != '') {
					accountantSet.add(role.Accounting_Firm_Id__c);
				}
				list_ZPuserRole.add(role);
			}
			Map<String, Account> companyMap = new Map<String, Account>();
			Map<String, Account> accountantMap = new Map<String, Account>();
			if (companySet.size() > 0) {
				companyMap = getCompanyMap(companySet);
			}
			if (accountantSet.size() > 0) {
				accountantMap = getAccountantMap(accountantSet);
			}
			//Dato - April 10, 2020 - added Deleted_At__c filter in ZP User Role query to avoid displaying inactive role info.
			for (ZP_User_Role__c role : list_ZPuserRole) {
				userRoleInfo roleInfo = new userRoleInfo();
				if (role.Company_Id__c != null && role.Company_Id__c != '') {
					if (companyUserRoleMap.containsKey(role.Company_Id__c)) {
						roleInfo = companyUserRoleMap.get(role.Company_Id__c);
					}
				}
				if (role.Accounting_Firm_Id__c != null && role.Accounting_Firm_Id__c != '') {
					if (firmUserRoleMap.containsKey(role.Accounting_Firm_Id__c)) {
						roleInfo = firmUserRoleMap.get(role.Accounting_Firm_Id__c);
					}
				}

				if (role.Company_Id__c != null && role.Company_Id__c != '') {
					roleInfo.zpCompanyId = role.Company_Id__c;
					if (companyMap.containsKey(role.Company_Id__c)) {
						Account comp = companyMap.get(role.Company_Id__c);
						roleInfo.companyName = comp.Name;
						roleInfo.companyId = comp.Id;
						if (String.isNotBlank(comp.Concierge_Group_Id__c)) {
							roleInfo.conciergeGroupId = 'Concierge Pod: ' + comp.Concierge_Group_Id__c + ' <br/> ';
							roleInfo.conciergeGroupName = comp.Concierge_Group__c;
						}

						if (string.isNotBlank(comp.Tier__c)) {
							roleInfo.Tier = 'Tier: ' + comp.Tier__c + ' <br/> ';
						}
					}
				}
				if (role.Accounting_Firm_Id__c != null && role.Accounting_Firm_id__c != '') {
					roleInfo.zpFirmId = role.Accounting_Firm_Id__c;
					if (accountantMap.containsKey(role.Accounting_Firm_Id__c)) {
						Account accntant = accountantMap.get(role.Accounting_Firm_Id__c);
						roleInfo.firmName = accntant.Name;
						roleInfo.firmId = accntant.Id;
						if (String.isNotBlank(accntant.Concierge_Group_Id__c)) {
							roleInfo.conciergeGroupId = 'Concierge Pod ' + accntant.Concierge_Group_Id__c + ' <br/> ';
							roleInfo.conciergeGroupName = accntant.Concierge_Group__c;
						}

						if (String.isNotBlank(accntant.AM_Tier__c)) {
							roleInfo.Tier = 'Partner Tier: ' + accntant.AM_Tier__c + ' <br/> ';
						}
					}
				}
				roleInfo.firstName = role.First_Name__c;
				roleInfo.lastName = role.Last_Name__c;
				if (role.Type__c == 'Role::PayrollAdmin') {
					roleInfo.payrollAdmin = true;
					if (role.Is_Primary__c) {
						roleInfo.primaryPayrollAdmin = true;
					}
				} else if (role.Type__c == 'Role::Employee') {
					roleInfo.employee = true;
				} else if (role.Type__c == 'Role::Contractor') {
					roleInfo.contractor = true;
				} else if (role.Type__c == 'Role::Signatory') {
					roleInfo.signatory = true;
				} else if (role.Type__c == 'Role::Accountant') {
					roleInfo.accountant = true;
				}
				if (role.Billing_Admin__c == true) {
					roleInfo.billingAdmin = true;
				}

				if (role.User_Permissions__c != null && role.User_Permissions__c.length() > 0) {
					String perStr;
					for (String pstr : role.User_Permissions__c.split(',')) {
						if (String.isBlank(perStr)) {
							perStr = '<b>' + getTitleString(pstr) + '</b><br/>';
						} else {
							perStr += '<b>' + getTitleString(pstr) + '</b><br/>';
						}
					}
					roleInfo.permissionStr = perStr;
				}

				if (role.Company_Id__c != null && role.Company_Id__c != '') {
					companyUserRoleMap.put(role.Company_Id__c, roleInfo);
				}
				if (role.Accounting_Firm_Id__c != null && role.Accounting_Firm_Id__c != '') {
					firmUserRoleMap.put(role.Accounting_Firm_Id__c, roleInfo);
				}
			}
		}
		companyInfo = companyUserRoleMap.values();
		firmInfo = firmUserRoleMap.values();

		userRoleInformation info = new userRoleInformation();
		//SJay - 03/23/2020 - Assigning global map to userRoleInformation map instead of list to avoid the over 1000 limit of lists.
		//Jira: BT-7264 - Collection size issue when opening email case
		info.companyInfo = companyInfo;
		info.firmInfo = firmInfo;
		info.companyUserRoleMap = companyUserRoleMap;
		info.firmUserRoleMap = firmUserRoleMap;

		return info;
	}

	public Map<String, Account> getCompanyMap(Set<String> companySet) {
		Map<String, Account> companyMap = new Map<String, Account>();
		for (Account acc : [SELECT Id, Name, ZP_Company_Id__c, ZP_Firm_ID__c, Concierge_Group__c, Concierge_Group_Id__c, Tier__c, RecordType.Name FROM Account WHERE ZP_Company_Id__c IN :companySet]) {
			companyMap.put(acc.ZP_Company_Id__c, acc);
		}
		return companyMap;
	}

	public Map<String, Account> getAccountantMap(Set<String> accountantSet) {
		Map<String, Account> accountantMap = new Map<String, Account>();
		for (Account acc : [
			SELECT Id, Name, ZP_Company_Id__c, ZP_Firm_ID__c, Concierge_Group__c, Concierge_Group_Id__c, AM_Tier__c, RecordType.Name
			FROM Account
			WHERE ZP_Firm_ID__c IN :accountantSet
		]) {
			accountantMap.put(acc.ZP_Firm_ID__c, acc);
		}
		return accountantMap;
	}

	public String getTitleString(String val) {
		val = val.toLowerCase().replaceAll('_', ' ');
		List<String> pieces = new List<String>();

		for (String s : val.split(' ')) {
			// Capitalize each piece
			s = s.capitalize();
			pieces.add(s);
		}

		return String.join(pieces, ' ');
	}

	Boolean isReroute = false;
	public void updateRerouteAccount() {
		isReroute = true;
		updateAccount();
	}

	public void updateAccount() {
		if (string.isNotBlank(company_FirmId) && string.isNotBlank(caseId)) {
			Case tempCase = new Case(Id = caseId);
			tempCase.AccountId = company_FirmId;
			tempCase.Related_Account_Touchpoint__c = true;
			if (isReroute) {
				Database.DMLOptions dmo = new Database.DMLOptions();
				dmo.assignmentRuleHeader.useDefaultRule = true;
				tempCase.setOptions(dmo);
			}

			try {
				update tempCase;
				isReroute = false;
			} catch (exception ex) {
				apexPages.addMessage(new apexPages.Message(apexPages.severity.error, ex.getMessage()));
			}
		}
	}

	public class userRoleInformation {
		public List<userRoleInfo> companyInfo { get; set; }
		public List<userRoleInfo> firmInfo { get; set; }
		// Jira: BT-7264 - Collection size issue when opening email case
		// SJay - 03/23/2020 - Added the maps to userRoleInformation class
		public Map<String, userRoleInfo> companyUserRoleMap { get; set; }
		public Map<String, userRoleInfo> firmUserRoleMap { get; set; }
	}

	public class userRoleInfo {
		public String zpCompanyId { get; set; }
		public String companyId { get; set; }
		public String companyName { get; set; }
		public string conciergeGroupId { get; set; }
		public string tier { get; set; }
		public string conciergeGroupName { get; set; }
		public String zpFirmId { get; set; }
		public String firmId { get; set; }
		public String firmName { get; set; }
		public String firstName { get; set; }
		public String lastName { get; set; }
		public String phone { get; set; }
		public String permissionStr { get; set; }
		public Boolean payrollAdmin { get; set; }
		public Boolean primaryPayrollAdmin { get; set; }
		public Boolean accountant { get; set; }
		public Boolean contractor { get; set; }
		public Boolean employee { get; set; }
		public Boolean signatory { get; set; }
		public Boolean billingAdmin { get; set; }
		/**
            @Added By: David (Dato) Tsamalashvili
            @Date: April 10, 2020
            @Desc: BT-7428 - All role names where rendered in UI since default values where null.
                    Setting boolean default values.
        */
		public userRoleInfo() {
			this.payrollAdmin = false;
			this.primaryPayrollAdmin = false;
			this.accountant = false;
			this.contractor = false;
			this.employee = false;
			this.signatory = false;
			this.billingAdmin = false;
		}
	}
}