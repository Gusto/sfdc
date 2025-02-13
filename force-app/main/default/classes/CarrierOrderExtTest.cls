@isTest
private class CarrierOrderExtTest {
	static Carrier_Order__c carrierOrder;
	static CarrierOrderExt ext;

	@isTest
	static void setStageToDenied() {
		givenTheImplementationStageIs('New');
		setupTestRun();
		List<String> additionalFields = ext.additionalFields;
		whenActionIsStageDenied();
	}
    
    /*
	 * @author:         Udit Jain
	 * @description:    To update the BO status when stage in Rady for early submission.
	 * @parm:           NA
	 * @return:         Void
	 */
    @IsTest
    static void setStageBOOrderStatus() {
        givenTheImplementationStageIs(CarrierOrderUtil.IMPLEMENTATION_STAGE_READY_FOR_EARLY_SUBMISSION);
        setupTestRun();
        List<String> additionalFields = ext.additionalFields;
        List<Benefit_Order__c> list_BO = [Select Id,Order_Status__c From Benefit_Order__c WHERE Id =: carrierOrder.Benefit_Order__c Limit 1];
        list_BO[0].Order_Status__c = CarrierOrderUtil.CO_STATUS_READY_FOR_OE_PREP;
        BenefitOrderHelper.skipTrigger = true;
        update list_BO;
        whenActionIsStageUpdationToBOStatus();
        System.assertEquals(list_BO[0].Order_Status__c, carrierOrder.Implementation_Stage__c);
	}

	@isTest
	static void setStageToCanceled() {
		givenTheImplementationStageIs('New');
		setupTestRun();
		whenActionIsStageCanceled();
		thenSObjectImplementationStageIs('Canceled');
		thenTheImplementationStageIs('New');
	}

	@isTest
	static void nextStageFromNew() {
		givenTheImplementationStageIs('With Advising');
		setupTestRun();
		whenActionIsNextStage();
		thenTheImplementationStageIs('With Sales');
	}

	@isTest
	static void nextStageFromApproved() {
		givenTheImplementationStageIs('Approved');
		setupTestRun();
		whenActionIsNextStage();
		thenTheImplementationStageIs('Approved');
	}

	@isTest
	static void nextStageFromActivated() {
		AccountTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		givenTheImplementationStageIs('Canceled');
		setupTestRun();
		whenActionIsNextStage();
		thenTheImplementationStageIs('Canceled');
	}

	static void givenCarrierOrderIsSet() {
		TestUtility.CarrierOrder();
		carrierOrder = getCarrierOrder();
	}

	static void givenTheImplementationStageIs(String value) {
		TestUtility.CarrierOrderWithStage(value);
		carrierOrder = getCarrierOrder();
		System.assertEquals(value, carrierOrder.Implementation_Stage__c);
	}

	static void whenActionIsNextStage() {
		Test.startTest();
		ext.nextStage();
		Test.stopTest();
	}

	static void whenActionIsStageDenied() {
		Test.startTest();
		ext.stageDenied();
		Test.stopTest();
	}
    
    /*
	 * @author:         Udit Jain
	 * @description:    To update the BO status when stage in Rady for early submission.
	 * @parm:           NA
	 * @return:         Void
	 */
    static void whenActionIsStageUpdationToBOStatus() {
		Test.startTest();
		ext.stageBOOrderStatus();
		Test.stopTest();
        List<Benefit_Order__c> list_BO = [Select Id,Order_Status__c From Benefit_Order__c WHERE Id =: carrierOrder.Benefit_Order__c Limit 1];
        System.assertEquals(list_BO[0].Order_Status__c, carrierOrder.Implementation_Stage__c);
	}

	static void whenActionIsStageCanceled() {
		Test.startTest();
		ext.stageCanceled();
		Test.stopTest();
	}

	static void thenTheImplementationStageIs(String value) {
		carrierOrder = getCarrierOrder();
		System.assertEquals(value, carrierOrder.Implementation_Stage__c, 'Implementation Stage was not set to ' + carrierOrder.Implementation_Stage__c);
	}

	static void thenSObjectImplementationStageIs(String value) {
		System.assertEquals('', carrierOrder.Implementation_Stage__c, 'SObject Implementation Stage not updated to ' + value);
	}

	static void thenValidationRuleFired() {
	}

	static Carrier_Order__c getCarrierOrder() {
		return [SELECT Id, Closed__c, Implementation_Stage__c, Benefit_Order__c FROM Carrier_Order__c];
	}

	static void setupTestRun() {
		ApexPages.StandardController stdCon = new ApexPages.StandardController(carrierOrder);
		ext = new CarrierOrderExt(stdCon);
		System.assertNotEquals(null, ext);
	}
}