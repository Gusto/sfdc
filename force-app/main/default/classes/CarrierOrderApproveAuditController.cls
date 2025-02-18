/*
 * Description: Contains methods to set the approve audit options
 * Author: Omar Benitez
 * Date: 05/05/2024
 */
public without sharing class CarrierOrderApproveAuditController {
	static final String TADA_PRE_OE_SETUP = 'TAdA: Pre OE Setup';
	static final String TADA_NO_PRE_OE_SETUP = 'TAdA: No Pre OE Setup';
	static final String ORDER_STAGE_UPDATE_USERS = 'Order Stage Update Users';
	static final String SAME_CARRIER_NO_PLAN = 'Same Carrier, NO Plan/Group Level Changes';
	static final String SAME_CARRIER_PLAN = 'Same carrier, plan/group level changes';
	static final String APPROVED = 'Approved';
	static final String TADA_SETUP_COMPLETE = 'TAdA Setup Complete';
	static final String APPROVED_PENDING_EE_AUDIT = 'Approved Pending EE Audit';
	static final String CO_FIELD = 'Carrier_Order__c';
	static final String IMP_STAGE_FIELD = 'Implementation_Stage__c';
	static final String IMP_STAGE_OPTS = 'implementationStageOptions';
	static final String IMP_STAGE_DET_OPTS = 'implementationStageDetailOptions';
	static final String ERROR = 'error';
	static final String CO_ALR_APPROVED = 'Carrier Order is already approved.';
	static final String IMP_STAGE_RET = 'implementationStage';
	static final String CO_OBJ_RET = 'objCarrierOrder';
	static final String HAS_TADA_RET = 'blnHasTadaOrder';
	static final String ERROR_SELECT_STAGE_DET = 'Please select Stage Detail.';
	static final String ERROR_SAVING_CO = 'Error updating Carrier Order.';

	/* Method will return all the related options for the approve audit combos */
	@AuraEnabled(cacheable=true)
	public static Map<String, Object> getOptions(String strCarrierOrderId) {
		Map<String, Object> map_response = new Map<String, Object>();
		Boolean blnHasTadaOrder = false;
		Set<Id> set_userPublicGroup = new Set<Id>();

		// fetching carrier order related to Id in Parameter
		for (GroupMember gm : [SELECT Id, UserOrGroupId FROM GroupMember WHERE Group.Name = :ORDER_STAGE_UPDATE_USERS]) {
			set_userPublicGroup.add(gm.UserOrGroupId);
		}
		Carrier_Order__c objCarrierOrder = [
			SELECT
				Id,
				Benefit_Order__c,
				Benefit_Order__r.OwnerId,
				RecordTypeId,
				Order_Assignment__c,
				Benefit_Order__r.Order_Status__c,
				Benefit_Order__r.Status_Detail__c,
				Order_Type__c,
				Implementation_Stage__c,
				Stage_Detail__c,
				Approval_Notes__c,
				OwnerId,
				Confirmation_Owner__c,
				Audit_Owner__c,
				Carrier__c,
				Carrier__r.Name,
				Approval_Method__c
			FROM Carrier_Order__c
			WHERE Id = :strCarrierOrderId
		];

		Map<String, String> map_ImplementationStage = new Map<String, String>();
        String recordTypeName = Schema.getGlobalDescribe().get('Carrier_Order__c').getDescribe().getRecordTypeInfosById().get(objCarrierOrder.recordTypeId).getName();
		for (SelectOption status : Cache.getFieldPickListValues(CO_FIELD, IMP_STAGE_FIELD)) {
			if (
                
				(recordTypeName != 'Renewal' && status.getLabel().equalsIgnoreCase(APPROVED_PENDING_EE_AUDIT)) &&
				objCarrierOrder != null &&
				objCarrierOrder.Order_Type__c != null &&
				(objCarrierOrder.Order_Type__c.contains(SAME_CARRIER_PLAN) ||
				objCarrierOrder.Order_Type__c.contains(SAME_CARRIER_NO_PLAN) ||
				objCarrierOrder.Order_Assignment__c == SAME_CARRIER_NO_PLAN ||
				objCarrierOrder.Order_Assignment__c == SAME_CARRIER_PLAN)
			) {
				continue;
			}

			if (status.getLabel().containsIgnoreCase(APPROVED)) {
				map_ImplementationStage.put(status.getValue(), status.getLabel());
			}
		}
		map_response.put(IMP_STAGE_OPTS, map_ImplementationStage);
		Map<String, String> map_ImplementationStageDetail = new Map<String, String>();
		map_ImplementationStageDetail.put(TADA_SETUP_COMPLETE, TADA_SETUP_COMPLETE);
		map_response.put(IMP_STAGE_DET_OPTS, map_ImplementationStageDetail);

		if (objCarrierOrder.Implementation_Stage__c != APPROVED) {
			objCarrierOrder.Implementation_Stage__c = APPROVED;
		} else {
			map_response.put(ERROR, CO_ALR_APPROVED);
		}

		// Condition to check Tada carrier Order
		if (String.isNotBlank(objCarrierOrder.Order_Type__c) && (objCarrierOrder.Order_Type__c.contains(TADA_PRE_OE_SETUP))) {
			blnHasTadaOrder = true;
			if (
				objCarrierOrder.OwnerId != UserInfo.getUserId() &&
				objCarrierOrder.Confirmation_Owner__c != UserInfo.getUserId() &&
				!set_userPublicGroup.contains(UserInfo.getUserId()) &&
				(objCarrierOrder.Benefit_Order__c != null &&
				objCarrierOrder.Benefit_Order__r.OwnerId != UserInfo.getUserId())
			) {
				map_response.put(ERROR, Label.TadaOrderError);
			}
		}

		//Get Carrier name from  Custom Settings
		//If associated carrier name is BASIC then no tada error should not come
		Boolean  blnShowNoTadaError = true;
		String strCarrierName = String.valueOf(Configuration_Settings__c.getInstance().Carrier_Name__c);
		if (strCarrierName != null && objCarrierOrder.Carrier__c != null && strCarrierName.indexOf(objCarrierOrder.Carrier__r.Name) > -1) {
			blnShowNoTadaError = false;
		}
		// Condition to check Non Tada carrier Order
		if (
			blnShowNoTadaError == true &&
			(String.isBlank(objCarrierOrder.Order_Type__c) ||
			(String.isNotBlank(objCarrierOrder.Order_Type__c) &&
			!objCarrierOrder.Order_Type__c.contains(TADA_PRE_OE_SETUP) &&
			!objCarrierOrder.Order_Type__c.contains(TADA_NO_PRE_OE_SETUP))) &&
			!set_userPublicGroup.contains(UserInfo.getUserId()) &&
			(objCarrierOrder.Confirmation_Owner__c != UserInfo.getUserId() &&
			objCarrierOrder.Audit_Owner__c != UserInfo.getUserId() &&
			(objCarrierOrder.Benefit_Order__c != null &&
			objCarrierOrder.Benefit_Order__r.OwnerId != UserInfo.getUserId()))
		) {
			map_response.put(ERROR, Label.NonTadaOrderError);
		}

		map_response.put(IMP_STAGE_RET, objCarrierOrder.Implementation_Stage__c);
		map_response.put(CO_OBJ_RET, objCarrierOrder);
		map_response.put(HAS_TADA_RET, blnHasTadaOrder);
		return map_response;
	}

	/* Method will valudate the Carrier Order and save it */
	@AuraEnabled
	public static Object saveOrder(Carrier_Order__c objCarrierOrder) {
		List<Carrier_Order__c> lstToUpdateCO = new List<Carrier_Order__c>();
		try {
			// Condition to check Order Type
			if (String.isNotBlank(objCarrierOrder.Order_Type__c) && objCarrierOrder.Order_Type__c.contains(TADA_PRE_OE_SETUP) && String.isBlank(objCarrierOrder.Stage_Detail__c)) {
				return ERROR_SELECT_STAGE_DET;
			}
			lstToUpdateCO.add(objCarrierOrder);
			for (Carrier_Order__c co : [SELECT Id, Implementation_Stage__c, Stage_Detail__c FROM Carrier_Order__c WHERE Parent_Carrier_Order__c = :objCarrierOrder.Id]) {
				co.Implementation_Stage__c = objCarrierOrder.Implementation_Stage__c;
				co.Stage_Detail__c = objCarrierOrder.Stage_Detail__c;
				co.Approval_Notes__c = objCarrierOrder.Approval_Notes__c;
				co.Approval_Method__c = objCarrierOrder.Approval_Method__c;
				lstToUpdateCO.add(co);
			}
			if (!lstToUpdateCO.isEmpty()) {
				update lstToUpdateCO;
			}

			// Update Benefit Order Status and Status Detail on Carrier Order approval
			if (objCarrierOrder.Benefit_Order__c != null) {
				Benefit_Order__c bo = new Benefit_Order__c(Id = objCarrierOrder.Benefit_Order__c);
				if (
					objCarrierOrder.Implementation_Stage__c == APPROVED &&
					objCarrierOrder.Order_Type__c != null &&
					objCarrierOrder.Order_Type__c.contains(TADA_PRE_OE_SETUP) &&
					objCarrierOrder.Stage_Detail__c == TADA_SETUP_COMPLETE
				) {
					bo.Status_Detail__c = TADA_SETUP_COMPLETE;
				}
				BenefitOrderHelper.skipTrigger = true;
				update bo;
				BenefitOrderHelper.skipTrigger = false;
			}
		} catch (Exception e) {
			return e;
		}
		return null;
	}
}