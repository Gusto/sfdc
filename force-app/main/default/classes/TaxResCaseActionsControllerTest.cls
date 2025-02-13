/**
 * Name: TaxResCaseActionsControllerTest.cls
 * Date: July-6-2021
 * Author: PR
 * Description: This class is used to test the "Code Coverage" of "TaxResCaseActionsController" class
 *              which is related to "Tax Res" project.
 */

@isTest
public with sharing class TaxResCaseActionsControllerTest {
	static String MASTERCHECKLIST_TAXRES_RT_ID = Cache.getRecordTypeId('BOR_Master_Checklist__c', 'Tax Res');
	static String PAYOPS_TAXRES_RT_ID = Cache.getRecordTypeId('PayOps_Checklists__c', 'Tax Res');

	/**
	 * @Author      :  Pravesh Rana
	 * @Description : setup method use to create test data
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@TestSetup
	static void handleCoverageData() {
		skipTrigger(true);
		Account objAccount = TestDataFactory.CompanyAccount();
		Contact objContact = TestDataFactory.createTestContact(objAccount.Id);
		Case objCase = TestDataFactory.createTestCase(objAccount.Id, objContact.Id);
		List<Role__c> list_Roles = new List<Role__c>();
		list_Roles.add(new Role__c(Name = 'Account Specialist', Team__c = 'Account Specialist'));
		insert list_Roles;

		Region_POD__c objASPod = new Region_POD__c(Name = 'Pod 1 coordinator', Skill_Type__c = 'Core', Type__c = 'Agency', Team__c = 'Account Specialist');
		insert objASPod;

		Skill__c objSkill = new TestDataFactory.SkillBuilder().setRoleId(list_Roles[0].Id).setRegionPOD(objASPod.Id).build();
		insert objSkill;

		List<User_Role__c> list_UserRoles = new List<User_Role__c>();
		list_UserRoles.add(new User_Role__c(User__c = UserInfo.getUserId(), User_Skill_Type__c = 'Core', User_Skill_Team__c = 'Account Specialist'));
		insert list_UserRoles;

		List<User_Skill__c> list_UserSkills = new List<User_Skill__c>();
		list_UserSkills.add(new User_Skill__c(Skill__c = objSkill.Id, User_Role__c = list_UserRoles[0].Id, Skill_Role_Name__c = 'Account Specialist', Active__c = true));
		insert list_UserSkills;

		ContentVersion objContentVersion = new TestDataFactory.ContentVersionBuilder()
			.setTitle('Test File')
			.setPathOnClient('Test.jpg')
			.setVersionData(Blob.valueOf('Test Content'))
			.build();	
		insert objContentVersion;

		List<ContentDocument> list_documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

		ContentDocumentLink objLink = new TestDataFactory.ContentDocumentLinkBuilder()
			.setLinkedEntityId(objCase.Id)
			.setContentDocumentId(list_documents[0].Id)
			.build();
		insert objLink;

		EmailMessage objEmailMsg = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setSubject('Test')
			.setTextBody('Test')
			.setStatus('5')
			.build();
		insert objEmailMsg;

		Attachment objAttachment = new TestDataFactory.AttachmentBuilder()
			.setBody(Blob.valueOf('Test Content'))
			.setParent(objEmailMsg.Id)
			.setName('Test Attachment')
			.build();
		insert objAttachment;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : validate "getEmailTemplateBody" method
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void getEmailTemplateBodyTest() {
		Test.startTest();
		skipTrigger(true);
		List<Case> list_Case = [SELECT Id FROM Case LIMIT 1];
		if (list_Case.size() > 0) {
			Case objCase = list_Case.get(0);
			EmailTemplate objEmailTemplate = TaxResCaseActionsController.getEmailTemplateBody('Blank_Return');
			System.assert(objEmailTemplate.Id != null, 'EmailTemplate Id should not be null.');

			objEmailTemplate = TaxResCaseActionsController.getEmailTemplateBody('');
			System.assert(objEmailTemplate == null, 'EmailTemplate should be null.');
		}

		Test.stopTest();
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : validate "getSolveCaseFields" method
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void getSolveCaseFieldsTest() {
		Test.startTest();

		List<Case> list_Case = [SELECT Id FROM Case LIMIT 1];
		if (list_Case.size() > 0) {
			Case objCase = list_Case.get(0);
			List<String> list_FieldSetFields = TaxResCaseActionsController.getSolveCaseFields();
			System.assert(list_FieldSetFields.size() > 0, 'Field Set should have fields.');
		}

		Test.stopTest();
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : validation for "getUpdatableCaseFields" method
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void getUpdatableCaseFieldsTest() {
		Test.startTest();

		List<Case> list_Case = [SELECT Id FROM Case LIMIT 1];
		if (list_Case.size() > 0) {
			Case objCase = list_Case.get(0);
			List<String> list_FieldSetFields = TaxResCaseActionsController.getUpdatableCaseFields(objCase.Id);
			System.assert(list_FieldSetFields.size() > 0, 'Field Set should have fields.');
		}

		Test.stopTest();
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : validation for "handleFocusedCaseEmailStatus" method
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void handleFocusedCaseEmailStatusPositive() {
		skipTrigger(true);
		List<Case> list_Cases = [SELECT Id, Follow_Up_Date__c, Status, OwnerId FROM Case WHERE RecordType.Name = 'Tax Res' LIMIT 1];
		Test.startTest();
		list_Cases[0].OwnerId = UserInfo.getUserId();
		list_Cases[0].Status = CaseUtils.CASE_STATUS_READY_FOR_RESEARCH;
		update list_Cases;
		list<User_Role__c> listUserRoles = [SELECT id, User__c, User_Skill_Team__c FROM User_Role__c LIMIT 1];
		listUserRoles[0].User_Skill_Team__c = 'Account Specialist';
		update listUserRoles;
		string messsege = TaxResCaseActionsController.handleFocusedCaseEmailStatus(list_Cases[0].Id);
		System.assert(list_Cases.size() > 0, 'There should be at least 1 case in list.');
		system.assert(string.isNotBlank(messsege), 'messsege should not be blank.');
		system.assertEquals('success', messsege, 'messsege should be success.');
		list_Cases[0].Status = CaseUtils.CASE_STATUS_SHELVED;
		list_Cases[0].Shelved_Reason__c = 'Need captain support';
		list_Cases[0].Follow_Up_Date__c = system.today().adddays(+1);
		update list_Cases;
		string result = TaxResCaseActionsController.handleFocusedCaseEmailStatus(list_Cases[0].Id);
		system.assertEquals('Invalid case', result, 'result should match.');
		//changes end
		Test.stopTest();
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : validation negative scenario for "handleFocusedCaseEmailStatus" method
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void handleFocusedCaseEmailStatusNegative() {
		List<Case> list_Cases = [SELECT Id FROM Case WHERE RecordType.Name = 'Tax Res' LIMIT 1];
		Test.startTest();
		string messege = TaxResCaseActionsController.handleFocusedCaseEmailStatus(list_Cases[0].Id);
		Test.stopTest();

		list_Cases = [SELECT Id, Email_Status__c FROM Case WHERE RecordType.Name = 'Tax Res' LIMIT 1];

		System.assert(list_Cases?.size() > 0, 'list_Cases should have at least 1 case.');
		System.assert(list_Cases[0].Email_Status__c != 'In progress', 'Email_Status__c should not be In Progress.');
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : validation for "handleUnFocusedCaseEmailStatus" method
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void handleUnFocusedCaseEmailStatusPositive() {
		List<String> list_CaseIds = new List<String>();
		Case objNewCase = new Case();
		String strResultMessage = '';
		for (Case objCase : [SELECT Id, Email_Status__c FROM Case WHERE RecordType.Name = 'Tax Res' LIMIT 1]) {
			list_CaseIds.add(objCase.Id);
			objNewCase = objCase;
		}

		objNewCase.Email_Status__c = 'In progress';
		update objNewCase;

		Case_Audit_Log__c objCaseAudit = new TestdataFactory.TaxResCaseAuditLogBuilder().setFromStatus('New').setToStatus(CaseUtils.EMAILSTATUS_IN_PROGRESS).setCaseId(objNewCase.Id).build();
		insert objCaseAudit;
		Test.startTest();
		strResultMessage = TaxResCaseActionsController.handleUnFocusedCaseEmailStatus(list_CaseIds);
		Test.stopTest();

		System.assert(strResultMessage == 'success', 'Result should be success.');
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : validation negative scenario for "handleUnFocusedCaseEmailStatus" method
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void handleUnFocusedCaseEmailStatusNegative() {
		List<String> list_CaseIds = new List<String>();
		Case objNewCase = new Case();
		String strResultMessage = '';
		for (Case objCase : [SELECT Id, Email_Status__c FROM Case WHERE RecordType.Name = 'Tax Res' LIMIT 1]) {
			list_CaseIds.add(objCase.Id);
			objNewCase = objCase;
		}

		Test.startTest();
		strResultMessage = TaxResCaseActionsController.handleUnFocusedCaseEmailStatus(list_CaseIds);
		Test.stopTest();

		System.assert(strResultMessage != 'success', 'Result message should not be success.');
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Skip Trigger, which is not required for this functionality
	 * @Parm        : Boolean
	 * @Return      : N/A
	 **/
	public static void skipTrigger(Boolean blnFlag) {
		AccountTriggerHelper.skipTrigger = blnFlag;
		CaseTriggerHelper.skipTrigger = blnFlag;
		CaseAuditLogTriggerHelper.skipTrigger = blnFlag; //BPO-939
	}

	/**
	 * @Author      : Shyam Nasare
	 * @Description : test method for checking available files on Case record
	 * @Parm        : Boolean
	 * @Return      : N/A
	 **/
	@IsTest
	static void testGetAvailableFiles(){
		Id objCaseId = [SELECT Id FROM Case LIMIT 1].Id;
		Test.startTest();
		Map<Id, String> map_IdvsTitle = TaxResCaseActionsController.getAvailableFiles(objCaseId);
		Test.stopTest();
		System.assert(!map_IdvsTitle.isEmpty(), 'ContentDocument map is null');
	}
}