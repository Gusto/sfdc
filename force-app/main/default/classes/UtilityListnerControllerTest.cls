@isTest
public class UtilityListnerControllerTest {
	
    static testmethod void testGetCaseDetails() {
        // Create a new Payroll Care Case
     	Case cse = TestDataFactory.createCaseRecord('Payroll Care', true);
        Test.startTest();
        Case caseRecord = UtilityListnerController.getCaseDetails(cse.Id);
        Test.stopTest();
        
        System.assertEquals(true, caseRecord != null, 'Utility Listner Controller - case details not fetched properly');
    }
}