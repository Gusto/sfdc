@isTest
public class AdvocateStateTriggerHelperTest {
    
    @isTest
    static void testHistoryCreation() {
        
        test.startTest();
        	Advocate_State__c state = new Advocate_State__c();
        	state.User_Id__c = UserInfo.getUserId();
        	state.User__c = UserInfo.getUserId();
        	state.State__c = 'Logged In';
        
        	upsert state User_Id__c;
        
        	system.assertEquals('Logged In', state.State__c);
        
        	state.State__c = 'Active';
        
        	upsert state User_Id__c;
        
        	system.assertEquals('Active', state.State__c);
        
        	delete state;
        test.stopTest();
    }
}