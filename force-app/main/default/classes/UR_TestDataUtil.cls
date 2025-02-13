public with sharing class UR_TestDataUtil{

    public static Research_Configuration__c createResearchConfig() {
        Research_Configuration__c configObj = new Research_Configuration__c();
        List<Research_Configuration__c> configObjList = [Select Max_Incentive_of_Current_Year__c, Administrator_1__c, Days_Since_Last_Contact_High_Limit__c, Days_Since_Last_Contact_Low_Limit__c, Max_Number_Of_Participants_High_Limit__c, Min_Number_Of_Participants_Low_Limit__c, Qualitative_Survey_Participated_Blackout__c, Quantitative_Survey_Participated_Blackou__c from Research_Configuration__c limit 1];
        if(configObjList.size()>0){
            configObj = configObjList[0]; 
        }else{
            configObj.Administrator_1__c  = 'test@gusto.com';
            configObj.Days_Since_Last_Contact_High_Limit__c  = 90;
            configObj.Days_Since_Last_Contact_Low_Limit__c = 60;
            configObj.Max_Number_Of_Participants_High_Limit__c = 500;
            configObj.Max_Number_Of_Studies_Participants__c=200;
            configObj.Min_Number_Of_Participants_Low_Limit__c = 1;
            configObj.Qualitative_Survey_Participated_Blackout__c = 10;
            configObj.Quantitative_Survey_Participated_Blackou__c   = 30;
            configObj.Max_Incentive_of_Current_Year__c = 500;
            insert configObj;
        }
        return configObj;
    }
    
    public static Research_Project_Master__c createResearchProjectMaster(String projectName){
        Date startDate = Date.today();
        Date endDate = startDate.addDays(5);
        Research_Project_Master__c projectObj = new Research_Project_Master__c();
        projectObj.Name = projectName;        
        projectObj.Project_Start_Date__c = startDate;
        projectObj.Project_End_Date__c = endDate;
        projectObj.Type_of_Research__c = UR_NewEditProjectCtrl.MODERATED_REMOTE_INTERVIEW;
		projectObj.Type_of_people_are_you_hoping_to_contact__c = 'All';
		projectObj.Number_of_Participants_to_Add_to_Project__c = '20';
		projectObj.Number_of_Allowed_Participant__c = 50;
		projectObj.Plan_to_offer_incentives__c = 'Yes, we plan to offer Gusto swag';
        projectObj.Description__c = 'Test Description';
        projectObj.Incentive_Amount__c = 5;
        projectObj.Screener_URL__c = 'https://gusto.az1.qualtrics.com/jfe/form/SV_6JrTfBbk6RLAImx?sID=';
        projectObj.Uploaded_CSV_Column__c = 8;
        insert projectObj;
       
        return projectObj;
    }
    
    public static void createResearchUploadInfoList(Id projectId){
        List<UXR_CSV_Staging__c> csvList = new List<UXR_CSV_Staging__c>();
        UXR_CSV_Staging__c csvObj = new UXR_CSV_Staging__c(Research_Project_Master__c=projectId,First_Name__c='first_name',Last_Name__c='last_name',Email__c='email',Company_Id__c='Company_Id__c',User_Id__c='user_id',Employee_Id__c='employee_id', Accountant_Firm_Id__c='accounting_firm_id',CSV_Header__c=true,Status__c='Pending',Message__c='Error Message', UXR_CSV_Column1__c='Role');
		csvList.add(csvObj);
        
		UXR_CSV_Staging__c csvObj1 = new UXR_CSV_Staging__c(Research_Project_Master__c=projectId,First_Name__c='Test',Last_Name__c='user1',Email__c='TestEmail_0@gmail.com',Company_Id__c='33001',User_Id__c='44001',Employee_Id__c='55001', Accountant_Firm_Id__c='',CSV_Header__c=false,Status__c='Pending',Message__c='', UXR_CSV_Column1__c='Test');
		csvList.add(csvObj1);
		
		UXR_CSV_Staging__c csvObj2 = new UXR_CSV_Staging__c(Research_Project_Master__c=projectId,First_Name__c='Test',Last_Name__c='user2',Email__c='Test.user+user22@lirik.io',Company_Id__c='33002',User_Id__c='44002',Employee_Id__c='100041', Accountant_Firm_Id__c='',CSV_Header__c=false,Status__c='Pending',Message__c='', UXR_CSV_Column1__c='Test');
		csvList.add(csvObj2);
		
        insert csvList;
		csvObj1.Status__c='Processed';
		csvObj2.Status__c='Processed';
        
		update csvList;
    }
    
    public static Research_Project_Teams__c addTeamMember(Research_Project_Master__c projectMasterObj, Id userObjId, Boolean editAccess, Boolean inviteForInterView, Boolean projectCreator){
        Research_Project_Teams__c teamMember = new Research_Project_Teams__c();
        if(projectMasterObj.id!=null && userObjId!=null){
            teamMember.Edit_Access__c = editAccess;
            teamMember.Invite_for_Interviews__c = inviteForInterView;
            teamMember.Research_Project_Master__c = projectMasterObj.Id;
            teamMember.User__c = userObjId;
            teamMember.Project_Creator__c = projectCreator;
            insert teamMember;
        }
        return teamMember; 
    }
    
    public static List<Research_Project_Detail__c> createResearchProjectDetails(List<Contact> contactList, Id projectId){
        List<Research_Project_Detail__c> projectDetailList = new List<Research_Project_Detail__c>();
        for(Contact con : contactList){
            Research_Project_Detail__c prd=new Research_Project_Detail__c();
            prd.Research_Project_Master__c=projectId;
            prd.Comment__c='Test Comment';
            prd.Contact__c=con.Id;
            prd.Research_Participant_Status__c='Reserved';
            prd.Added_by_CSV__c = false;
            projectDetailList.add(prd);
        }
        insert projectDetailList;
        
        return projectDetailList;
    }
    
    public static List<Contact> createContact(Integer totalContact){
        Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();

        Map<String, Id> contactRecordTypeMap =  new Map<String, Id>();
        for(RecordType rObj : [SELECT Id, sObjectType FROM RecordType WHERE DeveloperName = 'Company' and (sObjectType='Contact' or sObjectType='Account')]){
            contactRecordTypeMap.put(rObj.sObjectType, rObj.Id);
        }
        
        Account accountObj = new Account();
        List<Account> accountList = [select id, Name, ZP_Company_ID__c from Account where Name = 'Name'];
        if(accountList.size()==0){
            accountObj.Name='Gusto';
            accountObj.ZP_Company_ID__c='1001';
            accountObj.recordTypeId = contactRecordTypeMap.get('Account');
            accountObj.Joined_Date_Panda__c = Date.today();
            accountObj.First_Contractor_Payment_Date__c = Date.today();
            accountObj.Medical_Deductions__c = true;
            accountObj.Has_Active_WC_Policy__c = true;
            accountObj.HI_Active_Benefits__c = true;
            accountObj.Tier__c = objTierConfig.New_Tier_2__c;
            accountObj.Industry = 'Physical Fitness Facilities';
            accountObj.Number_of_Active_Employees__c = 20;
            accountObj.Number_of_Active_Contractors__c = 20;
            accountObj.No_Clients_Total__c = 20;
            accountObj.ZP_Company_Overall_Status__c='Active';
			accountObj.States__c = 'AK;AL;AR;AZ';
            insert accountObj;
        }else{
            accountObj = accountList[0];
        }
        
        List<Contact> conList = new List<Contact>();
        for(Integer iCount=0; iCount<totalContact; iCount++){
            Contact conObj = new Contact();
            conObj.recordTypeId = contactRecordTypeMap.get('Contact');
            conObj.FirstName = 'TestFirstName_'+iCount;
            conObj.LastName = 'TestLastName_'+iCount;
            conObj.Email = 'TestEmail_'+iCount + '@gmail.com';
            conObj.Employee_Id__c = '1001'; 
            conObj.ZP_User_Id__c = ''+iCount;
            conObj.AccountId = accountObj.id;
            conObj.ZP_User_Role__c = 'Accountant; Benefits Admin; Contractor; Employee; Payroll Admin; Primary Payroll Admin; Signatory';
            conObj.MailingCountry = 'United States';
			conObj.MailingCity = 'San Diego';
            conObj.MailingState = 'California';
            
            conList.add(conObj);
        }
        insert conList;
        return conList;
    }
    
    public static List<Research_Project_Detail__c> createProjectParticipantTest(Research_Project_Master__c projectObj, List<Contact> contactList){
        List<Research_Project_Detail__c> participantList = new List<Research_Project_Detail__c>();
        for(Contact conObj : contactList){
            Research_Project_Detail__c obj = new Research_Project_Detail__c();
            obj.Research_Project_Master__c = projectObj.id;
            obj.Contact__c = conObj.id;
            obj.Research_Participant_Status__c = 'Attended';
            obj.Unread_Email__c = true;
            participantList.add(obj);
        }
        insert participantList;
        createSurveyRecord(participantList);
        
        return participantList;
    }
    
    public static List<Research_Project_Detail__c>  ReturnParticipantListTest(Research_Project_Master__c projectObj, List<Contact> contactList){
    	List<Research_Project_Detail__c> participantList = new List<Research_Project_Detail__c>();
        for(Contact conObj : contactList){
            Research_Project_Detail__c obj = new Research_Project_Detail__c();
            obj.Research_Project_Master__c = projectObj.id;
            obj.Contact__c = conObj.id;
            obj.Research_Participant_Status__c = 'Attended';
            obj.Applicable_for_Incentive__c = true;
            obj.Proposed_Incentive__c = 10;
            obj.Gift_card_swag_sent__c = false;
            participantList.add(obj);
        }
        insert participantList;
        return participantList;
    }
    
    public static void createProjectNotesTest(Research_Project_Master__c projectObj, integer noOfNotes){
        List<Note> notetList = new List<Note>();
         for(Integer iCount=0; iCount<noOfNotes; iCount++){
            Note obj = new Note();
            obj.ParentId = projectObj.id;
            obj.Body = 'Test Note ' + iCount ;
            obj.Title='Test Title ' + iCount ;
            notetList.add(obj);
        }
        insert notetList;
    }
    
    public static List<Event> createParticipantEventTest(List<Research_Project_Detail__c> participantList){
        List<Event> eventList = new List<Event>();
         for(Research_Project_Detail__c rp:participantList){
            Event obj = new Event();
            obj.WhatId = rp.id;
           	obj.Subject='Test Subject ' + rp.id;
           	obj.StartDateTime=DateTime.Now();
           	obj.EndDateTime=DateTime.Now().addMinutes(30);
            eventList.add(obj);
        }
        insert eventList;
        return eventList;
    }
    
    public static void createEmailMapping(){
        List<EmailTemplate> emailTempate = [Select id, Name from EmailTemplate limit 1];
        if(emailTempate.size()>0){
            List<Research_Email_Template__c> tempalteMapping = new List<Research_Email_Template__c>();
            tempalteMapping.add(new Research_Email_Template__c(Email_Template__c=emailTempate[0].id+'', Email_Template_Name__c=emailTempate[0].Name, Status__c='Send survey or screener'));
            tempalteMapping.add(new Research_Email_Template__c(Email_Template__c=emailTempate[0].id+'', Email_Template_Name__c=emailTempate[0].Name, Status__c='Invite to Interview'));
            tempalteMapping.add(new Research_Email_Template__c(Email_Template__c=emailTempate[0].id+'', Email_Template_Name__c=emailTempate[0].Name, Status__c='Send follow up info'));
            insert tempalteMapping;
        }
    }
    
    public static void createSurveyRecord(List<Research_Project_Detail__c> participantList){
        List<Research_Survey__c> surveyList = new List<Research_Survey__c>(); 
        Integer iCount = 0;
        for(Research_Project_Detail__c projectDetailsObj : participantList){
            surveyList.add(new Research_Survey__c(Recorded_Date__c=DateTime.now(), Research_Project_Detail__c= projectDetailsObj.Id, Response_Id__c=iCount+''));
            iCount = iCount + 1;
        }
        insert surveyList;
    
        iCount = 0;
        List<Research_Survey_Response__c> responseList = new List<Research_Survey_Response__c>();
        for(Research_Survey__c surveyObj : surveyList){
            responseList.add(new Research_Survey_Response__c(Research_Survey__c=surveyObj.id, Survey_Questions__c='Ques_'+iCount, Survey_Answers__c='Ans_'+iCount, Survey_Question_Code__c='Code_'+iCount));
            iCount = iCount + 1;
        }
        insert responseList;
    }
    
    public static Research_Integration_Data__c createResearchIntegrationData(String projectName, Id projectId, String type){
        
        Research_Integration_Data__c obj = new Research_Integration_Data__c();
        obj.Cancelled__c = false;
        obj.Data__c = '{"event"=>"invitee.created", "time"=>2019-02-13 05:26:37 +0000, "payload"=>{"event_type"=>{"uuid"=>"BCCBYE3SDLK47P5M", "kind"=>"One-on-One", "slug"=>"' + projectName + '", "name"=>"60 Minute Meeting", "duration"=>60, "owner"=>{"type"=>"users", "uuid"=>"EDBFHSDWUK6TIP2Z"}}, "event"=>{"uuid"=>"ACFT6O3PME3DTNRE", "assigned_to"=>["Saurabh Anand"], "extended_assigned_to"=>[{"name"=>"Saurabh Anand", "email"=>"testemail_0@gmail.com", "primary"=>true}], "start_time"=>2019-02-21 10:30:00 +0530, "start_time_pretty"=>"10:30am - Thursday, February 21, 2019", "invitee_start_time"=>2019-02-21 10:30:00 +0530, "invitee_start_time_pretty"=>"10:30am - Thursday, February 21, 2019", "end_time"=>2019-02-21 11:30:00 +0530, "end_time_pretty"=>"11:30am - Thursday, February 21, 2019", "invitee_end_time"=>2019-02-21 11:30:00 +0530, "invitee_end_time_pretty"=>"11:30am - Thursday, February 21, 2019", "created_at"=>2019-02-13 10:56:37 +0530, "location"=>nil, "canceled"=>false, "canceler_name"=>nil, "cancel_reason"=>nil, "canceled_at"=>nil}, "invitee"=>{"uuid"=>"HGE2AIVJHVWQJT5Y", "first_name"=>nil, "last_name"=>nil, "name"=>"Anand", "email"=>"testemail_0@gmail.com", "text_reminder_number"=>nil, "timezone"=>"Asia/Kolkata", "created_at"=>2019-02-13 10:56:37 +0530, "is_reschedule"=>false, "payments"=>[], "canceled"=>false, "canceler_name"=>nil, "cancel_reason"=>nil, "canceled_at"=>nil}, "questions_and_answers"=>[], "questions_and_responses"=>{}, "tracking"=>{"utm_campaign"=>nil, "utm_source"=>nil, "utm_medium"=>nil, "utm_content"=>nil, "utm_term"=>nil, "salesforce_uuid"=>nil}, "old_event"=>nil, "old_invitee"=>nil, "new_event"=>nil, "new_invitee"=>nil}}';
        obj.Event_End_Date__c = DateTime.Now().addMinutes(30);
        obj.Event_Start_Date__c = DateTime.Now();
        obj.Integration_Type__c = type;
        obj.Meeting_Id__c = 'HGE2AIVJHVWQJT5Y';
        obj.Participant_Id__c = 'testemail_0@gmail.com';
        obj.Project_Id__c = projectName;
        obj.Subject__c = '60 Minute Meeting';
        
        insert obj;
        return obj;
    }
    
    public static Research_Integration_Data__c createSurveyResponseDataTest(String projectName, Id participantId, String type){
        
        Research_Integration_Data__c obj = new Research_Integration_Data__c();
        obj.Cancelled__c = false;
        String str = 'StartDate,EndDate,Status,IPAddress,Progress,Duration (in seconds),Finished,RecordedDate,ResponseId,RecipientLastName,RecipientFirstName,RecipientEmail,ExternalReference,LocationLatitude,LocationLongitude,DistributionChannel,UserLanguage,Q1,Q2,Q3,Q3_1_TEXT,sID \n' +
                    'Start Date,End Date,Response Type,IP Address,Progress,Duration (in seconds),Finished,Recorded Date,Response ID,Recipient Last Name,Recipient First Name,Recipient Email,External Data Reference,Location Latitude,Location Longitude,Distribution Channel,User Language,Are you a payroll administrator for your company.,Do you run payroll in one state or multiple?,Can you suggest any improvements with out product. - Selected Choice,Can you suggest any improvements with out product. - Click to write Choice 1 - Text,sID \n' + 
                    '"{""ImportId"":""startDate"",""timeZone"":""Z""}","{""ImportId"":""endDate"",""timeZone"":""Z""}","{""ImportId"":""status""}","{""ImportId"":""ipAddress""}","{""ImportId"":""progress""}","{""ImportId"":""duration""}","{""ImportId"":""finished""}","{""ImportId"":""recordedDate"",""timeZone"":""Z""}","{""ImportId"":""_recordId""}","{""ImportId"":""recipientLastName""}","{""ImportId"":""recipientFirstName""}","{""ImportId"":""recipientEmail""}","{""ImportId"":""externalDataReference""}","{""ImportId"":""locationLatitude""}","{""ImportId"":""locationLongitude""}","{""ImportId"":""distributionChannel""}","{""ImportId"":""userLanguage""}","{""ImportId"":""QID1""}","{""ImportId"":""QID2""}","{""ImportId"":""QID4""}","{""ImportId"":""QID4_1_TEXT""}","{""ImportId"":""sID""}" \n' + 
                    '2018-12-28 18:24:17,2018-12-28 18:24:36,0,66.97.187.37,100,18,1,2018-12-28 18:24:36,R_1pn6r2S5cOtVcNz,,,,,37.7621002197265625,-122.3970947265625,anonymous,EN,1,2,1,None 123,'+participantId +'\n'+ 
                    '2018-12-28 19:00:10,2018-12-28 19:00:24,0,66.97.187.37,100,13,1,2018-12-28 19:00:24,R_1ITvMsikxegX2Qw,,,,,37.7621002197265625,-122.3970947265625,anonymous,EN,2,1,1,test2,'+participantId + '\n';
        
        obj.Data__c = str;
        obj.Event_End_Date__c = DateTime.Now().addMinutes(30);
        obj.Event_Start_Date__c = DateTime.Now();
        obj.Integration_Type__c = type;
        obj.Meeting_Id__c = 'HGE2AIVJHVWQJT5Y';
        obj.Participant_Id__c = 'testemail_0@gmail.com';
        obj.Project_Id__c = projectName;
        obj.Subject__c = '60 Minute Meeting';
        
        insert obj;
        return obj;
    }
}