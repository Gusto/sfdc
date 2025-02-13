/**
 * @name         SelectionsSubmittedEventJSON
 * @author       Neha Dabas
 * @date         11th December 2020
 * @description  JSON Structure for Selection Submitted Event(Enrollment Refactor).
 * @test class
 * @revisions    Date ------------ Name ------------ Comments
 */
public with sharing class HISelectionsSubmittedEventJSON {
	public String created_at;
	public String error_message;
	public SelectionInfo[] selections;
	public HIEnrollmentEventUtility.EnrollmentSourceInfo enrollment_source;
	public HIEnrollmentEventUtility.EmployeeInfo employee;
	public HIEnrollmentEventUtility.CompanyInfo company;
	public StateCarrierInfo[] state_carriers;
	public PolicyInfo[] policies;
	public HIEnrollmentEventUtility.DependentInfo[] dependents;
	public FormInfo[] forms;
	public String[] answers;

	public class SelectionInfo {
		public String uuid;
		public String url;
		public String status;
		public EnrollmentInfo enrollment_information;
		public Double estimated_total_premium;
		public Double estimated_employee_premium;
		public Double estimated_dependents_premium;
		public String start_date;
		public String end_date;
		public String ops_owner;
		public OverlapingSubscriptionInfo overlapping_subscription;
	}

	public class EnrollmentInfo {
		public String policy_id;
		public String[] dependent_ids;
		public Long state_carrier_id;
	}

	public class OverlapingSubscriptionInfo {
		public String policy_id;
		public Long state_carrier_id;
	}

	public class StateCarrierInfo {
		public Long id;
		public String name;
		public String key;
		public String carrier_enrollment_url;
		public String state;
		public Boolean byb_automation_authorized;
	}

	public class PolicyInfo {
		public String id;
		public String name;
		public String benefit_type;
		public String group_number;
		public String policy_number;
		public String url;
	}

	public class FormInfo {
		public Long id;
		public Boolean form_includes_all_dependents;
		public Boolean fully_mapped;
		public String[] missing_values_by_path;
		public String name;
		public String signed_at;
		public Long state_carrier_id;
		public String url;
	}
}