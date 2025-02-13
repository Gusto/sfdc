public class UR_CloseProjectBatch implements Database.Batchable<sObject>, Database.Stateful {
	public string projectId;
	public string projectStatus;
	public Database.QueryLocator start(Database.BatchableContext bc) {
		String strQuery =
			'SELECT Research_Project_Master__r.Type_of_Research__c, Contact__c ' +
			'FROM Research_Project_Detail__c ' +
			'WHERE Research_Project_Master__c = :projectId ' +
			'AND Research_Project_Master__r.Type_of_Research__c != \'' +
			UR_NewEditProjectCtrl.UNMODERATED_SURVEY +
			'\' ' +
			'AND Research_Project_Master__r.Type_of_Research__c != \'' +
			UR_NewEditProjectCtrl.OTHER_SURVEY +
			'\' ';

		return Database.getQueryLocator(strQuery);
	}
	public void execute(Database.BatchableContext bc, List<Research_Project_Detail__c> scope) {
		enableDisableContactTrigger(true);
		try {
			List<Contact> lstUpdateContact = new List<Contact>();
			Date dt = null;
			if ('Complete' == projectStatus) {
				dt = Date.today();
			}

			for (Research_Project_Detail__c rpd : scope) {
				Contact contactObj = new Contact(id = rpd.Contact__c);
				contactObj.UR_Recent_Project_Completion_date__c = dt;
				lstUpdateContact.add(contactObj);
			}

			if (lstUpdateContact != null && lstUpdateContact.size() > 0) {
				update lstUpdateContact;
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('UR_CloseProjectBatch', 'execute', ex.getMessage(), ex.getStackTraceString());
		}
		enableDisableContactTrigger(false);
	}

	public void finish(Database.BatchableContext bc) {
		enableDisableContactTrigger(false);
	}

	public void enableDisableContactTrigger(boolean flag) {
		ContactTriggerHelper.skipTrigger = flag;
		AccountTriggerHelper.skipTrigger = flag;
		CampaignMemberTriggerHelper.skipTrigger = flag;
	}
}