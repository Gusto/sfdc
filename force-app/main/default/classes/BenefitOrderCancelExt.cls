public without sharing class BenefitOrderCancelExt {
	private Benefit_Order__c ben;
	public Boolean blnBORPermissionError { get; set; }
	public Boolean blnNewPlanOrRenewalOrder { get; set; }
	public BenefitOrderCancelExt(ApexPages.StandardController controller) {
		ben = (Benefit_Order__c) controller.getRecord();
		if (
			ben.RecordTypeId == BenefitOrderHelper.BO_REC_TYPE_ID_CHANGE ||
			ben.RecordTypeId == BenefitOrderHelper.BO_REC_TYPE_ID_NEW_PLAN ||
			ben.RecordTypeId == BenefitOrderHelper.BO_REC_TYPE_ID_RENEWAL
		) {
			blnNewPlanOrRenewalOrder = true;
		} else {
			blnNewPlanOrRenewalOrder = false;
		}
		blnBORPermissionError = false;
		permissionCheck();
		setOrderStatusToCanceled();
	}

	public void setOrderStatusToCanceled() {
		ben.Order_Status__c = 'Canceled';
	}

	public PageReference cancelBenefitOrder() {
		Map<Id, Ticket__c> map_OpenTicketsWithBO = BenefitOrderUtil.fetchOpenTicketsRelatedToBO(new Set<Id>{ ben.Id });

		if (!map_OpenTicketsWithBO.isEmpty()) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, BenefitOrderUtil.MSQ_CLOSE_OPEN_TICKET_FIRST));
			return null;
		}

		setOrderStatusToCanceled();
		try {
			update ben;
		} catch (Exception objExp) {
			ApexPages.addMessage(new apexPages.Message(ApexPages.severity.ERROR, objExp.getMessage()));
			return null;
		}

		PageReference objPageRef = new PageReference('/' + ben.Id);
		return objPageRef;
	}

	/**BY: PR, Date: Feb/12/20, Desc: for BOR type of BO only qualifier and Owner should have the permission to cancel the record */
	void permissionCheck() {
		if (ben.recordTypeId == Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR')) {
			set<Id> set_userPublicGroup = new Set<Id>();
			ben = [SELECT Id, Opportunity__r.OwnerId, OwnerId, Status_Detail__c, Additional_Details__c FROM Benefit_Order__c WHERE Id = :ben.Id LIMIT 1];
			for (GroupMember gm : [SELECT Id, UserOrGroupId FROM GroupMember WHERE Group.Name = 'BT Order status update users']) {
				set_userPublicGroup.add(gm.UserOrGroupId);
			}

			string str_LoggedINUserId = UserInfo.getUserId();
			if (
				!(ben.OwnerId == str_LoggedINUserId ||
				ben.Opportunity__r.OwnerId == str_LoggedINUserId ||
				set_userPublicGroup.contains(ben.OwnerId) ||
				set_userPublicGroup.contains(ben.Opportunity__r.OwnerId))
			) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Benefit Order record can only be cancelled by Qualifier or Advocate.'));
				blnBORPermissionError = true;
			}
		}
	}
}