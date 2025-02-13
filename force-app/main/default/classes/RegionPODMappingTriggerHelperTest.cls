/**
 * @name         RegionPODMappingTriggerHelperTest
 * @author       Anand Singh
 * @date         14th Oct 2021
 * @description  Test class for RegionPODMappingTriggerHelper class.
 **/
@isTest
private class RegionPODMappingTriggerHelperTest {
	/**
	 * @Author      : Anand Singh
	 * @Description : Test Class setup method
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@testSetup
	static void setupData() {
		Utils.skipTrigger(true);

		//For Notice Analyst
		List<Agency_Information__c> list_AgencyInformations = TestDataFactory.CreateAgencyInformation();
		Region_POD__c objNARegionPOD = TestDataFactory.CreateAgencyRegion(
			'Test AS Region',
			RegionPODMappingTriggerHelper.ACCOUNT_SPECIALIST
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
	static testMethod void testRegionPODMappingTriggerHelperPostiveCase() {
		Test.startTest();
		//get Agency and Create new POD Mapping
		List<Agency_Information__c> list_AgencyInformations = [SELECT ID FROM Agency_Information__c];
		//Get NA Region POD
		Region_POD__c objNARegionPOD = [
			SELECT ID
			FROM Region_POD__c
			WHERE Team__c = :RegionPODMappingTriggerHelper.ACCOUNT_SPECIALIST
		];

		//Create new Region POD Mapping
		List<Region_POD_mapping__c> list_NARegionPODMappings = TestDataFactory.CreateAgencyRegionPODMapping(
			objNARegionPOD,
			list_AgencyInformations
		);
		update [SELECT ID FROM Region_POD_mapping__c];

		RegionPODMappingTriggerHelper.blnSkipTrigger = true;
		update [SELECT ID FROM Region_POD_mapping__c];
		delete [SELECT ID FROM Region_POD_mapping__c];
		RegionPODMappingTriggerHelper.blnSkipTrigger = false;
		RegionPODMappingTriggerHandler.resetSkipTriggerFlags();
		RegionPODMappingTriggerHandler objHandler = new RegionPODMappingTriggerHandler();
		objHandler.beforeDelete();
		objHandler.afterDelete();
		Test.stopTest();

		List<Case> list_CasesTemp = [
			SELECT Id, Account_Specialist_POD__c
			FROM Case
			WHERE RecordType.Name = 'Tax Res'
			LIMIT 1
		];

		System.assert(list_CasesTemp.size() > 0);
		System.assert(list_CasesTemp[0].Account_Specialist_POD__c != null);
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Forecast POD for new case
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void testRegionPODMappingTriggerHelperNegativeCase() {
		Test.startTest();
		//For Notice Analyst
		List<Agency_Information__c> list_AgencyInformationsTemp = [SELECT ID FROM Agency_Information__c];

		//For Account Specilaist
		Region_POD__c objASRegionPODTemp = TestDataFactory.CreateAgencyRegion(
			'Test AS Region',
			'Coordinator'
		);

		List<Region_POD_mapping__c> list_ASRegionPODMappings = TestDataFactory.CreateAgencyRegionPODMapping(
			objASRegionPODTemp,
			list_AgencyInformationsTemp
		);
		Test.stopTest();

		List<Case> list_CasesTemp = [
			SELECT Id, Account_Specialist_POD__c
			FROM Case
			WHERE RecordType.Name = 'Tax Res'
			LIMIT 1
		];

		System.assert(list_CasesTemp.size() > 0);
		System.assert(list_CasesTemp[0].Account_Specialist_POD__c == null);
	}
}