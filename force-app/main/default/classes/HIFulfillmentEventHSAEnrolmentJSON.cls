public class HIFulfillmentEventHSAEnrolmentJSON {
	public employee employee;
	public company company;
	public hsa_benefit hsa_benefit;
	public hsa_selection hsa_selection;
	public String policies_url; //https://hippo.zentest.com/companies/742157482339/policies
	public String benefits_url; //https://hippo.zentest.com/companies/742157482339/employees/1/subscriptions

	public HIFulfillmentEventHSAEnrolmentJSON() {}
	public class employee {
		public Long id; //1
		public String first_name; //Bonnie
		public String last_name; //Robel
		public String middle_initial; //D
		public String status; //Active
		public String ssn; //241541227
		public String birthday; //Fri, 31 Jul 1992
		public Long company_id; //742157482339
		public String hired_at; //Mon, 31 Jul 2017
		public String employment_status; //full_time
		public address home_address;
		public address work_address;
		public String email; //employee_email@example.com
		public String gender; //female
		public String panda_url; //https://app.zentest.com/companies/742157482339/employees/1
		public String hippo_url; //https://hippo.zentest.com/companies/742157482339/employees/1
	}
	public class address {
		public Long id; //492427006170
		public String street_1; //58860 Blake Curve
		public String street_2; //Suite 126
		public Integer employee_count; //4
		public String city; //Samsonside
		public String state; //CA
		public String county_name; //San Francisco
		public String country; //USA
		public String zip; //94107
		public String phone; //4051234567
		public String single_line_street; //58860 Blake Curve, Suite 126
	}

	public class company {
		public Long id; //742157482339
		public String name; //Walker, Quigley and Gutmann
		public String email; //company_email@example.com
		public String salesforce_account_id;
		public String[] work_states;
		public String sic_code; //3999
		public address mailing_address;
		public address filing_address;
		public address benefits_address;
		public Integer number_of_eligible_ees; //1
		public Integer number_of_ineligible_ees; //0
		public boolean has_federal_cobra;
		public boolean is_suspended;
		public String panda_url; //https://app.zentest.com/companies/742157482339
		public String hippo_url; //https://hippo.zentest.com/companies/742157482339
	}
	public class hsa_benefit {
		public Long id; //1
		public Long company_id; //742157482339
		public String effective_date; //Mon, 31 Jul 2017
		public String expiration_date; //Tue, 31 Jul 2018
		public String status; //visible
		public String url; //https://hippo.zentest.com/companies/742157482339/policies
        	public String provider_key;//Added for BBO-1966
	}
	public class hsa_selection {
		public Long id; //1
		public Long employee_id; //1
		public Long hsa_benefit_id; //1
		public String start_date;
		public String max_contribution_cents; //10000
		public String url; //https://hippo.zentest.com/companies/742157482339/employees/1/hsa_subscriptions/1
	}
}