/**
 * @author Alex Xiong
 * @description Test class for AlertBannerCtrl
 */
@isTest
public class AlertBannerCtrlTest {
	/**
	 * @author Pradeep Chary
	 * @description test getHighlightBanner() method.
	 */
    @isTest
    static void testGetBanner() {
        Test.startTest();
        Page_Alert_Banner__c objBanner = new Page_Alert_Banner__c();
        objBanner.Active__c = true;
        objBanner.Application__c = 'Engagement';
        objBanner.Subject__c = 'Test';
        objBanner.Message__c = 'This is a banner for Engagement';
        insert objBanner;
        
        List<AppDefinition> list_Def = [SELECT DurableId, Label FROM AppDefinition WHERE Label = 'Engagement' LIMIT 1];
        UserAppInfo objUserAppInfo = new UserAppInfo(AppDefinitionId = list_Def[0].DurableId, UserId = UserInfo.getUserId(), FormFactor = 'Small');
        insert objUserAppInfo;
        
        List<Page_Alert_Banner__c> list_Banners = AlertBannerCtrl.getHighlightBanner();
        System.assertEquals('This is a banner for Engagement', list_Banners[0].Message__c, 'Incorrect Message');
    
    	Test.stopTest();
    }
}