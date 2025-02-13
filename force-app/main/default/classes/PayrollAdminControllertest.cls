@isTest
public class PayrollAdminControllertest {
	static testMethod void payrolladmin() {
		Account acc = new Account(Name = 'Test Company Name123');
		insert acc;

		Opportunity opp = new Opportunity(Name = 'Test Opp', AccountId = acc.Id, ZP_Company_ID__c = '123456', Source_ID__c = 'HINP123');
		insert Opp;

		ZP_User_Role__c zpuserrole = new ZP_User_Role__c(
			User_Id__c = '1237889',
			First_Name__c = 'Char',
			Last_Name__c = 'Dhar',
			Type__c = 'Role::PayrollAdmin',
			Company_Id__c = opp.ZP_Company_ID__c,
			Is_Primary__c = true
		);
		insert zpuserrole;

		ZP_User__c zpuser = new ZP_User__c(Email__c = 'admin@test.com', Id__c = zpuserrole.User_Id__c, Created_At__c = System.now(), Updated_At__c = System.now());
		insert zpuser;

		HI_New_Plans_Application__c HINPApp = new HI_New_Plans_Application__c(Id__c = '2987-HI', External_Key__c = 'HINP123');
		insert HINPApp;

		HI_Benefits_Admin__c HIBAuser = new HI_Benefits_Admin__c(ZP_User_Id__c = '1237889', Id__c = '2987-HI');
		insert HIBAuser;

		test.startTest();

		ApexPages.StandardController sc = new ApexPages.StandardController(opp);

		PayrollAdminController payrolladm = new PayrollAdminController(sc);
		payrolladm.getUserroles();
		PayrollAdminController.userDetails wrapperRec = new PayrollAdminController.userDetails(zpuserrole.First_Name__c, zpuserrole.Last_Name__c, zpuser.Email__c, zpuserrole.Is_Primary__c);

		BenefitsAdminController bac = new BenefitsAdminController(sc);
		bac.getUserroles();
		bac.getBenefitUserroles();
		BenefitsAdminController.BenefitsuserDetails benefitswrapper = new BenefitsAdminController.BenefitsuserDetails(
			zpuserrole.First_Name__c,
			zpuserrole.Last_Name__c,
			zpuser.Email__c,
			zpuserrole.Is_Primary__c
		);

		test.stopTest();
	}
}