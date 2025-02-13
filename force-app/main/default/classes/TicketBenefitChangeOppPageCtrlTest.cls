@isTest
private class TicketBenefitChangeOppPageCtrlTest {
	static testMethod void unitTestWithoutOppTktOwnerDiff() {
		Test.startTest();
		OpportunityTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;

		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits Change Case');
		cse.Subject = 'Test';
		cse.Description = 'Test';
		cse.Type = 'QLE';
		insert cse;

		Ticket__c tck = new Ticket__c();
		tck.RecordTypeId = Schema.SObjectType.Ticket__c.getRecordTypeInfosByName().get('Advising Fulfillment').getRecordTypeId();
		tck.Status__c = 'New';
		tck.Priority__c = 'Low';
		tck.Fulfillment_Case__c = cse.Id;
		insert tck;

		ApexPages.StandardController stdController = new ApexPages.StandardController(tck);
		TicketBenefitChangeOppPageCtrl extension = new TicketBenefitChangeOppPageCtrl(stdController);

		System.assert(extension.navigateToOpportunity() == null);
		System.assert(extension.hasError == true);

		extension.savemethod();
		Test.stopTest();
	}
	static testMethod void unitTestWithoutOppValidations() {
		Test.startTest();
		OpportunityTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;

		Account objAcc = new Account(Name = 'test account');
		insert objAcc;

		Contact objContact = new Contact(AccountId = objAcc.Id, LastName = 'last', Email = 'first@last.com');
		insert objContact;

		Case cse = new Case();
		cse.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits Change Case');
		cse.Subject = 'Test';
		cse.Description = 'Test';
		cse.Type = 'QLE';
		cse.AccountId = objAcc.Id;
		insert cse;

		Ticket__c tck = new Ticket__c();
		tck.RecordTypeId = Schema.SObjectType.Ticket__c.getRecordTypeInfosByName().get('Advising Fulfillment').getRecordTypeId();
		tck.Status__c = 'New';
		tck.Priority__c = 'Low';
		tck.Fulfillment_Case__c = cse.Id;
		tck.Account__c = objAcc.Id;
		insert tck;
		tck.OwnerId = UserInfo.getUserId();
		update tck;

		ApexPages.StandardController stdController = new ApexPages.StandardController(tck);
		TicketBenefitChangeOppPageCtrl extension = new TicketBenefitChangeOppPageCtrl(stdController);

		System.assert(extension.navigateToOpportunity() == null);

		extension.oppObj.Type = 'Transfer TAdA Plan';
		extension.checkBenefitType();

		extension.savemethod();

		extension.objTTFRecord.Contact__c = objContact.Id;
		extension.fetchPrimaryContact();

		extension.savemethod();

		extension.lst_Tada[0].isChecked = true;

		extension.savemethod();

		extension.lst_Tada[0].lineItem.Renewal_Date__c = System.today().addDays(5);

		extension.addNewRow();

		System.assert(extension.savemethod() == null);

		extension.lst_Tada[0].orderName = 'Flexible Spending Account - Medical';
		extension.checkBenefitType();
		System.assert(extension.savemethod() == null);

		Test.stopTest();
	}
	static testMethod void unitTestWithoutOppWithTaDa() {
		Test.startTest();
		OpportunityTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;

		Account objAcc = new Account(Name = 'test account');
		insert objAcc;

		Contact objContact = new Contact(AccountId = objAcc.Id, LastName = 'last', Email = 'first@last.com');
		insert objContact;

		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits Change Case');
		cse.Subject = 'Test';
		cse.Description = 'Test';
		cse.Type = 'QLE';
		cse.AccountId = objAcc.Id;
		insert cse;

		Ticket__c tck = new Ticket__c();
		tck.RecordTypeId = Schema.SObjectType.Ticket__c.getRecordTypeInfosByName().get('Advising Fulfillment').getRecordTypeId();
		tck.Status__c = 'New';
		tck.Priority__c = 'Low';
		tck.Fulfillment_Case__c = cse.Id;
		tck.Account__c = objAcc.Id;
		insert tck;
		tck.OwnerId = UserInfo.getUserId();
		update tck;

		ApexPages.StandardController stdController = new ApexPages.StandardController(tck);
		TicketBenefitChangeOppPageCtrl extension = new TicketBenefitChangeOppPageCtrl(stdController);

		extension.oppObj.Type = 'Transfer TAdA Plan';
		extension.checkBenefitType();
		extension.objTTFRecord.Contact__c = objContact.Id;
		extension.fetchPrimaryContact();
		extension.lst_Tada[0].isChecked = true;
		extension.lst_Tada[0].lineItem.Renewal_Date__c = system.today().addDays(5);

		System.assert(extension.savemethod() != null);

		Test.stopTest();
	}
	static testMethod void testWithAncillaryCoverageOppType() {
		Test.startTest();
		OpportunityTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;

		Account objAcc = new Account(Name = 'test account');
		insert objAcc;

		Contact objContact = new Contact(AccountId = objAcc.Id, LastName = 'last', Email = 'first@last.com');
		insert objContact;

		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits Change Case');
		cse.Subject = 'Test';
		cse.Description = 'Test';
		cse.Type = 'QLE';
		cse.AccountId = objAcc.Id;
		insert cse;

		Ticket__c tck = new Ticket__c();
		tck.RecordTypeId = Schema.SObjectType.Ticket__c.getRecordTypeInfosByName().get('Advising Fulfillment').getRecordTypeId();
		tck.Status__c = 'New';
		tck.Priority__c = 'Low';
		tck.Fulfillment_Case__c = cse.Id;
		tck.Account__c = objAcc.Id;
		insert tck;
		tck.OwnerId = UserInfo.getUserId();
		update tck;

		ApexPages.StandardController stdController = new ApexPages.StandardController(tck);
		TicketBenefitChangeOppPageCtrl extension = new TicketBenefitChangeOppPageCtrl(stdController);

		extension.oppObj.Type = 'Transfer TAdA and Ancillary Coverage';
		extension.checkBenefitType();
		extension.objTTFRecord.Contact__c = objContact.Id;
		extension.fetchPrimaryContact();
		extension.lst_Tada[0].isChecked = true;
		extension.lst_Tada[0].lineItem.Renewal_Date__c = system.today().addDays(5);

		System.assert(extension.savemethod() == null);

		Test.stopTest();
	}
	static testMethod void testWithNonTaDaOppType() {
		Test.startTest();
		OpportunityTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;

		Account objAcc = new Account(Name = 'test account');
		insert objAcc;

		Contact objContact = new Contact(AccountId = objAcc.Id, LastName = 'last', Email = 'first@last.com');
		insert objContact;

		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits Change Case');
		cse.Subject = 'Test';
		cse.Description = 'Test';
		cse.Type = 'QLE';
		cse.AccountId = objAcc.Id;
		insert cse;

		Ticket__c tck = new Ticket__c();
		tck.RecordTypeId = Schema.SObjectType.Ticket__c.getRecordTypeInfosByName().get('Advising Fulfillment').getRecordTypeId();
		tck.Status__c = 'New';
		tck.Priority__c = 'Low';
		tck.Fulfillment_Case__c = cse.Id;
		tck.Account__c = objAcc.Id;
		insert tck;
		tck.OwnerId = UserInfo.getUserId();
		update tck;

		ApexPages.StandardController stdController = new ApexPages.StandardController(tck);
		TicketBenefitChangeOppPageCtrl extension = new TicketBenefitChangeOppPageCtrl(stdController);

		extension.oppObj.Type = 'Add New Medical Plan';

		extension.checkBenefitType();
		extension.objTTFRecord.Contact__c = objContact.Id;
		extension.fetchPrimaryContact();
		extension.addNewRow();

		extension.savemethod();
		extension.addNewRow();
		extension.removeNewRow();
		extension.rowIndex = '1';
		extension.removeNewRow();
		Test.stopTest();
	}
	static testMethod void unitTestWithOpp() {
		Test.startTest();
		OpportunityTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;

		Account accRec = new Account();
		accRec.Name = 'Test Demo AccountName 1';
		accRec.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Company').getRecordTypeId();
		accRec.BillingStreet = 'Testing Avenue 1';
		accRec.BillingPostalCode = '123456';
		accRec.Company_Trade_Name__c = 'Company trade name 1';
		accRec.Phone = '19992344444';
		accRec.ShippingStreet = 'Testing Avenue 1';
		accRec.ShippingPostalCode = '123455';
		insert accRec;

		Opportunity opportunityRecord = new Opportunity();
		opportunityRecord.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Benefits Renewal').getRecordTypeId();
		opportunityRecord.Name = 'OppRecord';
		opportunityRecord.StageName = 'SAL';
		opportunityRecord.CloseDate = Date.newInstance(2016, 12, 9);
		opportunityRecord.AccountId = accRec.Id;
		insert opportunityRecord;

		Ticket__c tck = new Ticket__c();
		tck.RecordTypeId = Schema.SObjectType.Ticket__c.getRecordTypeInfosByName().get('Advising Fulfillment').getRecordTypeId();
		tck.Status__c = 'New';
		tck.Priority__c = 'Low';
		tck.Opportunity__c = opportunityRecord.Id;
		insert tck;

		ApexPages.StandardController stdController = new ApexPages.StandardController(tck);
		TicketBenefitChangeOppPageCtrl extension = new TicketBenefitChangeOppPageCtrl(stdController);

		System.assert(extension.navigateToOpportunity() != null);

		Test.stopTest();
	}

	static testMethod void testWithAllData() {
		Utils.skipTrigger(true);

		Account acc1 = TestUtility.CompanyAccount();

		Opportunity opp1 = TestUtility.BenefitsBoROpportunity();
		opp1.Account = acc1;
		opp1.Type = 'Transfer Ancillary Coverage';
		update opp1;

		case C1 = new case();
		C1.Accountid = acc1.id;
		C1.Type = 'Bor';
		insert C1;

		Benefit_Order__c boRec = new Benefit_Order__c();
		borec.Opportunity__c = opp1.Id;
		borec.Order_Status__c = 'Alignment Approved';
		borec.Application_Status__c = 'Plans Confirmed';
		boRec.RecordTypeId = cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR');
		borec.Renewal_Date__c = system.today();
		insert borec;

		Carrier__c obj_Carrier = new Carrier__c();
		obj_Carrier.Name = 'alegeus';
		obj_Carrier.Partner_Type__c = 'TAdA';
		obj_Carrier.Termination_Effective_Date__c = 'On the Date';
		obj_Carrier.State__c = 'al;ak';
		insert obj_Carrier;

		Carrier_Order__c obj_CarrierOrder = new Carrier_Order__c();
		obj_CarrierOrder.Name = 'TestCarrierOrder';
		obj_CarrierOrder.Carrier__c = obj_Carrier.Id;
		obj_CarrierOrder.Benefit_Order__c = borec.id;
		obj_CarrierOrder.Start_Date__c = System.today() - 50;
		obj_CarrierOrder.Renewal_Date__c = date.today();
		obj_CarrierOrder.RecordTypeId = Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');
		obj_CarrierOrder.Implementation_Stage__c = 'Implementing Plans';
		obj_CarrierOrder.OwnerId = UserInfo.getUserId();
		obj_CarrierOrder.Initial_Owner__c = UserInfo.getUserId();
		insert obj_CarrierOrder;

		Carrier_Order_Line_Item__c objCarrieOrderLineItem = new Carrier_Order_Line_Item__c();
		objCarrieOrderLineItem.Carrier_Order__c = obj_CarrierOrder.Id;
		objCarrieOrderLineItem.Renewal_Date__c = date.today();
		objCarrieOrderLineItem.Benefit_Types__c = 'Benefits BoR';
		insert objCarrieOrderLineItem;

		Contact Con = new Contact();
		Con.lastname = 'Test';
		Con.AccountId = acc1.Id;
		insert Con;

		Transition_to_Fulfillment__c ttf = new Transition_to_Fulfillment__c();
		insert ttf;

		Ticket__c t1 = new Ticket__c();
		t1.Carrier_Order__c = obj_CarrierOrder.id;
		t1.Status__c = 'new';
		t1.Benefit_Order__c = boRec.Id;
		t1.Opportunity__c = null;
        t1.Carrier__c = obj_Carrier.Id;
        t1.Account__c = acc1.Id;
        t1.Description__c = 'Test';
		insert t1;

		Utils.skipTrigger(false);

		ApexPages.StandardController stdController = new ApexPages.StandardController(t1);
		TicketBenefitChangeOppPageCtrl extension = new TicketBenefitChangeOppPageCtrl(stdController);

		extension.navigateToOpportunity();

		extension.savemethod();

		extension.oppObj.type = 'Transfer Ancillary Coverage';
		extension.checkBenefitType();

		extension.rowIndex = '0';
		extension.removeNewRow();
		extension.fetchBenefitType();
		extension.fetchPrimaryContact();
		extension.addNewRow();
		extension.createCarrierOrders();

		extension.getRenewalDate('HSA');
		extension.getRenewalDate('Flexible Spending Account - Medical');
		extension.getRenewalDate('Flexible Spending Account - Dependent Care');
	}
}