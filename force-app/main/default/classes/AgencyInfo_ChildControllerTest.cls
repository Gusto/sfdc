/** @name       AgencyInfo_ChildControllerTest
* @author       Rinkita
* @date         04th Ocotber 2024
* @description  Tests the Get, Create, and Update of Form_Name_Number__c .
* @revisions    Date ------------ Name ------------ Comments

**/
@isTest
public class AgencyInfo_ChildControllerTest {
	@TestSetup
    static void setupTestData() {
		Agency_Information__c objAgency = TestDataFactory.createOneAgencyInforation('Test Agency');
        Id strRecId = [SELECT Id FROM RecordType WHERE sObjectType = 'Form_Name_Number__c' and Name = 'General Details' LIMIT 1].Id;
        Form_Name_Number__c form = new Form_Name_Number__c(Form_Name_Number_Text__c = 'Test form', RecordTypeId = strRecId, Agency_Information__c = objAgency.Id);
        insert form;
        Id strRecId2 = [SELECT Id FROM RecordType WHERE sObjectType = 'Filing_Frequency_Schedule__c' and Name = 'General Details' LIMIT 1 ].Id;
        Filing_Frequency_Schedule__c fileFreq = new Filing_Frequency_Schedule__c(Filing_Frequency_Schedule_Type__c = 'Annual', RecordTypeId = strRecId2, Agency_Information__c = objAgency.Id);
        insert fileFreq;
        Deposit_Frequency_Schedule__c depoFreq = new Deposit_Frequency_Schedule__c(Deposit_Frequency_Schedule_Type__c = 'Annual', Agency_Information__c = objAgency.Id);
        insert depoFreq;
        Fixed_Tax_Surcharge__c taxSur = new Fixed_Tax_Surcharge__c(Fixed_Tax_Surcharge_Name__c = 'Test', Agency_Information__c = objAgency.Id);
        insert taxSur;
    }
    
     /**
     * @Author      : Rinkita
     * @Description : validate "AgencyInfo_ChildController.upsertFormNameRecord" method
     * @Parm        : (List<Form_Name_Number__c>, String, String)
     * @Return      : Integer
     **/
    @isTest
    static void testUpsertFormNameRecord() {
        Test.startTest();
        	List<Form_Name_Number__c> list_FormNames = [select id, Form_Name_Number_Text__c from Form_Name_Number__c];
        	AgencyInfo_ChildController.upsertFormNameRecord(list_FormNames, 'General Details', 'Form_Name_Number__c');
        Test.stopTest();
    }
    
    /**
     * @Author      : Rinkita
     * @Description : validate "AgencyInfo_ChildController.upsertFilingFrequencyRecord" method
     * @Parm        : (List<Filing_Frequency_Schedule_Type__c>, String, String)
     * @Return      : Integer
     **/
    @isTest
    static void testUpsertFilingFrequencyRecord() {
        Test.startTest();
        	List<Filing_Frequency_Schedule__c> list_fileFreq = [select id, Filing_Frequency_Schedule_Type__c from Filing_Frequency_Schedule__c];
        	AgencyInfo_ChildController.upsertFilingFrequencyRecord(list_fileFreq, 'General Details', 'Filing_Frequency_Schedule__c');
        Test.stopTest();
    }
    
    /**
     * @Author      : Rinkita
     * @Description : validate "AgencyInfo_ChildController.upsertDepositFrequencyRecord" method
     * @Parm        : (List<Deposit_Frequency_Schedule_Type__c>)
     * @Return      : Integer
     **/
    @isTest
    static void testUpsertDepositFrequencyRecord() {
        Test.startTest();
        	List<Deposit_Frequency_Schedule__c> list_DepoFreqSch = [select id, Deposit_Frequency_Schedule_Type__c from Deposit_Frequency_Schedule__c];
        	AgencyInfo_ChildController.upsertDepositFrequencyRecord(list_DepoFreqSch);
        Test.stopTest();
    }
    
    /**
     * @Author      : Rinkita
     * @Description : validate "AgencyInfo_ChildController.upsertFixedTaxSurRecord" method
     * @Parm        : (List<Fixed_Tax_Surcharge__c>)
     * @Return      : Integer
     **/
    @isTest
    static void testUpsertFixedTaxSurRecord() {
        Test.startTest();
        	List<Fixed_Tax_Surcharge__c> list_DepoFreqSch = [select id, Fixed_Tax_Surcharge_Name__c from Fixed_Tax_Surcharge__c];
        	AgencyInfo_ChildController.upsertFixedTaxSurRecord(list_DepoFreqSch);
        Test.stopTest();
    }
    
    /**
     * @Author      : Rinkita
     * @Description : validate "AgencyInfo_ChildController.deleteChildRecord" method
     * @Parm        : (List<Form_Name_Number__c>, String)
     * @Return      : void
     **/
    @isTest
    static void testDeleteChildRecord() {
        Test.startTest();
        	Id idForm = [select id from Form_Name_Number__c limit 1].Id;
        	List<Id> list_toDelete = new List<Id> {idForm};
        	AgencyInfo_ChildController.deleteChildRecord(list_toDelete, 'Form_Name_Number__c');
        Test.stopTest();
    }
    
    /**
     * @Author      : Rinkita
     * @Description : validate "AgencyInfo_ChildController.deleteChildRecord" method
     * @Parm        : (List<Filing_Frequency_Schedule__c>, String)
     * @Return      : void
     **/
    @isTest
    static void testDeleteChildRecord2() {
        Test.startTest();
        	Id idForm = [select id from Filing_Frequency_Schedule__c limit 1].Id;
        	List<Id> list_toDelete = new List<Id>{idForm};
        	AgencyInfo_ChildController.deleteChildRecord(list_toDelete, 'Filing_Frequency_Schedule__c');
        Test.stopTest();
    }
    
    /**
     * @Author      : Rinkita
     * @Description : validate "AgencyInfo_ChildController.deleteChildRecord" method
     * @Parm        : (List<Deposit_Frequency_Schedule__c>, String)
     * @Return      : void
     **/
    @isTest
    static void testDeleteChildRecord3() {
        Test.startTest();
        	Id idForm = [select id from Deposit_Frequency_Schedule__c limit 1].Id;
        	List<Id> list_toDelete = new List<Id> {idForm};
        	AgencyInfo_ChildController.deleteChildRecord(list_toDelete, 'Deposit_Frequency_Schedule__c');
        Test.stopTest();
    }
    
    /**
     * @Author      : Rinkita
     * @Description : validate "AgencyInfo_ChildController.deleteChildRecord" method
     * @Parm        : (List<Fixed_Tax_Surcharge__c>, String)
     * @Return      : void
     **/
    @isTest
    static void testDeleteChildRecord4() {
        Test.startTest();
        	Id idForm = [select id from Fixed_Tax_Surcharge__c limit 1].Id;
        	List<Id> list_toDelete = new List<Id> {idForm};
        	AgencyInfo_ChildController.deleteChildRecord(list_toDelete, 'Fixed_Tax_Surcharge__c');
        Test.stopTest();
    }
    
    /**
     * @Author      : Rinkita
     * @Description : validate "AgencyInfo_ChildController.getComplianceMetadata" method
     * @Parm        : (String)
     * @Return      : Integer
     **/
    @isTest
    static void testGetComplianceMetadata() {
        Test.startTest();
        	/*cannot insert  custom metadata*/
        	Integer intCounter = AgencyInfo_ChildController.getComplianceMetadata('Form_Name_Number__c');
        Test.stopTest();
    }
    
    /**
     * @Author      : Rinkita
     * @Description : validate "AgencyInfo_ChildController.getChildFormNameRecType" method
     * @Parm        : (Id, String, Integer)
     * @Return      : List<Form_Name_Number__c>
     **/
    @isTest
    static void testGetChildFormNameRecType() {
        Test.startTest();
        	Id agencyInfoId = [select id from Agency_Information__c limit 1].Id; 
        	AgencyInfo_ChildController.getChildFormNameRecType(agencyInfoId, 'General Details', 5);
        Test.stopTest();
    }
    
    /**
     * @Author      : Rinkita
     * @Description : validate "AgencyInfo_ChildController.getChildFilingFrequencyScheduleRecType" method
     * @Parm        : (Id, String, Integer)
     * @Return      : List<Filing_Frequency_Schedule__c>
     **/
    @isTest
    static void testGetChildFilingFrequencyScheduleRecType() {
        Test.startTest();
        	Id agencyInfoId = [select id from Agency_Information__c limit 1].Id; 
        	AgencyInfo_ChildController.getChildFilingFrequencyScheduleRecType(agencyInfoId, 'General Details', 5);
        Test.stopTest();
    }
    
    /**
     * @Author      : Rinkita
     * @Description : validate "AgencyInfo_ChildController.getChildDepositFrequencySchedule" method
     * @Parm        : (Id, String, Integer)
     * @Return      : List<Deposit_Frequency_Schedule__c>
     **/
    @isTest
    static void testGetChildDepositFrequencySchedule() {
        Test.startTest();
        	Id agencyInfoId = [select id from Agency_Information__c limit 1].Id; 
        	AgencyInfo_ChildController.getChildDepositFrequencySchedule(agencyInfoId, 5);
        Test.stopTest();
    }
    
    /**
     * @Author      : Rinkita
     * @Description : validate "AgencyInfo_ChildController.getChildFixedTaxSurcharge" method
     * @Parm        : (Id, String, Integer)
     * @Return      : List<Fixed_Tax_Surcharge__c>
     **/
    @isTest
    static void testGetChildFixedTaxSurcharge() {
        Test.startTest();
        	Id agencyInfoId = [select id from Agency_Information__c limit 1].Id; 
        	AgencyInfo_ChildController.getChildFixedTaxSurcharge(agencyInfoId, 5);
        Test.stopTest();
    }
    
}