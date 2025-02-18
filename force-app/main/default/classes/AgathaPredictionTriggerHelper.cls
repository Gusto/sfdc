public with sharing class AgathaPredictionTriggerHelper {
	public static boolean skipTrigger = false;
	private static integer counter = 0;
	public static boolean queue = false;
	public Decimal CONFIDENCE_SCORE = 0.9; //default value
	public Set<String> SET_AGENCIES_TO_IGNORE = new Set<String>();
	public boolean IS_TAX_CASE_ROUTE = true;
	public Integer TAX_RES_ATTACHMENT = 3; //default value
	public static string AGATHAPREDICTION_NOT_PREDICTED = 'not_predicted';
	public static Map<String, String> map_RecordTypeAutoCloseQueues = new Map<String, String>{
		'Payroll Care' => 'Payroll_Care_Auto_Close',
		'Modern Bank' => 'Modern_Bank_Auto_Close',
		'Tax Ops' => 'TaxOps_Auto_Closed_Queue'
	};
	public static Set<String> set_CaseRecordTypes = new Set<String>{
		CaseUtils.RECTYPE_ENGAGEMENT,
		CaseUtils.RECTYPE_PAYROLL_CARE,
		CaseUtils.RECTYPE_BENEFITS_CARE,
		CaseUtils.RECTYPE_TAXRES,
		CaseUtils.RECTYPE_MODERN_BANK,
		CaseUtils.RECTYPE_RISK_ASSURANCE
	};

	public void OnBeforeInsert(List<Agatha_Prediction__c> listPrediction) {
	}

	public void OnAfterInsert(Map<ID, Agatha_Prediction__c> newPredictionMap) {
		try {
			if (Label.PredictionTool == 'Agatha' || test.isRunningTest()) {
				processInformation(newPredictionMap.values());
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('AgathaPredictionTriggerHelper', 'OnAfterInsert', objException.getMessage(), objException.getStackTraceString());
		}
	}

	@future
	public static void OnAfterInsertAsync(Set<ID> IdSet) {
	}

	public void OnBeforeUpdate(Map<ID, Agatha_Prediction__c> oldPredictionMap, Map<ID, Agatha_Prediction__c> newPredictionMap) {
		counter++;
	}

	public void OnAfterUpdate(Map<ID, Agatha_Prediction__c> oldPredictionMap, Map<ID, Agatha_Prediction__c> newPredictionMap) {
	}

	@future
	public static void OnAfterUpdateAsync(Set<ID> updatedIDs) {
	}

	public void OnBeforeDelete(Agatha_Prediction__c[] listPrediction, Map<ID, Agatha_Prediction__c> oldPredictionMap) {
		counter++;
	}

	public void OnAfterDelete(Agatha_Prediction__c[] listPrediction, Map<ID, Agatha_Prediction__c> oldPredictionMap) {
		counter++;
	}

	@future
	public static void OnAfterDeleteAsync(Set<ID> deletedIDs) {
	}

	public void OnUndelete(Agatha_Prediction__c[] listPrediction) {
		counter++;
	}

	public void fetchCustomSetting() {
		List<Configuration_Settings__c> configSettingList = [
			SELECT id, TaxRes_Agencies_to_Ignore__c, TaxRes_Prediction_Score__c, Route_tax_res_cases__c, TaxRes_Attachment__c
			FROM Configuration_Settings__c
		];
		CONFIDENCE_SCORE = 0.9; //default value
		SET_AGENCIES_TO_IGNORE = new Set<String>();
		if (configSettingList.size() > 0) {
			if (String.isNotBlank(configSettingList[0].TaxRes_Prediction_Score__c)) {
				CONFIDENCE_SCORE = Decimal.valueOf(configSettingList[0].TaxRes_Prediction_Score__c);
			}
			if (String.isNotBlank(configSettingList[0].TaxRes_Agencies_to_Ignore__c)) {
				for (String agencyInfo : configSettingList[0].TaxRes_Agencies_to_Ignore__c.split(';')) {
					if (String.isNotBlank(agencyInfo)) {
						agencyInfo = agencyInfo.trim();
						if (agencyInfo.length() > 15) {
							agencyInfo = agencyInfo.subString(0, 15);
						}
						SET_AGENCIES_TO_IGNORE.add(agencyInfo);
					}
				}
			}

			IS_TAX_CASE_ROUTE = configSettingList[0].Route_tax_res_cases__c;

			if (configSettingList[0].TaxRes_Attachment__c != null) {
				TAX_RES_ATTACHMENT = Integer.valueOf(configSettingList[0].TaxRes_Attachment__c);
			}
		}
	}

	/*In the following method we are setting up the Confirm Case Reason, Routing Case Reason, CCR Classification, RCR Classification,
        RecordTypeId, Type, Class, Priority, task us and Send Survey, fields for Case object. Based on Case Reason Code present in
        Agatha Prediction object records.
    */
	private void processInformation(List<Agatha_Prediction__c> listPrediction) {
		fetchCustomSetting();

		Id TaxRes_Informational_Queue = getQueueId('TaxRes_Informational');
		set<id> caseIdSet = new Set<id>();
		set<string> reasonSet = new Set<string>();
		set<string> agencyInfoSet = new Set<string>();
		Boolean blnAutoSendEmail = false;
		Map<String, Group> map_QueuesByName = new Map<String, Group>();

		CaseTriggerHelper.context = 'wiseio';
		for (Agatha_Prediction__c pred : listPrediction) {
			caseIdSet.add(pred.Case__c);
			reasonSet.add(pred.Case_Reason_Code__c);
			agencyInfoSet.add(pred.Agency_Information__c);
		}

		setCaseRecordTypeMap();
		map<id, Case> caseMap = getCaseMap(caseIdSet);
		for (Group objGroup : GlobalQueryHelper.getGroupsByType('queue')) {
			map_QueuesByName.put(objGroup.DeveloperName, objGroup);
		}

		set<id> newCaseIdSet = new Set<id>();
		for (Agatha_Prediction__c pred : listPrediction) {
			Case objCase = caseMap.get(pred.Case__c);
			if (objCase.RecordType.Name != null && objCase.RecordType.Name == 'Tax Res') {
				newCaseIdSet.add(pred.Case__c);
			}
		}
		Map<Id, boolean> map_caseEmailAttachment = new Map<Id, boolean>();
		if (newCaseIdSet.size() > 0) {
			map_caseEmailAttachment = createAttachmentMap(newCaseIdSet);
		}

		map<String, Case_Reason_Classification__c> classificationMap = new Map<String, Case_Reason_Classification__c>();
		if (!reasonSet.isEmpty()) {
			classificationMap = getReasonClassificationMap(reasonSet);
		}
		map<String, Agency_Information__c> agencyInfoMap = getAgencyInformationMap(agencyInfoSet);
		List<Case> caseList = new List<Case>();
		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;
		Database.DMLOptions dmoNoRule = new Database.DMLOptions();
		dmoNoRule.assignmentRuleHeader.useDefaultRule = false;
		String strAgencyInfoId = '';

		for (Agatha_Prediction__c objAgathaPrediction : listPrediction) {
			Boolean blnRoutingReasonPopulated = false;
			Case objCase = caseMap.get(objAgathaPrediction.Case__c);
			String strOwnerId = objCase.OwnerId;
			Boolean blnIsTypePopulated = false;

			if (objCase.RecordTypeId == CaseUtils.RECTYPE_ENGAGEMENT) {
				objCase.Status = CaseUtils.STATUS_IN_PROGRESS;
			}
			if (objAgathaPrediction.Case_Reason_Code__c != null && objAgathaPrediction.Case_Reason_Code__c != '') {
				if (set_CaseRecordTypes.contains(objCase.RecordTypeId)) {
					if (classificationMap.containsKey(objAgathaPrediction.Case_Reason_Code__c.toLowerCase())) {
						Case_Reason_Classification__c objCaseReason = classificationMap.get(objAgathaPrediction.Case_Reason_Code__c.toLowerCase());
						if (objCaseReason.Default_Type__c == CaseUtils.TYPE_ENGAGEMENT) {
							if (objCase.RecordTypeId != CaseUtils.RECTYPE_ENGAGEMENT) {
								objCase.RecordTypeId = CaseUtils.RECTYPE_ENGAGEMENT;
								objCase.OwnerId = CaseUtils.ID_ENGAGEMENT_CASES_QUEUE;
							}
                            
							if (String.isNotBlank(objCaseReason.Specialization__c)) {
								objCase.Specialization__c = objCaseReason.Specialization__c;
							}
							objCase.Type = String.isNotBlank(objCaseReason.Case_Type_Pillar__c)
												?objCaseReason.Case_Type_Pillar__c
												:objAgathaPrediction.Case_Type__c;
							objCase.Support_Level__c = String.isNotBlank(objCaseReason.Support_Level__c)
														?objCaseReason.Support_Level__c
														:objAgathaPrediction.Support_Level__c;
							if (String.isNotBlank(objCaseReason.Case_Type_Pillar__c) && objCaseReason.Case_Type_Pillar__c.equalsIgnoreCase(CaseUtils.TYPE_TADA)) {
								objCase.Type = Caseutils.TYPE_TADA;
							}
							blnIsTypePopulated = true;
						} else {
							objCase.Type = objCaseReason.Default_Type__c;
						}
					} else if (objAgathaPrediction.Case_Reason_Code__c == 'not_predicted' || String.isBlank(objAgathaPrediction.Case_Reason_Code__c)) {
						if (String.isBlank(objAgathaPrediction.Support_Level__c) || objAgathaPrediction.Support_Level__c == AGATHAPREDICTION_NOT_PREDICTED) {
							objCase.Support_Level__c = CaseUtils.TIER_1;
						} else {
							objCase.Support_Level__c = objAgathaPrediction.Support_Level__c;
						}
						if (String.isBlank(objAgathaPrediction.Case_Type__c) || objAgathaPrediction.Case_Type__c == AGATHAPREDICTION_NOT_PREDICTED) {
							objCase.Type = CaseUtils.PAYROLL_CASE_PILLAR;
						} else {
							objCase.Type = objAgathaPrediction.Case_Type__c;
						}
						objCase.Specialization__c = String.isNotBlank(objAgathaPrediction.Specialization__c) ? objAgathaPrediction.Specialization__c : null;
						blnIsTypePopulated = true;
					}
				}

				if (objCase.Answer_IQ_Eligible__c == false) {
					continue;
				}
				if (objCase.Answer_IQ_Processed__c != null && objCase.Answer_IQ_Processed__c != '' && objCase.Answer_IQ_Eligible__c == true) {
					continue;
				}
				strOwnerId = objCase.OwnerId;
				//If cases are in Ignore Agatha Case Queues, don't insert routing case reason
				List<String> list_QueuesToIgnore = new List<String>();

				if (String.isBlank(objCase.Routing_Case_Reason__c) && classificationMap.containsKey(objAgathaPrediction.Case_Reason_Code__c.toLowerCase())) {
					Case_Reason_Classification__c classification = classificationMap.get(objAgathaPrediction.Case_Reason_Code__c.toLowerCase());
					objCase.Routing_Case_Reason__c = classification.Name;
					objCase.Routing_Case_Reason_Classification__c = classification.Id;

					if (!classification.Generic_Routing_Reason__c) {
						objCase.Confirm_Case_Reason__c = classification.Name;
						objCase.Confirm_Case_Reason_Classification__c = classification.Id;
						objCase.Routing_Team__c = classification.Routing_Team__c;
					}
					// this if part should not run if agatha prediction type value is not Null.
					if (classification.Type__c != null && objCase.RecordType.Name.indexOf('Risk Assurance') < 0) {
						Id recTypeId = recordTypeNameIdMap.get(classification.Type__c);
						if (recTypeId != null && String.valueof(recTypeId).length() > 0 && !blnIsTypePopulated) {
							objCase.RecordTypeId = recTypeId;
							if (objCase.Type != 'Cobra') {
								objCase.Type = classification.Type__c;
							}
							// SJay - 07/08/2020 - set tax res ob message to true if Record Type = tax res
							if (recordTypeNameIdMap.containsKey('Tax Res') && classification.Type__c == 'Tax Res' && objCase.TaxRes_OBMsg_Trigger__c == false) {
								objCase.TaxRes_OBMsg_Trigger__c = true;
							}
						}
					}

					objCase.Class__c = classification.Class__c;
					objCase.Priority = classification.Priority__c;
					objCase.Task_Us__c = classification.Task_Us__c;
					objCase.Send_Survey__c = classification.Survey_Eligible__c;
					if (objAgathaPrediction.Confidence__c != null) {
						objCase.Agatha_Confidence__c = 100 * objAgathaPrediction.Confidence__c;
					}

					if (objCase.Class__c == 'Class 0') {
						String strEmailDomain = '';
						if (String.isNotBlank(objCase.SuppliedEmail)) {
							List<String> list_EmailSplits = objCase.SuppliedEmail.split('@');
							if (!list_EmailSplits.isEmpty() && list_EmailSplits.size() > 1) {
								strEmailDomain = list_EmailSplits[1];
							}
						}

						if (Label.Inbound_Email_Exception_Domains.indexOf(strEmailDomain) == -1) {
							String strQueueName = map_RecordTypeAutoCloseQueues.get(objCase.RecordType.Name);
							if (String.isNotBlank(strQueueName) && map_QueuesByName.containsKey(strQueueName)) {
								objCase.OwnerId = map_QueuesByName.get(strQueueName).Id;
							}
						}
					}

					/**
					 * Author: Alex
					 * Date: 12/3/2020
					 * Desc: Copy text from case reason to case.
					 * If case reason auto email behavior is "Send," and meets threshold do not do DML options
					 */
					CaseTriggerHelper.prepareCaseReasonAutoEmail(classification, objCase, null, true);
					if (classification.Confidence_Threshold__c <= objAgathaPrediction.Confidence__c && objCase.Last_out_bound_email__c == null) {
						if (classification.Auto_Email_Behavior__c == 'Send') {
							blnAutoSendEmail = true;
							if (objCase.BusinessHoursId != null) {
								Integer intDays = Integer.valueOf(Label.EngagementAutoCloseDays);
								objCase.Auto_Close_Date_Time__c = BusinessHours.add(objCase.BusinessHoursId, System.Now(), 1000 * 60 * 60 * 9 * intDays);
							}
						}
					}

					blnRoutingReasonPopulated = true;
				}
				objCase.Answer_IQ_Processed__c = 'Yes';
				objCase.setOptions(dmoNoRule);
				/* (If owner is a group OR owner is an integration user) AND Auto Send Email is false
				AND blnRoutingReasonPopulated is true, use DML Options */
				if (
					(strOwnerId.indexOf('00G') == 0 ||
					objCase.Case_Owner_Role__c == 'Integration Users') &&
					!blnAutoSendEmail &&
					blnRoutingReasonPopulated &&
					objCase.Class__c != 'Class 0' &&
					!blnIsTypePopulated
				) {
					objCase.setOptions(dmo);
				} else {
					objCase.setOptions(dmoNoRule);
				}
			} else if (objCase.RecordType.Name != null && objCase.RecordType.Name == 'Tax Res' && String.isBlank(objCase.Agency_Info_Agatha__c)) {
				//If "Case Reason code" is does not exist then this block of code executed.
				if (objAgathaPrediction.Agency_Information__c != null) {
					objCase.Agency_Info_Agatha__c = objAgathaPrediction.Agency_Information__c;
				}

				if (objAgathaPrediction.Root_Cause__c != null) {
					objCase.Root_Cause_Agatha__c = objAgathaPrediction.Root_Cause__c;
				}

				strAgencyInfoId = objAgathaPrediction.Agency_Information__c;
				if (String.isNotBlank(strAgencyInfoId) && strAgencyInfoId.length() > 15) {
					strAgencyInfoId = strAgencyInfoId.subString(0, 15);
				}
				if (agencyInfoMap.containsKey(strAgencyInfoId)) {
					objCase.Agency_Information__c = agencyInfoMap.get(strAgencyInfoId).Id;
					if (agencyInfoMap.get(strAgencyInfoId).OCR_Enabled__c && !objCase.Is_OCR_Processed__c) {
						objCase.Status = CaseUtils.CASE_STATUS_READY_FOR_OCR_CAPTURE;
					}
				}

				//If the prediction root cause is 'Informational', update Agency information based on prediction and Root cause as 'Informational'. We also need to assign the case to 'TaxRes Informational' Queue.
				if (objAgathaPrediction.Root_Cause__c == 'Informational') {
					//If case record type is 'Tax Res' in that case, we case assign case.Root_Cause__c field value.
					objCase.Customer_Journey__c = 'Accounts Update';
					objCase.Root_Cause__c = 'Informational';
				}
			}
			caseList.add(objCase);
		}
		CaseTriggerHelper.fromAgatha = true;
		update caseList;
		CaseTriggerHelper.fromAgatha = false;
	}

	private map<String, Agency_Information__c> getAgencyInformationMap(Set<String> agencyInfoSet) {
		map<String, Agency_Information__c> agencyMap = new Map<String, Agency_Information__c>();
		String key = '';
		for (Agency_Information__c agencyObj : [SELECT Id, Name, Routing_Queue__c, OCR_Enabled__c FROM Agency_Information__c WHERE Id IN :agencyInfoSet AND Routing_Queue__c != NULL]) {
			key = agencyObj.Id + '';
			if (String.isNotBlank(key) && key.length() > 15) {
				key = key.subString(0, 15);
			}
			agencyMap.put(key, agencyObj);
		}

		return agencyMap;
	}

	private map<String, Case_Reason_Classification__c> getReasonClassificationMap(Set<String> reasonSet) {
		map<String, Case_Reason_Classification__c> reasonIdMap = new Map<String, Case_Reason_Classification__c>();
		for (Case_Reason_Classification__c classification : [
			SELECT
				Id,
				Reason_Code__c,
				Name,
				Type__c,
				Class__c,
				Priority__c,
				Task_Us__c,
				Survey_Eligible__c,
				Auto_Email_Behavior__c,
				Email_Content__c,
				Do_Not_Auto_Solve_for_Auto_Email__c,
				Confidence_Threshold__c,
				Email_Signature__c,
				Override_Email_Signature__c,
				Generic_Routing_Reason__c,
				Default_Type__c,
				Case_Type_Pillar__c,
				Routing_Team__c,
				Support_Level__c,
				Specialization__c
			FROM Case_Reason_Classification__c
			WHERE Reason_Code__c IN :reasonSet
		]) {
			if (String.isNotBlank(classification.Reason_Code__c)) {
				reasonIdMap.put(classification.Reason_Code__c.toLowerCase(), classification);
			}
		}

		return reasonidMap;
	}

	public map<Id, Case> getCaseMap(Set<id> caseIdSet) {
		return new Map<Id, Case>(
			[
				SELECT
					Id,
					Status,
					Is_OCR_Processed__c,
					OwnerId,
					BusinessHoursId,
					Routing_Case_Reason__c,
					Routing_Group__c,
					Confirm_Case_Reason__c,
					Answer_IQ_Processed__c,
					Answer_IQ_Eligible__c,
					RecordTypeId,
					RecordType.Name,
					RecordType.DeveloperName,
					Class__c,
					Priority,
					Task_Us__c,
					Send_Survey__c,
					Type,
					Support_Level__c,
					Specialization__c,
					Agency_Info_Agatha__c,
					Root_Cause_Agatha__c,
					Agency_Information__c,
					Root_Cause__c,
					Customer_Journey__c,
					TaxRes_OBMsg_Trigger__c,
					Last_out_bound_email__c,
					Auto_Email_Behavior__c,
					Auto_Response_Email_Sent__c,
					Origin,
					Owner.Name,
					Case_Owner_Role__c,
					Auto_Response_Email_Content__c,
					SuppliedEmail,
					Routing_Team__c,
					Has_A_Valid_Recommendation__c 
				FROM Case
				WHERE Id IN :caseidSet
			]
		);
	}

	public Id getQueueId(String queueName) {
		List<Group> lst_queue = [SELECT id, Name, Type, DeveloperName FROM Group WHERE DeveloperName = :queueName AND Type = 'Queue'];
		if (lst_queue.size() > 0) {
			return lst_queue[0].Id;
		} else {
			return null;
		}
	}

	map<String, String> recordTypeNameIdMap = new Map<String, String>();
	public void setCaseRecordTypeMap() {
		recordTypeNameIdMap = new Map<String, String>();
		// recordTypeIdNameMap = new map<String,String>();

		for (RecordType recType : [SELECT Id, Name, DeveloperName, SObjectType FROM RecordType WHERE SobjectType = 'Case']) {
			recordTypeNameIdMap.put(recType.Name, recType.id);
			// recordTypeIdNameMap.put(recType.id,recType.Name);
		}
	}

	public Map<Id, boolean> createAttachmentMap(Set<Id> set_caseId) {
		Map<Id, boolean> map_caseEmailAttachment = new Map<Id, boolean>();
		Map<Id, Integer> map_caseAttachmentCount = new Map<Id, Integer>();
		Map<Id, Id> map_caseAndEmailId = new Map<Id, Id>();
		List<EmailMessage> lst_email = [SELECT Id, RelatedToId, Incoming FROM EmailMessage WHERE RelatedToId IN :set_caseId AND Incoming = TRUE];
		if (lst_email.size() > 0) {
			//If inbound email message exist.
			for (EmailMessage emailObj : lst_email) {
				map_caseEmailAttachment.put(emailObj.RelatedToId, false);
				map_caseAndEmailId.put(emailObj.Id, emailObj.RelatedToId);
			}

			List<AggregateResult> attachmentList = [SELECT ParentId, count(Id) TotalAttachment FROM Attachment WHERE ParentId IN :map_caseAndEmailId.keyset() GROUP BY ParentId];
			for (AggregateResult attachmentObj : attachmentList) {
				if (map_caseAndEmailId.containsKey(attachmentObj.get('ParentId') + '')) {
					Id key = map_caseAndEmailId.get(attachmentObj.get('ParentId') + '');
					if (key != null) {
						Integer attachmentCount = Integer.valueOf(attachmentObj.get('TotalAttachment') + '');
						if (attachmentCount > 0) {
							if (map_caseAttachmentCount.containsKey(key)) {
								attachmentCount = map_caseAttachmentCount.get(key) + attachmentCount;
							}
							map_caseAttachmentCount.put(key, attachmentCount);
						}
					}
				}
			}

			for (Id caseId : map_caseAttachmentCount.keySet()) {
				if (map_caseAttachmentCount.get(caseId) <= TAX_RES_ATTACHMENT) {
					map_caseEmailAttachment.put(caseId, true);
				} else if (map_caseAttachmentCount.get(caseId) > TAX_RES_ATTACHMENT) {
					map_caseEmailAttachment.put(caseId, false);
				}
			}
		}
		return map_caseEmailAttachment;
	}
}