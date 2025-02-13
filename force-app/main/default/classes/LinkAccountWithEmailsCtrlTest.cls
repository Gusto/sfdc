@istest
private class LinkAccountWithEmailsCtrlTest {
    @testsetup
    static void createData(){
		Utils.skipTrigger(true);
    	//Create Accounts
    	List<Account> lstAccount = new List<Account>();
    	Account accRec1 = new Account();
    	accRec1.Name = 'Test Demo AccountName 1';
    	accRec1.BillingStreet = 'Testing Avenue 1';
    	accRec1.BillingPostalCode = '123456';
    	accRec1.Company_Trade_Name__c = 'Company trade name 1';
    	accRec1.Phone = '19992344444';
    	accRec1.ShippingStreet = 'Testing Avenue 1';
    	accRec1.ShippingPostalCode = '123455';
    	
    	lstAccount.add(accRec1);
    	
    	Account accRec2 = new Account();
    	accRec2.Name = 'Test Demo AccountName 2';
    	accRec2.BillingStreet = 'Testing Avenue 1';
    	accRec2.BillingPostalCode = '123455';
    	accRec2.Company_Trade_Name__c = 'Company trade name 1';
    	accRec2.Phone = '19992344444';
    	accRec2.ShippingStreet = 'Testing Avenue 1';
    	accRec2.ShippingPostalCode = '123455';
    	
    	lstAccount.add(accRec2);
    	
    	AccountTriggerHelper.skipTrigger = true;
    	
    	insert lstAccount;
    	
    	OpportunityTriggerHelper.skipTrigger = true;
    	Opportunity opp1 = TestUtility.BenefitsNewPlanOpportunity();
    	
    	Carrier__c carrierRec = TestUtility.Carrier();
    	Benefit_Order__c boRec = TestUtility.createTestBenefitOrder('New Plan', opp1.Id, 'Test Benefit Order', true);
    	boRec.Coverage_Effective_Date__c = Date.TODAY();
 		boRec.Order_Status__c = 'Approved';
        boRec.Push_Rate_Reason__c  = 'Not enough EE enrolled';
        //$User.Exempt_from_Validation_Rules__c = true;
        update boRec;   
        
       	Carrier_Order__c coRec = TestUtility.createTestCarrierOrder(carrierRec.id, 'CarrierOrderHandlerTest', boRec.id, true);
    	coRec.Implementation_Stage__c = 'Qualification'; 
        update coRec;
        
    	List<Case> lstCases = new List<Case>();
    	Id caseRecTypeCO = Cache.getRecordTypeId('Case','Benefits Renewal Case');
    	Id caseRecTypeMF = Cache.getRecordTypeId('Case','MF NHE');
    	lstCases.add(new Case(RecordTypeId = caseRecTypeCO, Subject='test CO case',AccountId = accRec2.Id,Carrier_Order__c = coRec.Id));
    	lstCases.add(new Case(RecordTypeId = caseRecTypeMF,
                              Subject='test MF case',
                              AccountId = accRec2.Id, 
                              Status = 'New',
                              Related_Case__c = null,
                              Requires_Action__c = false,
                              Type = 'NHE'                           
                             ));
    	
    	insert lstCases;
    	
    	lstCases[1].OwnerId = userInfo.getUserId();
    	lstCases[1].Origin = 'Email';
    	update lstCases[1];
    	
    	List<Email_Message__c> lstEmailMsg = new List<Email_Message__c>();
    	
    	lstEmailMsg.add(new Email_Message__c(	Account_List__c = accRec1.Id+';',
    											From_Addresses__c = 'xyz@abc.com',
                                             	Text_Body__c = 'test email',
                                             	CC_Address__c = 'renewals@gusto.com',
    											HTML_Text_Body__c = 'test email',
                                             	Text_Body_Long__c = 'test email',
    											Inbox_Type__c = 'New_Plans',
    											Linked_Accounts__c = accRec2.Id+';',
    											Subject__c = 'Re:Test Demo AccountName 1',
                                             	Parent_Case__c = null,
                                            	Archived__c = false
    											))	;
    											
    	lstEmailMsg.add(new Email_Message__c(	Account_List__c = accRec1.Id+';',
    											From_Addresses__c = 'test@abc.com',
                                             	Text_Body__c = 'test email 2',
                                             	CC_Address__c = 'carrierops@gusto.com',
    											HTML_Text_Body__c = 'test email 2',
                                             	Text_Body_Long__c = 'test email 2',
    											Inbox_Type__c = 'Renewals',
    											Linked_Accounts__c = accRec2.Id+';',
    											Subject__c = 'Re:Test Demo AccountName 1',
                                             	Parent_Case__c = null,
                                             	Archived__c = false
    											))	;
    	lstEmailMsg.add(new Email_Message__c(	Account_List__c = accRec2.Id+';',
    											From_Addresses__c = 'test@abc.com',
                                             	Text_Body__c = 'test email 2',
                                             	CC_Address__c = 'carrierops@gusto.com',
    											HTML_Text_Body__c = 'test email 2',
                                             	Text_Body_Long__c = 'test email 2',
    											Inbox_Type__c = 'Renewals',
    											Linked_Accounts__c = accRec2.Id+';',
    											Possible_Match__c = 'Test Demo AccountName 2',
    											Subject__c = 'Re:Test Demo AccountName 2',
                                             	Parent_Case__c = lstCases[1].Id,
                                             	Archived__c = false
    											))	;    	
    	
    	insert lstEmailMsg;
    	
    	List<Attachment> lstAttachment = new List<Attachment>();
    	lstAttachment.add(new Attachment(	Name = 'Test attach',
													Body = Blob.valueOf('test body'),
													ParentId = lstEmailMsg[0].Id
													));
													
		lstAttachment.add(new Attachment(	Name = 'Test attach',
													Body = Blob.valueOf('test body'),
													ParentId = lstEmailMsg[1].Id
													));
    	insert lstAttachment;
    }
    
    private static testmethod void testLinkAccountCtrl(){
    	test.startTest();
    		LinkAccountWithEmailsCtrl ctrl = new LinkAccountWithEmailsCtrl();
    		
    		system.assert(NULL != ctrl.lst_EmailsWrap && ctrl.lst_EmailsWrap.size() > 0);
    		
    		//unit test pagination logic
    		system.assert(ctrl.getTotalPages() > 0);
    		ctrl.first();
    		ctrl.last();
    		ctrl.next();
    		ctrl.previous();
    		system.assert(ctrl.hasPrevious == false);
    		system.assert(ctrl.hasNext == false);
    		system.assert(ctrl.PageNumber > 0);
			ctrl.intSelectedEmail = 0;
    		ctrl.showSelectedEmail();
    	test.stopTest();
    }
    private static testmethod void testLinkAccount(){
    	test.startTest();
    		LinkAccountWithEmailsCtrl ctrl = new LinkAccountWithEmailsCtrl();
    		
    		system.assert(NULL != ctrl.lst_EmailsWrap && ctrl.lst_EmailsWrap.size() > 0);
    		system.assert(NULL != ctrl.lst_EmailsWrap[0].obj_Message.Linked_Accounts__c);
    		System.currentPageReference().getParameters().put('mid', ctrl.lst_EmailsWrap[0].obj_Message.Id);
			ctrl.intSelectedEmail = 0;
			ctrl.linkSelectedEmail(); 
			//system.assert(ctrl.lstCasesWithCarrier.size() > 0);
			//system.assert(ctrl.lstCasesMemberFulfilment.size() > 0);  
			system.assert(NULL != ctrl.objEmailToLink.map_LinkedAccounts);
			
			String strAcc = ctrl.objEmailToLink.obj_Message.Linked_Accounts__c.split(';')[0];
			ctrl.accIdToBeDeLink =  strAcc;
			
			ctrl.delinkAccount();
			
			Account acc = new Account();
	    	acc.Name = 'Testinf New Acc';
	    	acc.BillingStreet = 'Testing Avenue 1';
	    	acc.BillingPostalCode = '123996';
	    	acc.Company_Trade_Name__c = 'Company trade name 1';
	    	acc.Phone = '19992344444';
	    	acc.ShippingStreet = 'Testing Avenue 1';
	    	acc.ShippingPostalCode = '123455';
			insert acc;
			
			ctrl.objOrd.AccountId = acc.Id;
			
			ctrl.linkNewAccount();
			
			ctrl.accIdToBeDeLink = ctrl.objEmailToLink.obj_Message.Account_List__c.split(';')[0];
			
			ctrl.objEmailToLink.map_SelectedAccounts.put(ctrl.accIdToBeDeLink,true);
			
			ctrl.linkPossibleMatchAccount();
			
			ctrl.accIdToBeDeLink = ctrl.objEmailToLink.obj_Message.Account_List__c.split(';')[0];
			
			ctrl.objEmailToLink.map_SelectedAccounts.put(ctrl.accIdToBeDeLink,false);
			
			ctrl.linkPossibleMatchAccount();
			
    	test.stopTest();
    }

    private static testmethod void testLinkContact(){
    	test.startTest();
    		LinkAccountWithEmailsCtrl ctrl = new LinkAccountWithEmailsCtrl();
    		
    		system.assert(NULL != ctrl.lst_EmailsWrap && ctrl.lst_EmailsWrap.size() > 0);
    		system.assert(NULL != ctrl.lst_EmailsWrap[0].obj_Message.Linked_Accounts__c);
    		System.currentPageReference().getParameters().put('mid', ctrl.lst_EmailsWrap[0].obj_Message.Id);
			ctrl.intSelectedEmail = 0;
			ctrl.linkSelectedEmail(); 
			//system.assert(ctrl.lstCasesWithCarrier.size() > 0);
			//system.assert(ctrl.lstCasesMemberFulfilment.size() > 0);  
			system.assert(NULL != ctrl.objEmailToLink.map_LinkedAccounts);
			

			Account acc = [SELECT ID,Name FROM Account WHERE Name = 'Test Demo AccountName 2'];	
            Contact con = new Contact();
        	con.FirstName = 'Test';
            con.LastName = 'New Acc';
        	con.AccountId = acc.Id;
        	con.Email = 'testing@123.com';
        	insert con;	
        
			//ctrl.objOrd.AccountId = acc.Id;
			ctrl.objOrd.CustomerAuthorizedById = con.Id;
        
			ctrl.linkNewAccount();
			
			ctrl.accIdToBeDeLink = ctrl.objEmailToLink.obj_Message.Account_List__c.split(';')[0];
			
			ctrl.objEmailToLink.map_SelectedAccounts.put(ctrl.accIdToBeDeLink,true);
			
			ctrl.linkPossibleMatchAccount();
			
			ctrl.accIdToBeDeLink = ctrl.objEmailToLink.obj_Message.Account_List__c.split(';')[0];
			
			ctrl.objEmailToLink.map_SelectedAccounts.put(ctrl.accIdToBeDeLink,false);
			
			ctrl.linkPossibleMatchAccount();
			
    	test.stopTest();
    }
    
     private static testmethod void testAttachCase(){
    	test.startTest();
    		LinkAccountWithEmailsCtrl ctrl = new LinkAccountWithEmailsCtrl();
    		Account acc = [SELECT ID,Name FROM Account WHERE Name = 'Test Demo AccountName 2'];	

    		system.assert(NULL != ctrl.lst_EmailsWrap && ctrl.lst_EmailsWrap.size() > 0);
    		system.assert(NULL != ctrl.lst_EmailsWrap[0].obj_Message.Linked_Accounts__c);
    		System.currentPageReference().getParameters().put('mid', ctrl.lst_EmailsWrap[0].obj_Message.Id);
			ctrl.intSelectedEmail = 0;
			ctrl.linkSelectedEmail(); 
			system.assert(ctrl.lstCasesWithCarrier.size() > 0);
         	//system.assert(ctrl.lstCasesMemberFulfilment.size() > 0);
			system.assert(NULL != ctrl.objEmailToLink.map_LinkedAccounts);
         	system.assert(NULL != ctrl.objEmailToLink.obj_Message);
         	//system.assert(objEmailToLink.obj_Message.Parent_Case__c == NULL);   
			ctrl.idSelectedCase = ctrl.lstCasesWithCarrier[0].Id;
         	system.assert(NULL != ctrl.idSelectedCase);
			ctrl.attachEmailToCase();
         	ctrl.idSelectedAccount = acc.Id;
         	ctrl.attachEmailToExistingCase();
         	ctrl.createCaseFeed();
			ctrl.showAllEmails();
     }
    private static testmethod void testArchivedEmail(){
    	test.startTest();
    		LinkAccountWithEmailsCtrl ctrl = new LinkAccountWithEmailsCtrl();
    		
    		system.assert(NULL != ctrl.lst_EmailsWrap && ctrl.lst_EmailsWrap.size() > 0);
    		
    		ctrl.str_SubSearch = 'Acc';
    		
    		ctrl.fetchEmails();
        
    		system.assert(NULL == ctrl.lst_EmailsWrap || ctrl.lst_EmailsWrap.size() == 0);
    		
    		ctrl.str_SubSearch = 'AccountName 1';
    		
    		ctrl.fetchEmails();
    		
    		system.assert(NULL != ctrl.lst_EmailsWrap && ctrl.lst_EmailsWrap.size() > 0);
    		
    		ctrl.intSelectedEmail = 0;
    		
    		Integer intEmailCount = ctrl.lst_EmailsWrap.size();
    		
    		ctrl.archiveSelectedEmail();
    		
    		System.assert(ctrl.lst_EmailsWrap.size() == intEmailCount );
    		
    	test.stopTest();
    }

    private static testmethod void testattachEmailToExistingCase(){
    	test.startTest();
    		LinkAccountWithEmailsCtrl ctrl = new LinkAccountWithEmailsCtrl();
    		ctrl.refreshEmails();
    		system.assert(NULL != ctrl.lst_EmailsWrap && ctrl.lst_EmailsWrap.size() > 0);
    		
    		ctrl.str_SubSearch = 'Acc';
        
    		ctrl.attachEmailToExistingCase();
    		system.assert(NULL != ctrl.lst_EmailsWrap && ctrl.lst_EmailsWrap.size() > 0);
    		
    		ctrl.intSelectedEmail = 0;
    		
    		Integer intEmailCount = ctrl.lst_EmailsWrap.size();
    		
    		ctrl.archiveSelectedEmail();
    		
    		system.assert(ctrl.lst_EmailsWrap.size() == intEmailCount);
    		
    	test.stopTest();
    }

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Bulk Archival Email Message
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	private static testMethod void testBulkArchiveEmail() {
		Test.startTest();
		LinkAccountWithEmailsCtrl objCtrl = new LinkAccountWithEmailsCtrl();
		objCtrl.strSortBy = 'Subject__c';
		objCtrl.sortEmailList();

		for (LinkAccountWithEmailsCtrl.EmailWrapper objWrapper : objCtrl.lst_EmailsWrap) {
			objWrapper.blnSelect = true;
		}

		objCtrl.archiveMassEmail();

		System.assert([SELECT Id FROM Email_Message__c WHERE Archived__c = TRUE].size() == 3);

		Test.stopTest();
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Bulk Secured Email Message
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	private static testMethod void testBulkSecuredEmail() {
		Test.startTest();
		LinkAccountWithEmailsCtrl objCtrl = new LinkAccountWithEmailsCtrl();
		objCtrl.strSortBy = 'Subject__c';
		objCtrl.sortEmailList();
		objCtrl.intSelectedEmail = 0;
		objCtrl.secureSelectedEmail();
		
		for (LinkAccountWithEmailsCtrl.EmailWrapper objWrapper : objCtrl.lst_EmailsWrap) {
			objWrapper.blnSelect = true;
		}

		objCtrl.secureMassEmail();

		System.assert([SELECT Id FROM Email_Message__c WHERE Secure_Email__c = TRUE].size() == 3);

		Test.stopTest();
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Bulk Un-Secured Email Message
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	private static testMethod void testBulkUnSecuredEmail() {
		Test.startTest();
		LinkAccountWithEmailsCtrl objCtrl = new LinkAccountWithEmailsCtrl();
		objCtrl.strSortBy = 'Subject__c';
		objCtrl.sortEmailList();
		objCtrl.intSelectedEmail = 0;
		objCtrl.secureSelectedEmail();
		
		for (LinkAccountWithEmailsCtrl.EmailWrapper objWrapper : objCtrl.lst_EmailsWrap) {
			objWrapper.blnSelect = true;
		}
		objCtrl.secureMassEmail();

		System.assert([SELECT Id FROM Email_Message__c WHERE Secure_Email__c = True].size() == 3);

		for (LinkAccountWithEmailsCtrl.EmailWrapper objWrapper : objCtrl.lst_EmailsWrap) {
			objWrapper.blnSelect = true;
		}
		objCtrl.unSecureMassEmail();

		Test.stopTest();

		System.assert([SELECT Id FROM Email_Message__c WHERE Secure_Email__c = False].size() == 3);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Closed Parent Case record.
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	private static testMethod void testClosedParentCase() {
		Test.startTest();
		Account objAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Demo AccountName 2'];
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('MF Member/Group Updates')
			.setSubject('Test MF/Group Updates')
			.setOrigin('Email')
			.setAccountId(objAccount.Id)
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('testunauthorized@gmail.com')
			.setDescription('Test MF/Group Updates')
			.build();
		insert objCase;

		LinkAccountWithEmailsCtrl objCtrl = new LinkAccountWithEmailsCtrl();
		objCtrl.strSortBy = 'Subject__c';
		objCtrl.sortEmailList();
		Id idEmailMessage = null;
		for (LinkAccountWithEmailsCtrl.EmailWrapper objWrapper : objCtrl.lst_EmailsWrap) {
			if(objWrapper.obj_Message.Parent_Case__c != null) {
				objWrapper.blnSelect = true;
				idEmailMessage = objWrapper.obj_Message.Id;
				objCtrl.objEmailToLink = objWrapper;
			}
		}
		ApexPages.currentPage().getParameters().put('mId', idEmailMessage);

		objCtrl.fetchEmails();
		objCtrl.linkSelectedEmail(); 
		objCtrl.idSelectedCase = objCase.Id;
		objCtrl.attachEmailToCase();

		Test.stopTest();

		List<Case> list_Cases = [SELECT Id, Status, Related_Case__c, Related_Case__r.Status FROM Case Where Id =: objCase.Id];
		System.assertEquals(CaseUtils.STATUS_NEW, list_Cases[0].Status, 'Current Case should be open');
		System.assertEquals(CaseUtils.STATUS_CLOSED, list_Cases[0].Related_Case__r.Status, 'Parent Case is not closed');

	}
}