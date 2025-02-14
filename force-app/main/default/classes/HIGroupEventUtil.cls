/**
 * @name         HIGroupEventUtil
 * @author       Anand Singh
 * @date         01/20/2021
 * @description  Utility class to hold constants and common data
 * @test class   HIGroupEventTriggerHelperTest,SubmissionAutomationHelperTest
 * @revisions    Date ------------ Name ------------ Comments
 **/
public class HIGroupEventUtil {
	public static final String EVENT_TYPE_TTS_NOTE_POST_OE_EMAIL = 'tts_note_post_OE_email';
	public static final String GROUP_TTS_NOTE_POST_PROCESSED_MESSAGE = 'Email send successfully';
	public static final String EVENT_TYPE_DOC_COLLECTION_STATUS = 'document_collection_status';
	public static final String ERROR_DOC_COLLECTION_STATUS_MISSING = 'Document Collection Status is blank';
	public static final String DOC_COLLECTION_PROCESSED_MESSAGE = 'HI Document Collection Status Event Processed Successfully';
	public static final String GROUP_QUALIFICATION_PROCESSED_MESSAGE = 'Group Qualification Automation Event Processed Successfully';
	public static final String DOC_COLLECTION_ERROR_UNPROCESSED_EVENT = 'Either relevant Benefit Order was not found or there was an error while updating it';
	public static final String DOC_COLLECTION_DEAD_UNPROCESSED_EVENT = 'Corresponding benefit order not found.';
	public static final String ERROR_EMAIL_BODY_MISSING = 'Email body is blank.';
	public static final String RENEWAL_DEAD_UNPROCESSED_EVENT = 'Corresponding opportunity not found.';
	public static final String ERROR_ALTERNATE_REQ_DATE = 'Alternate packages requested timestamp is blank.';
	public static final String ERROR_UNPROCESSED_EVENT_OPP_UPDATE = 'Either relevant Opportunity was not found or there was an error while updating it';
	public static final String EVENT_TYPE_RENEWAL_REQUEST = 'renewal_alternates_requested';
	public static final String GROUP_RENEWAL_PROCESSED_MESSAGE = 'Group Renewal Alternates Requested Event Processed Successfully';
	public static final String GROUP_OA_INTRO_EMAIL_PROCESSED_MESSAGE = 'Group OA Intro Email Processed Successfully';
	public static final String EVENT_TYPE_QA_SHEET_INFO = 'qa_sheet_info';
	public static final String EVENT_TYPE_CONFIRMATION_AUTO = 'group_confirmations_automation';
	public static final String EVENT_TYPE_RENEWAL_INTRO = 'renewal_intro_email';
	public static final String EVENT_TYPE_RENEWAL_FOLLOWUP = 'renewal_followup_email';
    //Added for BBO-2141
    public static final String EVENT_TYPE_LEVEL_FUNDED_TRANSITION_RENEWAL_INTRO_EMAIL = 'level_funded_transition_renewal_intro_email';
    public static final String EVENT_TYPE_LEVEL_FUNDED_TRANSITION_RENEWAL_CHECKIN_EMAIL = 'level_funded_transition_renewal_check_in_email';
    public static final String EVENT_TYPE_LEVEL_FUNDED_AUTO_RENEWAL_EMAIL = 'level_funded_autorenew_email';
    public static final String EVENT_TYPE_LEVEL_FUNDED_TRANSITION_RENEWAL_INTRO_EMAIL_LABEL = 'Level Funded Transition Intro';
    public static final String EVENT_TYPE_LEVEL_FUNDED_TRANSITION_RENEWAL_CHECKIN_EMAIL_LABEL = 'Level Funded Transition Check In';
    public static final String EVENT_TYPE_LEVEL_FUNDED_AUTO_RENEWAL_EMAIL_LABEL = 'Level Funded Auto Renewal';
    //End
	public static final String EVENT_TYPE_RENEWAL_FINAL = 'autorenewal_email';
	public static final String EVENT_TYPE_LEVEL_FUNDED_INTRO = 'level_funded_intro_email';
	public static final String EVENT_TYPE_LEVEL_FUNDED_AUTO_RENEW = 'level_funded_autorenew_email';
	public static final String EVENT_TYPE_QUALIFICATION_AUTO = 'group_qualification_automation';
	public static final String EVENT_TYPE_OA_INTRO_EMAIL = 'OA_intro_email';
	public static final String EVENT_TYPE_GROUP_TERM_CASE = 'group_termination_case';
	public static final String TYPE_PARTIAL_COVERAGE_TERMINATION = 'Partial Coverage Termination';
	public static final String CASE_RELATED_TO_BO_NOT_FOUND = 'Case records related to benefit order not found.';
	public static final String EVENT_TYPE_SUBMISSION_AUTO = 'group_submission_automation';
	public static final String ORG_WIDE_DEFAULT_RENEWAL = 'renewals@gusto.com';
	public static final String ERROR_EVENT_INFO_MISSING = 'Event Info is blank';
	public static final String ERROR_EVENT_STATE_CARRIER_MISSING = 'State Carrier Id is blank';
	public static final String ERROR_APPLICATION_ID_MISSING = 'Application Id is blank';
	public static final String ERROR_EVENT_ID_MISSING = 'Event Id is blank';
	public static final String ERROR_APPLICATION_TYPE_MISSING = 'Application Type is blank';
	public static final String ERROR_APPLICATION_TYPE_INVALID = 'Application Type is Invalid';
	public static final String ERROR_COMPANY_ID_MISSING = 'Company Id is blank';
	public static final String ERROR_INVALID_TERM_REASON = 'Termination Reason is not configured in Salesforce';
	public static final String ERROR_UNPROCESSED_EVENT = 'Either relevant Carrier Order was not found or there was an error while updating it';
	public static final String PROCESSED_MESSAGE = 'HI Submission Automation Event Processed Successfully';
	public static final String GROUP_TERM_SUCCESS_MESSAGE = 'HI Group Event processed successfully';
	public static final String CO_REC_TYPE_NEW_PLAN = 'New Plan';
	public static final String CO_REC_TYPE_RENEWAL = 'Renewal';
	public static final String CO_REC_TYPE_CHANGE = 'Benefit Change';
	public static final Set<String> set_EligibleCORecTypesForAutomation = new Set<String>{ CO_REC_TYPE_NEW_PLAN, CO_REC_TYPE_RENEWAL, CO_REC_TYPE_CHANGE };
	public static final String CO_STATUS_READY_FOR_SUBMISSION_PREP = 'Ready for Submission Prep';
	public static final String CO_STATUS_READY_FOR_CONFIRMATION = 'Ready for Confirmation';
	public static final String STATUS_UNABLE_TO_AUTOMATE = 'Unable_to_automate';
	public static final String STATUS_FAILED = 'Failed';
	public static final String STATUS_SUCCESS = 'Success';
	public static final String FEED_TEXT_POST = 'TextPost';
	public static final String FEED_VISIBILITY_ALL = 'AllUsers';
	public static final String Y_VALUE = 'Y';
	public static final String N_VALUE = 'N';
	public static final String YES_VALUE = 'Yes';
	public static final String NO_VALUE = 'No';
	public static final String YES_SMALLCASE_VALUE = 'yes';
	public static final String HIPPO = 'HIPPO';
	public static final String NEW_PLANS_APPLICATIONS = '/new_plans_applications/';
	public static final String BENEFIT_CHANGE_APPLICATIONS = '/benefit_change_applications/';
	public static final String RENEWALS = '/renewals/';
	public static final String HIPPO_COMPANY_URL = 'http://hippo.gusto.com/companies/';
	public static final String QA_SHEET = '/qa_sheet';
	public static final String PLAN_ADDITIONS = 'Plan Additions:';
	public static final String PLAN_REMOVALS = 'Plan Removals:';
	public static final String PLAN_RENEWALS = 'Plan Renewals:';

	public static User objAutomatedUser;

	public static Id fetchAutomatedUserId() {
		Id idAutomatedUser;
		if (objAutomatedUser == null) {
			objAutomatedUser = [SELECT Id FROM User WHERE Alias = 'autoproc'];
		}

		if (objAutomatedUser != null && objAutomatedUser.Id != null) {
			idAutomatedUser = objAutomatedUser.Id;
		}

		return idAutomatedUser;
	}
}