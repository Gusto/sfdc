@isTest
public class InboundCallListenerControllerTest {
	/**
	 * @author      Praveen Sethu
	 * @description Test response from NICE inContact
	 **/
	@isTest
	static void testInboundCallListener() {
		Sales_Interaction__c objInteraction = new Sales_Interaction__c(DNIS__c = '1234', ANI__c = '1234', CCID__c = '1234');
		insert objInteraction;

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new InboundCallMockResponseTest());
		InboundCallListenerController.setInboundCallEmailAddress(new List<Id>{ objInteraction.Id });
		Test.stopTest();

		objInteraction = [SELECT Id, Email_Address__c FROM Sales_Interaction__c WHERE Id = :objInteraction.Id];
		System.assertEquals('praveen.sethu@gusto.com', objInteraction.Email_Address__c, 'Email address not set correctly');
	}
}