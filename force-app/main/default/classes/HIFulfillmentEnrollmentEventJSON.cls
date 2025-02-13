/*
This JSON is for type enrollment_ready_for_processing
*/
public class HIFulfillmentEnrollmentEventJSON {
	public String error_message;
	public Enrollment enrollment;
	public List<RecentQle> recent_qles;
	public String enrollment_source;
	public string carrier_directory;
	public Employee employee;
	public Company company;
	public List<StateCarrier> state_carriers;
	public Subscriptions benefit_items;
	public List<Policy> policies;
	public List<Dependent> dependents;
	public List<Form> forms;
	public List<Answer> answers;
	public cls_alegeus alegeus;
	public string benefits_url;
	public string enrollments_url;

	public HIFulfillmentEnrollmentEventJSON() {
	}

	public class Enrollment {
		public Long id;
		public Long employee_id;
		public string url;
	}

	public class RecentQle {
		public Long id;
		public string event;
		public string date_of_event;
		public List<string> file_upload_urls;
		public string url;
	}

	public class HomeAddress {
		public long id;
		public string street_1;
		public string street_2;
		public string city;
		public string county_name;
		public string state;
		public string zip;
		public string country;
		public string phone;
		public string created_at;
		public string updated_at;
		public string fax;
		public Boolean inactive;
		public Boolean work_address;
	}

	public class Employee {
		public long id;
		public string first_name;
		public string last_name;
		public string middle_initial;
		public string status;
		public string ssn;
		public string birthday;
		public long company_id;
		public string hired_at;
		public string employment_status;
		public HomeAddress home_address;
		public Address work_address;
		public string email;
		public string gender;
		public string annual_salary;
		public string benefits_eligibility_date;
		public string panda_url;
		public string hippo_url;
	}

	public class Address {
		public long id;
		public string street_1;
		public string street_2;
		public string city;
		public string county_name;
		public string state;
		public string zip;
		public string country;
		public string phone;
		public string created_at;
		public string updated_at;
		public string fax;
		public Boolean inactive;
		public Boolean work_address;
		public Integer employee_count;
	}

	public class Company {
		public long id;
		public string name;
		public string email;
		public String salesforce_account_id;
		public List<string> work_states;
		public string sic_code;
		public Address mailing_address;
		public Address filing_address;
		public Address benefits_address;
		public Integer number_of_eligible_ees;
		public Integer number_of_ineligible_ees;
		public Boolean has_federal_cobra;
		public Boolean is_suspended;
		public string panda_url;
		public string hippo_url;
	}

	public class StateCarrier {
		public Long id;
		public string name;
		public string state;
		public string key;
		public string url;
		public string carrier_enrollment_url;
		public List<Long> forms;
	}

	public class DependentId {
		public Long id;
	}

	public class SubscriptionInfo {
		public Long id;
		public Long policy_id;
		public string benefit_type;
		public String start_date;
		public String end_date;
		public Boolean processed;
		public Long enrollment_id;
		public long employee_id;
		public List<Long> dependent_ids;
		public Long state_carrier_id;
		public string url;
		public string estimated_start_date;
		public double estimated_total_premium;
		public double estimated_employee_premium;
		public double estimated_dependents_premium;
		public Double guaranteed_issue;
		public Double voluntary_benefit_amount;
		public Double total_benefit_amount;
		//public Boolean first_time_offered;
		public string ops_owner;
		public String uuid; // @Neha Jan 6,2021 : To consume uuid sent by Eng.
	}

	public class ABHPSubscription {
		public CarrierTypeSubscription benefit_items;
		public Policy[] policies;
	}

	public class CarrierTypeSubscription {
		public SubscriptionInfo current; // to be used as new instead varNew
		public List<SubscriptionInfo> overlapping;
		public List<SubscriptionInfo> previous;
	}

	public class Subscriptions {
		public CarrierTypeSubscription medical;
		public CarrierTypeSubscription dental;
		public CarrierTypeSubscription vision;
		public CarrierTypeSubscription life;
		public CarrierTypeSubscription long_term_disability;
		public CarrierTypeSubscription short_term_disability;
		public CarrierTypeSubscription voluntary_short_term_disability;
		public CarrierTypeSubscription voluntary_long_term_disability;
		public CarrierTypeSubscription voluntary_life;
	}

	public class Policy {
		public Long id;
		public string name;
		public string benefit_type;
		public string group_number;
		public string policy_number;
		public Long plan_id;
		public Boolean visible;
		public string termination_policy;
		public Long state_carrier_id;
		public string url;
	}

	public class Dependent {
		public Long id;
		public string first_name;
		public string last_name;
		public string ssn;
		public string birthday;
		public string gender;
		public string dependent_type;
		public long employee_id;
		public string url;
	}

	public class Form {
		public Long id;
		public string name;
		public string signed_at;
		public string url;
		public string encoded_form_data;
		public Long state_carrier_id;
		public Boolean fully_mapped;
		public String[] missing_values_by_path;
		public Boolean form_includes_all_dependents;
	}

	public class Data {
		public string value;
	}

	public class Answer {
		public Long id;
		public Long dependent_id;
		public string question_key;
		public Data data;
		public Long enrollment_id;
		public string carrier_key;
		public string created_at;
		public string updated_at;
	}

	public class cls_alegeus {
		public ABHPSubscription dca;
		public ABHPSubscription fsa;
		public cls_hsa hsa;
	}

	public class cls_hsa {
		public cls_hsa_benefit hsa_benefit;
		public cls_hsa_selection hsa_selection;
	}

	public class cls_hsa_benefit {
		public Long id; //1
		public Long company_id; //742157482339
		public String effective_date; //Mon, 31 Jul 2017
		public String expiration_date; //Tue, 31 Jul 2018
		public String status; //visible
		public String url; //https://hippo.zentest.com/companies/742157482339/policies
	}
	public class cls_hsa_selection {
		public Long id; //1
		public Long employee_id; //1
		public Long hsa_benefit_id; //1
		public String start_date;
		public String max_contribution_cents; //10000
		public String url; //https://hippo.zentest.com/companies/742157482339/employees/1/hsa_subscriptions/1
	}
}