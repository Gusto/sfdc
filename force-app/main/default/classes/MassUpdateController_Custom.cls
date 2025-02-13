/*
    Name : MassUpdateOpportunityController_Custom
    DOC : October, 27 2017
    BY :PR
    Description : We are using this controller to mass udpate the Owner field of standard and custom objets.    
*/
public with sharing class MassUpdateController_Custom {
	private final ApexPages.StandardSetController cntr;
	private final PageReference fromPage;
	private final List<SObject> objs;
	private transient ApexPages.Message currentMsg;
	private Map<String, Schema.SObjectField> fieldMap;
	private final String newLine = '<br></br>';
	private String sType;
	private String currentStep;
	private Schema.SObjectField field;

	public opportunity oppRec { get; set; }
	public boolean hideRecordSection { get; set; }

	public MassUpdateController_Custom(ApexPages.StandardSetController controller) {
		hideRecordSection = false;
		oppRec = new Opportunity();
		currentStep = '1';
		controller.setPageSize(1000);
		cntr = (ApexPages.StandardSetController) controller;
		fromPage = cntr.cancel();
		Id recordId = (Id) ApexPages.CurrentPage().getParameters().get('id');

		if (!isMassUpdateEnabled()) {
			String msg = 'Mass-update is not allowed for the logged-in User. Please click Cancel button to return back.';
			currentMsg = new ApexPages.Message(ApexPages.severity.ERROR, msg);
			hideRecordSection = true;
		} else {
			// initially we are populating the selected records in the sobject list
			if (this.objs == null) {
				this.objs = (List<SObject>) cntr.getSelected();
			}
			// if no record is selected we are showing an error message
			if (getRecordSize() < 1) {
				String msg = 'No record was selected on the list view. Please click Cancel button and select records for mass update.';
				currentMsg = new ApexPages.Message(ApexPages.severity.ERROR, msg);
				hideRecordSection = true;
			} else {
				sType = discoverSObjectType(objs.get(0)).getName();
				String msg = 'Number of records selected for update: ' + getRecordSize();
				currentMsg = new ApexPages.Message(ApexPages.severity.INFO, msg);
				Schema.DescribeSObjectResult sObj = discoverSObjectType(objs.get(0));
				fieldMap = sObj.fields.getMap();
				field = fieldMap.get('OwnerId');
			}
		}
		ApexPages.addMessage(currentMsg);
	}

	public boolean isMassUpdateEnabled() {
		boolean isMassUpdateEnabled = false;
		List<User> userList = [SELECT id, Mass_Update_List_View__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

		if (userList != null && userList.size() > 0 && userList.get(0).Mass_Update_List_View__c) {
			isMassUpdateEnabled = true;
		}

		return isMassUpdateEnabled;
	}

	public String getStep() {
		return currentStep;
	}

	public integer getRecordSize() {
		if (objs != null) {
			return objs.size();
		} else {
			return 0;
		}
	}

	public PageReference cancel() {
		return fromPage;
	}

	public PageReference step2() {
		currentMsg = (new MassUpdater(objs, field, string.valueof(oppRec.OwnerId))).massUpdate();
		ApexPages.addMessage(currentMsg);
		currentStep = '2';
		return ApexPages.currentPage();
	}

	public DescribeSObjectResult discoverSObjectType(SObject s) {
		Map<String, Schema.SObjectType> des = Schema.getGlobalDescribe();

		for (Schema.SObjectType o : des.values()) {
			if (s.getSObjectType() == o) {
				return o.getDescribe();
			}
		}
		return null;
	}
}