/**
 * @name         : UnblockBenefitOrderExt
 * @author       : Deepika saini
 * @date         : 03-17-2021
 * @description  : Re-calculate the BO status to be the earliest of the associated CO stages.
 * @test classes : UnblockBenefitOrderExtTest
 **/

public with sharing class UnblockBenefitOrderExt {
	private Benefit_Order__c objBenefitOrder;
	public Boolean blnUnBlockPermissionError { get; set; }
	public Map<Id, Benefit_Order__c> map_BenefitOrdersToUpdate = new Map<Id, Benefit_Order__c>();
	static final String BO_ALREADY_UNBLOCKED_MESSAGE = 'Benefit Order record is already Unblocked.';
	static final String BO_UNBLOCKED_BY_OA_ONLY_MESSAGE = 'Benefit Order record can only be Unblocked by Onboarding Advocate.';
	static final String CO_ALREADY_BLOCKED_MESSAGE = 'Order is blocked at CO level. Move COs to appropriate stage and then Un-block';

	public UnblockBenefitOrderExt(ApexPages.StandardController objBOStandardCntrl) {
		objBenefitOrder = (Benefit_Order__c) objBOStandardCntrl.getRecord();
		blnUnBlockPermissionError = false;
		permissionCheck();
	}

	public PageReference unblockBenefitOrder() {
		if (!blnUnBlockPermissionError) {
			CarrierOrderTriggerHelper.populateOrderStatusForNonBoR(
				new Set<Id>{ objBenefitOrder.Id },
				map_BenefitOrdersToUpdate,
				true
			);

			try {
				if (!map_BenefitOrdersToUpdate.isEmpty()) {
					update map_BenefitOrdersToUpdate.values();
				}
			} catch (Exception objException) {
				ApexPages.addMessage(new apexPages.Message(ApexPages.severity.ERROR, objException.getMessage()));
				return null;
			}

			PageReference pageRef = new PageReference('/' + objBenefitOrder.Id);
			return pageRef;
		}
		return null;
	}

	public PageReference cancel() {
		PageReference pageRef = new PageReference('/' + objBenefitOrder.Id);
		return pageRef;
	}

	//only OA should have the permission to cancel the record
	void permissionCheck() {
		objBenefitOrder = [
			SELECT
				Id,
				OwnerId,
				Order_Status__c,
				(
					SELECT Id, Implementation_Stage__c
					FROM Carrier_Orders__r
					WHERE Implementation_Stage__c = :BenefitOrderUtil.STATUS_BLOCKED
				)
			FROM Benefit_Order__c
			WHERE Id = :objBenefitOrder.Id
			LIMIT 1
		];

		if (
			objBenefitOrder.Order_Status__c != null &&
			objBenefitOrder.Order_Status__c != BenefitOrderUtil.STATUS_BLOCKED
		) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, BO_ALREADY_UNBLOCKED_MESSAGE));
			blnUnBlockPermissionError = true;
		}

		if (objBenefitOrder.OwnerId != UserUtils.ID_CURRENT_USER) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, BO_UNBLOCKED_BY_OA_ONLY_MESSAGE));
			blnUnBlockPermissionError = true;
		}

		if (objBenefitOrder.Carrier_Orders__r != null && objBenefitOrder.Carrier_Orders__r.size() > 0) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CO_ALREADY_BLOCKED_MESSAGE));
			blnUnBlockPermissionError = true;
		}
	}
}