@isTest
public class AgencyInformationDetailsTest {
    @TestSetup
    static void setupTestData() {
        List<Agency_Information__c> list_AgencyInformations = TestDataFactory.CreateAgencyInformation();
    }
    @isTest
    static void unitTestSITMethod() {
        Agency_Information__c obj_AgenciesInfo = [SELECT Id FROM Agency_Information__c LIMIT 1];
        List<AgencyInformationDetails.objectData> objReturnData= AgencyInformationDetails.getFieldMetadata(obj_AgenciesInfo.Id,'SUI_Agencies__c');
        System.assertEquals(objReturnData.isEmpty(),false, 'Failed');
    }
    @isTest
    static void unitTestSUIMethod() {
        Agency_Information__c obj_AgenciesInfo = [SELECT Id FROM Agency_Information__c LIMIT 1];
        List<AgencyInformationDetails.objectData> objReturnData = AgencyInformationDetails.getFieldMetadata(obj_AgenciesInfo.Id,'SIT_Agencies__c');
        System.assertEquals(objReturnData.isEmpty(),false ,'Failed');
    }
    @isTest
    static void unitTestASCRMethod() {
        Agency_Information__c obj_AgenciesInfo = [SELECT Id FROM Agency_Information__c LIMIT 1];
        List<AgencyInformationDetails.objectData> objReturnData = AgencyInformationDetails.getFieldMetadata(obj_AgenciesInfo.Id,'Agencies_Supporting_Combined_Reporting__c');
        System.assertEquals(objReturnData.isEmpty(),false ,'Failed');
    }
}