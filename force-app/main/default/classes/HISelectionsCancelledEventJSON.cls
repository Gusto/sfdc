/**
 * @name         HISelectionsCancelledEventJSON
 * @author       Neha Dabas
 * @date         11th December 2020
 * @description  JSON Structure for Selection Cancelled Event(Enrollment Refactor).
 * @test class   
 * @revisions    Date ------------ Name ------------ Comments  
 */
public with sharing class HISelectionsCancelledEventJSON {
    public String created_at;
    public SelectionInfo selection;
    public HIEnrollmentEventUtility.CompanyInfo company;
    public EmployeeInfo employee;
    public String destroy_reason; //BBO-1456
    public class SelectionInfo{
        public String uuid;
        public String url;
        public String status;
        public EnrollmentInfo enrollment_information;
        public String start_date;
        public String ops_owner;
    }
    public class EnrollmentInfo{
        public PolicyInfo policy;
        public StateCarrierInfo state_carrier;
    }
    public class StateCarrierInfo{
       public Long id;
       public String name;
       public String state;
       public String url;
       public String[] answers;
    }
    public class PolicyInfo{
        public String name;
        public String benefit_type;
        public String termination_policy;
        public String group_number;
        public String policy_number;
        public String url;
    }
    public class EmployeeInfo{
        public Long id;
        public String first_name;
        public String last_name;
        public String middle_initial;
        public String ssn;
        public String birthday;
        public String lost_coverage_date;
        public String benefits_eligibility_date;
        public String terminated_at;
        public String panda_url;
        public String hippo_url;
    }
}