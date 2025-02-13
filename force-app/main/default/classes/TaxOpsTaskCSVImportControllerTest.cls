@isTest
public class TaxOpsTaskCSVImportControllerTest {
	
	@testSetup 
    static void setUp() {
    	List<Tax_Ops_Task__c> tskList = new List<Tax_Ops_Task__c>();
        Tax_Ops_Task__c tskObj = new Tax_Ops_Task__c();
		tskObj.Tax_Code__c = 'OH000-001';
		tskObj.Process_step__c = 'Payments';
		tskObj.Failed_Payment_Account_Numbers__c = '1234112,758373,127483';
		tskObj.Failed_Payment_FEINs__c = '1234112,758373,127483';
		
		tskList.add(tskObj);
		
		Tax_Ops_Task__c tskObj1 = new Tax_Ops_Task__c();
		tskObj1.Tax_Code__c = 'OH000-002';
		tskObj1.Process_step__c = 'Filing';
		tskObj1.Failed_Filing_FEINs__c = '1234112,758373,127483';
		tskObj1.Failed_Filing_Account_Numbers__c = '1234112,758373,127483';
		tskList.add(tskObj1);
		
		insert tskList;
    }
    
     static testMethod void testsaveChildDetailsAsCSVAttachment() {
    	List<Tax_Ops_Task__c> tskOpsList = [Select Id, OwnerId, Process_step__c, Tax_Code__c, Failed_Payment_FEINs__c, Failed_Payment_Account_Numbers__c From Tax_Ops_Task__c Where Process_step__c =: 'Filing'];
    	
    	ApexPages.StandardController stdController = new ApexPages.StandardController(tskOpsList[0]);
        TaxOpsTaskCSVImportController ctrlObj = new TaxOpsTaskCSVImportController(stdController);
    	ctrlObj.saveChildDetailsAsCSVAttachment();
    	
    	Attachment attach = [Select Id From Attachment Where ParentId =: tskOpsList[0].Id LIMIT 1];
    	system.assert(attach.Id != null);
     }
     
     static testMethod void testgatherCSVData() {
    	List<Tax_Ops_Task__c> tskOpsList = [Select Id, OwnerId, Process_step__c, Tax_Code__c, Failed_Payment_FEINs__c, Failed_Payment_Account_Numbers__c From Tax_Ops_Task__c Where Process_step__c =: 'Filing'];
    	    	List<Tax_Ops_Failed_Record__c> failedRecordList = new List<Tax_Ops_Failed_Record__c>();
    	Tax_Ops_Failed_Record__c failedRecord = new Tax_Ops_Failed_Record__c();
    	failedRecord.Tax_Ops_Task__c = tskOpsList[0].Id;
    	failedRecord.FEIN__c = '1234112';
    	failedRecord.Account_Number__c = '1234112';
        failedRecord.Inactive__c = false;
        failedRecordList.add(failedRecord);
        
        Tax_Ops_Failed_Record__c failedRecord1 = new Tax_Ops_Failed_Record__c();
    	failedRecord1.Tax_Ops_Task__c = tskOpsList[0].Id;
    	failedRecord1.FEIN__c = '1234112';
    	failedRecord1.Account_Number__c = '1234112';
        failedRecord1.Inactive__c = false;
        failedRecordList.add(failedRecord1);
    	insert failedRecordList;

    	apexPages.currentPage().getParameters().put('id', tskOpsList[0].Id);
        TaxOpsTaskCSVImportController ctrlObj = new TaxOpsTaskCSVImportController();
     }
}