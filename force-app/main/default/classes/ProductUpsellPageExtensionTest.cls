@isTest
public class ProductUpsellPageExtensionTest {
	static testMethod void testAsyncMethods() {
    	Account comp = new Account();
        comp.RecordTypeId = Cache.getRecordTypeId('Account', 'Company');
        comp.Name = 'Test Company';
        comp.ZP_Company_Id__c='12121212121212';
        insert comp;
        
        Contact cntct = new Contact();
        cntct.AccountId = comp.id;
        cntct.FirstName='Test';
        cntct.LastName='Test';
        cntct.Email='PriPayrollAdmin@gusto.com';
        insert cntct;

        Opportunity opportunity = new Opportunity();
        opportunity.StageName='SAL';
        opportunity.CloseDate = system.today();
        opportunity.RecordTypeId = OpportunityUtil.ACQUISITION_OPPTY_RT_ID;
        opportunity.AccountId = comp.Id;
        opportunity.NumberOfEmployees__c=1;
        opportunity.Number_of_Contractors__c=0;
        opportunity.ZP_Company_ID__c='12121212121212';
        opportunity.Source_Id__c='12121212121212';
        opportunity.Name = 'Test Opportunity';
        insert opportunity;
        OpportunityContactRole roleObj = new OpportunityContactRole();
        roleObj.ContactId = cntct.Id;
        roleObj.OpportunityId = opportunity.Id;
        roleObj.Role = 'Benefits Signatory';
        insert roleObj;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(opportunity);
        ProductUpsellPageExtension extension = new ProductUpsellPageExtension(sc);
        extension.saveRec();
    }
}