/**
 * @name         : ChimaChatInternalWidgetCtrlTest
 * @author       : Yogesh Kherajani
 * @date         : 24/04/2024
 * @description  : This class has test methods for ChimaChatInternalWidgetCtrl
 **/
@isTest
public class ChimaChatInternalWidgetCtrlTest {
	/**
	 * @Author      : Yogesh Kherajani
	 * @Description : This method creates all the test data.
	 **/
	@testSetup
	private static void setupData() {
		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		//Account creation
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setName('TestAccount')
			.setZPCompanyId('12312321')
			.setZPFirmId('12312321')
			.setConciergeGroupId('test')
			.setConciergeGroup('test')
			.setTier(objTierConfig.New_Tier_2__c)
			.setAMTier('Gold')
			.setRecordTypeId('Company')
			.build();
		AccountTriggerHelper.skipTrigger = true;
		insert objAccount;

		//Contact creation
		Contact objContact = new TestDataFactory.ContactBuilder().setAccountId(objAccount.Id).setLastName('TestContact').setRecordTypeId('Company').setZPUserId('12312321').build();
		ContactTriggerHelper.skipTrigger = true;
		insert objContact;

		//Case creation
		Case objCase = new TestDataFactory.CaseBuilder()
			.setSubject('Om Test')
			.setStatus('New')
			.setOrigin('Email')
			.setSuppliedEmail('test@gmail.com')
			.setRecordTypeId('Payroll Care')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.build();
		CaseTriggerHelper.skipTrigger = true;
		insert objCase;
	}

	/**
	 * @Author      : Yogesh Kherajani
	 * @Description : To test the ChimaChatInternalWidgetCtrl constructor.
	 **/
	@isTest
	private static void chimaChatInternalWidgetCtrlUnitTest() {
		Case objCase = [
			SELECT Id
			FROM Case
			LIMIT 1
		];

		PageReference objChimaChatInternalWidgetVFPage = Page.ChimaChatInternalWidget;
		Test.setCurrentPage(objChimaChatInternalWidgetVFPage);

		objChimaChatInternalWidgetVFPage.getParameters().put('recordId', objCase.Id);

		ApexPages.StandardController objStandardCtrl = new ApexPages.StandardController(objCase);
		ChimaChatInternalWidgetCtrl objChimaChatInternalWidgetCtrl = new ChimaChatInternalWidgetCtrl(objStandardCtrl);

		System.assert(objChimaChatInternalWidgetCtrl.idChatTranscriptRecordType != null, 'Live Chat Transcript should have Internal Record Type');
		System.assert(objChimaChatInternalWidgetCtrl.objChatWrapper.strCaseRecId != null, 'Chat Wrapper should contain case record Id');
	}
}