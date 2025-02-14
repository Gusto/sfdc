/**
* @name         HIGroupEventAdvisingEmailAutomation
* @author       Anand
* @Date         01/11/2021
* @description  This class handels the HIGroupEvent__c object json parsing and field mapping to  Advising Email AutomationJSON
* @test class   HIGroupEventAdvisingEmailAutomation.cls
* @revisions    Date ------------ Name ------------ Comments   
               
**/

public class HIGroupEventAdvisingEmailAutomation {
	static final String RENEWAL_OPP_APPLICATION_PREFIX = 'hawaiian_ice-renewal-';
	static Set<String> set_EmailTemplateNames = new Set<String>();
	static Map<String, OrgWideEmailAddress> map_OrgWideAddresses = new Map<String, OrgWideEmailAddress>();

	static final String ERROR_MSG_OPP_CLOSED = 'Related Opportunity is closed.';
	static final String ERROR_MSG_OPENCASENOTFOUND = 'Not able to find open case.';
	static final String ERROR_MSG_EMAILFAILURE = 'Error while sending email.';
	static final String ERROR_MSG_ALREADYSENT = ' is already sent. ';
	static final String INDEXOF_ALREADYSENT = 'is already sent';

	static final String INTRO_EMAIL_TYPE = 'Advising Intro Email';
	static final String INTRO_EMAIL_TYPE_TADAS = 'Advising Intro Email Tadas';
	static final String INTRO_EMAIL_TYPE_SCORP = 'Advising Intro Email SCorp';
	static final String INTRO_EMAIL_TYPE_SCORP_TADAS = 'Advising Intro Email Scorp And Tadas';
	public static final String LFT_INTRO = 'Level Funded Transition Intro';
	public static final String LFT_AUTO_RENEW = 'Level Funded Auto Renewal';
	static final String ADVISING_FOLLOWUP_EMAIL = 'Advising Followup Email';
	static final String ADVISING_FINAL_REMINDER_EMAIL = 'Advising Final Reminder Email';
	static final String ADVISING_AUTO_RENEWAL_EMAIL = 'Advising Auto Renewal Email';
	static final String PROCESSED_SUCESSFULLY = 'HI Group event Intro email processed sucessfully.';
	static final String ERROR_MSG_JSON = 'Something went wrong while deserializing JSON String.';
	static final String ERROR_MSG_OPEN_CASE_NOT_AVAILABLE = 'Related Open case is not available.';
	static final String ERROR_MSG_ADVISING_EMAIL_OFF = 'Event processed successfully but, emails are turned off for the customer.';
	static final String ERROR_MSG_RELATED_CASE_NOT_FOUND = 'Not able to find related case.';
	static final String ERROR_MSG_CONTACT_NOT_ASSOCIATED = 'Contact is not associated with related case - ';
	static final String ERROR_MSG_CONTACT_FIRST_NAME = 'Contact first name field is blank. ';
	static final String ERROR_MSG_ACCOUNT_NAME = 'Account name field is blank. ';
	static final String ERROR_MSG_COVERAGE_EFFECTIVE = 'Coverage Effective Date field is blank. ';
	static final String ERROR_MSG_SELECTION_DEADLINE = 'Selection Deadline Date field is blank. ';
	public static final String ERROR_MSG_INVALID_SELECTION_DEADLINE = 'Selection Deadline Date field is invalid. ';
	static final String ERROR_MSG_BENEFIT_ADDRESS = 'Benefit Address field is blank. ';
	static final String ERROR_MSG_NUMBER_OF_DAYS = 'Number of Days Remaining field is blank. ';
	static final String ERROR_MSG_INVALID_DATA = 'Invalid data for validation. ';
	public static final String REASON_FOR_ADVISING = 'Auto-renewed';

	static final String ERROR_MSG_OCR = '~ocr';
	static final String ERROR_MSG_CASE = '~case';
	static final String ERROR_MSG_OPPORTUNITY = '~opportunity';
	static final String ERROR_MSG_EMAILMESSAGE = '~emailcreation';

	static final String MACRO_ID_ADVISING_TEAM_SIGNATURE = 'advising_team_signature';
	public static final String MACRO_ID_LEVEL_FUNDED_MACRO = 'Advising Level Funded Intro Email';
	public static final String MACRO_ID_LEVEL_FUNDED_SAME_TX = 'level_funded_intro_email_same/same_TX';
	public static final String MACRO_ID_LEVEL_FUNDED_SAME_NONTTX = 'level_funded_intro_email_same/same_non-TX';
	public static final String MACRO_ID_LEVEL_FUNDED_SWITCH_TX = 'level_funded_intro_email_carrier_switch_TX';
	public static final String MACRO_ID_LEVEL_FUNDED_SWITCH_NONTX = 'level_funded_intro_email_carrier_switch_non-TX';

	static Map<String, String> map_CompanyIdErrorMessages = new Map<String, String>();
	static Map<String, String> map_CompanyIdExistingErrorMessages = new Map<String, String>();
	static Map<String, Boolean> map_CompanyIdEmailSent = new Map<String, Boolean>();
	static String strProcessAgain = null;
	static String strDMLError = '';
	static Boolean blnEmailSent = false;

	//For Email Macros
	public static Set<String> set_MacroIdentifier = new Set<String>{ MACRO_ID_ADVISING_TEAM_SIGNATURE, MACRO_ID_LEVEL_FUNDED_MACRO, MACRO_ID_LEVEL_FUNDED_SAME_TX, MACRO_ID_LEVEL_FUNDED_SAME_NONTTX, MACRO_ID_LEVEL_FUNDED_SWITCH_TX, MACRO_ID_LEVEL_FUNDED_SWITCH_NONTX };

	private static Map<String, String> map_RetriveEmailMacro = HIGroupEventAdvisingEmailAutomation.getEmailMacro();

	//we are using this mapping in this class only. That is why we have not moved the following map to any util
	//Updated Map for BBO-2141
	static Map<String, String> map_TemplateIdentifierEmailCodes = new Map<String, String>{
		'Advising Intro Email' => 'Intro Email',
		'Advising Intro Email Tadas' => 'Intro Email',
		'Advising Intro Email SCorp' => 'Intro Email',
		'Advising Intro Email Scorp And Tadas' => 'Intro Email',
		'Advising Followup Email' => 'Followup Email',
		'Advising Final Reminder Email' => 'Final Reminder Email',
		'Advising Auto Renewal Email' => 'Auto Renewal Email',
        LFT_INTRO => LFT_INTRO,
		LFT_AUTO_RENEW => LFT_AUTO_RENEW,
		'Level Funded Transition Intro' => 'Level Funded Transition Intro',
        'Level Funded Transition Check In' => 'Level Funded Transition Check In',
        'Level Funded Auto Renewal' => 'Level Funded Auto Renewal'
	};
	
	static Set<String> set_OnOffAutomatedAdvisingEmails = new Set<String>{ 'Advising Followup Email', 'Advising Final Reminder Email','Advising Intro Email', 'Advising Intro Email Tadas', 'Advising Intro Email SCorp', 'Advising Intro Email Scorp And Tadas', LFT_INTRO, LFT_AUTO_RENEW};
	//Added for 2141 
	static Map<String,String> map_EmailTypeToTemplateNameIdentifier = New Map<String,String>{
		'Level Funded Transition Intro' => 'Level Funded Transition Intro',
		'Level Funded Transition Check In' => 'Level Funded Transition Advising Check In Email',
		'Level Funded Auto Renewal' => 'Level Funded Auto Renewal'    
	};
	public static Configuration_Settings__c objConfigSettings = Configuration_Settings__c.getOrgDefaults();

	public static void processIntroInformation(List<HIEventWrapper> list_HiGroupEventIntroEmail) {
		if (list_HiGroupEventIntroEmail != null && list_HiGroupEventIntroEmail.size() > 0) {
			for (HIEventWrapper objHIGroupEventWrapper : list_HiGroupEventIntroEmail) {
				HIGroupEvent__c objHIGroupEvent = (HIGroupEvent__c) objHIGroupEventWrapper.objHiGroupEvent;

				if (String.isNotBlank(objHIGroupEvent.Message__c)) {
					map_CompanyIdExistingErrorMessages.put(objHIGroupEvent.Company_Id__c, objHIGroupEvent.Message__c);
					map_CompanyIdEmailSent.put(objHIGroupEvent.Company_Id__c, objHIGroupEvent.Email_Sent__c);
				}

				//Clear the message
				objHIGroupEvent.Message__c = null;

				try {
					String strJson = objHIGroupEventWrapper.jsonString;
					AdvisingEmailJSONWrapper objHIIntroEmailtWrapper = (AdvisingEmailJSONWrapper) JSON.deserialize(strJson, AdvisingEmailJSONWrapper.class);

					objHIGroupEvent.Application_type__c = objHIIntroEmailtWrapper.application_type;
					objHIGroupEvent.Application_Id__c = objHIIntroEmailtWrapper.application_id;
					objHIGroupEvent.Company_Id__c = objHIIntroEmailtWrapper.company_id;
					objHIGroupEvent.Survey_Completed_By__c = objHIIntroEmailtWrapper.survey_completed_by;
					if (String.isNotBlank(objHIIntroEmailtWrapper.selection_deadline)) {
						objHIGroupEvent.Selection_Deadline_Date__c = convertDateFromString(objHIIntroEmailtWrapper.selection_deadline);
					}

					String strEmailType = INTRO_EMAIL_TYPE;
					if (objHIIntroEmailtWrapper.tada_interest_from_survey && !objHIIntroEmailtWrapper.scorp) {
						strEmailType = INTRO_EMAIL_TYPE_TADAS;
					}

					if (!objHIIntroEmailtWrapper.tada_interest_from_survey && objHIIntroEmailtWrapper.scorp) {
						strEmailType = INTRO_EMAIL_TYPE_SCORP;
					}

					if (objHIIntroEmailtWrapper.tada_interest_from_survey && objHIIntroEmailtWrapper.scorp) {
						strEmailType = INTRO_EMAIL_TYPE_SCORP_TADAS;
					}

					if (objHIGroupEvent.Event_Type__c != null && HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_INTRO.equalsIgnoreCase(objHIGroupEvent.Event_Type__c)) {
						strEmailType = LFT_INTRO;
					}

					if (objHIGroupEvent.Event_Type__c != null && HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_AUTO_RENEW.equalsIgnoreCase(objHIGroupEvent.Event_Type__c)) {
						strEmailType = LFT_AUTO_RENEW;
					}
                   //BBO-2141 Start
				   if (objHIGroupEvent.Event_Type__c != null && HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_TRANSITION_RENEWAL_INTRO_EMAIL.equalsIgnoreCase(objHIGroupEvent.Event_Type__c)) {
					strEmailType = HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_TRANSITION_RENEWAL_INTRO_EMAIL_LABEL;
				}
				if (objHIGroupEvent.Event_Type__c != null && HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_TRANSITION_RENEWAL_CHECKIN_EMAIL.equalsIgnoreCase(objHIGroupEvent.Event_Type__c)) {
					strEmailType = HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_TRANSITION_RENEWAL_CHECKIN_EMAIL_LABEL;
				}
				if (objHIGroupEvent.Event_Type__c != null && HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_AUTO_RENEWAL_EMAIL.equalsIgnoreCase(objHIGroupEvent.Event_Type__c)) {
					strEmailType = HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_AUTO_RENEWAL_EMAIL_LABEL;
				}
				//BBO-2141 Ends
					objHIGroupEvent.Email_Type__c = strEmailType;
					AdvisingEmailJSONWrapper.Benefit_Address objAddress = objHIIntroEmailtWrapper.benefit_address;

					String strBenefitAddress = null;
					if (objAddress != null) {
						if (String.isNotBlank(objAddress.street_1)) {
							strBenefitAddress = objAddress.street_1;
						}

						if (String.isNotBlank(objAddress.street_2)) {
							strBenefitAddress = strBenefitAddress + ', ' + objAddress.street_2;
						}

						if (String.isNotBlank(objAddress.city) && String.isNotBlank(objAddress.state) && String.isNotBlank(objAddress.zip)) {
							strBenefitAddress = strBenefitAddress + ', ' + objAddress.city;
							strBenefitAddress = strBenefitAddress + ', ' + objAddress.state + ' ' + objAddress.zip;
						}

						if (String.isNotBlank(objAddress.country)) {
							strBenefitAddress = strBenefitAddress + ' ' + objAddress.country;
						}
					}

					objHIGroupEvent.Benefit_Address__c = strBenefitAddress;
                    //BBO-2141 Started
                    system.debug('objHIGroupEvent.Email_Type__c==> '+objHIGroupEvent.Email_Type__c);
                    system.debug('map_EmailTypeToTemplateNameIdentifier==> '+map_EmailTypeToTemplateNameIdentifier);
                    system.debug('Condition Check=> '+map_EmailTypeToTemplateNameIdentifier.containsKey(objHIGroupEvent.Email_Type__c));
                    if(map_EmailTypeToTemplateNameIdentifier.containsKey(objHIGroupEvent.Email_Type__c)){
                        set_EmailTemplateNames.add(map_EmailTypeToTemplateNameIdentifier.get(objHIGroupEvent.Email_Type__c));
                    }
                    else{
						set_EmailTemplateNames.add(objHIGroupEvent.Email_Type__c);
                    }
                    //BBO-2141 Ends
					HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, PROCESSED_SUCESSFULLY, objHIGroupEvent);
				} catch (Exception objEx) {
					HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, ERROR_MSG_JSON, objHIGroupEvent);
					continue;
				}
			}

			//Sending Email
			if (set_EmailTemplateNames != null && set_EmailTemplateNames.size() > 0) {
				sendAdvisingEmail(list_HiGroupEventIntroEmail);
			}
		}
	}

	public static void processFollowupInformation(List<HIEventWrapper> list_HiGroupEventFollowUpEmail) {
		if (list_HiGroupEventFollowUpEmail != null && list_HiGroupEventFollowUpEmail.size() > 0) {
			for (HIEventWrapper objHIGroupEventWrapper : list_HiGroupEventFollowUpEmail) {
				HIGroupEvent__c objHIGroupEvent = (HIGroupEvent__c) objHIGroupEventWrapper.objHiGroupEvent;

				if (String.isNotBlank(objHIGroupEvent.Message__c)) {
					map_CompanyIdExistingErrorMessages.put(objHIGroupEvent.Company_Id__c, objHIGroupEvent.Message__c);
					map_CompanyIdEmailSent.put(objHIGroupEvent.Company_Id__c, objHIGroupEvent.Email_Sent__c);
				}

				//Clear the message
				objHIGroupEvent.Message__c = null;

				try {
					String strJson = objHIGroupEventWrapper.jsonString;
					AdvisingEmailJSONWrapper objHIFollowUpWrapper = (AdvisingEmailJSONWrapper) JSON.deserialize(strJson, AdvisingEmailJSONWrapper.class);

					objHIGroupEvent.Application_type__c = objHIFollowUpWrapper.application_type;
					objHIGroupEvent.Application_Id__c = objHIFollowUpWrapper.application_id;
					objHIGroupEvent.Company_Id__c = String.valueOf(objHIFollowUpWrapper.company_id);
					if (String.isNotBlank(objHIFollowUpWrapper.selection_deadline)) {
						objHIGroupEvent.Selection_Deadline_Date__c = ConvertDateFromString(objHIFollowUpWrapper.selection_deadline);
					}

					objHIGroupEvent.Number_Of_Days_Remaining__c = objHIFollowUpWrapper.number_of_days_remaining;
					String strEmailType = ADVISING_FOLLOWUP_EMAIL;
					//If remaining  days is 0 then send last followup
					if (objHIGroupEvent.Number_Of_Days_Remaining__c == '0') {
						strEmailType = ADVISING_FINAL_REMINDER_EMAIL;

						String strPlanHTML = '<ul>';
						if (objHIFollowUpWrapper.medical != null && objHIFollowUpWrapper.medical.size() > 0) {
							String strDetails = '<li>Medical</li><ul>';
							for (AdvisingEmailJSONWrapper.Medical objDetail : objHIFollowUpWrapper.medical) {
								strDetails += '<li>' + objDetail.plan_name + '</li>';
							}
							strDetails += '</ul>';

							strPlanHTML += strDetails;
						}

						if (objHIFollowUpWrapper.dental != null && objHIFollowUpWrapper.dental.size() > 0) {
							String strDetails = '<li>Dental</li><ul>';
							for (AdvisingEmailJSONWrapper.Dental objDetail : objHIFollowUpWrapper.dental) {
								strDetails += '<li>' + objDetail.plan_name + '</li>';
							}
							strDetails += '</ul>';

							strPlanHTML += strDetails;
						}

						if (objHIFollowUpWrapper.vision != null && objHIFollowUpWrapper.vision.size() > 0) {
							String strDetails = '<li>Vision</li><ul>';
							for (AdvisingEmailJSONWrapper.Vision objDetail : objHIFollowUpWrapper.vision) {
								strDetails += '<li>' + objDetail.plan_name + '</li>';
							}
							strDetails += '</ul>';

							strPlanHTML += strDetails;
						}

						if (objHIFollowUpWrapper.long_term_disability != null && objHIFollowUpWrapper.long_term_disability.size() > 0) {
							String strDetails = '<li>Long Term Disability</li><ul>';
							for (AdvisingEmailJSONWrapper.Long_term_disability objDetail : objHIFollowUpWrapper.long_term_disability) {
								strDetails += '<li>' + objDetail.plan_name + '</li>';
							}
							strDetails += '</ul>';

							strPlanHTML += strDetails;
						}

						if (objHIFollowUpWrapper.short_term_disability != null && objHIFollowUpWrapper.short_term_disability.size() > 0) {
							String strDetails = '<li>Long Term Disability</li><ul>';
							for (AdvisingEmailJSONWrapper.Short_term_disability objDetail : objHIFollowUpWrapper.short_term_disability) {
								strDetails += '<li>' + objDetail.plan_name + '</li>';
							}
							strDetails += '</ul>';

							strPlanHTML += strDetails;
						}

						if (String.isNotBlank(objHIFollowUpWrapper.tadas)) {
							String strDetails = '<li>Tax-Advantaged Accounts</li><ul>';
							for (String objDetail : objHIFollowUpWrapper.tadas.split(',')) {
								strDetails += '<li>' + objDetail.toUpperCase() + '</li>';
							}
							strDetails += '</ul>';

							strPlanHTML += strDetails;
						}

						strPlanHTML += '</ul>';
						objHIGroupEvent.Advising_Plans__c = strPlanHTML;
					}

					objHIGroupEvent.Email_Type__c = strEmailType;
					set_EmailTemplateNames.add(objHIGroupEvent.Email_Type__c);
					HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, PROCESSED_SUCESSFULLY, objHIGroupEvent);
				} catch (Exception objEx) {
					HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, ERROR_MSG_JSON, objHIGroupEvent);
					continue;
				}
			}

			//Sending Email
			if (set_EmailTemplateNames != null && set_EmailTemplateNames.size() > 0) {
				sendAdvisingEmail(list_HiGroupEventFollowUpEmail);
			}
		}
	}

	public static void processFinalInformation(List<HIEventWrapper> list_HiGroupEventFinalEmail) {
		if (list_HiGroupEventFinalEmail != null && list_HiGroupEventFinalEmail.size() > 0) {
			for (HIEventWrapper objHIGroupEventWrapper : list_HiGroupEventFinalEmail) {
				HIGroupEvent__c objHIGroupEvent = (HIGroupEvent__c) objHIGroupEventWrapper.objHiGroupEvent;

				if (String.isNotBlank(objHIGroupEvent.Message__c)) {
					map_CompanyIdExistingErrorMessages.put(objHIGroupEvent.Company_Id__c, objHIGroupEvent.Message__c);
					map_CompanyIdEmailSent.put(objHIGroupEvent.Company_Id__c, objHIGroupEvent.Email_Sent__c);
				}

				//Clear the message
				objHIGroupEvent.Message__c = null;

				try {
					String strJson = objHIGroupEventWrapper.jsonString;
					AdvisingEmailJSONWrapper objHIFinalWrapper = (AdvisingEmailJSONWrapper) JSON.deserialize(strJson, AdvisingEmailJSONWrapper.class);

					objHIGroupEvent.Application_type__c = objHIFinalWrapper.application_type;
					objHIGroupEvent.Application_Id__c = String.valueOf(objHIFinalWrapper.application_id);
					objHIGroupEvent.Company_Id__c = String.valueOf(objHIFinalWrapper.company_id);

					if (String.isNotBlank(objHIFinalWrapper.selection_deadline)) {
						objHIGroupEvent.Selection_Deadline_Date__c = ConvertDateFromString(objHIFinalWrapper.selection_deadline);
					}

					objHIGroupEvent.Email_Type__c = ADVISING_AUTO_RENEWAL_EMAIL;
					set_EmailTemplateNames.add(objHIGroupEvent.Email_Type__c);
					HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, PROCESSED_SUCESSFULLY, objHIGroupEvent);
				} catch (Exception objEx) {
					HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, ERROR_MSG_JSON, objHIGroupEvent);
					continue;
				}
			}

			//Sending Email
			if (set_EmailTemplateNames != null && set_EmailTemplateNames.size() > 0) {
				sendAdvisingEmail(list_HiGroupEventFinalEmail);
			}
		}
	}
    
    public static void sendAdvisingEmail(List<HIEventWrapper> list_HiGroupEventWrapperRecords) {
		if (list_HiGroupEventWrapperRecords != null && list_HiGroupEventWrapperRecords.size() > 0) {
			Set<String> set_OppApplicationIds = new Set<String>();
			Set<String> set_OppCompanyIds = new Set<String>();
			Map<String, Case> map_OppCompanyIdWithLatestCases = new Map<String, Case>();
			Map<String, List<String>> map_OppCompanyIdWithCCEmailIds = new Map<String, List<String>>();
			Set<String> set_OppEligibleContactRoles = new Set<String>{ 'Payroll Admin', 'Primary Payroll Admin', 'Benefits Signatory', 'Benefits Admin' };
			Map<String, String> map_ZpCompanyIdErrors = new Map<String, String>();
			map_OrgWideAddresses = OEEmailAutomationHelper.getOrgWideAddresses(new Set<String>{ HIGroupEventUtil.ORG_WIDE_DEFAULT_RENEWAL });
			Map<String, Contact> map_ZPUserIdContacts = new Map<String, Contact>();
			Map<String, String> map_CompanyZPUserIds = new Map<String, String>();
			Map<String, String> map_CompanyIdWithApplicationIds = new Map<String, String>();
			List<Case> list_CasesToUpdate = new List<Case>();
			Database.DMLOptions objDO = new Database.DMLOptions();
			objDO.assignmentRuleHeader.useDefaultRule = false;

			Boolean blnIsContactChanged = false;
			List<OpportunityContactRole> list_OpportunityContactRoles = new List<OpportunityContactRole>();
			Map<String, String> map_OpportunityIdCompanyIds = new Map<String, String>();
			Map<String, String> map_OpportunityContactRoleIdCompanyIds = new Map<String, String>();
			Map<String, String> map_CaseIdIdCompanyIds = new Map<String, String>();

			Set<Id> set_CaseOwnerIds = new Set<Id>();

			//looping through HIGroupEvent records to get related ApplicationIds and CompanyIds
			for (HIEventWrapper objHIGroupEventWrapper : list_HiGroupEventWrapperRecords) {
				HIGroupEvent__c objHIGroupEvent = (HIGroupEvent__c) objHIGroupEventWrapper.objHiGroupEvent;
				if (objHIGroupEvent.Processing_State__c != IntegrationUtils.ERROR_STATE) {
					set_OppApplicationIds.add(RENEWAL_OPP_APPLICATION_PREFIX + objHIGroupEvent.Application_Id__c);
					set_OppCompanyIds.add(objHIGroupEvent.Company_Id__c);
					map_CompanyIdWithApplicationIds.put(objHIGroupEvent.Company_Id__c + ':' + RENEWAL_OPP_APPLICATION_PREFIX + objHIGroupEvent.Application_Id__c, objHIGroupEvent.Email_Type__c);

					if (string.isNotBlank(objHIGroupEvent.Survey_Completed_By__c)) {
						map_CompanyZPUserIds.put(objHIGroupEvent.Company_Id__c, objHIGroupEvent.Survey_Completed_By__c);
					}
				}
			}

			//get All Related Contact based on Survey Submitted By
			if (map_CompanyZPUserIds != null && map_CompanyZPUserIds.size() > 0) {
				Set<String> set_ZPUserIds = new Set<String>();
				set_ZPUserIds.addAll(map_CompanyZPUserIds.values());

				for (Contact objContact : [SELECT Id, ZP_User_Id__c, FirstName, Account.Name FROM Contact WHERE ZP_User_Id__c != NULL AND ZP_User_Id__c IN :set_ZPUserIds]) {
					map_ZPUserIdContacts.put(objContact.ZP_User_Id__c, objContact);
				}
			}

			if (set_OppCompanyIds.size() > 0 && set_OppApplicationIds.size() > 0) {
				//Looping through "Queried Open Opportunity" using "CompanyId & ApplicationId"
				for (Opportunity objOpp : [
					SELECT
						Id,
						Account.ZP_Company_ID__c,
						Intro_Email_Date__c,
						Advising_Email__c,
						Source_ID__c,
						(
							SELECT
								Id,
								ContactId,
								Contact.ZP_User_Id__c,
								CreatedDate,
								IsClosed,
								Contact.FirstName,
								AccountId,
								Account.Name,
								Account.ZP_Company_ID__c,
								Coverage_Effective_Date__c,
								Opportunity__c,
								Opportunity__r.Source_ID__c,
								Case_Reference__c,
								Opportunity__r.Advising_Email__c,
								CaseNumber,
								Opportunity__r.Owner_Role_Name__c,
								OwnerId,
								Automated_Advising_Emails_Off__c,
								Renewal_Date__c,
								Offering_Selection_Deadline__c
							FROM Cases__r
							WHERE RecordTypeId = :OpportunityUtil.BENEFITS_RENEWAL_CASE_RT_ID AND Integration_Id__c != NULL AND Integration_Id__c LIKE 'hippo-%' AND AccountId != NULL
							ORDER BY CreatedDate DESC
							LIMIT 1
						),
						(
							SELECT Id, IsPrimary, ContactId, Contact.ZP_User_Id__c, Role
							FROM OpportunityContactRoles
							WHERE Role IN :set_OppEligibleContactRoles AND Contact.IsEmailBounced = FALSE AND Contact.EmailBouncedReason = NULL
						)
					FROM Opportunity
					WHERE
						AccountId != NULL
						AND Account.ZP_Company_ID__c != NULL
						AND Account.ZP_Company_ID__c IN :set_OppCompanyIds
						AND Source_ID__c != NULL
						AND Source_ID__c IN :set_OppApplicationIds
						AND StageName != :OpportunityUtil.CLOSED_WON_STAGE
						AND StageName != :OpportunityUtil.CLOSED_LOST_STAGE
						AND RecordTypeId = :OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID
				]) {
					String strErrorMsg = ' ';
					blnIsContactChanged = false;
					String strKey = objOpp.Account.ZP_Company_ID__c + ':' + objOpp.Source_ID__c;

					if (objOpp.Cases__r != null && objOpp.Cases__r.size() > 0 && objOpp.Cases__r.get(0).IsClosed) {
						strErrorMsg = ERROR_MSG_OPEN_CASE_NOT_AVAILABLE;
					}

					if (
						objOpp.Cases__r != null &&
						objOpp.Cases__r.size() > 0 &&
						objOpp.Cases__r.get(0).Automated_Advising_Emails_Off__c &&
						!set_OnOffAutomatedAdvisingEmails.isEmpty() &&
						!map_CompanyIdWithApplicationIds.isEmpty() &&
						map_CompanyIdWithApplicationIds.containsKey(strKey) &&
						set_OnOffAutomatedAdvisingEmails.contains(map_CompanyIdWithApplicationIds.get(strKey))
					) {
						strErrorMsg += ERROR_MSG_ADVISING_EMAIL_OFF;
					}

					if (objOpp.Cases__r == null || objOpp.Cases__r.size() == 0) {
						strErrorMsg += ERROR_MSG_RELATED_CASE_NOT_FOUND;
					}

					if (objOpp.Cases__r != null && objOpp.Cases__r.size() > 0 && !objOpp.Cases__r.get(0).IsClosed && String.isBlank(strErrorMsg)) {
						if (!map_OppCompanyIdWithLatestCases.containsKey(objOpp.Account.ZP_Company_ID__c)) {
							//Get Case Associated Contact ZP user Id and Compare with Survey Submitted by
							String strCompanyId = objOpp.Account.ZP_Company_ID__c;
							if (
								map_ZPUserIdContacts != null &&
								strCompanyId != null &&
								map_CompanyZPUserIds.containsKey(strCompanyId) &&
								map_CompanyZPUserIds.get(strCompanyId) != objOpp.Cases__r.get(0).Contact.ZP_User_Id__c
							) {
								String strZPUserId = map_CompanyZPUserIds.get(strCompanyId);

								if (String.isNotBlank(strZPUserId) && map_ZPUserIdContacts.containsKey(strZPUserId)) {
									objOpp.Cases__r.get(0).ContactId = map_ZPUserIdContacts.get(strZPUserId).Id;
									objOpp.Cases__r.get(0).setOptions(objDO);
									objOpp.Cases__r.get(0).Skip_Assignment__c = true;
									list_CasesToUpdate.add(objOpp.Cases__r.get(0));
									blnIsContactChanged = true;
								}
							}

							map_OppCompanyIdWithLatestCases.put(objOpp.Account.ZP_Company_ID__c, objOpp.Cases__r.get(0));
							//get Map of Open case and Company id
							map_CaseIdIdCompanyIds.put(objOpp.Cases__r.get(0).Id, objOpp.Account.ZP_Company_ID__c);

							if (
								FWManageRoleUtil.ROLE_ADVISOR.equalsIgnoreCase(objOpp.Cases__r.get(0).Opportunity__r.Owner_Role_Name__c) ||
								FWManageRoleUtil.ROLE_RENEWAL_SPECIALIST.equalsIgnoreCase(objOpp.Cases__r.get(0).Opportunity__r.Owner_Role_Name__c)
							) {
								set_CaseOwnerIds.add(objOpp.Cases__r.get(0).OwnerId);
							}
						}

						if (objOpp.OpportunityContactRoles != null && objOpp.OpportunityContactRoles.size() > 0) {
							List<String> list_TempContactIds = new List<String>();
							for (OpportunityContactRole objOppCRole : objOpp.OpportunityContactRoles) {
								if (objOpp.Cases__r.get(0).ContactId != objOppCRole.ContactId) {
									list_TempContactIds.add(objOppCRole.ContactId);
								}

								//make it false if any opp primary contact role exist
								if (blnIsContactChanged == true) {
									objOppCRole.IsPrimary = false;
									if (objOpp.Cases__r.get(0).ContactId == objOppCRole.ContactId) {
										objOppCRole.IsPrimary = true;
									}

									list_OpportunityContactRoles.add(objOppCRole);
									map_OpportunityContactRoleIdCompanyIds.put(objOppCRole.Id, objOpp.Account.ZP_Company_ID__c);
								}
							}
							if (list_TempContactIds.size() > 0) {
								map_OppCompanyIdWithCCEmailIds.put(objOpp.Account.ZP_Company_ID__c, list_TempContactIds);
							}
						}
					}

					if (String.isNotBlank(strErrorMsg)) {
						if (map_ZpCompanyIdErrors.containsKey(objOpp.Account.ZP_Company_ID__c)) {
							strErrorMsg += map_ZpCompanyIdErrors.get(objOpp.Account.ZP_Company_ID__c);
						}

						map_ZpCompanyIdErrors.put(objOpp.Account.ZP_Company_ID__c, strErrorMsg);
					}
				}

				Map<Id, Messaging.SingleEmailMessage> map_CaseIdEmailMessageInstances = new Map<Id, Messaging.SingleEmailMessage>();
				Map<String, EmailTemplate> map_TemplateNameRecords = new Map<String, EmailTemplate>();
				Set<Id> set_ErroredTargetObjectIds = new Set<Id>();
				List<Opportunity> list_ToUpdateOpportunities = new List<Opportunity>();
				Map<Id, EmailMessage> map_ContactIdsEmailMessageToInsert = new Map<Id, EmailMessage>();

				Map<Id, String> map_UserSignature = !set_CaseOwnerIds.isEmpty() ? OEEmailAutomationHelper.fetchUserSignature(set_CaseOwnerIds) : null;

				//Querying Email Templates related to Advising Email
				for (EmailTemplate objET : [SELECT Id, Subject, DeveloperName, HtmlValue, Name FROM EmailTemplate WHERE Name IN :set_EmailTemplateNames]) {
					map_TemplateNameRecords.put(objET.Name, objET);
				}

				//looping through HIEventGroup to create Messaging.SingleEmailMessage intances
				for (HIEventWrapper objHIGroupEventWrapper : list_HiGroupEventWrapperRecords) {
					HIGroupEvent__c objHIGroupEvent = (HIGroupEvent__c) objHIGroupEventWrapper.objHiGroupEvent;
					AdvisingEmailJSONWrapper objHIFollowUpWrapper = (AdvisingEmailJSONWrapper) JSON.deserialize(objHIGroupEventWrapper.jsonString, AdvisingEmailJSONWrapper.class);

					if (objHIGroupEvent.Processing_State__c == IntegrationUtils.ERROR_STATE) {
						continue;
					}

					if (map_ZpCompanyIdErrors.containsKey(objHIGroupEvent.Company_Id__c)) {
						String strStatus = IntegrationUtils.ERROR_STATE;

						if (map_ZpCompanyIdErrors.get(objHIGroupEvent.Company_Id__c).contains(ERROR_MSG_ADVISING_EMAIL_OFF)) {
							strStatus = IntegrationUtils.PROCESSED_STATE;
						}

						HIGroupEventTriggerHelper.setProcessingState(strStatus, map_ZpCompanyIdErrors.get(objHIGroupEvent.Company_Id__c), objHIGroupEvent);
						continue;
					}

					if (!map_OppCompanyIdWithLatestCases.containsKey(objHIGroupEvent.Company_Id__c)) {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, ERROR_MSG_OPP_CLOSED, objHIGroupEvent);
						continue;
					}

					Case objCase = map_OppCompanyIdWithLatestCases.get(objHIGroupEvent.Company_Id__c);
                    //Chage Contion For BBO-2141
					if (objCase != null && objCase.Id != null && (map_TemplateNameRecords.containsKey(objHIGroupEvent.Email_Type__c) || map_TemplateNameRecords.containsKey(map_EmailTypeToTemplateNameIdentifier.get(objHIGroupEvent.Email_Type__c)))) {
						String strValidationError = validationCheck(objCase, objHIGroupEvent, objHIFollowUpWrapper);

						if (String.isNotBlank(strValidationError)) {
							map_ZpCompanyIdErrors.put(objHIGroupEvent.Company_Id__c, strValidationError);
							String strErrorType = IntegrationUtils.ERROR_STATE;
							if (strValidationError.indexOf(INDEXOF_ALREADYSENT) > -1) {
								strErrorType = IntegrationUtils.DEAD_STATE;
							} else if (strValidationError.indexOf(ERROR_MSG_INVALID_SELECTION_DEADLINE) > -1) {
								strErrorType = IntegrationUtils.DEAD_STATE;
							}
							HIGroupEventTriggerHelper.setProcessingState(strErrorType, strValidationError, objHIGroupEvent);
							continue;
						}

						try {
							//code for OutboundEmail instance creation---------starts-----------
							EmailTemplate objEmailTemplate = map_TemplateNameRecords.get(objHIGroupEvent.Email_Type__c);
							String strEmailSubject = populateEmailSubjectDynamicFieldValues(objEmailTemplate.Subject, objCase, objHIFollowUpWrapper);
							//Condition Added for BBO-2141
                            if(map_TemplateNameRecords.containsKey(map_EmailTypeToTemplateNameIdentifier.get(objHIGroupEvent.Email_Type__c))){
                                objEmailTemplate = map_TemplateNameRecords.get(map_EmailTypeToTemplateNameIdentifier.get(objHIGroupEvent.Email_Type__c));
                            }
							Contact objContact = null;
							//If Contact get changed on case then retrive new contact based on Zp user id from HIGroup Event
							if (list_CasesToUpdate != null && list_CasesToUpdate.size() > 0 && map_ZPUserIdContacts.containsKey(objHIGroupEvent.Survey_Completed_By__c)) {
								objContact = map_ZPUserIdContacts.get(objHIGroupEvent.Survey_Completed_By__c);
							}

							String strEmailBody = populateEmailBodyWithDynamicFieldValues(objEmailTemplate.HtmlValue, objCase, objContact, objHIGroupEvent, map_UserSignature);

							Messaging.SingleEmailMessage objMessage = createEmailRecord(strEmailSubject, objCase, strEmailBody);

							//code to set cc addresses
							if (map_OppCompanyIdWithCCEmailIds.containsKey(objHIGroupEvent.Company_Id__c)) {
								objMessage.setCcAddresses(map_OppCompanyIdWithCCEmailIds.get(objHIGroupEvent.Company_Id__c));
							}

							if (map_OrgWideAddresses != null && map_OrgWideAddresses.size() > 0) {
								objMessage.setOrgWideEmailAddressId(map_OrgWideAddresses.values().get(0).Id);
							}

							//If email already sent then no need to execute again
							if (objHIGroupEvent.Email_Sent__c == false) {
								map_CaseIdEmailMessageInstances.put(objCase.Id, objMessage);
							}

							//code for OutboundEmail instance creation---------Ends-----------
							//code for EmailMessage record creation-------- start-----------
							EmailMessage objEmailMessage = createEmailMessageRecord(strEmailBody, objCase, strEmailSubject, objEmailTemplate.DeveloperName, objMessage, objHIGroupEvent);
							map_ContactIdsEmailMessageToInsert.put(objCase.ContactId, objEmailMessage);
							//code for EmailMessage record creation-------- Ends-----------
						} catch (Exception objEx) {
							HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, objEx.getMessage(), objHIGroupEvent);
							continue;
						}
					} else {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, ERROR_MSG_OPENCASENOTFOUND, objHIGroupEvent);
						continue;
					}
				}

				//in this we are sending email and handling errors while sending emails.
				//If email already sent then this  will not execeute again
				if (map_CaseIdEmailMessageInstances != null && map_CaseIdEmailMessageInstances.size() > 0) {
					List<Messaging.SendEmailResult> results = new List<Messaging.SendEmailResult>();
					if(OrganizationUtilities.canSendEmails()){
						results = Messaging.sendEmail(map_CaseIdEmailMessageInstances.values(), false);
					}

					for (Messaging.SendEmailResult objResult : results) {
						if (!objResult.isSuccess()) {
							set_ErroredTargetObjectIds.add(objResult.getErrors().get(0).getTargetObjectId());
						}
					}

					for (HIEventWrapper objHIGroupEventWrapper : list_HiGroupEventWrapperRecords) {
						HIGroupEvent__c objHIGroupEvent = (HIGroupEvent__c) objHIGroupEventWrapper.objHiGroupEvent;

						Case objCase = map_OppCompanyIdWithLatestCases.containsKey(objHIGroupEvent.Company_Id__c) ? map_OppCompanyIdWithLatestCases.get(objHIGroupEvent.Company_Id__c) : null;

						if (objCase?.ContactId != null && set_ErroredTargetObjectIds?.contains(objCase.ContactId)) {
							HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, ERROR_MSG_EMAILFAILURE, objHIGroupEvent);
							map_ContactIdsEmailMessageToInsert.remove(objCase.ContactId);
							continue;
						} else if (map_ZpCompanyIdErrors.containsKey(objHIGroupEvent.Company_Id__c)) {
							continue;
						} else {
							if(OrganizationUtilities.canSendEmails()){
								objHIGroupEvent.Email_Sent__c = true;
							}
						}
					}
				}

				//After email sent successfully get related opportuity data
				for (HIEventWrapper objHIGroupEventWrapper : list_HiGroupEventWrapperRecords) {
					HIGroupEvent__c objHIGroupEvent = (HIGroupEvent__c) objHIGroupEventWrapper.objHiGroupEvent;

					//Error handling
					if (objHIGroupEvent.Processing_State__c == IntegrationUtils.ERROR_STATE || objHIGroupEvent.Processing_State__c == IntegrationUtils.DEAD_STATE) {
						continue;
					}

					if (map_ZpCompanyIdErrors.containsKey(objHIGroupEvent.Company_Id__c)) {
						String strStatus = IntegrationUtils.ERROR_STATE;

						if (map_ZpCompanyIdErrors.get(objHIGroupEvent.Company_Id__c).contains(ERROR_MSG_ADVISING_EMAIL_OFF)) {
							strStatus = IntegrationUtils.PROCESSED_STATE;
						}

						HIGroupEventTriggerHelper.setProcessingState(strStatus, map_ZpCompanyIdErrors.get(objHIGroupEvent.Company_Id__c), objHIGroupEvent);
						continue;
					}

					//Get HI Group Message
					processMessage(objHIGroupEvent.Company_Id__c);

					Case objCase = map_OppCompanyIdWithLatestCases.containsKey(objHIGroupEvent.Company_Id__c) ? map_OppCompanyIdWithLatestCases.get(objHIGroupEvent.Company_Id__c) : null;

					if (objCase != null && objCase.Opportunity__c != null && objHIGroupEvent.Processing_State__c != IntegrationUtils.ERROR_STATE) {
						if ((strProcessAgain == null && blnEmailSent == false) || (strProcessAgain != null && strProcessAgain.indexOf('~opportunity') > -1)) {
							Opportunity objTempOppRec = new Opportunity(Id = objCase.Opportunity__c);

							Set<String> set_StrEmailType = new Set<String>();
							if (objCase?.Opportunity__c != null && String.isNotBlank(objCase.Opportunity__r.Advising_Email__c)) {
								set_StrEmailType.addAll(objCase.Opportunity__r.Advising_Email__c.split(';'));
							}

							set_StrEmailType.add(map_TemplateIdentifierEmailCodes.get(objHIGroupEvent.Email_Type__c));
							List<String> list_tempEmailType = new List<String>();
							list_tempEmailType.addAll(set_StrEmailType);
							objTempOppRec.Advising_Email__c = String.join(list_tempEmailType, ';');

							if (objHIGroupEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_RENEWAL_INTRO) {
								objTempOppRec.StageName = OpportunityUtil.RECOMMENDATION_SENT_STAGE;
								objTempOppRec.Recommendation_Sent_Start__c = System.now();
								objTempOppRec.Intro_Email_Date__c = System.Today();
							} else if (objHIGroupEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_RENEWAL_FINAL) {
								objTempOppRec.Reason_for_Advising__c = REASON_FOR_ADVISING;
							}

							list_ToUpdateOpportunities.add(objTempOppRec);
							map_OpportunityIdCompanyIds.put(objTempOppRec.Id, objHIGroupEvent.Company_Id__c);
							HIGroupEventTriggerHelper.setProcessingState(
								IntegrationUtils.PROCESSED_STATE,
								'HI Group event ' +
								map_TemplateIdentifierEmailCodes.get(objHIGroupEvent.Email_Type__c) +
								' processed sucessfully.',
								objHIGroupEvent
							);
						}
					} else {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, ERROR_MSG_OPENCASENOTFOUND, objHIGroupEvent);
						continue;
					}
				}

				//Update Opportunity
				if (list_ToUpdateOpportunities != null && list_ToUpdateOpportunities.size() > 0) {
					updateOpportunity(list_ToUpdateOpportunities, map_OpportunityIdCompanyIds);
				}

				//Update Case
				if (
					list_CasesToUpdate != null &&
					list_CasesToUpdate.size() > 0 &&
					((strProcessAgain == null && blnEmailSent == false) || (strProcessAgain != null && strProcessAgain.indexOf('~case') > -1))
				) {
					updateCase(list_CasesToUpdate, map_CaseIdIdCompanyIds);
				}

				//Update Opportunity Contact Role
				if (
					list_OpportunityContactRoles != null &&
					list_OpportunityContactRoles.size() > 0 &&
					((strProcessAgain == null && blnEmailSent == false) || (strProcessAgain != null && strProcessAgain.indexOf('~ocr') > -1))
				) {
					updateOpportunityContactRole(list_OpportunityContactRoles, map_OpportunityContactRoleIdCompanyIds);
				}

				//Create Email Message insert code
				if (
					map_ContactIdsEmailMessageToInsert != null &&
					map_ContactIdsEmailMessageToInsert.size() > 0 &&
					((strProcessAgain == null && blnEmailSent == false) || (strProcessAgain != null && strProcessAgain.indexOf('~emailcreation') > -1))
				) {
					//Create Email Record
					insertEmailRecord(map_ContactIdsEmailMessageToInsert.values(), map_CaseIdIdCompanyIds);
				}

				for (HIEventWrapper objHIGroupEventWrapper : list_HiGroupEventWrapperRecords) {
					HIGroupEvent__c objHIGroupEvent = (HIGroupEvent__c) objHIGroupEventWrapper.objHiGroupEvent;
					if (String.isNotBlank(objHIGroupEvent.Company_Id__c) && map_CompanyIdErrorMessages.containsKey(objHIGroupEvent.Company_Id__c)) {
						String strMessage = map_CompanyIdErrorMessages.get(objHIGroupEvent.Company_Id__c);

						if (String.isNotBlank(strDMLError)) {
							strMessage = '{' + strDMLError + '}' + '#' + strMessage;
						}

						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, strMessage, objHIGroupEvent);
					}
				}
			}
		}
	}

	//Update Opportunity Method
	private static void updateOpportunity(List<Opportunity> list_UpdateOpportunityTemp, Map<String, String> map_OpportunityIdCompanyIdTemp) {
		try {
			Map<String, String> map_RecordIdUpdateErrors = new Map<String, String>();
			List<Database.SaveResult> list_UpdateResults = new List<Database.SaveResult>();
			List<Database.SaveResult> list_TempUpdateResult = new List<Database.SaveResult>();
			OpportunityTriggerHelper.skipTrigger = true;
			list_TempUpdateResult = Database.update(list_UpdateOpportunityTemp, false);

			for (Database.SaveResult objSaveResult : list_TempUpdateResult) {
				if (!objSaveResult.isSuccess()) {
					for (Database.Error err : objSaveResult.getErrors()) {
						if (!err.getMessage().contains('Opportunities stage cannot be changed after stage becomes')) {
							list_UpdateResults.add(objSaveResult);
							break;
						}
					}
				}
			}

			map_RecordIdUpdateErrors = Utils.processSaveRecords(list_UpdateResults, list_UpdateOpportunityTemp, 'Id', true, 'HIGroupEventAdvisingEmailAutomation', 'SendAdvisingEmail-Opportunity');
			if (map_RecordIdUpdateErrors != null && map_RecordIdUpdateErrors.size() > 0) {
				strDMLError = '~opportunity';
			}

			for (String strOppId : map_RecordIdUpdateErrors.keySet()) {
				if (map_OpportunityIdCompanyIdTemp.containsKey(strOppId)) {
					map_CompanyIdErrorMessages.put(map_OpportunityIdCompanyIdTemp.get(strOppId), map_RecordIdUpdateErrors.get(strOppId));
				}
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException(
				'HIGroupEventAdvisinEmailAutomation',
				'sendAdvisingEmail',
				'Exception On Line ' +
				objException.getLineNumber() +
				'-' +
				objException.getMessage(),
				objException.getStackTraceString()
			);
		}
	}

	//Update Case Method
	private static void updateCase(List<Case> list_CasesToUpdateTemp, Map<String, String> map_CaseIdIdCompanyIdTemp) {
		try {
			Map<String, String> map_RecordIdUpdateErrors = new Map<String, String>();
			List<Database.SaveResult> list_UpdateResults = new List<Database.SaveResult>();
			CaseTriggerHelper.skipTrigger = true;
			list_UpdateResults = Database.update(list_CasesToUpdateTemp, false);

			map_RecordIdUpdateErrors = Utils.processSaveRecords(list_UpdateResults, list_CasesToUpdateTemp, 'Id', true, 'HIGroupEventAdvisingEmailAutomation', 'SendAdvisingEmail-Case');

			if (map_RecordIdUpdateErrors != null && map_RecordIdUpdateErrors.size() > 0) {
				strDMLError = strDMLError + '~case';
			}

			for (String strCaseId : map_RecordIdUpdateErrors.keySet()) {
				if (map_CaseIdIdCompanyIdTemp.containsKey(strCaseId)) {
					map_CompanyIdErrorMessages.put(map_CaseIdIdCompanyIdTemp.get(strCaseId), map_RecordIdUpdateErrors.get(strCaseId));
				}
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException(
				'HIGroupEventAdvisinEmailAutomation',
				'sendAdvisingEmail',
				'Exception On Line ' +
				objException.getLineNumber() +
				'-' +
				objException.getMessage(),
				objException.getStackTraceString()
			);
		}
	}

	//Update Opportunity Contact Role Method
	private static void updateOpportunityContactRole(List<OpportunityContactRole> list_OpportunityContactRoleTemp, Map<String, String> map_OpportunityContactRoleIdCompanyIdTemp) {
		Map<String, String> map_RecordIdUpdateErrors = new Map<String, String>();
		List<Database.SaveResult> list_UpdateResults = new List<Database.SaveResult>();
		try {
			list_UpdateResults = Database.update(list_OpportunityContactRoleTemp, false);

			map_RecordIdUpdateErrors = Utils.processSaveRecords(
				list_UpdateResults,
				list_OpportunityContactRoleTemp,
				'Id',
				true,
				'HIGroupEventAdvisingEmailAutomation',
				'SendAdvisingEmail-OpportunityContactRole'
			);

			if (map_RecordIdUpdateErrors != null && map_RecordIdUpdateErrors.size() > 0) {
				strDMLError = strDMLError + '~ocr';
			}

			for (String strOppId : map_RecordIdUpdateErrors.keySet()) {
				if (map_OpportunityContactRoleIdCompanyIdTemp.containsKey(strOppId)) {
					map_CompanyIdErrorMessages.put(map_OpportunityContactRoleIdCompanyIdTemp.get(strOppId), map_RecordIdUpdateErrors.get(strOppId));
				}
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException(
				'HIGroupEventAdvisinEmailAutomation',
				'sendAdvisingEmail',
				'Exception On Line ' +
				objException.getLineNumber() +
				'-' +
				objException.getMessage(),
				objException.getStackTraceString()
			);
		}
	}

	//Create Email message record
	private static void insertEmailRecord(List<EmailMessage> list_EmailMessageTemp, Map<String, String> map_CaseIdIdCompanyIdTemp) {
		try {
			Map<String, String> map_RecordIdUpdateErrors = new Map<String, String>();
			List<Database.SaveResult> list_UpdateResults = new List<Database.SaveResult>();

			list_UpdateResults = Database.insert(list_EmailMessageTemp, false);

			map_RecordIdUpdateErrors = Utils.processSaveRecords(list_UpdateResults, list_EmailMessageTemp, 'ParentId', true, 'HIGroupEventAdvisingEmailAutomation', 'SendAdvisingEmail-Email Creation');

			if (map_RecordIdUpdateErrors != null && map_RecordIdUpdateErrors.size() > 0) {
				strDMLError = strDMLError + '~emailcreation';
			}

			for (String strCaseId : map_RecordIdUpdateErrors.keySet()) {
				if (map_CaseIdIdCompanyIdTemp.containsKey(strCaseId)) {
					map_CompanyIdErrorMessages.put(map_CaseIdIdCompanyIdTemp.get(strCaseId), map_RecordIdUpdateErrors.get(strCaseId));
				}
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException(
				'HIGroupEventAdvisinEmailAutomation',
				'EmailMessage record creation.',
				'Exception On Line ' +
				objException.getLineNumber() +
				'-' +
				objException.getMessage(),
				objException.getStackTraceString()
			);
		}
	}

	private static void processMessage(String strCompanyIdTemp) {
		String strHIGroupEventMessage = null;
		blnEmailSent = false;
		if (map_CompanyIdExistingErrorMessages != null && map_CompanyIdExistingErrorMessages.size() > 0 && map_CompanyIdExistingErrorMessages.containsKey(strCompanyIdTemp) != null) {
			strHIGroupEventMessage = map_CompanyIdExistingErrorMessages.get(strCompanyIdTemp);
		}

		//For Email Sent
		if (map_CompanyIdEmailSent != null && map_CompanyIdEmailSent.size() > 0 && map_CompanyIdEmailSent.containsKey(strCompanyIdTemp) != null) {
			blnEmailSent = map_CompanyIdEmailSent.get(strCompanyIdTemp);
		}

		if (
			String.isNotBlank(strHIGroupEventMessage) &&
			(strHIGroupEventMessage.indexOf(ERROR_MSG_OCR) > -1 ||
			strHIGroupEventMessage.indexOf(ERROR_MSG_CASE) > -1 ||
			strHIGroupEventMessage.indexOf(ERROR_MSG_OPPORTUNITY) > -1 ||
			strHIGroupEventMessage.indexOf(ERROR_MSG_EMAILMESSAGE) > -1)
		) {
			strProcessAgain = strHIGroupEventMessage.split('#')[0];
		}
	}

	public static Date convertDateFromString(String strDate) {
		Date dtDate = null;
		if (String.isNotBlank(strDate)) {
			try {
				dtDate = Date.valueOf(strDate);
				String strYear = dtDate.year() + '';
				if (strYear.length() != 4) {
					dtDate = null;
				}
			} catch (Exception objException) {
				dtDate = null;
			}
		}
		return dtDate;
	}

	public static String populateEmailBodyWithDynamicFieldValues(
		String strTemplateOriginalBody,
		Case objCase,
		Contact objContactTemp,
		HIGroupEvent__c objHIGroupEvent,
		Map<Id, String> map_UserSignature
	) {
		String strFinalEmailBody = strTemplateOriginalBody;

		if (String.isNotBlank(strFinalEmailBody)) {
			strFinalEmailBody = setCommonFieldValues(strTemplateOriginalBody, objCase, objContactTemp, objHIGroupEvent, map_UserSignature);
		}

		return strFinalEmailBody;
	}
	
	public static String populateEmailSubjectDynamicFieldValues (String strSubject, Case objCase, AdvisingEmailJSONWrapper objHIIntroEmailtWrapper) {
		if (objCase.Offering_Selection_Deadline__c != null) {
			strSubject = strSubject.replace('[OFFERING SELECTION DEADLINE]', objCase.Offering_Selection_Deadline__c.format());
		}
		if (objHIIntroEmailtWrapper.alternate_package_savings != null) {
			strSubject = strSubject.replace('[alt percentage savings]', objHIIntroEmailtWrapper.alternate_package_savings);
		}

		strSubject = strSubject.replace('[ACCOUNT NAME]', objCase.Account.Name);

		return strSubject;
	}

	public static String setCommonFieldValues(String strTemplateBody, Case objCase, Contact objContactTemp, HIGroupEvent__c objHIGroupEvent, Map<Id, String> map_UserSignature) {
		if (String.isNotBlank(strTemplateBody) && objCase != null && objHIGroupEvent != null) {
			AdvisingEmailJSONWrapper objHIIntroEmailtWrapper = (AdvisingEmailJSONWrapper) JSON.deserialize(objHIGroupEvent.Event_Info__c, AdvisingEmailJSONWrapper.class);
			String strSeacrhKey = objHIGroupEvent.Event_Type__c;
			if (objHIIntroEmailtWrapper.alternate_recommendation_type != null) {
				strSeacrhKey = strSeacrhKey + '_' + objHIIntroEmailtWrapper.alternate_recommendation_type;
			}
			if (objHIIntroEmailtWrapper.benefit_address != null && String.isNotBlank(objHIIntroEmailtWrapper.benefit_address.state)) {
				if (objHIIntroEmailtWrapper.benefit_address.state.equalsIgnoreCase('TX')) {
					strSeacrhKey = strSeacrhKey + '_TX';
				} else {
					strSeacrhKey = strSeacrhKey + '_non-TX';
				}
			}

			if (map_RetriveEmailMacro.containsKey(strSeacrhKey)) {
				strTemplateBody = strTemplateBody.replace('[MACRO]', map_RetriveEmailMacro.get(strSeacrhKey));
			}

			String strValue = '';
			String strKey = '[' + MACRO_ID_LEVEL_FUNDED_MACRO + ']';
			if (
				map_RetriveEmailMacro.containsKey(strKey) && 
				HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_INTRO.equalsIgnoreCase(objHIGroupEvent.Event_Type__c) &&
				objHIIntroEmailtWrapper.alternate_recommendation_type != null && 
				objHIIntroEmailtWrapper.alternate_recommendation_type.equalsIgnoreCase('carrier_switch')
			) {
				strValue = map_RetriveEmailMacro.get(strKey);
			}
			strTemplateBody = strTemplateBody.replace(strKey, strValue);

			if (objContactTemp == null && objCase.ContactId != null) {
				strTemplateBody = strTemplateBody.replace('[CONTACT FIRSTNAME]', objCase.Contact.FirstName);
			} else if (objContactTemp != null) {
				strTemplateBody = strTemplateBody.replace('[CONTACT FIRSTNAME]', objContactTemp.FirstName);
			}

			strTemplateBody = strTemplateBody.replace('[ACCOUNT NAME]', objCase.Account.Name);

			if (objCase.Renewal_Date__c != null) {
				strTemplateBody = strTemplateBody.replace('[RENEWAL DATE]', objCase.Renewal_Date__c.format());
			}

			if (objCase.Offering_Selection_Deadline__c != null) {
				strTemplateBody = strTemplateBody.replace('[OFFERING SELECTION DEADLINE]', objCase.Offering_Selection_Deadline__c.format());
			}

			if (objCase.Coverage_Effective_Date__c != null) {
				strTemplateBody = strTemplateBody.replace('[COVERAGE EFFECTIVE DATE]', objCase.Coverage_Effective_Date__c);
			}
			
			if (objHIIntroEmailtWrapper.default_renewal_rate_change != null) {
				strTemplateBody = strTemplateBody.replace('[default increase]', objHIIntroEmailtWrapper.default_renewal_rate_change);
			}
			if (objHIIntroEmailtWrapper.alternate_package_savings != null) {
				strTemplateBody = strTemplateBody.replace('[alt percentage savings]', objHIIntroEmailtWrapper.alternate_package_savings);
			}

			String strCarrier = '';
			if (objHIIntroEmailtWrapper.alternate_package_carrier != null) {
				strCarrier = objHIIntroEmailtWrapper.alternate_package_carrier;
			}
			strTemplateBody = strTemplateBody.replace('[CARRIER]', strCarrier);

			String strDefaultQuote = '';
			if (objHIIntroEmailtWrapper.default_cost_breakdown_pdf != null) {
				strDefaultQuote ='<a href="' + objHIIntroEmailtWrapper.default_cost_breakdown_pdf + '">HERE</a>';
			}
			
			String strFundedtQuote = '';
			if (objHIIntroEmailtWrapper.alternate_cost_breakdown_pdf != null) {
				strFundedtQuote = '<a href="' + objHIIntroEmailtWrapper.alternate_cost_breakdown_pdf + '">HERE</a>';
			}
			strTemplateBody = strTemplateBody.replace('[default renewal quote]', strDefaultQuote);
			strTemplateBody = strTemplateBody.replace('[alt level funded quote]', strFundedtQuote);

			if (objHIGroupEvent.Selection_Deadline_Date__c != null) {
				DateTime dtmTempDeadLine = objHIGroupEvent.Selection_Deadline_Date__c;
				String strFormattedDate = String.valueOf(dtmTempDeadLine.formatGMT('EEEE, MMMM d'));

				if (dtmTempDeadLine.dayGmt() == 1) {
					strFormattedDate += 'st';
				} else if (dtmTempDeadLine.dayGmt() == 2) {
					strFormattedDate += 'nd';
				} else if (dtmTempDeadLine.dayGmt() == 3) {
					strFormattedDate += 'rd';
				} else {
					strFormattedDate += 'th';
				}

				strTemplateBody = strTemplateBody.replace('[SELECTION DEADLINE DATE]', strFormattedDate);
			}

			if (objHIGroupEvent.Benefit_Address__c != null) {
				strTemplateBody = strTemplateBody.replace('[BENEFIT ADDRESS]', objHIGroupEvent.Benefit_Address__c);
			}

			if (objCase.Opportunity__c != null && map_RetriveEmailMacro != null) {
				if (
					(FWManageRoleUtil.ROLE_ADVISOR.equalsIgnoreCase(objCase.Opportunity__r.Owner_Role_Name__c) ||
					FWManageRoleUtil.ROLE_RENEWAL_SPECIALIST.equalsIgnoreCase(objCase.Opportunity__r.Owner_Role_Name__c)) &&
					map_UserSignature != null &&
					map_UserSignature.containsKey(objCase.OwnerId)
				) {
					strTemplateBody = strTemplateBody.replace('[SIGNATURE]', map_UserSignature.get(objCase.OwnerId));
				} else if (map_RetriveEmailMacro.containsKey(MACRO_ID_ADVISING_TEAM_SIGNATURE)) {
					strTemplateBody = strTemplateBody.replace('[SIGNATURE]', map_RetriveEmailMacro.get(MACRO_ID_ADVISING_TEAM_SIGNATURE));
				}	
			}

			if (objHIGroupEvent.Number_Of_Days_Remaining__c != null) {
				strTemplateBody = strTemplateBody.replace('[NUMBER OF DAYS]', objHIGroupEvent.Number_Of_Days_Remaining__c);
			}

			if (objHIGroupEvent.Advising_Plans__c != null) {
				strTemplateBody = strTemplateBody.replace('[PLANS]', objHIGroupEvent.Advising_Plans__c);
			}

			strTemplateBody += '<div style="color: transparent">' + objCase.Case_Reference__c + '</div>';
		}

		return strTemplateBody;
	}

	public static Messaging.SingleEmailMessage createEmailRecord(String strSubject, Case objCase, String strBody) {
		//Add Account Name in Subject
		if (String.isNotBlank(strSubject) && strSubject.containsIgnoreCase('[ACCOUNT NAME]') && objCase != null && objCase.AccountId != null && objCase.Account.Name != null) {
			strSubject = strSubject.replace('[ACCOUNT NAME]', objCase.Account.Name);
		}

		Messaging.SingleEmailMessage objMail = new Messaging.SingleEmailMessage();
		objMail.setSubject(strSubject);
		objMail.setHTMLBody(strBody);
		objMail.setTargetObjectId(objCase.ContactId);
		objMail.setSaveAsActivity(false);
		objMail.setWhatId(objCase.Id);
		objMail.setUseSignature(false);
		return objMail;
	}

	public static String validationCheck(Case objCase, HIGroupEvent__c objHIGroupEvent, AdvisingEmailJSONWrapper objHIFollowUpWrapper) {
		String strError = '';

		if (objCase != null && objHIGroupEvent != null) {
			if (objCase.ContactId == null) {
				strError += ERROR_MSG_CONTACT_NOT_ASSOCIATED + objCase.CaseNumber + '. ';
			}

			if (
				String.isNotBlank(objCase.Opportunity__r.Advising_Email__c) &&
				((objHIGroupEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_RENEWAL_INTRO &&
				objCase.Opportunity__r.Advising_Email__c.indexOf(map_TemplateIdentifierEmailCodes.get(objHIGroupEvent.Email_Type__c)) > -1) ||
				(objHIGroupEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_RENEWAL_FINAL &&
				objCase.Opportunity__r.Advising_Email__c.indexOf(map_TemplateIdentifierEmailCodes.get(objHIGroupEvent.Email_Type__c)) > -1) ||
				(objHIGroupEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_INTRO &&
				objCase.Opportunity__r.Advising_Email__c.indexOf(map_TemplateIdentifierEmailCodes.get(objHIGroupEvent.Email_Type__c)) > -1) ||
				(objHIGroupEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_AUTO_RENEW &&
				objCase.Opportunity__r.Advising_Email__c.indexOf(map_TemplateIdentifierEmailCodes.get(objHIGroupEvent.Email_Type__c)) > -1))
			) {
				strError += map_TemplateIdentifierEmailCodes.get(objHIGroupEvent.Email_Type__c) + ERROR_MSG_ALREADYSENT;
			}

			if (objCase.ContactId != null && String.isBlank(objCase.Contact.FirstName)) {
				strError += ERROR_MSG_CONTACT_FIRST_NAME;
			}

			if (String.isBlank(objCase.Account.Name)) {
				strError += ERROR_MSG_ACCOUNT_NAME;
			}

			if (
				(objHIGroupEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_RENEWAL_INTRO ||
				(objHIGroupEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_RENEWAL_FOLLOWUP &&
				objHIGroupEvent.Number_Of_Days_Remaining__c != '0')) && objCase.Coverage_Effective_Date__c == null
			) {
				strError += ERROR_MSG_COVERAGE_EFFECTIVE;
			}

			if (objHIGroupEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_RENEWAL_INTRO) {
				if (String.isNotBlank(objHIFollowUpWrapper.selection_deadline) && convertDateFromString(objHIFollowUpWrapper.selection_deadline) == null) {
					strError += ERROR_MSG_INVALID_SELECTION_DEADLINE + objHIFollowUpWrapper.selection_deadline;
				} else if (objHIGroupEvent.Selection_Deadline_Date__c == null) {
					strError += ERROR_MSG_SELECTION_DEADLINE;
				}	
			}

			if (objHIGroupEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_RENEWAL_INTRO && String.isBlank(objHIGroupEvent.Benefit_Address__c)) {
				strError += ERROR_MSG_BENEFIT_ADDRESS;
			}

			if (
				objHIGroupEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_RENEWAL_FOLLOWUP &&
				objHIGroupEvent.Number_Of_Days_Remaining__c != '0' &&
				String.isBlank(objHIGroupEvent.Number_Of_Days_Remaining__c)
			) {
				strError += ERROR_MSG_NUMBER_OF_DAYS;
			}
		} else {
			strError = ERROR_MSG_INVALID_DATA;
		}

		return strError;
	}

	/*
	 * Creates EmailMessage record
	 */
	public static EmailMessage createEmailMessageRecord(
		String strBody,
		Case objCase,
		String strSubject,
		String strEmailTemplateName,
		Messaging.SingleEmailMessage objEmailMessage,
		HIGroupEvent__c objHIGroupEvent
	) {
		//Add Account Name in Subject
		if (String.isNotBlank(strSubject) && strSubject.containsIgnoreCase('[ACCOUNT NAME]') && objCase != null && objCase.AccountId != null && objCase.Account.Name != null) {
			strSubject = strSubject.replace('[ACCOUNT NAME]', objCase.Account.Name);
		}

		EmailMessage objMsg = new EmailMessage(); // Created a EmailMessage and copy all details.
		objMsg.ToAddress = objCase.contactId;
		objMsg.Subject = strSubject;
		objMsg.HtmlBody = strBody;
		objMsg.ParentId = objCase.Id; //Attaching with the case
		objMsg.MessageDate = System.now();
		objMsg.Status = '3';
		objMsg.Email_Template_Name__c = strEmailTemplateName;

		List<String> list_temp = objEmailMessage.getCcAddresses();
		if (list_temp != null && list_temp.size() > 0) {
			objMsg.CcAddress = String.join(list_temp, ',');
		}

		objMsg.FromName = HIGroupEventUtil.ORG_WIDE_DEFAULT_RENEWAL;
		objMsg.FromAddress = HIGroupEventUtil.ORG_WIDE_DEFAULT_RENEWAL;
		if (objHIGroupEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_RENEWAL_FOLLOWUP) {
			objMsg.Number_of_Days__c = (objHIGroupEvent.Number_Of_Days_Remaining__c != null ? decimal.valueOf(objHIGroupEvent.Number_Of_Days_Remaining__c) : null);
		}

		return objMsg;
	}

	//Getting EMail Macro to use in email template
	public static Map<String, String> getEmailMacro() {
		if (map_RetriveEmailMacro == null) {
			fetchEmailMacro();
		}
		return map_RetriveEmailMacro;
	}

	private static void fetchEmailMacro() {
		map_RetriveEmailMacro = new Map<String, String>();
		for (Email_Macro__c objEmailMacro : [
			SELECT Id, Body__c, Macro_Identifier__c
			FROM Email_Macro__c
			WHERE Carrier__c = NULL AND Macro_Identifier__c != NULL AND Macro_Identifier__c IN :set_MacroIdentifier
		]) {
			map_RetriveEmailMacro.put(objEmailMacro.Macro_Identifier__c, objEmailMacro.Body__c);
		}
	}
}