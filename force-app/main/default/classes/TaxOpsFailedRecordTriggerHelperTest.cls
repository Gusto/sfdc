@isTest
private class TaxOpsFailedRecordTriggerHelperTest {
	@testSetup
	static void setupDataMethod() {
		User objAdminUser = new TestDataFactory.UserBuilder()
			.setEmail('test@testorg.com')
			.setFirstName('Test')
			.setLastName('user')
			.setProfileId(TestDataFactory.objZPSysAdminProfile.Id)
			.setUserName('Implementation.AdvocateNew@test.Implementation')
			.setExemptfromValidationRules(true)
			.build();
		insert objAdminUser;

		Agency_Information__c agencyInfo = new Agency_Information__c();
		agencyInfo.Name = 'Ohio Business Gateway Test';
		agencyInfo.Tax_Code__c = 'OH000-001, OHIO_IT-3, OHIO_IT-501, OHIO_IT-941, OHIO_IT-942, OHIO_SD-101, OHIO_SD-141';
		agencyInfo.Agency_Rep__c = objAdminUser.Id;
		insert agencyInfo;

		Tax_Ops_Task__c tskObj = new Tax_Ops_Task__c();
		tskObj.Tax_Code__c = 'OH000-001';
		tskObj.Process_step__c = 'Payments';
		tskObj.Failed_Payment_Account_Numbers__c = 'FailedPayment123,FailedPayment1234';
		insert tskObj;
	}

	@isTest
	static void insertCheckMethod() {
		list<Tax_Ops_Task__c> taxOpsRecList = [SELECT id, Tax_Code__c FROM Tax_Ops_Task__c];

		list<Tax_Ops_Failed_Record__c> failedRecList = new List<Tax_Ops_Failed_Record__c>();

		Tax_Ops_Failed_Record__c failRec = new Tax_Ops_Failed_Record__c();
		//failRec.Tax_Code__c = taxOpsRecList.get(0).Tax_Code__c;
		failRec.Tax_Ops_Task__c = taxOpsRecList.get(0).id;
		failRec.Account_Number__c = 'FailedPayment123';
		failRec.recordTypeId = cache.getRecordTypeId('Tax_Ops_Failed_Record__c', 'Failed Payment');
		failRec.FEIN__c = 'test 1';
		failedRecList.add(failRec);

		Tax_Ops_Failed_Record__c failRec2 = new Tax_Ops_Failed_Record__c();
		//failRec2.Tax_Code__c = taxOpsRecList.get(0).Tax_Code__c;
		failRec2.Tax_Ops_Task__c = taxOpsRecList.get(0).id;
		failRec2.Account_Number__c = 'FailedPayment1234';
		failRec2.recordTypeId = cache.getRecordTypeId('Tax_Ops_Failed_Record__c', 'Failed Payment');
		failRec2.Account_Number__c = 'test 2';
		failedRecList.add(failRec2);

		insert failedRecList;

		failedRecList = [SELECT id FROM Tax_Ops_Failed_Record__c];
		System.assert(failedRecList.size() == 2, 'There should be 2 Tax_Ops_Failed_Record__c records.');

		update failedRecList;

		delete failedRecList;
	}
}