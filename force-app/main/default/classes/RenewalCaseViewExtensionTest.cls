@isTest
public class RenewalCaseViewExtensionTest {

static testMethod void testMethod1(){
   
    Account acc= new Account(Name='Test Company Name123');
    insert acc;
    
    Contact con = new Contact(LastName='Test');
    insert con;
       
    Case caseObj = new Case(
    ContactId = con.ID,
    AccountId = acc.Id,
    Status = 'Working',
    Origin = 'Phone');
    insert caseObj;
   
    ApexPages.StandardController sc = new ApexPages.StandardController(caseObj);
   
    RenewalCaseViewExtension obj = new RenewalCaseViewExtension (sc);
    PageReference pageRef = Page.PayrollTransferCasePage;
    pageRef.getParameters().put('id', String.valueOf(Case.Id));
    Test.setCurrentPage(pageRef);
    obj.SavePayrollTransferCase();
    

}

}