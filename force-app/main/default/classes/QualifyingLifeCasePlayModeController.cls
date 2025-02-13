public with sharing class QualifyingLifeCasePlayModeController {
	public static final String CONTACT_PLAY_MODE = 'Contact Play Mode';
	public String selectedCaseTypeStr { get; set; }
	public String selectedCarrierStr { get; set; }
	static String playClass;
	public String selectedBulkSize { get; set; }
	User loggedInUserRec = new User();
	public String caseIdd { get; set; }

	public String selectedQLCaseQueueId { get; set; }
	public String selectedFollowUpCaseQueueId { get; set; }
	public String currentQLCaseId { get; set; }
	public String currentFollowUpCaseIdsStr { get; set; }

	//follows wether queue fields are populated for Logged in user
	public Boolean isQLUserFieldsNull { get; set; }

	String allQueueIdString = ''; //using to store list of 'All Queue' ids string

	public QualifyingLifeCasePlayModeController() {
		List<User> userList = [SELECT Id, Selected_Case_Type_for_Play_Mode__c, Selected_Carrier_Type_for_Play_Mode__c FROM User WHERE Id = :UserInfo.getUserId()];
		if (userList.size() > 0) {
			loggedInUserRec = userList.get(0);
		}
	}

	public List<SelectOption> getCaseTypeSelectList() {
		List<SelectOption> casetypeList = new List<SelectOption>();
		casetypeList.add(new SelectOption('0', 'Select Case Type'));

		if (loggedInUserRec.id != null && loggedInUserRec.Selected_Case_Type_for_Play_Mode__c != null) {
			Set<String> selectedvalSet = new Set<String>();
			selectedvalSet.addAll(loggedInUserRec.Selected_Case_Type_for_Play_Mode__c.split(';'));
			for (Play_Mode_Config__c obj : Play_Mode_Config__c.getAll().values()) {
				if (selectedvalSet.contains(obj.Name)) {
					casetypeList.add(new SelectOption(obj.Name, obj.Name));
				}
			}
		}

		return casetypeList;
	}

	public List<SelectOption> getCarrierDetailSelectList() {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('0', 'Select Carrier Type'));

		if (loggedInUserRec.id != null && loggedInUserRec.Selected_Carrier_Type_for_Play_Mode__c != null) {
			Schema.DescribeFieldResult fieldResult = Carrier__c.Carrier_Play_Mode__c.getDescribe();
			List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

			Set<String> selectedvalSet = new Set<String>();
			selectedvalSet.addAll(loggedInUserRec.Selected_Carrier_Type_for_Play_Mode__c.split(';'));

			for (Schema.PicklistEntry f : ple) {
				if (selectedvalSet.contains(f.getValue())) {
					options.add(new SelectOption(f.getLabel(), f.getValue()));
				}
			}
		}

		return options;
	}

	@remoteAction
	public static String getSortingDetails(String caseTypeStr, String carrierTypeStr) {
		String returnStr;

		if (caseTypeStr != null && carrierTypeStr != null && caseTypeStr != '0') {
			Play_Mode_Config__c configRec = Play_Mode_Config__c.getValues(caseTypeStr);

			String caseSortByStr = configRec.Sorted_by_Field__c;
			if (String.isblank(caseSortByStr)) {
				return returnStr;
			} else {
				if (caseSortByStr != null && caseSortByStr.indexof(';') > -1) {
					caseSortByStr = caseSortByStr.replaceAll(';', ',');
				}
			}

			List<Case> tempCaseList = getQueriedCaseRecords(configRec, carrierTypeStr);

			if (tempCaseList.size() > 0) {
				String firstFilterStr = (caseSortByStr.indexof(',') > -1 ? caseSortByStr.substring(0, caseSortByStr.indexof(',')) : caseSortByStr);
				String fieldVal;
				if (firstFilterStr != null && tempCaseList.get(0).get(firstFilterStr) != null) {
					Map<String, Schema.SObjectField> M = Schema.SObjectType.Case.fields.getMap();
					Schema.SObjectField field = M.get(firstFilterStr.trim());
					Schema.DisplayType FldType = field.getDescribe().getType();

					//datetime tempVar;
					Date tempVar;
					if (FldType == Schema.DisplayType.DATE) {
						Date tempDate = date.valueof(tempCaseList.get(0).get(firstFilterStr));
						tempVar = tempDate;
					} else if (FldType == Schema.DisplayType.DATETIME) {
						tempVar = dateTime.valueof(tempCaseList.get(0).get(firstFilterStr)).date();
					}

					if (FldType == Schema.DisplayType.DATETIME || FldType == Schema.DisplayType.DATE) {
						fieldVal = tempVar.format();
					} else {
						fieldVal = string.valueof(tempCaseList.get(0).get(firstFilterStr));
					}
				}

				returnStr = '<b> Oldest ' + caseSortByStr.replace('__c', ' ').replaceAll('_', ' ').trim() + ' :</b> ' + (fieldVal == null ? '**' : fieldVal);
				returnStr += '</br> <b> Case Count : </b> ' + tempCaseList.size();

				returnStr = returnStr.replace('00:00:00', '');
			}

			if (configRec.Play_Mode_Class__c != null) {
				playClass = configRec.Play_Mode_Class__c;
				returnStr += '!*!' + configRec.Play_Mode_Class__c;
			}
		}

		return returnStr;
	}

	public static List<Case> getQueriedCaseRecords(Play_Mode_Config__c configRec, String carrierType) {
		String queryStr;
		String caseSortByStr;
		List<String> statusExceptionList = new List<String>();
		List<String> caseTypeFilterList = new List<String>();
		List<Id> recordTypeIdList = new List<Id>();
		List<Id> ownerQueueIdList = new List<Id>();

		if (configRec != null && configRec.Id != null) {
			playClass = configRec.Play_Mode_Class__c;

			if (!string.isBlank(configRec.Case_Type__c)) {
				if (configRec.Case_Type__c.indexof(';') > -1) {
					String tempStr = configRec.Case_Type__c.replaceAll('; ', ';').replaceAll(';  ', ';');
					caseTypeFilterList = tempStr.split(';');
				} else {
					caseTypeFilterList.add(configRec.Case_Type__c.trim());
				}
			}

			if (!string.isBlank(configRec.Case_record_Type__c)) {
				if (configRec.Case_record_Type__c.indexof(';') > -1) {
					String tempStr = configRec.Case_record_Type__c.replaceAll('; ', ';').replaceAll(';  ', ';');
					for (String recTypeName : tempStr.split(';')) {
						recordTypeIdList.add(Cache.getRecordTypeId('Case', recTypeName.trim()));
					}
				} else {
					recordTypeIdList.add(Cache.getRecordTypeId('Case', configRec.Case_record_Type__c.trim()));
				}
			}

			if (!String.isBlank(configRec.Owner_Queue__c)) {
				List<String> queueNameList = new List<String>();
				if (configRec.Owner_Queue__c.indexof(';') > -1) {
					String tempStr = configRec.Owner_Queue__c.replaceAll('; ', ';').replaceAll(';  ', ';');
					queueNameList = tempStr.split(';');
				} else {
					queueNameList.add(configRec.Owner_Queue__c.trim());
				}

				if (queueNameList.size() > 0) {
					for (Group qRec : [SELECT Type, Name, Id FROM Group WHERE type = 'Queue' AND Name IN :queueNameList]) {
						ownerQueueIdList.add(qRec.Id);
					}
				}
			}

			caseSortByStr = configRec.Sorted_by_Field__c;
			if (!String.isblank(caseSortByStr)) {
				if (caseSortByStr != null && caseSortByStr.indexof(';') > -1) {
					caseSortByStr = caseSortByStr.replaceAll(';', ',');
				}
			}

			if (!String.isblank(configRec.Status_Exceptions__c)) {
				if (configRec.Status_Exceptions__c.indexof(';') > -1) {
					statusExceptionList = configRec.Status_Exceptions__c.trim().split(';');
				} else {
					statusExceptionList.add(configRec.Status_Exceptions__c.trim());
				}
			}

			queryStr = 'SELECT Id, ContactId, OwnerId, RecordTypeId,Status, Type ' + (caseSortByStr.length() > 0 ? ',' + caseSortByStr : ' ') + ' FROM Case WHERE ';

			boolean useAnd = false;
			if (caseTypeFilterList.size() > 0) {
				queryStr += ' Type IN: caseTypeFilterList ';
				useAnd = true;
			}

			if (recordTypeIdList.size() > 0) {
				if (useAnd) {
					queryStr += ' and ';
				} else {
					useAnd = true;
				}
				queryStr += ' RecordTypeId IN: recordTypeIdList ';
			}

			if (recordTypeIdList.size() > 0) {
				if (useAnd) {
					queryStr += ' and ';
				} else {
					useAnd = true;
				}
				queryStr += ' OwnerId IN: ownerQueueIdList ';
			}

			if (carrierType != null && carrierType != '0' && playClass != null && playClass != CONTACT_PLAY_MODE) {
				if (useAnd) {
					queryStr += ' and ';
				} else {
					useAnd = true;
				}
				queryStr += ' Carrier__r.Carrier_Play_Mode__c =: carrierType ';
			}

			if (statusExceptionList.size() > 0) {
				if (useAnd) {
					queryStr += ' and ';
				} else {
					useAnd = true;
				}

				queryStr += ' Status NOT IN: statusExceptionList ';
			}

			if (!string.isBlank(caseSortByStr)) {
				if (caseSortByStr.indexof(',') > -1) {
					for (string sortStr : caseSortByStr.split(',')) {
						if (useAnd) {
							queryStr += ' and ' + sortStr + ' != null ';
						} else {
							queryStr += '  ' + sortStr + ' != null ';
							useAnd = true;
						}
					}
				} else {
					if (useAnd) {
						queryStr += ' and ' + caseSortByStr + ' != null ';
					} else {
						queryStr += '  ' + caseSortByStr + ' != null ';
						useAnd = true;
					}
				}

				queryStr += ' Order by ' + caseSortByStr + ' ASC ';
			}

			if (queryStr.length() > 0) {
				return database.query(queryStr);
			}
		}

		return new List<case>();
	}

	@remoteAction
	public static List<String> executePlay(String caseTypeStr, String carrierTypeStr, String bulksize) {
		if (caseTypeStr == '0') {
			apexPages.addMessage(new apexPages.Message(apexPages.severity.error, 'Please select case type.'));
			return null;
		}

		if (caseTypeStr != null && caseTypeStr != '0' && (carrierTypeStr != null || caseTypeStr == 'QSEHRA')) {
			Play_Mode_Config__c configRec = Play_Mode_Config__c.getValues(caseTypeStr);

			if (configRec.Play_Mode_Class__c == 'Select Number of Cases Play Mode' && bulksize != null) {
				List<Case> tempCaseList = getQueriedCaseRecords(configRec, carrierTypeStr);
				if (tempCaseList != null && tempCaseList.size() > 0) {
					return getListOfRecordToPlay(tempCaseList, configRec.Play_Mode_Class__c, bulksize, caseTypeStr);
				}
			} else if (configRec.Play_Mode_Class__c == CONTACT_PLAY_MODE) {
				List<Case> tempCaseList = getQueriedCaseRecords(configRec, carrierTypeStr);
				if (tempCaseList != null && tempCaseList.size() > 0) {
					return getListOfRecordToPlay(tempCaseList, configRec.Play_Mode_Class__c, '', '');
				}
			} else {
				List<Case> tempCaseList = getQueriedCaseRecords(configRec, carrierTypeStr);
				if (tempCaseList != null && tempCaseList.size() > 0) {
					List<String> finalCaseIds = getListOfRecordToPlay(tempCaseList, configRec.Play_Mode_Class__c, '', caseTypeStr);
					saveUserPrefrence(configRec, carrierTypeStr);
					return finalCaseIds;
				}
			}
		}

		return null;
	}

	public static List<String> getListOfRecordToPlay(List<Case> queriedCases, String playMode, String bulkSize, String caseTypeStr) {
		List<String> finalCaseIds = new List<String>();
		List<Case> processedRecords = new List<Case>();
		Boolean noMoreRec = false;
		Set<Id> set_ContactId = new Set<Id>();
		Set<Id> set_OwnerId = new Set<Id>();
		Set<Id> set_RecordTypeId = new Set<Id>();
		Set<String> set_type = new Set<String>();

		if (queriedCases != null && queriedCases.size() > 0) {
			for (Integer tCount = 0; tCount < 5; tCount++) {
				Boolean assignmentSuccessFull = false;

				if (playMode == 'Select Number of Cases Play Mode' && bulkSize != null) {
					if (processedRecords.size() > 0) {
						Set<Case> tempCaseSet = new Set<Case>();
						tempCaseSet.addAll(queriedCases);
						tempCaseSet.removeAll(processedRecords);
						queriedCases = new List<Case>();
						queriedCases.addAll(tempCaseSet);
					}

					for (Integer i = 0; i < integer.valueOf(bulksize); i++) {
						if (i == queriedCases.size()) {
							noMoreRec = true;
							break;
						}
						finalCaseIds.add(queriedCases.get(i).id);
						processedRecords.add(queriedCases.get(i));
					}
				} else if (playMode == CONTACT_PLAY_MODE) {
					if (queriedCases.size() > tCount) {
						processedRecords.add(queriedCases.get(tCount));
						set_ContactId.add(queriedCases.get(tCount).ContactId);
						set_OwnerId.add(queriedCases.get(tCount).OwnerId);
						set_RecordTypeId.add(queriedCases.get(tCount).RecordTypeId);
						set_type.add(queriedCases.get(tCount).Type);
						break;
					} else {
						noMoreRec = true;
					}
				} else {
					if (queriedCases.size() > tCount) {
						finalCaseIds.add(queriedCases.get(tCount).id);
						processedRecords.add(queriedCases.get(tCount));
					} else {
						noMoreRec = true;
					}
				}

				if (assignmentSuccessFull == true || noMoreRec == true) {
					break;
				}
			}
			if (playMode == CONTACT_PLAY_MODE) {
				finalCaseIds.addAll(findRelatedCases(set_ContactId, set_OwnerId, set_RecordTypeId, set_type));
			}
			if (finalCaseIds.size() > 0) {
				Boolean assignmentSuccessFull = assignCasesToUser(finalCaseIds, caseTypeStr);
			}
		}
		return finalCaseIds;
	}

	public static List<Id> findRelatedCases(Set<Id> set_ContactId, Set<Id> set_OwnerId, Set<Id> set_RecordTypeId, Set<String> set_type) {
		List<String> list_CaseIds = new List<String>();
		for (case caseRecord : [SELECT Id FROM Case WHERE ContactId IN :set_ContactId AND OwnerId IN :set_OwnerId AND RecordTypeId IN :set_RecordTypeId AND Type IN :set_type WITH USER_MODE]) {
			list_CaseIds.add(caseRecord.id);
		}
		return list_CaseIds;
	}

	public static Boolean assignCasesToUser(List<String> caseIdList, String caseTypeStr) {
		List<Case> caselistToUpdate = new List<Case>();
		if (caseIdList != null && caseIdList.size() > 0) {
			for (Case caseRec : [SELECT Id, Ownerid FROM Case WHERE Id IN :caseIdList FOR UPDATE]) {
				caseRec.Ownerid = UserInfo.getUserId();
				if (String.isNotBlank(caseTypeStr) && caseTypeStr == 'QSEHRA') {
					caseRec.Status = 'In Progress';
				}
				caselistToUpdate.add(caseRec);
			}
		}

		if (caselistToUpdate.size() > 0) {
			try {
				caseTriggerHelper.playmode = true;
				update caselistToUpdate;
				caseTriggerHelper.playmode = false;
			} catch (Exception ex) {
				return false;
			}
		}
		return true;
	}

	public static void saveUserPrefrence(Play_Mode_Config__c configRec, String selectedCarrierType) {
		if (configRec != null && selectedCarrierType != null) {
			User_Preference__c userPreference = new User_Preference__c();

			List<User_Preference__c> userList = [SELECT Id, MF_Case_Play_Details__c FROM User_Preference__c WHERE User__c = :UserInfo.getUserId()];
			if (userList.size() > 0) {
				userPreference = userList[0];
			} else {
				userPreference.User__c = UserInfo.getUserId();
			}

			String mfDetails = configRec.Name + '!@!' + selectedCarrierType;
			userPreference.MF_Case_Play_Details__c = mfDetails;

			try {
				upsert userPreference;
			} catch (Exception ex) {
			}
		}
	}

	@remoteAction
	public static String nextCase() {
		User_Preference__c userPreference = new User_Preference__c();

		List<User_Preference__c> userList = [SELECT Id, MF_Case_Play_Details__c FROM User_Preference__c WHERE User__c = :UserInfo.getUserId()];
		if (userList.size() > 0 && userList[0].MF_Case_Play_Details__c != null && userList[0].MF_Case_Play_Details__c.length() > 0) {
			userPreference = userList[0];

			Integer indexofSeparator = userPreference.MF_Case_Play_Details__c.indexof('!@!');
			String configName = userPreference.MF_Case_Play_Details__c.substring(0, indexofSeparator).trim();
			String carrierTypeStr = userPreference.MF_Case_Play_Details__c.substring(indexofSeparator + 3).trim();

			Play_Mode_Config__c configRec = Play_Mode_Config__c.getValues(configName);

			List<Case> tempCaseList = getQueriedCaseRecords(configRec, carrierTypeStr);
			if (tempCaseList != null && tempCaseList.size() > 0) {
				if (assignCasesToUser(new List<string>{ tempCaseList.get(0).id }, '')) {
					return string.valueof(tempCaseList.get(0).id);
				}
			}
		}

		return null;
	}
}