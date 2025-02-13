/**
 * @name         ShowAllTicketsOnBOCOCtrlTest
 * @author
 * @date         07/31/2024
 * @description  This class is used to test the functionality of ShowAllTicketsOnBOCOCtrl.
 **/
@isTest
public class ShowAllTicketsOnBOCOCtrlTest {
	/**
	 * @author       Deepika Saini
	 * @description  Test setup to create data
	 * @param        null
	 * @return       null
	 **/
	@TestSetup
	static void testGetRelatedTickets() {
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Account1').setZPCompanyId('123456789').build();
		insert objAccount;

		Opportunity objOpp = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
			.setAccountId(objAccount.Id)
			.setName('TEST OPPORTUNITY')
			.setStage('Open')
			.setCloseDate(System.Today())
			.setSourceID('testSourceId')
			.build();
		insert objOpp;

		Benefit_Order__c objBO = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(Cache.getRecordTypeId('Benefit_Order__c', 'Renewal'))
			.setOpp(objOpp.Id)
			.setStatus('Ready for Qualification')
			.setOwnerID(UserInfo.getUserId())
			.build();
		insert objBO;
		Carrier__c objCarrierRec = new TestDataFactory.CarrierBuilder().setName('Test123').setKey('test123').setId('test123').setCarrierId('28272728').build();
		insert objCarrierRec;

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('TestCarrierOrder')
			.setRecordTypeId(Cache.getRecordTypeId('Carrier_Order__c', 'Renewal'))
			.setCarrier(objCarrierRec.Id)
			.setOwnerID(UserInfo.getUserId())
			.setBenefitOrder(objBO.Id)
			.setOrderType('Carrier Switch')
			.setStartDate(System.today() - 50)
			.setImplementationStage('Ready for Submission Prep')
			.build();
		insert objCarrierOrder;
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test Method to check to get the records of tickets related to CO.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testGetRelatedTicketsCO() {
		Test.startTest();
		Account objAccount = [SELECT id FROM Account LIMIT 1];
		List<Carrier_Order__c> list_COs = [
			SELECT
				Benefit_Order__c,
				Id,
				Name,
				Carrier__c,
				Benefit_Types__c,
				Is_Multi_EIN__c,
				Total_Number_Of_Documents__c,
				RecordTypeId,
				Parent_Carrier_Order__c,
				Number_Of_Collected_Documents__c,
				Carrier__r.BT_Facilitator_POD__c,
				Initial_Owner__c,
				Assignment_Message__c,
				OwnerId,
				Implementation_Stage__c,
				Start_Date__c,
				OOO_Timestamp__c
			FROM Carrier_Order__c
			LIMIT 1
		];
		List<Ticket__c> list_Tickets = new List<Ticket__c>();
		for (Integer i = 0; i <= 5; i++) {
			Ticket__c objTicket = new TestDataFactory.TicketBuilder()
				//.setOppId(objOpp.Id)
				.setAccountId(objAccount.Id)
				.setStatus(TicketUtil.TICKET_STATUS_NEW)
				.setDescription('Test Ardius')
				.setOwnerId(UserInfo.getUserId())
				.setRecordTypeId(TicketUtil.ARDIUS_TICKET_RT_ID)
				.setCarrierOrderId(list_COs[0].Id)
				.build();
			list_Tickets.add(objTicket);
		}
		insert list_Tickets;
		List<Ticket__c> testRecordCO = ShowAllTicketsOnBOCOCtrl.getRelatedTickets(list_COs[0].Id);
		Test.stopTest();
		System.assertEquals(6, testRecordCO.size(), 'No ticket found for Benefit Order');
	}

}