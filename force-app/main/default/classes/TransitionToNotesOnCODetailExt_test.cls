@isTest
public class TransitionToNotesOnCODetailExt_test {
	@TestSetup
	static void setupData() {
		//Create CO records
		Carrier_Order__c objCO = TestUtility.CarrierOrder();
		Benefit_Order__c objBO = new Benefit_Order__c();
		List<Benefit_Order__c> list_BO = [
			SELECT Id, Name, Opportunity__c
			FROM Benefit_Order__c
			WHERE Id = :objCO.Benefit_Order__c
		];
		if (list_BO.size() > 0) {
			objBO = list_BO[0];
		}

		Master_Company_Level_Documents__c objMasterCompany = new Master_Company_Level_Documents__c(Status__c = 'Active', name = '');
		insert objMasterCompany;

		//Create Transition to Fulfillment Test records
		Id idTTFBorRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Change');
		Transition_to_Fulfillment__c objTTF = new Transition_to_Fulfillment__c(
			Opportunity__c = objBO.Opportunity__c,
			recordtypeid = idTTFBorRecType,
			Existing_MDVLiDi_Coverage__c = 'Y',
			Do_they_have_affiliates__c = false
		);
		objTTF.Parent_Transition_to_fulfillment__c = null;
		insert objTTF;

		//Create Company Level Documents Test records
		Company_Level_Documents__c objDoc1 = new Company_Level_Documents__c(Benefit_Order__c = objBO.id);
		insert objDoc1;
		Company_Level_Documents__c objDoc2 = new Company_Level_Documents__c(Benefit_Order__c = objBO.id, name = 'test');
		insert objDoc2;

		//Create QA Sheet Test records
		Id idQASheetRecordType = cache.getRecordTypeId('QA_Sheet__c', 'Benefit New Plan');
		QA_Sheet__c objQASheet = new QA_Sheet__c(
			RecordTypeId = idQASheetRecordType,
			Benefit_Order__c = objBO.id,
			SIC_Code__c = 'test',
			BAA_Signed_by__c = 'test',
			BSA_Signed__c = 'Yes'
		);
		objQASheet.Benefit_Order__c = objQASheet.Id;
		insert objQASheet;

		//Create QA Lines Of Coverage Test records
		QA_Lines_Of_Coverage__c objQALine = new QA_Lines_Of_Coverage__c(Lines_Of_Coverage__c = 'Medical', QA_Sheet__c = objQASheet.Id, S_No__c = 0);
		insert objQALine;
	}

	static testMethod void DisplayEditTTIA() {
		test.startTest();
		List<Carrier_Order__c> list_CO = [SELECT id FROM Carrier_Order__c];
		if (list_CO.size() > 0) {
			PageReference pageRef = Page.TransitionToNotesOnCODetail;
			Test.setCurrentPage(pageRef);
			ApexPages.StandardController sc = new ApexPages.StandardController(list_CO[0]);
			ApexPages.currentPage().getParameters().put('Id', list_CO[0].Id);
			TransitionToNotesOnCODetailExt dedit = new TransitionToNotesOnCODetailExt(sc);
		}
		test.stopTest();
	}
}