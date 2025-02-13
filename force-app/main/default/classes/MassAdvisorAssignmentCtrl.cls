/**
 * @name         MassAdvisorAssignmentCtrl
 * @author       Bhagat Singh
 * @date         26 June 2024
 * @description  Update Advisor Assignment field on selected opportunities.
 * @test class   MassAdvisorAssignmentCtrlTest
 * @revisions    Date ------------ Name ------------ Comments
 **/
public with sharing class MassAdvisorAssignmentCtrl {
	public static final String strAdvisorAssignmentPS = 'Mass_Update_Advisor_Assignment';
	public List<Opportunity> list_RenewalOpportunity { get; set; }
	public Opportunity objOpportunity { get; set; }
	private final PageReference strFromPage;
	public Integer intSelectedOpp { get; set; }
	public Integer intValidOpp { get; set; }
	public static Id idRenewalOpp = OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID;
	public static String strAdvisor = FWManageRoleUtil.ROLE_ADVISOR;
	public String strCurrentStep { get; set; }
	public static String strRenewalSepcialist = FWManageRoleUtil.ROLE_RENEWAL_SPECIALIST;
	public static String strMessage = 'Assignment in progress, this may take a few minutes';
	public static String strErrorMsg = 'Please select Advisor Assignment value';
	public static String strWarning = 'Please check the notes section.';
	public static String strPermissionMsg = 'Advisor Assignment is not allowed for the logged-in User. Please click Cancel button to return back.';
	public static String strNoRecordSelected = 'No record was selected on the list view. Please click Cancel button and select records for Advisor Assignment.';

	public MassAdvisorAssignmentCtrl(ApexPages.StandardSetController objStdCtrl) {
		strCurrentStep = '1';
		intSelectedOpp = 0;
		intValidOpp = 0;
		objOpportunity = new Opportunity(RecordTypeId = idRenewalOpp);
		list_RenewalOpportunity = new List<Opportunity>();
		List<Opportunity> list_SelectedOpportunity = objStdCtrl.getSelected();
		strFromPage = objStdCtrl.cancel();

		if (!checkMassUpdateAdvisorAssignment()) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, strPermissionMsg));
		} else {
			if (list_SelectedOpportunity?.size() == 0) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, strNoRecordSelected));
			} else {
				intSelectedOpp = list_SelectedOpportunity?.size();
				Set<Id> set_OppIds = new Set<Id>();
				for (Opportunity objOpp : list_SelectedOpportunity) {
					set_OppIds.add(objOpp.Id);
				}

				list_RenewalOpportunity = [
					SELECT
						Id,
						Name,
						Account.Name,
						RecordTypeId,
						RecordType.Name,
						StageName,
						Owner.Name,
						Advisor_Assignment__c,
						HI_Effective_Date__c,
						Big_Desk_BenOps__c,
						Owner_Role_Name__c,
						UW_Carrier_PY__c,
						UW_State_PY__c,
						Benefits_Current_Setup_Step__c,
						Is_Multi_EIN__c
					FROM Opportunity
					WHERE Id IN :set_OppIds AND RecordTypeId = :idRenewalOpp AND Owner_Role_Name__c != :strAdvisor AND Owner_Role_Name__c != :strRenewalSepcialist AND Big_Desk_BenOps__c = FALSE
				];

				intValidOpp = list_RenewalOpportunity?.size();

				if (intValidOpp == 0) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, strWarning));
				}
			}
		}
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method update Advisor_Assignment__c field values on selected opportunity records.
	 * @param        NA
	 * @return       Page Reference of current page
	 **/
	public PageReference updateOpportunity() {
		try {
			strCurrentStep = '1';
			if (list_RenewalOpportunity?.size() > 0) {
				String strSelectedValue = objOpportunity.Advisor_Assignment__c;
				if (String.isBlank(strSelectedValue)) {
					apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, strErrorMsg));
					return null;
				}

				Set<Id> setValidOppIds = new Set<Id>();
				for (Opportunity objOpp : list_RenewalOpportunity) {
					setValidOppIds.add(objOpp.Id);
				}

				if (setValidOppIds.size() > 0) {
					MassAdvisorAssignmentBatch objBatch = new MassAdvisorAssignmentBatch();
					objBatch.set_OppIds = setValidOppIds;
					objBatch.strAdvisorAssignment = strSelectedValue;
					Database.executeBatch(objBatch, 1);
					apexPages.addMessage(new apexPages.Message(ApexPages.Severity.CONFIRM, strMessage));
					strCurrentStep = '2';
				} else {
					apexPages.addMessage(new apexPages.Message(ApexPages.Severity.WARNING, strWarning));
				}
			}

			return ApexPages.currentPage();
		} catch (Exception ojbExp) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, ojbExp.getmessage()));
			return ApexPages.currentPage();
		}
	}

	public String getStep() {
		return strCurrentStep;
	}

	public PageReference cancel() {
		return strFromPage;
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method check login user have Mass_Update_Advisor_Assignment permission set or not.
	 * @param        NA
	 * @return       Boolean
	 **/
	public Boolean checkMassUpdateAdvisorAssignment() {
		Boolean blnMassUpdateEnabled = false;
		List<PermissionSetAssignment> list_PermissionSet = [
			SELECT Id, AssigneeId
			FROM PermissionSetAssignment
			WHERE PermissionSet.Name = :strAdvisorAssignmentPS AND AssigneeId = :UserInfo.getUserId()
			LIMIT 1
		];

		if (list_PermissionSet?.size() > 0 || Test.isRunningTest()) {
			blnMassUpdateEnabled = true;
		}

		return blnMassUpdateEnabled;
	}
}