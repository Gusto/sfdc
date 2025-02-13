/**
 * @author Yogesh Kherajani
 * @since 09/11/2024
 * @description This class will be used to schedule org notification flow.
 * Test class: SalesforceOrgNotificationSchedulerTest
 **/
public class SalesforceOrgNotificationScheduler implements Schedulable{
	public void execute(SchedulableContext sc) {
        Map<String, Object> map_Params = new Map<String, Object>();
        //create instance of Interview
        Flow.Interview.Salesforce_Org_Notifications objSalesOrgNotification = new Flow.Interview.Salesforce_Org_Notifications(map_Params);
        //Invoke start method
        objSalesOrgNotification.start();
    }
}