@isTest
private class BTTransitionToFulfilmentExtensionTest {
	public static final string strBenefitOrderType = 'New to BYB - OE';
	@testSetup
	static void introduceTestData() {
		skipTrigger(true);
		list<Opportunity> list_Opp = new List<Opportunity>();
		list<Account> list_acc = new List<Account>();

		Opportunity objOpp = TestUtility.BenefitsBoROpportunity();
		objOpp.Id__c = 'HIBORTRANSFERTTFCreation54454321';
		objOpp.Signing_Forms_Completed_Timestamp__c = system.now();
		objOpp.StageName = 'ER Confirm';
		list_Opp.add(objOpp);

		Opportunity objOpp2 = TestUtility.BenefitsBoROpportunity();
		objOpp2.Id__c = 'HIBORTRANSFERTTFCreation222222';
		objOpp2.Signing_Forms_Completed_Timestamp__c = system.now();
		objOpp2.StageName = 'ER Confirm';
		list_Opp.add(objOpp2);

		Opportunity objOpp3 = TestUtility.getNewOpportunity('Benefits BYOB', objOpp.AccountId);
		objOpp3.StageName = 'ER Confirm';
		objOpp3.Name = 'Benefits BYOB';
		list_Opp.add(objOpp3);

		Opportunity objOpp4 = TestUtility.BenefitsBoROpportunity();
		objOpp4.Id__c = 'HIBORTRANSFERTTFCreation333333';
		objOpp4.Signing_Forms_Completed_Timestamp__c = system.now();
		objOpp4.StageName = 'ER Confirm';
		list_Opp.add(objOpp4);

		update list_Opp;

		Account accRec = new Account(Id = objOpp.AccountId, Joined_Date_Panda__c = system.today(), ZP_Company_Id__c = getUniqueName() + '1');
		list_acc.add(accRec);

		Account accRec2 = new Account(Id = objOpp2.AccountId, Joined_Date_Panda__c = system.today(), ZP_Company_Id__c = getUniqueName() + '2');
		list_acc.add(accRec2);
		update list_acc;

		list<Contact> list_Contact = new List<Contact>();
		Id contactRecTypeId = Cache.getRecordTypeId('Contact', 'Company');
		Contact conRec1 = new Contact(AccountId = accRec.Id, LastName = 'test1', RecordTypeId = contactRecTypeId);
		list_Contact.add(conRec1);

		Contact conRec2 = new Contact(AccountId = accRec.Id, LastName = 'test2', RecordTypeId = contactRecTypeId);
		list_Contact.add(conRec2);
		insert list_Contact;

		list<Carrier__c> list_Carrier = new List<Carrier__c>();
		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Alegeus').setUniqueName('Alegeus').setKey('alegeus').setId('Alegeus54454321').setPartnerType('TAdA').build();
		list_Carrier.add(objCarrier);

		Carrier__c objCarrier2 = TestUtility.Carrier();
		objCarrier2.Key__c = 'OtherBTTTFNew';
		objCarrier2.ID__c = 'OtherBTTTFNew';
		list_Carrier.add(objCarrier2);
		Carrier__c objCarrier3 = TestUtility.Carrier();
		objCarrier3.Key__c = 'OtherBTNew';
		objCarrier3.ID__c = 'OtherBTNew';
		objCarrier3.Name = 'Other';
		list_Carrier.add(objCarrier3);

		Carrier__c objCarrier4 = TestUtility.Carrier();
		objCarrier4.Key__c = null;
		objCarrier4.ID__c = null;
		objCarrier4.Name = 'Aetna';
		list_Carrier.add(objCarrier4);
		upsert list_Carrier;

		list<HI_BoR_Transfer__c> list_hiBOR = new List<HI_BoR_Transfer__c>();
		HI_BoR_Transfer__c objHIBor = new HI_BoR_Transfer__c(
			Id__c = 'TTFCreation54454321',
			Benefit_Types__c = '["fsa", "commuter"]',
			Additional_Information__c = '{"administrators"=>{"fsa"=>"Zenefits", "commuter"=>"Zenefits"}, "title"=>"Benefits Administrator", "effective_month"=>1, "effective_month_same_as_medical"=>"yes"}'
		);
		list_hiBOR.add(objHIBor);

		HI_BoR_Transfer__c objHIBor2 = new HI_BoR_Transfer__c(
			Id__c = 'TTFCreation222222',
			Benefit_Types__c = '["fsa", "commuter"]',
			Additional_Information__c = '{"administrators"=>{"fsa"=>"Zenefits", "commuter"=>"Zenefits"}, "title"=>"Benefits Administrator", "effective_month"=>1, "effective_month_same_as_medical"=>"yes"}'
		);
		list_hiBOR.add(objHIBor2);
		insert list_hiBOR;

		list<HI_Carrier_Information__c> list_HICarrier = new List<HI_Carrier_Information__c>();
		HI_Carrier_Information__c objHICarrier = new HI_Carrier_Information__c(
			Id__c = 'HIBTTTFCreation123',
			Key__c = 'OtherBTTTFNew',
			Plan_Type__c = 'LTD',
			BOR_Transfer_Id__c = 'TTFCreation54454321'
		);
		list_HICarrier.add(objHICarrier);

		HI_Carrier_Information__c objHICarrier2 = new HI_Carrier_Information__c(Id__c = 'HIBTTTFCreation222', Key__c = 'OtherBTTTFNew', Plan_Type__c = 'LTD', BOR_Transfer_Id__c = 'TTFCreation222222');
		list_HICarrier.add(objHICarrier2);
		insert list_HICarrier;

		skipTrigger(false);
	}

	@isTest
	static void createTTFRecord() {
		skipTrigger(true);

		list<Opportunity> list_OppRec = [SELECT ID, AccountId FROM Opportunity];
		list<Contact> list_Contact = [SELECT Id FROM Contact];
		apexPages.currentPage().getParameters().put('oppId', string.valueOf(list_OppRec.get(0).Id));
		apexPages.currentPage().getParameters().put('retURL', '/' + string.valueOf(list_OppRec.get(0).Id));

		ApexPages.StandardController sc = new ApexPages.StandardController(new Transition_To_Fulfillment__c());
		BTTransitionToFulfilmentExtension controller = new BTTransitionToFulfilmentExtension(sc);

		for (BTTransitionToFulfilmentExtension.BenefitsWrapper wrapperRec : Controller.map_carrierKeyBenefitDetails.values()) {
			wrapperRec.objContact.Last_Activity_Date__c = date.newInstance(system.today().addMonths(3).Year(), system.today().addMonths(3).month(), 1);
			// wrapperRec.dtRenewalDate = system.today().addMonths(1);
		}
		controller.objTTFRecord.Contact__c = list_Contact.get(0).Id;
		controller.objTTFRecord.Exception_Request__c = 'Yes';
		controller.objTTFRecord.Reason_for_exception_request__c = 'Accountant has been let go';
		controller.objTTFRecord.Admin_Commited_High_Response_Level__c = 'N';
		controller.objTTFRecord.Any_lines_of_coverage_staying_external__c = 'Y';
		controller.objTTFRecord.Additional_Comments_Lines_of_Coverage__c = 'Test';
		controller.lst_eternalCoverageDetails.get(0).bln_isSelected = true;
		controller.lst_eternalCoverageDetails.get(1).bln_isSelected = true;
		controller.objTTFRecord.FSA_Renewal_Date__c = date.newInstance(system.today().addMonths(1).Year(), system.today().addMonths(1).month(), 1);
		controller.objTTFRecord.Send_Order__c = true;
		controller.objTTFRecord.Multi_EIN__c = 'Y';
		controller.objTTFRecord.BA_sent_expectation_setting_macro_to_ER__c = 'N';

		controller.lstAccWrapper = new List<BTTransitionToFulfilmentExtension.AccountWrapper>();
		controller.lstAccWrapper.add(new BTTransitionToFulfilmentExtension.AccountWrapper(new Account(id = list_OppRec.get(1).AccountId), true, 0));
		controller.selectedCompanyIndx = 0;
		controller.selectCompany();

		if (controller.lstAccWrapper == null || controller.lstAccWrapper.size() == 0) {
			controller.mapSelectedAccounts.put(list_OppRec.get(1).AccountId, new BTTransitionToFulfilmentExtension.AccountWrapper(new Account(id = list_OppRec.get(1).AccountId), true, 0));
		}
		controller.showBenefitOrderTypePage();
		controller.multiEINSendOrderCheck();

		boolean blnVal = controller.hasNext;
		blnVal = controller.hasPrevious;
		integer intVal = controller.pageNumber;
		controller.getTotalPages();
		controller.first();
		controller.last();
		controller.previous();
		controller.next();

		controller.strAccName = 'test';
		controller.searchAccounts();

		controller.strAccName = '';
		controller.searchAccounts();

		controller.lstAccWrapper.add(new BTTransitionToFulfilmentExtension.AccountWrapper(new Account(id = list_OppRec.get(1).AccountId), true, 0));
		controller.idAcccountToBeRemoved = list_OppRec.get(1).AccountId;
		controller.removeAccount();

		controller.cancelPage();
		skipTrigger(false);
	}

	@isTest
	static void updateTTFRecord() {
		skipTrigger(true);
		Id idTTFBoRRecordTypeId = TransitiontoFulfilmentUtil.strBenBorRecTypeId;

		list<Opportunity> list_OppRec = [SELECT ID, AccountId FROM Opportunity];
		list<Contact> list_Contact = [SELECT Id FROM Contact];

		OpportunityContactRole objContactRole = new OpportunityContactRole();
		objContactRole.OpportunityId = list_OppRec.get(0).Id;
		objContactRole.ContactId = list_Contact.get(0).Id;
		insert objContactRole;

		OpportunityContactRole objContactRole2 = new OpportunityContactRole();
		objContactRole2.OpportunityId = list_OppRec.get(0).Id;
		objContactRole2.ContactId = list_Contact.get(1).Id;
		objContactRole2.Check_Additional_POC__c = true;
		insert objContactRole2;

		Transition_to_Fulfillment__c objTTFRecord = new Transition_to_Fulfillment__c();
		objTTFRecord.Opportunity__c = list_OppRec.get(0).Id;
		objTTFRecord.Account__c = list_OppRec.get(0).AccountId;
		objTTFRecord.HSA_Renewal_Date__c = date.newInstance(system.today().addMonths(1).year(), system.today().addMonths(1).month(), 1);
		objTTFRecord.FSA_Renewal_Date__c = date.newInstance(system.today().addMonths(1).year(), system.today().addMonths(1).month(), 1);
		objTTFRecord.DCA_Renewal_Date__c = date.newInstance(system.today().addMonths(1).year(), system.today().addMonths(1).month(), 1);
		objTTFRecord.Type_of_TADA_s__c = 'Flexible Spending Account - Dependent Care;Commuter';
		objTTFRecord.Medical_Renewal_Date__c = 'alegeus>' + string.valueOf(system.today().addMonths(1).year()) + '/' + string.valueOf(system.today().addMonths(1).month()) + '/1';
		objTTFRecord.Multi_EIN__c = 'Y';
		objTTFRecord.RecordTypeId = idTTFBoRRecordTypeId;
		insert objTTFRecord;

		apexPages.currentPage().getParameters().put('Id', string.valueOf(objTTFRecord.Id));
		ApexPages.StandardController sc = new ApexPages.StandardController(objTTFRecord);
		BTTransitionToFulfilmentExtension controller = new BTTransitionToFulfilmentExtension(sc);

		controller.idPrimaryRole = objContactRole.Id;
		controller.list_POCWrapper.get(0).boolChkPrimary = true;
		controller.selectPrimary();

		controller.idSecRole = objContactRole2.Id;
		controller.selectSecondary();

		apexPages.currentPage().getParameters().put('ttfId', string.valueOf(objTTFRecord.Id));
		apexPages.currentPage().getParameters().put('source', 'DisplayEditTTS');
		BTTransitionToFulfilmentExtension customController = new BTTransitionToFulfilmentExtension();
		customController.objAttachmentNew.Name = 'Test Name';
		customController.objAttachmentNew.body = blob.valueOf('Test');
		customController.uploadAttachment();
		skipTrigger(false);
	}

	@isTest
	static void attachmentUploadCoverage() {
		list<Opportunity> list_OppRec = [SELECT ID FROM Opportunity];

		apexPages.currentPage().getParameters().put('oppId', string.valueOf(list_OppRec.get(0).Id));
		BTTransitionToFulfilmentExtension controller = new BTTransitionToFulfilmentExtension();
		controller.objAttachmentNew.Name = 'Test Name';
		controller.objAttachmentNew.body = blob.valueOf('Test');
		controller.uploadAttachment();
		controller.strAttachmentIdToDelete = [SELECT id FROM Attachment].get(0).Id;
		controller.deleteAttachmentRecord();
	}

	@isTest
	static void createTTFforBYB() {
		skipTrigger(true);
		List<Opportunity> list_OppsRec = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Benefits BYOB'];
		List<Contact> list_Contacts = [SELECT Id FROM Contact];
		List<Carrier__c> list_Carriers = [SELECT Id, Name, Key__c FROM Carrier__c WHERE Key__c = 'OtherBTTTFNew'];

		OpportunityContactRole objContactRole = new OpportunityContactRole();
		objContactRole.OpportunityId = list_OppsRec.get(0).Id;
		objContactRole.ContactId = list_Contacts.get(0).Id;
		insert objContactRole;

		OpportunityContactRole objContactRole2 = new OpportunityContactRole();
		objContactRole2.OpportunityId = list_OppsRec.get(0).Id;
		objContactRole2.ContactId = list_Contacts.get(1).Id;
		objContactRole2.Check_Broker_POC__c = true;
		insert objContactRole2;

		Test.startTest();
		ApexPages.currentPage().getParameters().put('oppId', String.valueOf(list_OppsRec.get(0).Id));
		ApexPages.currentPage().getParameters().put('retURL', '/' + String.valueOf(list_OppsRec.get(0).Id));

		ApexPages.StandardController sc = new ApexPages.StandardController(new Transition_To_Fulfillment__c());
		BTTransitionToFulfilmentExtension controller = new BTTransitionToFulfilmentExtension(sc);
		controller.objTTFRecord.Contact__c = list_Contacts.get(0).Id;
		controller.objTTFRecord.Priority__c = 'Y';
		controller.lst_priorityReasonDetails.get(0).bln_isSelected = true;
		controller.lst_eternalCoverageDetails.get(0).bln_isSelected = true;
		controller.lst_eternalCoverageDetails.get(1).bln_isSelected = true;

		controller.idPrimaryRole = objContactRole.Id;
		controller.list_POCWrapper[0].boolChkPrimary = true;
		controller.selectPrimary();

		controller.idBrokerRole = objContactRole2.Id;
		controller.list_POCWrapper[1].objContactRole.Check_Broker_POC__c = true;
		controller.selectBroker();
		controller.addNewCarrierRow();
		controller.intDeleteIndx = 0;
		controller.deleteCarrierName();
		controller.list_CarrierDetails[0].objCase.Carrier__c = list_Carriers[0].Id;
		controller.list_CarrierDetails[0].strCarrierName = list_Carriers[0].Name;
		controller.list_CarrierDetails[0].strCarrierKey = list_Carriers[0].Key__c;
		controller.list_CarrierDetails[0].objContact.Last_Activity_Date__c = Date.newInstance(System.today().addMonths(3).Year(), System.today().addMonths(3).month(), 1);
		controller.list_CarrierDetails[0].list_SelectedBenefitNames = new List<String>{ 'Medical', 'Dental', 'Vision', 'Life', 'LTD', 'STD' };
		controller.intSaveIndx = 0;
		controller.saveCarriers();
		controller.intEditIndx = 0;
		controller.editCarrierName();
		controller.objTTFRecord.Requires_Open_Enrollment_on_Gusto__c = 'Y';
		controller.objTTFRecord.Send_Order__c = true;
		controller.objRelatedOpp.SGHI_LGHI__c = 'SGHI';
		controller.objRelatedOpp.Funding_Type__c = 'Self Funded';
		controller.objTTFRecord.PEO__c = 'N';
		controller.objTTFRecord.Broker_Loyal__c = 'Y';
		controller.objTTFRecord.BoR_Eligible_Medical__c = 'N';
		controller.showBenefitOrderTypePage();
		controller.objBenefitOrder.Type__c = strBenefitOrderType;
		controller.saveTTFRecord();
		Test.stopTest();

		List<Transition_To_Fulfillment__c> list_TTFs = [
			SELECT Id, Medical_Carrier__c
			FROM Transition_To_Fulfillment__c
		];
		System.assert(list_TTFs.size() > 0);
		System.assert(list_TTFs[0].Medical_Carrier__c != null);
	}

	@isTest
	static void createTTFforBYBOtherCarrier() {
		skipTrigger(true);

		List<Opportunity> list_OppsRec = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Benefits BYOB'];
		List<Contact> list_Contacts = [SELECT Id FROM Contact];
		List<Carrier__c> list_Carriers = [SELECT Id, Name, Key__c FROM Carrier__c WHERE Name = 'Other'];
		OpportunityContactRole objContactRole = new OpportunityContactRole();
		objContactRole.OpportunityId = list_OppsRec.get(0).Id;
		objContactRole.ContactId = list_Contacts.get(0).Id;
		insert objContactRole;

		OpportunityContactRole objContactRole2 = new OpportunityContactRole();
		objContactRole2.OpportunityId = list_OppsRec.get(0).Id;
		objContactRole2.ContactId = list_Contacts.get(1).Id;
		objContactRole2.Check_Broker_POC__c = true;
		insert objContactRole2;

		Test.startTest();
		ApexPages.currentPage().getParameters().put('oppId', String.valueOf(list_OppsRec.get(0).Id));
		ApexPages.currentPage().getParameters().put('retURL', '/' + String.valueOf(list_OppsRec.get(0).Id));

		ApexPages.StandardController objStdController = new ApexPages.StandardController(new Transition_To_Fulfillment__c());
		BTTransitionToFulfilmentExtension objBTExtension = new BTTransitionToFulfilmentExtension(objStdController);
		objBTExtension.objTTFRecord.Contact__c = list_Contacts.get(0).Id;
		objBTExtension.objTTFRecord.Priority__c = 'Y';
		objBTExtension.lst_priorityReasonDetails.get(0).bln_isSelected = true;
		objBTExtension.lst_eternalCoverageDetails.get(0).bln_isSelected = true;
		objBTExtension.lst_eternalCoverageDetails.get(1).bln_isSelected = true;

		objBTExtension.idPrimaryRole = objContactRole.Id;
		objBTExtension.list_POCWrapper.get(0).boolChkPrimary = true;
		objBTExtension.selectPrimary();

		objBTExtension.idBrokerRole = objContactRole2.Id;
		objBTExtension.list_POCWrapper.get(1).objContactRole.Check_Broker_POC__c = true;
		objBTExtension.selectBroker();
		objBTExtension.addNewCarrierRow();
		objBTExtension.intSaveIndx = 0;
		objBTExtension.saveCarriers();
		objBTExtension.intDeleteIndx = 0;
		objBTExtension.deleteCarrierName();
		objBTExtension.list_CarrierDetails[0].objCase.Carrier__c = list_Carriers[0].Id;
		objBTExtension.list_CarrierDetails[0].strCarrierName = list_Carriers[0].Name;
		objBTExtension.list_CarrierDetails[0].strCarrierKey = list_Carriers[0].Key__c;
		objBTExtension.list_CarrierDetails[0].objContact.Last_Activity_Date__c = Date.newInstance(System.today().addMonths(3).Year(), System.today().addMonths(3).month(), 1);
		objBTExtension.list_CarrierDetails[0].strOtherCarrier = 'New Carrier';
		objBTExtension.list_CarrierDetails[0].list_SelectedBenefitNames = new List<String>{ 'Medical', 'Dental', 'Vision', 'Life', 'LTD', 'STD' };
		objBTExtension.intSaveIndx = 0;
		objBTExtension.saveCarriers();
		objBTExtension.intEditIndx = 0;
		objBTExtension.editCarrierName();
		objBTExtension.objTTFRecord.Requires_Open_Enrollment_on_Gusto__c = 'Y';
		objBTExtension.objTTFRecord.Send_Order__c = true;
		objBTExtension.objRelatedOpp.SGHI_LGHI__c = 'SGHI';
		objBTExtension.objRelatedOpp.Funding_Type__c = 'Self Funded';
		objBTExtension.objTTFRecord.PEO__c = 'N';
		objBTExtension.objTTFRecord.Broker_Loyal__c = 'Y';
		objBTExtension.objTTFRecord.BoR_Eligible_Medical__c = 'N';
		objBTExtension.showBenefitOrderTypePage();
		objBTExtension.objBenefitOrder.Type__c = strBenefitOrderType;
		objBTExtension.saveTTFRecord();

		Test.stopTest();

		List<Transition_To_Fulfillment__c> list_TTFs = [
			SELECT Id, Medical_Carrier__c, Medical_New_carriers__c
			FROM Transition_To_Fulfillment__c
		];
		System.assert(list_TTFs.size() > 0);
		System.assert(list_TTFs[0].Medical_Carrier__c != null);
		System.assert(list_TTFs[0].Medical_New_carriers__c != null);

		skipTrigger(false);
		OpportunityContactRole objContactRole1 = [SELECT Id, Check_Additional_POC__c FROM OpportunityContactRole LIMIT 1];
		System.assert(objContactRole1.Check_Additional_POC__c = true);
	}

	@isTest
	static void createTTFforBYBWithErrorCarrierMissing() {
		skipTrigger(true);

		List<Opportunity> list_OppsRec = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Benefits BYOB'];
		List<Contact> list_Contactss = [SELECT Id FROM Contact];
		List<Carrier__c> list_Carriers = [SELECT Id, Name, Key__c FROM Carrier__c WHERE Name = 'Other'];

		Test.startTest();
		ApexPages.currentPage().getParameters().put('oppId', String.valueOf(list_OppsRec.get(0).Id));
		ApexPages.currentPage().getParameters().put('retURL', '/' + String.valueOf(list_OppsRec.get(0).Id));

		ApexPages.StandardController objStdController = new ApexPages.StandardController(new Transition_To_Fulfillment__c());
		BTTransitionToFulfilmentExtension objBTExtension = new BTTransitionToFulfilmentExtension(objStdController);
		objBTExtension.objTTFRecord.Exception_Request__c = 'Yes';
		objBTExtension.showBenefitOrderTypePage();
		objBTExtension.objTTFRecord.Priority__c = 'Y';
		objBTExtension.addNewCarrierRow();
		objBTExtension.list_CarrierDetails[0].objCase.Carrier__c = null;
		objBTExtension.showBenefitOrderTypePage();
		Test.stopTest();
		ApexPages.Message[] objPageMessage = ApexPages.getMessages();
		System.assertNotEquals(0, objPageMessage.size());

		Boolean blnIsMessageFound = false;

		for (ApexPages.Message objMessage : objPageMessage) {
			if (objMessage.getSummary() == 'Carrier is required.' && objMessage.getSeverity() == ApexPages.Severity.WARNING) {
				blnIsMessageFound = true;
			}
		}
		System.assert(blnIsMessageFound);
	}

	@isTest
	static void createTTFforBYBWithBenefitTypeMissing() {
		skipTrigger(true);

		List<Opportunity> list_OppsRec = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Benefits BYOB'];
		List<Contact> list_Contactss = [SELECT Id FROM Contact];
		List<Carrier__c> list_Carriers = [SELECT Id, Name, Key__c FROM Carrier__c WHERE Name = 'Other'];

		Test.startTest();
		ApexPages.currentPage().getParameters().put('oppId', String.valueOf(list_OppsRec.get(0).Id));
		ApexPages.currentPage().getParameters().put('retURL', '/' + String.valueOf(list_OppsRec.get(0).Id));

		ApexPages.StandardController objStdController = new ApexPages.StandardController(new Transition_To_Fulfillment__c());
		BTTransitionToFulfilmentExtension objBTExtension = new BTTransitionToFulfilmentExtension(objStdController);
		objBTExtension.objTTFRecord.Exception_Request__c = 'Yes';
		objBTExtension.showBenefitOrderTypePage();
		objBTExtension.objTTFRecord.Priority__c = 'Y';
		objBTExtension.addNewCarrierRow();
		objBTExtension.list_CarrierDetails[0].objCase.Carrier__c = list_Carriers[0].Id;
		objBTExtension.list_CarrierDetails[0].strCarrierName = list_Carriers[0].Name;
		objBTExtension.list_CarrierDetails[0].strCarrierKey = list_Carriers[0].Key__c;
		objBTExtension.showBenefitOrderTypePage();
		Test.stopTest();
		ApexPages.Message[] objPageMessage = ApexPages.getMessages();
		System.assertNotEquals(0, objPageMessage.size());

		Boolean blnIsMessageFound = false;

		for (ApexPages.Message objMessage : objPageMessage) {
			if (objMessage.getSummary() == 'Benefit Type Should be Selected.' && objMessage.getSeverity() == ApexPages.Severity.WARNING) {
				blnIsMessageFound = true;
			}
		}
		System.assert(blnIsMessageFound);
	}

	@isTest
	static void createTTFforBYBWithRenewalDateMissing() {
		skipTrigger(true);

		List<Opportunity> list_OppsRec = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Benefits BYOB'];
		List<Contact> list_Contactss = [SELECT Id FROM Contact];
		List<Carrier__c> list_Carriers = [SELECT Id, Name, Key__c FROM Carrier__c WHERE Name = 'Other'];

		Test.startTest();
		ApexPages.currentPage().getParameters().put('oppId', String.valueOf(list_OppsRec.get(0).Id));
		ApexPages.currentPage().getParameters().put('retURL', '/' + String.valueOf(list_OppsRec.get(0).Id));

		ApexPages.StandardController objStdController = new ApexPages.StandardController(new Transition_To_Fulfillment__c());
		BTTransitionToFulfilmentExtension objBTExtension = new BTTransitionToFulfilmentExtension(objStdController);
		objBTExtension.objTTFRecord.Exception_Request__c = 'Yes';
		objBTExtension.showBenefitOrderTypePage();
		objBTExtension.objTTFRecord.Priority__c = 'Y';
		objBTExtension.addNewCarrierRow();
		objBTExtension.list_CarrierDetails[0].objCase.Carrier__c = list_Carriers[0].Id;
		objBTExtension.list_CarrierDetails[0].strCarrierName = list_Carriers[0].Name;
		objBTExtension.list_CarrierDetails[0].strCarrierKey = list_Carriers[0].Key__c;
		objBTExtension.list_CarrierDetails[0].list_SelectedBenefitNames = new List<String>{ 'Medical', 'Dental', 'Vision', 'Life', 'LTD', 'STD' };
		objBTExtension.showBenefitOrderTypePage();
		Test.stopTest();
		ApexPages.Message[] objPageMessage = ApexPages.getMessages();
		System.assertNotEquals(0, objPageMessage.size());

		Boolean blnIsMessageFound = false;

		for (ApexPages.Message objMessage : objPageMessage) {
			if (objMessage.getSummary() == 'Benefits renewal date is required.' && objMessage.getSeverity() == ApexPages.Severity.WARNING) {
				blnIsMessageFound = true;
			}
		}
		System.assert(blnIsMessageFound);
	}

	@isTest
	static void createTTFforBYBWithInvalidRenewalDate() {
		skipTrigger(true);

		List<Opportunity> list_OppsRec = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Benefits BYOB'];
		List<Contact> list_Contactss = [SELECT Id FROM Contact];
		List<Carrier__c> list_Carriers = [SELECT Id, Name, Key__c FROM Carrier__c WHERE Name = 'Other'];

		Test.startTest();
		ApexPages.currentPage().getParameters().put('oppId', String.valueOf(list_OppsRec.get(0).Id));
		ApexPages.currentPage().getParameters().put('retURL', '/' + String.valueOf(list_OppsRec.get(0).Id));

		ApexPages.StandardController objStdController = new ApexPages.StandardController(new Transition_To_Fulfillment__c());
		BTTransitionToFulfilmentExtension objBTExtension = new BTTransitionToFulfilmentExtension(objStdController);
		objBTExtension.objTTFRecord.Exception_Request__c = 'Yes';
		objBTExtension.showBenefitOrderTypePage();
		objBTExtension.objTTFRecord.Priority__c = 'Y';
		objBTExtension.addNewCarrierRow();
		objBTExtension.list_CarrierDetails[0].objCase.Carrier__c = list_Carriers[0].Id;
		objBTExtension.list_CarrierDetails[0].strCarrierName = list_Carriers[0].Name;
		objBTExtension.list_CarrierDetails[0].strCarrierKey = list_Carriers[0].Key__c;
		objBTExtension.list_CarrierDetails[0].list_SelectedBenefitNames = new List<String>{ 'Medical', 'Dental', 'Vision', 'Life', 'LTD', 'STD' };
		objBTExtension.list_CarrierDetails[0].objContact.Last_Activity_Date__c = Date.newInstance(System.today().addMonths(3).Year(), System.today().addMonths(3).month(), 7);
		objBTExtension.showBenefitOrderTypePage();
		Test.stopTest();
		ApexPages.Message[] objPageMessage = ApexPages.getMessages();
		System.assertNotEquals(0, objPageMessage.size());

		Boolean blnIsMessageFound = false;

		for (ApexPages.Message objMessage : objPageMessage) {
			if (objMessage.getSummary() == 'Benefit Renewal Date must be in the future, within the next year, 1st or 15th of month.' && objMessage.getSeverity() == ApexPages.Severity.WARNING) {
				blnIsMessageFound = true;
			}
		}
		System.assert(blnIsMessageFound);
	}

	@isTest
	static void createTTFforBYBWithError() {
		skipTrigger(true);

		List<Opportunity> list_OppsRec = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Benefits BYOB'];
		List<Contact> list_Contactss = [SELECT Id FROM Contact];
		List<Carrier__c> list_Carriers = [SELECT Id, Name, Key__c FROM Carrier__c WHERE Name = 'Other'];

		Test.startTest();
		ApexPages.currentPage().getParameters().put('oppId', String.valueOf(list_OppsRec.get(0).Id));
		ApexPages.currentPage().getParameters().put('retURL', '/' + String.valueOf(list_OppsRec.get(0).Id));

		ApexPages.StandardController objStdController = new ApexPages.StandardController(new Transition_To_Fulfillment__c());
		BTTransitionToFulfilmentExtension objBTExtension = new BTTransitionToFulfilmentExtension(objStdController);
		objBTExtension.objTTFRecord.Exception_Request__c = 'Yes';
		objBTExtension.showBenefitOrderTypePage();
		objBTExtension.objTTFRecord.Priority__c = 'Y';
		objBTExtension.addNewCarrierRow();
		objBTExtension.list_CarrierDetails[0].objCase.Carrier__c = list_Carriers[0].Id;
		objBTExtension.list_CarrierDetails[0].strCarrierName = list_Carriers[0].Name;
		objBTExtension.list_CarrierDetails[0].strCarrierKey = list_Carriers[0].Key__c;
		objBTExtension.list_CarrierDetails[0].list_SelectedBenefitNames = new List<String>{ 'Medical', 'Dental', 'Vision', 'Life', 'LTD', 'STD' };
		objBTExtension.list_CarrierDetails[0].objContact.Last_Activity_Date__c = Date.newInstance(System.today().addMonths(3).Year(), System.today().addMonths(3).month(), 1);
		objBTExtension.showBenefitOrderTypePage();

		Test.stopTest();

		List<Transition_To_Fulfillment__c> list_TTFs = [
			SELECT Id, Medical_Carrier__c, Medical_New_carriers__c
			FROM Transition_To_Fulfillment__c
		];
		System.assert(list_TTFs.size() == 0);

		ApexPages.Message[] objPageMessage = ApexPages.getMessages();
		System.assertNotEquals(0, objPageMessage.size());

		Boolean blnIsMessageFound = false;

		for (ApexPages.Message objMessage : objPageMessage) {
			if (objMessage.getSummary() == 'Enter Other Carrier Name.' && objMessage.getSeverity() == ApexPages.Severity.WARNING) {
				blnIsMessageFound = true;
			}
		}
		System.assert(blnIsMessageFound);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : If Join date is blank and Anchor Pay Date in current month then user can closed the opportunity.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void createTTFWithAnchorPayDate() {
		skipTrigger(true);

		List<Opportunity> list_OppsRec = [SELECT Id, AccountId FROM Opportunity WHERE RecordType.Name = 'Benefits BoR' AND Id__c = 'HIBORTRANSFERTTFCreation333333'];
		Opportunity objOpp = list_OppsRec[0];
		List<Contact> list_Contacts = [SELECT Id FROM Contact];
		List<Carrier__c> list_Carriers = [SELECT Id, Name, Key__c FROM Carrier__c WHERE Name = 'Other'];
		Account objAccount = new Account(Id = objOpp.AccountId);
		objAccount.Joined_Date_Panda__c = null;
		objAccount.Anchor_Pay_Date__c = Date.today();
		update objAccount;

		objOpp.Benefits_Setup_Steps_Completed__c = '6';
		update objOpp;

		Test.startTest();
		ApexPages.currentPage().getParameters().put('oppId', String.valueOf(objOpp.Id));
		ApexPages.currentPage().getParameters().put('retURL', '/' + String.valueOf(objOpp.Id));

		ApexPages.StandardController objStdController = new ApexPages.StandardController(new Transition_To_Fulfillment__c());
		BTTransitionToFulfilmentExtension objBTExtension = new BTTransitionToFulfilmentExtension(objStdController);
		objBTExtension.objTTFRecord.Send_Order__c = true;
		objBTExtension.objRelatedOpp.SGHI_LGHI__c = 'SGHI';
		objBTExtension.objRelatedOpp.Funding_Type__c = 'Self Funded';
		objBTExtension.objTTFRecord.PEO__c = 'N';
		objBTExtension.objTTFRecord.Contact__c = list_Contacts.get(0).Id;
		objBTExtension.objTTFRecord.Any_lines_of_coverage_staying_external__c = 'N';
		objBTExtension.showBenefitOrderTypePage();

		Test.stopTest();

		System.assertEquals([SELECT StageName FROM Opportunity WHERE Id = :objOpp.Id].StageName, 'Closed Won');
	}

	/**
	 * @Author        Deepika Saini
	 * @Description   Test the functionality of byb ttf when key of entered is not present
	 * @Parm          N/A
	 * @Return        N/A
	 **/
	@isTest
	static void createTTFforBYBCarrierKeyMissing() {
		skipTrigger(true);

		List<Opportunity> list_OppsRec = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Benefits BYOB'];
		List<Contact> list_Contacts = [SELECT Id FROM Contact];
		List<Carrier__c> list_Carriers = [SELECT Id, Name, Key__c FROM Carrier__c WHERE Key__c = NULL];

		Test.startTest();
		ApexPages.currentPage().getParameters().put('oppId', String.valueOf(list_OppsRec.get(0).Id));
		ApexPages.currentPage().getParameters().put('retURL', '/' + String.valueOf(list_OppsRec.get(0).Id));

		ApexPages.StandardController objStdController = new ApexPages.StandardController(new Transition_To_Fulfillment__c());
		BTTransitionToFulfilmentExtension objBTExtension = new BTTransitionToFulfilmentExtension(objStdController);
		objBTExtension.objTTFRecord.Exception_Request__c = 'Yes';
		objBTExtension.showBenefitOrderTypePage();
		objBTExtension.objTTFRecord.Priority__c = 'Y';
		objBTExtension.addNewCarrierRow();
		objBTExtension.list_CarrierDetails[0].objCase.Carrier__c = list_Carriers[0].Id;
		objBTExtension.list_CarrierDetails[0].strCarrierName = list_Carriers[0].Name;
		objBTExtension.list_CarrierDetails[0].strCarrierKey = list_Carriers[0].Key__c;
		objBTExtension.list_CarrierDetails[0].list_SelectedBenefitNames = new List<String>{ 'Medical', 'Dental', 'Vision', 'Life', 'LTD', 'STD' };
		objBTExtension.list_CarrierDetails[0].objContact.Last_Activity_Date__c = Date.newInstance(System.today().addMonths(3).Year(), System.today().addMonths(3).month(), 1);
		objBTExtension.showBenefitOrderTypePage();

		Test.stopTest();
		List<Transition_To_Fulfillment__c> list_TTFs = [
			SELECT Id, Medical_Carrier__c, Medical_New_carriers__c
			FROM Transition_To_Fulfillment__c
		];
		System.assert(list_TTFs.size() == 0);

		ApexPages.Message[] objPageMessage = ApexPages.getMessages();
		System.assertNotEquals(0, objPageMessage.size());

		Boolean blnIsMessageFound = false;

		for (ApexPages.Message objMessage : objPageMessage) {
			if (
				objMessage.getSummary() == 'Carrier is inactive please select an active carrier or select Other and enter the new carrier name in' &&
				objMessage.getSeverity() == ApexPages.Severity.WARNING
			) {
				blnIsMessageFound = true;
			}
		}
		System.assert(blnIsMessageFound);
	}

	/**
	 * @author        Deepika Saini
	 * @description   Test the functionality of byb ttf when Requires_Open_Enrollment_on_Gusto__c is not selected.
	 * @param          N/A
	 * @return        N/A
	 **/
	@isTest
	static void createTTFForBYBOpenEnrollmentNeg() {
		skipTrigger(true);
		List<Opportunity> list_OppsRec = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Benefits BYOB'];
		List<Contact> list_Contacts = [SELECT Id FROM Contact];
		List<Carrier__c> list_Carriers = [SELECT Id, Name, Key__c FROM Carrier__c WHERE Key__c = 'OtherBTTTFNew'];

		OpportunityContactRole objContactRole = new OpportunityContactRole();
		objContactRole.OpportunityId = list_OppsRec.get(0).Id;
		objContactRole.ContactId = list_Contacts.get(0).Id;
		insert objContactRole;

		OpportunityContactRole objContactRole2 = new OpportunityContactRole();
		objContactRole2.OpportunityId = list_OppsRec.get(0).Id;
		objContactRole2.ContactId = list_Contacts.get(1).Id;
		objContactRole2.Check_Broker_POC__c = true;
		insert objContactRole2;

		Test.startTest();
		ApexPages.currentPage().getParameters().put('oppId', String.valueOf(list_OppsRec.get(0).Id));
		ApexPages.currentPage().getParameters().put('retURL', '/' + String.valueOf(list_OppsRec.get(0).Id));

		ApexPages.StandardController objStandardCtrl = new ApexPages.StandardController(new Transition_To_Fulfillment__c());
		BTTransitionToFulfilmentExtension objBTController = new BTTransitionToFulfilmentExtension(objStandardCtrl);
		objBTController.objTTFRecord.Contact__c = list_Contacts.get(0).Id;
		objBTController.objTTFRecord.Priority__c = 'Y';
		objBTController.lst_priorityReasonDetails.get(0).bln_isSelected = true;
		objBTController.lst_eternalCoverageDetails.get(0).bln_isSelected = true;
		objBTController.lst_eternalCoverageDetails.get(1).bln_isSelected = true;

		objBTController.idPrimaryRole = objContactRole.Id;
		objBTController.list_POCWrapper[0].boolChkPrimary = true;
		objBTController.selectPrimary();

		objBTController.idBrokerRole = objContactRole2.Id;
		objBTController.list_POCWrapper[1].objContactRole.Check_Broker_POC__c = true;
		objBTController.selectBroker();
		objBTController.addNewCarrierRow();
		objBTController.intDeleteIndx = 0;
		objBTController.deleteCarrierName();
		objBTController.list_CarrierDetails[0].objCase.Carrier__c = list_Carriers[0].Id;
		objBTController.list_CarrierDetails[0].strCarrierName = list_Carriers[0].Name;
		objBTController.list_CarrierDetails[0].strCarrierKey = list_Carriers[0].Key__c;
		objBTController.list_CarrierDetails[0].objContact.Last_Activity_Date__c = Date.newInstance(System.today().addMonths(3).Year(), System.today().addMonths(3).month(), 1);
		objBTController.list_CarrierDetails[0].list_SelectedBenefitNames = new List<String>{ 'Medical', 'Dental', 'Vision', 'Life', 'LTD', 'STD' };
		objBTController.intSaveIndx = 0;
		objBTController.saveCarriers();
		objBTController.intEditIndx = 0;
		objBTController.editCarrierName();
		objBTController.objTTFRecord.Send_Order__c = true;
		objBTController.showBenefitOrderTypePage();
		objBTController.objBenefitOrder.Type__c = strBenefitOrderType;
		objBTController.saveTTFRecord();
		Test.stopTest();

		List<Transition_To_Fulfillment__c> list_TTFs = [
			SELECT Id, Medical_Carrier__c
			FROM Transition_To_Fulfillment__c
		];
		System.assert(list_TTFs.size() == 0);

		ApexPages.Message[] objPageMessage = ApexPages.getMessages();
		System.assertNotEquals(0, objPageMessage.size());

		Boolean blnIsMessageFound = false;

		for (ApexPages.Message objMessage : objPageMessage) {
			if (objMessage.getSummary() == 'Please select Requires Open Enrollment on Gusto?' && objMessage.getSeverity() == ApexPages.Severity.WARNING) {
				blnIsMessageFound = true;
			}
		}
		System.assert(blnIsMessageFound);
	}
	/**
	 * @Author        Omar Benitez
	 * @Description   Test the functionality of UpdatePreferedBroker
	 * @Parm          N/A
	 * @Return        N/A
	 **/
	@isTest
	static void testUpdatePreferedBroker() {
		skipTrigger(true);
		List<Opportunity> list_OppsRec = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Benefits BYOB'];
		Test.startTest();
		ApexPages.currentPage().getParameters().put('oppId', String.valueOf(list_OppsRec.get(0).Id));
		ApexPages.currentPage().getParameters().put('retURL', '/' + String.valueOf(list_OppsRec.get(0).Id));
		ApexPages.StandardController objStandardCtrl = new ApexPages.StandardController(new Transition_To_Fulfillment__c());
		BTTransitionToFulfilmentExtension objBTController = new BTTransitionToFulfilmentExtension(objStandardCtrl);
		objBTController.objTTFRecord.Handed_off_to_preferred_broker_partner__c = true;
		objBTController.objTTFRecord.Preferred_Broker__c = 'Sequoia';
		objBTController.objTTFRecord.Handed_off_to_preferred_broker_partner__c = false;
		objBTController.updatePreferedBroker();
		Test.stopTest();
		System.assertEquals(null, objBTController.objTTFRecord.Preferred_Broker__c, 'Preferred_Broker__c should be null');
	}
	/**
	 * @Author        Omar Benitez
	 * @Description   Test the functionality of updateBoREligibleMedical
	 * @Parm          N/A
	 * @Return        N/A
	 **/
	@isTest
	static void testUpdateBoREligibleMedical() {
		skipTrigger(true);
		List<Opportunity> list_OppsRec = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Benefits BYOB'];
		Test.startTest();
		ApexPages.currentPage().getParameters().put('oppId', String.valueOf(list_OppsRec.get(0).Id));
		ApexPages.currentPage().getParameters().put('retURL', '/' + String.valueOf(list_OppsRec.get(0).Id));
		ApexPages.StandardController objStandardCtrl = new ApexPages.StandardController(new Transition_To_Fulfillment__c());
		BTTransitionToFulfilmentExtension objBTController = new BTTransitionToFulfilmentExtension(objStandardCtrl);
		objBTController.objTTFRecord.BoR_Eligible_Medical__c = 'Y';
		objBTController.updateBoREligibleMedical();
		Test.stopTest();
		System.assertEquals(true, objBTController.blnBYBReason, 'blnBYBReason flag should be true when BoR Eligible Medican is Y');
		objBTController.objTTFRecord.BoR_Eligible_Medical__c = 'N';
		objBTController.updateBoREligibleMedical();
		System.assertEquals(false, objBTController.blnBYBReason, 'blnBYBReason flag should be false when BoR Eligible Medican is N');
	}
	static void skipTrigger(Boolean blnFlag) {
		OpportunityTriggerHelper.skipTrigger = blnFlag;
		AccountTriggerHelper.skipTrigger = blnFlag;
		OppRelatedTrackTriggerHelper.skipTrigger = blnFlag;
		TransitiontoFulfilmentTriggerHelper.skipTrigger = blnFlag;
		ContactTriggerHelper.skipTrigger = blnFlag;
		HIBorTransferTriggerHelper.skipTrigger = blnFlag;
		HICarrierInformationTriggerHelper.skipTrigger = blnFlag;
	}

	static string getUniqueName() {
		String dateString = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
		Integer randomInt = Integer.valueOf(math.rint(math.random() * 1000000));
		String uniqueName = dateString + randomInt;
		return uniqueName.left(19);
	}
}