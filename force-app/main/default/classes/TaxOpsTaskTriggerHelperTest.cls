@isTest
public class TaxOpsTaskTriggerHelperTest {
	@testSetup
	static void setUp() {
		User adminUser = new TestDataFactory.UserBuilder()
			.setEmail('test@testorg.com')
			.setFirstName('Test')
			.setLastName('user')
			.setProfileId(TestDataFactory.objZPSysAdminProfile.Id)
			.setUserName('Implementation.AdvocateNew@test.Implementation')
			.setExemptfromValidationRules(true)
			.build();
		insert adminUser;

		Agency_Information__c agencyInfo = new Agency_Information__c();
		agencyInfo.Name = 'Ohio Business Gateway Test';
		agencyInfo.Tax_Code__c = 'OH000-001, OHIO_IT-3, OHIO_IT-501, OHIO_IT-941, OHIO_IT-942, OHIO_SD-101, OHIO_SD-141';
		agencyInfo.Agency_Rep__c = adminUser.Id;
		insert agencyInfo;

		Tax_Ops_Task__c tskObj = new Tax_Ops_Task__c();
		tskObj.Tax_Code__c = 'OH000-001';
		tskObj.Process_step__c = 'Payments';
		insert tskObj;
	}

	@isTest
	static void testTaxOpsTaskCreation() {
		Agency_Information__c agencyInfo = [SELECT Id, Tax_Code__c, Agency_Rep__c FROM Agency_Information__c WHERE Name = :'Ohio Business Gateway Test'];
		List<Id> fixedSearchResults = new List<Id>();
		fixedSearchResults.add(agencyInfo.Id);
		Test.setFixedSearchResults(fixedSearchResults);
		Tax_Ops_Task__c tskObj = new Tax_Ops_Task__c();
		tskObj.Tax_Code__c = 'OH000-001';
		tskObj.Process_step__c = 'Payments';
		insert tskObj;

		tskObj = [SELECT Id, OwnerId FROM Tax_Ops_Task__c WHERE Id = :tskObj.Id];
		System.assertEquals(tskObj.OwnerId, agencyInfo.Agency_Rep__c, 'Agency_Rep__c and OwnerId should match.');

		update tskObj;

		delete tskObj;
	}

	@isTest
	static void testTaxOpsTaskUpdate() {
		Agency_Information__c agencyInfo = [SELECT Id, Tax_Code__c, Agency_Rep__c FROM Agency_Information__c WHERE Name = :'Ohio Business Gateway Test'];
		List<Id> fixedSearchResults = new List<Id>();
		fixedSearchResults.add(agencyInfo.Id);
		Test.setFixedSearchResults(fixedSearchResults);

		Tax_Ops_Task__c tskObj1 = [SELECT Id, OwnerId, Process_step__c, Tax_Code__c FROM Tax_Ops_Task__c WHERE Tax_Code__c = :'OH000-001'];
		tskObj1.Process_step__c = 'Filing';
		update tskObj1;
		tskObj1 = [SELECT Id, OwnerId FROM Tax_Ops_Task__c WHERE Id = :tskObj1.Id];
		System.assertEquals(tskObj1.OwnerId, agencyInfo.Agency_Rep__c, 'Agency_Rep__c and OwnerId should match.');
	}
}