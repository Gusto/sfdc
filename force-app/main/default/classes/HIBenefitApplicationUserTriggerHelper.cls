public with sharing class HIBenefitApplicationUserTriggerHelper extends TriggerHandler {
    
    public static boolean skipTrigger = false;
    public static boolean queue=true;
    
    public HIBenefitApplicationUserTriggerHelper() {
		super('HIBenefitApplicationUserTriggerHelper');
	}

    public override void beforeInsert() {
        List<HI_Benefit_Application_User__c> newBenefitAppUserList = (List<HI_Benefit_Application_User__c>) Trigger.new;
        if(queue == true){
                processInformation(newBenefitAppUserList);
        } else {
            for(HI_Benefit_Application_User__c  application : newBenefitAppUserList){
                application.Processing_State__c=IntegrationUtils.QUEUED_STATE;
            }
        }
    }

    public override void beforeUpdate() {
        List<HI_Benefit_Application_User__c> newBenefitAppUserList = (List<HI_Benefit_Application_User__c>) Trigger.new;

        if(queue == true){             
                processInformation(newBenefitAppUserList);            
        } else {
            for(HI_Benefit_Application_User__c  application : newBenefitAppUserList){
                application.Processing_State__c=IntegrationUtils.QUEUED_STATE;
            }
        }
    }

    private void processInformation(List<HI_Benefit_Application_User__c> applicationList){
        List<HI_Benefits_Admin__c> benefitsAdminList = new List<HI_Benefits_Admin__c>();
        Set<String> newPlanSet = new Set<String>();
        Set<String> borTransferSet = new Set<String>();
        for(HI_Benefit_Application_User__c applicationUser : applicationList){
            if(applicationUser.Application_Type__c=='NewPlansApplication'){
                newPlanSet.add(applicationUser.Application_Id__c);
            } else if(applicationUser.Application_Type__c=='BorTransfer'){
                borTransferSet.add(applicationUser.Application_Id__c);
            }
        }
        map<String,String> newPlanIdCompanyIdMap = new map<String,String>();
        map<String,String> borIdCompanyIdMap = new map<String,String>();
        if(newPlanSet.size()>0){
        	newPlanIdCompanyIdMap = getNewPlanIdCompanyIdMap(newPlanSet);
        }
        if(borTransferSet.size()>0){
        	borIdCompanyIdMap = getBorTransferIdCompanyIdMap(borTransferSet);
        }
            
        for(HI_Benefit_Application_User__c applicationUser : applicationList){
            if(applicationUser.Processing_State__c==IntegrationUtils.DEAD_STATE){
                continue;
            }
            HI_Benefits_Admin__c benAdmin = new HI_Benefits_Admin__c();
            benAdmin.Id__c=applicationUser.Application_Type__c+'-'+applicationUser.Application_Id__c;
            benAdmin.ZP_User_Id__c = applicationUser.User_Id__c;
            if(applicationUser.Application_Type__c=='NewPlansApplication'){
                if(newPlanIdCompanyIdMap.containsKey(applicationUser.Application_Id__c)){
                    benAdmin.Company_Id__c = newPlanIdCompanyIdMap.get(applicationUser.Application_Id__c);
                } 
            } else if(applicationUser.Application_Type__c=='BorTransfer'){
                if(borIdCompanyIdMap.containsKey(applicationUser.Application_Id__c)){
                    benAdmin.Company_Id__c = borIdCompanyIdMap.get(applicationUser.Application_Id__c);
                }
            }
            benefitsAdminList.add(benAdmin);
        }

        if(benefitsAdminList.size()>0){
            HIBenefitsAdminTriggerHelper.Queue=true;
            HIBenefitsAdminTriggerHelper benAdminHelper = new HIBenefitsAdminTriggerHelper();
            benAdminHelper.processInformation(benefitsAdminList);
            map<String,HI_Benefits_Admin__c> benAdminResultMap = new map<String,HI_Benefits_Admin__c>();
            for(HI_Benefits_Admin__c admin: benefitsAdminList){
                benAdminResultMap.put(admin.Id__c, admin);
            }
            for(HI_Benefit_Application_User__c applicationUser : applicationList){
                if(applicationUser.Processing_State__c==IntegrationUtils.DEAD_STATE){
                    continue;
                }
                HI_Benefits_Admin__c admin = benAdminResultMap.get(applicationUser.Application_Type__c+'-'+applicationUser.Application_Id__c);
                setProcessingState(admin.Processing_State__c,admin.Message__c,applicationUser);
            }
        }
    }

    private map<String,String> getNewPlanIdCompanyIdMap(Set<String> idSet){
        map<String,String> newPlanIdCompanyIdMap = new map<String,String>();
        for(HI_New_Plans_Application__c application : [Select Id,Company_id__c, Id__c from HI_New_Plans_Application__c where Id__c in : idSet]){
            newPlanIdCompanyIdMap.put(application.Id__c,application.Company_Id__c);
        }
        return newPlanIdCompanyIdMap;
    }
    
    private map<String,String> getBorTransferIdCompanyIdMap(Set<String> idSet){
        map<String,String> borTransferCompanyIdMap = new map<String,String>();
        for(HI_BoR_Transfer__c  application : [Select Id,Company_id__c, Id__c from HI_BoR_Transfer__c  where Id__c in : idSet]){
            borTransferCompanyIdMap.put(application.Id__c,application.Company_Id__c);
        }
        return borTransferCompanyIdMap;
    }

    // populating HI_State_carrier__c object fields
    private HI_Benefit_Application_User__c setProcessingState(String ProcessingState, String message, HI_Benefit_Application_User__c application){
        application.Processing_State__c = ProcessingState;
        application.Message__c = message;
        application.Last_Processed__c=System.now();
        return application;
    }
}