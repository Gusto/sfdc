@RestResource(urlMapping='/ZPCompany/*') 
global with sharing class ZPCompanyUpdateService {

    @HttpPost
    global static void  doPost(updateInfo updInfo) {
        ZPCompanyTriggerHelper.queue=true;
        ZP_Company__c comp = [Select id,Created_By_Email__c from zp_company__c where id=:updInfo.zpCompanyId];
        if(comp.Created_By_Email__c != null && comp.Created_By_Email__c!=''){
            List<Lead> leadList = new List<Lead>([Select Id, Name, email, isConverted, RecordTypeId, Unique_Email_Address__c, ZP_Company_Lead_ID__c, ZP_Company_ID__c,ConvertedAccountId,ConvertedOpportunityId,ownerid from Lead where isConverted=false and Email = :comp.Created_By_Email__c and RecordTypeId = :Cache.getRecordTypeId('Lead', 'Company')]);
            if(leadList.size()>0){
                ZPCompanyTriggerHelper.updateType='LeadConversion';
                String ownerId = leadList[0].ownerId;
                if(ownerId.indexOf('00G')==0){
                    update leadList[0];
                }
                ZPCompanyTriggerHelper.queue=false;
            }
        }
        update comp;
    }
    
    global class updateInfo {
        global String zpCompanyId;	
        global String AccountId;	
    }
}