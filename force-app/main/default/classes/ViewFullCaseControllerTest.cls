@isTest
public class ViewFullCaseControllerTest {
	
    static testmethod void testViewFullCaseWithValidCaseId() {
        // Created a new Payroll Care Case
       	Case newCase = TestDataFactory.createCaseRecord('Payroll Care', true);
        // Call method that sets case in route flag to false. Used by PEs. Once they complete routing. they set Case In Route flag to be false.
        ViewFullCaseController.updateCaseInRoute(newCase.Id);
        newCase = [Select Id, Case_In_Route__c from Case Where Id = :newCase.Id];
        // Check if the flag was updated to true
        System.assertEquals(false, newCase.Case_In_Route__c, 'Case In Route flag not updated to true');
    }
    
    
    static testmethod void testViewFullCaseWithInValidCaseId() {
        // Pass an invalid case Id 
        Boolean isUpdateSuccessful = ViewFullCaseController.updateCaseInRoute(null);
        // Update method should return false
        System.assertEquals(false, isUpdateSuccessful, 'Case In Route flag updated to true');
    }
}