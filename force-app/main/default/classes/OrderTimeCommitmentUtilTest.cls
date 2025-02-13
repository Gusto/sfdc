@isTest
public class OrderTimeCommitmentUtilTest {
    @TestSetup
    static void setup() 
    {
        List<Order_UiPath_Eligibility_Config__c> list_Configs = new List<Order_UiPath_Eligibility_Config__c>{
            new Order_UiPath_Eligibility_Config__c(
            Name = 'JustWorks',
            Payroll_Provider__c = 'JustWorks'
            ),
            new Order_UiPath_Eligibility_Config__c(
            Name = 'Paychex',
            Payroll_Provider__c = 'Paychex'
            ),
            new Order_UiPath_Eligibility_Config__c(
            Name = 'iSolved',
            Payroll_Provider__c = 'iSolved'
            )
        };

        insert list_Configs;

    }

    @isTest
    static void testaddRemoveUiPathEligibilitySettingValues() {

        Test.startTest();
            OrderTimeCommitmentUtil.addRemoveUiPathEligibilitySettingValues(new List<String>{'JustWorks,Paychex,Paycor'});
        Test.stopTest();

        System.assert(
            Order_UiPath_Eligibility_Config__c.getInstance('JustWorks') != null,
            'JustWorks record found.'
        );

        System.assert(
            Order_UiPath_Eligibility_Config__c.getInstance('Paycor') != null,
            'Paycor record found.'
        );

        System.assert(
            Order_UiPath_Eligibility_Config__c.getInstance('iSolved') == null,
            'iSolved config record deleted.'
        );

    }
}