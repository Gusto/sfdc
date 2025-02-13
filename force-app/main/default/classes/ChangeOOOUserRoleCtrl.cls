/**
 * @name         : ChangeOOOUserRoleCtrl
 * @author       : Rushi R
 * @date         : 12-27-2022
 * @description  : Extension/controller for the ChangeOOOUserRolePage
 * @test classes : ChangeOOOUserRoleCtrlTest
 **/
public class ChangeOOOUserRoleCtrl {
	public Id id_RecordId { get; private set; }
	public Id id_UserId { get; set; }
	public Boolean blnHasError { get; set; }

	public ChangeOOOUserRoleCtrl(ApexPages.StandardController controller) {
		blnHasError = false;
		id_RecordId = (Id) controller.getId();
		id_UserId = [SELECT Id, User__c FROM User_Role__c WHERE Id = :id_RecordId].User__c;
	}

	public pageReference changeOOOForUser() {
		User obj_User = [SELECT Id, Out_Of_Office__c FROM User WHERE Id = :id_UserId];
		Boolean blnOOOValue = obj_User.Out_Of_Office__c;

		obj_User.Out_Of_Office__c = blnOOOValue ? false : true;
		try {
			UserTriggerHelper.skipTrigger = true;
			Database.update(obj_User);
			UserTriggerHelper.skipTrigger = false;
		} catch (Exception ex) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, 'Unable to change the Out of Office, please try again!'));
			blnHasError = true;
		}

		return blnHasError ? null : new PageReference('/' + id_RecordId);
	}

	public pageReference backToRecord() {
		return new PageReference('/' + id_RecordId);
	}
}