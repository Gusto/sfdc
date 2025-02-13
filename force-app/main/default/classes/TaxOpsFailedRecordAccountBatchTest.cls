@isTest
private class TaxOpsFailedRecordAccountBatchTest {
	@testSetup
	static void itShould() {
		Tax_Ops_Task__c tskObj = new Tax_Ops_Task__c();
		tskObj.Tax_Code__c = 'OH000-001';
		tskObj.Process_step__c = 'Payments';
		tskObj.Failed_Payment_Account_Numbers__c = '1234112,1231243';
		tskObj.Failed_Payment_FEINs__c = '127483';
		insert tskObj;

		Account accRec1 = new Account();
		accRec1.Name = 'Test Demo AccountName 1';
		accRec1.BillingStreet = 'Testing Avenue 1';
		accRec1.BillingPostalCode = '123456';
		accRec1.Company_Trade_Name__c = 'Company trade name 1';
		accRec1.Phone = '19992344444';
		accRec1.ShippingStreet = 'Testing Avenue 1';
		accRec1.ShippingPostalCode = '123455';
		accRec1.ZP_Company_ID__c = '5464365436434';
		insert accRec1;

		Blob key = EncryptionUtils.generateKey('Master');
		ZP_Company_Tax_Code_EIN__c obj = new ZP_Company_Tax_Code_EIN__c();
		obj.Account_Number__c = '1234112';
		obj.FEIN__c = '127483';
		obj.Reference_Ein__c = '1231243';
		obj.Tax_Code__c = 'OH000-001';
		obj.ZP_Company_ID__c = '5464365436434';
        obj.FEIN_Encrypt__c = '5464365436434';
        obj.Account_Number_Encrypt__c = '5464365436434';
        obj.Reference_Ein_Encrypt__c = '5464365436434';
		insert obj;
	}

	@isTest
	static void checkBatchRun() {
		List<Tax_Ops_Task__c> tskOpsList = [
			SELECT Id, OwnerId, Process_step__c, Tax_Code__c, Failed_Payment_FEINs__c, Failed_Payment_Account_Numbers__c
			FROM Tax_Ops_Task__c
			WHERE Process_step__c = :'Payments'
		];

		List<Tax_Ops_Failed_Record__c> failedRecordList = new List<Tax_Ops_Failed_Record__c>();
		Tax_Ops_Failed_Record__c failedRecord = new Tax_Ops_Failed_Record__c();
		failedRecord.Tax_Ops_Task__c = tskOpsList[0].Id;
		failedRecord.FEIN__c = '127483';
		failedRecord.Inactive__c = false;
		failedRecord.recordTypeId = cache.getRecordTypeId('Tax_Ops_Failed_Record__c', 'Failed Payment');
		failedRecordList.add(failedRecord);

		Tax_Ops_Failed_Record__c failedRecord1 = new Tax_Ops_Failed_Record__c();
		failedRecord1.Tax_Ops_Task__c = tskOpsList[0].Id;
		failedRecord1.Account_Number__c = '5464365436434';
		failedRecord1.Inactive__c = false;
		failedRecord1.recordTypeId = cache.getRecordTypeId('Tax_Ops_Failed_Record__c', 'Failed Payment');
		failedRecordList.add(failedRecord1);
		insert failedRecordList;

		test.startTest();
		TaxOpsFailedRecordAccountAssignmentBatch cntrl = new TaxOpsFailedRecordAccountAssignmentBatch();
		database.executeBatch(cntrl, 1);
		test.stopTest();
        cntrl.decodeStr('test');
        
	}
}