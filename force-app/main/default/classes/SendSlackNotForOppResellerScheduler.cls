/**
 * @author Yogesh Kherajani
 * @since 09/18/2024
 * @description This class will be used to Send Slack Notification To Opportunity Reseller.
 * Test class: SendSlackNotForOppResellerSchedulerTest
 **/
public class SendSlackNotForOppResellerScheduler implements Schedulable{
    public void execute(SchedulableContext SC) {
        List<SendSlackNotForOppResellerWrapper> lst_SendSlakcNotification = new List<SendSlackNotForOppResellerWrapper>();
        
        for(Opportunity objOppRec : [
            SELECT Id, Sold_By__c, Sold_By__r.Name, Sold_By__r.Owner_Slack_Id__c, Referred_By__c, Send_Slack_to_Reseller__c,
            Referred_By__r.Name, Referred_By__r.Owner_Slack_Id__c
            FROM Opportunity 
            WHERE Send_Slack_to_Reseller__c = TRUE
        ]){
            SendSlackNotForOppResellerWrapper objSendSlakcNotification = new SendSlackNotForOppResellerWrapper();
            objSendSlakcNotification.strOpportunityId = objOppRec.Id;
            
            if(objOppRec.Sold_By__c != NULL){
                objSendSlakcNotification.strSoldBy = objOppRec.Sold_By__c;
            	objSendSlakcNotification.strSoldByName = objOppRec.Sold_By__r.Name;
                objSendSlakcNotification.strSoldByOwnerSlackId = objOppRec.Sold_By__r.Owner_Slack_Id__c;
            }
            
            if(objOppRec.Referred_By__c != NULL){
                objSendSlakcNotification.strReferredBy = objOppRec.Sold_By__c;
            	objSendSlakcNotification.strReferredByName = objOppRec.Sold_By__r.Name;
                objSendSlakcNotification.strReferredByOwnerSlackId = objOppRec.Referred_By__r.Owner_Slack_Id__c;
            }
            
            lst_SendSlakcNotification.add(objSendSlakcNotification);
        }
        
        if(!lst_SendSlakcNotification.isEmpty()){
            Map<String, Object> map_SendSlackNotification = new Map<String, Object>();
            map_SendSlackNotification.put('lst_SendSlackRecords', lst_SendSlakcNotification);
            
            // Instantiate and start the Flow
            Flow.Interview.Send_Slack_notificaiotn_to_partner_for_new_client_add_within_30_days_of_CW objFlow = new Flow.Interview.Send_Slack_notificaiotn_to_partner_for_new_client_add_within_30_days_of_CW(map_SendSlackNotification);
            objFlow.start();    
        }
    }
}