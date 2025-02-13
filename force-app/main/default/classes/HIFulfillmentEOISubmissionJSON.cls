public class HIFulfillmentEOISubmissionJSON{
	public List<selection> selections;
	public employee employee;
	public company company;
	public state_carrier state_carrier;
	public List<eoi_details> eoi_details;
    public String benefits_url;	//http://localhost:4001/companies/7757616923551897/employees/7757869432256982/benefits
    
	public class selection {
		public Long id;	//526959
        public Long policy_id;
        public String benefit_type;  
		public String url;	//http://localhost:4001/companies/7757616923551897/employees/7757869432256982/selections/526959
        
	}
    
	public class employee {
		public Long id;	//7757869432256982 
		public String first_name;	//Addie
		public String last_name;	//Corkery
		public String middle_initial;
		public String status;	//Active
		public String ssn;	//123456789
		public String birthday;	//1995-02-25
		public Long company_id;	//7757616923551897
		public String hired_at;	//2018-07-25
		public String employment_status;	//full_time
		public home_address home_address;
		public work_address work_address;
		public String email;	//ruben.senger7757869449871567@daugherty.co
		public String gender;	//female
		public String panda_url;	//http://manage.gusto-dev.com:3000/companies/7757616923551897/employees/7757869432256982
		public String hippo_url;	//http://localhost:4001/companies/7757616923551897/employees/7757869432256982
	}
	
	public class home_address {
		public Long id;	//7757869432170709
		public String street_1;	//512 Dulce Flats
		public String street_2;	//
		public String city;	//Sacramento
		public String county_name;	//Sacramento
		public String state;	//CA
		public String zip;	//95820
		public String country;	//USA
		public String phone;
		public String created_at;	//2018-07-20T16:49:20.000-07:00
		public String updated_at;	//2018-07-20T18:00:13.000-07:00
		public String fax;
		public boolean inactive;
		public boolean work_address;
	}
	
	public class work_address {
		public Long id;	//7757727713164251
		public String street_1;	//649 Donnell Brook
		public String street_2;	//Suite 489
		public String city;	//Sacramento
		public String county_name;	//Sacramento
		public String state;	//CA
		public String zip;	//95815
		public String country;	//USA
		public String phone;	//7249233548
		public String created_at;	//2015-12-07T06:25:16.000-08:00
		public String updated_at;	//2015-12-07T06:25:16.000-08:00
		public String fax;
		public boolean inactive;
		public boolean work_address;
		public Integer employee_count;	//37
	}
    
	public class company {
		public Long id;	//7757616923551897
		public String name;	//Zulauf, Dickinson and Romaguera
		public String email;	//gus_jenkins7757869448687101@hayesokon.net
		public String salesforce_account_id;
		public String[] work_states;
		public String sic_code;	//8011
		public work_address mailing_address;
		public work_address filing_address;
		public work_address benefits_address;
		public Integer number_of_eligible_ees;	//12
		public Integer number_of_ineligible_ees;	//5
		public boolean has_federal_cobra;
		public boolean is_suspended;
		public String panda_url;	//http://manage.gusto-dev.com:3000/companies/7757616923551897
		public String hippo_url;	//http://localhost:4001/companies/7757616923551897
	}
	
	
	public class state_carrier {
		public Integer id;	//9
		public String name;	//Aetna
		public String state;	//CA
		public String key;	//aetna_ca
		public String url;	//http://localhost:4001/national_carriers/1/state_carriers/9
		public String carrier_enrollment_url;	//http://localhost:4001/companies/7757616923551897/employees/7757869432256982/enrollments/262800/aetna_ca
	}
	public class eoi_details {
        public Long selection_id;
		public String benefit_amount;	//81120.0
		public String guaranteed_issue;	//70000.0
		public String eoi_url;	//http://localhost:4001/companies/7757616923551897/employees/7757869432256982/eois
		public String effective_date;	//2018-09-01
		public dependent_participant[] dependent_participants;
        public Long document_id;
	}
	public class dependent_participant {
		public String name;	//Isaiah Berlin
		public String benefit_amount;	//10000.0
		public String guaranteed_issue;	//2000.0
	}
	
}