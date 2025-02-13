@isTest
public class TaxOpsFailedRecordsCreationCtrlTest {
	
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
		
		Tax_Ops_Task__c tskObj2 = new Tax_Ops_Task__c();
		tskObj2.Tax_Code__c = 'OH000-003';
		tskObj2.Process_step__c = 'Filing';
		tskList.add(tskObj2);
		
		insert tskList;
        
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
        obj.Account_Number__c = '127483';
        obj.FEIN__c = '758373';
        obj.Reference_Ein__c = '1234112';
        obj.Tax_Code__c = 'OH000-001';
        obj.ZP_Company_ID__c = '5464365436434';
        insert obj;
    	
    	Contact contact = new Contact();
        contact.RecordTypeId = Cache.getRecordTypeId('Contact', 'Company');
        contact.Phone = '1234567890';
        contact.FirstName = 'Test';
        contact.LastName = 'TestEngagementCaseViewExtension';            
        contact.AccountId = accRec1.id;
        contact.Email = 'EngagementUser@gusto1.com';
        insert contact;
    	
    	ZP_User__c zpUser = new ZP_User__c();
        zpUser.Name = 'EngagementCaseView TestUser';
        zpUser.Created_At__c = system.today();
        zpUser.Updated_At__c = system.today();
        zpUser.Id__c = 'EngagementCaseViewUser1';
        zpUser.Email__c = 'EngagementUser@gusto1.com';
        insert zpUser;
    	
    	List<ZP_User_Role__c> userRoleList = new List<ZP_User_Role__c>();
    	ZP_User_Role__c userRole = new ZP_User_Role__c();
        userRole.User_Id__c = zpUser.Id__c;
        userRole.Company_Id__c = '5464365436434';
        userRole.First_Name__c = 'EngagementCaseView';
        userRole.Last_Name__c = 'TestUser';
        userRole.User_Permissions__c = 'full_access;';
        userRole.Type__c = 'Role::PayrollAdmin';
        userRole.Is_Primary__c = true;
        userRoleList.add(userRole);
        
        ZP_User_Role__c userRole1 = new ZP_User_Role__c();
        userRole1.User_Id__c = zpUser.Id__c;
        userRole1.Company_Id__c = '5464365436434';
        userRole1.First_Name__c = 'EngagementCaseView';
        userRole1.Last_Name__c = 'TestUser';
        userRole1.User_Permissions__c = 'full_access;';
        userRole1.Type__c = 'Role::PayrollAdmin';
        userRoleList.add(userRole1);
        
        insert userRoleList;
    }
    
    @isTest
    static  void testSyncFailedRecordsFP() {
    	List<Tax_Ops_Task__c> tskOpsList = [Select Id, OwnerId, Process_step__c, Tax_Code__c, Failed_Payment_FEINs__c, Failed_Payment_Account_Numbers__c From Tax_Ops_Task__c Where Process_step__c =: 'Payments'];
    	Contact con = [Select Id, Email From Contact Where Email = 'EngagementUser@gusto1.com'];
    	List<Tax_Ops_Failed_Record__c> failedRecordList = new List<Tax_Ops_Failed_Record__c>();
    	Tax_Ops_Failed_Record__c failedRecord = new Tax_Ops_Failed_Record__c();
    	failedRecord.Tax_Ops_Task__c = tskOpsList[0].Id;
    	failedRecord.FEIN__c = '1234112';
    	failedRecord.Account_Number__c = '1234112';
    	failedRecord.CC_Ids__c = con.Id;
        failedRecord.Inactive__c = false;
        failedRecord.recordTypeId = cache.getRecordTypeId('Tax_Ops_Failed_Record__c','Failed Payment');
        failedRecordList.add(failedRecord);
        
        Tax_Ops_Failed_Record__c failedRecord1 = new Tax_Ops_Failed_Record__c();
    	failedRecord1.Tax_Ops_Task__c = tskOpsList[0].Id;
    	failedRecord1.FEIN__c = '1234112';
    	failedRecord1.Account_Number__c = '1234112';
        failedRecord1.Inactive__c = false;
        failedRecord1.CC_Ids__c = con.Id;
        failedRecord1.recordTypeId = cache.getRecordTypeId('Tax_Ops_Failed_Record__c','Failed Payment');
        failedRecordList.add(failedRecord1);
    	insert failedRecordList;
    	
    	ApexPages.StandardSetController stdController = new ApexPages.StandardSetController(tskOpsList);
        TaxOpsFailedRecordsCreationController ctrlObj = new TaxOpsFailedRecordsCreationController(stdController);
        apexPages.currentPage().getParameters().put('id', tskOpsList[0].Id);
        apexPages.currentPage().getParameters().put('rtnm', 'fp');
        apexPages.currentPage().getParameters().put('syncrec', '1');
        ctrlObj.sortField = 'Name';
        ctrlObj.selectedFilterStr = 'FEIN__c';
        ctrlObj.filterStr = '1234112';
        ctrlObj.selectedRecIdStr = failedRecordList[1].Id;
    	ctrlObj.syncFailedRecords();
    	ctrlObj.selectedFailedRecordList.get(0).Inactive__c = true;
    	ctrlObj.isCommonUpdate = true;
        ctrlObj.massUpdate();
        ctrlObj.saveEmailBody = true;
        ctrlObj.populateEmailBodySampleToFailedRecords();
        ctrlObj.sendEmailMessageForTaxOpsFailedRecords(failedRecordList);
        List<Tax_Ops_Failed_Record__c> UpdatedfailedRecordList = [Select Id, CC_Address__c From Tax_Ops_Failed_Record__c Where Tax_Ops_Task__c =: tskOpsList[0].Id];
        system.assertEquals(UpdatedfailedRecordList[0].CC_Address__c, con.Email);
    } 
    
    @isTest
    static void testSyncFailedRecordsFF() {
    	List<Tax_Ops_Task__c> tskOpsList = [Select Id, OwnerId, Process_step__c, Tax_Code__c, Failed_Payment_FEINs__c, Failed_Payment_Account_Numbers__c From Tax_Ops_Task__c Where Process_step__c =: 'Filing'];
    	List<Tax_Ops_Failed_Record__c> failedRecordList = new List<Tax_Ops_Failed_Record__c>();
    	Tax_Ops_Failed_Record__c failedRecord = new Tax_Ops_Failed_Record__c();
    	failedRecord.Tax_Ops_Task__c = tskOpsList[0].Id;
    	failedRecord.FEIN__c = '1234112';
    	failedRecord.Account_Number__c = '1234112';
        failedRecord.Inactive__c = false;
        failedRecord.recordTypeId = cache.getRecordTypeId('Tax_Ops_Failed_Record__c','Failed Filing');
        failedRecordList.add(failedRecord);
        
        Tax_Ops_Failed_Record__c failedRecord1 = new Tax_Ops_Failed_Record__c();
    	failedRecord1.Tax_Ops_Task__c = tskOpsList[0].Id;
    	failedRecord1.FEIN__c = '1234112';
    	failedRecord1.Account_Number__c = '1234112';
        failedRecord1.Inactive__c = false;
        failedRecord1.recordTypeId = cache.getRecordTypeId('Tax_Ops_Failed_Record__c','Failed Filing');
        failedRecordList.add(failedRecord1);
    	insert failedRecordList;
    	
    	ApexPages.StandardSetController stdController = new ApexPages.StandardSetController(tskOpsList);
        TaxOpsFailedRecordsCreationController ctrlObj = new TaxOpsFailedRecordsCreationController(stdController);
        apexPages.currentPage().getParameters().put('id', tskOpsList[0].Id);
        apexPages.currentPage().getParameters().put('rtnm', 'ff');
        apexPages.currentPage().getParameters().put('syncrec', '1');
        ctrlObj.selectedRecIdStr = failedRecordList[1].Id;
    	ctrlObj.syncFailedRecords();
    	ctrlObj.selectedFailedRecordList.get(0).Inactive__c = true;
    	ctrlObj.isCommonUpdate = true;
        ctrlObj.massUpdate();
        ctrlObj.saveAndPrevious();
        ctrlObj.saveAndNext();
        ctrlObj.createAttachFailedRec();
        
        Attachment attach = [Select Id From Attachment Where ParentId =: tskOpsList[0].Id LIMIT 1];
    	system.assert(attach.Id != null);
    }
    
    @isTest
    static void testpopulateContactForTaxOpsFailedRecords() {
    	List<Tax_Ops_Task__c> tskOpsList = [Select Id, OwnerId, Process_step__c, Tax_Code__c, Failed_Payment_FEINs__c, Failed_Payment_Account_Numbers__c From Tax_Ops_Task__c Where Process_step__c =: 'Filing'];
    	
        Account accRec = [select Id, ZP_Company_ID__c From Account Where ZP_Company_ID__c = '5464365436434'];
        
        List<Tax_Ops_Failed_Record__c> failedRecordList = new List<Tax_Ops_Failed_Record__c>();
    	Tax_Ops_Failed_Record__c failedRecord = new Tax_Ops_Failed_Record__c();
    	failedRecord.Tax_Ops_Task__c = tskOpsList[0].Id;
    	failedRecord.FEIN__c = '1234112';
    	failedRecord.Account_Number__c = '1234112';
        failedRecord.Inactive__c = true;
        failedRecord.Account__c = accRec.Id;
        failedRecord.recordTypeId = cache.getRecordTypeId('Tax_Ops_Failed_Record__c','Failed Payment');
        failedRecordList.add(failedRecord);
        
        Tax_Ops_Failed_Record__c failedRecord1 = new Tax_Ops_Failed_Record__c();
    	failedRecord1.Tax_Ops_Task__c = tskOpsList[0].Id;
    	failedRecord1.FEIN__c = '1234112';
    	failedRecord1.Account_Number__c = '1234112';
        failedRecord1.Inactive__c = false;
        failedRecord1.recordTypeId = cache.getRecordTypeId('Tax_Ops_Failed_Record__c','Failed Payment');
        failedRecordList.add(failedRecord1);
    	insert failedRecordList;
    	
    	ApexPages.StandardSetController stdController = new ApexPages.StandardSetController(tskOpsList);
        TaxOpsFailedRecordsCreationController ctrlObj = new TaxOpsFailedRecordsCreationController(stdController);
        ctrlObj.populateContactForTaxOpsFailedRecords(failedRecordList);
        //Blob key = EncryptionUtils.generateKey('Master');
        //String DecryptedStr = ctrlObj.getEncryptStr('345356');
        //ctrlObj.getDecryptedStr(DecryptedStr);
    }
    
    @isTest
    static void testSyncFailedRecordsFFWithoutAccNum() {
    	List<Tax_Ops_Task__c> tskOpsList = [Select Id, OwnerId, Process_step__c, Tax_Code__c, Failed_Payment_FEINs__c, Failed_Payment_Account_Numbers__c From Tax_Ops_Task__c Where Tax_Code__c = 'OH000-003'];
    	
        Account accRec = [select Id, ZP_Company_ID__c From Account Where ZP_Company_ID__c = '5464365436434'];
        
        List<Tax_Ops_Failed_Record__c> failedRecordList = new List<Tax_Ops_Failed_Record__c>();
    	Tax_Ops_Failed_Record__c failedRecord = new Tax_Ops_Failed_Record__c();
    	failedRecord.Tax_Ops_Task__c = tskOpsList[0].Id;
    	failedRecord.FEIN__c = '1234112';
    	failedRecord.Account_Number__c = '1234112';
        failedRecord.Inactive__c = true;
        failedRecord.Account__c = accRec.Id;
        failedRecord.recordTypeId = cache.getRecordTypeId('Tax_Ops_Failed_Record__c','Failed Filing');
        failedRecordList.add(failedRecord);
        
        Tax_Ops_Failed_Record__c failedRecord1 = new Tax_Ops_Failed_Record__c();
    	failedRecord1.Tax_Ops_Task__c = tskOpsList[0].Id;
    	failedRecord1.FEIN__c = '1234112';
    	failedRecord1.Account_Number__c = '1234112';
        failedRecord1.Inactive__c = false;
        failedRecord1.recordTypeId = cache.getRecordTypeId('Tax_Ops_Failed_Record__c','Failed Filing');
        failedRecordList.add(failedRecord1);
    	insert failedRecordList;
    	
    	ApexPages.StandardSetController stdController = new ApexPages.StandardSetController(tskOpsList);
        TaxOpsFailedRecordsCreationController ctrlObj = new TaxOpsFailedRecordsCreationController(stdController);
        apexPages.currentPage().getParameters().put('id', tskOpsList[0].Id);
        apexPages.currentPage().getParameters().put('rtnm', 'ff');
        apexPages.currentPage().getParameters().put('syncrec', '1');
        ctrlObj.createTaxOpsFailedRec_v2();
        ctrlObj.selectedRecIdStr = failedRecordList[1].Id;
    	ctrlObj.syncFailedRecords();
    	ctrlObj.isCommonUpdate = true;
        ctrlObj.massUpdate();
        
        List<Tax_Ops_Failed_Record__c> UpdatedfailedRecordList = [Select Id, Inactive__c From Tax_Ops_Failed_Record__c Where Tax_Ops_Task__c =: tskOpsList[0].Id];
        system.assertEquals(UpdatedfailedRecordList[0].Inactive__c, true);
    }
}