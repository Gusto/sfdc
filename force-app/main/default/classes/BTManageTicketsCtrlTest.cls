/**
* @name         BTManageTicketsCtrlTest
* @author       Anand Singh
* @date         03/08/2020
* @description  Test class for BTManageTicketsCtrl
* @revisions    Date ------------ Name ------------ Comments       
**/
@istest
public class BTManageTicketsCtrlTest {

  @Testsetup      
     public static void TestSetupMethod(){
    AccountTriggerHelper.skipTrigger = true;
    OpportunityTriggerHelper.skipTrigger = true;
    BenefitOrderHelper.skipTrigger = true;
    CaseTriggerHelper.skipTrigger = true;
    account acc1 = TestUtility.CompanyAccount();
    acc1.billingstate = 'New York';
    update acc1;
        
    Opportunity opp1 = TestUtility.BenefitsBoROpportunity();
    opp1.Account= acc1;
    update opp1;
         
    Benefit_Order__c boRec = TestUtility.createTestBenefitOrder('New Plan', opp1.Id, 'Test Benefit Order', true);
    boRec.UW_Owner__c=UserInfo.getUserId();
         
    update borec;
      case C1= new case();
      C1.Accountid = acc1.id;
      C1.Type = 'BOR';
      C1.AccountId = acc1.id;
      C1.Benefit_Order__c = boRec.id;
      CaseTriggerHelper.skipTrigger = true;
      insert C1;
       
       
    Carrier__c objCarrier1 = TestUtility.createTestCarrier('Test1','CA' ,false);
        insert objCarrier1;           
    Carrier_Order__c obj_CarrierOrder= new Carrier_Order__c();
    obj_CarrierOrder.Carrier__c =objCarrier1.Id;
    obj_CarrierOrder.Benefit_Order__c=boRec.id;
    Id rectype = Schema.SObjectType.Carrier_Order__c.getRecordTypeInfosByName().get('Benefits BoR').getRecordTypeId();
    obj_CarrierOrder.RecordTypeId=rectype;
    obj_CarrierOrder.Renewal_Date__c=date.today();
    obj_CarrierOrder.Benefit_Types__c='HSA';
    obj_CarrierOrder.Implementation_Stage__c='With Sales';  
    obj_CarrierOrder.Start_Date__c = date.today();
    obj_CarrierOrder.ownerid = userinfo.getUserId();
    obj_CarrierOrder.Facilitator_2_Enrollment_Review__c = userinfo.getUserId(); 
    obj_CarrierOrder.Facilitator_2_Plan_Review__c = Null;
    obj_CarrierOrder.Order_Type__c = 'New line of Coverage'; 
         
    insert  obj_CarrierOrder;   
    obj_CarrierOrder.OwnerId = userInfo.getUserId();
    update obj_CarrierOrder;
    
    Carrier_Order_Line_Item__c objCarrieOrderLineItem = new Carrier_Order_Line_Item__c();
    objCarrieOrderLineItem.Carrier_Order__c = obj_CarrierOrder.Id;
    objCarrieOrderLineItem.Renewal_Date__c = date.today();
    objCarrieOrderLineItem.Benefit_Types__c = 'Benefits BoR';
    insert objCarrieOrderLineItem;

    List<Ticket_Mapping__c> list_tktMapping = new List<Ticket_Mapping__c>();
        list_tktMapping.add(new Ticket_Mapping__c(  From_Team_Process_step__c = 'Benefits Transfer',From_Sub_Team_s__c = 'Qualifier',
                              To_Team__c = 'BoR Sales',To_Sub_team__c='',
                              Ticket_Reason_s__c='Qualification',Ticket_Reason_Details__c = '2% shareholder issues',
                              Update_Order_Status__c = 'Only Affected CO',Automated_QC_Error_Required__c = 'Yes',
                              Order_Status_while_Ticket_is_Open__c = 'With Sales',
                              Order_Status_when_Ticket_is_Closed__c = 'Qualification'
                              ));
                              
         list_tktMapping.add(new Ticket_Mapping__c(  From_Team_Process_step__c = 'Benefits Transfer',From_Sub_Team_s__c = 'Facilitator 1',
                              To_Team__c = 'Benefits Transfer',To_Sub_team__c='Advocate',
                              Ticket_Reason_s__c='Coverage terminated',Ticket_Reason_Details__c = 'Group benefits are canceled with the carrier',
                              Update_Order_Status__c = 'Only Affected CO',Automated_QC_Error_Required__c = 'No',
                              Order_Status_while_Ticket_is_Open__c = 'Collecting Documents',
                              Order_Status_when_Ticket_is_Closed__c = 'Collecting Documents'
                              ));
        list_tktMapping.add(new Ticket_Mapping__c(  From_Team_Process_step__c = 'Benefits Transfer',From_Sub_Team_s__c = 'Facilitator 2',
                              To_Team__c = 'Benefits Transfer',To_Sub_team__c='Facilitator 1',
                              Ticket_Reason_s__c='Insufficient Data',Ticket_Reason_Details__c = 'Incorrect rates for plan year',
                              Update_Order_Status__c = 'Only Affected CO',Automated_QC_Error_Required__c = 'Yes',
                              Order_Status_while_Ticket_is_Open__c = 'Collecting Documents',
                              Order_Status_when_Ticket_is_Closed__c = 'Implementing Plans'
                              ));
                              
        list_tktMapping.add(new Ticket_Mapping__c(  From_Team_Process_step__c = 'Benefits Transfer',From_Sub_Team_s__c = 'Benefit Transfer Fulfillment',
                              To_Team__c = 'Benefits Transfer',To_Sub_team__c='Facilitator 2',
                              Ticket_Reason_s__c='Incorrect Enrollment Review Information',Ticket_Reason_Details__c = 'EE Member ID’s not added to subscriptions',
                              Update_Order_Status__c = 'BO And All CO',Automated_QC_Error_Required__c = 'Yes',
                              Order_Status_while_Ticket_is_Open__c = 'Enrollment Review Entry in Progress',
                              Order_Status_when_Ticket_is_Closed__c = 'Ready to Send Enrollment Review'
                              ));
        list_tktMapping.add(new Ticket_Mapping__c(  From_Team_Process_step__c = 'Benefits Transfer',From_Sub_Team_s__c = 'Benefit Transfer Fulfillment',
                              To_Team__c = 'Benefits Transfer',To_Sub_team__c='Facilitator 2',
                              Ticket_Reason_s__c='Incorrect Plan Review Information',Ticket_Reason_Details__c = 'Incorrect WP added',
                              Update_Order_Status__c = 'Only Affected CO',Automated_QC_Error_Required__c = 'Yes',
                              Order_Status_while_Ticket_is_Open__c = 'Implementing Plans',
                              Order_Status_when_Ticket_is_Closed__c = 'Ready to Send Plan Review'
                              ));
        
        list_tktMapping.add(new Ticket_Mapping__c(  From_Team_Process_step__c = 'Benefits Transfer',From_Sub_Team_s__c = 'Advocate',
                              To_Team__c = 'Benefits Transfer',To_Sub_team__c='Qualifier',
                              Ticket_Reason_s__c='Qualification',Ticket_Reason_Details__c = 'Benefits through a trust',
                              Update_Order_Status__c = 'Only Affected CO',Automated_QC_Error_Required__c = 'No',
                              Order_Status_while_Ticket_is_Open__c = 'Qualification',
                              Order_Status_when_Ticket_is_Closed__c = 'Back to status prior to ticket creation'
                              ));
                              
        list_tktMapping.add(new Ticket_Mapping__c(  From_Team_Process_step__c = 'Benefits Transfer',From_Sub_Team_s__c = 'Advocate',
                              To_Team__c = 'Benefits Transfer',To_Sub_team__c='Qualifier',
                              Ticket_Reason_s__c='Qualification',Ticket_Reason_Details__c = 'Self Funded',
                              Update_Order_Status__c = 'BO And All CO',Automated_QC_Error_Required__c = 'No',
                              Order_Status_while_Ticket_is_Open__c = 'Qualification',
                              Order_Status_when_Ticket_is_Closed__c = 'Back to status prior to ticket creation'
                              ));
        insert list_tktMapping;

        State_Name_to_abbreviations_Mapping__c st = new  State_Name_to_abbreviations_Mapping__c();
        st.State_Name__c = 'new york';
        st.State_Abbreviation__c = 'NY';
        st.Name = 'one';
        insert st;
    } 
  static TestMethod void testCreateQCError(){
    test.startTest();
          ApexPages.Standardcontroller c = new ApexPages.Standardcontroller([select id from Benefit_Order__c]);
         ApexPages.currentPage().getParameters().put('ID',[select id from Benefit_Order__c].id);     
             ApexPages.currentPage().getParameters().put('source','QCError'); 
          
          BTManageTicketsCtrl Ctrl = new BTManageTicketsCtrl();
      
          Ctrl.saveQCError();
          Ctrl.objTicket.Reporting_Team__c = 'Facilitator 2';
          
          Ctrl.ticketToTeam();
          Ctrl.saveQCError();
          
          Ctrl.strSelectedTeam = 'Benefits Transfer';
        
          Ctrl.subTeam();
          Ctrl.saveQCError();
          
          Ctrl.strSelectedSubTeam = 'Facilitator 1';
          Ctrl.assignOwner();
          Ctrl.ticketDetail();
        
          Ctrl.saveQCError();
          Ctrl.strSelectedReason = 'Insufficient Data';
          Ctrl.saveQCError();
          
          Ctrl.strSelectedReasonDetail = 'Incorrect rates for plan year';
          
          Ctrl.ticketUpdateCoOnlyValue();
          Ctrl.saveQCError();
          
          Ctrl.objQcError.Description__c = 'TEst Description';
          Ctrl.saveQCError();
          
        test.stopTest(); 
    }
    static TestMethod void testCreateTicketWithBOIncorrectPlanReviewNegative(){
    test.startTest();
      Benefit_Order__c objBO = [select id from Benefit_Order__c];
          ApexPages.Standardcontroller c = new ApexPages.Standardcontroller(objBO);
         ApexPages.currentPage().getParameters().put('ID',objBO.id);     
             ApexPages.currentPage().getParameters().put('source','Ticket'); 
          BTManageTicketsCtrl ctrl = new BTManageTicketsCtrl();
          
          ctrl = new BTManageTicketsCtrl();
          ctrl.objTicket.Reporting_Team__c = 'Benefit Transfer Fulfillment';
          ctrl.strSelectedTeam = 'Benefits Transfer';
          ctrl.subTeam();
          ctrl.strSelectedSubTeam = 'Facilitator 2';
          ctrl.assignOwner();
          ctrl.strSelectedReason = 'Incorrect Plan Review Information';
          ctrl.ticketDetail();
          ctrl.strSelectedReasonDetail = 'Incorrect WP Added';
          ctrl.ticketUpdateCoOnlyValue();
          ctrl.saveTicket();
         // system.assert([SELECT count() FROM Ticket__c] == 0);
        test.stopTest();
    }
    static TestMethod void testCreateTicketWithBOIncorrectPlanReview(){
    test.startTest();
      Benefit_Order__c objBO = [select id from Benefit_Order__c];
      Carrier_Order__c objCO = [select id from Carrier_Order__c];
      objCO.OwnerId = userInfo.getUserId();
      objCo.Facilitator_2_Plan_Review__c = userInfo.getUserId();
      update objCO;
      
          ApexPages.Standardcontroller c = new ApexPages.Standardcontroller(objBO);
         ApexPages.currentPage().getParameters().put('ID',objBO.id);     
             ApexPages.currentPage().getParameters().put('source','Ticket'); 
          BTManageTicketsCtrl ctrl = new BTManageTicketsCtrl();
          
          ctrl = new BTManageTicketsCtrl();
          ctrl.objTicket.Reporting_Team__c = 'Benefit Transfer Fulfillment';
          ctrl.strSelectedTeam = 'Benefits Transfer';
          ctrl.subTeam();
          ctrl.strSelectedSubTeam = 'Facilitator 2';
          ctrl.assignOwner();
          ctrl.strSelectedReason = 'Incorrect Plan Review Information';
          ctrl.ticketDetail();
          ctrl.strSelectedReasonDetail = 'Incorrect WP Added';
          ctrl.ticketUpdateCoOnlyValue();
          ctrl.saveTicket();
          //system.assert([SELECT count() FROM Ticket__c] == 1);
        test.stopTest();
    }
    static TestMethod void testCreateTicketWithBOIncorrectEnrollmentReview(){
    test.startTest();
      Benefit_Order__c objBO = [select id from Benefit_Order__c];
          ApexPages.Standardcontroller c = new ApexPages.Standardcontroller(objBO);
         ApexPages.currentPage().getParameters().put('ID',objBO.id);     
             ApexPages.currentPage().getParameters().put('source','Ticket'); 
          BTManageTicketsCtrl ctrl = new BTManageTicketsCtrl();
          
          ctrl = new BTManageTicketsCtrl();
          ctrl.objTicket.Reporting_Team__c = 'Benefit Transfer Fulfillment';
          ctrl.strSelectedTeam = 'Benefits Transfer';
          ctrl.subTeam();
          ctrl.strSelectedSubTeam = 'Facilitator 2';
          ctrl.assignOwner();
          ctrl.strSelectedReason = 'Incorrect Enrollment Review Information';
          ctrl.ticketDetail();
          ctrl.strSelectedReasonDetail = 'EE Member ID’s not added to subscriptions';
          ctrl.ticketUpdateCoOnlyValue();
          ctrl.saveTicket();
         // system.assert([SELECT count() FROM Ticket__c] == 1);
        test.stopTest();
    }
    static TestMethod void testCreateTicketWithBOOriginalStatus1(){
    test.startTest();
      Benefit_Order__c objBO = [select id from Benefit_Order__c];
          ApexPages.Standardcontroller c = new ApexPages.Standardcontroller(objBO);
         ApexPages.currentPage().getParameters().put('ID',objBO.id);     
             ApexPages.currentPage().getParameters().put('source','Ticket'); 
          BTManageTicketsCtrl ctrl = new BTManageTicketsCtrl();
          
          ctrl = new BTManageTicketsCtrl();
          ctrl.objTicket.Reporting_Team__c = 'Advocate';
          ctrl.strSelectedTeam = 'Benefits Transfer';
          ctrl.subTeam();
          ctrl.strSelectedSubTeam = 'Qualifier';
          ctrl.assignOwner();
          ctrl.strSelectedReason = 'Qualification';
          ctrl.ticketDetail();
          ctrl.strSelectedReasonDetail = 'Benefits through a trust';
          ctrl.ticketUpdateCoOnlyValue();
          ctrl.saveTicket();
         //system.assert([SELECT count() FROM Ticket__c] == 1);
        test.stopTest();
    }
    static TestMethod void testCreateTicketWithBOOriginalStatus2(){
    test.startTest();
      Benefit_Order__c objBO = [select id from Benefit_Order__c];
          ApexPages.Standardcontroller c = new ApexPages.Standardcontroller(objBO);
         ApexPages.currentPage().getParameters().put('ID',objBO.id);     
             ApexPages.currentPage().getParameters().put('source','Ticket'); 
          BTManageTicketsCtrl ctrl = new BTManageTicketsCtrl();
          
          ctrl = new BTManageTicketsCtrl();
          ctrl.objTicket.Reporting_Team__c = 'Advocate';
          ctrl.strSelectedTeam = 'Benefits Transfer';
          ctrl.subTeam();
          ctrl.strSelectedSubTeam = 'Qualifier';
          ctrl.assignOwner();
          ctrl.strSelectedReason = 'Qualification';
          ctrl.ticketDetail();
          ctrl.strSelectedReasonDetail = 'Self Funded';
          ctrl.ticketUpdateCoOnlyValue();
          ctrl.saveTicket();
          //system.assert([SELECT count() FROM Ticket__c] == 1);
        test.stopTest();
    }
  static TestMethod void testCreateTicketWithBONegative(){
    test.startTest();
      Benefit_Order__c objBO = [select id from Benefit_Order__c];
          ApexPages.Standardcontroller c = new ApexPages.Standardcontroller(objBO);
         ApexPages.currentPage().getParameters().put('ID',objBO.id);     
             ApexPages.currentPage().getParameters().put('source','Ticket'); 
          BTManageTicketsCtrl ctrl = new BTManageTicketsCtrl();
          
          ctrl.objTicket.Reporting_Team__c = 'Facilitator 2';
          ctrl.strSelectedTeam = 'Benefits Transfer';
        
          ctrl.subTeam();
          ctrl.ticketDetail();
        
          ctrl.assignOwnerFromCO();
          //system.assert(ctrl.saveTicket() == NULL);
          
          ctrl.strSelectedSubTeam = 'Facilitator 1';
          //system.assert(ctrl.saveTicket() == NULL);
          ctrl.strSelectedReason = 'Insufficient Data';
          //system.assert(ctrl.saveTicket() == NULL);
          
          ctrl.strSelectedReasonDetail = 'Incorrect rates for plan year';
          //system.assert(ctrl.saveTicket() == NULL);
          
        test.stopTest(); 
    }  
    static TestMethod void testCreateTicketWithCOIncorrectPlanReview(){
      test.startTest();
      Carrier_Order__c objCO = [select id,Facilitator_2_Plan_Review__c from Carrier_Order__c];
      objCO.OwnerId = userInfo.getUserId();
      objCo.Facilitator_2_Plan_Review__c = userInfo.getUserId();
      update objCO;
      
        ApexPages.Standardcontroller c = new ApexPages.Standardcontroller(objCO);
         ApexPages.currentPage().getParameters().put('ID',objCO.id);     
           ApexPages.currentPage().getParameters().put('source','Ticket'); 
        BTManageTicketsCtrl ctrl = new BTManageTicketsCtrl();
        
        ctrl.objTicket.Reporting_Team__c = 'Benefit Transfer Fulfillment';
          ctrl.strSelectedTeam = 'Benefits Transfer';
          ctrl.subTeam();
          ctrl.strSelectedSubTeam = 'Facilitator 2';
          ctrl.assignOwner();
          ctrl.strSelectedReason = 'Incorrect Plan Review Information';
          ctrl.ticketDetail();
          ctrl.strSelectedReasonDetail = 'Incorrect WP Added';
          ctrl.ticketUpdateCoOnlyValue();
          ctrl.saveTicket();
        //system.assert([SELECT count() FROM Ticket__c] == 1);
      test.stopTest();
    }
    static TestMethod void testCreateTicketWithCOIncorrectPlanReviewNeg(){
      test.startTest();
      Carrier_Order__c objCO = [select id,Facilitator_2_Plan_Review__c from Carrier_Order__c];

        ApexPages.Standardcontroller c = new ApexPages.Standardcontroller(objCO);
         ApexPages.currentPage().getParameters().put('ID',objCO.id);     
           ApexPages.currentPage().getParameters().put('source','Ticket'); 
        BTManageTicketsCtrl ctrl = new BTManageTicketsCtrl();
        
        ctrl.objTicket.Reporting_Team__c = 'Benefit Transfer Fulfillment';
          ctrl.strSelectedTeam = 'Benefits Transfer';
          ctrl.subTeam();
          ctrl.strSelectedSubTeam = 'Facilitator 2';
          ctrl.assignOwner();
          ctrl.strSelectedReason = 'Incorrect Plan Review Information';
          ctrl.ticketDetail();
          ctrl.strSelectedReasonDetail = 'Incorrect WP Added';
          ctrl.ticketUpdateCoOnlyValue();
          ctrl.saveTicket();
        //system.assert([SELECT count() FROM Ticket__c] == 0);
      test.stopTest();
    }
    static TestMethod void testCreateTicketWithCOIncorrectPlanEnrollment(){
      test.startTest();
      Carrier_Order__c objCO = [select id,Facilitator_2_Plan_Review__c from Carrier_Order__c];
        ApexPages.Standardcontroller c = new ApexPages.Standardcontroller(objCO);
         ApexPages.currentPage().getParameters().put('ID',objCO.id);     
           ApexPages.currentPage().getParameters().put('source','Ticket'); 
        BTManageTicketsCtrl ctrl = new BTManageTicketsCtrl();
        
        ctrl.objTicket.Reporting_Team__c = 'Benefit Transfer Fulfillment';
          ctrl.strSelectedTeam = 'Benefits Transfer';
          ctrl.subTeam();
          ctrl.strSelectedSubTeam = 'Facilitator 2';
          ctrl.assignOwner();
          ctrl.strSelectedReason = 'Incorrect Enrollment Review Information';
          ctrl.ticketDetail();
          ctrl.strSelectedReasonDetail = 'EE Member ID’s not added to subscriptions';
          ctrl.ticketUpdateCoOnlyValue();
          ctrl.saveTicket();
        //system.assert([SELECT count() FROM Ticket__c] == 1);
      test.stopTest();
    }
    static TestMethod void testCreateTicketWithCOOriginalStatus1(){
      test.startTest();
      Carrier_Order__c objCO = [select id,Facilitator_2_Plan_Review__c from Carrier_Order__c];
        ApexPages.Standardcontroller c = new ApexPages.Standardcontroller(objCO);
         ApexPages.currentPage().getParameters().put('ID',objCO.id);     
           ApexPages.currentPage().getParameters().put('source','Ticket'); 
        BTManageTicketsCtrl ctrl = new BTManageTicketsCtrl();
        
        ctrl = new BTManageTicketsCtrl();
          ctrl.objTicket.Reporting_Team__c = 'Advocate';
          ctrl.strSelectedTeam = 'Benefits Transfer';
          ctrl.subTeam();
          ctrl.strSelectedSubTeam = 'Qualifier';
          ctrl.assignOwner();
          ctrl.strSelectedReason = 'Qualification';
          ctrl.ticketDetail();
          ctrl.strSelectedReasonDetail = 'Benefits through a trust';
          ctrl.ticketUpdateCoOnlyValue();
          ctrl.saveTicket();
          //system.assert([SELECT count() FROM Ticket__c] == 1);
      test.stopTest();
    }
     static TestMethod void testCreateTicketWithCOOriginalStatus2(){
      test.startTest();
      Carrier_Order__c objCO = [select id,Facilitator_2_Plan_Review__c from Carrier_Order__c];
        ApexPages.Standardcontroller c = new ApexPages.Standardcontroller(objCO);
         ApexPages.currentPage().getParameters().put('ID',objCO.id);     
           ApexPages.currentPage().getParameters().put('source','Ticket'); 
        BTManageTicketsCtrl ctrl = new BTManageTicketsCtrl();
        
        ctrl = new BTManageTicketsCtrl();
          ctrl.objTicket.Reporting_Team__c = 'Advocate';
          ctrl.strSelectedTeam = 'Benefits Transfer';
          ctrl.subTeam();
          ctrl.strSelectedSubTeam = 'Qualifier';
          ctrl.assignOwner();
          ctrl.strSelectedReason = 'Qualification';
          ctrl.ticketDetail();
          ctrl.strSelectedReasonDetail = 'Self Funded';
          ctrl.ticketUpdateCoOnlyValue();
          ctrl.saveTicket();
          //system.assert([SELECT count() FROM Ticket__c] == 1);
      test.stopTest();
    }
    static TestMethod void testCreateTicketWithCONegative(){
    test.startTest();
      Carrier_Order__c objCO = [select id,Facilitator_2_Plan_Review__c from Carrier_Order__c];
          ApexPages.Standardcontroller c = new ApexPages.Standardcontroller(objCO);
         ApexPages.currentPage().getParameters().put('ID',objCO.id);     
             ApexPages.currentPage().getParameters().put('source','Ticket'); 
          BTManageTicketsCtrl ctrl = new BTManageTicketsCtrl();
      
          //system.assert(ctrl.saveTicket() == NULL);
          ctrl.objTicket.Reporting_Team__c = 'Qualifier';
          
          ctrl.strSelectedTeam = 'BoR Sales';
        
          ctrl.subTeam();
          ctrl.assignOwner();
          ctrl.ticketDetail();
        
          ctrl.assignOwnerFromCO();
          //system.assert(ctrl.saveTicket() == NULL);
          
          ctrl.strSelectedReason = 'Qualification';
          //system.assert(ctrl.saveTicket() == NULL);
          
          ctrl.strSelectedReasonDetail = '2% shareholder details';
          //system.assert(ctrl.saveTicket() == NULL);
          
        test.stopTest(); 
    }  
}