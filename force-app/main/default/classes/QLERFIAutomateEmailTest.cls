/**
 * @name         QLERFIAutomateEmailTest
 * @description  Test class for QLERFIAutomateEmailBatch * QLERFIAutomateEmailUtils
 * @author       Bhagat singh
 * @date         April 22, 2020
 * @revisions    Date ------------ Name ------------ Comments
 **/
@isTest
private class QLERFIAutomateEmailTest {
	@testsetup
	static void createTestData() {
		Utils.skipTrigger(true);

		Account objAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company').setName('test acc1').setZPCompanyId('100989001')
			.build();
		insert objAcc;

		List<Contact> list_Contacts = new List<Contact>{
			new TestDataFactory.ContactBuilder()
				.setRecordTypeId('Company').setAccountId(objAcc.Id).setZPUserId('200919001')
				.setFirstName('Test1').setLastName('Contact').setEmail('test.contact1@gusto.com')
				.build(),
			new TestDataFactory.ContactBuilder()
				.setRecordTypeId('Company').setAccountId(objAcc.Id).setZPUserId('200919002')
				.setFirstName('Test2').setLastName('Contact').setEmail('test.contact2@gusto.com')
				.build(),
			new TestDataFactory.ContactBuilder()
				.setRecordTypeId('Company').setAccountId(objAcc.Id).setZPUserId('200919003')
				.setFirstName('Test3').setLastName('Contact').setEmail('test.contact3@gusto.com')
				.build()
		};
		insert list_Contacts;

		List<Case> list_Cases = new List<Case>{
			new TestDataFactory.CaseBuilder()
				.setAccountId(objAcc.Id).setContactId(list_Contacts[0].Id).setRecordTypeId('MF QLE')
				.setOrigin('Email').setType('Payroll Care').setSubject('Payroll Care Case')
				.setDescription('Payroll Care Case').setSuppliedEmail('test.contact1@gusto.com')
				.build(),
			new TestDataFactory.CaseBuilder()
				.setAccountId(objAcc.Id).setContactId(list_Contacts[1].Id).setRecordTypeId('MF QLE')
				.setOrigin('Email').setType('Payroll Care').setSubject('Payroll Care Case')
				.setDescription('Payroll Care Case').setSuppliedEmail('test.contact2@gusto.com')
				.build(),
			new TestDataFactory.CaseBuilder()
				.setAccountId(objAcc.Id).setContactId(list_Contacts[2].Id).setRecordTypeId('Benefits Renewal Case')
				.setOrigin('Hippo').setType('Benefits Renewal').setSubject('Gusto benefits renewal')
				.setDescription('Gusto benefits renewal').setSuppliedEmail('test.contact3@gusto.com')
				.build()
		};
		insert list_Cases;

		Date dtNextReminder = System.today();
		list_Cases[1].RFI_3rd_Business_Day__c = dtNextReminder.addDays(-2);
		list_Cases[1].RFI_6th_Business_Day__c = dtNextReminder.addDays(-1);
		list_Cases[1].RFI_9th_Business_Day__c = dtNextReminder;
		list_Cases[1].Automated_RFI_Flow__c = true;
		list_Cases[1].RFI_Status__c = 'RFI 3';
		list_Cases[1].QLE_RFI_Type__c = 'Divorce';
		list_Cases[1].Insufficient_Proof_Reason__c = 'Test';

		list_Cases[0].RFI_3rd_Business_Day__c = dtNextReminder;
		list_Cases[0].Automated_RFI_Flow__c = true;
		list_Cases[0].RFI_Status__c = 'RFI 1';
		list_Cases[0].QLE_RFI_Type__c = 'Divorce';
		list_Cases[0].Insufficient_Proof_Reason__c = 'Test';

		for (Integer intIndex = 1; intIndex <= 6; intIndex++) {
			dtNextReminder = Utils.getNextBusinessDayFromDate(dtNextReminder);
			if (intIndex == 3) {
				list_Cases[0].RFI_6th_Business_Day__c = dtNextReminder;
			} else if (intIndex == 6) {
				list_Cases[0].RFI_9th_Business_Day__c = dtNextReminder;
			}
		}
		update list_Cases;

		TicketTriggerHelper.skipTrigger = true;
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.ADVISING_FULFILLMENT_TICKET_RT_ID)
			.setCaseId(list_Cases[2].Id)
			.setEscalationReason('Recertification')
			.setStatus('New')
			.setOwnerId(UserInfo.getUserId())
			.build();
		insert objTicket;
		TicketTriggerHelper.skipTrigger = false;
		Utils.skipTrigger(false);
	}

	/**
	 * @description  This method is used to test the QLERFIAutomateEmailBatch class process - Positive.
	 * @param        null
	 * @return       null
	**/
	@isTest
	static void testReminderEmailBatch() {
		Test.startTest();
		QLERFIAutomateEmailBatch objBatch = new QLERFIAutomateEmailBatch();
		ID idBatch = Database.executeBatch(objBatch);
		Test.stopTest();

		List<Case> list_Cases = [SELECT Id, RFI_Status__c FROM Case WHERE Contact.Email = 'test.contact1@gusto.com'];
		if(OrganizationUtilities.canSendEmails()){
			System.assert(list_Cases.size() > 0);
			System.assertEquals('RFI 2', list_Cases[0].RFI_Status__c, 'Status will updated successfully.');
		}
	}

	/**
	 * @description  This method is used to test the QLERFIAutomateEmailBatch class process - Negative.
	 * @param        null
	 * @return       null
	**/
	@isTest
	static void testReminderEmailBatchNegativeCase() {
		Test.startTest();
		List<Case> list_UpdateCases = new List<Case>();
		for (Case objCase : [SELECT Id, Automated_RFI_Flow__c FROM Case]) {
			objCase.Automated_RFI_Flow__c = false;
			list_UpdateCases.add(objCase);
		}
		update list_UpdateCases;

		QLERFIAutomateEmailBatch objBatch = new QLERFIAutomateEmailBatch();
		ID idBatch = Database.executeBatch(objBatch);
		Test.stopTest();

		List<Case> list_Cases = [SELECT Id, RFI_Status__c FROM Case WHERE Contact.Email = 'test.contact1@gusto.com'];
		System.assertEquals('RFI 1', list_Cases[0].RFI_Status__c, 'Status will not changed.');
	}

	/**
	 * @description  This method is used to test exception creation process of the QLERFIAutomateEmailBatch.
	 * @param        null
	 * @return       null
	**/
	@isTest
	static void testReminderEmailBatchException() {
		List<Contact> list_Contacts = [SELECT Id, Email FROM Contact];
		for (Contact objContact : list_Contacts) {
			objContact.Email = null;
		}
		update list_Contacts;

		Test.startTest();
		QLERFIAutomateEmailBatch objBatch = new QLERFIAutomateEmailBatch();
		ID idBatch = Database.executeBatch(objBatch);
		Test.stopTest();

		System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent');
		System.assertEquals(false, [SELECT Id FROM Exception_Log__c WHERE Class_Name__c = 'QLERFIAutomateEmailBatch'].isEmpty());
	}

	/**
	 * @description  This method is used to test the schedulable process of the QLERFIAutomateEmailBatch.
	 * @param        null
	 * @return       null
	**/
	@isTest
	static void testScheduleQLEBatch() {
		Test.startTest();
		QLERFIAutomateEmailBatch objSchedule = new QLERFIAutomateEmailBatch();
		String strJobId = system.schedule('Test QLE Schedule', '0 0 23 * * ?', objSchedule);
		Test.stopTest();

		System.assertNotEquals(null, strJobId, 'Job not scheduled');
	}

	/**
	 * @author		 Deepika Saini
	 * @description  This method is used to test the functionality of sending Follou Up 1 Emails.
	 * @param        null
	 * @return       null
	**/
	@isTest
	static void testFollowUp1EmailPositive () {
		CasetriggerHelper.skipTrigger = true;
		Case objCase = [SELECT Id, RFI_3rd_Business_Day__c, Automated_RFI_Flow__c FROM Case WHERE RecordType.Name = 'Benefits Renewal Case'];
		objCase.RFI_3rd_Business_Day__c = System.today();
		objCase.Automated_RFI_Flow__c = true;
		update objCase;
		CasetriggerHelper.skipTrigger = false;
		Test.startTest();
		QLERFIAutomateEmailBatch objBatch = new QLERFIAutomateEmailBatch();
		ID idBatch = Database.executeBatch(objBatch);
		Test.stopTest();
		if(OrganizationUtilities.canSendEmails()){
			EmailMessage objEmailMessage = [SELECT RelatedToId, Email_Template_Name__c FROM EmailMessage WHERE RelatedToId = : objCase.Id];
			Ticket__c objTicket = [Select Id, Recert_Status__c FROM Ticket__c WHERE Case__c = :objCase.Id];
			System.assert(objEmailMessage != null, 'Follow up email is send.');
			System.assertEquals('Follow_up_email_11', objEmailMessage.Email_Template_Name__c, 'Follow up 1 email is send.');
			System.assertNotEquals('Recert Failed', objTicket.Recert_Status__c, 'Status is set to Recert Failed');
		}
	}

	/**
	 * @author		 Deepika Saini
	 * @description  This method is used to test the functionality of sending Follou Up 2 Emails.
	 * @param        null
	 * @return       null
	**/
	@isTest
	static void testFollowUp2EmailPositive () {
		Case objCase = [SELECT Id FROM Case WHERE RecordType.Name = 'Benefits Renewal Case'];
		objCase.RFI_3rd_Business_Day__c = System.Today().addDays(-1);
		objCase.RFI_6th_Business_Day__c = System.Today();
		objCase.Automated_RFI_Flow__c = true;
		update objCase;
		
		Test.startTest();
		QLERFIAutomateEmailBatch objBatch = new QLERFIAutomateEmailBatch();
		ID idBatch = Database.executeBatch(objBatch);
		Test.stopTest();
		if(OrganizationUtilities.canSendEmails()){
			EmailMessage objEmailMessage = [SELECT RelatedToId, Email_Template_Name__c, FromAddress FROM EmailMessage WHERE RelatedToId = : objCase.Id];
			Ticket__c objTicket = [Select Id, Recert_Status__c FROM Ticket__c WHERE Case__c = :objCase.Id];
			System.assert(objEmailMessage != null, 'Follow up email is send.');
			System.assertEquals('renewals@gusto.com', objEmailMessage.FromAddress, 'Reminder email not sent from renewals@gusto.com.');
			System.assertEquals('Follow_up_email_21', objEmailMessage.Email_Template_Name__c, 'Follow up 2 email is send.');
			System.assertEquals('Recert Failed', objTicket.Recert_Status__c, 'Status is set to not Recert Failed');
		}
	}
}