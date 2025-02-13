/**
 * Test Class for PolicyHelper
 * @see PolicyHelper
 * @group Benefits
 */
@isTest
private class PolicyHelper_Tests {
	/**
	 * @Author        Bhagat Singh
	 * @Description	  Test data set up
	 * @Parm          void
	 * @Return        void
	 **/
	@TestSetup
	static void setup() {
		Utils.skipTrigger(true);
		//BenefitOrderHelper.skipTaskCreation = true;
		User objAdminUser = new TestDataFactory.UserBuilder()
			.setAlias('partam')
			.setEmail('partneram@testorg.com')
			.setEmailEncoding('UTF-8')
			.setFirstName('Test')
			.setLastName('User')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId(UserInfo.getProfileId())
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('partneram@testorg.com')
			.setExemptfromValidationRules(true)
			.build();
		insert objAdminUser;

		State__c objState = new TestDataFactory.StateBuilder().setName('California').setId('State321').setAbbreviation('CA').build();
		insert objState;

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Gusto Test').setZPCompanyId('5102020').build();
		insert objAccount;

		PriceBook2 objPB = TestUtility.createCompanyPriceBookInformation();

		List<Opportunity> list_Opportunity = new List<Opportunity>();
		list_Opportunity.add(
			new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
				.setName('Benefits New Plan')
				.setPriceBookId(objPB.id)
				.setAccountId(objAccount.Id)
				.setStage('SAL')
				.setCloseDate(System.today().addDays(30))
				.setSourceID('hawaiian_ice-new_plans_application-O321')
				.setBenefitsState('CA')
				.setNumberOfEE(5)
				.build()
		);
		insert list_Opportunity;

		String strCarrierName = 'Beam';
		String strCarrierId = '64';
		String strOrderType = 'Same Carrier, NO Plan/Group Level Changes';
		List<RPA_Submission_Automation_rules__mdt> list_SubmissionMetadata = TestUtility.getSubmissionMetadata(Utils.HI_ONLY);
		if (list_SubmissionMetadata != null) {
			strCarrierName = list_SubmissionMetadata[0].DeveloperName;
			strCarrierId = list_SubmissionMetadata[0].Carrier_Id__c;
			if (String.isNotBlank(list_SubmissionMetadata[0].Order_Type__c)) {
				strOrderType = list_SubmissionMetadata[0].Order_Type__c;
				List<String> list_OrderType = strOrderType.split(';');
				strOrderType = list_OrderType[0].trim();
			}
		}

		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder()
			.setName(strCarrierName)
			.setUniqueName('beam_dental_ca')
			.setId('259')
			.setKey('beam_dental_ca')
			.setState('CA')
			.setCarrierId(strCarrierId)
			.build();
		insert objCarrier;

		Id idNewPlanRT = cache.getRecordTypeId('Benefit_Order__c', 'New Plan');
		Benefit_Order__c objBenefitOrder = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(idNewPlanRT)
			.setName('New Plan BO')
			.setAccount(objAccount.Id)
			.setOpp(list_Opportunity[0].Id)
			.setCoverageEffectiveDate(System.today())
			.setSubmissionDeadline(System.today())
			.setOwnerID(UserInfo.getUserId())
			.build();
		insert objBenefitOrder;

		List<Carrier_Order__c> list_CO = new List<Carrier_Order__c>();
		list_CO.add(
			new TestDataFactory.CarrierOrderBuilder()
				.setName('Test CO1')
				.setCarrier(objCarrier.Id)
				.setBenefitOrder(objBenefitOrder.id)
				.setImplementationStage('Ready for Qualification')
				.setRecordTypeId(Cache.getRecordTypeId('Carrier_Order__c', 'Renewal'))
				.setOwnerID(UserInfo.getUserId())
				.setStartDate(System.today() - 50)
				.setOrderAssignment(strOrderType)
				.build()
		);
		insert list_CO;

		Utils.skipTrigger(false);
	}

	/**
	 * @author        Bhagat Singh
	 * @description	  Opportunity Line item Create & Delete
	 * @param         void
	 * @return        void
	 **/
	@isTest
	static void testOppLinesCreateAndDelete() {
		Test.startTest();
		User objAdminUser = [SELECT Id FROM User WHERE UserName = 'partneram@testorg.com' LIMIT 1];
		List<Carrier__c> list_Carrier = [SELECT Id FROM Carrier__c WHERE Key__c = 'beam_dental_ca' LIMIT 1];
		List<Opportunity> list_Opportunity = [SELECT id FROM Opportunity LIMIT 1];
		List<State__c> list_State = [SELECT Id FROM State__c WHERE Name = 'California' LIMIT 1];
		System.runAs(objAdminUser) {
			List<Policy__c> list_Policy = new List<Policy__c>();
			list_Policy.add(
				new TestDataFactory.PolicyBuilder()
					.setName('Test Policy 1')
					.setIdOpprtunity(list_Opportunity[0].Id)
					.setIdCarrier(list_Carrier[0].Id)
					.setIsSelected(true)
					.setExternalKey('External321')
					.setBenefitType('Dental')
					.setIdState(list_State[0].id)
					.setCoverageEffectiveDate(System.today().addDays(10))
					.build()
			);
			list_Policy.add(
				new TestDataFactory.PolicyBuilder()
					.setName('Test Policy 2')
					.setIdOpprtunity(list_Opportunity[0].Id)
					.setIdCarrier(list_Carrier[0].Id)
					.setIsSelected(true)
					.setExternalKey('External322')
					.setBenefitType('Dental')
					.setIdState(list_State[0].id)
					.setCoverageEffectiveDate(System.today().addDays(10))
					.build()
			);
			list_Policy.add(
				new TestDataFactory.PolicyBuilder()
					.setName('Test Policy 3')
					.setIdOpprtunity(list_Opportunity[0].Id)
					.setIdCarrier(list_Carrier[0].Id)
					.setIsSelected(true)
					.setExternalKey('External323')
					.setBenefitType('Vision')
					.setIdState(list_State[0].id)
					.setCoverageEffectiveDate(System.today().addDays(10))
					.build()
			);
			list_Policy.add(
				new TestDataFactory.PolicyBuilder()
					.setName('Test Policy 4')
					.setIdOpprtunity(list_Opportunity[0].Id)
					.setIdCarrier(list_Carrier[0].Id)
					.setIsSelected(true)
					.setExternalKey('External324')
					.setBenefitType('Dental')
					.setIdState(list_State[0].id)
					.setCoverageEffectiveDate(System.today().addDays(10))
					.build()
			);
			Database.insert(list_Policy, false);
		}

		Test.stopTest();

		List<OpportunityLineItem> list_OppLineItems = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :list_Opportunity[0].Id];
		//System.assert(list_OppLineItems.size() > 0);
	}

	/**
	 * @author        Bhagat Singh
	 * @description	  Create Policy and Update Benefits_State__c on Opportunity.
	 * @param         void
	 * @return        void
	 **/
	@isTest
	static void testStateRollup() {
		Test.startTest();
		Utils.skipTrigger(true);
		String strState = 'NY';
		User objAdminUser = [SELECT Id FROM User WHERE UserName = 'partneram@testorg.com' LIMIT 1];
		List<Carrier__c> list_Carrier = [SELECT Id FROM Carrier__c WHERE Key__c = 'beam_dental_ca' LIMIT 1];
		List<Opportunity> list_Opportunity = [SELECT id FROM Opportunity LIMIT 1];
		List<Account> list_Account = [SELECT Id FROM Account WHERE Name = 'Gusto Test' LIMIT 1];
		list_Opportunity[0].Benefits_State__c = 'CA';
		list_Opportunity[0].NumberOfEmployees__c = 30;
		update list_Opportunity[0];
		State__c objState = new TestDataFactory.StateBuilder().setName('New York').setId('State322').setAbbreviation(strState).build();
		insert objState;
		Utils.skipTrigger(false);

		List<Policy__c> list_Policy = new List<Policy__c>();
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setName('Test Policy 1')
				.setIdOpprtunity(list_Opportunity[0].Id)
				.setIdCarrier(list_Carrier[0].Id)
				.setIsSelected(true)
				.setExternalKey('External321')
				.setBenefitType('Dental')
				.setIdState(objState.id)
				.setCoverageEffectiveDate(System.today().addDays(10))
				.build()
		);
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setName('Test Policy 2')
				.setIdOpprtunity(list_Opportunity[0].Id)
				.setIdCarrier(list_Carrier[0].Id)
				.setIsSelected(true)
				.setExternalKey('External322')
				.setBenefitType('Dental')
				.setIdState(objState.id)
				.setCoverageEffectiveDate(System.today().addDays(10))
				.build()
		);
		insert list_Policy;

		Test.stopTest();

		list_Policy = [SELECT id, opportunity__c, Opportunity__r.Benefits_State__c FROM Policy__c WHERE id = :list_Policy[0].Id];
		System.assert(list_Policy[0].Opportunity__r.Benefits_State__c == strState);
	}

	/**
	 * @author        Bhagat Singh
	 * @description	  Delete State Rollup and update Benefits_State__c on Opportunity
	 * @param         void
	 * @return        void
	 **/
	@isTest
	static void testStateRollupForDelete() {
		Test.startTest();
		Utils.skipTrigger(true);
		String strState = 'NY';
		User objAdminUser = [SELECT Id FROM User WHERE UserName = 'partneram@testorg.com' LIMIT 1];
		List<Carrier__c> list_Carrier = [SELECT Id FROM Carrier__c WHERE Key__c = 'beam_dental_ca' LIMIT 1];
		List<Opportunity> list_Opportunity = [SELECT id FROM Opportunity LIMIT 1];
		List<Account> list_Account = [SELECT Id FROM Account WHERE Name = 'Gusto Test' LIMIT 1];
		list_Opportunity[0].Benefits_State__c = 'CA';
		list_Opportunity[0].NumberOfEmployees__c = 30;
		update list_Opportunity[0];
		State__c objState = new TestDataFactory.StateBuilder().setName('New York').setId('State322').setAbbreviation(strState).build();
		insert objState;
		Utils.skipTrigger(false);

		List<Policy__c> list_Policy = new List<Policy__c>();
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setName('Test Policy 1')
				.setIdOpprtunity(list_Opportunity[0].Id)
				.setIdCarrier(list_Carrier[0].Id)
				.setIsSelected(true)
				.setExternalKey('External321')
				.setBenefitType('Dental')
				.setIdState(objState.id)
				.setCoverageEffectiveDate(System.today().addDays(10))
				.build()
		);
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setName('Test Policy 2')
				.setIdOpprtunity(list_Opportunity[0].Id)
				.setIdCarrier(list_Carrier[0].Id)
				.setIsSelected(true)
				.setExternalKey('External322')
				.setBenefitType('Dental')
				.setIdState(objState.id)
				.setCoverageEffectiveDate(System.today().addDays(10))
				.build()
		);
		insert list_Policy;

		List<Policy__c> list_UpdatedPolicy = [SELECT id, opportunity__c, Opportunity__r.Benefits_State__c FROM Policy__c WHERE id = :list_Policy[0].Id];
		System.assert(list_UpdatedPolicy[0].Opportunity__r.Benefits_State__c == strState);

		delete list_Policy;

		Test.stopTest();

		list_Opportunity = [SELECT id, Benefits_State__c FROM Opportunity WHERE Id = :list_Opportunity[0].Id];
		System.assert(String.isBlank(list_Opportunity[0].Benefits_State__c));
	}

	/**
	 * @author        Bhagat Singh
	 * @description	  Delete State Rollup
	 * @param         void
	 * @return        void
	 **/
	@isTest
	static void carrierOrderBenefitTypesTest() {
		Test.startTest();
		Utils.skipTrigger(true);
		String strState = 'NY';
		User objAdminUser = [SELECT Id FROM User WHERE UserName = 'partneram@testorg.com' LIMIT 1];
		List<Carrier__c> list_Carrier = [SELECT Id FROM Carrier__c WHERE Key__c = 'beam_dental_ca' LIMIT 1];
		List<Opportunity> list_Opportunity = [SELECT id FROM Opportunity LIMIT 1];
		List<Account> list_Account = [SELECT Id FROM Account WHERE Name = 'Gusto Test' LIMIT 1];
		list_Opportunity[0].Benefits_State__c = 'CA';
		list_Opportunity[0].NumberOfEmployees__c = 30;
		update list_Opportunity[0];
		State__c objState = new TestDataFactory.StateBuilder().setName('New York').setId('State322').setAbbreviation(strState).build();
		insert objState;
		Utils.skipTrigger(false);

		List<Policy__c> list_Policy = new List<Policy__c>();
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setName('Test Policy 1')
				.setIdOpprtunity(list_Opportunity[0].Id)
				.setIdCarrier(list_Carrier[0].Id)
				.setIsSelected(true)
				.setExternalKey('External321')
				.setBenefitType('Long Term Disability')
				.setIdState(objState.id)
				.setCoverageEffectiveDate(System.today().addDays(10))
				.build()
		);
		insert list_Policy;

		Policy__c objPolicy = new TestDataFactory.PolicyBuilder()
			.setName('Test Policy 2')
			.setIdOpprtunity(list_Opportunity[0].Id)
			.setIdCarrier(list_Carrier[0].Id)
			.setIsSelected(false)
			.setExternalKey('External322')
			.setBenefitType('Short Term Disability')
			.setIdState(objState.id)
			.setCoverageEffectiveDate(System.today().addDays(10))
			.build();
		insert objPolicy;

		delete list_Policy;

		Test.stopTest();
	}

	/**
	 * @author        Bhagat Singh
	 * @description	  Carrier Order with BenefitType : Negative Case
	 * @param         void
	 * @return        void
	 **/
	@isTest
	static void carrierOrderBenefitTypesNegTest() {
		Test.startTest();
		Utils.skipTrigger(true);
		List<Carrier__c> list_Carrier = [SELECT Id FROM Carrier__c WHERE Key__c = 'beam_dental_ca' LIMIT 1];
		List<Carrier_Order__c> list_CO = [SELECT id, Benefit_Order__c FROM Carrier_Order__c LIMIT 1];
		List<State__c> list_State = [SELECT Id FROM State__c WHERE Name = 'California' LIMIT 1];
		list<Opportunity> list_Opportunity = [SELECT id FROM Opportunity LIMIT 1];
		list_Opportunity[0].Order_Generated__c = true;
		list_Opportunity[0].Benefits_State__c = 'CA';
		list_Opportunity[0].NumberOfEmployees__c = 30;
		update list_Opportunity[0];

		delete list_CO[0];
		Utils.skipTrigger(false);
		PolicyHelper.skipTrigger = true;

		List<Policy__c> list_Policy = new List<Policy__c>();
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setName('Test Policy 1')
				.setIdOpprtunity(list_Opportunity[0].Id)
				.setIdCarrier(list_Carrier[0].Id)
				.setIsSelected(false)
				.setExternalKey('External321')
				.setBenefitType('Dental')
				.setIdState(list_State[0].id)
				.setCoverageEffectiveDate(System.today().addDays(10))
				.build()
		);
		insert list_Policy[0];
		PolicyHelper.skipTrigger = false;

		list_Policy[0].Is_Selected__c = true;
		list_Policy[0].Carrier_Order__c = null;
		update list_Policy[0];

		Test.stopTest();
	}

	/**
	 * @author        Bhagat Singh
	 * @description	  Carrier Order for new Policy
	 * @param         void
	 * @return        void
	 **/
	@isTest
	static void createCarrierOrderTest() {
		Test.startTest();
		Utils.skipTrigger(true);
		List<Carrier__c> list_Carrier = [SELECT Id FROM Carrier__c WHERE Key__c = 'beam_dental_ca' LIMIT 1];
		List<Carrier_Order__c> list_CO = [SELECT id, Benefit_Order__c FROM Carrier_Order__c LIMIT 1];
		List<State__c> list_State = [SELECT Id FROM State__c WHERE Name = 'California' LIMIT 1];
		list<Opportunity> list_Opportunity = [SELECT id FROM Opportunity LIMIT 1];
		list_Opportunity[0].Order_Generated__c = true;
		list_Opportunity[0].Benefits_State__c = 'CA';
		list_Opportunity[0].NumberOfEmployees__c = 30;
		update list_Opportunity[0];

		delete list_CO[0];
		Utils.skipTrigger(false);
		PolicyHelper.skipTrigger = false;

		List<Policy__c> list_Policy = new List<Policy__c>();
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setName('Test Policy 1')
				.setIdOpprtunity(list_Opportunity[0].Id)
				.setIdCarrier(list_Carrier[0].Id)
				.setIsSelected(true)
				.setExternalKey('External321')
				.setBenefitType('Dental')
				.setIdState(list_State[0].id)
				.setCoverageEffectiveDate(System.today().addDays(10))
				.build()
		);
		insert list_Policy[0];

		Test.stopTest();
	}

	/**
	 * @author        Bhagat Singh
	 * @description	  Carrier Order with BenefitType
	 * @param         void
	 * @return        void
	 **/
	@isTest
	static void carrierOrderBenefitTypes2Test() {
		Test.startTest();
		Utils.skipTrigger(true);
		list<Opportunity> list_Opportunity = [SELECT id FROM Opportunity LIMIT 1];
		List<Carrier__c> list_Carrier = [SELECT Id FROM Carrier__c WHERE Key__c = 'beam_dental_ca' LIMIT 1];
		List<Carrier_Order__c> list_CO = [SELECT id, Benefit_Order__c FROM Carrier_Order__c LIMIT 1];
		List<State__c> list_State = [SELECT Id FROM State__c WHERE Name = 'California' LIMIT 1];

		PolicyHelper.skipTrigger = false;
		List<Policy__c> list_Policy = new List<Policy__c>();
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setName('Test Policy 1')
				.setIdOpprtunity(list_Opportunity[0].Id)
				.setIdCarrier(list_Carrier[0].Id)
				.setIdCarrierOrder(list_CO[0].Id)
				.setIsSelected(true)
				.setExternalKey('External321')
				.setIdState(list_State[0].id)
				.setCoverageEffectiveDate(System.today().addDays(10))
				.build()
		);
		insert list_Policy;

		Policy__c objPolicy = new TestDataFactory.PolicyBuilder()
			.setIsSelected(true)
			.setBenefitType('Dental')
			.setRequestType('Carrier Switch; Contribution Scheme Change')
			.build();
		objPolicy.Id = list_Policy[0].Id;
		update objPolicy;

		Utils.skipTrigger(false);

		Test.stopTest();
	}

	/**
	 * @author        Bhagat Singh
	 * @description	  Carrier Order with BenefitType
	 * @param         void
	 * @return        void
	 **/

	@isTest
	static void carrierOrderIsSelectedTest() {
		Test.startTest();
		Utils.skipTrigger(true);
		list<Opportunity> list_Opportunity = [SELECT id FROM Opportunity LIMIT 1];
		List<Carrier__c> list_Carrier = [SELECT Id FROM Carrier__c WHERE Key__c = 'beam_dental_ca' LIMIT 1];
		List<Carrier_Order__c> list_CO = [SELECT id, Benefit_Order__c FROM Carrier_Order__c LIMIT 1];
		List<State__c> list_State = [SELECT Id FROM State__c WHERE Name = 'California' LIMIT 1];

		PolicyHelper.skipTrigger = false;
		List<Policy__c> list_Policy = new List<Policy__c>();
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setName('Test Policy 1')
				.setIdOpprtunity(list_Opportunity[0].Id)
				.setIdCarrier(list_Carrier[0].Id)
				.setIsSelected(true)
				.setExternalKey('External321')
				.setIdState(list_State[0].id)
				.setBenefitType('Dental')
				.setIdCarrierOrder(list_CO[0].Id)
				.setCoverageEffectiveDate(System.today().addDays(10))
				.build()
		);
		insert list_Policy;

		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Beam').setUniqueName('beam_medical_ca').setId('260').setKey('beam_Medical_ca').setState('CA').setCarrierId('64').build();
		insert objCarrier;

		list_Policy.clear();
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setName('Test Policy 1')
				.setIdOpprtunity(list_Opportunity[0].Id)
				.setIdCarrier(objCarrier.Id)
				.setIsSelected(true)
				.setExternalKey('External32231')
				.setIdState(list_State[0].id)
				.setBenefitType('Medical')
				.setCoverageEffectiveDate(System.today().addDays(10))
				.build()
		);
		insert list_Policy;

		Utils.skipTrigger(false);
		Test.stopTest();
		Utils.skipTrigger(false);
	}

	/**
	 * @author        Bhagat Singh
	 * @description	  Policy Complexity Score
	 * @param         void
	 * @return        void
	 **/

	@isTest
	static void policyComplexityScoreTest() {
		Test.startTest();
		Utils.skipTrigger(true);
		list<Opportunity> list_Opportunity = [SELECT id FROM Opportunity LIMIT 1];
		List<Carrier__c> list_Carrier = [SELECT Id FROM Carrier__c WHERE Key__c = 'beam_dental_ca' LIMIT 1];
		List<Carrier_Order__c> list_CO = [SELECT id, Benefit_Order__c FROM Carrier_Order__c LIMIT 1];
		List<State__c> list_State = [SELECT Id FROM State__c WHERE Name = 'California' LIMIT 1];

		PolicyHelper.skipTrigger = false;
		List<Policy__c> list_Policy = new List<Policy__c>();
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setName('Test Policy 1')
				.setIdOpprtunity(list_Opportunity[0].Id)
				.setIdCarrier(list_Carrier[0].Id)
				.setIdCarrierOrder(list_CO[0].Id)
				.setIsSelected(true)
				.setExternalKey('External321')
				.setIdState(list_State[0].id)
				.setCoverageEffectiveDate(System.today().addDays(10))
				.build()
		);
		insert list_Policy;

		list_Policy[0].Benefit_Type__c = 'Vision';
		update list_Policy[0];
		Utils.skipTrigger(false);

		Test.stopTest();
	}

	/**
	 * @author        Bhagat Singh
	 * @description	  Create HSA or Commuter Policy - Positive Case
	 * @param         void
	 * @return        void
	 **/
	@isTest
	static void testHSACommuterPolicyPositiveCase() {
		Utils.skipTrigger(true);
		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE Key__c = 'beam_dental_ca' LIMIT 1];
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();

		Test.startTest();
		PriceBook2 objPB = [SELECT Id FROM PriceBook2 WHERE Name = :objTierConfig.New_Price_1__c LIMIT 1];
		Opportunity objOpp = TestUtility.BenefitsNewPlanOpportunity();
		objOpp.HI_Effective_Date__c = Date.today();
		objOpp.Benefits_Current_Setup_Step__c = 'Completed';
		objOpp.Pricebook2Id = objPB.id;
		objOpp.Order_Generated__c = true;
		objOpp.numberOfEmployees__c = 5;
		update objOpp;

		Contact objContact = TestUtils.createContact(objOpp.AccountId, 'Test', 'User01', 'testuser01@gusto.com', false);
		objContact.RecordTypeId = ContactUtil.COMPANY_CONTACT_RT_ID;
		insert objContact;

		NewTransitionToFulfillmentController.BO_order_type = new List<String>();
		NewTransitionToFulfillmentController.BO_order_type.add('Carrier Switch');
		Id idTTFRecordType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits New Plan');
		Transition_to_Fulfillment__c objTTF = TestUtility.createTestTransitionToFulfillment(objOpp.AccountId, objContact.Id, objOpp.Id, idTTFRecordType, true);
		TestUtility.createTestBenefitOrder('New Plan', objOpp.Id, 'Benefit Order', true);
		Id idMFQueue = GlobalQueryHelper.getQueueIdByName('MF Automation');
		Case objCase = TestUtility.createCase(objOpp.AccountId, objContact.Id, 'MF NHE');
		objCase.Status = 'On Hold';
		objCase.OwnerId = idMFQueue;
		objCase.Carrier__c = objCarrier.Id;
		insert objCase;
		Utils.skipTrigger(false);

		Policy__c objPolicy = TestUtility.createTestPolicy(objOpp.Id, objCarrier.Id, true, 'Test Policy1', null, false);
		objPolicy.Benefit_Type__c = 'HSA';
		objPolicy.Is_Selected__c = true;
		objPolicy.Group_Number__c = '1001';
		insert objPolicy;

		objPolicy.policy_Number__c = '1001';
		objPolicy.Account__c = objOpp.AccountId;
		update objPolicy;
		Test.stopTest();

		System.assert([SELECT Id, Benefit_Types__c FROM Carrier_Order__c WHERE Benefit_Order__r.Opportunity__c = :objOpp.Id].Benefit_Types__c.indexOf('HSA') > -1);
	}

	/**
	 * @author        Bhagat Singh
	 * @description	  Create HSA or Commuter Policy - Negative Case
	 * @param         void
	 * @return        void
	 **/
	@isTest
	static void testHSACommuterPolicyNegativeCase() {
		Utils.skipTrigger(true);
		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE Key__c = 'beam_dental_ca' LIMIT 1];
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();

		Test.startTest();
		PriceBook2 objPB = [SELECT Id FROM PriceBook2 WHERE Name = :objTierConfig.New_Price_1__c LIMIT 1];
		Opportunity objOpp = TestUtility.BenefitsRenewalOpportunity();
		objOpp.Reason_for_Advising__c = 'Auto-renewed';
		objOpp.HI_Effective_Date__c = Date.today();
		objOpp.Benefits_Current_Setup_Step__c = 'Completed';
		objOpp.Pricebook2Id = objPB.id;
		objOpp.Order_Generated__c = true;
		objOpp.numberOfEmployees__c = 5;
		update objOpp;

		Contact objContact = TestUtils.createContact(objOpp.AccountId, 'Test', 'User01', 'testuser01@gusto.com', false);
		objContact.RecordTypeId = ContactUtil.COMPANY_CONTACT_RT_ID;
		insert objContact;
		Utils.skipTrigger(false);

		NewTransitionToFulfillmentController.BO_order_type = new List<String>();
		NewTransitionToFulfillmentController.BO_order_type.add('Carrier Switch');
		Id idTTFRecordType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Renewal');
		Transition_to_Fulfillment__c objTTF = TestUtility.createTestTransitionToFulfillment(objOpp.AccountId, objContact.Id, objOpp.Id, idTTFRecordType, true);
		objTTF.Adding_TADA__c = 'Y';
		objTTF.Type_of_TADA_s__c = 'HSA;Commuter';
		update objTTF;

		TestUtility.createTestBenefitOrder('Renewal', objOpp.Id, 'Benefit Order', true);

		Policy__c objPolicy = TestUtility.createTestPolicy(objOpp.Id, objCarrier.Id, true, 'Test Policy1', null, false);
		objPolicy.Benefit_Type__c = 'HSA';
		objPolicy.Is_Selected__c = false;
		insert objPolicy;
		Test.stopTest();

		System.assert([SELECT Id FROM Carrier_Order__c WHERE Benefit_Order__r.Opportunity__c = :objOpp.Id].size() == 0);
	}

	/**
	 * @author        Deepika Saini
	 * @description	  update orderType on renewal Carrier Order
	 * @param         void
	 * @return        void
	 **/
	@isTest
	static void testOrderTypeOnCO() {
		Test.startTest();
		Utils.skipTrigger(true);
		Account objAccount = [SELECT Id FROM Account LIMIT 1];
		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE Key__c = 'beam_dental_ca' LIMIT 1];
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		Opportunity opp1 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
			.setName('Benefits New Plan test')
			.setAccountId(objAccount.Id)
			.setStage('SAL')
			.setCloseDate(System.today().addDays(30))
			.setSourceID('hawaiian_ice-new_plans-O321')
			.setBenefitsState('CA')
			.setNumberOfEE(5)
			.setId('HIRENEWAL0321')
			.setHIEffectiveDate(Date.today().addDays(2))
			.setBenefitsCurrentSetupSteps('Completed')
			.setOrderGenerated(true)
			.build();
		insert opp1;

		Id idContactRecordType = cache.getRecordTypeId('Contact', 'Company');
		Contact objContact = new TestDataFactory.ContactBuilder().setAccountId(opp1.AccountId).setEmail('testuser01@gusto.com').setLastName('Test').setRecordTypeId(idContactRecordType).build();
		insert objContact;

		Id idTTFRecordType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits New Plan');
		Transition_to_Fulfillment__c objTTF = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setOpportunityId(opp1.Id)
			.setRecordTypeId(idTTFRecordType)
			.setContactId(objContact.Id)
			.setAccountId(opp1.AccountId)
			.setSendOrder(true)
			.build();
		insert objTTF;
		Id idBORecordType = cache.getRecordTypeId('Benefit_Order__c', 'Renewal');
		Benefit_Order__c objbo = new TestDataFactory.BenefitOrderBuilder()
			.setOpp(opp1.Id)
			.setRecordType(idBORecordType)
			.setName('Benefit Order')
			.setCoverageEffectiveDate(System.today())
			.setSubmissionDeadline(System.today())
			.setOwnerID(UserInfo.getUserId())
			.build();
		insert objbo;
		Id idQASheetRecordType = cache.getRecordTypeId('QA_Sheet__c', 'Benefit Renewal');
		QA_Sheet__c qas = new TestDataFactory.QASheetBuilder()
		.setBenefitOrderId(objbo.id)
		.setSICCodeSupportedByAllCarriers('Yes')
		.setSICCode('test')
		.setBAASigned('Yes')
		.setBAASignedBy('test')
		.setBSASigned('Yes')
		.setBSASignedBy('test')
		.setRecordTypeId(idQASheetRecordType)
		.setOpportunityId(opp1.Id)
		.build();
		insert qas;

		List<QA_Lines_Of_Coverage__c> list_QaLineOfCoverage = new List<QA_Lines_Of_Coverage__c>();

		list_QaLineOfCoverage.add(new TestDataFactory.QALineOfCoverageBuilder().setQASheetId(qas.Id).setLinesOfCoverage('Medical').build());
		list_QaLineOfCoverage.add(new TestDataFactory.QALineOfCoverageBuilder().setQASheetId(qas.Id).setLinesOfCoverage('Dental').build());
		list_QaLineOfCoverage.add(new TestDataFactory.QALineOfCoverageBuilder().setQASheetId(qas.Id).setLinesOfCoverage('Short Term Disability').build());
		list_QaLineOfCoverage.add(new TestDataFactory.QALineOfCoverageBuilder().setQASheetId(qas.Id).setLinesOfCoverage('Long Term Disability').build());
		list_QaLineOfCoverage.add(new TestDataFactory.QALineOfCoverageBuilder().setQASheetId(qas.Id).setLinesOfCoverage('Vision').build());
		list_QaLineOfCoverage.add(new TestDataFactory.QALineOfCoverageBuilder().setQASheetId(qas.Id).setLinesOfCoverage('Life').build());

		list_QaLineOfCoverage[0].New_Carrier__c = 'Y';
		list_QaLineOfCoverage[1].Waiting_Period_Change__c = 'Y';
		insert list_QaLineOfCoverage;
		List<Carrier__c> list_Carrier = new List<Carrier__c>();
		list_Carrier.add(new TestDataFactory.CarrierBuilder().setName('Beam').setUniqueName('beam_medical_fl').setId('260').setKey('beam_Medical_ba').setState('FL').setCarrierId('108').build());
		list_Carrier.add(new TestDataFactory.CarrierBuilder().setName('Beam1').setUniqueName('beam_medical_qa').setId('261').setKey('beam_Medical_fl').setState('CA').setCarrierId('109').build());
		list_Carrier.add(new TestDataFactory.CarrierBuilder().setName('Beam2').setUniqueName('beam_medical_ma').setId('262').setKey('beam_Medical_ca').setState('IN').setCarrierId('110').build());
		list_Carrier.add(new TestDataFactory.CarrierBuilder().setName('Beam3').setUniqueName('beam_medical_ca').setId('263').setKey('beam_Medical_aa').setState('BA').setCarrierId('111').build());
		list_Carrier.add(new TestDataFactory.CarrierBuilder().setName('Beam4').setUniqueName('beam_medical_da').setId('264').setKey('beam_Medical_ma').setState('CL').setCarrierId('112').build());
		list_Carrier.add(new TestDataFactory.CarrierBuilder().setName('Beam5').setUniqueName('beam_medical_ga').setId('265').setKey('beam_Medical_er').setState('AL').setCarrierId('113').build());
		insert list_Carrier;
		Utils.skipTrigger(false);
		List<Policy__c> list_Policy = new List<Policy__c>();
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setName('Test Policy 1')
				.setIdOpprtunity(opp1.Id)
				.setIdCarrier(list_Carrier[0].Id)
				.setIsSelected(true)
				.setExternalKey('External321')
				.setBenefitType('Medical')
				.setCoverageEffectiveDate(System.today().addDays(10))
				.build()
		);
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setName('Test Policy 2')
				.setIdOpprtunity(opp1.Id)
				.setIdCarrier(list_Carrier[1].Id)
				.setIsSelected(true)
				.setExternalKey('External322')
				.setBenefitType('Dental')
				.setCoverageEffectiveDate(System.today().addDays(10))
				.build()
		);
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setName('Test Policy 3')
				.setIdOpprtunity(opp1.Id)
				.setIdCarrier(list_Carrier[2].Id)
				.setIsSelected(true)
				.setExternalKey('External323')
				.setBenefitType('Vision')
				.setCoverageEffectiveDate(System.today().addDays(10))
				.build()
		);
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setName('Test Policy 4')
				.setIdOpprtunity(opp1.Id)
				.setIdCarrier(list_Carrier[3].Id)
				.setIsSelected(true)
				.setExternalKey('External324')
				.setBenefitType('Life')
				.setCoverageEffectiveDate(System.today().addDays(10))
				.build()
		);
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setName('Test Policy 5')
				.setIdOpprtunity(opp1.Id)
				.setIdCarrier(list_Carrier[4].Id)
				.setIsSelected(true)
				.setExternalKey('External325')
				.setBenefitType('Long Term Disability')
				.setCoverageEffectiveDate(System.today().addDays(10))
				.build()
		);
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setName('Test Policy 6')
				.setIdOpprtunity(opp1.Id)
				.setIdCarrier(list_Carrier[5].Id)
				.setIsSelected(true)
				.setExternalKey('External326')
				.setBenefitType('Short Term Disability')
				.setCoverageEffectiveDate(System.today().addDays(10))
				.build()
		);
		Database.insert(list_Policy, false);
		Test.stopTest();
		System.assert([SELECT Id, Order_Type__c FROM Carrier_Order__c].size() > 0, 'There should be at least one Carrier Order.');
	}
}