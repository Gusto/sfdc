@isTest
public class AdminPermissionsTest {
	@isTest
	static void testGetAdminPerms() {
		//Method to fetch permissions
		Account objAcc = new Account(name = 'Test', ZP_Company_ID__c = '1111');
		insert objAcc;

		contact objCon = new contact();
		objCon.accountId = objAcc.id;
		objCon.LastName = 'Full';
		objCon.ZP_User_Id__c = '0000';
		objCon.Email = 'test@test.com';
		insert objCon;

		Case objCase = new Case(Status = 'New', Origin = 'Phone', AccountId = objAcc.Id, SuppliedEmail = 'test@test.com', ContactId = objCon.Id);
		insert objCase;

		ZP_User__c objUser = new ZP_User__c(Email__c = 'test@test.com', Created_At__c = System.now(), Updated_At__c = System.now(), Id__c = '122733');
		insert objUser;
		List<ZP_User__c> userList = new List<ZP_User__c>();
		userList.add(objUser);

		ZP_User_Role__c userRoleObj = new ZP_User_Role__c(User_Permissions__c = 'Test Permissions', User_Id__c = objCon.ZP_User_Id__c, Company_Id__c = objAcc.ZP_Company_ID__c, Deleted_At__c = null);
		insert userRoleObj;

		LiveChatVisitor objVisitor = new LiveChatVisitor();
		insert objVisitor;

		LiveChatTranscript objChat = new LiveChatTranscript(CaseId = objCase.Id, liveChatVisitorId = objVisitor.id);
		insert objChat;

		Test.startTest();
		List<String> lst_permission = AdminPermissions.queryAdminPerms(objCase.Id);
		System.assert(lst_permission.size() > 0, 'There should be at least 1 permissions.');
		Test.stopTest();
	}

	@isTest
	static void testGetUserRoles() {
		//Method to fetch user roles
		Account objAcc = new Account(name = 'Test', ZP_Company_ID__c = '1111');
		insert objAcc;

		contact objCon = new contact();
		objCon.accountId = objAcc.id;
		objCon.LastName = 'Full';
		objCon.ZP_User_Id__c = '0000';
		insert objCon;

		Case objCase = new Case(Status = 'New', Origin = 'Phone', AccountId = objAcc.Id, SuppliedEmail = 'test@test.com', ContactId = objCon.Id);
		insert objCase;

		ZP_User__c objUser = new ZP_User__c(Email__c = 'test@test.com', Created_At__c = System.now(), Updated_At__c = System.now(), Id__c = '122733');
		insert objUser;
		List<ZP_User__c> userList = new List<ZP_User__c>();
		userList.add(objUser);

		ZP_User_Role__c objuserRole = new ZP_User_Role__c(
			User_Permissions__c = 'Test Permissions',
			User_Id__c = objCon.ZP_User_Id__c,
			Company_Id__c = objAcc.ZP_Company_ID__c,
			Is_Primary__c = false,
			Deleted_At__c = null,
			Type__c = 'Role::PayrollAdmin'
		);
		insert objuserRole;

		LiveChatVisitor objVisitor = new LiveChatVisitor();
		insert objVisitor;

		LiveChatTranscript objChat = new LiveChatTranscript(CaseId = objCase.Id, liveChatVisitorId = objVisitor.id);
		insert objChat;
		Test.startTest();
		List<String> lst_roles = AdminPermissions.queryUserRoles(objCase.Id);
		System.assert(lst_roles.size() > 0, 'There should be at least 1 user role.');
		Test.stopTest();
	}
}