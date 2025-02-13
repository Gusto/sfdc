@isTest
public class RecoveryCaseClassSettingUpdateTest {
	@TestSetup
	static void dataSetupMethod() {
		Recovery_Case_Class_Assignment_Setting__c settObj = new Recovery_Case_Class_Assignment_Setting__c();
		settObj.Name = '1';
		settObj.Error_Code__c = 'R01';
		settObj.Recovery_Amount_Starting_Limit__c = 1;
		settObj.Recovery_Amount_End_Limit__c = 50;
		settObj.Eligible_Class__c = 'Class 1';
		settObj.Task_Us__c = false;

		insert settObj;
	}

	@isTest
	static void updateObjectTestMethod() {
		RecoveryCaseClassSettingUpdateController classInstance = new RecoveryCaseClassSettingUpdateController();
		system.assert(classInstance.lst_wrapper.size() > 0);
		classInstance.saveCustomSetting();
		classInstance.closeCurrentPage();
	}
}