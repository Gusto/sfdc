/**
 * @name         : PayrollAuditTriggerHelper
 * @author       : Debasmita Rawooth
 * @date         : 07-28-2021
 * @description  : New PayrollAuditTriggerHelper Class for PayrollAuditTrigger
 * @test classes : PayrollAuditTriggerHelperTest
 **/
public class PayrollAuditTriggerHelper {
	// Static Variable used to Skip Triggers
	public static Boolean skipTrigger = false;

	/*** All set variables ***/
	public Set<String> set_CompanyIds;
	public Set<String> set_AdminUserIds;

	/*** All Map Variables ***/
	public Map<String, Account> map_CompanyIdToAccount;
	public Map<String, Contact> map_AdminUserIdToContact;

	//Constructor
	public PayrollAuditTriggerHelper() {
		set_CompanyIds = new Set<String>();
		set_AdminUserIds = new Set<String>();
		map_CompanyIdToAccount = new Map<String, Account>();
		map_AdminUserIdToContact = new Map<String, Contact>();
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Handles Before Insert Context
	 * @Parm        : list_PayrollAudits - List of Payroll Audits from Trigger.new
	 * @Return      : N/A
	 **/
	public void processBeforeInsert(List<Payroll_Audit__c> list_PayrollAudits) {
		setCollectionsBefore(list_PayrollAudits);

		//set field values
		for (Payroll_Audit__c objPayrollAudit : list_PayrollAudits) {
			updateAccount(objPayrollAudit, null);
			updateContact(objPayrollAudit, null);
		}
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Handles Before Update Context
	 * @Parm        : list_PayrollAudits - List of Payroll Audits from Trigger.new
	 * @Parm        : map_OldPayrollAudits - Map of Payroll Audit Id and Payroll Audit Object from Trigger.oldMap
	 * @Return      : N/A
	 **/
	public void processBeforeUpdate(
		List<Payroll_Audit__c> list_PayrollAudits,
		Map<Id, Payroll_Audit__c> map_OldPayrollAudits
	) {
		setCollectionsBefore(list_PayrollAudits);

		//set field values
		for (Payroll_Audit__c objPayrollAudit : list_PayrollAudits) {
			Payroll_Audit__c objOldPayrollAudit = map_OldPayrollAudits.containsKey(objPayrollAudit.Id)
				? map_OldPayrollAudits.get(objPayrollAudit.Id)
				: null;
			updateAccount(objPayrollAudit, objOldPayrollAudit);
			updateContact(objPayrollAudit, objOldPayrollAudit);
		}
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Queries data and creates collections required for BEFORE context
	 * @Parm        : list_PayrollAudits - List of Payroll Audits from Trigger.new
	 * @Return      : N/A
	 **/
	public void setCollectionsBefore(List<Payroll_Audit__c> list_PayrollAudits) {
		for (Payroll_Audit__c objPayrollAudit : list_PayrollAudits) {
			//get company ids to query existing accounts
			if (String.isNotBlank(objPayrollAudit.company_id__c)) {
				set_CompanyIds.add(objPayrollAudit.company_id__c);
			}
			//get admin user ids to query existing users
			if (String.isNotBlank(objPayrollAudit.admin_user_id__c)) {
				set_AdminUserIds.add(objPayrollAudit.admin_user_id__c);
			}
		}
		if (!set_CompanyIds.isEmpty()) {
			for (Account objAcc : queryAccounts(set_CompanyIds)) {
				map_CompanyIdToAccount.put(objAcc.ZP_Company_ID__c, objAcc);
			}
		}
		if (!set_AdminUserIds.isEmpty()) {
			for (Contact objCon : queryContacts(set_AdminUserIds)) {
				map_AdminUserIdToContact.put(objCon.ZP_User_Id__c, objCon);
			}
		}
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Queries Accounts based on ZP_Company_Id__c
	 * @Parm        : set_CompanyIds - Set of
	 * @Return      : List of Accounts
	 **/
	public List<Account> queryAccounts(Set<String> set_CompanyIds) {
		return [SELECT Id, Name, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c IN :set_CompanyIds];
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Queries Contacts based on ZP_user_Id__c
	 * @Parm        : set_AdminUserIds -
	 * @Return      : List of Contacts
	 **/
	public List<Contact> queryContacts(Set<String> set_AdminUserIds) {
		return [
			SELECT Id, FirstName, LastName, Email, ZP_User_Id__c
			FROM Contact
			WHERE ZP_User_Id__c IN :set_AdminUserIds
		];
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Updates Account__c based on value in company_id__c
	 * @Parm        : objPayrollAudit - New Payroll Audit
	 * @Parm        : objOldPayrollAudit - Old Payroll Audit
	 * @Return      : N/A
	 **/
	public void updateAccount(Payroll_Audit__c objPayrollAudit, Payroll_Audit__c objOldPayrollAudit) {
		if (
			objOldPayrollAudit == null ||
			(objOldPayrollAudit != null && (objOldPayrollAudit.company_id__c != objPayrollAudit.company_id__c))
		) {
			if (
				objPayrollAudit.company_id__c != null &&
				map_CompanyIdToAccount.containsKey(objPayrollAudit.company_id__c)
			) {
				objPayrollAudit.Account__c = map_CompanyIdToAccount.get(objPayrollAudit.company_id__c).Id;
			}
		}
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Updates Contact__c based on value in admin_user_id__c
	 * @Parm        : objPayrollAudit - New Payroll Audit
	 * @Parm        : objOldPayrollAudit - Old Payroll Audit
	 * @Return      : N/A
	 **/
	public void updateContact(Payroll_Audit__c objPayrollAudit, Payroll_Audit__c objOldPayrollAudit) {
		if (
			objOldPayrollAudit == null ||
			(objOldPayrollAudit != null && (objOldPayrollAudit.admin_user_id__c != objPayrollAudit.admin_user_id__c))
		) {
			if (
				objPayrollAudit.admin_user_id__c != null &&
				map_AdminUserIdToContact.containsKey(objPayrollAudit.admin_user_id__c)
			) {
				objPayrollAudit.Contact__c = map_AdminUserIdToContact.get(objPayrollAudit.admin_user_id__c).Id;
				objPayrollAudit.Admin_First_Name__c = map_AdminUserIdToContact.get(objPayrollAudit.admin_user_id__c)
					.FirstName;
				objPayrollAudit.Admin_Last_Name__c = map_AdminUserIdToContact.get(objPayrollAudit.admin_user_id__c)
					.LastName;
				objPayrollAudit.Admin_Email__c = map_AdminUserIdToContact.get(objPayrollAudit.admin_user_id__c)
					.Email;
			}
		}
	}
}