/**
 * @description  Contains all the test methods for CampaignTriggerHelper
 * @author       Veeresh Kumar
 * @date         04-19-2022
 * @see          CampaignTriggerHelper
 **/
@isTest
public class CampaignTriggerHelperTest {
	/**
	 * @description Test if Trigger is skipped.
	 * @author      Veeresh Kumar
	 * @param       NA
	 * @return      NA
	 **/
	@isTest
	private static void testSkipTrigger() {
		Test.startTest();
		// Creating new active Campaign
		Campaign objCampaign = new TestDataFactory.CampaignBuilder().setName('Test').setIsActive(true).setType('Webinar').build();

		CampaignTriggerHelper.blnSkipTrigger = true;
		insert objCampaign;
		CampaignTriggerHelper.blnSkipTrigger = false;
		Test.stopTest();

		Campaign objCampaignAssert = [SELECT Id, StartDate FROM Campaign WHERE Id = :objCampaign.Id];
		System.assertEquals(null, objCampaign.StartDate, 'Start Date should be null');
	}

	/**
	 * @description Test if StartDate is set to CreatedDate
	 * @author      Veeresh Kumar
	 * @param       NA
	 * @return      NA
	 **/
	@isTest
	private static void testSetStartDate() {
		Test.startTest();
		// Creating new active Campaign
		Campaign objCampaign = new TestDataFactory.CampaignBuilder().setName('Test').setIsActive(true).setType('Webinar').build();
		insert objCampaign;
		Test.stopTest();

		Campaign objCampaignAssert = [SELECT Id, StartDate, CreatedDate FROM Campaign WHERE Id = :objCampaign.Id];
		System.assertEquals(Date.today(), objCampaignAssert.StartDate, 'Start date should be today.');
	}
}