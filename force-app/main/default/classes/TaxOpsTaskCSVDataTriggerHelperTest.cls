@isTest
public class TaxOpsTaskCSVDataTriggerHelperTest {
    @testSetup
    static void setup(){
        
        Tax_Ops_Task__c taxOpsTask=new Tax_Ops_Task__c();
        	taxOpsTask.Payments_Completed__c=true;
             taxOpsTask.Tax_Code__c='OH000-001';
        insert taxOpsTask;
        
        Id accId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Company').getRecordTypeId();
        Account account=new Account();
        account.Name = 'Test Demo AccountName 1';
        account.BillingStreet = 'Testing Avenue 1';
        account.BillingPostalCode = '123456';
        account.Company_Trade_Name__c = 'Company trade name 1';
        account.Phone = '19992344444';
        account.ShippingStreet = 'Testing Avenue 1';
        account.ShippingPostalCode = '123455';
        account.ZP_Company_ID__c = '5464365436434';
        account.RecordTypeId=accId;
        insert account;
        
        Blob key = EncryptionUtils.generateKey('Master');
        ZP_Company_Tax_Code_EIN__c obj = new ZP_Company_Tax_Code_EIN__c();
        obj.Account_Number__c = '127483';
        obj.FEIN__c = '758373';
        obj.Reference_Ein__c = '1234112';
        obj.Tax_Code__c = 'OH000-001';
        obj.ZP_Company_ID__c = '5464365436434';
        insert obj;
        
        Id failedRecId=Schema.SObjectType.Tax_Ops_Failed_Record__c.getRecordTypeInfosByName().get('Failed Filing').getRecordTypeId();

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

        Tax_Ops_Tasks_Csv_Field_Mapping__c temCSVObj4 = new Tax_Ops_Tasks_Csv_Field_Mapping__c();
        temCSVObj4.API_Name__c = 'Account_Number__c';
        temCSVObj4.Field_Label__c = 'Account_Number__c';
        temCSVObj4.Name='Account_Number__c';
        lst_mappingObj.add(temCSVObj4);

        insert lst_mappingObj;
        
    }
    
    @isTest
    static void testTriggerEvents(){
        Tax_Ops_Task__c taskObj = [SELECT id FROM Tax_Ops_Task__c];
        Test.startTest();

            List<Tax_Ops_Tasks_Csv_Data__c> lst_CSVData=new List<Tax_Ops_Tasks_Csv_Data__c>();
            for(Integer i=0;i<10;i++){
                Tax_Ops_Tasks_Csv_Data__c tempCsvObj = new Tax_Ops_Tasks_Csv_Data__c(
                                                            Account__c='TestAcc'+i, 
                                                            Account_Number__c='127483',
                                                            FEIN__c='758373',
                                                            Processing_Status__c='Queued',
                                                            Message__c='This is Test Message',
                                                            Amount_Held__c='1000',
                                                            Uploaded_to_Koala__c='Test',
                                                            Filing_Successful__c='InProgress',
                                                            Processed_At__c=System.now(),
                                                            Tax_Ops_Task__c=taskObj.Id);
                
                if(i <= 5){
                    tempCsvObj.Record_Type__c = cache.getRecordTypeId('Tax_Ops_Failed_Record__c', 'Failed Filing');
                }
                else{
                    tempCsvObj.Record_Type__c = cache.getRecordTypeId('Tax_Ops_Failed_Record__c', 'Failed Payment');
                }

                lst_CSVData.add(tempCsvObj);
            }
            insert lst_CSVData;

            UPDATE lst_CSVData;

            DELETE lst_CSVData;
            UNDELETE lst_CSVData;

        Test.stopTest();
    }
    
    


    
}