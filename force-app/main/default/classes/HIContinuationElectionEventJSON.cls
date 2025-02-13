/**
 * @name         HIContinuationElectionEventJSON
 * @author       Bhagat Singh
 * @date         31st March 2021
 * @description  JSON Structure for Continuation Election Event(Enrollment Refactor).
 * @test class
 * @revisions    Date ------------ Name ------------ Comments
 */
public with sharing class HIContinuationElectionEventJSON {
	public SubscriptionsInfo[] continuation_subscriptions;
	public HIEnrollmentEventUtility.EmployeeInfo employee;
	public HIEnrollmentEventUtility.CompanyInfo company;
	public StateCarrierInfo[] state_carriers;
	public PolicyInfo[] policies;
	public HIEnrollmentEventUtility.DependentInfo[] dependents;
	public FormInfo[] forms;

	public class SubscriptionsInfo {
		public String url;
		public EnrollmentInfo enrollment_information;
		public Double estimated_total_premium;
		public Double estimated_employee_premium;
		public Double estimated_dependents_premium;
		public String start_date;
		public String end_date;
	}

	public class EnrollmentInfo {
		public String policy_id;
		public String[] dependent_ids;
		public Long state_carrier_id;
		public Boolean employee_enrolled;
	}

	public class StateCarrierInfo {
		public Long id;
		public String name;
		public String key;
		public String state;
	}

	public class PolicyInfo {
		public String id;
		public String name;
		public String benefit_type;
		public String group_number;
		public String policy_number;
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