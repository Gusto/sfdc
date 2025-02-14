/**
* @name         BTBOSideViewCtrlTest
* @author       Vinay 
* @date         27-02-2020
* @description  Test class for BTBOSideViewCtrl class . VF page - BTBOSideView
**/
@isTest
public class BTBOSideViewCtrlTest {

    static testmethod void  testBTBOSideViewCtrl(){
       OpportunityTriggerHelper.skipTrigger=true;
	   AccountTriggerHelper.skipTrigger=true;
       BenefitOrderHelper.skipTrigger=true;
	   BenefitOrderHelper.skipTaskCreation=true;
        
        account acc1 = TestUtility.CompanyAccount();
        
        Opportunity opp1 = TestUtility.BenefitsNewPlanOpportunity();
  
       Benefit_Order__c boRec = TestUtility.createTestBenefitOrder('New Plan', opp1.Id, 'Test Benefit Order', true); 
       borec.Qualification_Follow_Up_Date__c=Date.newInstance(2016, 12, 9);
       borec.Qualification_Follow_Up_Notes__c	='test data';
       borec.UW_Owner__c = NULL; 
       borec.External_Deductions_for_LiDi__c='yes';
       borec.External_Deductions__c = 'yes';
       borec.Useful_docs_in_attachments__c	='yes';
       borec.Order_Status__c = 'Qualification';
       borec.GDrive_Link__c = 'http://Link';
       borec.Number_Of_Collected_Documents__c=11;
       borec.Action_Necessary_Notes__c='test';
       borec.Is_Multi_EIN__c=true;
       borec.Letters_sent_to_all_carriers__c=true;
       borec.Order_Status__c = 'Ready for Qualification';
       update borec;
        
       
       Benefit_Order__c boRecChild = TestUtility.createTestBenefitOrder('New Plan', opp1.Id, 'Test Benefit Order', true); 
       boRecChild.Qualification_Follow_Up_Date__c=Date.newInstance(2016, 12, 9);
       boRecChild.Qualification_Follow_Up_Notes__c	='test data';
       boRecChild.UW_Owner__c = NULL; 
       boRecChild.External_Deductions_for_LiDi__c='yes';
       boRecChild.External_Deductions__c = 'yes';
       boRecChild.Useful_docs_in_attachments__c	='yes';
       boRecChild.Order_Status__c = 'Qualification';
       boRecChild.GDrive_Link__c = 'http://Link';
       boRecChild.Number_Of_Collected_Documents__c=11;
       boRecChild.Action_Necessary_Notes__c='test';
       boRecChild.Is_Multi_EIN__c=true;
       boRecChild.Letters_sent_to_all_carriers__c=true;
       boRecChild.Order_Status__c = 'Ready for Qualification';
       boRecChild.Parent_Benefit_Order__c=borec.id;
       update boRecChild;
        
       Case cse = new Case();
        cse.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits BoR');
        cse.AccountId = acc1.Id;
        cse.Benefit_Order__c=borec.id;
        cse.Subject='Test';
        cse.Description='Test';
        cse.Type='QLE';
        cse.Origin='Email';
        insert cse;
              
       Carrier__c objCarrier = TestUtility.createTestCarrier('Alegeus','NY' ,true);
       
       Carrier_Order__c obj_CarrierOrder = TestUtility.createTestCarrierOrder(objCarrier.id, 'CarrierORderHandlerTest', boRec.id, true); 
       obj_CarrierOrder.Implementation_Stage__c= 'Ready for Document Collection';	
       Id rectype = Schema.SObjectType.Carrier_Order__c.getRecordTypeInfosByName().get('Benefits BoR').getRecordTypeId();
       obj_CarrierOrder.RecordTypeId=rectype;
       obj_CarrierOrder.Is_Multi_EIN__c=true;
       obj_CarrierOrder.Benefit_Types__c = 'Medical';
       update obj_CarrierOrder;
         
        
       /* Ticket__c t1 = new Ticket__c();
        t1.Carrier_Order__c= obj_CarrierOrder.id;
        t1.Status__c ='new';
        insert t1;
        */
       ApexPages.currentPage().getParameters().put('IdOwner',boRec.id);
       ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(boRec);
       BTBOSideViewCtrl obj1 = new BTBOSideViewCtrl(sc);
       
        
       obj1.UpdateStage();
       obj1.qualifyOrder();
       System.assertEquals(obj1.blnShowQualifyButton, false, 'Qualify button is visible');
       
       obj1.blnCustomerSignedApp=true;
       obj1.blnIsADV=true;
       obj1.blnShowTADASection=true;
        
       obj1.saveBO();
       obj1.MarkTADAComplete();
       obj1.acceptOrder();
       System.assertEquals(obj1.blnShowAcceptOrderButton, false, 'Accept Order button is visible');
    }
    
   
}