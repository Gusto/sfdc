/**
Created by : Praveen Sethu
Created Date : 11/26/2020
Description: Handles Queueable jobs related to ZP Benefits.
**/
public class ZPBenefitQueue implements Queueable {
    
    private List<ZP_Benefit__c> list_ZPBenefits;
    
    // Constructor
    public ZPBenefitQueue(List<ZP_Benefit__c> list_InputZPBenefits){
        list_ZPBenefits = list_InputZPBenefits;
    }
    
    public void execute(QueueableContext context) {
        ZPBenefitTriggerHelper.blnQueue = true;
        
        if(!list_ZPBenefits.isEmpty()) {
            try {
                update list_ZPBenefits;
            } catch(Exception objException) {
                ExceptionLogUtil.logException('ZPBenefitQueue', 'execute', 'Exception On Line ' + objException.getLineNumber() + '-' + objException.getMessage(), objException.getStackTraceString());
            }
        }
    }
}