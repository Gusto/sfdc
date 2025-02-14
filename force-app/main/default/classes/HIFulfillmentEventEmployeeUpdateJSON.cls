public class HIFulfillmentEventEmployeeUpdateJSON {
	public updates[] updates;
	public String updated_at;
	public employee employee;
	public company company;
	public state_carrier[] state_carriers;
	public member_level_event[] member_level_events;

	public benefit_item[] benefit_items;
	public policy[] policies;
	public String sent_at;
	public String benefits_url; //http://localhost:4001/companies/7757616923569265/employees/7757869431500092/subscriptions
	public alegeus_benefit_type alegeus;
	public cls_forms[] forms;
	public String error_message;

	public HIFulfillmentEventEmployeeUpdateJSON() {
	}

	public class alegeus_benefit_type {
		public alegeus_info fsa;
		public alegeus_info dca;
		public alegeus_info hsa;
	}

	public class alegeus_info {
		public benefit_item[] benefit_items;
		public policy[] policies;
	}

	public class updates {
		public String type; //bank_account
		public update_info previous;
		public update_info current;
	}

	public class update_info {
		public address home_address;
		public address filing_address;
		public address mailing_address;
		public bank_info bank_account;
		public String ssn;
		public String first_name;
		public String last_name;
		public String birthday;
		public String hired_at;
		public String two_percent_shareholder;
		public String flsa_status;
		public String extrapolated_annual_salary;
	}

	public class bank_info {
		public String account_type; //Checking
		public String bank_name; //WELLS FARGO BANK NA
		public boolean account_or_routing_number_changed;
		public String bank_account_last_four; //3485
		public Long zp_event_id; //8
	}

	public class employee {
		public Long id; //7757869431500092
		public String first_name; //General
		public String last_name; //Keebler
		public String middle_initial; //
		public String status; //Active
		public String ssn; //123456789
		public String birthday; //1975-05-21
		public Long company_id; //7757616923569265
		public String hired_at; //2016-01-01
		public String employment_status; //full_time
		public home_address home_address;
		public address work_address;
		public String email; //isadore_conroy7757869448777567@bergnaum.co
		public String gender; //male
		public String panda_url; //http://manage.zenpayroll.dev:3000/companies/7757616923569265/employees/7757869431500092
		public String hippo_url; //http://localhost:4001/companies/7757616923569265/employees/7757869431500092
	}

	public class home_address {
		public Long id; //7757727713476955
		public String street_1; //479 Becker Rue
		public String street_2; //Suite 641
		public String city; //Piedmont
		public String county_name; //Alameda
		public String state; //CA
		public String zip; //94610
		public String country; //USA
		public String phone;
		public String created_at; //2016-07-06T15:39:52.000-07:00
		public String updated_at; //2017-01-22T08:00:56.000-08:00
		public String fax;
		public boolean inactive;
		public boolean work_address;
	}

	public class address {
		public Long id; //7757727713288244
		public String street_1; //4841 Darrick Valleys
		public String street_2; //Suite 937
		public String city; //Oakland
		public String county_name; //Alameda
		public String state; //CA
		public String zip; //94607
		public String country; //USA
		public String phone; //8824115401
		public String created_at; //2016-02-24T13:45:05.000-08:00
		public String updated_at; //2017-04-04T08:53:14.000-07:00
		public String fax; //4833286754
		public boolean inactive;
		public boolean work_address;
		public Integer employee_count; //7
	}

	public class company {
		public Long id; //7757616923569265
		public String name; //Crooks Group
		public String email; //isadore_conroy7757869448777567@bergnaum.co
		public String salesforce_account_id;
		public String[] work_states;
		public String sic_code; //7373
		public address mailing_address;
		public address filing_address;
		public address benefits_address;
		public Integer number_of_eligible_ees; //5
		public Integer number_of_ineligible_ees; //1
		public boolean has_federal_cobra;
		public boolean is_suspended;
		public String panda_url; //http://manage.zenpayroll.dev:3000/companies/7757616923569265
		public String hippo_url; //http://localhost:4001/companies/7757616923569265
	}

	public class cls_forms {
		public Long id; //2929
		public String name; //name
		public String url; //url
		public string signed_at;
		public string encoded_form_data;
		public Long state_carrier_id;
		public Boolean fully_mapped;
		public String[] missing_values_by_path;
		public Boolean form_includes_all_dependents;
	}

	public class state_carrier {
		public Integer id; //22
		public String name; //Guardian
		public String state; //CA
		public String key; //guardian_ca
		public String url; //http://localhost:4001/national_carriers/24/state_carriers/22
		public boolean byb_automation_authorized;
	}

	public class member_level_event {
		public String uuid;
		public Long carrier_id;
		public String carrier_state;
		public String carrier_key;
	}

	public class benefit_item {
		public Integer id; //21225
		public Integer policy_id; //6135
		public String benefit_type; //life
		public String start_date; //2016-09-01
		public String end_date; //2017-08-31
		public boolean processed;
		public Integer enrollment_id;
		public Long employee_id; //7757869431500092
		public Integer[] dependent_ids;
		public Integer state_carrier_id; //22
		public String url; //http://localhost:4001/companies/7757616923569265/employees/7757869431500092/subscriptions/21225
	}

	public class policy {
		public Integer id; //6135
		public String name; //Guardian EM Life 1F
		public String benefit_type; //life
		public String group_number; //G-00530411
		public String policy_number;
		public Integer plan_id; //1381
		public boolean visible;
		public String termination_policy; //last_day_of_month_on_or_after_termination
		public Integer state_carrier_id; //22
		public String url; //http://localhost:4001/companies/7757616923569265/policies/6135
	}
}