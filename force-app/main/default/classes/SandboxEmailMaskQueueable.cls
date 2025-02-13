/**
* @name         SandboxEmailMaskQueueable
* @author       Sanjay Paryani
* @date         07/07/2020 
* @description  Queueable job for the SandboxEmailMaskBatch
* @revisions    Date ------------ Name ------------ Comments 
*               07/07/2020        SanjayP           Changed unmasking technique as Salesforce currently uses .invalid for email masking.
*                        							sObj.put(fieldName, email.left(68).replaceAll('@', '=') + '@example.com');
**/
public class SandboxEmailMaskQueueable implements Queueable{
    private List<sObject> list_Scope;
    public String strQuery = '';
    public List<String> list_EmailFields = new List<String>();
    
    public SandboxEmailMaskQueueable(List<sObject> list_Records, List<String> list_EmailFieldsInput) {
        this.list_Scope = list_Records;
        this.list_EmailFields = list_EmailFieldsInput;
    }
    
    public void execute(QueueableContext context){
        if(list_Scope != null && !list_Scope.isEmpty()){
            for(sObject sObj : list_Scope){
                for(String fieldName : list_EmailFields) {
                    String strEmail = (String)sObj.get(fieldName);
                    if(String.isNotBlank(strEmail) && !strEmail.contains('.invalid')){
                        if(strEmail.length() > 72) {
                        	sObj.put(fieldName, strEmail.right(72) + '.invalid');     
                        } else {
                            sObj.put(fieldName, strEmail + '.invalid'); 
                        }
                    }
                }
            }
            //update list_Scope;
            AccountTriggerHelper.skipTrigger = true;
            OpportunityTriggerHelper.skipTrigger = true;
            LeadTriggerHelper.skipTrigger = true;
            ContactTriggerHelper.skipTrigger = true;
            CaseTriggerHelper.skipTrigger = true;
            database.update(list_Scope, false);
        }  
    }
}