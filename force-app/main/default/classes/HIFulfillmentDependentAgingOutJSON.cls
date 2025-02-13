public class HIFulfillmentDependentAgingOutJSON{
	public cls_employee employee;
	public cls_company company;
	public cls_dependent dependent;
	public class cls_employee {
		public Long id;	//1403814289845323
		public String first_name;	//Samantha
		public String last_name;	//Fay
		public String middle_initial;	//
		public String status;	//Active
		public String ssn;	//123456789
		public String birthday;	//1975-01-21
		public Long company_id;	//1403814155979215
		public String hired_at;	//2011-04-01
		public String employment_status;	//full_time
		public cls_home_address home_address;
		public cls_work_address work_address;
		public String email;	//helen1403814290162314@bauch.name
		public String gender;	//male
		public String panda_url;	//http://manage.zenpayroll.dev:3000/companies/1403814155979215/employees/1403814289845323
		public String hippo_url;	//http://localhost:4001/companies/1403814155979215/employees/1403814289845323
	}
	public class cls_home_address {
		public Long id;	//1403814337566789
		public String street_1;	//126 Conn Fields
		public String street_2;	//Apt. 945
		public String city;	//Anaheim
		public String county_name;	//Orange
		public String state;	//CA
		public String zip;	//92807
		public String country;	//USA
		public String phone;
		public String created_at;	//2014-06-26T13:25:37.000-07:00
		public String updated_at;	//2014-06-26T13:25:37.000-07:00
		public String fax;
		public boolean inactive;
		public boolean work_address;
	}

	public class cls_work_address {
		public Long id;	//1403814205717482
		public String street_1;	//387 Huel Cliffs
		public String street_2;	//Apt. 933
		public String city;	//Anaheim
		public String county_name;	//Orange
		public String state;	//CA
		public String zip;	//92807
		public String country;	//USA
		public String phone;	//4626259268
		public String created_at;	//2014-06-26T13:23:25.000-07:00
		public String updated_at;	//2014-06-26T13:23:25.000-07:00
		public String fax;	//8496074826
		public boolean inactive;
		public boolean work_address;
		public Integer employee_count;	//21
	}
	public class cls_company {
		public Long id;	//1403814155979215
		public String name;	//Keebler Inc
		public String email;	//chesley.little1403814155945538@auer.com
		public String salesforce_account_id;
		public String[] work_states;
		public String sic_code;	//7379
		public cls_work_address mailing_address;
		public cls_work_address filing_address;
		public cls_work_address benefits_address;
		public Integer number_of_eligible_ees;	//7
		public Integer number_of_ineligible_ees;	//1
		public boolean has_federal_cobra;
		public boolean is_suspended;
		public String panda_url;	//http://manage.zenpayroll.dev:3000/companies/1403814155979215
		public String hippo_url;	//http://localhost:4001/companies/1403814155979215
	}

	public class cls_dependent {
		public Long id;	//3
		public String first_name;	//Darrell
        public String middle_initial;	//Darrell
		public String last_name;	//Lakin
		public String ssn;	//123456789
		public String birthday;	//2006-07-30
		public String gender;	//female
		public String dependent_type;	//child
		public Long employee_id;	//1403814289845323
		public String url;	//http://localhost:4001/companies/1403814155979215/employees/1403814289845323/dependents/3
		public boolean disabled;
	}

    
}