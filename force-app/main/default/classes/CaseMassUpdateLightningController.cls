/***
 * @name         : CaseMassUpdateLightningController
 * @author       : Alex Xiong
 * @date         : 03-03-2021
 * @description  : Apex controller for caseMassUpdateAuraComponent.
 * @test classes : CaseMassUpdateLightningControllerTest
 ***/
global with sharing class CaseMassUpdateLightningController {
	private ApexPages.StandardSetController setController;
	static final String TAX_RES_ACCOUNT_SPECIALIST = 'Account Specialist';
	static final String INVALID_TAXRES_USER_ERROR_MSG = 'Selected owner is not a valid Tax Resolution user, based on the owner type selected.';
	static final String USER_DETAILS_ERROR_MSG = 'Please provide all the detials to update case.';
	static final String ROUND_ROBIN = 'round_robin';
	static final String IC_ASSIGNMENT = 'ic_assignment';
	static final Decimal ROUND_ROBIN_RECORD_LIMIT = Configuration_Settings__c.getOrgDefaults().TaxRes_Round_Robin_Case_DML_Limit__c;
	public static final String FROM_MASSUPDATE = 'MassUpdate';
	public static final String MF_COMPLETED = 'MF_Completed';
	public static final Id idMFCompletedQueue = GlobalQueryHelper.getGroupsByName(MF_COMPLETED).get(0).Id;
	public String getCaseRecordList { get; set; }

	public class CaseMassUpdateAuraResponse {
		@AuraEnabled
		public Boolean isSuccess;

		@AuraEnabled
		public Boolean isEligible;

		@AuraEnabled
		public String errorMessage;

		@AuraEnabled
		public String selectedRecordType;

		@AuraEnabled
		public List<String> caseRecordTypeList;

		public CaseMassUpdateAuraResponse(Boolean isSuccess, Boolean isEligible, String errorMessage) {
			this.isSuccess = isSuccess;
			this.isEligible = isEligible;
			this.errorMessage = errorMessage;
		}

		public CaseMassUpdateAuraResponse() {
		}

		public CaseMassUpdateAuraResponse(Boolean isSuccess, String errorMessage) {
			this.isSuccess = isSuccess;
			this.errorMessage = errorMessage;
		}
	}

	public class CaseFieldSetWrapper {
		@AuraEnabled
		public String fieldApiName;

		@AuraEnabled
		public String fieldLabel;

		@AuraEnabled
		public Boolean isFieldRequired;

		@AuraEnabled
		public String fieldType;

		@AuraEnabled
		public Boolean isFieldComboBox;

		public CaseFieldSetWrapper(String fieldApiName, String fieldLabel, Boolean isFieldRequired, String fieldType, Boolean isFieldComboBox) {
			this.fieldApiName = fieldApiName;
			this.fieldLabel = fieldLabel;
			this.isFieldRequired = isFieldRequired;
			this.fieldType = fieldType;
			this.isFieldComboBox = isFieldComboBox;
		}
	}

	public class CaseFieldSetResponse {
		@AuraEnabled
		public List<CaseFieldSetWrapper> fieldSetWrapper;

		@AuraEnabled
		public List<String> caseReasons;

		@AuraEnabled
		public List<String> lsiList;

		@AuraEnabled
		public Id recordTypeId;

		@AuraEnabled
		public Boolean isOwnerIdAvailable;

		public CaseFieldSetResponse(List<CaseFieldSetWrapper> fieldSetWrapper, List<String> caseReasons, List<String> lsiList, Id recordTypeId, Boolean isOwnerIdAvailable) {
			this.fieldSetWrapper = fieldSetWrapper;
			this.caseReasons = caseReasons;
			this.lsiList = lsiList;
			this.recordTypeId = recordTypeId;
			this.isOwnerIdAvailable = isOwnerIdAvailable;
		}
	}

	public CaseMassUpdateLightningController(ApexPages.StandardSetController controller) {
		this.setController = controller;
		List<Case> caseRecordsList = (List<Case>) this.setController.getSelected();
		getCaseRecordList = JSON.serialize(caseRecordsList);
	}

	@AuraEnabled
	public static List<Case> fetchRelatedCases(List<String> caseIdList) {
		return [SELECT Id, RecordType.Name, AccountId, Account.Name, ContactId, Contact.Name, OwnerId, Owner.Name, Subject, CaseNumber, Type, Origin FROM Case WHERE Id IN :caseIdList];
	}

	@AuraEnabled
	public static CaseMassUpdateAuraResponse checkMassUpdateEligibility(Id caseId) {
		List<String> caseRecordTypeList = new List<String>();
		try {
			Boolean recordTypeSupported = false;
			CaseMassUpdateAuraResponse response = new CaseMassUpdateAuraResponse();

			Case caseObj = [SELECT Id, RecordTypeId, RecordType.Name FROM Case WHERE Id = :caseId];

			for (Case_RecordType_FieldSet_Setting__c rec : [SELECT id, Name, Field_Set_API_Name__c FROM Case_RecordType_FieldSet_Setting__c]) {
				if (caseObj.RecordType.Name.equalsIgnoreCase(rec.Name)) {
					response = new CaseMassUpdateAuraResponse(true, true, '');
					response.selectedRecordType = caseObj.RecordType.Name;
					recordTypeSupported = true;
				}
				caseRecordTypeList.add(rec.Name);
			}
			response.caseRecordTypeList = caseRecordTypeList;
			if (!recordTypeSupported) {
				response = new CaseMassUpdateAuraResponse(true, false, 'Record Type (' + caseObj.RecordType.Name + ') is not eligible for mass update');
			}

			return response;
		} catch (Exception ex) {
			return new CaseMassUpdateAuraResponse(false, false, 'Error: ' + ex.getMessage());
		}
	}

	@AuraEnabled
	public static CaseFieldSetResponse returnFieldNameAPIList(String selectedRecordType) {
		List<Schema.FieldSetMember> fieldsApiNameList = new List<Schema.FieldSetMember>();
		List<CaseFieldSetWrapper> caseFieldWrapperList = new List<CaseFieldSetWrapper>();
		Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(selectedRecordType).getRecordTypeId();
		Case_RecordType_FieldSet_Setting__c fieldSetCustomSetting = [SELECT Id, Name, Field_Set_API_Name__c FROM Case_RecordType_FieldSet_Setting__c WHERE Name = :selectedRecordType];
		Boolean isOwnerIdAvailable = false;

		fieldsApiNameList.addAll(getFields(fieldSetCustomSetting.Field_Set_API_Name__c, 'Case'));
		for (Schema.FieldSetMember fieldSetMember : fieldsApiNameList) {
			Boolean isFieldComboBox = false;

			String fieldApiName = fieldSetMember.getFieldPath();
			if (fieldApiName.equals('Routing_Case_Reason__c') || fieldApiName.equals('Confirm_Case_Reason__c') || fieldApiName.equals('Large_Scale_Issue__c')) {
				isFieldComboBox = true;
			}

			if (fieldApiName.equals('OwnerId')) {
				isOwnerIdAvailable = true;
			}

			CaseFieldSetWrapper caseField = new CaseFieldSetWrapper(
				fieldSetMember.getFieldPath(),
				fieldSetMember.getLabel(),
				fieldSetMember.getRequired(),
				String.valueOf(fieldSetMember.getType()),
				isFieldComboBox
			);
			caseFieldWrapperList.add(caseField);
		}

		List<String> caseReasonsList = getCaseReasons(selectedRecordType);
		List<String> lsiList = getlsiList();
		return new CaseFieldSetResponse(caseFieldWrapperList, caseReasonsList, lsiList, recordTypeId, isOwnerIdAvailable);
	}

	public static List<Schema.FieldSetMember> getFields(String fieldSetName, String ObjectName) {
		Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
		Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
		Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
		Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
		return fieldSetObj.getFields();
	}

	@AuraEnabled
	public static CaseMassUpdateAuraResponse massUpdateAndRouteCase(
		Case caseToUpdate,
		Boolean isMassUpdateAndRoute,
		List<String> attributeList,
		List<String> caseIdList,
		Boolean blnPostFeed,
		String strChatterText,
		String strOwnerId,
		String strOwnerType,
		String strStatus,
		String strAssignmentType,
		Boolean blnIsMFRecordTypeCase
	) {
		try {
			List<Case> lst_caseToUpdate = new List<Case>();
			List<Case> list_taxResCasesToUpdate = new List<Case>();
			String strSuccessMsgInBatch;

			Map<Id, Case> map_taxResCases = new Map<Id, Case>();
			if (caseToUpdate.RecordTypeId != null && caseToUpdate.RecordTypeId == CaseUtils.RECTYPE_TAXRES && !caseIdList.isEmpty()) {
				List<Case> list_taxResCases = TaxResNoticeIndexDetailsController.reEvaluateSkillPatterns(new List<String>(caseIdList));
				map_taxResCases = new Map<Id, Case>(list_taxResCases);
			}

			//For Other than tax res or if it's Tax Res mass update
			if (String.isBlank(strOwnerType) || strOwnerType != 'Account Specialist') {
				for (String caseId : caseIdList) {
					Case objCase = new Case(Id = caseId);
					for (String attribute : attributeList) {
						if (caseToUpdate.get(attribute) != null) {
							objCase.put(attribute, caseToUpdate.get(attribute));
						}
					}
					if (blnIsMFRecordTypeCase) {
						objCase.Status = (String.isNotBlank(caseToUpdate.Status)) ? caseToUpdate.Status : 'Closed';
						objCase.OwnerId = (String.isNotBlank(caseToUpdate.OwnerId)) ? caseToUpdate.OwnerId : idMFCompletedQueue;
					}

					if (isMassUpdateAndRoute) {
						Database.DMLOptions dmo = new Database.DMLOptions();
						dmo.assignmentRuleHeader.useDefaultRule = true;
						objCase.setOptions(dmo);
					}
					lst_caseToUpdate.add(objCase);
				}
			} else {
				//get selected owner has tax res role or not
				if (
					(String.isBlank(strAssignmentType) ||
					(String.isNotBlank(strAssignmentType) &&
					strAssignmentType == IC_ASSIGNMENT &&
					String.isNotBlank(strOwnerId)) ||
					(String.isNotBlank(strAssignmentType) && strAssignmentType == ROUND_ROBIN)) && String.isNotBlank(strStatus)
				) {
					//Check selected owner has tax res type of user or not
					List<User_Role__c> list_UserRoles = [
						SELECT Id, User_Skill_Team__c, User__c
						FROM User_Role__c
						WHERE User__c = :strOwnerId AND User_Skill_Team__c = :strOwnerType AND User__r.isActive = TRUE
						LIMIT 1
					];

					if (list_UserRoles?.size() > 0 || strAssignmentType == ROUND_ROBIN) {
						if (caseIdList.size() > 0) {
							for (String strCaseId : caseIdList) {
								Case objCase = map_taxResCases.containsKey(strCaseId) ? map_taxResCases.get(strCaseId) : new Case(Id = strCaseId);
								objCase.Status = strStatus;

								// for specialist
								if (String.isNotBlank(strAssignmentType) && strAssignmentType == IC_ASSIGNMENT) {
									objCase.OwnerId = strOwnerId;
									objCase.Account_Specialist__c = strOwnerId;
								} else if (String.isNotBlank(strAssignmentType) && strAssignmentType == ROUND_ROBIN) {
									objCase.Account_Specialist__c = null;
									objCase.Error_Message__c = FROM_MASSUPDATE;
								}

								list_taxResCasesToUpdate.add(objCase);
							}
						}
					} else {
						return new CaseMassUpdateAuraResponse(false, INVALID_TAXRES_USER_ERROR_MSG);
					}
				} else {
					return new CaseMassUpdateAuraResponse(false, USER_DETAILS_ERROR_MSG);
				}
			}

			if (!lst_caseToUpdate.isEmpty() || !list_taxResCasesToUpdate.isEmpty()) {
				if (!lst_caseToUpdate.isEmpty()) {
					update lst_caseToUpdate;
				}

				if (!list_taxResCasesToUpdate.isEmpty()) {
					if (list_taxResCasesToUpdate.size() <= ROUND_ROBIN_RECORD_LIMIT) {
						update list_taxResCasesToUpdate;
					} else if (list_taxResCasesToUpdate.size() > ROUND_ROBIN_RECORD_LIMIT) {
						BatchDML.Operation objUpdate = BatchDML.Operation.UPD;
						ID jobID = System.enqueueJob(new BatchDML(objUpdate, list_taxResCasesToUpdate, false));
						strSuccessMsgInBatch = 'Batched Successfully.';
					}
				}

				if (blnPostFeed) {
					CaseUpdateChatterWrapper objWrap = new CaseUpdateChatterWrapper(caseIdList, strChatterText);
					String strWrapper = JSON.serialize(objWrap);
					postChatterFuture(strWrapper);
				}
			}

			return new CaseMassUpdateAuraResponse(true, strSuccessMsgInBatch);
		} catch (Exception ex) {
			//skip validation rule errors since they come from bad user input
			if (!ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
				ExceptionLogUtil.logException('CaseMassUpdateLightningController', 'massUpdateAndRouteCase', ex.getMessage(), ex.getStackTraceString());
			}
			return new CaseMassUpdateAuraResponse(false, ex.getMessage());
		}
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : Takes JSON serialized list of case ids and a string then makes chatter posts on those cases.
	 * @Parm        : strWrap - JSON serialized CaseUpdateChatterWrapper
	 **/
	@future
	public static void postChatterFuture(String strWrap) {
		try {
			CaseUpdateChatterWrapper objWrap = (CaseUpdateChatterWrapper) JSON.deserialize(strWrap, CaseUpdateChatterWrapper.class);
			List<ConnectApi.BatchInput> list_BatchInputs = new List<ConnectApi.BatchInput>();

			for (Id idCase : objWrap.list_CaseIds) {
				ConnectApi.FeedItemInput objInput = new ConnectApi.FeedItemInput();
				objInput.SubjectId = idCase;

				ConnectApi.MessageBodyInput objBody = new ConnectApi.MessageBodyInput();
				objBody.MessageSegments = new List<ConnectApi.MessageSegmentInput>();

				ConnectApi.TextSegmentInput objTextSegment = new ConnectApi.TextSegmentInput();
				objTextSegment.Text = objWrap.strChatterText;

				objBody.MessageSegments.add(objTextSegment);
				objInput.Body = objBody;

				ConnectApi.BatchInput objBatchInput = new ConnectApi.BatchInput(objInput);
				list_BatchInputs.add(objBatchInput);
			}

			ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), list_BatchInputs);
		} catch (Exception ex) {
			ExceptionLogUtil.logException('CaseMassUpdateLightningController', 'postChatterFuture', ex.getMessage(), ex.getStackTraceString());
		}
	}

	//return routing and confirm case reasons
	public static list<string> getCaseReasons(String selectedRecordType) {
		// Fetch value from Case_Reason_Classification__c
		// Filter based on selected record type name
		list<string> caseReasons = new List<string>();
		caseReasons = new List<String>();
		for (Case_Reason_Classification__c crc : [SELECT Id, Name, Class__c FROM Case_Reason_Classification__c WHERE type__c = :selectedRecordType AND Active__c = TRUE]) {
			caseReasons.add(crc.Name);
		}
		return caseReasons;
	}

	//get lsi option list
	public static list<string> getlsiList() {
		// Populate values from Large_Scale_Issue__c when record type is Tax Res
		list<string> lsiList = new List<string>();
		for (Large_Scale_Issue__c lsi : [SELECT Id, Name FROM Large_Scale_Issue__c]) {
			lsiList.add(lsi.Name);
		}
		return lsiList;
	}

	@AuraEnabled
	public static ListView getListViews(String objName, String listviewName) {
		ListView obj_listview = [SELECT Id, Name FROM ListView WHERE SobjectType = :objName AND Name = :listviewName LIMIT 1];

		// Perform isAccessible() check here
		return obj_listview;
	}

	/**
	 * @name         : CaseUpdateChatterWrapper
	 * @author       : Alex Xiong
	 * @date         : 03-04-2021
	 * @description  : Wrapper class for ConnectAPI to make chatter posts on Cases asynchronously.
	 **/
	public class CaseUpdateChatterWrapper {
		List<Id> list_CaseIds;
		String strChatterText;

		public CaseUpdateChatterWrapper(List<Id> list_CaseIds, String strChatterText) {
			this.list_CaseIds = list_CaseIds;
			this.strChatterText = strChatterText;
		}
	}
}