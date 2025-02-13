public with sharing class HINewPlansApplicationQueue implements Queueable{
    
    private List<HI_New_Plans_Application__c> npApplicationList;
    private Map<Id, HI_New_Plans_Application__c> map_npApplicationsOld;
        
    public HINewPlansApplicationQueue(List<HI_New_Plans_Application__c> inputNPApplicationList){
        npApplicationList = inputNPApplicationList;
    }
    
    public HINewPlansApplicationQueue(List<HI_New_Plans_Application__c> inputNPApplicationList, Map<Id, HI_New_Plans_Application__c> map_npApplicationsOld) {
        npApplicationList = inputNPApplicationList;
        this.map_npApplicationsOld = map_npApplicationsOld;
    }
    public void execute(QueueableContext context) {
        HINewPlansApplicationTriggerHelper.queue=true;
        HINewPlansApplicationTriggerHelper.map_npApplicationsOld = map_npApplicationsOld;
        if(npApplicationList.size() > 0){ 
            update npApplicationList;
        }
    }
}