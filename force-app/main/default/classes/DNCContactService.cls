@RestResource(urlMapping='/DNCService/Contact/*')
global with sharing class DNCContactService {
    
    @HttpGet
    global static List<contactInfo>  doGet() {
        List<contactInfo> contactList = new List<contactInfo>();
        
        List<Contact> contacts = new List<Contact>([Select id, Normalized_Phone__c, Normalized_Other_Phone__c, Normalized_Mobile_Phone__c, 
                                                    (Select id from Cases where CreatedDate>=Last_n_days:90 and origin in ('Phone','Email','Chat','Web','Success Email','Panda','Hippo','Cobra Email','Gusto')),
                                                    (Select id, CallType, RecordType.Name 
                                                     from Tasks 
                                                     where (recordType.name in ('Chat') or (recordType.name in ('Call') and CallType='Inbound') ) 
                                                     and CreatedDate >= LAST_N_DAYS:90)
                                                    from Contact where Account.Account_Status__c!='Customer'
                                                    and (DNC_Validated_Date_Time__c>Last_n_days:30 or DNC_Validated_Date_Time__c=null) 
                                                    and (
                                                        Normalized_phone__c !=null or 
                                                        Normalized_Mobile_Phone__c!=null or 
                                                        Normalized_Other_Phone__c!=null ) Limit 100]);
        
        for(Contact c : contacts){
            contactInfo cInfo = new contactInfo();
            cInfo.id = c.Id;
            cInfo.normalizedPhone = c.Normalized_phone__c;
            cInfo.normalizedMobilePhone = c.Normalized_Mobile_Phone__c;
            cInfo.normalizedOtherPhone = c.Normalized_Other_Phone__c;
            cInfo.activityExists = false;
            if(c.Tasks.size() > 0 || c.Cases.size() > 0 ){
                cInfo.activityExists=true;
            }
            contactList.add(cInfo);
        }
        
        return contactList;
    }
    
    @HttpPost
    global static void  doPost(List<contactUpdateInfo> contactUpdateList) {
        List<Contact> contactList = new List<Contact>();
        for(contactUpdateInfo info : contactUpdateList){
            Contact c = new Contact(Id=info.id);
            if(info.activityExists=='true'){
                c.Dnc_activity_exists__c = true;
            } else {
                c.Dnc_activity_exists__c = false;
            }
            if(info.doNotCall=='true'){
                c.DoNotCall= true; 
            } else {
                c.DoNotCall= false; 
            }
            c.DNC_Validated_Date_Time__c=system.now();  
            contactList.add(c);
        }
        contactTriggerHelper.skipTrigger = true;
        update contactList;
        //return ''+leadUpdateList;
    }
    
    global class contactUpdateInfo{
        global String id;
        global string activityExists;
        global string doNotCall;
    }
    
    global class contactInfo {
        global String id;	
        global String normalizedPhone;	
        global String normalizedOtherPhone;	
        global String normalizedMobilePhone;	
        global boolean activityExists;
    }
}