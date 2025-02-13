/**
 * @name         : LWC_AccountUserInformationController
 * @author       : Dhir Kumar
 * @date         : 10-08-2020
 * @description  : Apex controller for caseAccountHeaderPopover LWC.
 * @test classes : LWC_AccountUserInformationCont_Test
 **/
public without sharing class LWC_AccountUserInformationController {
	/**
	 * @Author      : Dhir Kumar
	 * @Description : It will query the case record
	 * @Parm        : strId - record id
	 * @Return      : Map<String, SObject>
	 **/
	@AuraEnabled
	public static Map<String, SObject> queryCase(String strId) {
		Map<String, SObject> map_Case = new Map<String, SObject>();
		Id idRecordId = (Id) strId;
		String strSObjectType = idRecordId.getSObjectType().getDescribe().getName();
		if (strSObjectType.equals('LiveChatTranscript')) {
			strId = [SELECT Id, CaseId FROM LiveChatTranscript WHERE Id = :strId]?.CaseId;
		}
		Case objCase = [
			SELECT
				Id,
				Subject,
				CaseNumber,
				ContactId,
				AccountId,
				OwnerId,
				Status,
				RecordTypeId,
				RecordType.Name,
				Panda_Company_URL__c,
				Account_Company_Id__c,
				Contact_Employee_Id__c,
				Assigned_by_Play_Mode__c,
				Contact.Name,
				Account.Name,
				Contact.Email,
				Contact.Phone
			FROM Case
			WHERE Id = :strId
		];
		map_Case.put('CaseRec', objCase);
		return map_Case;
	}

	/**
	 * @Author      : Dhir Kumar
	 * @Description : This method will Perform the DML operation on the Case and relate to contact selected from the UI.
	 * @Parm        : idCaseId - case id, strAccountId - Account Id
	 * @Return      : -
	 **/
	@AuraEnabled
	public static void updateContactOnSave(Id idCaseId, String strAccountId) {
		String strObjectType = idCaseId.getSObjectType().getDescribe().getName();
		if (strObjectType.equals('LiveChatTranscript')) {
			idCaseId = [SELECT Id, CaseId FROM LiveChatTranscript WHERE Id = :idCaseId]?.CaseId;
		}

		if (idCaseId != null && String.isNotBlank(strAccountId)) {
			Case objCase = new Case(Id = idCaseId, AccountId = strAccountId);
			update objCase;
		}
	}

	/**
	 * @Author      : Dhir Kumar
	 * @Description : This method is to get the ZP User roles and related informatoin to show as contact on the UI.
	 * @Parm        : idCase - case id
	 * @Return      : UserRoleInformation - Wrapper of UserRoleInformation
	 **/
	@AuraEnabled
	public static UserRoleInformation getUserInformation(Id idCase) {
		List<UserRoleInfo> list_CompanyInfo = new List<UserRoleInfo>();
		List<UserRoleInfo> list_FirmInfo = new List<UserRoleInfo>();
		Set<String> set_Company = new Set<String>();
		Set<String> set_Accountant = new Set<String>();
		ZP_User__c objZPUser = new ZP_User__c();
		Case objCase;
		String strObjectType = idCase.getSObjectType().getDescribe().getName();
		if (strObjectType.equals('LiveChatTranscript')) {
			idCase = [SELECT Id, CaseId FROM LiveChatTranscript WHERE Id = :idCase]?.CaseId;
		}

		if (!String.isBlank(idCase)) {
			objCase = [
				SELECT Contact.ZP_User_Id__c, Account.ZP_Company_ID__c, Account.ZP_Firm_ID__c, Account.AM_Tier__c, Contact.Name, SuppliedEmail
				FROM Case
				WHERE Id = :idCase
				LIMIT 1
			];
		}
		
		// SJay - 03/23/2020 - Added the maps to UserRoleInformation class
		//Jira: BT-7264 - Collection size issue when opening email case
		Map<String, UserRoleInfo> map_CompanyUser = new Map<String, UserRoleInfo>();
		Map<String, UserRoleInfo> map_FirmUserRole = new Map<String, UserRoleInfo>();

		if (objCase != null && objCase.Account != null && (String.isNotBlank(objCase.Account.ZP_Company_ID__c) || String.isNotBlank(objCase.Account.ZP_Firm_ID__c))) {
			//Dato - April 10, 2020 - added Deleted_At__c filter in ZP User Role query to avoid displaying inactive role info.
			String strQuery = 'SELECT Id, Type__c, User_Id__c, First_Name__c, Last_Name__c, Accounting_Firm_Id__c, Contractor_Id__c, Billing_Admin__c, Company_Id__c, Is_Primary__c, Collaborator_Type__c, User_Permissions__c FROM ZP_User_Role__c';
			strQuery += ' WHERE (';
			if (String.isNotBlank(objCase.Account.ZP_Company_ID__c)) {
				strQuery += ' Company_Id__c = \'' + objCase.Account.ZP_Company_ID__c + '\'';
			}
			if (String.isNotBlank(objCase.Account.ZP_Company_ID__c) && String.isNotBlank(objCase.Account.ZP_Firm_ID__c)) {
				strQuery += ' OR ';
			}
			if (String.isNotBlank(objCase.Account.ZP_Firm_ID__c)) {
				strQuery += 'Accounting_Firm_Id__c = \'' + objCase.Account.ZP_Firm_ID__c + '\'';
			}
			strQuery += ' ) AND Deleted_At__c = null';
			String strQueryClauseForAdmin = strQuery + ' AND Type__c LIKE \'%PayrollAdmin%\'';

			for (ZP_User_Role__c objZPUserRole : Database.query(strQueryClauseForAdmin)) {
				if (String.isNotBlank(objZPUserRole.User_Id__c)) {
					set_Company.add(objZPUserRole.User_Id__c);
				}
			}

			Map<String, Contact> map_Company = new Map<String, Contact>();
			Map<String, Contact> map_Accountant = new Map<String, Contact>();

			if (set_Company.size() > 0) {
				map_Company = getCompanyMap(set_Company);
			}

			//Dato - April 10, 2020 - added Deleted_At__c filter in ZP User Role query to avoid displaying inactive role info.
			for (ZP_User_Role__c objZPUserRole : Database.query(strQuery)) {
				if (String.isNotBlank(objZPUserRole.User_Id__c)) {
					if (map_Company.containsKey(objZPUserRole.User_Id__c)) {
						UserRoleInfo objRoleInfoWrapper = new UserRoleInfo();
						if (map_CompanyUser.containsKey(objZPUserRole.User_Id__c)) {
							objRoleInfoWrapper = map_CompanyUser.get(objZPUserRole.User_Id__c);
						}
						objRoleInfoWrapper.strZPCompanyId = objZPUserRole.User_Id__c;

						Contact objCompanyCont = map_Company.get(objZPUserRole.User_Id__c);
						objRoleInfoWrapper.strCompanyName = objCompanyCont.Name;
						objRoleInfoWrapper.strCompanyId = objCompanyCont.Id;
						if (String.isNotBlank(objCompanyCont.Account.Concierge_Group_Id__c)) {
							objRoleInfoWrapper.strConciergeGroupId = 'Concierge Pod: ' + objCompanyCont.Account.Concierge_Group_Id__c + ' <br/> ';
							objRoleInfoWrapper.strConciergeGroupName = objCompanyCont.Account.Concierge_Group__c;
						}

						if (string.isNotBlank(objCompanyCont.Account.Tier__c)) {
							objRoleInfoWrapper.strTier = 'Tier: ' + objCompanyCont.Account.Tier__c + ' <br/> ';
						}

						objRoleInfoWrapper.strFirstName = objZPUserRole.First_Name__c;
						objRoleInfoWrapper.strLastName = objZPUserRole.Last_Name__c;
						if (objZPUserRole.Type__c == 'Role::PayrollAdmin') {
							objRoleInfoWrapper.blnPayrollAdmin = true;
							if (objZPUserRole.Is_Primary__c) {
								objRoleInfoWrapper.blnPrimaryPayrollAdmin = true;
							}
						}
						if (objZPUserRole.Type__c == 'Role::Employee') {
							objRoleInfoWrapper.blnEmployee = true;
						}
						if (objZPUserRole.Type__c == 'Role::Contractor') {
							objRoleInfoWrapper.blnContractor = true;
						}
						if (objZPUserRole.Type__c == 'Role::Signatory') {
							objRoleInfoWrapper.blnSignatory = true;
						}
						if (objZPUserRole.Type__c == 'Role::Accountant') {
							objRoleInfoWrapper.blnAccountant = true;
						}
						// if(objZPUserRole.Billing_Admin__c == true){
						//     roleInfo.blnBillingAdmin = true;
						// }
						if (String.isNotBlank(objZPUserRole.User_Permissions__c)) {
							String strPermissions;
							for (String strPermission : objZPUserRole.User_Permissions__c.split(',')) {
								if (String.isBlank(strPermissions)) {
									strPermissions = '<b>' + getTitleString(strPermission) + '</b><br/>';
								} else {
									strPermissions += '<b>' + getTitleString(strPermission) + '</b><br/>';
								}
							}
							objRoleInfoWrapper.strPermission = strPermissions;
						}

						if (String.isNotBlank(objZPUserRole.User_Id__c)) {
							map_CompanyUser.put(objZPUserRole.User_Id__c, objRoleInfoWrapper);
						}
						if (String.isNotBlank(objZPUserRole.User_Id__c)) {
							map_FirmUserRole.put(objZPUserRole.User_Id__c, objRoleInfoWrapper);
						}
					}
				}
			}
		}

		list_CompanyInfo = map_CompanyUser.values();
		list_FirmInfo = map_FirmUserRole.values();

		UserRoleInformation objUserRoleInfoWrapper = new UserRoleInformation();
		//SJay - 03/23/2020 - Assigning global map to UserRoleInformation map instead of list to avoid the over 1000 limit of lists.
		//Jira: BT-7264 - Collection size issue when opening email case
		objUserRoleInfoWrapper.list_CompanyInfo = list_CompanyInfo;
		objUserRoleInfoWrapper.list_FirmInfo = list_FirmInfo;
		objUserRoleInfoWrapper.map_CompanyUserRole = map_CompanyUser;
		objUserRoleInfoWrapper.map_FirmUserRole = map_FirmUserRole;

		return objUserRoleInfoWrapper;
	}

	/**
	 * @Author      : Dhir Kumar
	 * @Description : This method will get the contacts on the basis of company ID from ZP user Role
	 * @Parm        : set_Company - Set of ZP User Ids
	 * @Return      : Map<String, Contact> - Map of Contacts by ZP User Id.
	 **/
	public static Map<String, Contact> getCompanyMap(Set<String> set_Company) {
		Map<String, Contact> map_Company = new Map<String, Contact>();
		for (Contact objContact : [
			SELECT Id, ZP_User_Id__c, Name, Account.ZP_Company_Id__c, Account.ZP_Firm_Id__c, Account.Concierge_Group__c, Account.Concierge_Group_Id__c, Account.Tier__c, Account.RecordType.Name
			FROM Contact
			WHERE ZP_User_Id__c IN :set_Company
		]) {
			map_Company.put(objContact.ZP_User_Id__c, objContact);
		}
		return map_Company;
	}

	/**
	 * @Author      : Dhir Kumar
	 * @Description : This method will get the contact on the basis of Firm ID from ZP user Role
	 * @Parm        : set_Accountant - set of ZP User Ids
	 * @Return      : Map<String, Contact> - Map of Contacts by ZP User Id.
	 **/
	public static Map<String, Contact> getAccountantMap(Set<String> set_Accountant) {
		Map<String, Contact> map_Accountant = new Map<String, Contact>();
		for (Contact objContact : [
			SELECT
				Id,
				ZP_User_Id__c,
				Name,
				Account.ZP_Company_Id__c,
				Account.ZP_Firm_Id__c,
				Account.Concierge_Group__c,
				Account.Concierge_Group_Id__c,
				Account.Tier__c,
				Account.AM_Tier__c,
				Account.RecordType.Name
			FROM Contact
			WHERE ZP_User_Id__c IN :set_Accountant
		]) {
			map_Accountant.put(objContact.ZP_User_Id__c, objContact);
		}
		return map_Accountant;
	}

	/**
	 * @Author      : Dhir Kumar
	 * @Description : This method will alter the data into capital and will join them into string
	 * @Parm        : strVal
	 * @Return      : String
	 **/
	public static String getTitleString(String strVal) {
		strVal = strVal.toLowerCase().replaceAll('_', ' ');
		List<String> list_Pieces = new List<String>();

		for (String strPiece : strVal.split(' ')) {
			// Capitalize each piece
			strPiece = strPiece.capitalize();
			list_Pieces.add(strPiece);
		}

		return String.join(list_Pieces, ' ');
	}

	/**
	 * @name         : UserRoleInformation
	 * @author       : Dhir Kumar
	 * @date         : 10-08-2020
	 * @description  : Wrapper class for UserRoleInformation
	 * @test classes : LWC_AccountUserInformationCont_Test
	 **/
	public class UserRoleInformation {
		@AuraEnabled
		public List<UserRoleInfo> list_CompanyInfo { get; set; }
		@AuraEnabled
		public List<UserRoleInfo> list_FirmInfo { get; set; }
		// Jira: BT-7264 - Collection size issue when opening email case
		// SJay - 03/23/2020 - Added the maps to UserRoleInformation class
		@AuraEnabled
		public Map<String, UserRoleInfo> map_CompanyUserRole { get; set; }
		@AuraEnabled
		public Map<String, UserRoleInfo> map_FirmUserRole { get; set; }
	}

	/**
	 * @name         : UserRoleInfo
	 * @author       : Dhir Kumar
	 * @date         : 10-08-2020
	 * @description  : Wrapper class for UserRoleInfo
	 * @test classes : LWC_AccountUserInformationCont_Test
	 **/
	public class UserRoleInfo {
		@AuraEnabled
		public String strZPCompanyId { get; set; }
		@AuraEnabled
		public String strCompanyId { get; set; }
		@AuraEnabled
		public String strCompanyName { get; set; }
		@AuraEnabled
		public string strConciergeGroupId { get; set; }
		@AuraEnabled
		public string strTier { get; set; }
		@AuraEnabled
		public string strConciergeGroupName { get; set; }
		@AuraEnabled
		public String strZPFirmId { get; set; }
		@AuraEnabled
		public String strFirmId { get; set; }
		@AuraEnabled
		public String strFirmName { get; set; }
		@AuraEnabled
		public String strFirstName { get; set; }
		@AuraEnabled
		public String strLastName { get; set; }
		@AuraEnabled
		public String strPhone { get; set; }
		@AuraEnabled
		public String strPermission { get; set; }
		@AuraEnabled
		public Boolean blnPayrollAdmin { get; set; }
		@AuraEnabled
		public Boolean blnPrimaryPayrollAdmin { get; set; }
		@AuraEnabled
		public Boolean blnAccountant { get; set; }
		@AuraEnabled
		public Boolean blnContractor { get; set; }
		@AuraEnabled
		public Boolean blnEmployee { get; set; }
		@AuraEnabled
		public Boolean blnSignatory { get; set; }
		@AuraEnabled
		public Boolean blnBillingAdmin { get; set; }
		/**
            @Added By: David (Dato) Tsamalashvili
            @Date: April 10, 2020
            @Desc: BT-7428 - All role names where rendered in UI since default values where null.
                    Setting boolean default values.
        */
		public UserRoleInfo() {
			this.blnPayrollAdmin = false;
			this.blnPrimaryPayrollAdmin = false;
			this.blnAccountant = false;
			this.blnContractor = false;
			this.blnEmployee = false;
			this.blnSignatory = false;
			this.blnBillingAdmin = false;
		}
	}
}