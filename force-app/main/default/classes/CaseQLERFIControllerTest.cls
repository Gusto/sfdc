/*
 * Description: Contains test methods to send and save the QLE RFI Case
 * Author: Omar Benitez
 * Date: 10/31/2024
 */
@isTest
public class CaseQLERFIControllerTest {
	@TestSetup
	static void setupData() {
		TriggerHandler.bypassAll();
		Account objCompAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account OHI').setZPCompanyId('1111111111').build();
		insert objCompAccount;
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objCompAccount.Id)
			.setFirstName('First Name1')
			.setLastName('Last Name1')
			.setEmail('testuser1@firstcontact.com')
			.build();
		insert objContact;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objCompAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('MF QLE')
			.setType('QLE')
			.setSubject('Test  MF QLE  Case')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Test MF QLE Case')
			.build();
		insert objCase;

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder().setParentId(objCase.Id).setToAddress('testemail@test.com').setIncoming(true).build();
		insert objEmailMessage;

		TriggerHandler.clearAllBypasses();
	}

	@isTest
	static void testSendFirstRFI() {
		Case objCase = [SELECT Id, QLE_RFI_Type__c, RFI_TYPE__C, Insufficient_Proof_Reason__c FROM Case LIMIT 1];
		objCase.QLE_RFI_Type__c = 'Change of address';
		objCase.RFI_TYPE__C = 'Request for proof of birth';
		objCase.Insufficient_Proof_Reason__c = 'Proof';
		Test.startTest();
		CaseQLERFIController.sendFirstRFI(objCase);
		Test.stopTest();
		objCase = [SELECT Id, RFI_Status__c, QLE_RFI_Type__c, RFI_TYPE__C, Insufficient_Proof_Reason__c FROM Case LIMIT 1];
		System.assertEquals(QLERFIAutomateEmailUtils.STATUS_RFI_1, objCase.RFI_Status__c);
		System.assertEquals('Change of address', objCase.QLE_RFI_Type__c);
		System.assertEquals('Request for proof of birth', objCase.RFI_TYPE__C);
		System.assertEquals('Proof', objCase.Insufficient_Proof_Reason__c);
	}
}