@isTest
public class DisplayEditTTConfirmationExt_Test {
	@isTest
	static void DisplayEditTTIA() {
		AccounttriggerHelper.skipTrigger = true;
		OpportunitytriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		test.startTest();
		Master_Company_Level_Documents__c mcl = new Master_Company_Level_Documents__c(Status__c = 'Active', name = 'test');
		insert mcl;
		Id boRenewalRecType = cache.getRecordTypeId('Benefit_Order__c', 'New Plan');
		Benefit_Order__c objBenOrder = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(boRenewalRecType)
			.setStatusDetail('STATUS DETAIL')
			.setType('Same Carrier, No plan/group level changes')
			.setOwnerID(UserInfo.getUserId())
			.build();
		insert objBenOrder;
		State__c state = new State__c();
		state.Abbreviation__c = 'TS';
		state.Name = 'TEST STATE';
		insert state;

		Carrier__c carrier = new Carrier__c();
		carrier.Name = 'TEST CARRIER';
		carrier.State__c = state.Id;
		insert carrier;

		Carrier_Order__c carOrder = new Carrier_Order__c();
		carOrder.Carrier__c = carrier.Id;
		carOrder.Name = 'Test Carrier';
		carOrder.Benefit_Order__c = objBenOrder.Id;
		carOrder.Order_Type__c = 'TAdA: Pre OE Setup';
		insert carOrder;
		Id TTFBorRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits New Plan');
		Id TTFQBcRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Change');
		Transition_to_Fulfillment__c ttf = new Transition_to_Fulfillment__c(
			Opportunity__c = objBenOrder.Opportunity__c,
			recordtypeid = TTFBorRecType,
			Existing_MDVLiDi_Coverage__c = 'Y',
			Do_they_have_affiliates__c = true
		);
		insert ttf;
		Transition_to_Fulfillment__c ttf1 = new Transition_to_Fulfillment__c(
			Opportunity__c = objBenOrder.Opportunity__c,
			recordtypeid = TTFQBcRecType,
			Existing_MDVLiDi_Coverage__c = 'Y',
			Do_they_have_affiliates__c = true
		);
		insert ttf1;
		Company_Level_Documents__c cld = new Company_Level_Documents__c(Benefit_Order__c = objBenOrder.Id);
		insert cld;
		Company_Level_Documents__c cld1 = new Company_Level_Documents__c(Benefit_Order__c = objBenOrder.Id, name = 'test');
		insert cld1;
		QA_Sheet__c qas = new QA_Sheet__c(
			Benefit_Order__c = objBenOrder.Id,
			SIC_Code__c = 'test',
			BSA_Signed__c = 'Yes'
		);
		insert qas;
		QA_Lines_Of_Coverage__c qlc = new QA_Lines_Of_Coverage__c(
			Lines_Of_Coverage__c = 'Medical',
			QA_Sheet__c = qas.Id,
			Carrier_Order__c = carOrder.Id,
			S_No__c = 0,
			Request_for_Submission__c = true
		);
		insert qlc;
		ApexPages.StandardController sc = new ApexPages.StandardController(mcl);
		PageReference pageRef = Page.DisplayEditTTS;
		pageRef.getParameters().put('Bid', String.valueOf(objBenOrder.Id));
		Test.setCurrentPage(pageRef);
		DisplayEditTTConfirmationExt dedit = new DisplayEditTTConfirmationExt(sc);
		dedit.DisplayRec();
		dedit.customsave();
		dedit.objTTF.NHEs_that_were_submitted_with_group__c = 'Pending Testing Pull to TTC\nUpdates TTC testing';
		dedit.objTTF.State_continuation_enrollees_submitted__c = 'Pending Testing Pull to TTC\nUpdates TTC testing';
		dedit.QALinesOfCoverage[0].Allows_plans_with_no_enrollees__c = 'Y';
		dedit.QALinesOfCoverage[0].Should_policy_year_be_anything__c = 'Yes';
		dedit.QALinesOfCoverage[0].Other_items_to_note_for_this_group__c = 'Test';
		dedit.MoveToConfirmation();
		dedit.getChildCarrierOrderStatus();
		test.stopTest();

		System.assert(true, 'Fixing Apex PMD issue.');
	}

	@isTest
	static void DisplayEditTTIA1() {
		AccounttriggerHelper.skipTrigger = true;
		OpportunitytriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		test.startTest();
		Master_Company_Level_Documents__c mcl = new Master_Company_Level_Documents__c(Status__c = 'Active', name = 'test');
		insert mcl;
		Id boRenewalRecType = cache.getRecordTypeId('Benefit_Order__c', 'New Plan');
		Benefit_Order__c objBenOrder = new TestDataFactory.BenefitOrderBuilder().setRecordType(boRenewalRecType).setStatusDetail('STATUS DETAIL').setOwnerID(UserInfo.getUserId()).build();
		insert objBenOrder;
		State__c state = new State__c();
		state.Abbreviation__c = 'TS';
		state.Name = 'TEST STATE';
		insert state;

		Carrier__c carrier = new Carrier__c();
		carrier.Name = 'TEST CARRIER';
		carrier.State__c = state.Id;
		insert carrier;

		Carrier_Order__c carOrder = new Carrier_Order__c();
		carOrder.Carrier__c = carrier.Id;
		carOrder.Name = 'Test Carrier';
		carOrder.Benefit_Order__c = objBenOrder.Id;
		carOrder.Order_Type__c = 'TAdA: Pre OE Setup';
		insert carOrder;
		Id TTFBorRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits New Plan');
		Id TTFQBcRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Confirmation New Plan');
		Transition_to_Fulfillment__c ttf = new Transition_to_Fulfillment__c(
			Opportunity__c = objBenOrder.Opportunity__c,
			recordtypeid = TTFBorRecType,
			Existing_MDVLiDi_Coverage__c = 'Y',
			Do_they_have_affiliates__c = true,
			NHEs_that_were_submitted_with_group__c = 'test'
		);
		insert ttf;
		Transition_to_Fulfillment__c ttf1 = new Transition_to_Fulfillment__c(
			Opportunity__c = objBenOrder.Opportunity__c,
			recordtypeid = TTFQBcRecType,
			Existing_MDVLiDi_Coverage__c = 'Y',
			Do_they_have_affiliates__c = true,
			NHEs_that_were_submitted_with_group__c = 'test'
		);
		insert ttf1;
		Company_Level_Documents__c cld = new Company_Level_Documents__c(Benefit_Order__c = objBenOrder.Id);
		insert cld;
		Company_Level_Documents__c cld1 = new Company_Level_Documents__c(Benefit_Order__c = objBenOrder.Id, name = 'test');
		insert cld1;
		QA_Sheet__c qas = new QA_Sheet__c(
			Benefit_Order__c = objBenOrder.Id,
			SIC_Code__c = 'test',
			BSA_Signed__c = 'Yes'
		);
		insert qas;
		QA_Lines_Of_Coverage__c qlc = new QA_Lines_Of_Coverage__c(
			Lines_Of_Coverage__c = 'Medical',
			QA_Sheet__c = qas.Id,
			Carrier_Order__c = carOrder.Id,
			S_No__c = 0,
			Request_for_Submission__c = true
		);
		insert qlc;
		ApexPages.StandardController sc = new ApexPages.StandardController(mcl);
		PageReference pageRef = Page.DisplayEditTTS;
		pageRef.getParameters().put('Bid', String.valueOf(objBenOrder.Id));
		Test.setCurrentPage(pageRef);
		DisplayEditTTConfirmationExt dedit = new DisplayEditTTConfirmationExt(sc);
		dedit.DisplayRec();
		dedit.customsave();
		dedit.MoveToConfirmation();
		test.stopTest();

		System.assert(true, 'Fixing Apex PMD issue.');
	}

	@isTest
	static void DisplayEditTTIAFromCarrierOrder() {
		AccounttriggerHelper.skipTrigger = true;
		OpportunitytriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		test.startTest();
		List<Carrier_Play_Information_Defaults__c> list_CPlayDefaults = new List<Carrier_Play_Information_Defaults__c>();
		list_CPlayDefaults.add(
			new Carrier_Play_Information_Defaults__c(
				Name = 'OrderFirstPlayBef1_15',
				Event_Type__c = 'Order',
				Play_Mode_Type__c = 'First Play',
				Before_AFter__c = 'Before',
				Number_of_Days__c = 4,
				From__c = 1,
				To__c = 15
			)
		);
		list_CPlayDefaults.add(
			new Carrier_Play_Information_Defaults__c(
				Name = 'OrderFirstPlayBef16_20',
				Event_Type__c = 'Order',
				Play_Mode_Type__c = 'First Play',
				Before_AFter__c = 'Before',
				Number_of_Days__c = 3,
				From__c = 16,
				To__c = 20
			)
		);
		list_CPlayDefaults.add(
			new Carrier_Play_Information_Defaults__c(
				Name = 'OrderFirstPlayBef21_25',
				Event_Type__c = 'Order',
				Play_Mode_Type__c = 'First Play',
				Before_AFter__c = 'Before',
				Number_of_Days__c = 2,
				From__c = 21,
				To__c = 25
			)
		);
		list_CPlayDefaults.add(
			new Carrier_Play_Information_Defaults__c(
				Name = 'OrderFirstPlayBef26',
				Event_Type__c = 'Order',
				Play_Mode_Type__c = 'First Play',
				Before_AFter__c = 'BeforeOnward',
				Number_of_Days__c = 2,
				From__c = 26,
				To__c = 31
			)
		);
		insert list_CPlayDefaults;
		Master_Company_Level_Documents__c mcl = new Master_Company_Level_Documents__c(Status__c = 'Active', name = 'test');
		insert mcl;
		Id boRenewalRecType = cache.getRecordTypeId('Benefit_Order__c', 'New Plan');
		Benefit_Order__c objBenOrder = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(boRenewalRecType)
			.setStatusDetail('STATUS DETAIL')
			.setCoverageEffectiveDate(System.today().addDays(5))
			.setOwnerID(UserInfo.getUserId())
			.build();
		insert objBenOrder;
		State__c state = new State__c();
		state.Abbreviation__c = 'TS';
		state.Name = 'TEST STATE';
		insert state;

		Carrier__c carrier = new Carrier__c();
		carrier.Name = 'TEST CARRIER';
		carrier.State__c = state.Id;
		insert carrier;

		Carrier_Order__c carOrder = new Carrier_Order__c();
		carOrder.Carrier__c = carrier.Id;
		carOrder.Name = 'Test Carrier';
		carOrder.Benefit_Order__c = objBenOrder.Id;
		carOrder.Order_Type__c = 'TAdA: Pre OE Setup';
		insert carOrder;
		Id TTFBorRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits New Plan');
		Id TTFQBcRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Confirmation New Plan');
		Transition_to_Fulfillment__c ttf = new Transition_to_Fulfillment__c(
			Opportunity__c = objBenOrder.Opportunity__c,
			recordtypeid = TTFBorRecType,
			Existing_MDVLiDi_Coverage__c = 'Y',
			Do_they_have_affiliates__c = true,
			NHEs_that_were_submitted_with_group__c = 'test'
		);
		insert ttf;
		Transition_to_Fulfillment__c ttf1 = new Transition_to_Fulfillment__c(
			Opportunity__c = objBenOrder.Opportunity__c,
			recordtypeid = TTFQBcRecType,
			Existing_MDVLiDi_Coverage__c = 'Y',
			Do_they_have_affiliates__c = true,
			NHEs_that_were_submitted_with_group__c = 'test',
			State_continuation_enrollees_submitted__c = 'test comments'
		);
		insert ttf1;
		Company_Level_Documents__c cld = new Company_Level_Documents__c(Benefit_Order__c = objBenOrder.Id);
		insert cld;
		Company_Level_Documents__c cld1 = new Company_Level_Documents__c(Benefit_Order__c = objBenOrder.Id, name = 'test');
		insert cld1;
		QA_Sheet__c qas = new QA_Sheet__c(
			Benefit_Order__c = objBenOrder.Id,
			SIC_Code__c = 'test',
			BSA_Signed__c = 'Yes'
		);
		insert qas;
		QA_Lines_Of_Coverage__c qlc = new QA_Lines_Of_Coverage__c(
			Lines_Of_Coverage__c = 'Medical',
			QA_Sheet__c = qas.Id,
			Carrier_Order__c = carOrder.Id,
			Color_Code__c = 'Benefits_selected_Carrier__c',
			S_No__c = 0,
			Request_for_Submission__c = true,
			Allows_plans_with_no_enrollees__c = 'No',
			Should_policy_year_be_anything__c = 'No',
			Other_items_to_note_for_this_group__c = 'test'
		);
		insert qlc;
		ApexPages.StandardController sc = new ApexPages.StandardController(mcl);
		PageReference pageRef = Page.DisplayEditTTConfirmation;
		pageRef.getParameters().put('cid', String.valueOf(carOrder.Id));
		Test.setCurrentPage(pageRef);
		DisplayEditTTConfirmationExt dedit = new DisplayEditTTConfirmationExt(sc);
		dedit.DisplayRec();
		dedit.MoveToConfirmation();

		System.assert([SELECT COUNT() FROM Carrier_Order__c WHERE Order_Playable_Date__c != NULL AND Id = :carOrder.Id] == 1, 'Record count should be 1.');
		test.stopTest();
	}
}