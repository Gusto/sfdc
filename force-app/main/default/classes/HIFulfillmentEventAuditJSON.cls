/**
 * @name         HIFulfillmentEventAuditJSON
 * @author
 * @date         15th December 2020
 * @description
 * @test class
 * @revisions    Date ------------ Name ------------ Comments
 * 			02/28/2023		   Anurag Gautam
 */

public class HIFulfillmentEventAuditJSON {
	public String audit_type;
	public String subject;
	public date deadline_date;
	public item[] items;
	public String instructions;
	public company company;
	public employee employee;
	public state_carriers[] state_carriers;
	public benefit_items[] benefit_items;
	public policies[] policies;
	public dependents[] dependents;
	public forms[] forms;
	public String benefits_url;
	public String dependents_url;
	public benefits_status_periods[] source_benefits_status_periods;
	public benefits_status_periods[] target_benefits_status_periods;
	public String ops_owner;

	public HIFulfillmentEventAuditJSON() {
	}

	public class item {
		public Long id;
		public String uuid;
		public Integer policy_id;
		public String policy_uuid;
		public String benefit_type;
		public String start_date;
		public String end_date;
		public boolean processed;
		public Integer enrollment_id;
		public Long employee_id;
		public Integer[] dependent_ids;
		public Integer state_carrier_id;
		public String url;
		public String type;
	}

	public class company {
		public Long id;
		public String name;
		public String email;
		public String salesforce_account_id;
		public String[] work_states;
		public String sic_code;
		public work_address mailing_address;
		public work_address filing_address;
		public work_address benefits_address;
		public Integer number_of_eligible_ees;
		public Integer number_of_ineligible_ees;
		public boolean has_federal_cobra;
		public boolean is_suspended;
		public String panda_url;
		public String hippo_url;
		public String reconciliation_url;
	}

	public class employee {
		public Long id;
		public String first_name;
		public String last_name;
		public String middle_initial;
		public String status;
		public String ssn;
		public String birthday;
		public Long company_id;
		public String hired_at;
		public String employment_status;
		public home_address home_address;
		public work_address work_address;
		public String email;
		public String gender;
		public String panda_url;
		public String hippo_url;
	}

	public class home_address {
		public Long id;
		public String street_1;
		public String street_2;
		public String city;
		public String county_name;
		public String state;
		public String zip;
		public String country;
		public String phone;
		public String created_at;
		public String updated_at;
		public String fax;
		public boolean inactive;
		public boolean work_address;
	}

	public class work_address {
		public Long id;
		public String street_1;
		public String street_2;
		public String city;
		public String county_name;
		public String state;
		public String zip;
		public String country;
		public String phone;
		public String created_at;
		public String updated_at;
		public String fax;
		public boolean inactive;
		public boolean work_address;
		public Integer employee_count;
	}

	public class state_carriers {
		public Long id;
		public String name;
		public String state;
		public String key;
		public String url;
		public Long[] forms;
	}

	public class forms {
		public Long id;
		public String name;
		public String url;
		public string signed_at;
		public string encoded_form_data;
	}

	public class benefit_items {
		public Long id;
		public Long policy_id;
		public String benefit_type;
		public String start_date;
		public String end_date;
		public boolean processed;
		public Integer enrollment_id;
		public Long employee_id;
		public Long[] dependent_ids;
		public Integer state_carrier_id;
		public String url;
		public Double total_premium;
	}

	public class dependent_ids {
		public Long id;
	}

	public class policies {
		public Integer id;
		public String name;
		public String benefit_type;
		public Long application_id;
		public String application_type;
		public String group_number;
		public String policy_number;
		public Integer plan_id;
		public boolean visible;
		public String termination_policy;
		public Integer state_carrier_id;
		public String url;
	}

	public class dependents {
		public Long id;
		public String first_name;
		public String last_name;
		public String ssn;
		public String birthday;
		public String gender;
		public String dependent_type;
		public Long employee_id;
		public String url;
	}

	public class benefits_status_periods {
		public Long id;
		public Long employee_id;
		public Long employment_id;
		public String employment_event;
		public String benefits_status;
		public String start_date;
	}
}