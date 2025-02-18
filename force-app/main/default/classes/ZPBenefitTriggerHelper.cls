/**
Created by : Praveen Sethu
Created Date : 11/26/2020
Description: Handles all business logic for various contexts of ZP Benefits DML operations.
**/
public class ZPBenefitTriggerHelper {
	
    public static Boolean blnQueue = false;
    
    // Map of Company Id to Account Object
    public Map<String, Account> map_CompanyIdToAccount;
    
    public ZPBenefitTriggerHelper() {
        map_CompanyIdToAccount = new Map<String, Account>();
    }
    
    /*** Process Before Insert  ***/
    public void processBeforeInsert(List<ZP_Benefit__c> list_ZPBenefits) {
    	
        createCollectionsBefore(list_ZPBenefits,null);
        
        for(ZP_Benefit__c objBenefit : list_ZPBenefits) {
            setAccountInfo(objBenefit);
        }
    }
    
    /*** Process Before Update  ***/
    public void processBeforeUpdate(List<ZP_Benefit__c> list_NewZPBenefits, Map<Id, ZP_Benefit__c> map_OldZPBenefits){
    	
        createCollectionsBefore(list_NewZPBenefits,map_OldZPBenefits);
        
        for(ZP_Benefit__c objBenefit : list_NewZPBenefits) {
            setAccountInfo(objBenefit);
        }
    }
    
    /**** Before Context : Create data collections to be used across functions ****/
    public void createCollectionsBefore(List<ZP_Benefit__c> list_NewZPBenefits, Map<Id, ZP_Benefit__c> map_OldZPBenefits) {
        
        Set<String> set_CompanyIds = new Set<String>();
        // Create data collections
        for(ZP_Benefit__c objBenefit : list_NewZPBenefits)
        {
            ZP_Benefit__c objOldBenefit = (map_OldZPBenefits != null ? map_OldZPBenefits.get(objBenefit.Id) : null);
            if(String.isNotBlank(objBenefit.Company_Id__c)) {
                set_CompanyIds.add(objBenefit.Company_Id__c);
            }
        }
        
        if(!set_CompanyIds.isEmpty()) {
            
            List<Account> list_Accounts = queryAccounts(set_CompanyIds);
            for(Account objAccnt: list_Accounts) {
                map_CompanyIdToAccount.put(objAccnt.ZP_Company_ID__c, objAccnt);
            }
        }
    }
    
    /**** Set Account__c lookup value on ZP_Benefit__c ****/
    public void setAccountInfo(ZP_Benefit__c objBenefit) {
        objBenefit.Account__c = map_CompanyIdToAccount.containsKey(objBenefit.Company_Id__c) ? 
            							map_CompanyIdToAccount.get(objBenefit.Company_Id__c).Id : null;
    }
    
    /**** query Accounts ****/
    public List<Account> queryAccounts(Set<String> set_CompanyIds) {
        return [SELECT Id, ZP_Company_ID__c  FROM Account WHERE ZP_Company_ID__c  IN :set_CompanyIds];
    }
}