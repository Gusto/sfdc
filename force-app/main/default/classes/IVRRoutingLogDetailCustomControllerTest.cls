/**
* @name         IVRRoutingLogDetailCustomControllerTest
* @author       Sanjay Paryani
* @date         10/25/2019
* @description  Test class for IVRRoutingLogDetailCustomController
* @revisions    Date ------------ Name ------------ Comments 
*				11/05/2019		  SanjayP			Added method skipAndSaveTest() to test for skipAndSave() method functionality.
**/
@isTest
private class IVRRoutingLogDetailCustomControllerTest {
    

    @testSetup static void testData() {
        Account acc = TestUtility.CompanyAccount();
        List<User> list_Users = TestUtility.createUsers('ZP System Administrator',1);
		insert list_Users;
            
        test.startTest();
	        Case cse = new Case();
	        //cse.RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care');
	        cse.AccountId = acc.Id;
	        cse.Subject='Test';
	        cse.Description='Test';
	        cse.Type='QLE';
        	cse.OwnerId = list_Users.get(0).Id;
        	cse.Confirm_Case_Reason__c  = 'test reason';
	        insert cse;
        	
        	IVR_Intent_Grouping__c igp = new IVR_Intent_Grouping__c();
        	igp.Name = 'TAdA Questions';
            igp.Intent_Code__c = 'TAdA_Questions';  
        	igp.Skill__c = 'Benefits Class 2';
       	 	insert igp;
        
            IVR_Routing_Log__c ivr = new IVR_Routing_Log__c();
            ivr.Lex_Transcript__c = 'I need help with Benefits';
            ivr.IVR_Intent_Grouping__c = igp.Id;
            ivr.OwnerId = list_Users.get(0).Id;
            ivr.Correct_Intent_Grouping__c = igp.Id;
            ivr.Case__c = cse.Id;
            ivr.Utterance__c = 'I need help with Benefits';
            ivr.Approved__c = 'No';
            ivr.Transcript_Reviewed__c = false;
        	ivr.isIVRinPlay__c = false;
        	ivr.Bot_Review_Skipped__c = false;
            ivr.ConversationId__c = 'd3e6c99f-2095-4999-8a65-5a65a6855cbf';
            insert ivr;
        
        test.stopTest();
    }
    
    @isTest static void playModeFunctionalityTest() {
        IVR_Routing_Log__c ivr = new IVR_Routing_Log__c();
        list<IVR_Routing_Log__c> ivrList = new list<IVR_Routing_Log__c>();
        ivrList  = [SELECT 	Bot_Review_Skipped__c,
                            Case_Reason__c,
                            isIVRinPlay__c,
                            IVR_Intent_Grouping__r.Name,
                            Case_Skill__c,
                            Skill__c,
                            CreatedDate,
                            Type__c,
                            ConversationId__c,
                            Tree_Input__c,
                            CIP_Queue_Name__c,
                            CIP_Auth__c,
                            Company_Name__c,
                            CIP_Customer_Name__c,
                            Lex_Transcript__c,
                            Id,
                            IVR_Intent_Grouping__c,
                            OwnerId,
                            Call_Recording__c,
                            Correct_Intent_Grouping__c,
                            Case__c,
                            Case__r.CaseNumber,
                            Utterance__c,
                            Approved__c,
                            Name,
                            Correct_Intent_Grouping__r.Name
                    FROM 	IVR_Routing_Log__c
                   ];
         
            IVR_Routing_Log__c ivrLogRecord = new IVR_Routing_Log__c();   
            
        //apexPages.StandardSetController sc = new apexPages.StandardSetController(caseList);
        IVRRoutingLogDetailCustomController controller  = new IVRRoutingLogDetailCustomController();
        //play functionality check
        controller.currentIVRRLogId = ivrList.get(0).id;
        //list<IVR_Routing_Log__c> tempCaseList = controller.ivrList;
        controller.getIVRDetail();       
        controller.startPlay();        
        //system.assert(controller.isPlay == true); //isPlay boolean value check
        
        controller.cancelUpdate();
        system.assert(controller.isPlay == false);
        controller.getIVRQueueList();
        
        controller.startPlay();         

        //saveNext functionality check 
        controller.selectedIVRRLog =  ivrLogRecord;              
        controller.selectedIVRRLog.Approved__c = 'Yes'; 
        string ivrId = controller.selectedIVRRLog.id;
        controller.saveNextRecord();
    }

    @isTest static void playModeFunctionalityTest_case2() {
        IVR_Routing_Log__c ivr = new IVR_Routing_Log__c();
        list<IVR_Routing_Log__c> ivrList = new list<IVR_Routing_Log__c>();

        ivrList  = [SELECT 	Bot_Review_Skipped__c,
                            Case_Reason__c,
                            isIVRinPlay__c,
                            IVR_Intent_Grouping__r.Name,
                            Case_Skill__c,
                            Skill__c,
                            CreatedDate,
                            Type__c,
                            ConversationId__c,
                            CIP_Queue_Name__c,
                            CIP_Auth__c,
                            CIP_Customer_Name__c,
                            Lex_Transcript__c,
                            Id,
                            IVR_Intent_Grouping__c,
                            OwnerId,
                            Call_Recording__c,
                            Correct_Intent_Grouping__c,
                            Case__c,
                            Case__r.CaseNumber,
                            Utterance__c,
                            Approved__c,
                            Name,
                            Correct_Intent_Grouping__r.Name
                    FROM 	IVR_Routing_Log__c
                   ];
         
            IVR_Routing_Log__c ivrLogRecord = new IVR_Routing_Log__c();   
            
        //apexPages.StandardSetController sc = new apexPages.StandardSetController(caseList);
        IVRRoutingLogDetailCustomController controller  = new IVRRoutingLogDetailCustomController();
        //play functionality check
        controller.currentIVRRLogId = ivrList.get(0).id;
        controller.isPlay = true;
        //controller.isSkipped = true;        
        controller.selectedQueueId = '1';
        //controller.alreadyPlayedIVRRLogIdSet.clear();
        User usr = [SELECT Id From User WHERE FirstName = 'test' AND Lastname = 'usr'].get(0);
        system.runAs(usr) {
        	controller.getIVRDetail();     
            controller.startPlay();        
            controller.cancelUpdate();
            system.assert(controller.isPlay == false);
            controller.getIVRQueueList();
            controller.startPlay();         
            //saveNext functionality check 
            controller.selectedIVRRLog =  ivrLogRecord;              
            controller.selectedIVRRLog.Approved__c = 'Yes'; 
            string ivrId = controller.selectedIVRRLog.id;
            controller.saveNextRecord();
        }
    }  
    
    @isTest static void skipAndSaveTest() {            
        IVR_Routing_Log__c ivr = new IVR_Routing_Log__c();
        list<IVR_Routing_Log__c> ivrList = new list<IVR_Routing_Log__c>();
        ivrList  = [SELECT 	Bot_Review_Skipped__c,
                            Case_Reason__c,
                            isIVRinPlay__c,
                            IVR_Intent_Grouping__r.Name,
                            Case_Skill__c,
                            Skill__c,
                            CreatedDate,
                            Type__c,
                            ConversationId__c,
                            CIP_Queue_Name__c,
                            CIP_Auth__c,
                            Company_Name__c,
                            CIP_Customer_Name__c,
                            Lex_Transcript__c,
                            Id,
                            IVR_Intent_Grouping__c,
                            OwnerId,
                            Call_Recording__c,
                            Correct_Intent_Grouping__c,
                            Case__c,
                            Case__r.CaseNumber,
                            Utterance__c,
                            Approved__c,
                            Name,
                            Correct_Intent_Grouping__r.Name
                    FROM 	IVR_Routing_Log__c
                   ];
         
            IVR_Routing_Log__c ivrLogRecord = new IVR_Routing_Log__c();   
            
        //apexPages.StandardSetController sc = new apexPages.StandardSetController(caseList);
        IVRRoutingLogDetailCustomController controller  = new IVRRoutingLogDetailCustomController();
        //play functionality check
        controller.currentIVRRLogId = ivrList.get(0).id;
        //list<IVR_Routing_Log__c> tempCaseList = controller.ivrList;
        controller.getIVRDetail();       
        controller.startPlay();        

        controller.selectedIVRRLog =  ivrLogRecord;              
        controller.selectedIVRRLog.Approved__c = 'Yes'; 
        controller.skipAndSave();    
    }
    
}