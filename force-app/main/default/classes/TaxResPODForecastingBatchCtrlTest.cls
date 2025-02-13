/**
 * @name         TaxResPODForecastingBatchCtrlTest
 * @author       Anand Singh
 * @date         14th Oct 2021
 * @description  Test class for TaxResPODForecastingBatchCtrl class.
 **/
@isTest
private class TaxResPODForecastingBatchCtrlTest {
	/**
	 * @Author      : Anand Singh
	 * @Description : Test Class setup method
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@testSetup
	static void setupData() {
		Utils.skipTrigger(true);

        //For Account Specilaist
		List<Agency_Information__c> list_AgencyInformations = TestDataFactory.CreateAgencyInformation();
		Region_POD__c objASRegionPOD = TestDataFactory.CreateAgencyRegion(
			'Test AS Region',
			TaxResPODForecastingBatchCtrl.ACCOUNT_SPECIALIST
		);

		List<Region_POD_mapping__c> list_ASRegionPODMappings = TestDataFactory.CreateAgencyRegionPODMapping(
			objASRegionPOD,
			list_AgencyInformations
		);

		Account objAccount = TestUtility.CompanyAccount();

		Contact objContact = new Contact(
			FirstName = 'Test',
			LastName = 'User01',
			recordTypeId = ContactUtil.COMPANY_CONTACT_RT_ID,
			AccountId = objAccount.Id,
			Email = 'testuser01@gusto.com',
			Zp_User_Id__c = '75001'
		);
		insert objContact;

		List<Case> list_Cases = new List<Case>();
		list_Cases.add(TestUtility.createCase(objAccount.Id, null, 'Tax Res'));
		list_Cases[0].Status = 'Research in progress';
		list_Cases[0].Agency_Information__c = list_AgencyInformations[0].Id;
		list_Cases[0].ContactId = objContact.Id;

		insert list_Cases;

		Utils.skipTrigger(false);
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Forecast POD for new case
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void testTaxResPODForecasePostiveCase() {
		Test.startTest();
		TaxResPODForecastingBatchCtrl objSchedule = new TaxResPODForecastingBatchCtrl();
		String strSchedule = '0 0 23 * * ?';
		system.schedule('Test', strSchedule, objSchedule);

		TaxResPODForecastingBatchCtrl objCommBatch = new TaxResPODForecastingBatchCtrl();
    	Database.executeBatch(objCommBatch, 1);

		Test.stopTest();

		List<Case> list_CasesTemp = [SELECT Id,  Account_Specialist_POD__c
				FROM Case WHERE RecordType.Name = 'Tax Res' LIMIT 1];

		System.assert(list_CasesTemp.size() > 0);
		System.assert(list_CasesTemp[0].Account_Specialist_POD__c != null);
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Forecast POD for new case : Negative Case.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void testTaxResPODForecaseNegativeCase() {
		Test.startTest();
        
        CaseTriggerHelper.skipTrigger = true;
		List<Case> list_Cases = [SELECT Id,Agency_Information__c FROM Case WHERE RecordType.Name = 'Tax Res'];
		if (list_Cases?.size() > 0) {
			list_Cases[0].Agency_Information__c = null;
			update list_Cases[0];
		}
        
		TaxResPODForecastingBatchCtrl objCommBatch = new TaxResPODForecastingBatchCtrl();
		Database.executeBatch(objCommBatch, 1);

		Test.stopTest();

		System.assert(
			[SELECT Id, Account_Specialist_POD__c FROM Case WHERE RecordType.Name = 'Tax Res' LIMIT 1]
			.Account_Specialist_POD__c == null
		);
	}
}