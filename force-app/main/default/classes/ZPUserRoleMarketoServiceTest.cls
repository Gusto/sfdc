@istest
public class ZPUserRoleMarketoServiceTest {
	@isTest
	static void testGetUserRoleData() {
		AccountTriggerHelper.skipTrigger = true;
		Account compAccount = new Account();
		compAccount.RecordTypeId = Cache.getRecordTypeId('Account', 'Company');
		compAccount.Name = 'Test';
		compAccount.ZP_Company_ID__c = '99999999999999';
		insert compAccount;
		Account resellerAccount = new Account();
		resellerAccount.RecordTypeId = Cache.getRecordTypeId('Account', 'Reseller');
		resellerAccount.Name = 'Test';
		resellerAccount.ZP_Firm_ID__c = '8888888888';
		insert resellerAccount;
		ZP_User__c user = new ZP_User__c();
		user.Id__c = '888888';
		user.Email__c = 'test@gusto.com';
		user.Created_At__c = system.today();
		user.Updated_At__c = system.today();
		insert user;

		ZP_User__c user1 = new ZP_User__c();
		user1.Id__c = '777777777777777';
		user1.email__c = 'testuser@gmail.com';
		user1.Last_Sign_In_At__c = system.now();
		user1.Created_At__c = system.now();
		user1.Updated_At__c = system.now();
		insert user1;

		List<ZP_User_Role__c> userRoleList = new List<ZP_User_Role__c>();
		ZP_User_Role__c userRole = new ZP_User_Role__c();
		userRole.User_Id__c = '777777777777777';
		userRole.Id__c = '343434343434';
		userRole.Company_Id__c = '99999999999999';
		userRole.Created_At__c = system.now();
		userRole.Updated_At__c = system.now();
		userRole.Type__c = 'Role::PayrollAdmin';
		userRole.User_Id__c = user1.Id;
		userRole.Is_Primary__c = true;
		userRoleList.add(userRole);

		ZP_User_Role__c role = new ZP_User_Role__c();
		role.User_Id__c = '888888';
		role.First_Name__c = 'Test';
		role.Last_Name__c = 'Test';
		role.Company_Id__c = '99999999999999';
		role.Accounting_Firm_Id__c = '8888888888';
		role.Company_Account__c = compAccount.id;
		role.Accounting_Firm_Account__c = resellerAccount.id;
		role.Type__c = 'Role::PayrollAdmin';
		userRoleList.add(role);
		insert userRoleList;

		ZP_Company_Onboarding_Funnel__c fun = new ZP_Company_Onboarding_Funnel__c();
		fun.Company_Id__c = '99999999999999';
		insert fun;

		ZP_Company__c objComp = new ZP_Company__c();
		objComp.Id__c = '99999999999999';
		objComp.Managing_Accounting_Firm_Id__c = '8888888888';
		insert objComp;

		List<ZPUserRoleMarketoService.UserRoleInfo> userRoleInfList = ZPUserRoleMarketoService.doGet();
		System.assertEquals(userRoleInfList.size(), 1, 'UserRoleInfoList size should be 1');
		System.assertEquals(userRoleInfList[0].accounting_firm_id, '8888888888', 'accounting_firm_id should be 8888888888');
	}
}