trigger AttachmentTrigger on Attachment (after insert, after update, before insert, before update) {

    // David Schach: Not allowing permissions bypass because part of this is a security-related update
	/* if (FeatureManagement.checkPermission('Bypass_Triggers')) {
		return;
	} */
	new AttachmentTriggerHandler().run();

}