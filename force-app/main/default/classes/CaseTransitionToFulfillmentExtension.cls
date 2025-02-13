public class CaseTransitionToFulfillmentExtension {
	public Case theCase {get; private set;} 
    public Transition_To_Fulfillment__c transition {get; private set;}
    
    public CaseTransitionToFulfillmentExtension(ApexPages.StandardController controller) {
        theCase = (Case) controller.getRecord();
        transition = new Transition_To_Fulfillment__c();
        //Lirik - Not in USE - Migration for BOR to BO -- Start ---
       // theCase = [Select Id, AccountId, ContactId,BoR_Transfer__c,Description  from Case where id = :theCase.id];
       //Lirik - Not in USE - Migration for BOR to BO -- End ---
       
        theCase = [Select Id, AccountId, ContactId,Benefit_Order__c,Description  from Case where id = :theCase.id];
        Set<String> oppIdList = new Set<String>();
        //Lirik - Not in USE - Migration for BOR to BO -- Start ---
        /*for(BoR_Transfer__c transfer : [Select Id, Salesforce_Opportunity_Id__c from BoR_Transfer__c where id = :theCase.BoR_Transfer__c and id !=null]){
            oppIdList.add(transfer.Salesforce_Opportunity_Id__c);
        }*/
        //Lirik - Not in USE - Migration for BOR to BO -- End ---
         for(Benefit_Order__c transfer : [Select Id, Opportunity__c from Benefit_Order__c where id = :theCase.Benefit_Order__c and id !=null]){
            oppIdList.add(transfer.Opportunity__c);
        }
        
        if(oppIdList.size() > 0){
        	List<Transition_To_Fulfillment__c> transitionList = new List<Transition_To_Fulfillment__c>([Select id, Benefits_Point_of_Contact__c, Contact_Preference__c, Medical_Carrier__c, Dental_Carrier__c,  Vision_Carrier__c, Is_LiDi_contributory__c, LiDi_Carrier__c, FSA_HSA_401K__c, Notes_for_the_CX_team__c from Transition_To_Fulfillment__c where Opportunity__c in :oppIdList]);
            if(transitionList.size() > 0){
                transition = transitionList[0];
            }
        }
        
    }
}