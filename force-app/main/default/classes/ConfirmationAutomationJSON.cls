public with sharing class ConfirmationAutomationJSON {
    public String event_id;
    public String company_id;
    public String application_type;
    public String event_type;
    public String application_id;
    public String state_carrier_id;
    public String error_message;
    public List<Policy> policies;

    public class Policy{
        public String id;
        public String name;
        public String benefit_type;
        public String hi_confirmation_page_link;
        public String hi_confirmation_automation_message;
        public String hi_confirmation_automation_status;
    }
}