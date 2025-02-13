/**
 * @description  Used to test retrieving fields from opportunity and account field sets
 * @author       Praveen Sethu
 * @date         09-07-2023
 **/
@isTest
public class NBAMiniViewControllerTest {
	/**
	 * @author      Praveen Sethu
	 * @description Test retrieving fields from opportunity and account field sets
	 **/
	@isTest
	static void testGetFieldsFromFieldSet() {
		// insert company account
		Account objCompanyAcc = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').setZPCompanyId('1234567890').build();
		insert objCompanyAcc;

		// insert company opportunity
		Opportunity objOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Company Opportunity')
			.setAccountId(objCompanyAcc.Id)
			.setStage('MQL')
			.setCloseDate(System.today())
			.build();
		insert objOppty;

		// start test and send opportunity and account field set names
		Test.startTest();
		NBAMiniViewController.NBAMiniViewWrapperResponse objResponse = NBAMiniViewController.getFieldsFromFieldSet(
			'NBA_Small_Biz_Mini_View', // opportunity field set name
			'NBA_Small_Biz_Mini_View', // account field set name
			'NBA_Small_Biz_Mini_View', // lead field set name
			objOppty.Id
		);
		Test.stopTest();

		// assert if we are able to successfully retrieve fields from both field sets
		System.assertEquals(true, objResponse.blnSuccess, 'Unable to retreive field sets');
	}
}