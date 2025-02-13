@istest
public class EmailCaseTeamExtensionTest {
	@testSetup
	static void setup() {
		CaseTeamRole objCaseTeamRole = [SELECT Id, Name FROM CaseTeamRole WHERE Name = 'Customer Contact' LIMIT 1];

		Account objAccRecord = new TestDataFactory.AccountBuilder()
			.setName('Test Demo AccountName 1')
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setBillingStreet('Testing Avenue 1')
			.setBillingPostalCode('123456')
			.setPhone('19992344444')
			.setCompanyTradeName('Company trade name 1')
			.setShippingStreet('Testing Avenue 1')
			.setShippingPostalCode('123455')
			.build();
		insert objAccRecord;

		Contact objContact = new TestDataFactory.ContactBuilder().setLastName('Test Contact').setAccountId(objAccRecord.Id).setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID).build();
		insert objContact;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId(CaseUtils.TYPE_BENEFITS_NEW_PLAN_CASE)
			.setAccountId(objAccRecord.Id)
			.setContactId(objContact.Id)
			.setSubject('Test Relation')
			.setDescription('Test Relation')
			.setSuppliedEmail('TickettriggerHelper@gusto.com')
			.setType(CaseUtils.TYPE_SALES)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.build();
		insert objCase;

		CaseTeamMember objCaseTeamMember = new TestDataFactory.CaseTeamMemberBuilder().setMemberId(objContact.Id).setParentId(objCase.Id).setTeamRoleId(objCaseTeamRole.Id).build();
		insert objCaseTeamMember;
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test Method to check EmailCaseTeam VF page functionality.
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testCaseExtension() {
		Case objCase = [SELECT Id FROM Case WHERE RecordTypeId = :CaseUtils.RECTYPE_NEW_PLAN LIMIT 1];

		Test.startTest();
		ApexPages.currentPage().getParameters().put('id', objCase.id);
		ApexPages.StandardController objSC = new ApexPages.StandardController(objCase);
		EmailCaseTeamExtension objExtension = new EmailCaseTeamExtension(objSC);

		Test.stopTest();

		System.assertEquals(EmailCaseTeamExtension.OWD_EMAIL_NEWPLANS, objExtension.strFromEmails, 'From Email address is invalid.');
	}
}