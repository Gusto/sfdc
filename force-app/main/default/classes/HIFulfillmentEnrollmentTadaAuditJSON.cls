/**
 * @name         HIFulfillmentEnrollmentTadaAuditJSON
 * @author		 PR
 * @date          June/19/2020
 * @description  This class is used as a wrapper class for "tada audit" json.
 * @test class
 */
public class HIFulfillmentEnrollmentTadaAuditJSON {
	public String sub_type;
	public Company company;
	public Employee employee;
	public List<Dependent> dependents;
	public employee_benefit employee_benefits;
	public Error errors;
	public String audit_type;

	public HIFulfillmentEnrollmentTadaAuditJSON() {
	}

	public class Company {
		public Long id;
		public String name;
		public String email;
		public String salesforce_account_id;
		public List<String> work_states;
		public String sic_code;
		public Address mailing_address;
		public Address filing_address;
		public Address benefits_address;
		public Integer number_of_eligible_ees;
		public Integer number_of_ineligible_ees;
		public Boolean has_federal_cobra;
		public Boolean is_suspended;
		public String panda_url;
		public String hippo_url;
		public String google_drive_folder_url;
	}

	public class Employee {
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
		public HomeAddress home_address;
		public Address work_address;
		public String email;
		public String gender;
		public String annual_salary;
		public String benefits_eligibility_date;
		public String panda_url;
		public String hippo_url;
	}

	public class Address {
		public Long id;
		public String fax;
		public String zip;
		public String city;
		public String phone;
		public String state;
		public String country;
		public Boolean inactive;
		public String street_1;
		public String street_2;
		public String created_at;
		public String updated_at;
		public String county_name;
		public Boolean work_address;
		public Integer employee_count;
	}

	public class HomeAddress {
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
		public Boolean inactive;
		public Boolean work_address;
	}

	public class Dependent {
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

	public class employee_benefit {
		public String benefit_type;
		public String hippo_url;
		public String effective_date;
		public String parking_monthly_election;
		public String transit_monthly_election;
		public String election;
		public String provider_key;
	}

	public class Error {
		public String error_code;
		public String error_reason;
	}
}