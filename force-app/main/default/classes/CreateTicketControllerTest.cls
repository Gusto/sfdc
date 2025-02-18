/**
 * @name         : CreateTicketControllerTest
 * @author       : Ankit CS
 * @date         : 08-12-2021
 * @description  : Test class for CreateTicketController
 **/
@isTest
public class CreateTicketControllerTest {
	//Flag to indicate when to throw an exception
	public static Boolean blnThrowException = false;
	/**
	 * @Author      : Ankit CS
	 * @Description : This method creates all the test data
	 **/
	@testSetup
	static void setupData() {

		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;

		User objThisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		User objUser = new User();

		// Generating a Unique Name
		String orgId = UserInfo.getOrganizationId();
		String strDate = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
		Integer intRandom = Integer.valueOf(math.rint(math.random() * 1000000));
		String strUniqueName = orgId + strDate + intRandom;
		String strUserName = strUniqueName + '@testgusto' + orgId + '.com';

		System.runAs(objThisUser) {
			Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'ZP System Administrator'];
			objUser = new TestDataFactory.UserBuilder()
				.setUniqueUserName()
				.setLastName('Test User')
				.setEmail(strUserName)
				.setProfileId(objProfile.Id)
				.setTimeZoneSidKey('America/Denver')
				.setLocaleSidKey('en_US')
				.setLanguageLocaleKey('en_US')
				.setEmailEncoding('ISO-8859-1')
				.setAlias('test')
				.setIsActive(true)
				.build();
			insert objUser;
		}

		// Create Company Accounts
		List<Account> list_Accounts = new List<Account>();
		Account objAccount = new Account();
		objAccount.RecordTypeId = Cache.getRecordTypeId('Account', 'Company');
		objAccount.Name = 'TEST ACCOUNT';
		objAccount.Joined_Date_Panda__c = System.today();
		objAccount.ZP_Company_ID__c = String.valueOf(CaseTriggerHelperTest.generateRandomId());
		insert objAccount;

		// Create Company Contact
		Contact objContact = new Contact();
		objContact.RecordTypeId = Cache.getRecordTypeId('Contact', 'Company');
		objContact.AccountId = objAccount.Id;
		objContact.FirstName = 'TEST CONTACT';
		objContact.LastName = 'CONTACT';
		objContact.Phone = '1234567890';
		objContact.Email = 'test.contact@gusto.com';
		objContact.ZP_User_Id__c = String.valueOf(CaseTriggerHelperTest.generateRandomId());
		insert objContact;

		//Creating Cases
		List<Case> list_Cases = new List<Case>();
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Care')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setType('Payroll Care')
			.setSubject('Case assigned to user')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.build();
		objCase.OwnerId = objUser.Id;
		list_Cases.add(objCase);
		objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Care')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setType('Payroll Care')
			.setSubject('Case assigned to queue')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.build();
		objCase.OwnerId = [SELECT Id FROM Group WHERE Name = 'Payroll Care - Non Actionable' and type = 'Queue']?.Id;
		list_Cases.add(objCase);
		CaseTriggerHelper.skipTrigger = true;
		insert list_Cases;
		CaseTriggerHelper.skipTrigger = false;

		// Create a new Ticket Config
		List<Ticket_Config__c> list_TicketConfig = new List<Ticket_Config__c>();
		Ticket_Config__c objTicketConfig = new TestDataFactory.TicketConfigBuilder()
			.setName('Test MYBC - Escalations')
			.setRecordType('Advising Fulfillment')
			.setOwnerType('Case Owner')
			.setQueueId('MYBC - Escalations')
			.setTeam('Member Operations')
			.setTicketReason('Member Operation Reason 1')
			.setTicketSubReason('Member Operation Sub Reason 11')
			.setIsActive(true)
			.build();

		Ticket_Config__c objTicketConfig2 = new TestDataFactory.TicketConfigBuilder()
			.setName('Test MYBC - Escalations')
			.setRecordType('Advising Fulfillment')
			.setOwnerType('Case Owner')
			.setQueueId('MYBC - Escalations')
			.setTeam('Member Operations')
			.setTicketReason('Member Operation Reason 2')
			.setTicketSubReason('Member Operation Reason 21')
			.setIsActive(true)
			.build();

		Ticket_Config__c objTicketConfig3 = new TestDataFactory.TicketConfigBuilder()
			.setName('Test MYBC - Escalations')
			.setRecordType('Advising Fulfillment')
			.setOwnerType('Case Owner')
			.setQueueId('MYBC - Escalations')
			.setTeam('Risk')
			.setTicketReason('Member Fulfillment Reason 1')
			.setTicketSubReason('Member Fulfilment Sub Reason 11')
			.setIsActive(true)
			.build();

		list_TicketConfig.add(objTicketConfig);
		list_TicketConfig.add(objTicketConfig2);
		list_TicketConfig.add(objTicketConfig3);
		insert list_TicketConfig;

		AccountTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method for loadCreateTicketData()
	 **/
	
	@isTest
	static void testLoadCreateTicketData() {
		Test.startTest();

		// This is used when Create Ticket page initially loads and we retrieve all necessary picklist values
		CreateTicketController.CreateTicketResponseWrapper objResponseWrapper = CreateTicketController.loadCreateTicketData();
		// Validate if we have got all picklist values
		System.assertEquals(true, objResponseWrapper.list_TicketReasons.size() > 0, 'Create Ticket Controller - All Picklist values are not loaded');

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method for updateTicket()
	 **/

	@isTest
	static void testUpdateTicket() {
		Test.startTest();
		Case objCase = [SELECT Id, OwnerId, Status FROM Case WHERE Subject = 'Case assigned to queue' LIMIT 1];
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.ADVISING_FULFILLMENT_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setOwnerId(UserInfo.getUserId())
			.setCaseId(objCase.Id)
			.build();

		// Create a new Ticket Config
		Ticket_Config__c objTicketConfig = new TestDataFactory.TicketConfigBuilder()
			.setName('Test')
			.setRecordType('Advising Fulfillment')
			.setOwnerType('Assign to a Queue')
			.setQueueId('Member Fulfillment')
			.build();
		insert objTicketConfig;
		
		CreateTicketController.CreateTicketResponseWrapper objResponseWrapper = CreateTicketController.updateTicket(objTicket, objTicketConfig);
		Test.stopTest();

		objTicket = [SELECT Id,OwnerId,Owner.Name FROM Ticket__c WHERE Id =:objTicket.Id];
		// Validate if Ticket was created successfully
		System.assertEquals(true, objResponseWrapper.blnIsSuccess, 'Create Ticket Controller - Ticket not created successfully');
		System.assertEquals(objTicket.OwnerId,GlobalQueryHelper.getNameQueueMap(new Set<String>{ TicketUtil.QUEUE_MEMBER_OPS }).get(TicketUtil.QUEUE_MEMBER_OPS),'Owner should be Member Fulfillment and not Adivising Fulfillment Queue');
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method for updateTicket() for ticket routing to benefit order owner
	 **/	
	@isTest
	static void testUpdateTicket2() {
		// Create a new Benefit Order
		Benefit_Order__c objNewBenefitOrder = TestUtility.NewPlanBenefitOrder();

		// Create a new ticket
		Ticket__c objTicket = new Ticket__c(
			Status__c = 'New',
			Escalation_Reason__c = 'Test',
			Priority__c = 'Low',
			Description__c = 'Test Description',
			Employee_Hippo_Link__c = 'test@yxz.com',
			Benefit_Order__c = objNewBenefitOrder.Id
		);

		// Create a new Ticket Config
		Ticket_Config__c objTicketConfig = new Ticket_Config__c(Name = 'Test', Ticket_Record_Type__c = 'Benefits Transfer', Owner_Type__c = 'Benefit Order Owner', Queue_Id__c = 'Benefits Transfer');

		// Create a ticket that has a benefit order
		Test.startTest();

		CreateTicketController.CreateTicketResponseWrapper objResponseWrapper = CreateTicketController.updateTicket(objTicket, objTicketConfig);
		//Asserting if the Ticket was created successfully
		System.assertEquals(true, objResponseWrapper.blnIsSuccess, 'Create Ticket Controller - Ticket not created successfully');

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method for updateTicket() for ticket routing to Opportunity owner
	 **/
	@isTest
	static void testupdateTicket3() {
		Account objNewAccount = TestUtility.CompanyAccount();
		Opportunity objNewOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setAccountId(objNewAccount.Id)
			.setName('Test Oppty 1')
			.setStage('New')
			.setCloseDate(Date.today())
			.build();
		insert objNewOpportunity;

		// Create a new ticket
		Ticket__c objTicket = new Ticket__c(
			Status__c = 'New',
			Escalation_Reason__c = 'Test',
			Priority__c = 'Low',
			Description__c = 'Test Description',
			Employee_Hippo_Link__c = 'test@yxz.com',
			Opportunity__c = objNewOpportunity.Id
		);

		Ticket_Config__c objTicketConfig = new Ticket_Config__c(Name = 'Test', Ticket_Record_Type__c = 'Benefits Transfer', Owner_Type__c = 'Opportunity Owner', Queue_Id__c = 'Benefits Transfer');

		Test.startTest();

		CreateTicketController.CreateTicketResponseWrapper objResponseWrapper = CreateTicketController.updateTicket(objTicket, objTicketConfig);
		//Asserting if the ticket is created successfully
		System.assertEquals(true, objResponseWrapper.blnIsSuccess, 'Create Ticket Controller - Ticket not created successfully');

		Test.stopTest();
	}

	/**
     * @Author      : Ankit CS
     * @Description : This method tests the updateTicket() method when Owner Type is Case Owner 
                     and Case is assigned to a user
    **/	
	@isTest
	static void testUpdateTicketUserAsCaseOwner() {
		Test.startTest();
		Case objCase = [SELECT Id, OwnerId, Status FROM Case WHERE Subject = 'Case assigned to user' LIMIT 1];

		// Initialize a new Ticket
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setStatus('New')
			.setEscalationReason('Test')
			.setPriority('Low')
			.setDescription('Test Case Ticket 1')
			.setHippoLink('test@yxz.com')
			.setCaseId(objCase.Id)
			.build();

		Ticket_Config__c objTicketConfig = [SELECT Id, Owner_Type__c, Queue_Id__c, Ticket_Record_Type__c FROM Ticket_Config__c LIMIT 1];
		CreateTicketController.CreateTicketResponseWrapper objResponseWrapper = CreateTicketController.updateTicket(objTicket, objTicketConfig);

		// Validate if Ticket was created successfully
		System.assertEquals(true, objResponseWrapper.blnIsSuccess, 'Ticket not created');

		Ticket__c objCreatedTicket = [SELECT Id, OwnerId FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assert(objCreatedTicket.Id != null, 'Ticket Id should not be null.');
		Test.stopTest();
	}

	/**
     * @Author      : Ankit CS
     * @Description : This method tests the updateTicket() method when Owner Type is Case Owner and 
                     Case is assigned to a queue and Status is New
    **/	
	@isTest
	static void testUpdateTicketCaseAssignedToQueue() {
		Case objCase = [SELECT Id, OwnerId, Status FROM Case WHERE Subject = 'Case assigned to queue' LIMIT 1];

		// Initialize a new Ticket
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setStatus('New')
			.setEscalationReason('Test')
			.setPriority('Low')
			.setDescription('Test Case Ticket 1')
			.setHippoLink('test@yxz.com')
			.setCaseId(objCase.Id)
			.build();

		Ticket_Config__c objTicketConfig = [SELECT Id, Owner_Type__c, Queue_Id__c, Ticket_Record_Type__c FROM Ticket_Config__c LIMIT 1];
		Test.startTest();
		CreateTicketController.CreateTicketResponseWrapper objResponseWrapper = CreateTicketController.updateTicket(objTicket, objTicketConfig);

		// Validate if Ticket was created successfully
		System.assertEquals(true, objResponseWrapper.blnIsSuccess, 'Ticket not created');

		Ticket__c objCreatedTicket = [SELECT Id, OwnerId FROM Ticket__c WHERE Id = :objTicket.Id];
		Group objGroup = [SELECT Id FROM Group WHERE Name = 'Member Ops - Submissions'];
		System.assert(objCreatedTicket.Id != null, 'Ticket Id should not be null.');
		Test.stopTest();
	}

	/**
     * @Author      : Ankit CS
     * @Description : This method tests the updateTicket() method when Owner Type is Case Owner 
                     and Case is assigned to a queue and Status is Submitted
    **/	
	@isTest
	static void testUpdateTicketCaseAssignedToQueueSubmitted() {
		Case objCase = [SELECT Id, OwnerId, Status FROM Case WHERE Subject = 'Case assigned to queue' LIMIT 1];

		// Initialize a new Ticket
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setStatus('New')
			.setEscalationReason('Test')
			.setPriority('Low')
			.setDescription('Test Case Ticket 1')
			.setHippoLink('test@yxz.com')
			.setCaseId(objCase.Id)
			.build();

		Ticket_Config__c objTicketConfig = [SELECT Id, Owner_Type__c, Queue_Id__c, Ticket_Record_Type__c FROM Ticket_Config__c LIMIT 1];
		objCase.Status = 'Submitted';
		CaseTriggerHelper.skipTrigger = true;
		update objCase;
		CaseTriggerHelper.skipTrigger = false;
		Test.startTest();
		CreateTicketController.CreateTicketResponseWrapper objResponseWrapper = CreateTicketController.updateTicket(objTicket, objTicketConfig);

		// Validate if Ticket was created successfully
		System.assertEquals(true, objResponseWrapper.blnIsSuccess, 'Ticket not created');

		Ticket__c objCreatedTicket = [SELECT Id, OwnerId FROM Ticket__c WHERE Id = :objTicket.Id];
		Group objGroup = [SELECT Id FROM Group WHERE Name = 'Member Ops - Follow Up'];
		System.assert(objCreatedTicket.Id != null, 'Ticket Id should not be null.');
		System.assertEquals(objCreatedTicket.OwnerId,objGroup.Id,'Ticket Owner Should be updated with Member Ops - Follow UP queue');
		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : To cover the catch blocks
	 **/	
	@isTest
	static void testExceptions() {
		Test.startTest();

		blnThrowException = true;
		CreateTicketController.CreateTicketResponseWrapper objResponseWrapper = CreateTicketController.loadCreateTicketData();
		// assert for exception
		System.assert(!objResponseWrapper.blnIsSuccess, 'Is Success should be false.');

		Ticket__c objTicket = new Ticket__c(Status__c = 'New', Escalation_Reason__c = 'Test', Priority__c = 'Low', Description__c = 'Test Description', Employee_Hippo_Link__c = 'test@yxz.com');

		// Create a new Ticket Config
		Ticket_Config__c objTicketConfig = new Ticket_Config__c(Name = 'Test', Ticket_Record_Type__c = 'Advising Fulfillment', Owner_Type__c = 'Assign to a Queue', Queue_Id__c = 'Member Fulfillment');

		objResponseWrapper = CreateTicketController.updateTicket(objTicket, objTicketConfig);
		// assert for exception
		System.assert(!objResponseWrapper.blnIsSuccess, 'Is Success should be false.');
		blnThrowException = false;

		Test.stopTest();
	}
  
	/**
	 * @Author      : Elavarasan N
	 * @Description : To cover the getTicketReasonInfo
	**/	
	@isTest
	static void testGetTicketReasonInfo() {

		Test.startTest();
		List<String> list_TicketReasonsMember = TicketConfigController.getTicketReasonInfo('Member Operations');
		List<String> list_TicketReasonsRisk = TicketConfigController.getTicketReasonInfo('Risk');
		System.assertEquals(2, list_TicketReasonsMember.size(), 'Ticket Reasons does not match for Member Operations');
		System.assertEquals(1, list_TicketReasonsRisk.size(), 'Ticket Reasons does not match for Risk');
		Test.stopTest();
	}

	/**
	 * @author Alex Xiong
	 * @description confirm API Integration Escalation Tickets get created with Status = New
	 */
	@isTest
	static void testAPIIntegrationEscalationStatus() {
		Ticket_Config__c objTicketConfig = new TestDataFactory.TicketConfigBuilder()
			.setName('Integration & Partnership Escalation')
			.setRecordType('API Integration Escalation')
			.setOwnerType('Assign to a Queue')
			.setQueueId('BizDev')
			.build();
		insert objTicketConfig;

		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
		.setRecordTypeId(TicketUtil.API_INTEGRATION_ESCALATION_TICKET_RT_ID)
		.setOwnerId(UserInfo.getUserId())
		.build();

		CreateTicketController.updateTicket(objTicket, objTicketConfig);

		List<Ticket__c> list_Ticket = [SELECT Id, Status__c FROM Ticket__c WHERE RecordTypeId = :TicketUtil.API_INTEGRATION_ESCALATION_TICKET_RT_ID];
		System.assertEquals('New', list_Ticket[0].Status__c, 'Status should be New');
	}
}