@isTest
public class TaxOpsTaskPageExtensionTest {
	@testSetup 
    static void setUp() {
        Account accRec1 = new Account();
    	accRec1.Name = 'Test Demo AccountName 1';
    	accRec1.BillingStreet = 'Testing Avenue 1';
    	accRec1.BillingPostalCode = '123456';
    	accRec1.Company_Trade_Name__c = 'Company trade name 1';
    	accRec1.Phone = '19992344444';
    	accRec1.ShippingStreet = 'Testing Avenue 1';
    	accRec1.ShippingPostalCode = '123455';
    	accRec1.ZP_Company_ID__c = '758373';
    	insert accRec1;
        
        Tax_Ops_Task__c tskObj = new Tax_Ops_Task__c();
		tskObj.Tax_Code__c = 'OH000-001';
		tskObj.Process_step__c = 'Payments';
        tskObj.Status__c = 'New';
		insert tskObj;
        
        Tax_Ops_Task__c tsk2Obj = new Tax_Ops_Task__c();
		tsk2Obj.Tax_Code__c = 'OH000-002';
		tsk2Obj.Process_step__c = 'Payments';
        tsk2Obj.Status__c = 'New';
        tsk2Obj.Skip_Save__c = true;
		insert tsk2Obj;  
        
        Blob key = EncryptionUtils.generateKey('Master');
        ZP_Company_Tax_Code_EIN__c obj = new ZP_Company_Tax_Code_EIN__c();
        obj.Account_Number__c = '127483';
        obj.FEIN__c = '758373';
        obj.Reference_Ein__c = '1234112';
        obj.Tax_Code__c = 'OH000-001';
        obj.ZP_Company_ID__c = '758373';
        insert obj;
    }
    
    static testMethod void testupdateTaskStatus() {
    	Tax_Ops_Task__c tskObj1 = [Select Id, OwnerId, Process_step__c, Tax_Code__c, Failed_Payment_FEINs__c, Failed_Payment_Account_Numbers__c From Tax_Ops_Task__c Where Tax_Code__c =: 'OH000-001'];
    	
        ApexPages.StandardController stdController = new ApexPages.StandardController(tskObj1);
        TaxOpsTaskPageExtension ctrlObj = new TaxOpsTaskPageExtension(stdController);
        ctrlObj.csvFileBody = Blob.valueOf('Testing');
        ctrlObj.saveRec();
        ctrlObj.updateTaskStatus();
        ctrlObj.uploadFailedRecCsv();
        
        tskObj1 = [Select Id, OwnerId, Process_step__c, Tax_Code__c, Status__c From Tax_Ops_Task__c Where Id = : tskObj1.Id];
        system.assertEquals(tskObj1.Status__c, 'In Progress');
    } 
    
    static testMethod void testmoveToInprogress() {
    	Tax_Ops_Task__c tskObj1 = [Select Id, OwnerId, Process_step__c, Tax_Code__c, Failed_Payment_FEINs__c, Failed_Payment_Account_Numbers__c From Tax_Ops_Task__c Where Tax_Code__c =: 'OH000-001'];
    	ApexPages.StandardController stdController = new ApexPages.StandardController(tskObj1);
        TaxOpsTaskPageExtension ctrlObj = new TaxOpsTaskPageExtension(stdController);
        ctrlObj.saveRec();
        ctrlObj.moveToInprogress();
        
        tskObj1 = [Select Id, OwnerId, Process_step__c, Tax_Code__c, Status__c From Tax_Ops_Task__c Where Id = : tskObj1.Id];
        system.assertEquals(tskObj1.Status__c, 'In Progress');
        
        ctrlObj.moveToOpen();
        
        tskObj1 = [Select Id, OwnerId, Process_step__c, Tax_Code__c, Status__c From Tax_Ops_Task__c Where Id = : tskObj1.Id];
        system.assertEquals(tskObj1.Status__c, 'Open');
    }	
    
    static testMethod void testCheckUploadInprogress() {
    	Tax_Ops_Task__c tskObj1 = [Select Id, OwnerId, Process_step__c, Tax_Code__c, Failed_Payment_FEINs__c, Failed_Payment_Account_Numbers__c,CSV_File_Processing__c From Tax_Ops_Task__c Where Tax_Code__c =: 'OH000-001'];    	
        ApexPages.StandardController stdController = new ApexPages.StandardController(tskObj1);
        TaxOpsTaskPageExtension ctrlObj = new TaxOpsTaskPageExtension(stdController);    
    	ctrlObj.checkUploadInprogress();
        tskObj1 = [Select Id, OwnerId, Process_step__c, Tax_Code__c, Status__c,CSV_File_Processing__c From Tax_Ops_Task__c Where Id = : tskObj1.Id];
        system.assertEquals(ctrlObj.isUploadInprogress, tskObj1.CSV_File_Processing__c);        
    }

    static testMethod void testSaveRec() {
    	Tax_Ops_Task__c tskObj1 = [Select Id, Skip_Save__c,OwnerId, Process_step__c, Tax_Code__c, Failed_Payment_FEINs__c, Failed_Payment_Account_Numbers__c,CSV_File_Processing__c From Tax_Ops_Task__c Where Tax_Code__c =: 'OH000-002'];    	
        ApexPages.StandardController stdController = new ApexPages.StandardController(tskObj1);
        TaxOpsTaskPageExtension ctrlObj = new TaxOpsTaskPageExtension(stdController);    
    	ctrlObj.saveRec();
        ctrlobj.setVoid();
        tskObj1 = [Select Id, Skip_Save__c,OwnerId, Process_step__c, Tax_Code__c, Status__c,CSV_File_Processing__c From Tax_Ops_Task__c Where Id = : tskObj1.Id];
        system.assertEquals(tskObj1.Skip_Save__c, true);        
    }
    
}