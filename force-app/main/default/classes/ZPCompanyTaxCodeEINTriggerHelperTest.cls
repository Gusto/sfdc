@isTest
public class ZPCompanyTaxCodeEINTriggerHelperTest {
	static testMethod void testTaxOpsTaskCreation() {
		ZP_Company_Tax_Code_EIN__c obj = new ZP_Company_Tax_Code_EIN__c();
		obj.Account_Number__c = '127483';
		obj.FEIN__c = '758373';
		obj.Reference_Ein__c = '1234112';
		obj.Tax_Code__c = 'OH000-001';
		insert obj;
        obj = [Select id,Account_Number__c from ZP_Company_Tax_Code_EIN__c];
        System.assertEquals(obj.Account_Number__c, '127483', 'The Account_Number__c of ZP_Company_Tax_Code_EIN__c records should be 127483.');

        update obj;
        obj = [Select id,Account_Number__c from ZP_Company_Tax_Code_EIN__c];
        System.assertEquals(obj.Account_Number__c, '127483', 'The Account_Number__c of ZP_Company_Tax_Code_EIN__c records should be 127483.');
        
		ZPCompanyTaxCodeEINTriggerHelper ctrlObj = new ZPCompanyTaxCodeEINTriggerHelper(true, 1);
		Boolean IsTriggerContext = ctrlObj.IsTriggerContext;
		Boolean IsVisualforcePageContext = ctrlObj.IsVisualforcePageContext;
		Boolean IsWebServiceContext = ctrlObj.IsWebServiceContext;
		Boolean IsExecuteAnonymousContext = ctrlObj.IsExecuteAnonymousContext;

		delete obj;
        List<ZP_Company_Tax_Code_EIN__c> objList = [Select id,Account_Number__c from ZP_Company_Tax_Code_EIN__c];
        System.assertEquals(objList.size(), 0, 'All records of ZP_Company_Tax_Code_EIN__c should be deleted.');
	}
}