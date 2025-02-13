public class HITaDaSelectionCancelledEventJSON {
	public String created_at;// "2020-12-08T15:15:22-08:00"
    public SelectionInfo selection;
    public EmployeeInfo employee;
    public CompanyInfo company;

    public class SelectionInfo{
        public String uuid;
        public String benefit_type;
        public String start_date;
        public String provider_key;
    }

    public class EmployeeInfo{
        public Long id;
        public String first_name;
        public String last_name;
        public String middle_initial;
        public String ssn;
        public String email;
        public String benefits_eligibility_date;
        public String lost_coverage_date;
        public String panda_url;
        public String hippo_url;
    }
    
	public class CompanyInfo{
        public Long id ;
        public String email;
        public String panda_url;
        public String hippo_url;
    }
}