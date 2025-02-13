/**
 * @Author 		: Chandrika
 * @Date Created : 04 August 2020
 * @Desc 		: Test class for ZPAccountantSurveyResponseTriggerHelper
 */
@isTest
public class ZPAccountantSurveyResponseTriggerTest {
	@isTest
	static void testAccountantSurveyResponse() {
		AccountTriggerHelper.skipTrigger = true;
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(Cache.getRecordTypeId('Account', 'Reseller')).setName('lirik-test').setZPFirmId('Company11111').build();
		insert objAccount;
		AccountTriggerHelper.skipTrigger = false;

		LeadTriggerHelper.skipTrigger = true;
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setFirstName('Test')
			.setLastName('Test-Self_Onbaord')
			.setEmail('testselfOnboard@test.com')
			.setCompany('lirik-test')
			.setZpCompanyId('1234567890')
			.setLeadSource('Added by Client')
			.setStatus('AQL')
			.setRecordTypeId(Cache.getRecordTypeId('Lead', 'Company'))
			.setConvertedAccountId(objAccount.Id)
			.setZPAccountantLeadID('178901')
			.build();
		insert objLead;
		Database.LeadConvert lc = new database.LeadConvert();
		lc.setLeadId(objLead.id);
		leadStatus objconvertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
		lc.setConvertedStatus(objconvertStatus.MasterLabel);
		lc.setDoNotCreateOpportunity(true);
		Database.LeadConvertResult lcr = Database.convertLead(lc);
		LeadTriggerHelper.skipTrigger = false;

		ZP_Accountant_Survey_Response__c obj_ZPAccSurveyResponse = new TestDataFactory.ZPAccountantSurveyResponseBuilder()
			.setFirmPrimaryLocationZipCode('85250')
			.setId('11111')
			.setInvolvementInClientPayroll('Somewhat')
			.setNumberOfAccountantsInFirm('2 - 9 accountants')
			.setOtherPayrollProvidersUsed('Intuit or QuickBooks, Square')
			.setRoleAtFirm('Controller')
			.setServicesOffered('Bookkeeping, HR Advising, Managing payroll')
			.setWillRunFirstClientPayrollTimeline('As soon as possible')
			.setAccountantLeadId('178901')
			.build();
		insert obj_ZPAccSurveyResponse;
		Test.startTest();
		obj_ZPAccSurveyResponse.Firm_Primary_Location_Zip_Code__c = '94539';
		obj_ZPAccSurveyResponse.Accounting_Firm_Id__c = 'Company11111';
		update obj_ZPAccSurveyResponse;

		List<ZP_Accountant_Survey_Response__c> list_ZpAccSurveyRes = [SELECT Id, Accounting_Firm_Id__c FROM ZP_Accountant_Survey_Response__c];
		System.assert(list_ZpAccSurveyRes.size() != null, 'list_ZpAccSurveyRes should not be null.');

		Test.stopTest();
	}

	@isTest
	static void testAccountantSurveyResponsEmail() {
		AccountTriggerHelper.skipTrigger = true;
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(Cache.getRecordTypeId('Account', 'Reseller')).setName('lirik-test').setZPFirmId('Company11111').build();
		insert objAccount;
		AccountTriggerHelper.skipTrigger = false;

		LeadTriggerHelper.skipTrigger = true;
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setFirstName('Test')
			.setLastName('Test-Self_Onbaord')
			.setEmail('responemail@testresponemail.com')
			.setCompany('lirik-test')
			.setZpCompanyId('1234567890')
			.setLeadSource('Added by Client')
			.setStatus('AQL')
			.setRecordTypeId(Cache.getRecordTypeId('Lead', 'Company'))
			.setConvertedAccountId(objAccount.Id)
			.setZPAccountantLeadID('178901')
			.build();
		insert objLead;
		Database.LeadConvert lc = new database.LeadConvert();
		lc.setLeadId(objLead.id);
		leadStatus objconvertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
		lc.setConvertedStatus(objconvertStatus.MasterLabel);
		lc.setDoNotCreateOpportunity(true);
		Database.LeadConvertResult lcr = Database.convertLead(lc);
		LeadTriggerHelper.skipTrigger = false;

		ZP_Accountant_Survey_Response__c obj_ZPAccSurveyResponse = new TestDataFactory.ZPAccountantSurveyResponseBuilder()
			.setFirmPrimaryLocationZipCode('85250')
			.setId('11111')
			.setAccountingFirmId('2222222')
			.setRespondentEmail('responemail@testresponemail.com')
			.setInvolvementInClientPayroll('Somewhat')
			.setNumberOfAccountantsInFirm('2 - 9 accountants')
			.setOtherPayrollProvidersUsed('Intuit or QuickBooks, Square')
			.setRoleAtFirm('Controller')
			.setServicesOffered('Bookkeeping, HR Advising, Managing payroll')
			.setWillRunFirstClientPayrollTimeline('As soon as possible')
			.setAccountantLeadId('178901')
			.build();

		Test.startTest();
		insert obj_ZPAccSurveyResponse;

		List<ZP_Accountant_Survey_Response__c> list_ZpAccSurveyRes = [SELECT Id, Accounting_Firm_Id__c FROM ZP_Accountant_Survey_Response__c];
		System.assert(list_ZpAccSurveyRes.size() != null, 'list_ZpAccSurveyRes should not be null.');

		Test.stopTest();
	}
	//BY :Prashant : 07-09-2020 : Test case scenario for Onboarding Intent

	@isTest
	static void testOnbaordingIntent() {
		LeadTriggerHelper.skipTrigger = true;

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setFirstName('Test')
			.setLastName('TestLead')
			.setEmail('responemail@testresponemail.com')
			.setCompany('lirik-testnew')
			.setLeadSource('Added by Client')
			.setZPFirmId('Company11111')
			.setStatus('AQL')
			.setRecordTypeId(Cache.getRecordTypeId('Lead', 'Reseller'))
			.setZPAccountantLeadID('178901')
			.build();
		insert objLead;

		Database.LeadConvert lc = new Database.LeadConvert();
		lc.setLeadId(objLead.id);
		leadStatus objconvertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
		lc.setConvertedStatus(objconvertStatus.MasterLabel);
		lc.setDoNotCreateOpportunity(true);
		Database.LeadConvertResult lcr = Database.convertLead(lc);

		lead objConvrtLead = [SELECT Id, IsConverted, converted_Account__c, ConvertedAccountId, ConvertedContactId FROM Lead WHERE id = :objLead.id];
		objConvrtLead.converted_Account__c = objConvrtLead.ConvertedAccountId;
		update objConvrtLead;

		LeadTriggerHelper.skipTrigger = false;

		ZP_Accountant_Survey_Response__c objZPAccSurveyResponse = new TestDataFactory.ZPAccountantSurveyResponseBuilder()
			.setFirmPrimaryLocationZipCode('85250')
			.setId('11111')
			.setAccountingFirmId('Company11111')
			.setRespondentEmail('responemail@testresponemail.com')
			.setInvolvementInClientPayroll('Somewhat')
			.setNumberOfAccountantsInFirm('less than 10')
			.setWillRunFirstClientPayrollTimeline('In the next month')
			.setAccountantLeadId('178901')
			.build();
		Test.startTest();

		insert objZPAccSurveyResponse;

		Accountant_Survey_Response__c objAccSurvey = [SELECT Id, Contact__c, Account__c, Onboarding_Intent__c FROM Accountant_Survey_Response__c WHERE Account__c = :objConvrtLead.ConvertedAccountId];
		System.assertEquals('High', objAccSurvey.Onboarding_Intent__c, 'Account Survey Response\'s Onboarding_Intent__c should be High');

		Account objAcc = [SELECT Id, Onboarding_Intent__c, ASR_Number_Of_Accountants__c FROM Account WHERE Id = :objAccSurvey.Account__c];
		System.assertEquals('High', objAcc.Onboarding_Intent__c, 'Account\'s Onboarding_Intent__c should be High');
		System.assertEquals('less than 10', objAcc.ASR_Number_Of_Accountants__c, 'Account\'s ASR_Number_Of_Accountants__c should be 2 - 9 accountants');
		Contact objCon = [SELECT Id, Onboarding_Intent__c, AccountId FROM Contact WHERE Id = :objAccSurvey.Contact__c];
		System.assertEquals('High', objCon.Onboarding_Intent__c, 'Contact\'s Onboarding_Intent__c should be High');
		objZPAccSurveyResponse.Number_of_Accountants_in_Firm__c = 'CantTell';
		update objZPAccSurveyResponse;

		Test.stopTest();
	}
}