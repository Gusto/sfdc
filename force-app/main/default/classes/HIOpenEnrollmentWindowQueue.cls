public with sharing class HIOpenEnrollmentWindowQueue implements Queueable{
    
    private List<HI_Open_Enrollment_Window__c> openEnrollmentWindowList;   
    public HIOpenEnrollmentWindowQueue(List<HI_Open_Enrollment_Window__c> inputOpenEnrollmentWindowList){
        openEnrollmentWindowList = inputOpenEnrollmentWindowList;
    }
    
    public void execute(QueueableContext context) {
        HIOpenEnrollmentWindowTriggerHelper.queue=true;
        if(openEnrollmentWindowList.size() > 0){ 
            update openEnrollmentWindowList;
        }
    }

}