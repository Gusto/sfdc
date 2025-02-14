@isTest
public class BTMultiEINAffiliateAssignmentCtrlTest {
	@testSetup
	static void setupData() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		Opportunity objOpp = TestUtility.BenefitsBoROpportunity();
		objOpp.Id__c = 'HIBORTRANSFERzpEIN67890';
		objOpp.StageName = 'Closed Won';
		objOpp.Order_Generated__c = true;
		update objOpp;

		Account accRec = new Account(Id = objOpp.AccountId);
		accRec.ZP_Company_Overall_Status__c = 'Active';
		accRec.ZP_Company_Id__c = 'zpMainAccount123';
		accRec.Joined_Date_Panda__c = system.today();
		update accRec;

		OpportunityTriggerHelper.skipTrigger = false;
		AccountTriggerHelper.skipTrigger = false;

		Carrier__c objCarrier = TestUtility.Carrier();
		objCarrier.Name = 'Alegeus';
		objCarrier.Key__c = 'alegeus32199';
		objCarrier.ID__c = 'alegeus32199';
		update objCarrier;

		Benefit_Order__c boRec = new Benefit_Order__c();
		boRec.Opportunity__c = objOpp.id;
		borec.Account__c = objOpp.AccountId;
		boRec.UW_Owner__c = UserInfo.getUserId();
		borec.Type__c = 'BOR BOR TAdA Only';
		boRec.Order_Status__c = 'Ready for Qualification';
		boRec.BOR_ID__c = 'zpEIN67890';
		boRec.ownerid = userInfo.getuserId();
		boRec.RecordTypeId = Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR');
		insert borec;

		TransitiontoFulfilmentTriggerHelper.skipTrigger = true;
		Transition_to_Fulfillment__c objTTFRecord = new Transition_to_Fulfillment__c();
		objTTFRecord.Opportunity__c = objOpp.Id;
		objTTFRecord.Account__c = objOpp.AccountId;
		objTTFRecord.HSA_Renewal_Date__c = System.today();
		objTTFRecord.FSA_Renewal_Date__c = System.today();
		objTTFRecord.DCA_Renewal_Date__c = System.today();
		objTTFRecord.Type_of_TADA_s__c = 'Flexible Spending Account - Dependent Care;Commuter';
		insert objTTFRecord;
		TransitiontoFulfilmentTriggerHelper.skipTrigger = false;

		HI_BoR_Transfer__c objHIBor = new HI_BoR_Transfer__c();
		objHIBor.Additional_Information__c = '{"administrators"=>{"fsa"=>"Zenefits", "commuter"=>"Zenefits"}, "title"=>"Benefits Administrator", "effective_month"=>1, "effective_month_same_as_medical"=>"yes"}';
		objHIBor.Id__c = 'zpEIN67890';
		objHIBor.Benefit_Types__c = '["fsa", "commuter"]';
		insert objHIBor;

		list<HI_Carrier_Information__c> list_HICarrier = new List<HI_Carrier_Information__c>();
		HI_Carrier_Information__c objHICarrier = new HI_Carrier_Information__c();
		objHICarrier.BOR_Transfer_Id__c = 'zpEIN67890';
		objHICarrier.Key__c = 'alegeus32199';
		objHICarrier.Id__c = 'HI99654321';
		objHICarrier.Plan_Type__c = 'LTD';
		list_HICarrier.add(objHICarrier);

		HICarrierInformationTriggerHelper.isBOInsert = true;
		insert list_HICarrier;
	}

	@isTest
	static void addAffiliate() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		Opportunity objOpp = TestUtility.BenefitsBoROpportunity();
		objOpp.Id__c = 'HIBORTRANSFERzpEIN6789012';
		objOpp.StageName = 'Closed Won';
		objOpp.Order_Generated__c = true;
		update objOpp;

		Account accRec = new Account(Id = objOpp.AccountId);
		accRec.ZP_Company_Overall_Status__c = 'Active';
		accRec.ZP_Company_Id__c = 'zpMainAccount1234';
		accRec.Joined_Date_Panda__c = system.today();
		update accRec;

		OpportunityTriggerHelper.skipTrigger = false;
		AccountTriggerHelper.skipTrigger = false;

		Carrier__c objCarrier = TestUtility.Carrier();
		objCarrier.Name = 'Alegeus';
		objCarrier.Key__c = 'alegeus321991';
		objCarrier.ID__c = 'alegeus321991';
		update objCarrier;

		Benefit_Order__c boRec = new Benefit_Order__c();
		boRec.Opportunity__c = objOpp.id;
		boRec.Account__c = objOpp.Accountid;
		boRec.UW_Owner__c = UserInfo.getUserId();
		borec.Type__c = 'BOR BOR TAdA Only';
		boRec.Order_Status__c = 'Ready for Qualification';
		boRec.BOR_ID__c = 'zpEIN6789021';
		boRec.ownerid = userInfo.getuserId();
		boRec.RecordTypeId = Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR');
		insert borec;

		TransitiontoFulfilmentTriggerHelper.skipTrigger = true;
		Transition_to_Fulfillment__c objTTFRecord = new Transition_to_Fulfillment__c();
		objTTFRecord.Opportunity__c = objOpp.Id;
		objTTFRecord.Account__c = objOpp.AccountId;
		objTTFRecord.HSA_Renewal_Date__c = System.today();
		objTTFRecord.FSA_Renewal_Date__c = System.today();
		objTTFRecord.DCA_Renewal_Date__c = System.today();
		objTTFRecord.Type_of_TADA_s__c = 'Flexible Spending Account - Dependent Care;Commuter';
		insert objTTFRecord;
		TransitiontoFulfilmentTriggerHelper.skipTrigger = false;

		HI_BoR_Transfer__c objHIBor = new HI_BoR_Transfer__c();
		objHIBor.Additional_Information__c = '{"administrators"=>{"fsa"=>"Zenefits", "commuter"=>"Zenefits"}, "title"=>"Benefits Administrator", "effective_month"=>1, "effective_month_same_as_medical"=>"yes"}';
		objHIBor.Id__c = 'zpEIN6789021';
		objHIBor.Benefit_Types__c = '["fsa", "commuter"]';
		insert objHIBor;

		list<HI_Carrier_Information__c> list_HICarrier = new List<HI_Carrier_Information__c>();
		HI_Carrier_Information__c objHICarrier = new HI_Carrier_Information__c();
		objHICarrier.BOR_Transfer_Id__c = 'zpEIN6789021';
		objHICarrier.Key__c = 'alegeus32199';
		objHICarrier.Id__c = 'HI996543211';
		objHICarrier.Plan_Type__c = 'LTD';
		list_HICarrier.add(objHICarrier);

		HICarrierInformationTriggerHelper.isBOInsert = true;
		insert list_HICarrier;

		test.startTest();
		//apexPages.currentPage().getParameters().put('rtnam','');
		ApexPages.StandardController sc = new ApexPages.StandardController(borec);
		BTMultiEINAffiliateAssignmentController controller = new BTMultiEINAffiliateAssignmentController(sc);
		controller.strAccName = 'test';
		controller.searchAccounts();
		controller.strAccName = '';
		controller.searchAccounts();
		controller.list_AccWrapper.get(0).blnIsSelected = true;
		controller.intSelectedCompanyIndx = 0;
		controller.selectCompany();
		controller.saveChildAccount();

		// Check that the parent relationship is updated for Account.
		Account var_accToUpdateParent = [SELECT Id, ParentId FROM Account WHERE ParentId != NULL LIMIT 1];
		System.assertEquals(accRec.Id, var_accToUpdateParent.ParentId, 'The account should have the correct ParentId.');

		// Check that the Parent relationship is updated for Benefit_Order__c.
		Benefit_Order__c var_BOToUpdateParent = [SELECT Parent_Benefit_Order__c, Account__c FROM Benefit_Order__c WHERE Account__c = :var_accToUpdateParent.Id];
		System.assertEquals(boRec.Id, var_BOToUpdateParent.Parent_Benefit_Order__c, 'The Benefit Order Parent should be correctly updated.');

		controller.idAcccountToBeRemoved = [SELECT id FROM Account WHERE Id != :borec.Account__c LIMIT 1].get(0).Id;
		controller.removeAccount();

		controller.saveChildAccount();

		// Check that the parent relationship is removed and updated to null for Account.
		Account var_accToRemoveParent = [SELECT Id, ParentId FROM Account WHERE Id = :controller.idAcccountToBeRemoved LIMIT 1];
		System.assertEquals(null, var_accToRemoveParent.ParentId, 'The account should have the correct ParentId.');

		// Check that the parent relationship is removed and updated to null for Benefit_Order__c.
		Benefit_Order__c var_BOToRemoveParent = [SELECT Parent_Benefit_Order__c, Account__c FROM Benefit_Order__c WHERE Account__c = :var_accToRemoveParent.Id];
		System.assertEquals(null, var_BOToRemoveParent.Parent_Benefit_Order__c, 'The Benefit Order Parent should be correctly updated.');

		boolean blnValue = controller.hasNext;
		blnValue = controller.hasPrevious;
		Integer intPageNUmber = controller.pageNumber;
		intPageNUmber = controller.getTotalPages();
		controller.last();
		controller.first();
		controller.next();
		controller.cancelBO();
		test.stopTest();
	}
}