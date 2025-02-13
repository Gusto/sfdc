public with sharing class PrivacyRequestsUtil { // change to util class
    public static void updateCookieKey() {
        Blob blobKey = crypto.generateAesKey(128);
        String key = EncodingUtil.base64Encode(blobKey);

        Configuration_Settings__c configSettings = Configuration_Settings__c.getOrgDefaults();
        configSettings.Privacy_Requests_Cookie_Key__c = key;
        upsert configSettings;
    }
}