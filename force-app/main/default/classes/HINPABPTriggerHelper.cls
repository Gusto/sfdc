/*
 * @name         : HINPABPTriggerHelper
 * @author       : Sanjay Paryani
 * @date         : 06-04-2021
 * @description  : HI_New_Plans_ApplicationsBenefitsPackage__c Trigger Logic
 * @test classes : HINPABPTriggerHelperTest
 */
public without sharing class HINPABPTriggerHelper {
	public static boolean skipTrigger = false;

	public void processAfterInsert(Map<ID, HI_New_Plans_ApplicationsBenefitsPackage__c> map_HINPABenefitsPackages) {
		if (Test.isRunningTest()) {
			throwTestException();
		}
        
        reprocessHIPolicy(map_HINPABenefitsPackages);
	}

	/*
	* @author      	: 	Sanjay Paryani
	* @description  : 	This method will look for any matching Benefits_Package_Id__c on 
						HI_Policy__c with Id__c on HI_New_Plans_ApplicationsBenefitsPackage__c and reprocess them.
	*/
	public void reprocessHIPolicy(Map<ID, HI_New_Plans_ApplicationsBenefitsPackage__c> map_HINPABenefitsPackages) {
		Map<String, HI_New_Plans_ApplicationsBenefitsPackage__c> map_HINPABenefitsPackageWithId = new Map<String, HI_New_Plans_ApplicationsBenefitsPackage__c>();
		Map<Id, HI_Policy__c> map_HIPoliciesToReprocess = new Map<Id, HI_Policy__c>();

		try {
			for (HI_New_Plans_ApplicationsBenefitsPackage__c objHINPABenefitsPackage : map_HINPABenefitsPackages.values()) {
				map_HINPABenefitsPackageWithId.put(objHINPABenefitsPackage.Benefits_Package_Id__c, objHINPABenefitsPackage);
			}

			for (HI_Policy__c objHIPolicy : [
				SELECT ID, Benefits_Package_Id__c, Id__c
				FROM HI_Policy__c
				WHERE
					Benefits_Package_Id__c IN :map_HINPABenefitsPackageWithId.keySet()
					AND Processing_State__c = :IntegrationUtils.BACKLOG
			]) {
				objHIPolicy.Processing_State__c = IntegrationUtils.QUEUED_STATE;
				map_HIPoliciesToReprocess.put(objHIPolicy.Id, objHIPolicy);
			}

			if (map_HIPoliciesToReprocess.size() > 0) {
				database.update(map_HIPoliciesToReprocess.values());
			}

			if (Test.isRunningTest() && HINPABPTriggerHelperTest.blnRunCatchTest == true) {
				throw new DMLException('DML Exception occurred during testing');
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException(
				'HINPABPTriggerHelper',
				'reprocessHIPolicy',
				objEx.getMessage() +
				' On Line ' +
				objEx.getLineNumber(),
				objEx.getStackTraceString()
			);
		}
	}
    
	public void throwTestException() {
		if (Test.isRunningTest() && HINPABPTriggerHelperTest.blnRunCatchHandlerTest == true) {
			throw new NullPointerException();
		}
	}    
}