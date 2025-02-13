@IsTest
public class TestUtility {
	static final String DUMMY_NAME = 'Test Record';
	static final Id ID_LOGGED_USER = UserInfo.getUserId();

	public String getUserNamePrefix() {
		return UserInfo.getOrganizationId() + System.now().millisecond();
	}

	public static List<Task> Task_OutboundCall(Set<Id> whatIds, Set<Id> whoIds, String tskStatus, Integer createdDaysAgo) {
		List<Task> tasks = new List<Task>();
		if (whatIds != null) {
			for (Id i : whatIds) {
				Task t = (Task) Task.SObjectType.newSObject(null, true);
				t.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Call').getRecordTypeId();
				t.Type = 'Outbound Call';
				t.Status = tskStatus;
				t.CreatedDate = System.Now().addDays(createdDaysAgo);
				t.WhatId = i;
				tasks.add(t);
			}
		} else if (whoIds != null) {
			for (Id i : whoIds) {
				Task t = (Task) Task.SObjectType.newSObject(null, true);
				t.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Call').getRecordTypeId();
				t.Type = 'Outbound Call';
				t.Status = tskStatus;
				t.CreatedDate = System.Now().addDays(createdDaysAgo);
				t.WhoId = i;
				tasks.add(t);
			}
		}
		return tasks;
	}

	public static List<Task> Task_Standard(Set<Id> whatIds, Set<Id> whoIds, String tskStatus, Integer createdDaysAgo) {
		List<Task> tasks = new List<Task>();
		if (whatIds != null) {
			for (Id i : whatIds) {
				Task t = (Task) Task.SObjectType.newSObject(null, true);
				t.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Call').getRecordTypeId();
				t.Type = 'Standard';
				t.Status = tskStatus;
				t.CreatedDate = System.Now().addDays(createdDaysAgo);
				t.WhatId = i;
				tasks.add(t);
			}
		} else if (whoIds != null) {
			for (Id i : whoIds) {
				Task t = (Task) Task.SObjectType.newSObject(null, true);
				t.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Call').getRecordTypeId();
				t.Type = 'Standard';
				t.Status = tskStatus;
				t.CreatedDate = System.Now().addDays(createdDaysAgo);
				t.WhoId = i;
				tasks.add(t);
			}
		}
		return tasks;
	}

	//*********************************************************************
	//    Leads
	//*********************************************************************

	public static List<Lead> Leads(Integer NumberOfLeads) {
		List<Lead> leadList = new List<Lead>();
		for (Integer x = 0; x < NumberOfLeads; x++) {
			String random = String.valueOf(Math.random()).right(5);
			Lead l = (Lead) Lead.SObjectType.newSObject(null, true);
			l.FirstName = 'first_' + random + String.valueOf(x);
			l.LastName = 'last_' + random + String.valueOf(x);
			l.Company = 'company_' + random + String.valueOf(x);
			l.Email = String.valueOf(x) + 'lead' + random + '@test.com';
			l.Phone = String.valueOf(Math.random()).right(9);
			leadList.add(l);
		}
		System.assertEquals(NumberOfLeads, leadList.size(), 'Number of leads in list should be ' + NumberOfLeads);
		return leadList;
	}

	//*********************************************************************
	//    State
	//*********************************************************************

	public static List<State__c> States(String StatePrefixName, Integer NumberOfStates) {
		List<State__c> stateList = new List<State__c>();
		for (Integer x = 0; x < NumberOfStates; x++) {
			State__c s = (State__c) State__c.SObjectType.newSObject(null, true);
			s.Name = StatePrefixName + x;
			stateList.add(s);
		}
		System.assertEquals(NumberOfStates, stateList.size(), 'Number of states in list should be ' + NumberOfStates);
		return stateList;
	}

	//*********************************************************************
	//    Benefit Orders
	//*********************************************************************

	public static Account CompanyAccount() {
		Account acc = createAccount('Company');
		insert acc;
		return acc;
	}

	public static Account ResellerAccount() {
		Account acc = createAccount('Reseller');
		insert acc;
		return acc;
	}

	public static Account createAccount(String recType) {
		Id recTypeId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get(recType).getRecordTypeId();
		Account acc = (Account) Account.SObjectType.newSObject(recTypeId, true);
		String dateString = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
		Integer randomInt = Integer.valueOf(math.rint(math.random() * 1000000));
		String uniqueName = dateString + randomInt;
		acc.Name = 'TEST ACCOUNT';
		acc.Joined_Date_Panda__c = System.today();
		acc.ZP_Company_ID__c = uniqueName.left(20);
		return acc;
	}

	public static Opportunity BenefitsNewPlanOpportunity() {
		Account acc = CompanyAccount();
		Opportunity opp = TestUtility.createOpportunity('Benefits New Plan', acc.Id);
		insert opp;
		return opp;
	}

	public static Opportunity BenefitsBoROpportunity() {
		Account acc = CompanyAccount();
		Opportunity opp = TestUtility.createOpportunity('Benefits BoR', acc.Id);
		insert opp;
		return opp;
	}

	public static Opportunity BenefitsRenewalOpportunity() {
		Account acc = CompanyAccount();
		Opportunity opp = TestUtility.createOpportunity('Benefits Renewal', acc.Id);
		insert opp;
		return opp;
	}

	public static Opportunity createOpportunity(String recType, Id accountId) {
		Id recTypeId = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName().get(recType).getRecordTypeId();
		Opportunity opp = (Opportunity) Opportunity.SObjectType.newSObject(recTypeId, true);
		String dateString = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
		Integer randomInt = Integer.valueOf(math.rint(math.random() * 1000000));
		String uniqueName = dateString + randomInt;
		String strSourceId = 'hawaiian_ice-new_plans_application-' + uniqueName;
		opp.Name = 'TEST OPPORTUNITY';
		opp.StageName = 'STAGENAME';
		opp.CloseDate = System.Today();
		opp.AccountId = accountId;
		opp.Source_ID__c = strSourceId;
		return opp;
	}

	public static Opportunity getNewOpportunity(String recType, Id accountId) {
		Id recTypeId = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName().get(recType).getRecordTypeId();
		Opportunity opp = (Opportunity) Opportunity.SObjectType.newSObject(recTypeId, true);
		opp.Name = 'TEST OPPORTUNITY';
		opp.StageName = 'SAL';
		opp.CloseDate = System.Today();
		opp.AccountId = accountId;
		opp.HI_Opportunity_Assignment_State__c = 'California';

		if (recType == 'Benefits BYOB') {
			opp.SGHI_LGHI__c = 'SGHI';
			opp.Renewal_Date__c = System.today();
			opp.Funding_Type__c = 'Self funded';
			opp.BYOB_Source__c = 'Renewals';
			opp.BYOB_Broker__c = 'USI';
			opp.Handoff_Email_Sent__c = true;
		}
		insert opp;
		return opp;
	}

	public static Policy__c Policy() {
		Opportunity opp = BenefitsNewPlanOpportunity();
		Carrier__c car = Carrier();
		return new TestUtility().insertPolicy(opp.Id, car.Id);
	}

	private Policy__c insertPolicy(Id opportunityId, Id carrierId) {
		Policy__c plc = (Policy__c) Policy__c.SObjectType.newSObject();
		plc.Name = 'TEST POLICY';
		plc.Opportunity__c = opportunityId;
		plc.Carrier__c = carrierId;
		plc.Is_Selected__c = true;
		insert plc;
		return plc;
	}

	public static list<Policy__c> insertPolicyForDifferentBenefitType(Id opportunityId, Id carrierId, Integer noOfPolicy) {
		list<String> benefitTypes = new List<String>{ 'Medical', 'Dental', 'Vision', 'Life', 'Long Term Disability', 'Short Term Disability' };
		list<Policy__c> plList = new List<Policy__c>();
		integer i = 0;
		for (String s : benefitTypes) {
			Policy__c plc = (Policy__c) Policy__c.SObjectType.newSObject();
			plc.Name = 'TEST POLICY';
			plc.Opportunity__c = opportunityId;
			plc.Carrier__c = carrierId;
			plc.Is_Selected__c = true;
			plc.Benefit_Type__c = s;
			plList.add(plc);
			i++;
			if (i == noOfPolicy) {
				break;
			}
		}
		insert plList;

		return plList;
	}

	public static Benefit_Order__c NewPlanBenefitOrder() {
		Opportunity opp = BenefitsNewPlanOpportunity();
		Benefit_Order__c benefitOrder = createBenefitOrder('New Plan', opp.Id);
		benefitOrder.Account__c = opp.AccountId;
		insert benefitOrder;
		return benefitOrder;
	}

	public static Benefit_Order__c createBenefitOrder(String recType, Id opportunityId) {
		Id recTypeId = Benefit_Order__c.SObjectType.getDescribe().getRecordTypeInfosByName().get(recType).getRecordTypeId();
		Benefit_Order__c ben = (Benefit_Order__c) Benefit_Order__c.SObjectType.newSObject();
		ben.Name = 'TEST BENEFIT ORDER';
		ben.RecordTypeId = recTypeId;
		ben.Opportunity__c = opportunityId;
		ben.Status_Detail__c = 'Owner only group';
		return ben;
	}

	public static Carrier_Order__c CarrierOrder() {
		Benefit_Order__c ben = NewPlanBenefitOrder();
		Carrier__c car = Carrier();
		Carrier_Order__c carrierOrder = new TestUtility().createCarrierOrder(car.Id, ben.Id);
		insert carrierOrder;
		return carrierOrder;
	}

	public static Carrier_Order__c CarrierOrderWithStage(String impStage) {
		Benefit_Order__c ben = NewPlanBenefitOrder();
		Carrier__c car = Carrier();
		Carrier_Order__c carrierOrder = new TestUtility().createCarrierOrder(car.Id, ben.Id);
		carrierOrder.Implementation_Stage__c = impStage;
		insert carrierOrder;
		return carrierOrder;
	}

	private Carrier_Order__c createCarrierOrder(Id carrierId, Id benefitOrderId) {
		Carrier_Order__c car = (Carrier_Order__c) Carrier_Order__c.SObjectType.newSObject();
		car.Name = 'TEST CARRIER ORDER';
		car.Carrier__c = carrierId;
		car.Benefit_Order__c = benefitOrderId;
		car.Order_Type__c = 'TAdA: Pre OE Setup';
		return car;
	}

	public static Carrier__c Carrier() {
		State__c state = State();
		Carrier__c carrier = new TestUtility().createCarrier(state.Id);
		insert carrier;
		return carrier;
	}

	private Carrier__c createCarrier(Id stateId) {
		Carrier__c carrier = (Carrier__c) Carrier__c.SObjectType.newSObject();
		carrier.Name = 'TEST CARRIER';
		carrier.State__c = stateId;
		return carrier;
	}

	public static State__c State() {
		State__c state = new TestUtility().createState();
		insert state;
		return state;
	}

	private State__c createState() {
		State__c state = (State__c) State__c.SObjectType.newSObject();
		state.Abbreviation__c = 'TS';
		state.Name = 'TEST STATE';
		return state;
	}

	//*********************************************************************
	//    Bulk SObjects
	//*********************************************************************

	public static void InsertCompanyLeads(Integer quantity) {
		insert new TestUtility().createLeads(quantity, 'Company');
	}

	private List<Lead> createLeads(Integer quantity, String recType) {
		Id recTypeId = Lead.SObjectType.getDescribe().getRecordTypeInfosByName().get(recType).getRecordTypeId();
		List<Lead> leads = new List<Lead>();
		for (Integer i = 0; i < quantity; i++) {
			String random = String.valueOf(i) + String.valueOf(Math.random()).right(5);
			Lead lead = (Lead) Schema.Lead.SObjectType.newSObject(recTypeId, true);
			lead.FirstName = 'FIRST' + random;
			lead.LastName = 'LAST' + random;
			lead.Email = 'TEST' + random + '@LEAD.COM';
			lead.Company = 'COMPANY' + random;
			lead.Phone = '1234567890';
			leads.add(lead);
		}
		return leads;
	}
	/**
	 * Create test product
	 */
	public static Product2 createTestProduct(String prodName, String family, Boolean isInsert) {
		Product2 prod = new Product2(Name = prodName, Family = family);
		if (isInsert) {
			insert prod;
		}
		return prod;
	}
	/**
	 * Create test price book entry and return the object
	 */
	public static PricebookEntry createTestPriceBookEntry(Id prodId, Decimal unitPrice, Id priceBookId, Boolean isInsert) {
		PriceBookEntry pbe = new PricebookEntry();
		pbe.Product2Id = prodId;
		pbe.UnitPrice = unitPrice;
		pbe.Pricebook2Id = priceBookId;
		pbe.IsActive = true;
		if (isInsert) {
			insert pbe;
		}
		return pbe;
	}
	/**
	 * Create test policy record
	 */
	public static Policy__c createTestPolicy(Id opportunityId, Id carrierId, Boolean isSelected, String name, Id carrierOrder, Boolean isInsert) {
		Policy__c plc = new Policy__c();
		plc.Name = name;
		plc.Opportunity__c = opportunityId;
		plc.Carrier__c = carrierId;
		plc.Is_Selected__c = isSelected;
		plc.Carrier_Order__c = carrierOrder;
		if (isInsert) {
			insert plc;
		}
		return plc;
	}
	/**
	 * Create test Carrier Record
	 */
	public static Carrier__c createTestCarrier(String name, String state, Boolean isInsert) {
		Carrier__c carrier = new Carrier__c();
		carrier.Name = name;
		carrier.State__c = state;
		if (isInsert) {
			insert carrier;
		}
		return carrier;
	}
	/**
	 * Create test carrier record
	 */
	public static Carrier_Order__c createTestCarrierOrder(Id carrierId, String name, Id benefitOrderId, Boolean isInsert) {
		Carrier_Order__c carOrder = new Carrier_Order__c();
		carOrder.Carrier__c = carrierId;
		carOrder.Name = name;
		carOrder.Benefit_Order__c = benefitOrderId;
		if (isInsert) {
			insert carOrder;
		}
		return carOrder;
	}

	/**
	 * Create test benefit order
	 */
	public static Benefit_Order__c createTestBenefitOrder(String recType, Id opportunityId, String name, Boolean isInsert) {
		Id recTypeId = Benefit_Order__c.SObjectType.getDescribe().getRecordTypeInfosByName().get(recType).getRecordTypeId();
		Benefit_Order__c ben = new Benefit_Order__c();
		ben.Name = name;
		ben.RecordTypeId = recTypeId;
		ben.Opportunity__c = opportunityId;
		if (isInsert) {
			insert ben;
		}
		return ben;
	}

	public static PriceBook2 createCompanyPriceBookInformation() {
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();

		PriceBook2 objPB = new TestDataFactory.PriceBookBuilder().setName(objTierConfig.New_Price_1__c).setActive().build();
		insert objPB;

		List<Product2> list_Product = new List<Product2>();
		list_Product.add(TestUtility.createTestProduct('Active Employee', 'Payroll', false));
		list_Product.add(TestUtility.createTestProduct('Contractor', 'Employee', false));
		list_Product.add(TestUtility.createTestProduct('Medical', 'Benefit', false));
		list_Product.add(TestUtility.createTestProduct('Dental', 'Employee', false));
		list_Product.add(TestUtility.createTestProduct('Vision', 'Employee', false));
		list_Product.add(TestUtility.createTestProduct('Life', 'Employee', false));
		list_Product.add(TestUtility.createTestProduct('Long Term Disability', 'Employee', false));
		list_Product.add(TestUtility.createTestProduct('HSA', 'HSA', false));
		list_Product.add(TestUtility.createTestProduct('Commuter', 'Commuter', false));
		insert list_Product;

		List<PricebookEntry> list_PPEntry = new List<PricebookEntry>();
		list_PPEntry.add(TestUtility.createTestPriceBookEntry(list_Product[0].Id, 5, Test.getStandardPriceBookId(), false));
		list_PPEntry.add(TestUtility.createTestPriceBookEntry(list_Product[1].Id, 5, Test.getStandardPriceBookId(), false));
		list_PPEntry.add(TestUtility.createTestPriceBookEntry(list_Product[2].Id, 5, Test.getStandardPriceBookId(), false));
		list_PPEntry.add(TestUtility.createTestPriceBookEntry(list_Product[3].Id, 5, Test.getStandardPriceBookId(), false));
		list_PPEntry.add(TestUtility.createTestPriceBookEntry(list_Product[4].Id, 5, Test.getStandardPriceBookId(), false));
		list_PPEntry.add(TestUtility.createTestPriceBookEntry(list_Product[5].Id, 5, Test.getStandardPriceBookId(), false));
		list_PPEntry.add(TestUtility.createTestPriceBookEntry(list_Product[6].Id, 5, Test.getStandardPriceBookId(), false));
		list_PPEntry.add(TestUtility.createTestPriceBookEntry(list_Product[7].Id, 5, Test.getStandardPriceBookId(), false));
		list_PPEntry.add(TestUtility.createTestPriceBookEntry(list_Product[8].Id, 5, Test.getStandardPriceBookId(), false));
		list_PPEntry.add(TestUtility.createTestPriceBookEntry(list_Product[0].Id, 5, objPB.id, false));
		list_PPEntry.add(TestUtility.createTestPriceBookEntry(list_Product[1].Id, 5, objPB.id, false));
		list_PPEntry.add(TestUtility.createTestPriceBookEntry(list_Product[2].Id, 5, objPB.id, false));
		list_PPEntry.add(TestUtility.createTestPriceBookEntry(list_Product[3].Id, 5, objPB.id, false));
		list_PPEntry.add(TestUtility.createTestPriceBookEntry(list_Product[4].Id, 5, objPB.id, false));
		list_PPEntry.add(TestUtility.createTestPriceBookEntry(list_Product[5].Id, 5, objPB.id, false));
		list_PPEntry.add(TestUtility.createTestPriceBookEntry(list_Product[6].Id, 5, objPB.id, false));
		list_PPEntry.add(TestUtility.createTestPriceBookEntry(list_Product[7].Id, 5, objPB.id, false));
		list_PPEntry.add(TestUtility.createTestPriceBookEntry(list_Product[8].Id, 5, objPB.id, false));
		insert list_PPEntry;

		return objPB;
	}

	/**
	 * @Description - This method creates Users.
	 * @param - profileName (String): accepts name for Profile.
	 * @param - numUsers (Integer): accepts number of users.
	 * @return - List<User> objects
	 */
	public static List<User> createUsers(String profileName, Integer numUsers) {
		// Generating a Unique Name
		String orgId = UserInfo.getOrganizationId();
		String dateString = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
		Integer randomInt = Integer.valueOf(math.rint(math.random() * 1000000));
		String uniqueName = orgId + dateString + randomInt;

		// Querying for the Profile record matching the input profile name.
		Profile prof = [SELECT ID FROM Profile WHERE Name = :profileName];
		List<User> usrList = new List<User>();
		for (Integer i = 0; i < numUsers; i++) {
			User usr = new User(
				firstname = 'test',
				lastname = 'usr',
				email = 'usr' + uniqueName + '@test' + orgId + '.org',
				username = 'usr' + uniqueName + '@test' + orgId + '.org',
				alias = uniqueName.substring(18, 23),
				TimeZoneSidkey = 'GMT',
				LocaleSidKey = 'en_US',
				emailencodingKey = 'UTF-8',
				languagelocalekey = 'en_US',
				ProfileId = prof.ID
			);
			usrList.add(usr);
		}
		return usrList;
	}

	public static void createSkillCriteriaSetupRecord() {
		List<Skill_Criteria_Setup__c> list_SkillsSetup = new List<Skill_Criteria_Setup__c>();

		list_SkillsSetup.add(
			new Skill_Criteria_Setup__c(
				Name = 'Implementation Advocate-Core',
				Team__c = 'Implementation Advocate',
				Skill_Type__c = 'Core',
				Filter_Criteria__c = 'Order Type;Region;Partner;Benefits Big Desk;Maestro'
			)
		);

		list_SkillsSetup.add(new Skill_Criteria_Setup__c(Name = 'Advisor-Core', Team__c = 'Advisor', Skill_Type__c = 'Core', Filter_Criteria__c = 'Region;Benefits Big Desk;Order Allocation;State'));

		list_SkillsSetup.add(new Skill_Criteria_Setup__c(Name = 'Benefits Designer-Core', Team__c = 'Benefits Designer', Skill_Type__c = 'Core', Filter_Criteria__c = 'Region;State;Coverage type'));

		list_SkillsSetup.add(
			new Skill_Criteria_Setup__c(
				Name = 'Renewal Specialist-Core',
				Team__c = 'Renewal Specialist',
				Skill_Type__c = 'Core',
				Filter_Criteria__c = 'Region;Benefits Big Desk;Order Allocation;State'
			)
		);

		insert list_SkillsSetup;
	}

	public static void createCarrierList() {
		String strState1 =
			'AL; AK; AZ; AR; CA; CO; CT; DE; FL; GA; HI; ID; IL; IN; IA; KS; KY; LA; ME; MD; MA;' +
			' MI; MN; MS; MO; MT; NE; NV; NH; NJ; NM; NY; NC; ND; OH; OK; OR; PA; RI; SC; SD; TN;' +
			' TX; UT; VT; VA; WA; WV; WI; WY';
		String strState2 = 'AL; AK; AZ; AR; CA; CO; CT; DE; FL; GA';
		String strState3 = 'HI; ID; IL; IN; IA; KS; KY; LA; ME; MD; MA';
		String strState4 = 'MI; MN; MS; MO; MT; NE; NV; NH; NJ';
		String strState5 = 'NM; NY; NC; ND; OH; OK; OR; PA; RI; SC; SD; TN';
		String strState6 = 'TX; UT; VT; VA; WA; WV; WI; WY';

		List<Carrier__c> lstCarrier = new List<Carrier__c>();
		//lstCarrier.add(new Carrier__c(Name='Alegeus', Carrier_Play_Mode__c='Alegeus', State__c=strState1, Carrier_Unique_Name__c='Alegeus'));
		lstCarrier.add(new Carrier__c(Name = 'Aetna', Carrier_Play_Mode__c = 'Other', State__c = strState2, Carrier_Unique_Name__c = 'Aetna', Submission_BOR_Assignment__c = false));
		lstCarrier.add(new Carrier__c(Name = 'Ameritas', Carrier_Play_Mode__c = 'Other', State__c = strState3, Carrier_Unique_Name__c = 'Ameritas', Submission_BOR_Assignment__c = false));
		lstCarrier.add(
			new Carrier__c(
				Name = 'Assurant Sun Life Financial',
				Carrier_Play_Mode__c = 'Other',
				State__c = strState4,
				Carrier_Unique_Name__c = 'Assurant Sun Life Financial',
				Submission_BOR_Assignment__c = false
			)
		);
		lstCarrier.add(new Carrier__c(Name = 'Avesis', Carrier_Play_Mode__c = 'Other', State__c = strState5, Carrier_Unique_Name__c = 'Avesis', Submission_BOR_Assignment__c = false));
		lstCarrier.add(new Carrier__c(Name = 'Best Life', Carrier_Play_Mode__c = 'Other', State__c = strState6, Carrier_Unique_Name__c = 'Best Life', Submission_BOR_Assignment__c = false));
		insert lstCarrier;
	}

	public static void createFlexibleWorkforceCarriers() {
		List<Flexible_Workforce_Carriers__c> lstCarrier = new List<Flexible_Workforce_Carriers__c>();
		lstCarrier.add(new Flexible_Workforce_Carriers__c(Name = 'Aetna', Carrier_Name__c = 'Aetna', Type__c = 'Both'));
		lstCarrier.add(new Flexible_Workforce_Carriers__c(Name = 'Ameritas', Carrier_Name__c = 'Ameritas', Type__c = 'Both'));
		lstCarrier.add(new Flexible_Workforce_Carriers__c(Name = 'Assurant Sun Life Financial', Carrier_Name__c = 'Assurant Sun Life Financial', Type__c = 'Both'));
		lstCarrier.add(new Flexible_Workforce_Carriers__c(Name = 'Avesis', Carrier_Name__c = 'Avesis', Type__c = 'Both'));
		lstCarrier.add(new Flexible_Workforce_Carriers__c(Name = 'Best Life', Carrier_Name__c = 'Best Life', Type__c = 'Both'));
		insert lstCarrier;
	}

	public static void createStateNametoAbbreviationsMapping() {
		List<State_Name_to_abbreviations_Mapping__c> lstStateMapping = new List<State_Name_to_abbreviations_Mapping__c>();
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Alabama', State_Abbreviation__c = 'AL', State_Name__c = 'Alabama', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Alaska', State_Abbreviation__c = 'AK', State_Name__c = 'Alaska', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Arizona', State_Abbreviation__c = 'AZ', State_Name__c = 'Arizona', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Arkansas', State_Abbreviation__c = 'AR', State_Name__c = 'Arkansas', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'California', State_Abbreviation__c = 'CA', State_Name__c = 'California', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Colorado', State_Abbreviation__c = 'CO', State_Name__c = 'Colorado', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Connecticut', State_Abbreviation__c = 'CT', State_Name__c = 'Connecticut', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Delaware', State_Abbreviation__c = 'DE', State_Name__c = 'Delaware', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'District of Columbia', State_Abbreviation__c = 'DC', State_Name__c = 'District of Columbia', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Florida', State_Abbreviation__c = 'FL', State_Name__c = 'Florida', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Georgia', State_Abbreviation__c = 'GA', State_Name__c = 'Georgia', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Hawaii', State_Abbreviation__c = 'HI', State_Name__c = 'Hawaii', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Idaho', State_Abbreviation__c = 'ID', State_Name__c = 'Idaho', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Illinois', State_Abbreviation__c = 'IL', State_Name__c = 'Illinois', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Indiana', State_Abbreviation__c = 'IN', State_Name__c = 'Indiana', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Iowa', State_Abbreviation__c = 'IA', State_Name__c = 'Iowa', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Kansas', State_Abbreviation__c = 'KS', State_Name__c = 'Kansas', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Kentucky', State_Abbreviation__c = 'KY', State_Name__c = 'Kentucky', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Louisiana', State_Abbreviation__c = 'LA', State_Name__c = 'Louisiana', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Maine', State_Abbreviation__c = 'ME', State_Name__c = 'Maine', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Maryland', State_Abbreviation__c = 'MD', State_Name__c = 'Maryland', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Massachusetts', State_Abbreviation__c = 'MA', State_Name__c = 'Massachusetts', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Michigan', State_Abbreviation__c = 'MI', State_Name__c = 'Michigan', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Minnesota', State_Abbreviation__c = 'MN', State_Name__c = 'Minnesota', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Mississippi', State_Abbreviation__c = 'MS', State_Name__c = 'Mississippi', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Missouri', State_Abbreviation__c = 'MO', State_Name__c = 'Missouri', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Montana', State_Abbreviation__c = 'MT', State_Name__c = 'Montana', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Nebraska', State_Abbreviation__c = 'NE', State_Name__c = 'Nebraska', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Nevada', State_Abbreviation__c = 'NV', State_Name__c = 'Nevada', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'New Hampshire', State_Abbreviation__c = 'NH', State_Name__c = 'New Hampshire', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'New Jersey', State_Abbreviation__c = 'NJ', State_Name__c = 'New Jersey', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'New Mexico', State_Abbreviation__c = 'NM', State_Name__c = 'New Mexico', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'New York', State_Abbreviation__c = 'NY', State_Name__c = 'New York', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'North Carolina', State_Abbreviation__c = 'NC', State_Name__c = 'North Carolina', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'North Dakota', State_Abbreviation__c = 'ND', State_Name__c = 'North Dakota', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Ohio', State_Abbreviation__c = 'OH', State_Name__c = 'Ohio', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Oklahoma', State_Abbreviation__c = 'OK', State_Name__c = 'Oklahoma', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Oregon', State_Abbreviation__c = 'OR', State_Name__c = 'Oregon', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Pennsylvania', State_Abbreviation__c = 'PA', State_Name__c = 'Pennsylvania', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Rhode Island', State_Abbreviation__c = 'RI', State_Name__c = 'Rhode Island', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'South Carolina', State_Abbreviation__c = 'SC', State_Name__c = 'South Carolina', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'South Dakota', State_Abbreviation__c = 'SD', State_Name__c = 'South Dakota', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Tennessee', State_Abbreviation__c = 'TN', State_Name__c = 'Tennessee', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Texas', State_Abbreviation__c = 'TX', State_Name__c = 'Texas', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Utah', State_Abbreviation__c = 'UT', State_Name__c = 'Utah', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Vermont', State_Abbreviation__c = 'VT', State_Name__c = 'Vermont', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Virginia', State_Abbreviation__c = 'VA', State_Name__c = 'Virginia', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Washington', State_Abbreviation__c = 'WA', State_Name__c = 'Washington', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'West Virginia', State_Abbreviation__c = 'WV', State_Name__c = 'West Virginia', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Wisconsin', State_Abbreviation__c = 'WI', State_Name__c = 'Wisconsin', HI_Active__c = true));
		lstStateMapping.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Wyoming', State_Abbreviation__c = 'WY', State_Name__c = 'Wyoming', HI_Active__c = true));

		insert lstStateMapping;
	}

	/**
	 * Create test TTF record
	 */
	public static Transition_to_Fulfillment__c createTestTransitionToFulfillment(Id idAccount, Id idContact, Id idOpportunity, Id idRecordType, Boolean blnSendOrder) {
		Transition_to_Fulfillment__c objTTF = new Transition_to_Fulfillment__c();
		objTTF.Contact__c = idContact;
		objTTF.Benefits_Point_of_Contact__c = 'Test';
		objTTF.Opportunity__c = idOpportunity;
		objTTF.Account__c = idAccount;
		objTTF.Renewal_Exception__c = 'Yes';
		objTTF.Renewal_Date__c = Date.today();
		objTTF.Medical_New_Carrier__c = 'Blue Cross Blue Shield';
		objTTF.Dental_Carrier__c = 'Beam';
		objTTF.Vision_Carrier__c = 'VSP';
		objTTF.LiDi_Carrier__c = 'Guardian';
		objTTF.FSA_HSA_401K__c = 'Principal';
		objTTF.Contact_Preference__c = 'Call';
		objTTF.RecordTypeId = idRecordType;
		objTTF.Send_Order__c = blnSendOrder;

		if (idRecordType == Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits BYB')) {
			objTTF.Priority__c = 'Y';
			objTTF.Priority_Reasons__c = 'Select Tier;';
		}
		insert objTTF;

		return objTTF;
	}

	/**
	 * Create Contact record
	 */
	public static Contact createTestContact(Id idAccount, Id idRecordType) {
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(idRecordType)
			.setEmail('abc@gusto.com')
			.setAccountId(idAccount)
			.setFirstName('Test Contact')
			.setLastName('Test')
			.build();
		insert objContact;

		return objContact;
	}

	public static Carrier_Order__c createCarrierOrder(Id idBenefitOrder, Id idCarrier, Id idRecordType, Boolean blnChild, Id idParentCO) {
		Carrier_Order__c objCarrierOrder = (Carrier_Order__c) Carrier_Order__c.SObjectType.newSObject();
		objCarrierOrder.Name = DUMMY_NAME;
		objCarrierOrder.Carrier__c = idCarrier;
		objCarrierOrder.Benefit_Order__c = idBenefitOrder;
		objCarrierOrder.RecordTypeId = idRecordType;

		if (blnChild && idParentCO != null) {
			objCarrierOrder.Parent_Carrier_Order__c = idParentCO;
		}
		insert objCarrierOrder;

		return objCarrierOrder;
	}

	public static Opportunity createOpp(Id idRecordType, Id idAccount, String strStageName) {
		Opportunity objOpp = new Opportunity(RecordTypeId = idRecordType);
		objOpp.AccountId = idAccount;
		objOpp.StageName = strStageName;
		objOpp.CloseDate = System.today();
		objOpp.Name = DUMMY_NAME;
		insert objOpp;

		return objOpp;
	}

	public static Account createAccount(Boolean blnChild, Account objParentAccount, String strZPCompanyId) {
		Account objAcc = new Account(Name = DUMMY_NAME, ZP_Company_Id__c = strZPCompanyId);
		if (blnChild && objParentAccount != null) {
			objAcc.Parent = objParentAccount;
			objAcc.ZP_Company_Id__c = strZPCompanyId;
		}
		insert objAcc;

		return objAcc;
	}

	public static Benefit_Order__c createBenefitOrder(Id idOpportunity, Id idRecordType, Boolean blnChild, Id idParentBO) {
		Benefit_Order__c objBO = new Benefit_Order__c();
		objBO.Opportunity__c = idOpportunity;
		objBO.RecordTypeId = idRecordType;
		objBO.OwnerId = ID_LOGGED_USER;

		if (blnChild && idParentBO != null) {
			objBO.Parent_Benefit_Order__c = idParentBO;
		}
		insert objBO;

		return objBo;
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Create customer case with Integration Id.
	 * @Parm        : idOppty 	:	Opportunity Id
	 * 				: idBO		:	Benefit Order Id
	 * 				: idAcount 	:	Account Id
	 * 				: idContact	: 	Contact Id
	 * 				: strRecTypeName	: 	Record Type Name
	 **/
	public static Case createCustomerCase(Id idOppty, Id idBO, Id idAccount, Id idContact, String strRecTypeName) {
		Case objCase = createCase(idAccount, idContact, strRecTypeName);
		objCase.Integration_Id__c = 'hippo-' + idOppty;
		objCase.Benefit_Order__c = idBO;
		return objCase;
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Create case
	 * @Parm        : idAcount 	:	Account Id
	 * 				: idContact	: 	Contact Id
	 * 				: strRecTypeName	: 	Record Type Name
	 **/
	public static Case createCase(Id idAccount, Id idContact, String strRecTypeName) {
		Case objCase = new Case(
			AccountId = idAccount,
			Subject = 'Test onboarding case',
			Priority = 'Medium',
			ContactId = idContact,
			RecordTypeId = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get(strRecTypeName).getRecordTypeId()
		);

		return objCase;
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Get SubmissionMetadata
	 * @Parm        : NA
	 *
	 **/
	public static List<RPA_Submission_Automation_rules__mdt> getSubmissionMetadata(String strValue) {
		List<RPA_Submission_Automation_rules__mdt> list_SubCarrierConfiguration = [
			SELECT
				DeveloperName,
				MasterLabel,
				Carrier_Id__c,
				Applicable_to_All_States__c,
				Order_Type__c,
				Active__c,
				Dont_Allow__c,
				HI_Carrier_Id__c,
				No_of_Business_Days__c,
				Submission_Type__c,
				No_of_days_to_Effective_Deadline__c
			FROM RPA_Submission_Automation_rules__mdt
			WHERE Carrier_Id__c != NULL AND Order_Type__c != NULL AND Submission_Type__c = :strValue
		];
		return list_SubCarrierConfiguration;
	}
}