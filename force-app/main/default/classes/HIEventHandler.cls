@RestResource(urlMapping='/HiEvent/*')
global with sharing class HIEventHandler {
	@HttpPost
	global static String createNewCase(String event_id, String event_type, String event_info, String ticket_owner, String company_id, String employee_id) {
		String eventInfo = event_info;
		List<Attachment> attachmentList = new List<Attachment>();
		if (event_type == 'enrollment_ready_for_processing' || event_type == 'voluntary_lidi_ready_for_processing') {
			HIFulfillmentEnrollmentEventJSON parsedData = (HIFulfillmentEnrollmentEventJSON) JSON.deserialize(event_info, HIFulfillmentEnrollmentEventJSON.class);
			if (parsedData.forms != null) {
				for (HIFulfillmentEnrollmentEventJSON.Form frm : parsedData.forms) {
					if (frm.encoded_form_data != null && frm.encoded_form_data != '') {
						Attachment attach = new Attachment();
						attach.Body = EncodingUtil.base64Decode(frm.encoded_form_data);
						attach.Name = '' + frm.id + '.pdf';
						attachmentList.add(attach);
						frm.encoded_form_data = '';
					}
				}
				eventInfo = JSON.serialize(parsedData);
			}
		}
		if (event_type == 'employee_losing_eligibility' || event_type == 'employee_losing_commuter_eligibility') {
			HIFulfillmentTerminationEvenJSON parsedData = (HIFulfillmentTerminationEvenJSON) JSON.deserialize(event_info, HIFulfillmentTerminationEvenJSON.class);
			if (parsedData.forms != null) {
				for (HIFulfillmentTerminationEvenJSON.cls_forms frm : parsedData.forms) {
					if (frm.encoded_form_data != null && frm.encoded_form_data != '') {
						Attachment attach = new Attachment();
						attach.Body = EncodingUtil.base64Decode(frm.encoded_form_data);
						attach.Name = '' + frm.id + '.pdf';
						attachmentList.add(attach);
						frm.encoded_form_data = '';
					}
				}
				eventInfo = JSON.serialize(parsedData);
			}
		}
		if (event_type == 'audit' || event_type == 'employee_ambiguous_status_periods_event') {
			HIFulfillmentEventAuditJSON parsedData = (HIFulfillmentEventAuditJSON) JSON.deserialize(event_info, HIFulfillmentEventAuditJSON.class);
			if (parsedData.forms != null) {
				for (HIFulfillmentEventAuditJSON.forms frm : parsedData.forms) {
					if (frm.encoded_form_data != null && frm.encoded_form_data != '') {
						Attachment attach = new Attachment();
						attach.Body = EncodingUtil.base64Decode(frm.encoded_form_data);
						attach.Name = '' + frm.id + '.pdf';
						attachmentList.add(attach);
						frm.encoded_form_data = '';
					}
				}
				eventInfo = JSON.serialize(parsedData);
			}
		}

		//HI Fulfillment Events Processing State, Message//
		HI_Fulfillment_Event__c objHIFulfill = new HI_Fulfillment_Event__c(
			Id__c = event_id,
			Event_Type__c = event_type,
			Event_Info__c = eventInfo,
			Company_id__c = company_id,
			Ops_Owner__c = ticket_owner,
			Employee_id__c = employee_id
		);

		Savepoint objSP = Database.setSavepoint();
		try {
			insert objHIFulfill;
		} catch (Exception ex) {
			Database.rollback(objSP);
			ExceptionLogUtil.logException('HIEventHandler', 'createNewCase', ex.getMessage(), ex.getStackTraceString() + '. line number: ' + ex.getLineNumber());
		}

		for (Attachment a : attachmentList) {
			a.ParentId = objHIFulfill.id;
		}

		return null;
	}
}