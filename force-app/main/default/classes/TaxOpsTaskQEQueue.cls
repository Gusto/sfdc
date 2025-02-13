public class TaxOpsTaskQEQueue implements Queueable {
	
	private List<Tax_Ops_Task_QE__c> tskQEList;
        
    public TaxOpsTaskQEQueue(List<Tax_Ops_Task_QE__c> inputQEList){
        tskQEList = inputQEList;
    }  

	public void execute(QueueableContext context) {
        TaxOpsTaskQETriggerHelper.queue=true; 
        if(tskQEList.size() > 0){ 
            update tskQEList;
        }
	}
}