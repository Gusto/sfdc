public class UR_IncentiveApprovalProcess implements Schedulable {
	public void execute(SchedulableContext sc) {
		sendApprovalEmail();
	}
	public void sendApprovalEmail() {
		try {
			String result = '';
			List<Research_Project_Master__c> lstUXRProject = new List<Research_Project_Master__c>();
			AggregateResult[] groupedResults = [
				SELECT count(Id) RowCount, Research_Project_Master__c
				FROM Research_Project_Detail__c
				WHERE Research_Participant_Status__c = 'Attended' AND Proposed_Incentive__c > 0 AND Applicable_for_Incentive__c = TRUE
				GROUP BY Research_Project_Master__c
			];
			for (AggregateResult ar : groupedResults) {
				result = ar.get('RowCount') + '';
				if (Integer.valueOf(result) > 0) {
					Research_Project_Master__c uxrObj = new Research_Project_Master__c();
					uxrObj.Id = ar.get('Research_Project_Master__c') + '';
					uxrObj.Incentive_Approval_Status__c = '';
					lstUXRProject.add(uxrObj);
				}
			}

			if (lstUXRProject.size() > 0) {
				UR_ProjectMasterTriggerHelper.skipTrigger = true;
				update lstUXRProject;
				for (Research_Project_Master__c uxrObj : lstUXRProject) {
					uxrObj.Incentive_Approval_Status__c = 'In progress';
				}
				update lstUXRProject;
				UR_ProjectMasterTriggerHelper.skipTrigger = false;
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('UR_IncentiveApprovalProcess', 'sendApprovalEmail', ex.getMessage(), ex.getStackTraceString());
		}
	}
}