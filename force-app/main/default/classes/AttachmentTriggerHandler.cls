public class AttachmentTriggerHandler extends TriggerHandler {
	private List<Attachment> list_NewRecords;
	private List<Attachment> list_OldRecords;
	private Map<Id, Attachment> map_NewRecords;
	private Map<Id, Attachment> map_OldRecords;

	public AttachmentTriggerHandler() {
		super('AttachmentTriggerHandler');
		this.list_NewRecords = (List<Attachment>) Trigger.new;
		this.list_OldRecords = (List<Attachment>) Trigger.old;
		this.map_NewRecords = (Map<Id, Attachment>) Trigger.newMap;
		this.map_OldRecords = (Map<Id, Attachment>) Trigger.oldMap;
	}

	public override void beforeInsert() {
		renameAttachmentExeToTxt(list_NewRecords);
	}

	public override void afterInsert() {
		createNewAttachment(list_NewRecords);
	}

	public override void beforeUpdate() {
		renameAttachmentExeToTxt(list_NewRecords);
	}

	private void renameAttachmentExeToTxt(List<Attachment> list_NewRecords) {
		for (Attachment objAttachment : list_NewRecords) {
			String strParentId = objAttachment.ParentId;
			if (objAttachment != null && objAttachment.Name != null) {
				objAttachment.Name = objAttachment.Name.replace('.exe', '.txt');
			}
		}
	}

	private void createNewAttachment(List<Attachment> list_Attachments) {
		Set<Id> set_EmailMessageIDs = new Set<Id>();
		Map<String, Id> map_OldIdEmailMsgWithNewId = new Map<String, Id>();
		Map<Id, Id> map_stdEmailMsgToCustomEmailMsg = new Map<Id, Id>();
		List<Attachment> list_InsertAttachments = new List<Attachment>();

		for (Attachment objAttachment : list_Attachments) {
			String strParentId = objAttachment.ParentId;
			if (strParentId != null && strParentId.indexOf('02s') == 0) {
				set_EmailMessageIDs.add(objAttachment.ParentId);
			}
		}

		if (set_EmailMessageIDs.size() > 0) {
			for (EmailMessage objEmail : [SELECT Id, ParentId, Old_Parent_Email_Id__c FROM EmailMessage WHERE Old_Parent_Email_Id__c IN :set_EmailMessageIDs]) {
				map_OldIdEmailMsgWithNewId.put(objEmail.Old_Parent_Email_Id__c, objEmail.Id);
			}
		}

		if (!map_OldIdEmailMsgWithNewId.isEmpty()) {
			for (Attachment att : list_Attachments) {
				if (map_OldIdEmailMsgWithNewId.containsKey(att.ParentId)) {
					Attachment newAtt = att.clone();
					newAtt.parentid = map_OldIdEmailMsgWithNewId.get(att.ParentId);
					list_InsertAttachments.add(newAtt);
				}
			}
		}

		// Code below is to handle universal inbox email attachments
		if (!set_EmailMessageIDs.isEmpty()) {
			for (Email_Message__c objCustomEmail : [SELECT Id, EmailID__c FROM Email_Message__c WHERE EmailID__c IN :set_EmailMessageIDs]) {
				map_stdEmailMsgToCustomEmailMsg.put(objCustomEmail.EmailID__c, objCustomEmail.Id);
			}

			if (map_stdEmailMsgToCustomEmailMsg.size() > 0) {
				for (Attachment objAttachment : list_Attachments) {
					if (map_stdEmailMsgToCustomEmailMsg.containsKey(objAttachment.ParentId)) {
						Attachment objClonedAttachment = objAttachment.clone();
						objClonedAttachment.ParentId = map_stdEmailMsgToCustomEmailMsg.get(objAttachment.ParentId);
						list_InsertAttachments.add(objClonedAttachment);
					}
				}
			}
		}

		if (!list_InsertAttachments.isEmpty()) {
			TriggerHandler.bypass('AttachmentTriggerHandler');
			Map<String, String> map_AttachmentInsertDMLErrors = new Map<String, String>();
			List<Database.SaveResult> saveResult = Database.insert(list_InsertAttachments, false);
			map_AttachmentInsertDMLErrors = Utils.processSaveResult(saveResult, list_InsertAttachments, 'Id', true, 'AttachmentTriggerHandler-createNewAttachment::AttachmentInsert');
		}
	}
}