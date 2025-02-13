@isTest
private class UR_ManageContactCtrl_Test {
	@TestSetup  
    static void setupData() {
        ContactTriggerHelper.skipTrigger = true;
        AccountTriggerHelper.skipTrigger=true;

        // insert org default tier config settings
        Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
        insert objTierConfig;

        UR_TestDataUtil.createResearchConfig();
        UR_TestDataUtil.createEmailMapping();
        UR_TestDataUtil.createContact(5);
    }
    
    static testMethod void manageContactCtrlTest() {
        ContactTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger=true;
        Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();

        Research_Project_Master__c projectObj = UR_TestDataUtil.createResearchProjectMaster('Test Case 01');
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(projectObj);
        ApexPages.currentPage().getParameters().put('projectId',projectObj.Id);
        UR_ManageContactCtrl controller = new UR_ManageContactCtrl(sc); 
        
		controller.strNameFilter = 'contains';
		controller.strName = 'Test';
        controller.strCompanyName = 'Gusto';
		controller.selIncludeStr = 'AND';
		for(UR_ManageContactCtrl.ContactRole roleObj : controller.includeContactRoleList){
			roleObj.isChecked = true;
		}
        controller.selExcludeStr = 'AND';
		for(UR_ManageContactCtrl.ContactRole roleObj : controller.excludeContactRoleList){
			roleObj.isChecked = true;
		}
        for(UR_ManageContactCtrl.CompanyState stateObj : controller.includeCompanyStateList){
			stateObj.isChecked = true;
		}
        controller.selIncludeStateStr = 'OR';    
        controller.sortbyFieldAPIName = '';
        controller.SearchContact();
        controller.resetAll();

        controller.selIncludeStr = 'OR';
        controller.selExcludeStr = 'OR';
		controller.strCityFilter = 'contains';
		controller.strCity = 'San Diego';
		controller.strState = 'California';
		controller.searchAccount.Joined_Date_Panda__c = Date.today();
        controller.searchAccount.First_Contractor_Payment_Date__c = Date.today().addDays(-2);
        controller.searchAccount1.First_Contractor_Payment_Date__c = Date.today().addDays(2);
        controller.hasMedical = 'Yes';
        controller.hasActivePolicy = 'Yes';
        controller.strNPSScore = '1';
        controller.strNPSScore1 = '5';
        controller.searchTier = objTierConfig.New_Tier_2__c;
        for(UR_ManageContactCtrl.UserReportedIndustry industryObj : controller.userReportedIndustryList){
            industryObj.isChecked = true;
        }
		controller.selIndustryStr = 'Include';
        controller.activeEmployeeFrom = '1';
        controller.activeEmployeeFrom = '30';
        controller.activeContractorFrom = '1';
        controller.activeContractorTo = '30';
        controller.noClientFrom = '1';
        controller.noClientFrom = '20';
        controller.searchSoldThrough = 'Partner - Came to Gusto through Accountant';
        controller.strEmail='TestEmai_1@gmail.com';
        
        controller.selIncludeStateStr = 'AND';
		controller.SearchContact();
    }
	
	static testMethod void addParticipantsTest() {
        ContactTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger=true;
        Research_Project_Master__c projectObj = UR_TestDataUtil.createResearchProjectMaster('Test Case 02');
        List<Contact> contactList = [select id from contact limit 2];
        List<Research_Project_Detail__c> projectDetailList = UR_TestDataUtil.createResearchProjectDetails(contactList, projectObj.Id);
            
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(projectObj);
        ApexPages.currentPage().getParameters().put('projectId',projectObj.Id);
        UR_ManageContactCtrl controller = new UR_ManageContactCtrl(sc); 
        
		controller.strNameFilter = 'contains';
		controller.strName = 'Test';
	
		controller.SearchContact();
        for(UR_ManageContactCtrl.ContactWrapper ctw : controller.lstMainContactWrapper){
                ctw.selContact=true;
        }
        controller.AddContact();
        
        for(UR_ManageContactCtrl.ContactWrapper cw : controller.lstSelectedContactWrapper){
        	cw.selContact=true;
        }
        controller.RemoveContact();
        
        UR_ManageContactCtrl.ContactWrapper cw = new UR_ManageContactCtrl.ContactWrapper();
		cw.objCon=contactList[0];
        
        controller.lstMainContactWrapper.add(cw);
        
        for(UR_ManageContactCtrl.ContactWrapper ctw : controller.lstMainContactWrapper){
                ctw.selContact=true;
        }
        controller.AddContact();
        controller.SaveContact();
        controller.extraNOP = '20';
        controller.SendApprovalRequest();
        controller.RedirectToUploadCSV();
        controller.BackToManageContact();
        controller.BackToProjectVF();
        controller.getTotalRecord();
        controller.getTotalPages();
        controller.first();
        controller.last();
        controller.previous();
        controller.next();
        controller.populateSelectedparticipant(true);
        controller.sortSearchContactList();
        controller.selSortManageContactList();
        controller.HideFilter();
        controller.hideAddtionalFilter();
        UR_UtilityCtrl.RetriveProjectDetail(projectObj.Id + '');
	}
    
    static testMethod void emailMappingTest() {
        ContactTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger=true;
    	UR_EmailMappingCtrl Obj = new UR_EmailMappingCtrl();
        obj.getPopulateCTAStatusPicklist();
        obj.selectedStatus = 'Send survey or screener';
        for(UR_EmailMappingCtrl.EmailTemplateWrapper etw : obj.EmailTemplateWrapperList){
            etw.selct = true;
        }
        obj.CreateStatusTemplate();        
        obj.selectstatus();
        obj.CreateNewTemplate();
    }
       
    static testMethod void getSubQueryFilterTest() {
        ContactTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger=true;
    	UR_UtilityCtrl.createSearchString('String', 'equals', 'Name', 'Test');
        UR_UtilityCtrl.createSearchString('String', 'not equal to', 'Name', 'Test');
        UR_UtilityCtrl.createSearchString('String', 'contains', 'Name', 'Test');
        UR_UtilityCtrl.createSearchString('String', 'does not contain', 'Name', 'Test');
        UR_UtilityCtrl.createSearchString('String', 'start with', 'Name', 'Test');
         
        UR_UtilityCtrl.createSearchString('Date', 'equals', 'Name', Date.today(), Date.today());
        UR_UtilityCtrl.createSearchString('Date', 'not equal to', 'Name', Date.today(), Date.today());
        UR_UtilityCtrl.createSearchString('Date', 'less than', 'Name', Date.today(), Date.today());
        UR_UtilityCtrl.createSearchString('Date', 'greater or equal', 'Name', Date.today(), Date.today());
        UR_UtilityCtrl.createSearchString('Date', 'between', 'Name', Date.today(), Date.today());
        
        UR_UtilityCtrl.createSearchString('Number', 'equals', 'Name', 2);
        UR_UtilityCtrl.createSearchString('Number', 'not equal to', 'Name', 2);
        UR_UtilityCtrl.createSearchString('Number', 'less than', 'Name', 2);
        UR_UtilityCtrl.createSearchString('Number', 'greater than', 'Name', 2);
        UR_UtilityCtrl.createSearchString('Number', 'less or equal', 'Name', 2);
        UR_UtilityCtrl.createSearchString('Number', 'greater or equal', 'Name', 2);
    }
    
    static testMethod void createCalendlyDataTest() {
        ContactTriggerHelper.skipTrigger = true; 
		AccountTriggerHelper.skipTrigger=true;
        List<Contact> contactList =[Select id, Email from Contact where Email Like 'TestEmail_%'];
        Research_Project_Master__c projectObj = UR_TestDataUtil.createResearchProjectMaster('Test Case 03');
        projectObj = [select id, Name , Project_Id__c from Research_Project_Master__c where id=:projectObj.id limit 1];
	    List<Research_Project_Detail__c> participantList = UR_TestDataUtil.createProjectParticipantTest(projectObj, contactList); 
        UR_TestDataUtil.addTeamMember(projectObj, UserInfo.getUserId(), true, true, true);

        UR_TestDataUtil.createResearchIntegrationData(projectObj.Project_Id__c, participantList[0].Id, 'Calendly Data');
        Research_Integration_Data__c obj = UR_TestDataUtil.createResearchIntegrationData(projectObj.Project_Id__c, participantList[0].Id, 'Calendly Data');    
    }
    
    static testMethod void createSurveyResponseTest() {
        ContactTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger=true;
        List<Contact> contactList =[Select id, Email from Contact where Email Like 'TestEmail_%'];
        Research_Project_Master__c projectObj = UR_TestDataUtil.createResearchProjectMaster('Test Case 03');
        projectObj = [select id, Name , Project_Id__c from Research_Project_Master__c where id=:projectObj.id limit 1];
        
	    List<Research_Project_Detail__c> participantList = UR_TestDataUtil.createProjectParticipantTest(projectObj, contactList); 
        UR_TestDataUtil.addTeamMember(projectObj, UserInfo.getUserId(), true, true, true);
        
        Research_Integration_Data__c obj = UR_TestDataUtil.createSurveyResponseDataTest(projectObj.Project_Id__c, participantList[0].Id, 'Survey Response');
        Research_Survey__c objSurvey = [Select id from Research_Survey__c limit 1];
        if(objSurvey!=null){
            update objSurvey;
            delete objSurvey;
        }
        if(obj!=null){
            update obj;
            delete obj;
        }
        
    }

}