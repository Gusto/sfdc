/*
    By: BS
    Date: 30 October 2020    
	Description: This class is used as a helper class for the AnalyticsTimeTracker trigger 
*/
public with sharing class AnalyticsTimeTrackerTriggerHelper {
    public static boolean skipTrigger = false;
	
	public void OnBeforeInsert(List<Analytics_Time_Tracker__c> list_NewTracker){}

    public void OnAfterInsert(Map<ID, Analytics_Time_Tracker__c> map_NewTracker){}

    public void OnBeforeUpdate(Map<ID, Analytics_Time_Tracker__c>  map_OldTracker, Map<ID, Analytics_Time_Tracker__c> map_NewTracker){
        List<Analytics_Time_Tracker__c> list_UpdatedTracker = new List<Analytics_Time_Tracker__c>();
        Analytics_Time_Tracker__c objOld = null;
        for(Analytics_Time_Tracker__c objNew : map_NewTracker.values()){
            objOld = map_OldTracker.get(objNew.Id);
            if(objNew.Start_Date__c != objOld.Start_Date__c || objNew.End_Date__c != objOld.End_Date__c){
                if(objNew.Start_Date__c != null && objNew.End_Date__c != null &&  objNew.Start_Date__c <= objNew.End_Date__c){
                    list_UpdatedTracker.add(objNew);
                }else{
                    objNew.Processing_Time_Duration__c = null;
                }
            }
        }
        if(list_UpdatedTracker.size()>0){
            calculateBusinessDuration(list_UpdatedTracker);
        } 
	}

    public void OnAfterUpdate(Map<Id, Analytics_Time_Tracker__c>  map_OldTracker, Map<Id, Analytics_Time_Tracker__c> map_NewTracker){} 

    public void OnBeforeDelete(List<Analytics_Time_Tracker__c> list_NewTracker, Map<ID, Analytics_Time_Tracker__c> map_OldTracker){}

    public void calculateBusinessDuration(List<Analytics_Time_Tracker__c> list_UpdatedTracker){    
        Date dateStart = null;
        Date dateEnd = null;
        Integer intDays = 0;
        Integer intHours = 0;  
        Integer intMinutes = 0;  
        Decimal decimal_Minutes = 0;
        for(Analytics_Time_Tracker__c objTracker : list_UpdatedTracker){
            decimal_Minutes = 0;
            dateStart = objTracker.Start_Date__c.date();
            dateEnd = objTracker.End_Date__c.date();
            intDays =  dateStart.daysBetween(dateEnd);
            intHours = objTracker.End_Date__c.hour() - objTracker.Start_Date__c.hour();
            intMinutes = objTracker.End_Date__c.minute() - objTracker.Start_Date__c.minute();
            
            if(dateStart==dateEnd){
                objTracker.Skip_Reporting__c = false; 
            }else{
                objTracker.Skip_Reporting__c = true; 
            }
            decimal_Minutes = (intDays*24*60) + (intHours*60) + intMinutes;
            objTracker.Processing_Time_Duration__c = decimal_Minutes;
        }
    }
}