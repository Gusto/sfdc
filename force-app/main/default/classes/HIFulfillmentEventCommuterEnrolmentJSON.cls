public class HIFulfillmentEventCommuterEnrolmentJSON{
    public employee employee;
    public company company;
    public commuter_benefit commuter_benefit;
    public commuter_employee_benefit commuter_employee_benefit;
    public String policies_url; //https://hippo.zentest.com/companies/652058429284/policies
    public String benefits_url;    //https://hippo.zentest.com/companies/652058429284/employees/1/subscriptions
    public HIFulfillmentEventCommuterEnrolmentJSON(){}
    public class employee {
        public Long id; //1
        public String first_name;   //Jeanie
        public String last_name;    //Mayer
        public String middle_initial;   //C
        public String status;   //Active
        public String ssn;  //680111739
        public String birthday; //1992-07-28
        public Long company_id; //652058429284
        public String hired_at; //2017-07-28
        public String employment_status;    //full_time
        public home_address home_address;
        public work_address work_address;
        public String email;    //employee_email@example.com
        public String gender;   //female
        public String panda_url;    //https://app.zentest.com/companies/652058429284/employees/1
        public String hippo_url;    //https://hippo.zentest.com/companies/652058429284/employees/1
    }
    public class home_address {
        public Long id; //704880222638
        public String street_1; //33270 Letha Point
        public String street_2; //Suite 356
        public Integer employee_count;  //1
        public String city; //Edmundtown
        public String state;    //CA
        public String county_name;  //San Francisco
        public String country;  //USA
        public String zip;  //94107
        public String phone;    //4051234567
        public String single_line_street;   //33270 Letha Point, Suite 356
    }
    public class work_address {
        public Long id; //217178279283
        public String street_1; //1781 Hank Dam
        public String street_2; //Suite 767
        public Integer employee_count;  //5
        public String city; //Edmundtown
        public String state;    //CA
        public String county_name;  //San Francisco
        public String country;  //USA
        public String zip;  //94107
        public String phone;    //4051234567
        public String single_line_street;   //1781 Hank Dam, Suite 767
    }
    public class company {
        public Long id; //652058429284
        public String name; //Blanda Group
        public String email;    //company_email@example.com
        public String salesforce_account_id;
        public String[] work_states;
        public String sic_code; //3999
        public work_address mailing_address;
        public work_address filing_address;
        public work_address benefits_address;
        public Integer number_of_eligible_ees;  //1
        public Integer number_of_ineligible_ees;    //0
        public boolean has_federal_cobra;
        public boolean is_suspended;
        public String panda_url;    //https://app.zentest.com/companies/652058429284
        public String hippo_url;    //https://hippo.zentest.com/companies/652058429284
    }

    public class commuter_benefit {
        public Long id; //1
        public Long company_id; //652058429284
        public String status;   //created
        public String start_date;   //2017-07-01
        public String end_date;
        public boolean upcoming;
        public boolean active;
        public boolean expired;
        public String waiting_period;   //first_of_month_following_hire
        public company_contribution_inputs company_contribution_inputs;
        public String url;  //https://hippo.zentest.com/companies/652058429284/commuter_benefits/1
    }

    public class company_contribution_inputs {
        public String type; //waterfall
        public String contribution_amount;  //100.00
    }
    public class commuter_employee_benefit {
        public Long id; //1
        public Long employee_id;    //1
        public Long commuter_benefit_id;    //1
        public String status;   //created
        public String start_date;   //2017-07-01
        public String transit_monthly_election; //125.0
        public String transit_monthly_contribution; //100.0
        public String transit_monthly_deduction;    //25.0
        public String parking_monthly_election; //50.0
        public String parking_monthly_contribution; //0.0
        public String parking_monthly_deduction;    //50.0
        public String url;  //https://hippo.zentest.com/companies/652058429284/employees/1/commuter_employee_benefits/1
        public String commuter_benefit_url; //https://hippo.zentest.com/companies/652058429284/commuter_benefits/1
    }

}