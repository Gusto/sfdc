@isTest
public class IVRRoutingLogQueryHelperTest {
    static testMethod void testGetCases(){
        IVR_Routing_Log__c objIvr = new IVR_Routing_Log__c(ConversationId__c = 'test');
        insert objIvr;
        
        Case objCase = new Case(Status = 'New', Origin = 'Phone',IVR_Routing_Log__c = objIvr.Id);
        insert objCase;
        
        List<Case> lst_caseObj = new List<Case>();
        lst_caseObj.add(objCase);
        List<Id> lst_IvrId = new List<Id> ();
        lst_IvrId.add(objIvr.Id);
        Test.startTest();
        List<Case> lst_case = IVRRoutingLogQueryHelper.getCases(lst_IvrId);
        System.assertEquals(true, lst_case.size()>0);
        Test.stopTest();
    }
}