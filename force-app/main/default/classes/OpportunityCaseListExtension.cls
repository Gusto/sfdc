/**
 * @description  Retrives cases related to converted opportunity account and lead
 * @author       Praveen Sethu
 * @date         1/5/2022
 * @see          OpportunityCaseListExtensionTest
 **/
public class OpportunityCaseListExtension {
	private Opportunity objOppty;
	private Id idLead;

	/**
	 * @description Class constructor. Initializes opportunity and lead variables
	 * @author      Praveen Sethu
	 * @param       standard controller
	 * @return      NA
	 **/
	public OpportunityCaseListExtension(ApexPages.StandardController controller) {
		objOppty = (Opportunity) controller.getRecord();
		objOppty = [SELECT Id, AccountId FROM Opportunity WHERE Id = :objOppty.Id];
		// Fetch lead information from converted opportunity
		if (objOppty.AccountId != null) {
			List<Lead> list_Leads = [SELECT Id FROM Lead WHERE ConvertedAccountId = :objOppty.AccountId];
			idLead = !list_Leads.isEmpty() ? list_Leads.get(0).Id : idLead;
		}
	}

	/**
	 * @description Queries list of cases related to opportunities' account and leads
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      List of related cases
	 **/
	public List<Case> getCases() {
		Id idAccount = objOppty.AccountId;
		String strQuery = 'SELECT Id, CaseNumber, Subject, Status, Type, Status_Detail__c, Owner.Name FROM Case WHERE (AccountId = :idAccount AND AccountId != NULL)';
		if (idLead != null) {
			strQuery = strQuery + ' OR (Lead__c = :idLead)';
		}
		return Database.query(strQuery);
	}
}