/**
 * @author Alex Xiong
 * @description controller for alert banner
 * @see AlertBannerCtrlTest
 */
public without sharing class AlertBannerCtrl {
    
    /**
     * @author Pradeep Chary
     * @description get active banner based on Application name
     * @param application name to search for active banner messages
     * @return message to display
     */
    @AuraEnabled
    public static List<Page_Alert_Banner__c> getHighlightBanner() {
        List<UserAppInfo> list_UserAppInfo = [SELECT
                                              Id,
                                              AppDefinitionId
                                              FROM UserAppInfo
                                              WHERE UserId = :UserInfo.getUserId()
                                              LIMIT 1];
        if (!list_UserAppInfo.isEmpty()) {
            AppDefinition objAppDefinition = [SELECT
                                              DurableId,
                                              Label
                                              FROM AppDefinition
                                              WHERE DurableId = :list_UserAppInfo[0].AppDefinitionId
                                              LIMIT 1];
            List<Page_Alert_Banner__c> list_Banners = [SELECT 
                                                       Id,
                                                       Application__c,
                                                       Subject__c,
                                                       Message__c
                                                       FROM Page_Alert_Banner__c
                                                       WHERE Active__c = true];
            if (!list_Banners.isEmpty()) {
                return list_Banners;
            }
        }
        
        return new List<Page_Alert_Banner__c>();
    }
}