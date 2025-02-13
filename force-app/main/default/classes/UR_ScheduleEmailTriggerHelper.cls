public with sharing class UR_ScheduleEmailTriggerHelper{  
    public static boolean skipTrigger = false;
	
	public void OnAfterUpdate(Map<ID, Research_Schedule_Email__c>  oldResUploadMap, Map<ID, Research_Schedule_Email__c> newResUploadMap, List<Research_Schedule_Email__c> resUpload){
        DateTime currentDateTime = System.now();
        Research_Schedule_Email__c oldScheduleObj = null;
        Integer intHour = 0;
        Time selectedTime = null;
        DateTime scheduledDateTime = null;
        List<Research_Schedule_Email__c> newScheduleEmailList = new List<Research_Schedule_Email__c>();
        
        for(Research_Schedule_Email__c scheduleObj : resUpload){
            oldScheduleObj = oldResUploadMap.get(scheduleObj.Id);
            if(scheduleObj.Schedule_Email_Date__c!=oldScheduleObj.Schedule_Email_Date__c || scheduleObj.Schedule_Email_Time__c!=oldScheduleObj.Schedule_Email_Time__c){
                if(scheduleObj.Schedule_Email_Date__c!=null && scheduleObj.Schedule_Email_Time__c!=null){
                    intHour = Integer.valueOf(scheduleObj.Schedule_Email_Time__c);
                    selectedTime = Time.newInstance(intHour, 0, 0, 0);
                    scheduledDateTime =  DateTime.newInstance(scheduleObj.Schedule_Email_Date__c, selectedTime);
                    if(currentDateTime<scheduledDateTime){
                        //If schedule date is a future date.
                        newScheduleEmailList.add(scheduleObj);   
                    }
                }
            } 
        }
        
        if(newScheduleEmailList.size()>0){
            scheduleNewEmailJob(newScheduleEmailList);
        }
	}

    public void scheduleNewEmailJob(List<Research_Schedule_Email__c> newScheduleEmailList){
        Set<String> jobNameSet = new Set<String>();
        Map<String, String> jobNameMap = new Map<String, String>();
        String key='';
        //Create new schedule job set.
        for(Research_Schedule_Email__c scheduleEmail : newScheduleEmailList){
            Date scheduleDate = scheduleEmail.Schedule_Email_Date__c; 
            String hour = scheduleEmail.Schedule_Email_Time__c;
            String CRON_EXP = '0 0 '+hour+' '+scheduleDate.day()+' '+scheduleDate.month()+' ? '+scheduleDate.year();
            
            Integer intHour = Integer.valueOf(scheduleEmail.Schedule_Email_Time__c);
            Time myTime = Time.newInstance(intHour, 0, 0, 0);
            DateTime scheduledDateTime =  DateTime.newInstance(scheduleEmail.Schedule_Email_Date__c, myTime); 
            key = 'UXR_Schedule_Email_' + scheduledDateTime;
            jobNameSet.add(key);
            jobNameMap.put(key, CRON_EXP);
        }
        
        //If any job is aleady in-progress then no need to create new job.
        List<CronTrigger> scheduleJobList = [select id, CronJobDetail.name from CronTrigger where CronJobDetail.Name IN : jobNameSet];
        for(CronTrigger conJob : scheduleJobList){
            if(jobNameSet.contains(conJob.CronJobDetail.name)){
               jobNameSet.remove(conJob.CronJobDetail.name);
               jobNameMap.remove(conJob.CronJobDetail.name);
            }
        }
        
        //Create new schedule apex-job.
        for(String jobName : jobNameSet){
            UR_ScheduleEmail scheduleObj = new UR_ScheduleEmail();
            String jobID = system.schedule(jobName, jobNameMap.get(jobName), scheduleObj);
        }
    }
}