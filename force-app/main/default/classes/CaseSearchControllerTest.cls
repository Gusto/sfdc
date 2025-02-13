@isTest
public with sharing Class CaseSearchControllerTest {

    private static Case cse = new Case();
    private static Account acc = new Account();
    private static Contact con = new Contact();
    
    @testSetup static void testData() {
        acc = TestUtility.CompanyAccount();
        Account acc2 = TestUtility.CompanyAccount();
        
        test.startTest();
        //Case cse = new Case();
        
        list<Case> caseList = new list<Case>();
        
        cse.RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care');
        cse.AccountId = acc.Id;
        cse.Subject='Test';
        cse.Description='Test';
        cse.Type='Payroll Care';
        cse.Origin = 'Phone';
        caseList.add(cse);
        
        Case cse2 = new Case();
        cse2.RecordTypeId = cache.getRecordTypeId('Case', 'Sales Cases');
        cse2.AccountId = acc.Id;
        cse2.Subject='Test2';
        cse2.Description='Test2';
        cse2.Type='Sales Email';
        cse2.Origin = 'Email';
        caseList.add(cse2);
        
        insert caseList;
        
        con.FirstName = 'Gusto';
        con.LastName = 'CaseSearch';
        con.AccountId = acc2.id;
        insert con;        
        
        test.stopTest();
    }
    
	
    @isTest static void testCaseSearch() {
		testData();
        
        apexPages.StandardController sc = new apexPages.StandardController(cse);
        CaseSearchController controller  = new CaseSearchController(sc);   
        controller.getCaseStatusList();
        controller.getCaseOriginList();
        controller.getCaseList();
        
        List<case> tempCaseList = controller.accountCaseList;
        system.assert(tempCaseList.size() == 2);
        
        controller.filterCase.origin = 'Phone';
        controller.searchCase();
        tempCaseList = controller.accountCaseList;
        system.assert(tempCaseList.size() == 1);
        
        controller.filterCase.origin = 'Web';
        controller.searchCase();
        tempCaseList = controller.accountCaseList;
        system.assert(tempCaseList.size() == 0);
        
    }
    
    @isTest static void accountCaseSearch() {
        testData();
        
        apexPages.StandardController sc = new apexPages.StandardController(acc);
        CaseSearchController controller  = new CaseSearchController(sc);   
        controller.getCaseStatusList();
        controller.getCaseOriginList();
        controller.getCaseList();
        
        List<case> tempCaseList = controller.accountCaseList;
        system.assert(tempCaseList.size() == 2);
        
        controller.recordTypeFilter = cache.getRecordTypeId('Case', 'Sales Cases');
        controller.searchCase();        
        tempCaseList = controller.accountCaseList;        
        system.assert(tempCaseList.size() == 1);
    }
    
    @isTest static void contactCaseSearch() {
        testData();
        
        apexPages.StandardController sc = new apexPages.StandardController(con);
        CaseSearchController controller  = new CaseSearchController(sc);   
        controller.getCaseStatusList();
        controller.getCaseOriginList();
        controller.getCaseList();
        controller.searchCase();
        list<case> tempCaseList = controller.accountCaseList;
        system.assert(tempCaseList.size() == 0);
        
    }
    
    
}