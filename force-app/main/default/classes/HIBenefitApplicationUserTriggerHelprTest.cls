@isTest
public class HIBenefitApplicationUserTriggerHelprTest {

    @isTest
    static void benefitAdminCreateNewPlan() {
        ZPCompanyTriggerHelper.queue=true;
        
        Account acc = new Account();
        acc.Name = 'test';
        acc.ZP_company_id__c = '11111111111111';
        acc.RecordTypeId=Cache.getRecordTypeId('Account', 'Company');
        insert acc;
        
        ZP_User__c zpUser = new ZP_User__c();
        zpUser.Email__c='test@gusto.com';
        zpUser.Id__c='8888';
        zpUser.Created_At__c =system.today();
        zpUser.Updated_At__c=system.today();
        insert zpUser;
        
        ZP_User_Role__c zpUserRole = new ZP_User_Role__c();
        zpUserRole.User_Id__c='8888';
        zpUserRole.First_Name__c='Test';
        zpUserRole.Last_Name__c='Test';
        insert zpUserRole;
        
    	HI_New_Plans_Application__c hiNewPlansApplicationRec = new HI_New_Plans_Application__c();
    	hiNewPlansApplicationRec.Company_Id__c = '11111111111111';
    	hiNewPlansApplicationRec.External_Key__c = 'Opportunity321';
    	hiNewPlansApplicationRec.Id__c = 'newPlan321';
    	hiNewPlansApplicationRec.Requested_Start_Date__c = system.today();
		insert hiNewPlansApplicationRec;
            
        HIBenefitApplicationUserTriggerHelper.queue=true;
        HI_Benefit_Application_User__c usr = new HI_Benefit_Application_User__c();
        usr.Application_Id__c = 'newPlan321';
        usr.User_Id__c = '8888';
        usr.Id__c = '123';
        usr.Application_Type__c='NewPlansApplication';
        insert usr;
        
        usr=[Select Id, Processing_State__c from HI_Benefit_Application_User__c where Id=:usr.Id];
        //Commented out by David (Dato) Tsamalashvili - 05/31/2019
        //system.assertEquals(IntegrationUtils.PROCESSED_STATE, usr.Processing_State__c);
        
        List<AccountContactRelation> relList = new List<AccountContactRelation>([Select Id, Roles from AccountContactRelation where AccountId=:acc.Id]);
        for(AccountContactRelation rel : relList){
            //Commented out by David (Dato) Tsamalashvili - 05/31/2019
            //system.assert(rel.Roles.IndexOf('Benefits Admin')>-1);
        }
        
        update usr;
        
        delete usr;
    }    
    
    @isTest
    static void benefitAdminCreateBOR() {
        ZPCompanyTriggerHelper.queue=true;
        
        Account acc = new Account();
        acc.Name = 'test';
        acc.ZP_company_id__c = '11111111111111';
        acc.RecordTypeId=Cache.getRecordTypeId('Account', 'Company');
        insert acc;
        
        ZP_User__c zpUser = new ZP_User__c();
        zpUser.Email__c='test@gusto.com';
        zpUser.Id__c='8888';
        zpUser.Created_At__c =system.today();
        zpUser.Updated_At__c=system.today();
        insert zpUser;
        
        ZP_User_Role__c zpUserRole = new ZP_User_Role__c();
        zpUserRole.User_Id__c='8888';
        zpUserRole.First_Name__c='Test';
        zpUserRole.Last_Name__c='Test';
        insert zpUserRole;
        
    	HI_BoR_Transfer__c hiBORRec = new HI_BoR_Transfer__c();
    	hiBORRec.Company_Id__c = '11111111111111';
    	hiBORRec.External_Key__c = 'Opportunity321';
    	hiBORRec.Id__c = 'newBor321';
    	//hiBORRec.Requested_Start_Date__c = system.today();
		insert hiBORRec;
            
        HIBenefitApplicationUserTriggerHelper.queue=true;
        HI_Benefit_Application_User__c usr = new HI_Benefit_Application_User__c();
        usr.Application_Id__c = 'newBor321';
        usr.User_Id__c = '8888';
        usr.Id__c = '123';
        usr.Application_Type__c='BorTransfer';
        insert usr;
        
        usr=[Select Id, Processing_State__c from HI_Benefit_Application_User__c where Id=:usr.Id];
        //Commented out by David (Dato) Tsamalashvili - 05/31/2019
        //system.assertEquals(IntegrationUtils.PROCESSED_STATE, usr.Processing_State__c);
        
        List<AccountContactRelation> relList = new List<AccountContactRelation>([Select Id, Roles from AccountContactRelation where AccountId=:acc.Id]);
        for(AccountContactRelation rel : relList){
            //Commented out by David (Dato) Tsamalashvili - 05/31/2019
            //system.assert(rel.Roles.IndexOf('Benefits Admin')>-1);
        }
        
        update usr;
        
        delete usr;
    }      
}