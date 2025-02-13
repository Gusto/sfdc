/**
 * @name         : EngagementOmniListenerControllerTest
 * @author       : Sanjay Paryani
 * @date         : 08/24/2023
 * @description  : Test class for EngagementOmniListenerController
 **/
@isTest
public with sharing class EngagementOmniListenerControllerTest {
	public static final String SERVICECHANNEL_CASE = EngagementOmniListenerController.SERVICECHANNEL_CASE;
	public static final Id USER_ID = UserInfo.getUserId();

	/*
	 * @Author:          Sanjay Paryani
	 * @Description:     Test if opening up a case record tab is creating the agentwork record.
	 * @Parm:            N/A
	 * @Return:          N/A
	 */
	static testMethod void testOnlinePresenceChange() {
		User objRunningUser = new User();
		objRunningUser.id = USER_ID;
		Account objAccount = new TestDataFactory.AccountBuilder().setName('Test Account 123').setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setZPCompanyId('123123123123').build();
		insert objAccount;
		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setOwnerId(USER_ID)
			.setRecordTypeId('Engagement')
			.setType('Payroll')
			.setSubject('Test Case for AgentWork listener')
			.setOrigin('Email')
			.setStatus('Open')
			.setSuppliedEmail('test1@gusto.com')
			.setDescription('Description - Test Case for AgentWork listener')
			.build();
		insert objCase;

		Test.startTest();
		System.runAs(objRunningUser) {
			// Create AgentWork record for the logged in user
			try {
				Agentwork objAWRecord = new TestDataFactory.AgentWorkeBuilder()
					.setUserId(USER_ID)
					.setWorkItemId(objCase.Id)
					.setServiceChannelId(SERVICECHANNEL_CASE)
					.setShouldSkipCapacityCheck(false)
					.setCapacityWeight(1)
					.build();
				insert objAWRecord;
			} catch (Exception objEx) {
				ExceptionLogUtil.logException('EngagementOmniListenerControllerTest', 'testPresenceStatusChanges', objEx.getMessage(), objEx.getStackTraceString());
			}
			EngagementOmniListenerController.updateCaseStatus('Email - Available');
			Case objQueriedCaseRecord = [SELECT Id, Status FROM Case WHERE Id = :objCase.Id];
			System.assertEquals('In Progress', objQueriedCaseRecord?.Status, 'Case status was not updated to Open');
		}
		Test.stopTest();
	}

	/*
	 * @Author:          Sanjay Paryani
	 * @Description:     Test if opening up a case record tab is creating the agentwork record.
	 * @Parm:            N/A
	 * @Return:          N/A
	 */
	static testMethod void testBulkCaseUpdates() {
		List<Case> listCases = new List<Case>();
		User objRunningUser = new User();
		objRunningUser.id = USER_ID;
		Account objAccount = new TestDataFactory.AccountBuilder().setName('Test Account 123').setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setZPCompanyId('123123123123').build();
		insert objAccount;
		Case objCase1 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setOwnerId(USER_ID)
			.setRecordTypeId('Engagement')
			.setType('Payroll')
			.setSubject('Test Case for AgentWork listener 1')
			.setOrigin('Email')
			.setStatus('Open')
			.setSuppliedEmail('test1@gusto.com')
			.setDescription('Description - Test Case for AgentWork listener 1')
			.build();
		listCases.add(objCase1);
		Case objCase2 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setOwnerId(USER_ID)
			.setRecordTypeId('Engagement')
			.setType('Payroll')
			.setSubject('Test Case for AgentWork listener 2')
			.setOrigin('Email')
			.setStatus('Open')
			.setSuppliedEmail('test1@gusto.com')
			.setDescription('Description - Test Case for AgentWork listener 2')
			.build();
		listCases.add(objCase2);
		Case objCase3 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setOwnerId(USER_ID)
			.setRecordTypeId('Engagement')
			.setType('Payroll')
			.setSubject('Test Case for AgentWork listener 3')
			.setOrigin('Email')
			.setStatus('Open')
			.setSuppliedEmail('test1@gusto.com')
			.setDescription('Description - Test Case for AgentWork listener 3')
			.build();
		listCases.add(objCase3);
		Case objCase4 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setOwnerId(USER_ID)
			.setRecordTypeId('Engagement')
			.setType('Payroll')
			.setSubject('Test Case for AgentWork listener 4')
			.setOrigin('Email')
			.setStatus('Open')
			.setSuppliedEmail('test1@gusto.com')
			.setDescription('Description - Test Case for AgentWork listener 4')
			.build();
		listCases.add(objCase4);
		CaseTriggerHelper.skipTrigger = true;
		insert listCases;
		CaseTriggerHelper.skipTrigger = false;

		Test.startTest();
		System.runAs(objRunningUser) {
			// Create AgentWork record for the logged in user
			try {
				Agentwork objAWRecord = new TestDataFactory.AgentWorkeBuilder()
					.setUserId(USER_ID)
					.setWorkItemId(objCase1.Id)
					.setServiceChannelId(SERVICECHANNEL_CASE)
					.setShouldSkipCapacityCheck(false)
					.setCapacityWeight(1)
					.build();
				insert objAWRecord;
			} catch (Exception objEx) {
				ExceptionLogUtil.logException('EngagementOmniListenerControllerTest', 'testPresenceStatusChanges', objEx.getMessage(), objEx.getStackTraceString());
			}
			EngagementOmniListenerController.updateCaseStatus('Email - Available');
		}
		Test.stopTest();

		Case objQueriedCaseRecord = [SELECT Id, Status FROM Case WHERE Subject = 'Test Case for AgentWork listener 4'];
		System.assertEquals('In Progress', objQueriedCaseRecord?.Status, 'Case status was not updated to Open');
	}
}