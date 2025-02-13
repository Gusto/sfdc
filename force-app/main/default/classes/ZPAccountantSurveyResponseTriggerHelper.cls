/**
 * @Author      : Chandrika
 * Date Created : 03 August 2020
 * Asana        : https://app.asana.com/0/1182234805567945/1182419361757423
 * Desc         : This Helper class will Create Accountant Survey Response object and Relates to Account based on Information coming from Kafta
 * Test class   : ZPAccountantSurveyResponseTriggerTest
 */
public without sharing class ZPAccountantSurveyResponseTriggerHelper {
	public static Boolean skipTrigger = false;
	private static Integer intCounter = 0;
	public static Boolean blnQueue = false;

	public void OnBeforeInsert(List<ZP_Accountant_Survey_Response__c> list_zPAccountantSurveys) {
		intCounter++;
		try {
			for (ZP_Accountant_Survey_Response__c objZPAccountantSurvey : list_zPAccountantSurveys) {
				if (objZPAccountantSurvey.Processing_State__c != IntegrationUtils.DEAD_STATE || objZPAccountantSurvey.Processing_State__c != IntegrationUtils.BACKLOG) {
					objZPAccountantSurvey.Processing_State__c = IntegrationUtils.QUEUED_STATE;
				}
			}
			processInformation(list_zPAccountantSurveys);
		} catch (Exception ex) {
			ExceptionLogUtil.logException('ZPAccountantSurveyResponseTriggerHelper', 'Before Insert ', ex.getMessage(), 'Medium');
		}
	}

	public void OnAfterInsert(Map<Id, ZP_Accountant_Survey_Response__c> map_NewZPAccountantSurveys) {
	}

	public void OnBeforeUpdate(Map<Id, ZP_Accountant_Survey_Response__c> map_OldZPAccountantSurveys, Map<Id, ZP_Accountant_Survey_Response__c> map_NewZPAccountantSurveys) {
		try {
			for (ZP_Accountant_Survey_Response__c objZPAccountantSurvey : map_NewZPAccountantSurveys.values()) {
				if (objZPAccountantSurvey.Processing_State__c != IntegrationUtils.DEAD_STATE || objZPAccountantSurvey.Processing_State__c != IntegrationUtils.BACKLOG) {
					objZPAccountantSurvey.Processing_State__c = IntegrationUtils.QUEUED_STATE;
				}
			}
			processInformation(map_NewZPAccountantSurveys.values());
		} catch (Exception ex) {
			ExceptionLogUtil.logException('ZPAccountantSurveyResponseTriggerHelper', 'Before Update ', ex.getMessage(), 'Medium');
		}
	}

	public void OnAfterUpdate(Map<Id, ZP_Accountant_Survey_Response__c> map_OldZPAccountantSurveys, Map<Id, ZP_Accountant_Survey_Response__c> map_NewZPAccountantSurveys) {
	}

	private void processInformation(List<ZP_Accountant_Survey_Response__c> list_ZPAccSurveyResponses) {
		Set<String> set_ZPAccountantFirmId = new Set<String>();
		Set<String> set_ZPAccountantLeadId = new Set<String>();
		Set<String> set_ZPRespondentEmailIds = new Set<String>(); //BY:Prashant :31-08-2020
		Map<String, Accountant_Survey_Response__c> map_AccountantSurveyResponse = new Map<String, Accountant_Survey_Response__c>();
		Map<String, Account> map_AccountantSurveyResAcc = new Map<String, Account>();
		Map<String, Contact> map_AccountantSurveyResCon = new Map<String, Contact>();
		Map<String, Lead> map_AccountantSurveyResLead = new Map<String, Lead>(); //BY:Yuvraj :03-09-2020
		List<Accountant_Survey_Response__c> list_AccSurveyResponseToInsert = new List<Accountant_Survey_Response__c>();
		Map<Id, Accountant_Survey_Response__c> map_AccSurveysToUpdate = new Map<Id, Accountant_Survey_Response__c>();

		//BY:Prashant :09-09-2020 : Accountant Survey Update (Account,Contact,Lead) -variables
		Map<String, Accountant_Survey_Response__c> map_AccountFirmIdWithOnbrdIntent = new Map<String, Accountant_Survey_Response__c>();
		Map<String, String> map_ConRespEmailWithOnbrdIntent = new Map<String, String>();
		Map<String, String> map_LeadRespEmailWithOnbrdIntent = new Map<String, String>();
		Map<String, Lead> map_Leads = new Map<String, Lead>();
		Map<String, Account> map_Accounts = new Map<String, Account>();
		Map<Id, Lead> map_convertedLead = new Map<Id, Lead>();
		Set<Id> set_Accids = new Set<Id>();
		List<Account> list_AccountToUpdateOnboardSAL = new List<Account>();
		List<Contact> list_ContactToUpdateOnbordSAL = new List<Contact>();
		List<Lead> list_leadToUpdate = new List<Lead>();
		List<Accountant_Survey_Response__c> list_ASRtoUpdateAccConLead = new List<Accountant_Survey_Response__c>();
		Set<String> set_AccountantLeadIds = new Set<String>();

		//Error Map
		Map<String, String> map_DmlInsertUpdateErrorsMap_AccSurveyRes = new Map<String, String>();

		for (ZP_Accountant_Survey_Response__c objZPAccountantSurvey : list_ZPAccSurveyResponses) {
			if (objZPAccountantSurvey.Processing_State__c == IntegrationUtils.DEAD_STATE || objZPAccountantSurvey.Processing_State__c == IntegrationUtils.BACKLOG) {
				continue;
			}

			if (String.isBlank(objZPAccountantSurvey.Accountant_Lead_Id__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, objZPAccountantSurvey.Message__c = 'Accountant Lead Id does not exist', objZPAccountantSurvey);
				continue;
			}
			set_AccountantLeadIds.add(objZPAccountantSurvey.Accountant_Lead_Id__c);
			if (String.isNotBlank(objZPAccountantSurvey.Accounting_Firm_Id__c)) {
				set_ZPAccountantFirmId.add(objZPAccountantSurvey.Accounting_Firm_Id__c);
			}
			if (String.isNotBlank(objZPAccountantSurvey.Respondent_Email__c)) {
				set_ZPRespondentEmailIds.add(objZPAccountantSurvey.Respondent_Email__c);
			}
			objZPAccountantSurvey.Message__c = '';
		}

		if (!set_AccountantLeadIds.isEmpty()) {
			map_AccountantSurveyResponse = getAccSurveyResponse(set_AccountantLeadIds);
			map_AccountantSurveyResLead = getLead(set_AccountantLeadIds);
		}

		if (!set_ZPAccountantFirmId.isEmpty()) {
			map_AccountantSurveyResAcc = getAccount(set_ZPAccountantFirmId);
		}

		if (set_ZPRespondentEmailIds.size() > 0) {
			map_AccountantSurveyResCon = getContact(set_ZPRespondentEmailIds);
		}

		for (ZP_Accountant_Survey_Response__c objZPAccountantSurvey : list_ZPAccSurveyResponses) {
			if (objZPAccountantSurvey.Processing_State__c == IntegrationUtils.DEAD_STATE || objZPAccountantSurvey.Processing_State__c == IntegrationUtils.ERROR_STATE)
				continue;

			Account objAcc = null;
			Contact objContact = null;
			Lead objLead = null;
			if (map_AccountantSurveyResAcc.containsKey(objZPAccountantSurvey.Accounting_Firm_Id__c)) {
				objAcc = map_AccountantSurveyResAcc.get(objZPAccountantSurvey.Accounting_Firm_Id__c);
			}

			if (map_AccountantSurveyResCon.containsKey(objZPAccountantSurvey.Respondent_Email__c)) {
				objContact = map_AccountantSurveyResCon.get(objZPAccountantSurvey.Respondent_Email__c);
			}

			if (map_AccountantSurveyResLead.containsKey(objZPAccountantSurvey.Accountant_Lead_Id__c)) {
				objLead = map_AccountantSurveyResLead.get(objZPAccountantSurvey.Accountant_Lead_Id__c);
			}

			Accountant_Survey_Response__c objAccSurveyResponse = new Accountant_Survey_Response__c();

			if (map_AccountantSurveyResponse.containsKey(objZPAccountantSurvey.Accountant_Lead_Id__c)) {
				// update
				if (objLead != null) {
					objAccSurveyResponse = mapAccountantSurveyFields(objZPAccountantSurvey, map_AccountantSurveyResponse.get(objZPAccountantSurvey.Accountant_Lead_Id__c), objAcc, objContact, objLead); //By:Yuvraj :03-09-2020 :updated
					map_AccSurveysToUpdate.put(objAccSurveyResponse.Id, objAccSurveyResponse);
				} else {
					objZPAccountantSurvey.Processing_State__c = IntegrationUtils.ERROR_STATE;
					objZPAccountantSurvey.Message__c = 'Reseller Lead corresponding to survey NOT found!';
				}

				if (String.isNotBlank(objZPAccountantSurvey.Accounting_Firm_Id__c) && objAcc == null) {
					objZPAccountantSurvey.Processing_State__c = IntegrationUtils.ERROR_STATE;
					objZPAccountantSurvey.Message__c = 'Reseller Account corresponding to survey NOT found!';
				}
			} else {
				//insert
				if (objLead != null) {
					objAccSurveyResponse = mapAccountantSurveyFields(objZPAccountantSurvey, objAccSurveyResponse, objAcc, objContact, objLead); //By:Yuvraj :03-09-2020 :updated
					list_AccSurveyResponseToInsert.add(objAccSurveyResponse);
				} else {
					objZPAccountantSurvey.Processing_State__c = IntegrationUtils.ERROR_STATE;
					objZPAccountantSurvey.Message__c = 'Reseller Lead corresponding to survey NOT found!';
				}

				if (String.isNotBlank(objZPAccountantSurvey.Accounting_Firm_Id__c) && objAcc == null) {
					objZPAccountantSurvey.Processing_State__c = IntegrationUtils.ERROR_STATE;
					objZPAccountantSurvey.Message__c = 'Reseller Account corresponding to survey NOT found!';
				}
			}
		}

		//By:Prashant :09-09-2020 : To get the account/Lead/Contact details (Created  a new list to merge Insert and update Accountant survey resposne data)
		if (list_AccSurveyResponseToInsert.size() > 0) {
			list_ASRtoUpdateAccConLead.addAll(list_AccSurveyResponseToInsert);
			map_DmlInsertUpdateErrorsMap_AccSurveyRes = Utils.doDMLAndReturnAllErrors(
				'Insert',
				'Accountant_Lead_Id__c',
				list_AccSurveyResponseToInsert,
				false,
				true,
				'ZPAccountantSurveyResponseTriggerHelper-processInformation'
			);
		}

		if (!map_AccSurveysToUpdate.isEmpty()) {
			list_ASRtoUpdateAccConLead.addAll(map_AccSurveysToUpdate.values());
			map_DmlInsertUpdateErrorsMap_AccSurveyRes = Utils.doDMLAndReturnAllErrors(
				'Update',
				'Accountant_Lead_Id__c',
				map_AccSurveysToUpdate.values(),
				false,
				true,
				'ZPAccountantSurveyResponseTriggerHelper-processInformation'
			);
		}

		if (list_ASRtoUpdateAccConLead.size() > 0) {
			for (Accountant_Survey_Response__c objASR : list_ASRtoUpdateAccConLead) {
				if (objASR.Account__c != null && String.isNotBlank(objASR.Accounting_Firm_Id__c)) {
					map_AccountFirmIdWithOnbrdIntent.put(objASR.Accounting_Firm_Id__c, objASR);
				}
				if (objASR.Contact__c != null) {
					map_ConRespEmailWithOnbrdIntent.put(objASR.Respondent_Email__c, objASR.Onboarding_Intent__c);
				}
				if (objASR.Lead__c != null) {
					map_LeadRespEmailWithOnbrdIntent.put(objASR.Accountant_Lead_Id__c, objASR.Onboarding_Intent__c);
				}
			}
		}

		if (map_LeadRespEmailWithOnbrdIntent.size() > 0)
			map_Leads = getLead(map_LeadRespEmailWithOnbrdIntent.keySet());

		if (map_AccountFirmIdWithOnbrdIntent.size() > 0) {
			map_Accounts = getAccount(map_AccountFirmIdWithOnbrdIntent.keySet());
		}

		if (map_Accounts.size() > 0) {
			for (Account objAcc : map_Accounts.values()) {
				set_Accids.add(objAcc.Id);
			}
		}

		//Query to lead to check if account is converted from Lead
		if (set_Accids.size() > 0) {
			for (Lead objLead : [SELECT Id, IsConverted, Converted_Account__c FROM Lead WHERE Converted_Account__c = :set_Accids AND IsConverted = TRUE]) {
				map_convertedLead.put(objLead.Converted_Account__c, objLead);
			}
		}

		if (map_Accounts.size() > 0) {
			for (Account objAcc : map_Accounts.values()) {
				Boolean blnUpdateAcc = false;
				objAcc.ASR_Number_Of_Accountants__c = map_AccountFirmIdWithOnbrdIntent.get(objAcc.ZP_Firm_ID__c).Number_of_Accountants_in_Firm__c;
				if (String.isBlank(objAcc.Onboarding_Flow__c)) {
					objAcc.Onboarding_Flow__c = AccountUtil.ONBOARDING_FLOW_IN_APP;
					blnUpdateAcc = true;
				}
				if (map_convertedLead.size() > 0 && map_convertedLead.containsKey(objAcc.Id)) {
					objAcc.Self_Onboarded_SAL__c = true;
					if (map_AccountFirmIdWithOnbrdIntent.containsKey(objAcc.ZP_Firm_ID__c)) {
						objAcc.Onboarding_Intent__c = map_AccountFirmIdWithOnbrdIntent.get(objAcc.ZP_Firm_ID__c).Onboarding_Intent__c;
					}
					blnUpdateAcc = true;
					for (Contact objCon : objAcc.Contacts) {
						objCon.Self_Onboarded_SAL__c = true;
						if (map_ConRespEmailWithOnbrdIntent.size() > 0 && map_ConRespEmailWithOnbrdIntent.containsKey(objCon.Email)) {
							objCon.Onboarding_Intent__c = map_ConRespEmailWithOnbrdIntent.get(objCon.Email);
						}
						list_ContactToUpdateOnbordSAL.add(objCon);
					}
				}
				if (blnUpdateAcc) {
					list_AccountToUpdateOnboardSAL.add(objAcc);
				}
			}
		}

		if (map_Leads.size() > 0) {
			for (Lead objLead : map_Leads.values()) {
				if (map_LeadRespEmailWithOnbrdIntent.containsKey(objLead.ZP_Accountant_Lead_ID__c)) {
					objLead.Onboarding_Intent__c = map_LeadRespEmailWithOnbrdIntent.get(objLead.ZP_Accountant_Lead_ID__c);
					list_leadToUpdate.add(objLead);
				}
			}
		}

		if (list_AccountToUpdateOnboardSAL.size() > 0) {
			AccountTriggerHelper.skipTrigger = true;
			update list_AccountToUpdateOnboardSAL;
			AccountTriggerHelper.skipTrigger = false;
		}
		if (list_ContactToUpdateOnbordSAL.size() > 0) {
			ContactTriggerHelper.skipTrigger = true;
			update list_ContactToUpdateOnbordSAL;
			ContactTriggerHelper.skipTrigger = false;
		}
		if (list_leadToUpdate.size() > 0) {
			LeadTriggerHelper.skipTrigger = true;
			update list_leadToUpdate;
			LeadTriggerHelper.skipTrigger = false;
		}

		// Handle the dml errors via addError
		for (ZP_Accountant_Survey_Response__c objZPAccountantSurvey : list_ZPAccSurveyResponses) {
			if (map_DmlInsertUpdateErrorsMap_AccSurveyRes.keySet().size() > 0 && map_DmlInsertUpdateErrorsMap_AccSurveyRes.containsKey(objZPAccountantSurvey.Accountant_Lead_Id__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, map_DmlInsertUpdateErrorsMap_AccSurveyRes.get(objZPAccountantSurvey.Accountant_Lead_Id__c), objZPAccountantSurvey);
			} else if (objZPAccountantSurvey.processing_state__c == IntegrationUtils.QUEUED_STATE)
				setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Successfully Processed', objZPAccountantSurvey);
		}
	}

	private ZP_Accountant_Survey_Response__c setProcessingState(String state, String message, ZP_Accountant_Survey_Response__c objZPAccountantSurvey) {
		objZPAccountantSurvey.Processing_State__c = state;
		objZPAccountantSurvey.Message__c = message;
		return objZPAccountantSurvey;
	}

	private Accountant_Survey_Response__c mapAccountantSurveyFields(
		ZP_Accountant_Survey_Response__c objZPAccSurvey,
		Accountant_Survey_Response__c objAccSurvey,
		Account objAccount,
		Contact objContact,
		Lead objLead
	) {
		Accountant_Survey_Response__c objAccSurveyResponse;

		if (objAccSurvey == null) {
			//insert
			objAccSurveyResponse = new Accountant_Survey_Response__c();
		} else {
			//update
			objAccSurveyResponse = objAccSurvey;
		}

		objAccSurveyResponse.Accounting_Firm_Id__c = ObjZPAccSurvey.Accounting_Firm_Id__c;
		objAccSurveyResponse.Firm_Primary_Location_Zip_Code__c = ObjZPAccSurvey.Firm_Primary_Location_Zip_Code__c;
		objAccSurveyResponse.Id__c = ObjZPAccSurvey.Id__c;
		objAccSurveyResponse.Involvement_in_Client_Payroll__c = ObjZPAccSurvey.Involvement_in_Client_Payroll__c;
		objAccSurveyResponse.Number_of_Accountants_in_Firm__c = ObjZPAccSurvey.Number_of_Accountants_in_Firm__c;
		objAccSurveyResponse.Other_Payroll_Providers_Used__c = ObjZPAccSurvey.Other_Payroll_Providers_Used__c;
		objAccSurveyResponse.Role_at_Firm__c = ObjZPAccSurvey.Role_at_Firm__c;
		objAccSurveyResponse.Services_Offered__c = ObjZPAccSurvey.Services_Offered__c;
		objAccSurveyResponse.Will_Run_First_Client_Payroll_Timeline__c = ObjZPAccSurvey.Will_Run_First_Client_Payroll_Timeline__c;
		objAccSurveyResponse.Respondent_Email__c = ObjZPAccSurvey.Respondent_Email__c;
		objAccSurveyResponse.Onboarding_Intent__c = ObjZPAccSurvey.Onboarding_Intent_new__c;
		objAccSurveyResponse.Accountant_Lead_Id__c = ObjZPAccSurvey.Accountant_Lead_Id__c;
		if (objAccount != null) {
			objAccSurveyResponse.Account__c = objAccount.Id;
		}

		if (objContact != null)
			objAccSurveyResponse.Contact__c = objContact.Id;
		//Yuvraj : 03-09-2020
		if (objLead != null)
			objAccSurveyResponse.Lead__c = objLead.Id;

		return objAccSurveyResponse;
	}

	//get Accounts based on Accountant Firm Id
	private Map<String, Account> getAccount(Set<String> set_ZPAccountantFirmId) {
		Map<String, Account> map_result = new Map<String, Account>();
		//BY:Prashant :12-08-2020 : To update Account & Contacts 'Self_Onboarded_SAL__c' field( included Self_Onboarded_SAL__c & contact query )
		for (Account acc : [
			SELECT Id, Onboarding_Intent__c, ZP_Firm_ID__c, Name, Self_Onboarded_SAL__c, Onboarding_Flow__c, (SELECT Id, Onboarding_Intent__c, Email, Self_Onboarded_SAL__c FROM Contacts)
			FROM Account
			WHERE ZP_Firm_ID__c = :set_ZPAccountantFirmId AND RecordtypeId = :AccountUtil.RESELLER_ACCOUNT_RT_ID
		]) {
			map_result.put(acc.ZP_Firm_ID__c, acc);
		}

		return map_result;
	}

	//By:Prashant :31-08-2020 :https://app.asana.com/0/1175476642052761/1191263069554561
	//updated - get contact by email
	private Map<String, Contact> getContact(Set<String> set_ZPAccountantresponseEmailIds) {
		Map<String, Contact> map_result = new Map<String, Contact>();
		List<Contact> list_contact = [SELECT Id, Onboarding_Intent__c, Email, RecordTypeId FROM Contact WHERE Email = :set_ZPAccountantresponseEmailIds];

		if (list_contact.size() > 0) {
			if (list_contact.size() > 1) {
				for (Contact objCon : list_contact) {
					if (objCon.RecordTypeId == Cache.getRecordTypeId('Contact', 'Reseller')) {
						map_result.put(objCon.Email, objCon);
					}
				}
			} else {
				map_result.put(list_contact[0].Email, list_contact[0]);
			}
		}

		return map_result;
	}

	private Map<String, Lead> getLead(Set<String> set_AccountantLeadIds) {
		Map<String, Lead> map_result = new Map<String, Lead>();

		for (Lead objLead : [SELECT Id, Onboarding_Intent__c, RecordTypeId, Email, ZP_Accountant_Lead_ID__c FROM Lead WHERE ZP_Accountant_Lead_ID__c = :set_AccountantLeadIds]) {
			map_result.put(objLead.ZP_Accountant_Lead_ID__c, objLead);
		}

		return map_result;
	}

	//Get Accountant Survey Response
	//@return : Map(Accountant Lead Id ,AccSurveyResponse)
	private Map<String, Accountant_Survey_Response__c> getAccSurveyResponse(Set<String> set_AccountantLeadIds) {
		Map<String, Accountant_Survey_Response__c> map_result = new Map<String, Accountant_Survey_Response__c>();
		for (Accountant_Survey_Response__c objAccSurvey : [
			SELECT
				Id,
				Contact__c,
				Lead__c,
				Accounting_Firm_Id__c,
				Firm_Primary_Location_Zip_Code__c,
				Id__c,
				Involvement_in_Client_Payroll__c,
				Number_of_Accountants_in_Firm__c,
				Other_Payroll_Providers_Used__c,
				Role_at_Firm__c,
				Services_Offered__c,
				Will_Run_First_Client_Payroll_Timeline__c,
				Account__c,
				Accountant_Lead_Id__c
			FROM Accountant_Survey_Response__c
			WHERE Accountant_Lead_Id__c = :set_AccountantLeadIds
		]) {
			map_result.put(objAccSurvey.Accountant_Lead_Id__c, objAccSurvey);
		}

		return map_result;
	}
}