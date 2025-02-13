@isTest
private class GenesysCallbackIntegrationTest {
	@TestSetup
	static void setupMethod() {
		Account objCompAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account OHI').setZPCompanyId('1111111111').build();

		insert objCompAccount;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objCompAccount.Id)
			.setFirstName('Test First Name2')
			.setLastName('Test Last Name2')
			.setEmail('test@testdomain2.com')
			.build();

		insert objContact;

		Case cse = new Case();
		cse.AccountId = objCompAccount.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		cse.Type = 'Payroll Care';
		cse.Origin = 'Phone';
		cse.Genesys_Call_Id__c = 'ndndj123242';
		cse.SuppliedEmail = 'test.test@Genesystest.com';
		cse.SuppliedPhone = '4598598333';
		cse.SuppliedName = 'TestGenesysCallBack Controller';
		cse.Auto_Close_Date_Time__c = System.now();
		cse.ContactId = objContact.Id;
		insert cse;

		Integration_System_Information__c detailRec = new Integration_System_Information__c();
		detailRec.Name = 'GenesysCallBack';
		detailRec.Url__c = 'https://Test.com';
		detailRec.User_Name__c = 'TestUserName';
		detailRec.Password__c = 'DemoPassword';
		insert detailRec;
	}

	@isTest
	static void testCallOutMethod() {
		list<Case> caseList = [SELECT id, SuppliedPhone, SuppliedName, Auto_Close_Date_Time__c, Genesys_Call_Id__c, CaseNumber, Origin FROM Case];
		Case tempCase = caseList.get(0);
		string queueid = '123441123';
		string dtm = '';
		if (tempCase.Auto_Close_Date_Time__c != null) {
			DateTime tempDtm = tempCase.Auto_Close_Date_Time__c;
			dtm = tempDtm.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss') + '.000Z';
		}

		GenesysCallbackIntegration genesysIntegration = new GenesysCallbackIntegration();
		string response = genesysIntegration.sumitCallBack(
			queueid,
			tempCase.SuppliedPhone,
			tempCase.SuppliedName,
			dtm,
			userInfo.getFirstName() +
			' ' +
			userInfo.getLastName(),
			tempCase.id,
			true,
			null,
			null,
			'test',
			tempCase.Genesys_Call_Id__c,
			tempCase.CaseNumber,
			tempCase.Origin
		);

		System.assert(response != null && response.indexof('Success') > -1);
	}
}