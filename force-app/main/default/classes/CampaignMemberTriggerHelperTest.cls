/**
 * @description  Test class for Campaign Member Trigger Helper
 * @author       Praveen Sethu
 * @date         03-30-2022
 * @see          CampaignMemberTriggerHelper
 **/
@isTest
public class CampaignMemberTriggerHelperTest {
	@testSetup
	static void testData() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		LeadTriggerHelper.skipTrigger = true;

		// Creating Company Account
		Account objAccnt = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account 1').setZPCompanyId('1111111111').build();
		insert objAccnt;

		// Creating Company Contact
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccnt.Id)
			.setFirstName('Test First Name1')
			.setLastName('Test Last Name1')
			.setEmail('newmember@campaign.com')
			.setRecentSource('Recent Source')
			.setRecentCampaign('Recent Campaign')
			.setRecentContent('Recent Content')
			.build();
		insert objContact;

		// Creating Company Lead
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_COMPANY)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('leadcampaign@member.com')
			.setPhone('123456789')
			.setCompany('Company Lead 1')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.setLeadSource('LinkedIn')
			.setRecentSource('Recent Source')
			.setRecentCampaign('Recent Campaign')
			.setRecentContent('Recent Content')
			.build();
		insert objLead;

		LeadTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;
		AccountTriggerHelper.skipTrigger = false;
	}

	/**
	 * @description Test if lead status is updated on Campaign member on insert
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	@isTest
	static void testLeadStatusOnCampaignMemberInsert() {
		LeadTriggerHelper.skipTrigger = true;
		Test.startTest();
		// Getting Company Lead
		Lead objLead = [SELECT Id, Status, Recent_Source__c, Recent_Campaign__c, Recent_Content__c FROM Lead WHERE Email = 'leadcampaign@member.com' LIMIT 1];

		// Creating new active Campaign
		Campaign objCampaign = new TestDataFactory.CampaignBuilder().setName('Test').setIsActive(true).setType(CampaignMemberTriggerHelper.CAMPAIGN_TYPE_WEBINAR).build();
		insert objCampaign;

		CampaignMember objMember = new TestDataFactory.CampaignMemberBuilder().setLeadId(objLead.Id).setStatus('Responded').setCampaignId(objCampaign.Id).build();
		insert objMember;
		Test.stopTest();

		CampaignMember objMemberAssert = [
			SELECT Id, Recent_Source__c, Recent_Campaign__c, Recent_Content__c, FirstRespondedDate, On_Campaign_Member_Create_Lead_Status__c, Member_First_Responded_Date__c
			FROM CampaignMember
			WHERE Id = :objMember.Id
		];
		System.assertEquals(objLead.Status, objMemberAssert.On_Campaign_Member_Create_Lead_Status__c, 'Lead Status does not match');
		System.assertEquals(objMemberAssert.FirstRespondedDate, objMemberAssert.Member_First_Responded_Date__c, 'Member First Responded Date does not match');
		System.assertEquals(objLead.Recent_Source__c, objMemberAssert.Recent_Source__c, 'Recent Source does not match');
		System.assertEquals(objLead.Recent_Campaign__c, objMemberAssert.Recent_Campaign__c, 'Recent Campaign does not match');
		System.assertEquals(objLead.Recent_Content__c, objMemberAssert.Recent_Content__c, 'Recent Content does not match');
	}

	/**
	 * @description Test if Recent fields (Source, Campaign, Content are set on Campaign Member from Contact)
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	@isTest
	static void testRecentAttributionOnContact() {
		Test.startTest();
		// Getting Company Contact
		Contact objContact = [SELECT Id, Recent_Source__c, Recent_Campaign__c, Recent_Content__c FROM Contact WHERE Email = 'newmember@campaign.com' LIMIT 1];

		// Creating new active Campaign
		Campaign objCampaign = new TestDataFactory.CampaignBuilder().setName('Recent Attribution Contact').setIsActive(true).setType(CampaignMemberTriggerHelper.CAMPAIGN_TYPE_WEBINAR).build();
		insert objCampaign;

		CampaignMember objMember = new TestDataFactory.CampaignMemberBuilder().setContactId(objContact.Id).setStatus('Responded').setCampaignId(objCampaign.Id).build();
		insert objMember;
		Test.stopTest();

		CampaignMember objMemberAssert = [SELECT Id, Recent_Source__c, Recent_Campaign__c, Recent_Content__c FROM CampaignMember WHERE Id = :objMember.Id];
		System.assertEquals(objContact.Recent_Source__c, objMemberAssert.Recent_Source__c, 'Recent Source does not match');
		System.assertEquals(objContact.Recent_Campaign__c, objMemberAssert.Recent_Campaign__c, 'Recent Campaign does not match');
		System.assertEquals(objContact.Recent_Content__c, objMemberAssert.Recent_Content__c, 'Recent Content does not match');
	}

	/**
	 * @description Test if Recent fields from Contact are updated if member is linked to both contact and lead
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	@isTest
	static void testRecentAttributionPriority() {
		Test.startTest();
		// Getting Company Lead
		Lead objLead = [SELECT Id, Recent_Source__c, Recent_Campaign__c, Recent_Content__c FROM Lead WHERE Email = 'leadcampaign@member.com' LIMIT 1];

		// Getting Company Contact
		Contact objContact = [SELECT Id, Recent_Source__c, Recent_Campaign__c, Recent_Content__c FROM Contact WHERE Email = 'newmember@campaign.com' LIMIT 1];

		// Creating new active Campaign
		Campaign objCampaign = new TestDataFactory.CampaignBuilder().setName('Recent Attribution Lead').setIsActive(true).setType(CampaignMemberTriggerHelper.CAMPAIGN_TYPE_WEBINAR).build();
		insert objCampaign;

		CampaignMember objMember = new TestDataFactory.CampaignMemberBuilder().setLeadId(objLead.Id).setContactId(objContact.Id).setStatus('Responded').setCampaignId(objCampaign.Id).build();
		insert objMember;
		Test.stopTest();

		CampaignMember objMemberAssert = [SELECT Id, Recent_Source__c, Recent_Campaign__c, Recent_Content__c FROM CampaignMember WHERE Id = :objMember.Id];
		System.assertEquals(objContact.Recent_Source__c, objMemberAssert.Recent_Source__c, 'Recent Source does not match');
		System.assertEquals(objContact.Recent_Campaign__c, objMemberAssert.Recent_Campaign__c, 'Recent Campaign does not match');
		System.assertEquals(objContact.Recent_Content__c, objMemberAssert.Recent_Content__c, 'Recent Content does not match');
	}

	/**
	 * @description Test if Recent fields (Source, Campaign, Content are  NOT set on Campaign Member from Contact)
	 * @author      Veeresh Kumar
	 * @param       NA
	 * @return      NA
	 **/
	@isTest
	static void testRecentAttributionOnContactNegative() {
		Test.startTest();
		// Getting Company Contact
		Contact objContact = [SELECT Id, Recent_Source__c, Recent_Campaign__c, Recent_Content__c FROM Contact WHERE Email = 'newmember@campaign.com' LIMIT 1];

		// Creating new active Campaign
		Campaign objCampaign = new TestDataFactory.CampaignBuilder().setName('Recent Attribution Contact').setIsActive(true).build();
		insert objCampaign;

		CampaignMember objMember = new TestDataFactory.CampaignMemberBuilder().setContactId(objContact.Id).setStatus('Responded').setCampaignId(objCampaign.Id).build();
		insert objMember;
		Test.stopTest();

		CampaignMember objMemberAssert = [SELECT Id, Recent_Source__c, Recent_Campaign__c, Recent_Content__c FROM CampaignMember WHERE Id = :objMember.Id];
		System.assertNotEquals(objContact.Recent_Source__c, objMemberAssert.Recent_Source__c, 'Recent Source does not match');
		System.assertNotEquals(objContact.Recent_Campaign__c, objMemberAssert.Recent_Campaign__c, 'Recent Campaign does not match');
		System.assertNotEquals(objContact.Recent_Content__c, objMemberAssert.Recent_Content__c, 'Recent Content does not match');
	}
}