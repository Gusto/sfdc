/**
 * @name         TaxResChecklistController
 * @author       Pravesh Rana
 * @date         06/04/2021
 * @description  Support class for "TaxResCaseActions" & "TaxResChecklistCmp" lwc component
 * @test class   TaxResChecklistControllerTest
 * @revisions    Date ------------ Name ------------ Comments
 **/
public with sharing class TaxResChecklistController {
	static Id LOGGED_IN_USERID = UserInfo.getUserId();
	static String TAX_RES_LSI = 'TaxRes_LSI';
	static String TAX_RES = 'Tax Res';
	static String PE_CAPTAIN = 'PE/Captain';
	static String STATUS_OPEN = CaseUtils.STATUS_OPEN;
	static String STATUS_DONE = 'Done';
	static String STATUS_REJECT = 'Reject';
	public static String ACTIVE = 'Active';
	public static String SEND_NOTICE_PAGES = 'Send notice pages';
	static String SUCCESS = 'success';
	static String CASE_STATUS_OPEN = CaseUtils.STATUS_OPEN;

	public TaxResChecklistController() {
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : return "User_Role" record related to "Logged in User"
	 * @Parm        : N/A
	 * @Return      : User_Role object instance
	 **/
	@AuraEnabled
	public static User_Role__c getLoggedInUserRoleDetails() {
		try {
			List<User_Role__c> list_ObjUserRoles = [
				SELECT
					Id,
					User_Skill_Team__c,
					POD_Captain__c,
					(
						SELECT Id
						FROM User_Role__r
						WHERE User_Skill_Role_Name__c = :CaseUtils.TAXRES_ACCOUNT_SPECIALIST
						LIMIT 1
					)
				FROM User_Role__c
				WHERE User__c = :LOGGED_IN_USERID
			];

			if (list_ObjUserRoles.size() > 0) {
				return list_ObjUserRoles[0];
			}
		} catch (Exception objException) {
			User_Role__c objUserRole = new User_Role__c();
			objUserRole.BT_Notes__c = objException.getMessage();
			return objUserRole;
		}

		return null;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : query "email template" record based on parameter
	 * @Parm        : String [unique email template DeveloperName]
	 * @Return      : EmailTemplate
	 **/
	@AuraEnabled
	public static List<EmailTemplate> getEmailTemplateBody(String strEmailUniqueName) {
		try {
			if (String.isNotBlank(strEmailUniqueName)) {
				List<String> list_templateName = strEmailUniqueName.split(',');
				List<EmailTemplate> list_objEmailTemplates = [
					SELECT Id, HtmlValue, Name
					FROM EmailTemplate
					WHERE DeveloperName IN :list_templateName
				];
				if (list_objEmailTemplates.size() > 0) {
					return list_objEmailTemplates;
				}
			}
		} catch (Exception objException) {
			throw new AuraHandledException(objException.getMessage());
		}
		return new List<EmailTemplate>();
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Tranfer Case to LSI
	 * @Parm        : String [case id]
	 * @Return      : String [result/error/exception information]
	 **/
	@AuraEnabled
	public static String TransferToLSI(String strObjCaseId) {
		String strReturnMessage = null;
		try {
			if (String.isNotBlank(strObjCaseId)) {
				Case objCase = new Case(Id = strObjCaseId);
				List<Group> list_Group = GlobalQueryHelper.getGroupsByName(TAX_RES_LSI);
				if (list_Group.size() > 0) {
					objCase.OwnerId = list_Group[0].Id;
				}
				objCase.Status = CASE_STATUS_OPEN;
				objCase.Account_Specialist__c = null;
				CaseTriggerHelper.skipTrigger = true;
				update objCase;
				strReturnMessage = SUCCESS;
			}
		} catch (Exception objException) {
			strReturnMessage = objException.getMessage();
		}
		return strReturnMessage;
	}

	/**
	 * @Author      : Shyam Nasare
	 * @Description : Update Case Automation Triggered
	 * @Parm        : String Action, String CaseId
	 * @Return      : String [result/error/exception information]
	 **/
	@AuraEnabled
	public static String updateCaseForPILateDepositAutosolve(String strAction, String strObjCaseId) {
		String strReturnMessage = null;
		try {
			//CaseTriggerHelper.skipTrigger = true;
			List<Case> list_ObjCaseRecord = TaxResNoticeIndexDetailsController.getCasesWithTNDC(new List<Id>{ strObjCaseId });
			Case objCaseToUpdate = new Case(Id = strObjCaseId);
			if (strAction == 'confirmAutosolve') {
				objCaseToUpdate.p_i__c = CaseUtils.STATUS_PI_AUTOSOLVE_STATUS_APPROVED;
				TaxResAutoSolveUtil.handleFieldSync(list_ObjCaseRecord[0], objCaseToUpdate, TaxResNoticeIndexDetailsController.populateAutoSolvePackageDetails(list_ObjCaseRecord[0], TaxResAutoSolveUtil.PI_LATE_DEPOSIT_AUTOSOLVE_PACKAGE));
			} else if (strAction == 'declineAutosolve') {
				List<String> list_MassEmailStepValues = (list_ObjCaseRecord[0].Mass_Email_Step__c).split(';');
				if(list_MassEmailStepValues != null && list_MassEmailStepValues.contains(TaxResNoticeIndexDetailsController.PI_LATE_DEPOSIT_PARTIAL_AUTOSOLVE_FIRED)) {
					list_MassEmailStepValues.remove(list_MassEmailStepValues.indexOf(TaxResNoticeIndexDetailsController.PI_LATE_DEPOSIT_PARTIAL_AUTOSOLVE_FIRED));
					objCaseToUpdate.Mass_Email_Step__c = String.join(list_MassEmailStepValues, ';');
				}
				objCaseToUpdate.p_i__c = CaseUtils.STATUS_PI_AUTOSOLVE_STATUS_DENIED;
			}
			update objCaseToUpdate;
			strReturnMessage = SUCCESS;
		} catch (Exception objException) {
			System.debug(objException);
			strReturnMessage = objException.getMessage();
		}
		return strReturnMessage;
	}
}