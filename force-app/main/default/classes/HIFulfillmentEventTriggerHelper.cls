public class HIFulfillmentEventTriggerHelper extends TriggerHandler {
	public static boolean skipTrigger = false;
	public static boolean queue = false;

	public HIFulfillmentEventTriggerHelper() {
		super('HIFulfillmentEventTriggerHelper');
	}

	public override void beforeInsert() {
		List<HI_Fulfillment_Event__c> events = (List<HI_Fulfillment_Event__c>) Trigger.new;
		Blob encryptionKey = EncryptionUtils.getEncryptionKey('Master');
		for (HI_Fulfillment_Event__c event : events) {
			if (event.Event_Info__c == null || event.Event_Info__c == '')
				continue;

			Blob encryptedInfo = EncryptionUtils.getEncryptedBlob(encryptionKey, event.Event_Info__c);
			String b64Data = EncodingUtil.base64Encode(encryptedInfo);
			event.Event_Info_Encrypted__c = b64Data;
			event.Event_Info__c = '';
		}
		setIntegrationLogic(events);
		if (skipTrigger == true)
			return;

		if (queue == true) {
			List<HI_Fulfillment_Event__c> list_ContinuationElectionEvent = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> terminationEventList = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> enrollmentEventList = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> employeeUpdateEventList = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> auditEventList = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> hsaEnrollmentEventList = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> dependentAgingOutList = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> borNewHireList = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> eoiSubmissionList = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> basicpacificList = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> eoiFollowupList = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> errorEditingSeletionList = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> openEnrollmentEventList = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> listTadaAudit = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> list_ContTermination = new List<HI_Fulfillment_Event__c>(); //Chaitanya 09-28-2020
			List<HI_Fulfillment_Event__c> list_SelectionSubmitted = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> list_SelectionCancelled = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> list_tadaEnrollmentReadyForProcessing = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> list_tadaSelectionCancelled = new List<HI_Fulfillment_Event__c>();
			for (HI_Fulfillment_Event__c event : events) {
				if (event.Event_Type__c == HIEnrollmentEventUtility.ETYPE_TADA_ENR_READY_FOR_PROCESSING) {
					list_tadaEnrollmentReadyForProcessing.add(event);
				} else if (event.Event_Type__c == HIEnrollmentEventUtility.ETYPE_SELECTION_SUBMITTED || event.Event_Type__c == HIEnrollmentEventUtility.ETYPE_OPSOWNER_UPDATED) {
					list_SelectionSubmitted.add(event);
				} else if (event.Event_Type__c == HIEnrollmentEventUtility.ETYPE_SELECTION_CANCELLED) {
					list_SelectionCancelled.add(event);
				} else if (event.Event_Type__c == HIEnrollmentEventUtility.ETYPE_TADA_SELECTION_CANCELLED) {
					list_tadaSelectionCancelled.add(event);
				} else if (event.Event_Type__c == 'enrollment_ready_for_processing' && (Label.HIFulfillmentTriggerSetting.indexOf('enrollment_ready_for_processing,') > -1 || test.isRunningTest())) {
					enrollmentEventList.add(event);
				} else if (
					event.Event_Type__c == 'voluntary_lidi_ready_for_processing' && (Label.HIFulfillmentTriggerSetting.indexOf('voluntary_lidi_ready_for_processing,') > -1 || test.isRunningTest())
				) {
					enrollmentEventList.add(event);
				} else if (
					event.Event_Type__c.indexOf('employee_losing_eligibility') > -1 && (Label.HIFulfillmentTriggerSetting.indexOf('employee_losing_eligibility,') > -1 || test.isRunningTest())
				) {
					terminationEventList.add(event);
				} else if (
					event.Event_Type__c == 'employee_losing_commuter_eligibility' && (Label.HIFulfillmentTriggerSetting.indexOf('employee_losing_commuter_eligibility,') > -1 || test.isRunningTest())
				) {
					terminationEventList.add(event);
				} else if (
					(event.Event_Type__c == 'employee_update' || event.Event_Type__c == 'company_update') &&
					(Label.HIFulfillmentTriggerSetting.indexOf('employee_update,') > -1 ||
					Label.HIFulfillmentTriggerSetting.indexOf('company_update,') > -1 ||
					test.isRunningTest())
				) {
					employeeUpdateEventList.add(event);
				} else if (event.Event_Type__c == 'audit' && (Label.HIFulfillmentTriggerSetting.indexOf('audit,') > -1 || test.isRunningTest())) {
					auditEventList.add(event);
				} else if (
					event.Event_Type__c == 'employee_ambiguous_status_periods_event' &&
					(Label.HIFulfillmentTriggerSetting.indexOf('employee_ambiguous_status_periods_event,') > -1 || test.isRunningTest())
				) {
					auditEventList.add(event);
				} else if ((event.Event_Type__c == HIEnrollmentEventUtility.ETYPE_EMP_HSA_ENROLLMENT_AUTO_PROCESS || event.Event_Type__c == HIEnrollmentEventUtility.ETYPE_EMP_HSA_ENROLLMENT) && (Label.HIFulfillmentTriggerSetting.indexOf('employee_hsa_enrollment,') > -1 || test.isRunningTest())) {
					hsaEnrollmentEventList.add(event);
				} else if (event.Event_Type__c == 'dependent_aging_out' && (Label.HIFulfillmentTriggerSetting.indexOf('dependent_aging_out,') > -1 || test.isRunningTest())) {
					dependentAgingOutList.add(event);
				} else if (event.Event_Type__c == 'new_hire_before_bor_implemented' && (Label.HIFulfillmentTriggerSetting.indexOf('new_hire_before_bor_implemented,') > -1 || test.isRunningTest())) {
					borNewHireList.add(event);
				} else if (event.Event_Type__c == 'eoi_submission' && (Label.HIFulfillmentTriggerSetting.indexOf('eoi_submission,') > -1 || test.isRunningTest())) {
					eoiSubmissionList.add(event);
				} else if (event.Event_Type__c == 'add_to_basic_pacific' && (Label.HIFulfillmentTriggerSetting.indexOf('add_to_basic_pacific,') > -1 || test.isRunningTest())) {
					basicpacificList.add(event);
				} else if (event.Event_Type__c == 'eoi_followup' && (Label.HIFulfillmentTriggerSetting.indexOf('eoi_followup,') > -1 || test.isRunningTest())) {
					eoiFollowupList.add(event);
				} else if (event.Event_Type__c == 'error_editing_selection' && (Label.HIFulfillmentTriggerSetting.indexOf('error_editing_selection,') > -1 || test.isRunningTest())) {
					errorEditingSeletionList.add(event);
				} else if (event.Event_Type__c == 'cobra_open_enrollment' || event.Event_Type__c == 'invalid_kafka_message') {
					event.Processing_State__c = 'Dead';
				} else if (event.Event_Type__c == 'open_enrollment_status') {
					openEnrollmentEventList.add(event);
				} else if (event.Event_Type__c == 'tada_audit') {
					listTadaAudit.add(event);
				} else if (event.Event_Type__c == 'employee_continuation_termination') {
					list_ContTermination.add(event);
				} else if (event.Event_Type__c == HIEnrollmentEventUtility.HI_EVENT_CONTINUATION_ELECTION) {
					list_ContinuationElectionEvent.add(event);
				}
			}
			if (list_tadaEnrollmentReadyForProcessing.size() > 0) {
				HITaDaEnrollmentEvent.processInformation(list_tadaEnrollmentReadyForProcessing);
			}
			if (list_tadaSelectionCancelled.size() > 0) {
				HITaDaSelectionCancelledEvent.processInformation(list_tadaSelectionCancelled);
			}
			if (list_SelectionSubmitted.size() > 0) {
				HISelectionSubmittedEvent.processInformation(list_SelectionSubmitted);
			}
			if (list_SelectionCancelled.size() > 0) {
				HISelectionCancelledEvent.processInformation(list_SelectionCancelled);
			}
			if (terminationEventList.size() > 0) {
				HIFulfillmentEventTermination hifulfillmentEvent = new HIFulfillmentEventTermination();
				hifulfillmentEvent.processInformation(terminationEventList);
			}
			if (enrollmentEventList.size() > 0) {
				HIFulfillmentEventEnrollment hifulfillmentEvent = new HIFulfillmentEventEnrollment();
				hifulfillmentEvent.processInformation(enrollmentEventList);
			}
			if (employeeUpdateEventList.size() > 0) {
				HIFulfillmentEventEmployeeUpdate hifulfillmentEmployeeUpdateEvent = new HIFulfillmentEventEmployeeUpdate();
				hifulfillmentEmployeeUpdateEvent.processInformation(employeeUpdateEventList);
			}
			if (auditEventList.size() > 0) {
				HIFulfillmentEventAudit HIFulfillmentAuditEvent = new HIFulfillmentEventAudit();
				HIFulfillmentAuditEvent.processInformation(auditEventList);
			}
			if (hsaEnrollmentEventList.size() > 0) {
				HIFulfillmentEventHsaEnrolment hsaEnrolllment = new HIFulfillmentEventHsaEnrolment();
				hsaEnrolllment.processInformation(hsaEnrollmentEventList);
			}
			if (dependentAgingOutList.size() > 0) {
				HIFulfillmentDependentAgingOut dependentAgingOut = new HIFulfillmentDependentAgingOut();
				dependentAgingOut.processInformation(dependentAgingOutList);
			}
			if (borNewHireList.size() > 0) {
				HIFulfillmentBORNewHire borNewHire = new HIFulfillmentBORNewHire();
				borNewHire.processInformation(borNewHireList);
			}
			if (eoiSubmissionList.size() > 0) {
				HIFulfillmentEOISubmission eoiSubmission = new HIFulfillmentEOISubmission();
				eoiSubmission.processInformation(eoiSubmissionList);
			}
			if (basicpacificList.size() > 0) {
				HIFulfillmentAddToBasicPacific addToBasic = new HIFulfillmentAddToBasicPacific();
				addToBasic.processInformation(basicpacificList);
			}
			if (eoiFollowupList.size() > 0) {
				HIFulfillmentEoiFollowup eoiFollowup = new HIFulfillmentEoiFollowup();
				eoiFollowup.processInformation(eoiFollowupList);
			}
			if (errorEditingSeletionList.size() > 0) {
				HIFulfillmentErrorEditingSelection errorEditingSelection = new HIFulfillmentErrorEditingSelection();
				errorEditingSelection.processInformation(errorEditingSeletionList);
			}
			if (openEnrollmentEventList.size() > 0) {
				HIFulfillmentEventOpenEnrollment openEnrollmentEvent = new HIFulfillmentEventOpenEnrollment();
				openEnrollmentEvent.processInformation(openEnrollmentEventList);
			}
			if (listTadaAudit.size() > 0) {
				HIFulfillmentEventTadaAudit tadaAuditEvent = new HIFulfillmentEventTadaAudit();
				tadaAuditEvent.processInformation(listTadaAudit);
			}
			if (list_ContTermination != null && list_ContTermination.size() > 0) {
				HIFulfillmentEventContTermination contTerminationEvent = new HIFulfillmentEventContTermination();
				contTerminationEvent.processInformation(list_ContTermination);
			}
			if (list_ContinuationElectionEvent.size() > 0) {
				HIContinuationElectionEvent.processInformation(list_ContinuationElectionEvent);
			}
		} else {
			for (HI_Fulfillment_Event__c objHIFulfill : events) {
				objHIFulfill.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public override void afterInsert() {
		List<HI_Fulfillment_Event__c> events = (List<HI_Fulfillment_Event__c>) Trigger.new;
		if (queue == false && !test.isRunningTest()) {
			if (Limits.getQueueableJobs() == 0) {
				try {
					ID jobID = System.enqueueJob(new HIFulfillmentEventQueue(events));
				} catch (Exception ex) {
				}
			}
		}
	}

	public override void beforeUpdate() {
		Blob encryptionKey = EncryptionUtils.getEncryptionKey('Master');
		List<HI_Fulfillment_Event__c> events = (List<HI_Fulfillment_Event__c>) Trigger.new;
		for (HI_Fulfillment_Event__c event : events) {
			if (event.Event_Info__c != null && event.Event_Info__c != '') {
				Blob encryptedInfo = EncryptionUtils.getEncryptedBlob(encryptionKey, event.Event_Info__c);
				String b64Data = EncodingUtil.base64Encode(encryptedInfo);
				event.Event_Info_Encrypted__c = b64Data;
				event.Event_Info__c = '';
			}
		}
		setIntegrationLogic(events);
		if (skipTrigger == true)
			return;

		if (queue == true) {
			List<HI_Fulfillment_Event__c> list_ContinuationElectionEvent = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> terminationEventList = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> enrollmentEventList = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> employeeUpdateEventList = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> auditEventList = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> hsaEnrollmentEventList = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> dependentAgingOutList = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> borNewHireList = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> eoiSubmissionList = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> basicpacificList = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> eoiFollowupList = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> errorEditingSeletionList = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> openEnrollmentEventList = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> listTadaAudit = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> list_ContTermination = new List<HI_Fulfillment_Event__c>(); //Chaitanya 09-28-2020
			List<HI_Fulfillment_Event__c> list_SelectionSubmitted = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> list_SelectionCancelled = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> list_tadaEnrollmentReadyForProcessing = new List<HI_Fulfillment_Event__c>();
			List<HI_Fulfillment_Event__c> list_tadaSelectionCancelled = new List<HI_Fulfillment_Event__c>();
			for (HI_Fulfillment_Event__c event : events) {
				if (event.Event_Type__c == HIEnrollmentEventUtility.ETYPE_TADA_ENR_READY_FOR_PROCESSING) {
					list_tadaEnrollmentReadyForProcessing.add(event);
				} else if (event.Event_Type__c == HIEnrollmentEventUtility.ETYPE_SELECTION_SUBMITTED || event.Event_Type__c == HIEnrollmentEventUtility.ETYPE_OPSOWNER_UPDATED) {
					list_SelectionSubmitted.add(event);
				} else if (event.Event_Type__c == HIEnrollmentEventUtility.ETYPE_SELECTION_CANCELLED) {
					list_SelectionCancelled.add(event);
				} else if (event.Event_Type__c == HIEnrollmentEventUtility.ETYPE_TADA_SELECTION_CANCELLED) {
					list_tadaSelectionCancelled.add(event);
				} else if (event.Event_Type__c == 'enrollment_ready_for_processing' && (Label.HIFulfillmentTriggerSetting.indexOf('enrollment_ready_for_processing,') > -1 || test.isRunningTest())) {
					enrollmentEventList.add(event);
				} else if (
					event.Event_Type__c == 'voluntary_lidi_ready_for_processing' && (Label.HIFulfillmentTriggerSetting.indexOf('voluntary_lidi_ready_for_processing,') > -1 || test.isRunningTest())
				) {
					enrollmentEventList.add(event);
				} else if (
					event.Event_Type__c.indexOf('employee_losing_eligibility') > -1 && (Label.HIFulfillmentTriggerSetting.indexOf('employee_losing_eligibility,') > -1 || test.isRunningTest())
				) {
					terminationEventList.add(event);
				} else if (
					event.Event_Type__c == 'employee_losing_commuter_eligibility' && (Label.HIFulfillmentTriggerSetting.indexOf('employee_losing_commuter_eligibility,') > -1 || test.isRunningTest())
				) {
					terminationEventList.add(event);
				} else if (
					(event.Event_Type__c == 'employee_update' || event.Event_Type__c == 'company_update') &&
					(Label.HIFulfillmentTriggerSetting.indexOf('employee_update,') > -1 ||
					Label.HIFulfillmentTriggerSetting.indexOf('company_update,') > -1 ||
					test.isRunningTest())
				) {
					employeeUpdateEventList.add(event);
				} else if (event.Event_Type__c == 'audit' && (Label.HIFulfillmentTriggerSetting.indexOf('audit,') > -1 || test.isRunningTest())) {
					auditEventList.add(event);
				} else if (
					event.Event_Type__c == 'employee_ambiguous_status_periods_event' &&
					(Label.HIFulfillmentTriggerSetting.indexOf('employee_ambiguous_status_periods_event,') > -1 || test.isRunningTest())
				) {
					auditEventList.add(event);
				} else if ((event.Event_Type__c == HIEnrollmentEventUtility.ETYPE_EMP_HSA_ENROLLMENT_AUTO_PROCESS || event.Event_Type__c == HIEnrollmentEventUtility.ETYPE_EMP_HSA_ENROLLMENT) && (Label.HIFulfillmentTriggerSetting.indexOf('employee_hsa_enrollment,') > -1 || test.isRunningTest())) {
					hsaEnrollmentEventList.add(event);
				} else if (event.Event_Type__c == 'dependent_aging_out' && (Label.HIFulfillmentTriggerSetting.indexOf('dependent_aging_out,') > -1 || test.isRunningTest())) {
					dependentAgingOutList.add(event);
				} else if (event.Event_Type__c == 'new_hire_before_bor_implemented' && (Label.HIFulfillmentTriggerSetting.indexOf('new_hire_before_bor_implemented,') > -1 || test.isRunningTest())) {
					borNewHireList.add(event);
				} else if (event.Event_Type__c == 'eoi_submission' && (Label.HIFulfillmentTriggerSetting.indexOf('eoi_submission,') > -1 || test.isRunningTest())) {
					eoiSubmissionList.add(event);
				} else if (event.Event_Type__c == 'add_to_basic_pacific' && (Label.HIFulfillmentTriggerSetting.indexOf('add_to_basic_pacific,') > -1 || test.isRunningTest())) {
					basicpacificList.add(event);
				} else if (event.Event_Type__c == 'eoi_followup' && (Label.HIFulfillmentTriggerSetting.indexOf('eoi_followup,') > -1 || test.isRunningTest())) {
					eoiFollowupList.add(event);
				} else if (event.Event_Type__c == 'error_editing_selection' && (Label.HIFulfillmentTriggerSetting.indexOf('error_editing_selection,') > -1 || test.isRunningTest())) {
					errorEditingSeletionList.add(event);
				} else if (event.Event_Type__c == 'cobra_open_enrollment' || event.Event_Type__c == 'invalid_kafka_message') {
					event.Processing_State__c = 'Dead';
				} else if (event.Event_Type__c == 'open_enrollment_status') {
					openEnrollmentEventList.add(event);
				} else if (event.Event_Type__c == 'tada_audit') {
					listTadaAudit.add(event);
				} else if (event.Event_Type__c == 'employee_continuation_termination') {
					//Chaitanya 09-28-2020
					list_ContTermination.add(event);
				} else if (event.Event_Type__c == HIEnrollmentEventUtility.HI_EVENT_CONTINUATION_ELECTION) {
					list_ContinuationElectionEvent.add(event);
				}
			}
			if (list_tadaEnrollmentReadyForProcessing.size() > 0) {
				HITaDaEnrollmentEvent.processInformation(list_tadaEnrollmentReadyForProcessing);
			}
			if (list_tadaSelectionCancelled.size() > 0) {
				HITaDaSelectionCancelledEvent.processInformation(list_tadaSelectionCancelled);
			}
			if (list_SelectionSubmitted.size() > 0) {
				HISelectionSubmittedEvent.processInformation(list_SelectionSubmitted);
			}
			if (list_SelectionCancelled.size() > 0) {
				HISelectionCancelledEvent.processInformation(list_SelectionCancelled);
			}
			if (terminationEventList.size() > 0) {
				HIFulfillmentEventTermination hifulfillmentEvent = new HIFulfillmentEventTermination();
				hifulfillmentEvent.processInformation(terminationEventList);
			}
			if (enrollmentEventList.size() > 0) {
				HIFulfillmentEventEnrollment hifulfillmentEvent = new HIFulfillmentEventEnrollment();
				hifulfillmentEvent.processInformation(enrollmentEventList);
			}
			if (employeeUpdateEventList.size() > 0) {
				HIFulfillmentEventEmployeeUpdate hifulfillmentEmployeeUpdateEvent = new HIFulfillmentEventEmployeeUpdate();
				hifulfillmentEmployeeUpdateEvent.processInformation(employeeUpdateEventList);
			}
			if (auditEventList.size() > 0) {
				HIFulfillmentEventAudit HIFulfillmentAuditEvent = new HIFulfillmentEventAudit();
				HIFulfillmentAuditEvent.processInformation(auditEventList);
			}
			if (hsaEnrollmentEventList.size() > 0) {
				HIFulfillmentEventHsaEnrolment hsaEnrolllment = new HIFulfillmentEventHsaEnrolment();
				hsaEnrolllment.processInformation(hsaEnrollmentEventList);
			}
			if (dependentAgingOutList.size() > 0) {
				HIFulfillmentDependentAgingOut dependentAgingOut = new HIFulfillmentDependentAgingOut();
				dependentAgingOut.processInformation(dependentAgingOutList);
			}
			if (borNewHireList.size() > 0) {
				HIFulfillmentBORNewHire borNewHire = new HIFulfillmentBORNewHire();
				borNewHire.processInformation(borNewHireList);
			}
			if (eoiSubmissionList.size() > 0) {
				HIFulfillmentEOISubmission eoiSubmission = new HIFulfillmentEOISubmission();
				eoiSubmission.processInformation(eoiSubmissionList);
			}
			if (basicpacificList.size() > 0) {
				HIFulfillmentAddToBasicPacific addToBasic = new HIFulfillmentAddToBasicPacific();
				addToBasic.processInformation(basicpacificList);
			}
			if (eoiFollowupList.size() > 0) {
				HIFulfillmentEoiFollowup eoiFollowup = new HIFulfillmentEoiFollowup();
				eoiFollowup.processInformation(eoiFollowupList);
			}
			if (errorEditingSeletionList.size() > 0) {
				HIFulfillmentErrorEditingSelection errorEditingSelection = new HIFulfillmentErrorEditingSelection();
				errorEditingSelection.processInformation(errorEditingSeletionList);
			}
			if (openEnrollmentEventList.size() > 0) {
				HIFulfillmentEventOpenEnrollment openEnrollmentEvent = new HIFulfillmentEventOpenEnrollment();
				openEnrollmentEvent.processInformation(openEnrollmentEventList);
			}
			if (listTadaAudit.size() > 0) {
				HIFulfillmentEventTadaAudit tadaAuditEvent = new HIFulfillmentEventTadaAudit();
				tadaAuditEvent.processInformation(listTadaAudit);
			}
			if (list_ContTermination != null && list_ContTermination.size() > 0) {
				HIFulfillmentEventContTermination contTerminationEvent = new HIFulfillmentEventContTermination();
				contTerminationEvent.processInformation(list_ContTermination);
			}
			if (list_ContinuationElectionEvent.size() > 0) {
				HIContinuationElectionEvent.processInformation(list_ContinuationElectionEvent);
			}
		} else {
			for (HI_Fulfillment_Event__c objHIFulfill : events) {
				objHIFulfill.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public override void afterUpdate() {
		List<HI_Fulfillment_Event__c> events = (List<HI_Fulfillment_Event__c>) Trigger.new;
		if (queue == false && !test.isRunningTest()) {
			if (Limits.getQueueableJobs() == 0) {
				try {
					ID jobID = System.enqueueJob(new HIFulfillmentEventQueue(events));
				} catch (Exception ex) {
				}
			}
		}
	}

	public static HI_Fulfillment_Event__c setProcessingState(String ProcessingState, String message, HI_Fulfillment_Event__c objHIFulfill) {
		objHIFulfill.Processing_State__c = ProcessingState;
		objHIFulfill.Message__c = message;
		objHIFulfill.Processed_At__c = System.now();
		return objHIFulfill;
	}

	private static void setIntegrationLogic(List<HI_Fulfillment_Event__c> list_Events) {
		Map<String, Integration_Logic_Setting__c> logicMap = Integration_Logic_Setting__c.getall();
		if (logicMap.containsKey('HIFulfillmentEventTrigger')) {
			Integration_Logic_Setting__c logic = logicMap.get('HIFulfillmentEventTrigger');
			if (logic.Skip_Trigger_User_Name__c != null) {
				if (logic.Skip_Trigger_User_Name__c.indexOf(UserInfo.getUserName() + ';') > -1) {
					skipTrigger = true;
				}
			}
			if (logic.RealTime_User_Name__c != null) {
				if (logic.RealTime_User_Name__c.indexOf(UserInfo.getUserName() + ';') > -1) {
					queue = true;
				}
			}
			if (logic.Real_Time_Events__c != null && list_Events != null && list_Events.size() > 0) {
				for (HI_Fulfillment_Event__c objEvent : list_Events) {
					if (String.isNotBlank(objEvent.Event_Type__c) && logic.Real_Time_Events__c.indexOf(objEvent.Event_Type__c + ';') > -1) {
						queue = true;
					}
				}
			}
		}
	}
}