/**
 * @name         CarrierVersionDetailTriggerHelper
 * @author       Deepika Saini
 * @date         14 July 2022
 * @description  This class is used to hanlde event for CarrierVersionDetailTrigge
 * @test class   CarrierVersionDetailTriggerHelperTest
 * @revisions    Date ------------ Name ------------ Comments
 */
public class CarrierVersionDetailTriggerHelper {
	public static Boolean blnSkipTrigger = false;
	Set<String> set_COExcludedStages = new Set<String>{ CarrierOrderUtil.CO_STATUS_APPROVED, CarrierOrderUtil.STAGE_CANCELLED, CarrierOrderUtil.STAGE_CLOSED_ADMIN };

	public void OnBeforeInsert(List<Carrier_Version_Detail__c> list_NewCarrierVersionDetails) {
	}
	public void OnAfterInsert(List<Carrier_Version_Detail__c> list_NewCarrierVersionDetails) {
	}
	public void OnBeforeUpdate(Map<Id, Carrier_Version_Detail__c> map_OldCarrierVersionDetails, Map<Id, Carrier_Version_Detail__c> map_NewCarrierVersionDetail) {
	}
	public void OnAfterUpdate(Map<Id, Carrier_Version_Detail__c> map_OldCarrierVersionDetails, Map<Id, Carrier_Version_Detail__c> map_NewCarrierVersionDetail) {
		updateCODates(map_OldCarrierVersionDetails, map_NewCarrierVersionDetail.values());
	}

	/**
	 * @author      Deepika Saini
	 * @description Update Group, Member and NP Submission Deadline Date feilds on Carrier Order.
	 * @param       Map of Carrier Version detail with old values and List of Carrier Version Detail with new values
	 * @return      NA
	 **/
	public void updateCODates(Map<Id, Carrier_Version_Detail__c> map_OldCarrierVersionDetails, List<Carrier_Version_Detail__c> list_NewCarrierVersionDetails) {
		Set<Id> set_CarrierIds = new Set<Id>();

		for (Carrier_Version_Detail__c objCarrierVersion : list_NewCarrierVersionDetails) {
			if (
				map_OldCarrierVersionDetails == null ||
				(!map_OldCarrierVersionDetails.isEmpty() &&
				(objCarrierVersion.Member_Submission_Event__c != map_OldCarrierVersionDetails.get(objCarrierVersion.Id).Member_Submission_Event__c ||
				objCarrierVersion.Member_Submission_Variation1__c != map_OldCarrierVersionDetails.get(objCarrierVersion.Id).Member_Submission_Variation1__c ||
				objCarrierVersion.Member_Submission_Variation2__c != map_OldCarrierVersionDetails.get(objCarrierVersion.Id).Member_Submission_Variation2__c ||
				objCarrierVersion.Group_Submission_Event__c != map_OldCarrierVersionDetails.get(objCarrierVersion.Id).Group_Submission_Event__c ||
				objCarrierVersion.Group_Variation_Number1__c != map_OldCarrierVersionDetails.get(objCarrierVersion.Id).Group_Variation_Number1__c ||
				objCarrierVersion.Group_Variation_Number2__c != map_OldCarrierVersionDetails.get(objCarrierVersion.Id).Group_Variation_Number2__c ||
				objCarrierVersion.New_Plan_Submission_Event__c != map_OldCarrierVersionDetails.get(objCarrierVersion.Id).New_Plan_Submission_Event__c ||
				objCarrierVersion.New_Plan_Variation_Num1__c != map_OldCarrierVersionDetails.get(objCarrierVersion.Id).New_Plan_Variation_Num1__c ||
				objCarrierVersion.New_Plan_Variation_Num2__c != map_OldCarrierVersionDetails.get(objCarrierVersion.Id).New_Plan_Variation_Num2__c ||
				objCarrierVersion.With_Changes_Sub_Start_Variation_No__c != map_OldCarrierVersionDetails.get(objCarrierVersion.Id).With_Changes_Sub_Start_Variation_No__c ||
				objCarrierVersion.Without_Changes_Sub_Start_Variation_No__c != map_OldCarrierVersionDetails.get(objCarrierVersion.Id).Without_Changes_Sub_Start_Variation_No__c ||
				objCarrierVersion.With_Changes_Submission_Start_Event__c != map_OldCarrierVersionDetails.get(objCarrierVersion.Id).With_Changes_Submission_Start_Event__c ||
				objCarrierVersion.Without_Changes_Submission_Start_Event__c != map_OldCarrierVersionDetails.get(objCarrierVersion.Id).Without_Changes_Submission_Start_Event__c ||
				objCarrierVersion.Term_Submission_Event__c != map_OldCarrierVersionDetails.get(objCarrierVersion.Id).Term_Submission_Event__c ||
				objCarrierVersion.Term_Variation_Number__c != map_OldCarrierVersionDetails.get(objCarrierVersion.Id).Term_Variation_Number__c))
			) {
				set_CarrierIds.add(objCarrierVersion.Carrier_Id__c);
			}
		}

		if (!set_CarrierIds.isEmpty()) {
			List<Carrier_Order__c> list_CarrierOrders = getCarrierOrders(set_CarrierIds, set_COExcludedStages);
			if (!list_CarrierOrders.isEmpty()) {
				CarrierOrderTriggerHelper objCarrierOrderHelper = new CarrierOrderTriggerHelper();
				objCarrierOrderHelper.cacheData(list_CarrierOrders);
				Boolean blncheck = CarrierOrderTriggerHelper.blnUpdateSubmissionDeadlineDates;
				CarrierOrderTriggerHelper.blnUpdateSubmissionDeadlineDates = true;
				objCarrierOrderHelper.populateSubmissionDate(list_CarrierOrders, null);
				CarrierOrderTriggerHelper.blnUpdateSubmissionDeadlineDates = blncheck;
				update list_CarrierOrders;
			}
		}
	}

	public List<Carrier_Order__c> getCarrierOrders(Set<Id> set_COIds, Set<String> set_COExcludeStages) {
		return [
			SELECT
				Id,
				Order_Type__c,
				Group_Submission_Date__c,
				Member_Submission_Date__c,
				Submission_Deadline__c,
				Carrier__c,
				Benefit_Order__c,
				Submission_Deadline_Date__c,
				RecordTypeId,
				Renewal_Date__c,
				Special_Enrollment__c
			FROM Carrier_Order__c
			WHERE Carrier__c IN :set_COIds AND Implementation_Stage__c NOT IN :set_COExcludeStages AND Benefit_Order__r.Special_Enrollment__c = false
		];
	}
}