@isTest
public class csvParserTest {
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
        
        Blob key = EncryptionUtils.generateKey('Master');
        ZP_Company_Tax_Code_EIN__c obj = new ZP_Company_Tax_Code_EIN__c();
        obj.Account_Number__c = '127483';
        obj.FEIN__c = '758373';
        obj.Reference_Ein__c = '1234112';
        obj.Tax_Code__c = 'OH000-001';
        obj.ZP_Company_ID__c = '758373';
        insert obj;

        list<Tax_Ops_Tasks_Csv_Field_Mapping__c> lst_mappingObj = new list<Tax_Ops_Tasks_Csv_Field_Mapping__c>();

        Tax_Ops_Tasks_Csv_Field_Mapping__c temCSVObj1 = new Tax_Ops_Tasks_Csv_Field_Mapping__c();
        temCSVObj1.API_Name__c = 'FEIN__c';
        temCSVObj1.Field_Label__c = 'FEIN__c';
        temCSVObj1.Name='FEIN__c';
        lst_mappingObj.add(temCSVObj1);

        Tax_Ops_Tasks_Csv_Field_Mapping__c temCSVObj2 = new Tax_Ops_Tasks_Csv_Field_Mapping__c();
        temCSVObj2.API_Name__c = 'Amount_Held__c';
        temCSVObj2.Field_Label__c = 'Amount_Held__c';
        temCSVObj2.Name='Amount_Held__c';
        lst_mappingObj.add(temCSVObj2);

        Tax_Ops_Tasks_Csv_Field_Mapping__c temCSVObj3 = new Tax_Ops_Tasks_Csv_Field_Mapping__c();
        temCSVObj3.API_Name__c = 'Uploaded_to_Koala__c';
        temCSVObj3.Field_Label__c = 'Uploaded_to_Koala__c';
        temCSVObj3.Name='Uploaded_to_Koala__c';
        lst_mappingObj.add(temCSVObj3);

        /*Tax_Ops_Tasks_Csv_Field_Mapping__c temCSVObj4 = new Tax_Ops_Tasks_Csv_Field_Mapping__c();
        temCSVObj4.API_Name__c = 'Amount_Held__c';
        temCSVObj4.Field_Label__c = 'Amount_Held__c';
        temCSVObj4.Name='Amount_Held__c';
        lst_mappingObj.add(temCSVObj4);*/

        insert lst_mappingObj;

    }
    
    static testMethod void testupdateTaskStatus() {
    	Tax_Ops_Task__c tskObj1 = [Select Id, OwnerId, Process_step__c, Tax_Code__c, Failed_Payment_FEINs__c, Failed_Payment_Account_Numbers__c From Tax_Ops_Task__c Where Tax_Code__c =: 'OH000-001'];
    	
        csvParser csvObj = new csvParser();
        csvObj.recordTypeId = cache.getRecordTypeId('Tax_Ops_Failed_Record__c','Failed Filing');
        csvObj.parentId = tskObj1.Id;
        csvObj.importCSVFile();
        
        List<Tax_Ops_Tasks_Csv_Data__c> lst_stagingTable = [Select Id, Tax_Ops_Task__c From Tax_Ops_Tasks_Csv_Data__c Where Tax_Ops_Task__c =: tskObj1.Id];
        system.assert(lst_stagingTable.size() > 0);
    } 
}