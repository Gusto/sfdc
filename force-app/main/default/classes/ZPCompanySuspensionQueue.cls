public class ZPCompanySuspensionQueue  implements Queueable {

    private List<ZP_Company_Suspension__c> companyList;
        
    public ZPCompanySuspensionQueue(List<ZP_Company_Suspension__c> inputCompanyList){
        companyList = inputCompanyList;
    }
    
    public void execute(QueueableContext context) {
        ZPCompanySuspensionTriggerHelper.queue=true;
        if(companyList.size() > 0){ 
            update companyList;
        }
    }
}