/*
 * @name         : HIBenefitsPackageTriggerHelper
 * @author       : Sanjay Paryani
 * @date         : 05-12-2021
 * @description  : HI_Benefits_Package__c Trigger Logic
 * @test classes : HIBenefitsPackageTriggerHelperTest
 */
public without sharing class HIBenefitsPackageTriggerHelper {
	public static boolean skipTrigger = false;

	public void processAfterInsert(Map<ID, HI_Benefits_Package__c> map_HIBenefitsPackages) {
		if (Test.isRunningTest()) {
			throwTestException();
		}

		reprocessHIPolicy(map_HIBenefitsPackages);
	}

	public void processAfterUpdate(Map<ID, HI_Benefits_Package__c> map_HIBenefitsPackages) {
		if (Test.isRunningTest()) {
			throwTestException();
		}

		reprocessHIPolicy(map_HIBenefitsPackages);
	}

	/*
	* @author      	: 	Sanjay Paryani
	* @description  : 	This method will look for any matching Benefits_Package_Id__c on 
						HI_Policy__c with Id__c on HI_Benefits_Package__c and reprocess them.
	*/
	public void reprocessHIPolicy(Map<ID, HI_Benefits_Package__c> map_HIBenefitsPackages) {
		Map<String, HI_Benefits_Package__c> map_HIBenefitsPackageWithId = new Map<String, HI_Benefits_Package__c>();
		Map<Id, HI_Policy__c> map_HIPoliciesToReprocess = new Map<Id, HI_Policy__c>();

		try {
			for (HI_Benefits_Package__c objHIBenefitsPackage : map_HIBenefitsPackages.values()) {
				map_HIBenefitsPackageWithId.put(objHIBenefitsPackage.Id__c, objHIBenefitsPackage);
			}

			for (HI_Policy__c objHIPolicy : [
				SELECT ID, Benefits_Package_Id__c, Id__c
				FROM HI_Policy__c
				WHERE Benefits_Package_Id__c IN :map_HIBenefitsPackageWithId.keySet() AND Processing_State__c = :IntegrationUtils.BACKLOG
			]) {
				objHIPolicy.Processing_State__c = IntegrationUtils.QUEUED_STATE;
				map_HIPoliciesToReprocess.put(objHIPolicy.Id, objHIPolicy);
			}

			if (map_HIPoliciesToReprocess.size() > 0) {
				database.update(map_HIPoliciesToReprocess.values());
			}

			if (Test.isRunningTest() && HIBenefitsPackageTriggerHelperTest.blnRunCatchTest == true) {
				throw new DMLException('DML Exception occurred during testing');
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('HIBenefitsPackageTriggerHelper', 'reprocessHIPolicy', objEx.getMessage() + ' On Line ' + objEx.getLineNumber(), objEx.getStackTraceString());
		}
	}

	public void throwTestException() {
		if (Test.isRunningTest() && HIBenefitsPackageTriggerHelperTest.blnRunCatchHandlerTest == true) {
			throw new NullPointerException();
		}
	}
}