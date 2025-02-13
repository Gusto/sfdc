/**
 * @name         : BenefitOrderAssignOrReassignBatch
 * @author       : Neha Dabas
 * @date         : 04-5-2021
 * @description  : Sends mass email to cases
 * @test classes : MassEmailUtilTest
 **/
public class BenefitOrderAssignOrReassignBatch implements Database.Batchable<sObject> {
	Set<Id> set_AllBOIds;
	Boolean blnIsOOOAssignment;

	public BenefitOrderAssignOrReassignBatch(Set<Id> set_BOIds, Boolean blnIsOOOAssign) {
		this.set_AllBOIds = set_BOIds;
		this.blnIsOOOAssignment = blnIsOOOAssign;
	}

	public Database.QueryLocator start(Database.BatchableContext objBC) {
		Set<String> set_BOStatus = new Set<string>{
			BenefitOrderUtil.STATUS_CANCELLED,
			BenefitOrderUtil.STATUS_CLOSED_LOST,
			BenefitOrderUtil.STATUS_CLOSED_ADMIN
		};
		Set<Id> set_BORecTypeIdsToExclude = new Set<Id>{
			BenefitOrderUtil.BoR_BENEFIT_ORDER_RT_ID,
			BenefitOrderUtil.RENEWAL_ALIGNMENT_BENEFIT_ORDER_RT_ID
		};

		String strQuery = 'SELECT Parent_Benefit_Order__c, Initial_Owner__c, Type__c, OwnerId, Tier__c, Account__c, RecordTypeId, Order_Status__c, Partner_Tier__c, Assignment_State__c, Coverage_Effective_Date__c, Opportunity__c, Coverage_Effective_Month__c, Coverage_Effective_Year__c, Account__r.Priority_Support__c, Maestro__c FROM Benefit_Order__c WHERE RecordTypeId NOT IN :set_BORecTypeIdsToExclude AND Id IN :set_AllBOIds AND Order_Status__c NOT IN :set_BOStatus';
		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext objBC, List<Benefit_Order__c> list_BenefitOrders) {
		try {
			Set<Id> set_BOIds = new Set<Id>();
			for (Benefit_Order__c objBO : list_BenefitOrders) {
				set_BOIds.add(objBO.Id);
			}
			BenefitOrderAssignOrReassignUtil.assignOrReassignBenefitOrders(blnIsOOOAssignment, list_BenefitOrders, set_BOIds);
		} catch (Exception objException) {
			String strExceptionMessage = 'Exception On Line ' + objException.getLineNumber() + '-' + objException.getMessage();
			ExceptionLogUtil.logException('BenefitOrderAssignOrReassignBatch', 'execute', strExceptionMessage, objException.getStackTraceString());
		}
	}

	public void finish(Database.BatchableContext objBC) {
	}
}