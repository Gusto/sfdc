public class HIQASheetWrapper {
	public String company_id;
	public String application_type;
	public String application_id;
	public String original_group_type; // no mapp
	public Boolean taxable_as_scorp; //QA Taxed_as_s_corp__c
	public String panda_signatory_name_and_title; //QA Signatory_Name_Title__c
	public String entity_type;
	public String sic_code; //TTA Eligible_SIC_Code__c, QA SIC_Code__c
	public String wc_status; //Active_WC__c TTF
	public String fein;
	public Boolean applied_for_benefits_previously; //Previous_Coverage__c TTF
	public String advocate_additional_details; //Additional_Details_for_Advocate__c TTF
	public String accountant_partner; //no mapping
	public String new_hires_not_on_qwr;
	public String sales_deadline_passed; //no mapping found
	public String part_time_ees_eligible;
	public String owners_not_on_qwr;
	public String others_not_on_qwr;
	public String secretary_of_state_registration_status; //SOS_Registration__c TTF
	public String full_two_percent_shareholder_contributions_enabled; //X100_contributions_for_2_SHs__c TTF
	public String has_affiliates; //Do_they_have_affiliates__c TTF
	public String owner_names_and_percent_ownership; //LIst_of_Owner_names_and_the_percentage_s__c TTF
	public String two_percent_shareholders; //X2_shareholder_names__c
	public String subject_to_federal_or_state_cobra; //Subject_to_Federal_COBRA__c TTF
	public String continuation_of_coverage_set_up_in_hippo;
	public String basic_setup_required; //Basic_Action_Required__c
	public String has_non_owner_non_spouse_w2_ee;
	public String billing_setup_complete; //Automatic_billing_set_up__c ?need confirmation Y/N field
	public String tada_setup_complete; //no mapping
	public String baa_poa_signatory_name_and_title; //Signatory_Name__c
	public String names_of_ees_in_waiting_period; //EEs_in_WP__c
	public String waiving_initial_waiting_period; //Waiving_initial_WP__c
	//public String baa_poa_signed;//BAA_signed__c TTF
	public String wc_carrier_name;
	public String owners_not_covered_by_wc;
	public List<String> oe_blockers; //Other_OE_Blocker__c TTF
	public String group_ready_for_oe; //Is_the_group_ready_for_OE__c TTF
	public String ownership_docs_match_expected_owners; //no mapp
	public String ownership_discrepancy_details; //no mapping
	public String benefits_address_details_match_provided_documentation; //no mapping found
	public String address_mismatch_notes;
	public String bank_details_match_bank_verification_documents; //no mapping found
	public String bank_detail_notes; //no mapping found
	public String signatory_mismatch; //Signatory_mismatch__c TTF
	public String signatory_mismatch_notes; //Signatory_Name__c TTF
	public Date date_new_hire_payroll_ready; //QA190 -no mapping
	public Date date_group_payroll_ready; //Gusto_payroll_start_date__c TTF
	public String manual_oe_required; //Is_Manual_OE_required__c
	public String owner_percent_need_to_be_collected; // no mapping
	public String tada_owner_eligibility; //TAdA_Owner_Eligibility__c TTF
	public list<SuccessorsPredecessorsWrapper> plan_successors_predecessors; //Successor_predecessor_plan_codes_and_nam__c TTF
	public String any_group_level_changes_submitted; //TTIA Were_any_group_level_changes_already_sub__c
	public String continuation_subscriptions; //TTIA Continuation_Subscriptions__c
	public Date registration_date;
	public Date date_of_first_hired_ee; //no mapping found or no refrence excel sheet
	public Date date_business_established; //found in TTF*/
	public List<Date> scheduled_payroll_run_dates;
	public AddressWrapper benefit_address;
	public AddressWrapper filing_address;
	public List<QALineOfCoverageWrapper> qual_loc_data;
	public String industry;
	public Boolean has_prior_coverage;
	public String peo_switcher;
	public Boolean submit_for_special_enrollment;
	public Boolean address_change_to_be_made_by_submission;
	public Boolean has_rating_structure_change;
	public Boolean terminating_hsa;
	public Boolean alignment_to_be_requested_by_submission;
	public List<String> types_of_new_tadas;
	public List<String> types_of_renewing_tadas;
	public Boolean composite_rated;
	public class AddressWrapper {
		public String city;
		public String state;
		public String county_name;
		public String country;
		public String street_1;
		public String street_2;
		public String zip;
	}

    public class SuccessorsPredecessorsWrapper{
        public string predecessor_policy_name;
        public string successor_plan_name;
    }
    
    public class QALineOfCoverageWrapper{
        public String owner_names_and_percent_ownership;
        public Integer state_carrier_id;
        public String benefit_type;
        public String verified_rates;
        public String renewal_type; // Renewal_Type__c
        public String risk_of_not_meeting_participation;//no map
        public String documents_required_for_submission;
        public String can_offer_both_carriers_selected;//no map
        public String enough_non_owner_ees_eligible_for_coverage;//nomap
        public String meet_affiliate_requirements;//no map
        public String located_in_area_carrier_allows;//no map
        public String have_enough_in_state_ees;//no map
        public String select_plan_network_available_to_each_ee;//no map
        public String plan_available_and_set_up_for_hawaii_ees;//no map
        public String carrier_consider_group_to_be_startup;//no map
        public String been_in_business_long_enough;//no map
        public String part_time_ees_eligible_for_carrier;//no map
        public String will_meet_carrier_size_requirements_at_submission;//no map
        public String contribution_scheme_meet_carrier_requirements;
        public String contribution_changes_meet_carrier_requirements;
        public String offering_more_plans_than_potential_num_of_enrollees;//no map
        public String can_offer_all_plans_selected;//no map
        public String can_selected_networks_be_offered_together;//no map
        public String can_selected_plan_tiers_be_offered_together;//no map
        public String has_termination_policy_been_set;
        public Boolean is_early_submission_required;
        public String can_selected_packages_be_offered_together;//no map
        public String meet_class_based_requirements;//no map
        public String have_class_based_contributions;//no map
        public String meet_peo_switcher_requirements;//no map
        public String waiting_period_match_carrier_requirements;
        public String quoting_scheme_correct_for_each_policy;//Should_policy_year_be_anything__c
        public String rater_required_for_submission;// no map Documents_Require_for_Submission__c
        public String non_owner_must_enroll;
        public List<CompanyDocWrapper> documents_required_oa;
        public Boolean carrier_switch;
        public Boolean waiting_period_change;
        public Boolean new_line_of_coverage;
        public PlanDescription plan_description;
        public String contribution_description;
        public String waiting_period_description;
        public Boolean plan_change;
        public Boolean contribution_change;
        public Boolean alignment_to_be_requested_by_submission;
    }

    public class CompanyDocWrapper{
        public String document;
        public String option;
    }

    public class PlanDescription{
        public String[] plan_additions;
        public String[] plan_removals;
        public String[] plan_renewals;
    }
}