/*
 * To unit test the functionality in OnboardingAdvocateViewCtrl
 */
@isTest
private class OnboardingAdvocateViewCtrlTest {
    /*
     * Test data
     */
     @testSetup
     private static void setupTestData(){
     	User objAdminUser = new TestDataFactory.UserBuilder()
			.setUserName('Implementation.Advocate@test.Implementation')
			.setExemptfromValidationRules(true)
			.setEmail('mdruser@testorg.com')
			.setProfileId(UserInfo.getProfileId())
			.build();  

        insert objAdminUser;
     	
     	AccountTriggerHelper.skipTrigger = true;
     	OpportunityTriggerHelper.skipTrigger = true;
        Opportunity opp1 = TestUtility.BenefitsNewPlanOpportunity();
        OrderTriggerHelper.skipTrigger = true;
        Benefit_Order__c benefitOrdr1 = TestUtility.createTestBenefitOrder('New Plan', opp1.Id, 'Test Benefit Order',true);
         
        CarrierOrderTriggerHelper.skipTrigger = true;
        Carrier__c testCarrier1 = TestUtility.Carrier();
        
        List<Carrier_Order__c> lstCO = new List<Carrier_Order__c>();
        lstCO.add( new Carrier_Order__c( 	Name = 'TEST CARRIER ORDER1',
        									Carrier__c = testCarrier1.Id,
        									Benefit_Order__c = benefitOrdr1.Id,
        									Order_Type__c = 'New to Gusto'));
        insert lstCO;
        
        List<Case> lstCase = new List<Case>();
        lstCase.add(new Case(	RecordTypeId = cache.getRecordTypeId('Case', 'Benefits Change Case'),
        						AccountId = opp1.AccountId,
        						Subject = 'Test case 1',
        						Description='Test',
        						Type = 'Carrier Submission',
        						Carrier_Order__c = lstCO[0].Id,
        						Benefit_Order__c = benefitOrdr1.Id
        						));
        insert lstCase;
        
        Order ord = new Order();
        ord.AccountId = opp1.AccountId;
        ord.OpportunityId = opp1.Id;
        ord.Active_Employee_Count__c = 10;
        ord.EffectiveDate =System.today();
        ord.Status='Drafted';
        insert ord;
        TicketTriggerHelper.skipTrigger =true;
        List<Ticket__c> lstTkt = new List<Ticket__c>();
        
        lstTkt.add(new Ticket__c(	Order__c = ord.Id,
        							RecordTypeId = Cache.getRecordTypeId('Ticket__c','Benefits Onboarding NewPlans'),
        							Status__c = 'New',
        							Priority__c = 'Low',
        							Benefit_Order__c = benefitOrdr1.Id
        							));
		insert lstTkt;

		//custom setting
		insert new Configuration_Settings__c(OADefaultBOColumns__c = 'Name;Type__c;Order_Status__c;Follow_Up_Date__c;Submission_Deadline__c;Open_Enrollment_End_Date__c;Coverage_Effective_Date__c;Requires_Action__c;Follow_Up_Notes__c;Has_TADA__c',
											OADefaultBOProcessStepsColumns__c='Order_Status__c;Days_In_Current_Status__c;Follow_Up_Date__c;Follow_Up_Notes__c;Open_Enrollment_End_Date__c;Submission_Deadline__c;Name;Type__c;Coverage_Effective_Date__c;Opportunity_Owner__c;Filing_State__c',
											OADefaultCOColumns__c = 'Name;Benefit_Order__c;Implementation_Stage__c;Stage_Detail__c;Order_Assignment__c;Submission_Deadline_Date__c;Follow_Up_Date__c;Benefit_Order__r.Order_Status__c');
    }

	/*
	 * Unit Test For Action View
     */
	@isTest
	private static void testActionViewPositive(){
      	test.startTest();
      		Benefit_Order__c boObj = [Select Id From Benefit_Order__c LIMIT 1];
      		OnboardingAdvocateViewCtrl OACtrl = new OnboardingAdvocateViewCtrl(new ApexPages.StandardController(boObj));
      		OACtrl.CallOnOnboardingAdvocateActionView();
      		OACtrl.ShowCustomerCommunication();
      		OACtrl.ShowCarrierCommunication();
      		OACtrl.ShowTicketOwnedByMe();
      		OACtrl.ShowClosedTicket();
      		OACtrl.ShowCancelTerminated();
      		
      		Case objCase = [SELECT Id FROM Case LIMIT 1];
      		ApexPages.CurrentPage().getparameters().put('strCaseId',objCase.Id);
      		OACtrl.updateRequireStatus();
      		
      		system.assert(OACtrl.lstBOStatsWrapper.size() == 0);
      	test.stopTest();	
	}
	/*
	 * Unit Test For Action View Negative
     */
	@isTest
	private static void testActionViewNEgative(){
      	test.startTest();
      		Benefit_Order__c boObj = [Select Id From Benefit_Order__c LIMIT 1];
      		OnboardingAdvocateViewCtrl OACtrl = new OnboardingAdvocateViewCtrl(new ApexPages.StandardController(boObj));
      		
      		OACtrl.objBenefitOrder.Coverage_Effective_Date__c = null;
      		OACtrl.CallOnOnboardingAdvocateActionView();
			
			system.assert(OACtrl.lstBOStatsWrapper.size() == 0);
      	test.stopTest();	
	}
	/*
	 * Unit Test For Cohort View
     */
	@isTest
	private static void testCohortViewPositive(){
      	test.startTest();
      		Benefit_Order__c boObj = [Select Id,Coverage_Effective_Date__c From Benefit_Order__c LIMIT 1];

      		OnboardingAdvocateViewCtrl OACtrl = new OnboardingAdvocateViewCtrl(new ApexPages.StandardController(boObj));
      		OACtrl.CallOnOnboardingAdvocateCohortView();
      		OACtrl.createFilterJSON();
      		
      		OACtrl.currentObjName = 'Benefit_Order__c';
      		OACtrl.currentView = 'OA Cohort';
      		OACtrl.savePreference();
      		
      		system.assert(OACtrl.lstBOCohortView.size() == 0);
      	test.stopTest();	
	}
	/*
	 * Unit Test For Cohort View
     */
	@isTest
	private static void testCohortViewNegative(){
      	test.startTest();
      		Benefit_Order__c boObj = [Select Id From Benefit_Order__c LIMIT 1];
      		OnboardingAdvocateViewCtrl OACtrl = new OnboardingAdvocateViewCtrl(new ApexPages.StandardController(boObj));
      		
      		OACtrl.CallOnOnboardingAdvocateCohortView();
      		
      		OACtrl.lstBOCohortView = new List<OnboardingAdvocateViewCtrl.ProcessStepsWrapper>();
      		OACtrl.objBenefitOrder.Coverage_Expiration_Date__c = system.today();
      		OACtrl.objBenefitOrder.Follow_Up_Date__c =  system.today() - 10;
      		OACtrl.showBO();
      		system.assert(OACtrl.lstBOCohortView.size() == 0);
		    OACtrl.objBenefitOrder.Follow_Up_Date__c = system.today();
      		OACtrl.objBenefitOrder.Coverage_Expiration_Date__c =  system.today() - 10;  		
      		OACtrl.objBenefitOrder.Unblocked_Date__c = system.today(); 
      		OACtrl.objBenefitOrder.End_Date__c = system.today() - 10;
      		OACtrl.showBO();
      		
      		OACtrl.objBenefitOrder.Unblocked_Date__c = system.today() -30; 
      		OACtrl.objBenefitOrder.End_Date__c = system.today() - 40;
      		OACtrl.objBenefitOrder.Follow_Up_Date__c = system.today()-30;
      		OACtrl.objBenefitOrder.Coverage_Expiration_Date__c =  system.today() - 10;  
      		OACtrl.showBO();
      		
      		
      		OACtrl.currentObjName = 'Benefit_Order__c';
      		OACtrl.currentView = 'OA Cohort';
      		OACtrl.mapLstSelectedFields.put('OA Cohort Benefit_Order__c', new List<String>());
      		OACtrl.savePreference();
      		
      		OACtrl.mapLstSelectedFields.put('OA Cohort Benefit_Order__c', new List<String>{'1','2','3','4','5','6','7','8','9','10','11'});
      		OACtrl.savePreference();
      	test.stopTest();	
	}
	/*
	 * Unit Test For Cohort View
     */
	@isTest
	private static void testBusinessViewPositive(){
      	test.startTest();
      		Benefit_Order__c boObj = [Select Id From Benefit_Order__c LIMIT 1];
      		OnboardingAdvocateViewCtrl OACtrl = new OnboardingAdvocateViewCtrl(new ApexPages.StandardController(boObj));
      		OACtrl.callOnOnboardingAdvocateBusinessView();
      		
      		system.assert(OACtrl.lstBOBusinessView.size() > 0);
      	test.stopTest();	
	}

	@isTest
	private static void testBusinessViewNegative(){
      	test.startTest();
      		User adminUser = [Select Id From User Where Username = 'Implementation.Advocate@test.Implementation'];
      		system.runAs(adminUser){
	      		Benefit_Order__c boObj = [Select Id From Benefit_Order__c LIMIT 1];
	      		OnboardingAdvocateViewCtrl OACtrl = new OnboardingAdvocateViewCtrl(new ApexPages.StandardController(boObj));
      			OACtrl.callOnOnboardingAdvocateBusinessView();
      			
      			system.assert(OACtrl.lstBOBusinessView.size() == 0);
      		}
      	test.stopTest();	
	}
}