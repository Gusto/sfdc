/***************************************************
Purpose : Update Carrier Order Implementation Stage to 'Approved'
Written By : Deepak Tyagi
Test Classes : CarrierOrderApproveExtTest
****************************************************/
public class CarrierOrderApproveExt {
	public Carrier_Order__c carrierObj { get; set; }
	// Boolean to show error on VF page
	public Boolean isError { get; set; }
	// Boolean to show Stage Detail for Tada Order
	public Boolean blnHasTadaOrder { get; set; }
	// Set to store all userId from Public Group
	set<Id> set_userPublicGroup;
	string coStage = null;
	public List<SelectOption> lstImplementationStage { get; set; }
	public List<SelectOption> lstImplementationStageDetail { get; set; }

	public CarrierOrderApproveExt(ApexPages.StandardController standardController) {
		isError = false;
		blnHasTadaOrder = false;
		set_userPublicGroup = new Set<Id>();
		String currentRecordId = ApexPages.CurrentPage().getparameters().get('id');

		// fetching carrier order related to Id in Parameter
		for (GroupMember gm : [SELECT Id, UserOrGroupId FROM GroupMember WHERE Group.Name = 'Order Stage Update Users']) {
			set_userPublicGroup.add(gm.UserOrGroupId);
		}
		carrierObj = [
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
			WHERE Id = :currentRecordId
		];
		coStage = carrierObj.Implementation_Stage__c;
		BindPickList();
		if (carrierObj.Implementation_Stage__c != 'Approved') {
			carrierObj.Implementation_Stage__c = 'Approved';
		} else {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Carrier Order is already approved.'));
			isError = true;
		}

		// Condition to check Tada carrier Order
		if (String.isNotBlank(carrierObj.Order_Type__c) && (carrierObj.Order_Type__c.contains('TAdA: Pre OE Setup'))) {
			blnHasTadaOrder = true;
			if (
				carrierObj.OwnerId != UserInfo.getUserId() &&
				carrierObj.Confirmation_Owner__c != UserInfo.getUserId() &&
				!set_userPublicGroup.contains(UserInfo.getUserId()) &&
				(carrierObj.Benefit_Order__c != null &&
				carrierObj.Benefit_Order__r.OwnerId != UserInfo.getUserId())
			) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.TadaOrderError));
				isError = true;
			}
		}

		//Get Carrier name from  Custom Settings
		//Changes by AKS dated 10th Sept 2019
		//Given by Ashveej
		//If associated carrier name is BASIC then no tada error should not come
		boolean showNoTadaError = true;
		String strCarrierName = String.valueOf(Configuration_Settings__c.getInstance().Carrier_Name__c);
		if (strCarrierName != null && carrierObj.Carrier__c != null && strCarrierName.indexOf(carrierObj.Carrier__r.Name) > -1) {
			showNoTadaError = false;
		}
		// Condition to check Non Tada carrier Order
		if (
			showNoTadaError == true &&
			(String.isBlank(carrierObj.Order_Type__c) ||
			(String.isNotBlank(carrierObj.Order_Type__c) &&
			!carrierObj.Order_Type__c.contains('TAdA: Pre OE Setup') &&
			!carrierObj.Order_Type__c.contains('TAdA: No Pre OE Setup'))) &&
			!set_userPublicGroup.contains(UserInfo.getUserId()) &&
			(carrierObj.Confirmation_Owner__c != UserInfo.getUserId() &&
			carrierObj.Audit_Owner__c != UserInfo.getUserId() &&
			(carrierObj.Benefit_Order__c != null &&
			carrierObj.Benefit_Order__r.OwnerId != UserInfo.getUserId()))
		) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.NonTadaOrderError));
			isError = true;
		}
	}

	private void BindPickList() {
		lstImplementationStage = new List<SelectOption>();
		String recordTypeName = Schema.getGlobalDescribe().get('Carrier_Order__c').getDescribe().getRecordTypeInfosById().get(carrierObj.recordTypeId).getName();
		for (SelectOption status : Cache.getFieldPickListValues('Carrier_Order__c', 'Implementation_Stage__c')) {
			//Changes by DS dated 02nd Nov 2019
			//Given by Ashveej
			if (
				status.getLabel().equalsIgnoreCase('Approved Pending EE Audit') &&
				carrierObj != null &&
				carrierObj.Order_Type__c != null &&
				(carrierObj.Order_Type__c.contains('Same carrier, plan/group level changes') ||
				carrierObj.Order_Type__c.contains('Same Carrier, NO Plan/Group Level Changes') ||
				carrierObj.Order_Assignment__c == 'Same Carrier, NO Plan/Group Level Changes' ||
				carrierObj.Order_Assignment__c == 'Same carrier, plan/group level changes')
			) {
				continue;
			}

			if (status.getLabel().containsIgnoreCase('Approved')) {
				lstImplementationStage.add(status);
			}
			if (recordTypeName == 'Renewal' && status.getLabel().containsIgnoreCase('Approved Pending EE Audit')) {
				lstImplementationStage.add(status);
			}
		}
		lstImplementationStageDetail = new List<SelectOption>();
		lstImplementationStageDetail.add(new SelectOption('', '--None--'));
		lstImplementationStageDetail.add(new SelectOption('TAdA Setup Complete', 'TAdA Setup Complete'));
	}

	// Method to update Carrier Order
	public PageReference updateCarrier() {
		List<Carrier_Order__c> lstToUpdateCO = new List<Carrier_Order__c>();
		try {
			// Condition to check Order Type
			if (String.isNotBlank(carrierObj.Order_Type__c) && carrierObj.Order_Type__c.contains('TAdA: Pre OE Setup') && String.isBlank(carrierObj.Stage_Detail__c)) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please select Stage Detail.'));
				return null;
			}
			lstToUpdateCO.add(carrierObj);
			for (Carrier_Order__c co : [SELECT Id, Implementation_Stage__c, Stage_Detail__c FROM Carrier_Order__c WHERE Parent_Carrier_Order__c = :carrierObj.Id]) {
				co.Implementation_Stage__c = carrierObj.Implementation_Stage__c;
				co.Stage_Detail__c = carrierObj.Stage_Detail__c;
				co.Approval_Notes__c = carrierObj.Approval_Notes__c;
				lstToUpdateCO.add(co);
			}
			if (!lstToUpdateCO.isEmpty()) {
				update lstToUpdateCO;
			}

			// By: Deepak Tyagi, Date: June 3, 2019 Desc: Update Benefit Order Status and Status Detail on Carrier Order approval
			if (carrierObj.Benefit_Order__c != null) {
				Benefit_Order__c bo = new Benefit_Order__c(Id = carrierObj.Benefit_Order__c);

				// [SM] : commented out
				//bo.Order_Status__c = carrierObj.Implementation_Stage__c;
				if (
					carrierObj.Implementation_Stage__c == 'Approved' &&
					carrierObj.Order_Type__c != null &&
					carrierObj.Order_Type__c.contains('TAdA: Pre OE Setup') &&
					carrierObj.Stage_Detail__c == 'TAdA Setup Complete'
				)
					bo.Status_Detail__c = 'TAdA Setup Complete';

				BenefitOrderHelper.skipTrigger = true;
				update bo;
				BenefitOrderHelper.skipTrigger = false;
			}

			PageReference pageRef = new PageReference('/' + carrierObj.Id);
			pageRef.setRedirect(true);
			return pageRef;
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Error in updating Carrier Order.'));
			ExceptionLogUtil.logException('CarrierOrderApproveExt', 'updateCarrier', e.getMessage(), e.getStackTraceString());
			return null;
		}
	}
}