global class HIFulfillmentBotResponseJSON {
	public control_info control_info;
	public String losing_benefits_date; //2017-06-22
	public String losing_benefits_reason; //Termination
	public enrollment enrollment;
	public List<RecentQle> recent_qles;
	public String carrier_directory; //https://confluence.gustocorp.com/pages/viewpage.action?pageId=28803132
	public employee employee;
	public company company;
	public state_carrier state_carrier;
	public benefit_items benefit_items;
	public terminated_benefit_items[] terminated_benefit_items;
	public related_benefit_items[] related_benefit_items;
	public Policy[] policies;
	public List<Dependent> dependents;
	public member_update[] member_updates;
	public String benefits_url; //https://hippo.gusto.com/companies/8888888888888888/employees/7777777777777777/benefits
	public String enrollments_url; //https://hippo.gusto.com/companies/8888888888888888/employees/7777777777777777/enrollments
	public String member_level_event_uuids;

	public class control_info {
		public String case_id; //https://hippo.gusto.com/companies/8888888888888888/employees/7777777777777777/enrollments/426809
		public date created_date;
	}

	public class enrollment {
		public Long id; //999999999
		public Long employee_id; //7777777777777777
		public String url; //https://hippo.gusto.com/companies/8888888888888888/employees/7777777777777777/enrollments/426809
	}

	public class member_update {
		public String type; //bank_account
		public member_update_info member_update_info;
	}

	public class member_update_info {
		public work_address home_address;
		public work_address filing_address;
		public work_address mailing_address;
		public bank_info bank_account;
		public String ssn;
		public String first_name;
		public String last_name;
		public String birthday;
		public String hired_at;
		public String two_percent_shareholder;
		public String flsa_status;
	}

	public class bank_info {
		public String account_type; //Checking
		public String bank_name; //WELLS FARGO BANK NA
		public boolean account_or_routing_number_changed;
		public String bank_account_last_four; //3485
		public Long zp_event_id; //8
	}

	public class RecentQle {
		public Long id;
		public string event;
		public string date_of_event;
		public List<string> file_upload_urls;
		public string url;
	}

	public class employee {
		public Long id; //7777777777777777
		public String first_name; //Ron
		public String last_name; //James
		public String middle_initial; //A
		public String status; //Active
		public String ssn; //222222222
		public String birthday; //1991-03-07
		public Long company_id; //8888888888888888
		public String hired_at; //2019-05-06
		public String employment_status; //full_time
		public home_address home_address;
		public work_address work_address;
		public String email; //Ron.james@ronjamestest.com
		public String gender; //male
		public string annual_salary;
		public string benefits_eligibility_date;
		public String panda_url; //https://app.gusto.com/panda/companies/8888888888888888/employees/7777777777777777
		public String hippo_url; //https://hippo.gusto.com/companies/8888888888888888/employees/7777777777777777
	}

	public class home_address {
		public Long id; //7757869433017999
		public String fax;
		public String zip; //94582
		public String city; //San Ramon
		public String phone;
		public String state; //CA
		public String country; //USA
		public boolean inactive;
		public String street_1; //2222 Tahiti Ct
		public String street_2; //
		public String created_at; //2019-04-03T02:18:17.000-07:00
		public String updated_at; //2019-04-03T02:25:16.000-07:00
		public String county_name; //Contra Costa
		public boolean work_address;
	}

	public class work_address {
		public Long id; //7757869433017999
		public String fax;
		public String zip; //94582
		public String city; //San Ramon
		public String phone;
		public String state; //CA
		public String country; //USA
		public boolean inactive;
		public String street_1; //2222 Tahiti Ct
		public String street_2; //
		public String created_at; //2019-04-02T18:55:46.000-07:00
		public String updated_at; //2019-04-02T18:55:46.000-07:00
		public String county_name; //Contra Costa
		public boolean work_address;
		public Integer employee_count; //1
	}

	public class company {
		public Long id; //8888888888888888
		public String name; //ABC, Inc
		public String email; //abc.test@ronjamestest.com
		public String phone; //@BS 11 Jan 2021 .In case of "selections_submitted" request phone number is required
		public String salesforce_account_id; //001160000112121234
		public String[] work_states;
		public String sic_code; //7379
		public mailing_address mailing_address;
		public filing_address filing_address;
		public benefits_address benefits_address;
		public Integer number_of_eligible_ees; //58
		public Integer number_of_ineligible_ees; //10
		public boolean has_federal_cobra;
		public boolean is_suspended;
		public String panda_url; //https://app.gusto.com/panda/companies/8888888888888888
		public String hippo_url; //https://hippo.gusto.com/companies/8888888888888888
	}

	public class mailing_address {
		public Long id; //7757869433017999
		public String fax;
		public String zip; //94582
		public String city; //San Ramon
		public String phone;
		public String state; //CA
		public String country; //USA
		public boolean inactive;
		public String street_1; //2222 Tahiti Ct
		public String street_2; //
		public String created_at; //2019-04-02T18:55:46.000-07:00
		public String updated_at; //2019-04-02T18:55:46.000-07:00
		public String county_name; //Contra Costa
		public boolean work_address;
		public Integer employee_count; //19
	}

	public class filing_address {
		public Long id; //7757869433017999
		public String fax;
		public String zip; //94582
		public String city; //San Ramon
		public String phone;
		public String state; //CA
		public String country; //USA
		public boolean inactive;
		public String street_1; //2222 Tahiti Ct
		public String street_2; //
		public String created_at; //2019-04-02T18:55:46.000-07:00
		public String updated_at; //2019-04-02T18:55:46.000-07:00
		public String county_name; //Contra Costa
		public boolean work_address;
		public Integer employee_count; //19
	}

	public class benefits_address {
		public Long id; //7757869433017999
		public String fax;
		public String zip; //94582
		public String city; //San Ramon
		public String phone;
		public String state; //CA
		public String country; //USA
		public boolean inactive;
		public String street_1; //2222 Tahiti Ct
		public String street_2; //
		public String created_at; //2019-04-02T18:55:46.000-07:00
		public String updated_at; //2019-04-02T18:55:46.000-07:00
		public String county_name; //Contra Costa
		public boolean work_address;
		public Integer employee_count; //19
	}

	public class state_carrier {
		public Long id; //246
		public String name; //UnitedHealthcare
		public String state; //MA
		public String key; //united_healthcare_ma
		public String url; //https://hippo.gusto.com/national_carriers/60/state_carriers/246
		public String carrier_enrollment_url; //https://hippo.gusto.com/companies/8888888888888888/employees/7777777777777777/enrollments/426809/united_healthcare_ma
		public String signed_at;
	}

	public class benefit_items {
		public SubscriptionInfo medical;
		public SubscriptionInfo dental;
		public SubscriptionInfo vision;
		public SubscriptionInfo life;
		public SubscriptionInfo long_term_disability;
		public SubscriptionInfo short_term_disability;
		public SubscriptionInfo voluntary_short_term_disability;
		public SubscriptionInfo voluntary_long_term_disability;
		public SubscriptionInfo voluntary_life;
	}

	public class SubscriptionInfo {
		public String id; // changed from Integer to String @Bhagat, Jan 11, 2021. Required for "enrollment_ready_for_processing"
		public String policy_id; // changed from Integer to String @Bhagat, Jan 6, 2021
		public String benefit_type; //medical
		public String processing_status; //not_started
		public Date start_date;
		public Date end_date;
		public Integer enrollment_id; //426809
		public Long employee_id; //7777777777777777
		public String[] dependent_ids;
		public Integer state_carrier_id; //246
		public String url; //https://hippo.gusto.com/companies/8888888888888888/employees/7777777777777777/selections/968532
		public String estimated_start_date; //2019-06-01
		public Double estimated_total_premium; //951.6
		public Double estimated_employee_premium; //475.8
		public Double estimated_dependents_premium; //475.8
		public Double guaranteed_issue;
		public Double voluntary_benefit_amount;
		public Double total_benefit_amount;
		public String ops_owner; //member_fulfillment
	}

	public class terminated_benefit_items {
		public Long id; //72582
		public Long policy_id;
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

	public class related_benefit_items {
		public Long id; //72582
		public Long policy_id;
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

	public class Policy {
		public String id; //[BS: 30 Dec 2020 - 16e1d2db-ad5e-4fe1-9b60-930bd6e256a0]
		public String name; //Choice Plus 30/1750/100% Gold AT1R w/I8 (pkg 10/11) [MA-CS-2018]
		public String benefit_type; //medical
		public string group_number;
		public string policy_number;
		public Integer plan_id; //12921
		public boolean visible;
		public String termination_policy; //last_day_of_month_on_or_after_termination
		public Integer state_carrier_id; //246
		public String url; //https://hippo.gusto.com/companies/8888888888888888/policies/70436
	}

	public class Dependent {
		public String id; //[BS: 30 Dec 2020 - 16e1d2db-ad5e-4fe1-9b60-930bd6e256a0]
		public String first_name; //Jenna
		public String last_name; //McKenzie
		public String ssn; //777777777
		public String birthday; //19984-01-11
		public String gender; //female
		public String dependent_type; //spouse
		public Long employee_id; //7777777777777777
		public String url; //https://hippo.gusto.com/companies/8888888888888888/employees/7777777777777777/dependents/107172
	}
}