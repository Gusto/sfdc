@isTest
private class CreateTransitionToSubmissionExt_test {
	@isTest
	static void CreateTransitionToSubmission() {
		AccounttriggerHelper.skipTrigger = true;
		OpportunitytriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		Id boRenewalRecType = cache.getRecordTypeId('Benefit_Order__c', 'New Plan');
		Benefit_Order__c ben = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(boRenewalRecType)
			.setStatusDetail('STATUS DETAIL')
			.setOwnerID(UserInfo.getUserId())
			.build();
		insert ben;
		Transition_to_Fulfillment__c ttf = new Transition_to_Fulfillment__c(
			Opportunity__c = ben.Opportunity__c,
			Existing_MDVLiDi_Coverage__c = 'Y'
		);
		insert ttf;

		Test.startTest();
		ApexPages.StandardController sc = new ApexPages.StandardController(ben);
		PageReference pageRef = Page.CreateTransitionToSubmission;
		pageRef.getParameters().put('id', String.valueOf(ben.Id));
		Test.setCurrentPage(pageRef);
		CreateTransitionToSubmissionExt dedit = new CreateTransitionToSubmissionExt(sc);
		dedit.initSubmission();
		dedit.initCare();
		Test.stopTest();
	}
}