/**
 * @name         OrderTimeCommitmentUtil
 * @author       Deepak Jadhav
 * @description  Utility class for Order Time Commitment functionality
 * @see          OrderTimeCommitmentUtilTest
 */
public without sharing class OrderTimeCommitmentUtil {

    /**
     * @description  Method to update order UiPath Eligibility Config custom setting to maintain eligible Previous Payroll Providers to calculate Payroll Time Commitment 
    * @param list_SelectedProviders accepts comma sepeprated Previous Payroll Providers .
    */
    @InvocableMethod(label='Add/Remove UiPath Eligibility' description='Maintain eligible Previous Payroll Providers to calculate Payroll Time Commitment' category='Order')
    public static void addRemoveUiPathEligibilitySettingValues(List<String> list_SelectedProviders) {
        try{
            Set<String> set_SelectedProviders = new Set<String>(list_SelectedProviders[0].split(','));
            Set<String> set_UipathEligibleProviders = new Set<String>();
            List<Order_UiPath_Eligibility_Config__c> list_NonUipathEligibleProviders = new  List<Order_UiPath_Eligibility_Config__c>();
            List<Order_UiPath_Eligibility_Config__c> list_UipathEligibleProviders  = new  List<Order_UiPath_Eligibility_Config__c>();
            
            for(Order_UiPath_Eligibility_Config__c record : Order_UiPath_Eligibility_Config__c.getAll().values()){
                if( !set_SelectedProviders.isEmpty() && !set_SelectedProviders.contains(record.Payroll_Provider__c)){
                    list_NonUipathEligibleProviders.add(record);
                }

                set_UipathEligibleProviders.add(record.Payroll_Provider__c.trim());
            }
            
            for(String activeVal : set_SelectedProviders){
                if( set_UipathEligibleProviders.isEmpty() || (!set_UipathEligibleProviders.isEmpty() && !set_UipathEligibleProviders.contains(activeVal))){
                    list_UipathEligibleProviders.add(new Order_UiPath_Eligibility_Config__c(Name = activeVal , Payroll_Provider__c = activeVal,Active__c = true));
                }   
            }
            
            if(!list_NonUipathEligibleProviders.isEmpty()){
                delete list_NonUipathEligibleProviders;
            }
            
            if(!list_UipathEligibleProviders.isEmpty()){
                insert list_UipathEligibleProviders;
            }
        }catch(Exception e){
            ExceptionLogUtil.logException(
                'OrderTimeCommitmentConfig ', 
                'addRemoveUiPathEligibilitySettingValues', 
                e);
        }
    }   
}