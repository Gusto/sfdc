@isTest
public with sharing class CX_Engagement_MassEmailControllerTest {
	@TestSetup
	static void makeData() {
		List<Case_Reason_Classification__c> list_crc = new List<Case_Reason_Classification__c>{
			new Case_Reason_Classification__c(Name = 'Deduction or Garnishment', Type__c = 'Payroll Care', Active__c = true),
			new Case_Reason_Classification__c(Name = 'test crc 2', Type__c = 'Payroll Care', Active__c = true)
		};
		insert list_crc;

		Account acc = TestUtility.CompanyAccount();

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Contact', 'Company'))
			.setPhone('1234567890')
			.setFirstName('Test Contact')
			.setLastName('Test')
			.setAccountId(acc.Id)
			.setEmail('test@gusto.com')
			.setZPUserId('4324324321')
			.build();
		insert objContact;

		Group g = new Group(Type = 'Queue', Name = 'Queue name');
		insert g;

		System.runAs(new User(Id = UserInfo.getUserId())) {
			QueueSObject q = new QueueSObject(SobjectType = 'Case', QueueId = g.Id);
			insert q;

			List<Case> list_Cases = new List<Case>{
				new Case(
					RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care'),
					Subject = 'Test',
					Description = 'Test',
					Type = 'QLE',
					Origin = 'Email',
					SuppliedEmail = 'test.test1@test.com',
					ContactId = objContact.Id,
					OwnerId = g.Id,
					Status = 'New',
					Last_out_bound_email__c = null,
					Routing_Case_Reason__c = 'Deduction or Garnishment'
				)
			};

			insert list_Cases;

			EmailTemplate emailTemp = new EmailTemplate();
			emailTemp.isActive = true;
			emailTemp.Name = 'name';
			emailTemp.DeveloperName = 'email_temp_name';
			emailTemp.TemplateType = 'text';
			emailTemp.FolderId = UserInfo.getUserId();
			emailTemp.subject = 'Test Subject';

			insert emailTemp;
		}
	}

	@isTest
	public static void testSearch() {
		Test.startTest();
		Case_Reason_Classification__c crc = [SELECT Id FROM Case_Reason_Classification__c WHERE Name = 'Deduction or Garnishment'];
		List<EmailTemplate> list_EmailTemplates = [SELECT Id, FolderId FROM EmailTemplate WHERE DeveloperName = 'email_temp_name'];
		Group g = [SELECT Id FROM Group WHERE Name = 'Queue name'];

		CX_Engagement_MassEmailController c = new CX_Engagement_MassEmailController();
		c.strCaseReason = crc.Id;
		c.strSelectedEmailFolder = UserInfo.getUserId();
		c.strSelectedEmailTemplate = list_EmailTemplates[0].Id;
		c.dummyCase.OwnerId = g.Id;
		c.idMassEmailFolder = list_EmailTemplates[0].FolderId;

		c.getEmailTemplateFolderOpts();
		c.fetchCaseReasonClassifications();
		c.searchCases(false);
		c.searchCasesShowMessage();
		c.fetchEmailTemplatesByFolderName();
		c.strSelectedEmailTemplate = list_EmailTemplates[0].Id;
		c.displayEmailTemplate();
		c.saveTemplate();
		c.sendEmail();
		c.validateName('12345');

		List<SelectOption> list_select = new List<SelectOption>{ new SelectOption('1', '1'), new SelectOption('2', '2') };
		c.selectOptionSortByLabel(list_select);
		Test.stopTest();
	}
}