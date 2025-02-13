@RestResource(urlMapping='/DNCService/Lead/*')
global with sharing class DNCLeadService {
    
    @HttpGet
    global static List<leadInfo>  doGet() {
        List<leadInfo> leadList = new List<leadInfo>();
        
        List<Lead> leads = new List<Lead>([Select id, Normalized_Phone__c, Normalized_Alternate_Phone__c, Normalized_Mobile_Phone__c, 
                                           Normalized_Secondary_phone__c,(Select id from Cases__r where CreatedDate>=Last_n_days:90 and origin in ('Phone','Email','Chat','Web','Success Email','Panda','Hippo','Cobra Email','Gusto')),
                                           (Select id, CallType, RecordType.Name 
                                            from Tasks 
                                            where (recordType.name in ('Chat') or (recordType.name in ('Call') and CallType='Inbound') ) 
                                            and CreatedDate >= LAST_N_DAYS:90)
                                           from Lead where Isconverted=false 
                                           and (DNC_Validated_Date_Time__c>Last_n_days:30 or DNC_Validated_Date_Time__c=null) 
                                           and ( 
                                               Normalized_phone__c !=null or 
                                               Normalized_Mobile_Phone__c!=null or 
                                               Normalized_Alternate_Phone__c!=null or 
                                               Normalized_Secondary_Phone__c!=null) Limit 100]);
        
        for(Lead l : leads){
            leadInfo lInfo = new leadInfo();
            lInfo.id = l.Id;
            lInfo.normalizedPhone = l.Normalized_phone__c;
            lInfo.normalizedAlternatePhone = l.Normalized_Alternate_Phone__c;
            lInfo.normalizedMobilePhone = l.Normalized_Mobile_Phone__c;
            lInfo.normalizedSecondaryPhone = l.Normalized_Secondary_Phone__c;
            lInfo.activityExists = false;
            if(l.Tasks.size() > 0 || l.Cases__r.size() > 0 ){
                lInfo.activityExists=true;
            }
            leadList.add(lInfo);
        }
        
        return leadList;
    }
    
    @HttpPost
    global static void  doPost(List<leadUpdateInfo> leadUpdateList) {
        List<Lead> leadList = new List<Lead>();
        for(leadUpdateInfo info : leadUpdateList){
            Lead l = new Lead(Id=info.id);
            if(info.activityExists=='true'){
                l.Dnc_activity_exists__c = true;
            } else {
                l.Dnc_activity_exists__c = false;
            }
            if(info.doNotCall=='true'){
                l.DoNotCall= true;
            } else {
                l.DoNotCall= false;
            }
            l.DNC_Validated_Date_Time__c=system.now();
            leadList.add(l);
        }
        leadTriggerHelper.skipTrigger = true;
        update leadList;
        //return ''+leadUpdateList;
    }
    
    global class leadUpdateInfo{
        global String id;
        global string activityExists;
        global string doNotCall;
    }
    
    global class leadInfo {
        global String id;	
        global String normalizedPhone;	
        global String normalizedAlternatePhone;	
        global String normalizedMobilePhone;	
        global String normalizedSecondaryPhone;	
        global boolean activityExists;
    }
}