public class HIFulfillmentEOIFollowupJSON {
	public cls_selection selection;
	public cls_policy policy;
	public cls_employee employee;
	public cls_company company;
	public cls_state_carrier state_carrier;
	public cls_eoi_details eoi_details;
	public String benefits_url; //http://localhost:4001/companies/7757616923548552/employees/7757869432518714/benefits

	public class cls_selection {
		public Integer id; //781541
		public Integer policy_id; //85505
		public String processing_status; //processed
		public String start_date; //2019-01-22
		public String end_date; //2019-12-31
		public Integer enrollment_id; //368236
		public Long employee_id; //7757869432518714
		public Integer[] dependent_ids;
		public Integer state_carrier_id; //22
		public String url; //http://localhost:4001/companies/7757616923548552/employees/7757869432518714/selections/781541
		public String guaranteed_issue; //100000.0
		public String voluntary_benefit_amount; //100000.0
		public String total_benefit_amount; //100000.0
	}

	public class cls_policy {
		public Integer id; //85505
		public String name; //Guardian - Voluntary Life & AD&D - Sila Nanotechnologies
		public String benefit_type; //voluntary_life
		public String group_number; //70247800
		public String policy_number;
		public Integer plan_id; //13994
		public boolean visible;
		public String termination_policy; //last_day_of_employment
		public Integer state_carrier_id; //22
		public String url; //http://localhost:4001/companies/7757616923548552/policies/85505
	}

	public class cls_employee {
		public Long id; //7757869432518714
		public String first_name; //Renate
		public String last_name; //Keeling
		public String middle_initial;
		public String status; //Active
		public String ssn; //123456789
		public String birthday; //1984-07-09
		public Long company_id; //7757616923548552
		public String hired_at; //2019-01-22
		public String employment_status; //full_time
		public cls_home_address home_address;
		public cls_work_address work_address;
		public String email; //imogenebernier@kautzerrohan.name
		public String gender; //male
		public String panda_url; //http://manage.gusto-dev.com:3000/companies/7757616923548552/employees/7757869432518714
		public String hippo_url; //http://localhost:4001/companies/7757616923548552/employees/7757869432518714
	}

	public class cls_home_address {
		public Long id; //7757869432685256
		public String fax; //6536223026
		public String zip; //94501
		public String city; //Alameda
		public String phone; //2251536222
		public String state; //CA
		public String country; //USA
		public boolean inactive;
		public String street_1; //945 Spencer Summit
		public String street_2; //Apt. 280
		public String created_at; //2018-12-31T16:23:31.000-08:00
		public String updated_at; //2019-03-12T14:23:09.000-07:00
		public String county_name; //Alameda
		public boolean work_address;
	}

	public class cls_work_address {
		public Long id; //7757727713142867
		public String fax; //5562703451
		public String zip; //94501
		public String city; //Alameda
		public String phone; //5719209244
		public String state; //CA
		public String country; //USA
		public boolean inactive;
		public String street_1; //92351 Corrin Islands
		public String street_2; //Suite 975
		public String created_at; //2015-11-13T16:24:26.000-08:00
		public String updated_at; //2017-10-12T09:18:21.000-07:00
		public String county_name; //Alameda
		public boolean work_address;
	}

	public class cls_company {
		public Long id; //7757616923548552
		public String name; //Reynolds-Weimann
		public String email; //virgiemccullough@gislason.io
		public String salesforce_account_id; //0011600001sg2vaAAA
		public String[] work_states;
		public String sic_code; //3999
		public cls_mailing_address mailing_address;
		public cls_filing_address filing_address;
		public cls_benefits_address benefits_address;
		public Integer number_of_eligible_ees; //119
		public Integer number_of_ineligible_ees; //8
		public boolean has_federal_cobra;
		public boolean is_suspended;
		public String panda_url; //http://manage.gusto-dev.com:3000/companies/7757616923548552
		public String hippo_url; //http://localhost:4001/companies/7757616923548552
	}

	public class cls_mailing_address {
		public Long id; //7757727713142867
		public String fax; //6837311285
		public String zip; //94501
		public String city; //Alameda
		public String phone; //5734550370
		public String state; //CA
		public String country; //USA
		public boolean inactive;
		public String street_1; //4892 Pfeffer Haven
		public String street_2; //Apt. 662
		public String created_at; //2015-11-13T16:24:26.000-08:00
		public String updated_at; //2017-10-12T09:18:21.000-07:00
		public String county_name; //Alameda
		public boolean work_address;
		public Integer employee_count; //173
	}

	public class cls_filing_address {
		public Long id; //7757727713142867
		public String fax; //3020493736
		public String zip; //94501
		public String city; //Alameda
		public String phone; //8465163034
		public String state; //CA
		public String country; //USA
		public boolean inactive;
		public String street_1; //25690 Von Oval
		public String street_2; //Suite 368
		public String created_at; //2015-11-13T16:24:26.000-08:00
		public String updated_at; //2017-10-12T09:18:21.000-07:00
		public String county_name; //Alameda
		public boolean work_address;
		public Integer employee_count; //173
	}

	public class cls_benefits_address {
		public Long id; //7757727713142867
		public String fax; //3020493736
		public String zip; //94501
		public String city; //Alameda
		public String phone; //8465163034
		public String state; //CA
		public String country; //USA
		public boolean inactive;
		public String street_1; //25690 Von Oval
		public String street_2; //Suite 368
		public String created_at; //2015-11-13T16:24:26.000-08:00
		public String updated_at; //2017-10-12T09:18:21.000-07:00
		public String county_name; //Alameda
		public boolean work_address;
		public Integer employee_count; //173
	}

	public class cls_state_carrier {
		public Integer id; //22
		public String name; //Guardian
		public String state; //CA
		public String key; //guardian_ca
		public String url; //http://localhost:4001/national_carriers/24/state_carriers/22
	}

	public class cls_eoi_details {
		public Integer selection_id; //781541
		public String benefit_amount; //500000.0
		public String guaranteed_issue; //100000.0
		public String eoi_url; //http://localhost:4001/companies/7757616923548552/employees/7757869432518714/eois/processing_dashboard
		public String effective_date; //2019-01-01
		public cls_dependent_participants[] dependent_participants;
		public Long document_id;
	}

	public class cls_dependent_participants {
		public String name; //Foster Batz
		public String dependent_type; //spouse
		public String benefit_amount; //250000.0
		public String guaranteed_issue; //25000.0
	}
}