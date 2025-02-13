@isTest
public with sharing class PrivacyRequestTests {
    
    /*
    Author: Alex
    Purpose: test PrivacyRequestUtil.updateCookieKey()
    */
    @isTest
    public static void updateCookieKeyTest() {
        Configuration_Settings__c configSettings = Configuration_Settings__c.getOrgDefaults();
        configSettings.Privacy_Requests_Cookie_Key__c = 'Some Value';
        upsert configSettings;

        PrivacyRequestsUtil.updateCookieKey();
        Configuration_Settings__c configSettings2 = Configuration_Settings__c.getOrgDefaults();
        System.assertNotEquals(configSettings.Privacy_Requests_Cookie_Key__c, configSettings2.Privacy_Requests_Cookie_Key__c);
    }

    /*
    Author: Alex
    Purpose: test portal entrance
    updated by: Prashant
    */
    @isTest
    public static void PortalEntranceTest(){
        Configuration_Settings__c configSettings = Configuration_Settings__c.getOrgDefaults();
        configSettings.Privacy_Requests_Cookie_Key__c = 'MqhGH4VAY8hyp6XhrowAgg==';
        upsert configSettings;
        
        CaseTriggerHelper.skipTrigger = true;
        List<RecordType> recTypeId = [SELECT Id FROM RecordType WHERE SobjectType='Case' AND DeveloperName='Privacy_Request' LIMIT 1];
        Case c = new Case(
            RecordTypeId = recTypeId[0].Id,
            Status = 'New',
            Privacy_Requester_Email__c = 'test@test.com',
            Confirmation_Code__c = '1234567890'
        );
        insert c;
        CaseTriggerHelper.skipTrigger = false;

        PrivacyRequestsPortalEntranceCtrl p = new PrivacyRequestsPortalEntranceCtrl();
        p.strConfirmationCode = c.Confirmation_Code__c;
        p.strEmail = 'test@test.com';
        p.getCase();

        String str_Encrypted = PrivacyRequestsPortalEntranceCtrl.encryptString('12345');
        System.assertNotEquals('12345', str_Encrypted);

        String str_Decrypted = PrivacyRequestsPortalEntranceCtrl.decryptString(str_Encrypted);
        System.assertEquals('12345', str_Decrypted);
        p.submit();
    }
}