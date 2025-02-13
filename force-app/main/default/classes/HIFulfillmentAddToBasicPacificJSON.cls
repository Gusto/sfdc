public with sharing class HIFulfillmentAddToBasicPacificJSON {
	public cls_employee employee;
	public cls_company company;
	public cls_enrollees[] enrollees;
	public cls_subscriptions[] subscriptions;
	public String event_date; //Sat, 12 Jan 2019
	public String event_type; //Employee termination
	public static cls_mailing_address benefitsAddress;

	public class cls_employee {
		public string id; //7757869432367243
		public String first_name; //Tatum
		public String last_name; //Parisian
		public String middle_initial; //
		public String status; //Active
		public String ssn; //123456789
		public String birthday; //Mon, 01 Oct 1979
		public string company_id; //7757616923710601
		public String hired_at; //Sat, 31 Dec 2016
		public String employment_status; //full_time
		public cls_home_address home_address;
		public cls_home_address work_address;
		public String email; //xavierfisher@kulas.com
		public String gender; //male
		public String panda_url; //http://manage.gusto-dev.com:3000/companies/7757616923710601/employees/7757869432367243
		public String hippo_url; //http://localhost:4001/companies/7757616923710601/employees/7757869432367243
	}

	public class cls_home_address {
		public string id; //7757869432366169
		public String fax; //8931803228
		public String zip; //32259
		public String city; //Saint Johns
		public String phone; //7378235941
		public String state; //FL
		public String country; //USA
		public boolean inactive;
		public String street_1; //3981 Norbert Trace
		public String street_2; //Apt. 683
		public String created_at; //2018-10-01T16:56:03.000-07:00
		public String updated_at; //2018-10-01T16:56:03.000-07:00
		public String county_name; //Saint Johns
		public boolean work_address;
	}

	public class cls_company {
		public string id; //7757616923710601
		public String name; //Collins, Davis and Kuvalis
		public String email; //lawrencefahey@ondricka.com
		public string salesforce_account_id;
		public string[] work_states;
		public String sic_code; //2099
		public cls_mailing_address mailing_address;
		public cls_mailing_address filing_address;
		public cls_mailing_address benefits_address;
		public Integer number_of_eligible_ees; //88
		public Integer number_of_ineligible_ees; //0
		public boolean has_federal_cobra;
		public boolean is_suspended;
		public String panda_url; //http://manage.gusto-dev.com:3000/companies/7757616923710601
		public String hippo_url; //http://localhost:4001/companies/7757616923710601
		public string google_drive_folder_url;
	}

	public class cls_mailing_address {
		public string id; //7757869432365982
		public String fax; //5210952437
		public String zip; //90040
		public String city; //Commerce
		public String phone; //3511922856
		public String state; //CA
		public String country; //USA
		public boolean inactive;
		public String street_1; //7955 Rutherford Oval
		public String street_2; //Apt. 125
		public String created_at; //2018-10-01T16:18:19.000-07:00
		public String updated_at; //2018-10-01T16:18:19.000-07:00
		public String county_name; //Los Angeles
		public boolean work_address;
		public Integer employee_count; //80
	}

	public class cls_enrollees {
		public string id; //7757869432367243
		public String first_name; //Tatum
		public String last_name; //Parisian
		public string middle_initial;
		public String status; //Active
		public String ssn; //123456789
		public String birthday; //Mon, 01 Oct 1979
		public string company_id; //7757616923710601
		public String hired_at; //Sat, 31 Dec 2016
		public String employment_status; //full_time
		public cls_home_address home_address;
		public cls_home_address work_address;
		public String email; //xavierfisher@kulas.com
		public String gender; //male
		public string dependent_type;
		public String panda_url; //http://manage.gusto-dev.com:3000/companies/7757616923710601/employees/7757869432367243
		public String hippo_url; //http://localhost:4001/companies/7757616923710601/employees/7757869432367243
		public string employee_id;
		public string url;
	}

	public class cls_subscriptions {
		public string id; //478282
		public string policy_id; //88514
		public String benefit_type; //medical
		public String processing_status; //processed
		public String start_date; //Wed, 01 Aug 2018
		public String end_date; //Wed, 31 Jul 2019
		public string enrollment_id;
		public string employee_id; //7757869432367243
		public long[] dependent_ids;
		public string state_carrier_id; //25
		public String url; //http://localhost:4001/companies/7757616923710601/employees/7757869432367243/subscriptions/478282
	}
}