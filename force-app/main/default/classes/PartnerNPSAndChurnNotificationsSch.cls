public class PartnerNPSAndChurnNotificationsSch implements Schedulable {
    public void execute(SchedulableContext SC) {
        Map<String, Object> map_Params = new Map<String, Object>();
        //create instance of Interview
        Flow.Interview.Partner_NPS_and_Churn_Notifications_Slack objPNandCN = new Flow.Interview.Partner_NPS_and_Churn_Notifications_Slack(map_Params);
        //Invoke start method
        objPNandCN.start();
    }
}