public with sharing class HIBenefitChangeApplicationQueue implements Queueable {
	private List<HI_Benefit_Change_Application__c> changeList;

	public HIBenefitChangeApplicationQueue(List<HI_Benefit_Change_Application__c> inputChangeList) {
		changeList = inputChangeList;
	}

	public void execute(QueueableContext context) {
		HIBenefitChangeApplicationTriggerHelper.queue = true;
		if (changeList.size() > 0) {
			update changeList;
		}
	}
}