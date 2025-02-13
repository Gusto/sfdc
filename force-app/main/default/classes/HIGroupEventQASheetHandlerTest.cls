/**
 * @name         HIGroupEventQASheetHandlerTest
 * @description  Test class for HIGroupEventQASheetHandler, QASheetHelper
 **/
@isTest
public class HIGroupEventQASheetHandlerTest {
	public static String STR_JSON =
		'{"new_tadas":["test","test1"],"renewing_tadas":["test","test1"],"terminating_hsa":true,"peo_switcher":"Test","has_prior_coverage":true,"waiving_initial_waiting_period": "yes","application_type":"NewPlansApplication","application_id":4971,"original_group_type":"New Plan","company_id":"100989002",' +
		'"benefit_address":null,"filing_address":{"street_1":"501 Sheldon Rue","street_2":"Apt. 758","city":"Irvine","state":"CA","zip":"92618","county_name":"Orange",' +
		'"country":"USA"},"entity_type":"LLC","npa_panda_s_corp_mismatch":true,"scheduled_payroll_run_dates":["2017-07-31"],"wc_status":"No Policy","fein":"123456789",' +
		'"applied_for_benefits_previously":false,"date_of_first_hired_ee":"2020-08-01","new_hires_not_on_qwr":"claudia","advocate_additional_details":"notes for advocate abcded",' +
		'"submission_additional_details":"notes for submission 12345","accountant_partner":null,"ooo_hand_off_comments":null,"sales_deadline_passed":"no",' +
		'"date_business_established":"2020-01-01","part_time_ees_eligible":null,"owners_not_on_qwr":"claudia","others_not_on_qwr":"claudia",' +
		'"secretary_of_state_registration_status":"Active","registration_date":"2020-01-01","full_two_percent_shareholder_contributions_enabled":null,' +
		'"has_affiliates":null,"owner_names_and_percent_ownership":"Claudia 100%","two_percent_shareholders":null,"subject_to_federal_or_state_cobra":"Federal",' +
		'"continuation_of_coverage_set_up_in_hippo":"no","basic_setup_required":"yes","has_non_owner_non_spouse_w2_ee":"yes","billing_setup_complete":null,' +
		'"tada_setup_complete":null,"baa_poa_signatory_name_and_title":"john doe; treasure","names_of_ees_in_waiting_period":null,"baa_poa_signed":"no",' +
		'"wc_carrier_name":"APIntego","owners_not_covered_by_wc":"None","oe_blockers":[],"additional_details_issues_resolved":null,"group_ready_for_oe":null,' +
		'"ownership_docs_match_expected_owners":"yes","ownership_discrepancy_details":null,"benefits_address_details_match_provided_documentation":"no",' +
		'"address_mismatch_notes":"Address test","bank_details_match_bank_verification_documents":"yes","bank_detail_notes":null,"signatory_mismatch":"yes",' +
		'"signatory_mismatch_notes":"' +
		String.valueOf('a').repeat(5287) +
		'","ees_with_status_mismatch":"claudia-fulltime max-ft","unprocessed_selections":null,' +
		'"date_new_hire_payroll_ready":"2020-08-14","date_group_payroll_ready":"2020-08-15","manual_oe_required":null,"sic_valid_for_all_lines":null,' +
		'"owner_percent_need_to_be_collected":"yes","tada_owner_eligibility":"","plan_successors_predecessors":[{"predecessor_policy_name":"A", "successor_plan_name":"B"}],' +
		'"at_risk_not_meeting_ancillary_participation":null,"employer_communication":null,"personal_notes":null,"qual_loc_data":[{"plan_description":{"plan_additions":["A"],"plan_removals":["A"],"plan_renewals":["A"]},"state_carrier_id":1,"benefit_type":"medical",' +
		'"carrier_outreach_notes":null,"verified_rates":null,"risk_of_not_meeting_participation":null,"is_sic_valid":null,"documents_required_for_submission":"*1 qwr *2 roll *3 tax *4 form",' +
		'"can_offer_both_carriers_selected":null,"enough_non_owner_ees_eligible_for_coverage":"yes","effective_date_allowed":"yes","meet_affiliate_requirements":null,' +
		'"benefit_address_meet_carrier_requirements":"no","located_in_area_carrier_allows":"yes","have_enough_in_state_ees":"yes","select_plan_network_available_to_each_ee":"yes",' +
		'"plan_available_and_set_up_for_hawaii_ees":null,"carrier_consider_group_to_be_startup":"no","been_in_business_long_enough":"no","part_time_ees_eligible_for_carrier":null,' +
		'"will_meet_carrier_size_requirements_at_submission":null,"contribution_scheme_meet_carrier_requirements":"yes","contribution_changes_meet_carrier_requirements":null,' +
		'"offering_more_plans_than_potential_num_of_enrollees":null,"can_offer_all_plans_selected":null,"can_selected_networks_be_offered_together":null,' +
		'"can_selected_plan_tiers_be_offered_together":null,"has_termination_policy_been_set":null,"can_selected_packages_be_offered_together":"yes",' +
		'"meet_class_based_requirements":null,"have_class_based_contributions":null,"meet_peo_switcher_requirements":null,"waiting_period_match_carrier_requirements":null,' +
		'"quoting_scheme_correct_for_each_policy":null,"rater_required_for_submission":null,"documents_required_oa":[{"document": "Owner-doc DOH and FT/PT status annotated. ' +
		'If 3 or fewer eligible EEs - please mark each employee accordingly: EE Enrolled (not owner nor spouse of owner), EE Enrolled (Spouse of Owner), EE enrolled (Owner), Waiving.",' +
		'"option": "pending_in_gusto" },{ "document": "Schedule K-1 for all owners OR Schedule C (IRS Form 1040) for all owners", "option": "request_from_er"}]}]}';

	public static String STR_JSON_Renewal =
		'{"new_tadas":["test","test1"],"renewing_tadas":["test","test1"],"terminating_hsa":true,"peo_switcher":"Test","has_prior_coverage":true,"waiving_initial_waiting_period": "yes","application_type":"Renewal","application_id":4971,"original_group_type":"New Plan","company_id":"100989002",' +
		'"benefit_address":null,"filing_address":{"street_1":"501 Sheldon Rue","street_2":"Apt. 758","city":"Irvine","state":"CA","zip":"92618","county_name":"Orange",' +
		'"country":"USA"},"entity_type":"LLC","npa_panda_s_corp_mismatch":true,"scheduled_payroll_run_dates":["2017-07-31"],"wc_status":"No Policy","fein":"123456789",' +
		'"applied_for_benefits_previously":false,"date_of_first_hired_ee":"2020-08-01","new_hires_not_on_qwr":"claudia","advocate_additional_details":"notes for advocate abcded",' +
		'"submission_additional_details":"notes for submission 12345","accountant_partner":null,"ooo_hand_off_comments":null,"sales_deadline_passed":"no",' +
		'"date_business_established":"2020-01-01","part_time_ees_eligible":null,"owners_not_on_qwr":"claudia","others_not_on_qwr":"claudia",' +
		'"secretary_of_state_registration_status":"Active","registration_date":"2020-01-01","full_two_percent_shareholder_contributions_enabled":null,' +
		'"has_affiliates":null,"owner_names_and_percent_ownership":"Claudia 100%","two_percent_shareholders":null,"subject_to_federal_or_state_cobra":"Federal",' +
		'"continuation_of_coverage_set_up_in_hippo":"no","basic_setup_required":"yes","has_non_owner_non_spouse_w2_ee":"yes","billing_setup_complete":null,' +
		'"tada_setup_complete":null,"baa_poa_signatory_name_and_title":"john doe; treasure","names_of_ees_in_waiting_period":null,"baa_poa_signed":"no",' +
		'"wc_carrier_name":"APIntego","owners_not_covered_by_wc":"None","oe_blockers":[],"additional_details_issues_resolved":null,"group_ready_for_oe":null,' +
		'"ownership_docs_match_expected_owners":"yes","ownership_discrepancy_details":null,"benefits_address_details_match_provided_documentation":"no",' +
		'"address_mismatch_notes":"Address test","bank_details_match_bank_verification_documents":"yes","bank_detail_notes":null,"signatory_mismatch":"yes",' +
		'"signatory_mismatch_notes":"' +
		String.valueOf('a').repeat(5287) +
		'","ees_with_status_mismatch":"claudia-fulltime max-ft","unprocessed_selections":null,' +
		'"date_new_hire_payroll_ready":"2020-08-14","date_group_payroll_ready":"2020-08-15","manual_oe_required":null,"sic_valid_for_all_lines":null,' +
		'"owner_percent_need_to_be_collected":"yes","tada_owner_eligibility":"","plan_successors_predecessors":[{"predecessor_policy_name":"A", "successor_plan_name":"B"}],' +
		'"at_risk_not_meeting_ancillary_participation":null,"employer_communication":null,"personal_notes":null,"qual_loc_data":[{"plan_description":{"plan_additions":["A"],"plan_removals":["A"],"plan_renewals":["A"]},"state_carrier_id":1,"benefit_type":"medical",' +
		'"carrier_outreach_notes":null,"verified_rates":null,"risk_of_not_meeting_participation":null,"is_sic_valid":null,"documents_required_for_submission":"*1 qwr *2 roll *3 tax *4 form",' +
		'"can_offer_both_carriers_selected":null,"enough_non_owner_ees_eligible_for_coverage":"yes","effective_date_allowed":"yes","meet_affiliate_requirements":null,' +
		'"benefit_address_meet_carrier_requirements":"no","located_in_area_carrier_allows":"yes","have_enough_in_state_ees":"yes","select_plan_network_available_to_each_ee":"yes",' +
		'"plan_available_and_set_up_for_hawaii_ees":null,"carrier_consider_group_to_be_startup":"no","been_in_business_long_enough":"no","part_time_ees_eligible_for_carrier":null,' +
		'"will_meet_carrier_size_requirements_at_submission":null,"contribution_scheme_meet_carrier_requirements":"yes","contribution_changes_meet_carrier_requirements":null,' +
		'"offering_more_plans_than_potential_num_of_enrollees":null,"can_offer_all_plans_selected":null,"can_selected_networks_be_offered_together":null,' +
		'"can_selected_plan_tiers_be_offered_together":null,"has_termination_policy_been_set":null,"can_selected_packages_be_offered_together":"yes",' +
		'"meet_class_based_requirements":null,"have_class_based_contributions":null,"meet_peo_switcher_requirements":null,"waiting_period_match_carrier_requirements":null,' +
		'"quoting_scheme_correct_for_each_policy":null,"rater_required_for_submission":null,"documents_required_oa":[{"document": "Owner-doc DOH and FT/PT status annotated. ' +
		'If 3 or fewer eligible EEs - please mark each employee accordingly: EE Enrolled (not owner nor spouse of owner), EE Enrolled (Spouse of Owner), EE enrolled (Owner), Waiving.",' +
		'"option": "pending_in_gusto" },{ "document": "Schedule K-1 for all owners OR Schedule C (IRS Form 1040) for all owners", "option": "request_from_er"}]}]}';

	@testSetup
	static void testData() {
		String strState =
			'AL; AK; AZ; AR; CA; CO; CT; DE; FL; GA; HI; ID; IL; IN; IA; KS; KY; LA; ME; MD; MA; MI; MN; MS; MO;' +
			' MT; NE; NV; NH; NJ; NM; NY; NC; ND; OH; OK; OR; PA; RI; SC; SD; TN; TX; UT; VT; VA; WA; WV; WI; WY';
		Carrier__c objCarrier = new Carrier__c(Name = 'Aetna', Id__c = '1', Carrier_Play_Mode__c = 'Other', State__c = strState, Carrier_Unique_Name__c = 'Aetna');
		insert objCarrier;

		insert new TestDataFactory.CarrierVersionDetailBuilder()
			.setEffetciveDate(System.today().addDays(-30))
			.setVersionKey('Aetna001')
			.setCarrierId(objCarrier.Id)
			.setNumberOfPlansAllowedBasedOnFTE('Demo Text')
			.setNumberOfPlansAllowedOnEnrolleCount('Demo Text')
			.build();

		Account objAccount = new TestDataFactory.AccountBuilder()
			.setName('Test Account')
			.setZPCompanyId('100989002')
			.setRecordTypeId('Company')
			.build();
		insert objAccount;

		insert new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setSourceId('hawaiian_ice-new_plans_application-4971')
			.setAccountId(objAccount.Id)
			.setZPCompanyId('100989002')
			.setStage('SAL')
			.setCloseDate(System.Today())
			.setHIEffectiveDate(System.today().addDays(-2))
			.build();
	}

	@isTest
	static void testQASheetfromOppty() {
		Opportunity objOpp = [SELECT Id, AccountId FROM Opportunity WHERE Application_Id__c = '4971'];
		Account objAcct = [SELECT Name FROM Account WHERE Id = :objOpp.AccountId];

		Test.startTest();
		List<QA_Sheet__c> list_QASheet = [SELECT Id, DBA__c FROM QA_Sheet__c WHERE Opportunity__c = :objOpp.Id];
		System.assertEquals(1, list_QASheet.size(), 'QA Sheet should be created for NP Oppty');
		System.assertEquals(objAcct.Name, list_QASheet[0].DBA__c, 'QA Sheet DBA does not match');
		System.assertNotEquals(null, HIGroupEventUtil.fetchAutomatedUserId(), 'Automated User should always exist');
		Test.stopTest();
	}

	@isTest
	static void testQASheetInfoEvent() {
		Opportunity objOpp = [SELECT Id, AccountId FROM Opportunity WHERE Application_Id__c = '4971'];
		QA_Sheet__c objQASheet = [SELECT Id FROM QA_Sheet__c WHERE Opportunity__c = :objOpp.Id];
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('ecbc176c')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_QA_SHEET_INFO)
			.setProcessingState('Queued')
			.setEventInfo(STR_JSON)
			.setApplicationId('4971')
			.setCompanyId('100989002')
			.build();

		Test.startTest();
		insert objHIGroupEvent;
		Test.stopTest();

		objHIGroupEvent = [SELECT Id, Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id];
		System.assertEquals(objHIGroupEvent.Processing_State__c, 'Processed', 'Event should be processed');

		List<Company_Level_Documents__c> list_CLD = [SELECT Id, Name FROM Company_Level_Documents__c WHERE Opportunity__c = :objOpp.Id];
		System.assertEquals(2, list_CLD.size(), 'All Company Level Documents are not created');
		System.assert(list_CLD[0].Name.contains('DOH and FT/PT'), 'Name on Company Level Doc not updated');

		QA_Lines_Of_Coverage__c objQALoC = [SELECT Id, Carriers__c, Documents_Require_for_Submission__c FROM QA_Lines_Of_Coverage__c WHERE QA_Sheet__c = :objQASheet.Id];
		System.assertEquals('Aetna', objQALoC.Carriers__c, 'Carrier not updated on QA Lines of Coverage');
		System.assert(objQALoC.Documents_Require_for_Submission__c.contains('*1 qwr'), 'Doc require for submissions not updated');
	}

	@isTest
	static void testQASheetwithBOandCO() {
		Opportunity objOpp = [SELECT Id, AccountId FROM Opportunity WHERE Application_Id__c = '4971'];

		Test.startTest();
		insert new TestDataFactory.HIGroupEventBuilder()
			.setEventId('ecbc176c')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_QA_SHEET_INFO)
			.setProcessingState('Queued')
			.setEventInfo(STR_JSON)
			.setApplicationId('4971')
			.setCompanyId('100989002')
			.build();

		Benefit_Order__c objBO = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BenefitOrderUtil.NEW_PLAN_BENEFIT_ORDER_RT_ID)
			.setName('Test Benefit Order')
			.setAccount(objOpp.AccountId)
			.setOpp(objOpp.Id)
			.setCoverageEffectiveDate(System.today())
			.setSubmissionDeadline(System.today())
			.setOwnerID(UserInfo.getUserId())
			.setStatus(BenefitOrderUtil.STATUS_QUALIFICATION)
			.build();
		insert objBO;

		insert new TestDataFactory.CarrierOrderBuilder()
			.setName('Test Carrier Order')
			.setRecordTypeId(CarrierOrderUtil.RECTYPE_NEW_PLAN)
			.setBenefitOrder(objBO.Id)
			.setCarrier([SELECT Id FROM Carrier__c LIMIT 1].Id)
			.setOrderType(CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP)
			.setBenefitTypes('Medical')
			.build();
		Test.stopTest();

		QA_Sheet__c objQASheet = [SELECT Id, Benefit_Order__c FROM QA_Sheet__c WHERE Opportunity__c = :objOpp.Id];
		System.assertEquals(objBO.Id, objQASheet.Benefit_Order__c, 'Benefit Order should be linked to QA Sheet');

		Company_Level_Documents__c objCLD = [SELECT Id, Benefit_Order__c FROM Company_Level_Documents__c WHERE Opportunity__c = :objOpp.Id LIMIT 1];
		System.assertEquals(objBO.Id, objCLD.Benefit_Order__c, 'Benefit Order should be linked to Company Level Documents');

		Carrier_Order__c objCO = [SELECT Implementation_Stage__c FROM Carrier_Order__c WHERE Benefit_Order__c = :objBO.Id];
		System.assertNotEquals('Ready for Submission Prep', objCO.Implementation_Stage__c, 'Implementation Stage does not match');
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method is used to create Carrier Order with Benefit New Plan
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testQASheetwithCOBasic() {
		Opportunity objOpp = [SELECT Id, AccountId FROM Opportunity WHERE Application_Id__c = '4971'];

		Test.startTest();
		Benefit_Order__c objBO = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BenefitOrderUtil.NEW_PLAN_BENEFIT_ORDER_RT_ID)
			.setName('Test Benefit Order')
			.setAccount(objOpp.AccountId)
			.setOpp(objOpp.Id)
			.setCoverageEffectiveDate(System.today())
			.setSubmissionDeadline(System.today() - 5)
			.setOwnerID(UserInfo.getUserId())
			.setStatus(BenefitOrderUtil.STATUS_FULFILLED)
			.build();
		insert objBO;

		Id idQASheetRecordType = cache.getRecordTypeId('QA_Sheet__c', 'Benefit New Plan');
		QA_Sheet__c qas = new TestDataFactory.QASheetBuilder()
			.setBenefitOrderId(objBO.id)
			.setFederalCobraState('Federal')
			.setSICCode('7319')
			.setBAASignedBy('test')
			.setBSASigned('Yes')
			.setBSASignedBy('test')
			.setRecordTypeId(idQASheetRecordType)
			.setOpportunityId(objOpp.Id)
			.build();
		insert qas;
		insert new TestDataFactory.HIGroupEventBuilder()
			.setEventId('ecbc176c')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_QA_SHEET_INFO)
			.setProcessingState('Queued')
			.setEventInfo(STR_JSON)
			.setApplicationId('4971')
			.setCompanyId('100989002')
			.build();
		Test.stopTest();
		Carrier_Order__c objCO = [SELECT Implementation_Stage__c, Benefit_Types__c FROM Carrier_Order__c WHERE Benefit_Order__c = :objBO.Id];
		System.assertEquals('Ready for OE Prep', objCO.Implementation_Stage__c, 'Implementation Stage does not match');
		System.assertEquals('BASIC', objCO.Benefit_Types__c, 'Benefit Type does not match');
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method is used to create Carrier Order with Benefit Renewal
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testQASheetwithCOBasicRenewal() {
		Opportunity objOpp = [SELECT Id, AccountId FROM Opportunity WHERE Application_Id__c = '4971'];
		objOpp.RecordTypeId = OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID;
		update objOpp;

		Test.startTest();
		Benefit_Order__c objBO = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BenefitOrderUtil.RENEWAL_BENEFIT_ORDER_RT_ID)
			.setName('Test Benefit Order')
			.setAccount(objOpp.AccountId)
			.setOpp(objOpp.Id)
			.setCoverageEffectiveDate(System.today())
			.setSubmissionDeadline(System.today() - 5)
			.setOwnerID(UserInfo.getUserId())
			.setStatus(BenefitOrderUtil.STATUS_FULFILLED)
			.build();
		insert objBO;

		Id idQASheetRecordType = cache.getRecordTypeId('QA_Sheet__c', 'Benefit Renewal');
		QA_Sheet__c qas = new TestDataFactory.QASheetBuilder()
			.setBenefitOrderId(objBO.id)
			.setFederalCobraState('Federal')
			.setSICCode('7319')
			.setBAASignedBy('test')
			.setBSASigned('Yes')
			.setBSASignedBy('test')
			.setRecordTypeId(idQASheetRecordType)
			.setOpportunityId(objOpp.Id)
			.build();
		insert qas;
		insert new TestDataFactory.HIGroupEventBuilder()
			.setEventId('ecbc176c')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_QA_SHEET_INFO)
			.setProcessingState('Queued')
			.setEventInfo(STR_JSON_Renewal)
			.setApplicationId('4971')
			.setCompanyId('100989002')
			.build();
		Test.stopTest();
		Carrier_Order__c objCO = [SELECT Implementation_Stage__c, Benefit_Types__c FROM Carrier_Order__c WHERE Benefit_Order__c = :objBO.Id];
		System.assertEquals('Ready for OE Prep', objCO.Implementation_Stage__c, 'Implementation Stage does not match');
		System.assertEquals('BASIC', objCO.Benefit_Types__c, 'Benefit Type does not match');
	}
}