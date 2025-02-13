/**
@Created by : Deepesh Rao
@Created Date : 17-Oct-2023
@Desc : Batch class to update R&D Tax Credits case when an email is replied to from case
@see : BatchUpdateFirstResponseDateCaseTest
**/
public class BatchUpdateFirstResponseDateCase implements Database.Batchable<sObject> {
	List<Case> list_updateCaseList = new List<Case>();
	public Database.QueryLocator start(Database.BatchableContext context) {
		String strQuery =
			'SELECT Id,First_Response_Time__c,(SELECT Id,CreatedDate FROM EmailMessages WHERE (Status=\'2\' OR Status=\'3\') AND Incoming=false AND ParentId!=null ORDER BY CreatedDate ASC LIMIT 1) FROM Case WHERE ' +
			Label.First_Response_Time_Query;
		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext context, List<Case> list_caseRecords) {
		try {
			for (Case objCase : list_caseRecords) {
				if (objCase.EmailMessages != null && !objCase.EmailMessages.IsEmpty()) {
					for (EmailMessage objEmailMessage : objCase.EmailMessages) {
						if (objCase.First_Response_Time__c != null && objCase.First_Response_Time__c > objEmailMessage.CreatedDate) {
							objCase.First_Response_Time__c = objEmailMessage.CreatedDate;
							list_updateCaseList.add(objCase);
						} else if (objCase.First_Response_Time__c == null) {
							objCase.First_Response_Time__c = objEmailMessage.CreatedDate;
							list_updateCaseList.add(objCase);
						}
					}
				}
			}
			if (list_UpdateCaseList != null && !list_UpdateCaseList.IsEmpty()) {
				update list_updateCaseList;
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('BatchUpdateFirstResponseDateCase', 'execute', null, objException);
		}
	}

	public void finish(Database.BatchableContext BC) {
	}
}