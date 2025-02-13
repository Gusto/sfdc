@isTest class TaxResCaseMassEmailCtrlTest {

    @testsetup 
    static void createData(){
        AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
        Integer intRecordCount = 2;
        
		List<Large_Scale_Issue__c> list_LSI = new List<Large_Scale_Issue__c>();
		list_LSI.add(new Large_Scale_Issue__c(Name= 'Incorrect House tax'));
		insert list_LSI;

		List<Account> list_Account = new List<Account>();
		for(Integer i = 0;i<intRecordCount;i++){
			list_Account.add(new Account(NAme = 'August 6,'+i,ZP_Company_Id__c = '1210'+i));
		}
		insert list_Account;

		List<Contact> list_Contact = new List<Contact>();
		for(Integer i = 0;i<intRecordCount;i++){
			list_Contact.add(new Contact(FirstName = 'Neha'+i,LastName = 'Test August 6 ', Email='neha.dabas+'+i+'@lirik.io', AccountId = list_Account[i].Id));
		}
		insert list_Contact;
        
		List<Case> list_Case = new List<Case>();
		Id idTaxRes = Cache.getRecordTypeId('Case','Tax Res');
		for(Integer i = 0;i<intRecordCount;i++){
			Case objCase = new Case(Subject = 'Test LSI Case'+i,contactId = list_Contact[i].Id,AccountId = list_Account[i].Id,RecordTypeId = idTaxRes, Type = 'Tax Res',Customer_Journey__c = 'Large Scale Issue',Priority ='Medium',Direction__c='Inbound',Origin = 'Email');
			objCase.Large_Scale_Issue_Classification__c = list_LSI[0].Id;
			objCase.OwnerId = userInfo.getUserId();
			list_Case.add(objCase);
		}
		insert list_Case;
	}
	
	static testmethod void testSendEmailPositive(){
		Test.startTest();
        TaxResCaseMassEmailCtrl ctrl= new TaxResCaseMassEmailCtrl();
        //Select Large Scale Issue
        if(ctrl.list_LargeScaleIssueName!=null && ctrl.list_LargeScaleIssueName.size()>0){
            ctrl.strSelectLSIName = ctrl.list_LargeScaleIssueName[0].getValue();
        } 
        ctrl.fetchLSICases();
        
        //Select Folder
        List<SelectOption> list_EmailFolder = ctrl.getEmailTemplateFolderOpts();
        if(list_EmailFolder!=null && list_EmailFolder.size()>1){
        	ctrl.strSelectedEmailFolder = list_EmailFolder[1].getValue();
        }
        ctrl.fetchEmailTemplatesByFolderName();
        
        //Select Email Templates	
        if(ctrl.list_emailTemplatesByFolderName!=null && ctrl.list_emailTemplatesByFolderName.size()>1){
        	ctrl.strSelectedEmailTemplate = ctrl.list_emailTemplatesByFolderName[1].getValue();
        }
		ctrl.displayEmailTemplate();
        
        ctrl.getTotalPages();
        ctrl.first();
        ctrl.previous();
        ctrl.last();
        
        //Select Case Ids
        ctrl.selectUnselectAllCase();
        ctrl.intSelectedCaseIndx = 1;
        ctrl.list_CaseWrappers[1].blnSelected = false;
        ctrl.selectCase();
        system.assert(ctrl.blnOneOrMoreCasesSelected == false);
        ctrl.list_CaseWrappers[1].blnSelected = true;
        ctrl.selectCase();
        system.assert(ctrl.blnOneOrMoreCasesSelected == true);
        //Select First Response.
        ctrl.objDummyCaseResolutionEmail.Mass_Email_Step__c = 'First Response';
        //Send email to contact related to selected case ids.
        ctrl.sendEmail();
        ctrl.checkIsMassEmailBatchRunning();
 		ctrl.clearMassEmailMessage();
		Test.stopTest();
	}
}