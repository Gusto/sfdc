public class HIFulfillmentTerminationEvenJSON {
	public String benefits_eligibility_end_date; //2017-06-22
	public String losing_benefits_reason; //Termination
	public String carrier_directory; //https://confluence.gustocorp.com/pages/viewpage.action?pageId=28803132
	public cls_employee employee;
	public cls_company company;
	public cls_state_carriers[] state_carriers;
	public cls_benefit_items[] benefit_items;
	public cls_policies[] policies;
	public cls_dependents[] dependents;
	public cls_forms[] forms;
	public cls_tada tada;
	public cls_commuter_benefit commuter_benefit;
	public cls_commuter_employee_benefit commuter_employee_benefit;
	public String sent_at;
	public String benefits_url; //http://localhost:4001/companies/7757616923505614/employees/7757869431696318/subscriptions
	public String dependents_url; //http://localhost:4001/companies/7757616923505614/employees/7757869431696318/dependents

	public class cls_employee {
		public Long id; //7757869431696318
		public String first_name; //Ethan
		public String last_name; //Fritsch
		public String middle_initial; //B
		public String status; //Terminated
		public Long ssn; //123456789
		public String birthday; //1992-01-25
		public Long company_id; //7757616923505614
		public String hired_at; //2017-03-20
		public String employment_status; //full_time
		public cls_home_address home_address;
		public cls_address work_address;
		public String email; //blanca.sipes7757869449148235@ziemecummerata.net
		public String gender; //male
		public String panda_url; //http://manage.zenpayroll.dev:3000/companies/7757616923505614/employees/7757869431696318
		public String hippo_url; //http://localhost:4001/companies/7757616923505614/employees/7757869431696318
		public String payroll_type; //Exempt
	}

	public class cls_address {
		public Long id; //7757727713844547
		public String street_1; //45218 Deangelo Glens
		public String street_2; //Suite 683
		public String city; //Cambridge
		public String county_name; //Middlesex
		public String state; //MA
		public String zip; //02141
		public String country; //USA
		public String phone;
		public String created_at; //2017-03-20T06:41:28.000-07:00
		public String updated_at; //2017-03-20T06:41:28.000-07:00
		public String fax;
		public boolean inactive;
		public boolean work_address;
		public Integer employee_count; //0
	}

	public class cls_home_address {
		public Long id; //7757727712904980
		public String street_1; //660 Flavie Circle
		public String street_2; //Apt. 340
		public String city; //Cambridge
		public String county_name; //Middlesex
		public String state; //MA
		public String zip; //02141
		public String country; //USA
		public String phone; //9590115024
		public String created_at; //2015-04-21T07:10:17.000-07:00
		public String updated_at; //2017-01-02T00:13:08.000-08:00
		public String fax; //2697601503
		public boolean inactive;
		public boolean work_address;
	}

	public class cls_company {
		public Long id; //7757616923505614
		public String name; //Spinka-Waelchi
		public String email; //broderick7757869448502232@mann.co
		public String salesforce_account_id;
		public List<String> work_states;
		public String sic_code; //7372
		public cls_address mailing_address;
		public cls_address filing_address;
		public cls_address benefits_address;
		public Integer number_of_eligible_ees; //4
		public Integer number_of_ineligible_ees; //0
		public Boolean has_federal_cobra;
		public Boolean is_suspended;
		public String panda_url; //http://manage.zenpayroll.dev:3000/companies/7757616923505614
		public String hippo_url; //http://localhost:4001/companies/7757616923505614
	}

	public class cls_work_states {
		public String state;
	}

	public class cls_commuter_benefit {
		public Long id; //3
		public Long company_id; //1408063107892611
		public String status; //processed
		public String start_date; //2017-09-01
		public String end_date;
		public boolean upcoming;
		public boolean active;
		public boolean expired;
		public String waiting_period; //first_of_month_following_hire
		public cls_company_contribution_inputs company_contribution_inputs;
		public String url; //https://hippo.gusto.com/companies/1408063107892611/commuter_benefits/3
		public string provider_key;
	}

	public class cls_company_contribution_inputs {
		public String type; //fixed_amount
		public String parking_contribution_amount; //0
		public String transit_contribution_amount; //255
	}

	public class cls_commuter_employee_benefit {
		public Long id; //4
		public Long employee_id; //7757869431686263
		public Long commuter_benefit_id; //3
		public String status; //processed
		public String start_date; //2017-09-01
		public String transit_monthly_election; //255.0
		public String transit_monthly_contribution; //255.0
		public String transit_monthly_deduction; //0.0
		public String parking_monthly_election; //0.0
		public String parking_monthly_contribution; //0.0
		public String parking_monthly_deduction; //0.0
		public String url; //https://hippo.gusto.com/companies/1408063107892611/employees/7757869431686263/commuter_employee_benefits/4
		public String commuter_benefit_url; //https://hippo.gusto.com/companies/1408063107892611/commuter_benefits/3
	}

	public class cls_state_carriers {
		public Long id; //234
		public String name; //Blue Cross Blue Shield
		public String state; //MA
		public String key; //bcbs_ma
		public String url; //http://localhost:4001/national_carriers/7/state_carriers/234
		public Long[] forms;
		public boolean byb_automation_authorized;
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

	public class cls_benefit_items {
		public Long id; //72582
		public Long policy_id;
		public String uuid;
		public String policy_uuid;
		public String coverage_end_date;
		public String benefit_type; //medical
		public String start_date; //2017-03-20
		public String end_date; //2017-09-24
		public boolean processed;
		public Integer enrollment_id; //34528
		public Long employee_id; //7757869431696318
		public Long[] dependent_ids;
		public Integer state_carrier_id; //234
		public String url; //http://localhost:4001/companies/7757616923505614/employees/7757869431696318/subscriptions/72582
		public Double total_premium; //469.29
	}

	public class cls_dependent_ids {
		public Long id;
	}

	public class cls_policies {
		public Integer id; //13628
		public String name; //HMO Blue New England $1000 Deductible
		public String benefit_type;
		public String group_number; //6913996
		public String policy_number;
		public Integer plan_id; //2937
		public boolean visible;
		public String termination_policy; //last_day_of_employment
		public Integer state_carrier_id;
		public String url; //http://localhost:4001/companies/7757616923505614/policies/13628
		public String provider_key;
	}

	public class cls_dependents {
		public Long id; //121212
		public String first_name; //first_name
		public String last_name; //last_name
		public String ssn; //ssn
		public String birthday; //2017-03-20
		public String gender; //gender
		public String dependent_type; //dependent_type
		public Long employee_id; //12012012
		public String url;
	}

	public class tada_subscription_info {
		public cls_benefit_items[] benefit_items;
		public cls_policies[] policies;
	}

	public class cls_tada {
		public tada_subscription_info dca;
		public tada_subscription_info fsa;
		public tada_subscription_info hsa;
	}
}