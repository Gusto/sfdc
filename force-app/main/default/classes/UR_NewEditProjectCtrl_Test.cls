@isTest
private class UR_NewEditProjectCtrl_Test {
 
    static testMethod void createNewResearchProject() {
        ContactTriggerHelper.skipTrigger = true;
        AccountTriggerHelper.skipTrigger=true;
        Contact objContact = new Contact(LastName = 'con last name ',
                                        Email = UserInfo.getUserEmail());
        insert objContact;
        UR_TestDataUtil.createResearchConfig();
        Research_Project_Master__c projectObj = UR_TestDataUtil.createResearchProjectMaster('Test Case');
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(projectObj);
        ApexPages.currentPage().getParameters().put('id',projectObj.Id);
        ApexPages.currentPage().getParameters().put('st','ct');
        UR_NewEditProjectCtrl controller = new UR_NewEditProjectCtrl(sc); 
        controller.nextFromProject();
        
        controller.saveProjectMaster();
        controller.editProject();
        controller.backToProject();
        controller.editProjectTeam();
        controller.cancelProject();
        controller.addTeamMember();      
        controller.projectTeamMap.put(1,UR_TestDataUtil.addTeamMember(projectObj, UserInfo.getUserId(), true, true, true));
        controller.saveTeamMember();
        controller.saveProject();
        controller.CompleteProjectMsg(); 
        controller.addParticipants();
        
        UR_NewEditProjectCtrl controller1 = new UR_NewEditProjectCtrl(sc); 
        ApexPages.currentPage().getParameters().put('st','ct1');
        controller1.deleteRowIndex = 1;
        controller1.deleteTeamMember();
        
        Date startDate = Date.today();
        Date endDate = startDate.addDays(-2);
        Research_Project_Master__c projectObj1 = new Research_Project_Master__c();
        ApexPages.Standardcontroller sc1 = new ApexPages.Standardcontroller(projectObj1);
        UR_NewEditProjectCtrl controller2 = new UR_NewEditProjectCtrl(sc1); 
        controller2.projectMaster=new Research_Project_Master__c();
        controller2.checkRequiredField();
        controller2.projectMaster.Name = 'Test new UX Project';  
        controller2.checkRequiredField();
        controller2.projectMaster.Project_Start_Date__c = startDate;
        controller2.checkRequiredField();
        controller2.projectMaster.Project_End_Date__c = endDate;
        controller2.checkRequiredField();
        endDate = endDate.addDays(10);
        controller2.checkRequiredField();
        controller2.projectMaster.Project_End_Date__c = endDate;
        controller2.checkRequiredField();
        controller2.projectMaster.Type_of_Research__c = UR_NewEditProjectCtrl.MODERATED_REMOTE_INTERVIEW;
        controller2.checkRequiredField();
        controller2.projectMaster.Type_of_people_are_you_hoping_to_contact__c = 'All';
        controller2.checkRequiredField();
        controller2.projectMaster.Description__c = 'Test Description';
        controller2.checkRequiredField();
        controller2.projectMaster.Number_of_Participants_to_Add_to_Project__c = '4';
        controller2.checkRequiredField();
        controller2.projectMaster.Plan_to_offer_incentives__c = 'Test Description';
        controller2.checkRequiredField();
        
        projectObj.Additional_Participant_Status__c = 'Approved';
        projectObj.Number_of_Expected_Participant__c = 10;
        update projectObj;
        
        Research_Project_Master__c tempProjectObj = UR_TestDataUtil.createResearchProjectMaster('Test Case Temp'); 
        delete tempProjectObj;
            
        UR_TriggerHelper ug=new UR_TriggerHelper();
    }
}