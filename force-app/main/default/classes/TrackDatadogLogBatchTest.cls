/**
* @name         TrackDatadogLogBatchTest
* @author       Bhagat Singh
* @date         26/09/2024
* @description  Test class for TrackDatadogLogBatch class.
**/
@isTest
private class TrackDatadogLogBatchTest {
    /**
    * @Author      : Bhagat Singh
    * @Description : Test Class setup method
    **/
    @testSetup
    static void setupData() {
        OEIncompleteEmailBatchTest.createTestData();
        OEIncompleteEmailBatch  objBatch = new OEIncompleteEmailBatch();
        Database.executeBatch(objBatch);
    }
    
    /**
    * @Author      : Bhagat Singh
    * @Description : Validate TrackDatadogLogBatch.
    **/
    @isTest
    static void testDataDogBatch() {
        Test.startTest();
        Database.executeBatch(new TrackDatadogLogBatch());
        
        Test.stopTest();
    }
}