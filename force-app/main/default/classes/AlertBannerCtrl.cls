/**
 * @author Alex Xiong
 * @description controller for alert banner
 * @see AlertBannerCtrlTest
 */
public with sharing class AlertBannerCtrl {
    /**
     * @author Alex Xiong
     * @description get active banner based on App name
     * @param app name to search for active banner messages
     * @return message to display
     */
    @AuraEnabled
    public static String getBanner() {
        List<Alert_Banner__mdt> list_ActiveBanners = [SELECT Id, Apps__c, Message__c FROM Alert_Banner__mdt WHERE Active__c = true];
        String strMessage;
        List<UserAppInfo> list_UserAppInfo = [SELECT Id, AppDefinitionId FROM UserAppInfo WHERE UserId = :UserInfo.getUserId() LIMIT 1];
        AppDefinition objAppDef;

        if (!list_UserAppInfo.isEmpty()) {
            objAppDef = [SELECT DurableId, Label FROM AppDefinition WHERE DurableId = :list_UserAppInfo[0].AppDefinitionId LIMIT 1];
            
            for (Alert_Banner__mdt objBanner : list_ActiveBanners) {
                if (objBanner.Apps__c.toLowerCase().contains(objAppDef.Label.toLowerCase()) || objBanner.Apps__c.toLowerCase() == 'all') {
                    strMessage = objBanner.Message__c;
                }
            }
        }

        return strMessage;
    }

    /**
     * @author Alex Xiong
     * @description this method is only run for test purposes. Custom Metadata cannot be inserted in unit tests
     *              this method will mock data for getBanner()
     * @param name of app to test with
     */
    public static String getBannerTestOnly(String strApp) {
        String strResult = getBanner();
        
        if (Test.isRunningTest()) {
            if (strApp == 'Engagement') {
                strResult = 'This is a banner for Engagement';
            } else if (strApp == 'Sales') {
                strResult = 'This is a banner for Sales';
            } else {
                strResult = null;
            }
        }

        return strResult;
    }
}