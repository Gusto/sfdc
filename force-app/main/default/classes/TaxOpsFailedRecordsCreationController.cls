/***********************************************************************************
 * Filename	  : TaxOpsFailedRecordsCreationController
 * Purpose 	  : TaxOpsFailedRecordsCreationController is a controller class for VFPage TaxOpsMassupdaerRedirectPage
 *
 * Authors 	  :
 *
 * CreatedDate :
 ************************************************************************************/
/* History
 *-------
 * VERSION           AUTHOR                   DATE                   UserStory/DefectID              DETAIL
 * 1.0                                                                Base VERSION
 * 2.0               Chaitanya Kurra          09-15-2020              Tax Ops issue                   Tax Ops issue with email CCIDs
 */

public with sharing class TaxOpsFailedRecordsCreationController {
	public Tax_Ops_Failed_Record__c toUpdateFailedRecord { get; set; }
	public Tax_Ops_Task__c taskRec { get; set; }
	public boolean isRecordSelected { get; set; }
	public boolean massUpdateSuccessful { get; set; }
	public boolean recordTypeSupported { get; set; }
	public list<SelectOption> recordTypeOptionList { get; set; }
	public string selectedRecordTypeName { get; set; }
	public list<Schema.FieldSetMember> commonFieldsApiNameList { get; set; }
	public list<Schema.FieldSetMember> fieldsApiNameList { get; set; }
	public Integer pageSize { get; set; }

	public string selectedRecIdStr { get; set; }
	public boolean isCommonUpdate { get; set; }

	//pagination and filter
	public ApexPages.StandardSetController setCon { get; set; }
	public List<SelectOption> paginationSizeOptions { get; set; }
	public List<SelectOption> filterOptions { get; set; }
	public string selectedFilterStr { get; set; }
	public string filterStr { get; set; }
	public string sortField { get; set; }
	public boolean showDuplicates { get; set; }
	string preSortField;
	string previousSortOrder;

	public map<string, string> feinAccountnumberMap;
	public map<string, string> accountNumberFeinMap;
	public boolean sendMassEmail { get; set; }
	public boolean saveEmailBody { get; set; }

	boolean syncRecBeforeMassUpdate = false;

	//this is to use class methods
	public TaxOpsFailedRecordsCreationController() {
	}

	public TaxOpsFailedRecordsCreationController(apexPages.StandardSetController scon) {
		showDuplicates = false;
		isRecordSelected = true;
		massUpdateSuccessful = false;
		toUpdateFailedRecord = new Tax_Ops_Failed_Record__c();
		recordTypeSupported = false;
		recordTypeOptionList = new List<SelectOption>();

		paginationSizeOptions = new List<SelectOption>();
		paginationSizeOptions.add(new SelectOption('5', '5'));
		paginationSizeOptions.add(new SelectOption('10', '10'));
		paginationSizeOptions.add(new SelectOption('20', '20'));
		paginationSizeOptions.add(new SelectOption('50', '50'));
		paginationSizeOptions.add(new SelectOption('100', '100'));

		filterOptions = new List<SelectOption>();
		filterOptions.add(new SelectOption('0', '-Select Filter-'));
		filterOptions.add(new SelectOption('FEIN__c', 'Fein'));
		filterOptions.add(new SelectOption('Account_number__c', 'Account Number'));
		filterOptions.add(new SelectOption('Failure_Reason__c', 'Failure Reason'));
	}

	public list<Tax_Ops_Failed_Record__c> selectedFailedRecordList {
		get {
			if (setCon != null) {
				isRecordSelected = true;
				return (List<Tax_Ops_Failed_Record__c>) setCon.getRecords();
			} else {
				isRecordSelected = false;
				return null;
			}
		}
		set;
	}

	public void init() {
		string parentId = apexPages.currentPage().getParameters().get('id');
		string recordTypeName = apexPages.currentPage().getParameters().get('rtnm');
		if (pageSize == null)
			pageSize = 50;
		if (parentId != null && parentId.indexof(Tax_Ops_Task__c.SObjectType.getDescribe().getKeyPrefix()) == 0) {
			populateFieldNameList(recordTypeName); //populating fields name list based on recordtype

			string queryStr = 'select ';
			for (Schema.FieldSetMember rec : fieldsApiNameList) {
				if (
					rec.getFieldPath().equalsIgnoreCase('RecordTypeId') ||
					rec.getFieldPath().equalsIgnoreCase('FEIN__c') ||
					rec.getFieldPath().equalsIgnoreCase('Account_number__c') ||
					rec.getFieldPath().equalsIgnoreCase('Contact__c')
				) {
					continue;
				}
				queryStr += rec.getFieldPath() + ', ';
			}

			for (Schema.FieldSetMember rec : commonFieldsApiNameList) {
				if (
					rec.getFieldPath().equalsIgnoreCase('RecordTypeId') ||
					rec.getFieldPath().equalsIgnoreCase('FEIN__c') ||
					rec.getFieldPath().equalsIgnoreCase('Account_number__c') ||
					rec.getFieldPath().equalsIgnoreCase('Contact__c')
				) {
					continue;
				}
				if (queryStr != null && queryStr.indexof(rec.getFieldPath()) == -1) {
					queryStr += rec.getFieldPath() + ', ';
				}
			}

			queryStr += ' id,FEIN__c,RecordTypeId,Account_number__c,Contact__c,CC_Ids__c from Tax_Ops_Failed_Record__c where Tax_Ops_Task__c =:parentId ';
			if (string.isNotBlank(recordTypeName)) {
				string recordTypeId;
				if (recordTypeName.equalsIgnoreCase('ff')) {
					recordTypeId = Cache.getRecordTypeId('Tax_Ops_Failed_Record__c', 'Failed Filing');
					selectedRecordTypeName = 'Failed Filing';
				} else if (recordTypeName.equalsIgnoreCase('fp')) {
					recordTypeId = Cache.getRecordTypeId('Tax_Ops_Failed_Record__c', 'Failed Payment');
					selectedRecordTypeName = 'Failed Payment';
				}

				queryStr += ' and recordTypeId=:recordTypeId  and inactive__c = false  ';
				if (!showDuplicates) {
					queryStr += ' and isduplicate__c=:showDuplicates ';
				}

				if (string.isNotBlank(selectedFilterStr) && selectedFilterStr != '0' && string.isNotBlank(filterStr)) {
					queryStr += ' and ' + selectedFilterStr + ' like \'%' + filterStr + '%\'';
				}

				if (string.isNotBlank(sortField)) {
					if (preSortField == sortField && previousSortOrder == 'ASC') {
						previousSortOrder = 'DESC';
					} else {
						previousSortOrder = 'ASC';
					}
					preSortField = sortField;
					queryStr += ' order by ' + sortField + ' ' + previousSortOrder + ' NULLS LAST ';
				}

				toUpdateFailedRecord.RecordTypeId = recordTypeId;
			}

			List<Tax_Ops_Failed_Record__c> resultList = Database.query(queryStr);
			setCon = new ApexPages.StandardSetController(resultList);
			setCon.setPageSize(pageSize);
		}
	}

	public void syncFailedRecords() {
		/*BY:PR, Date:7/16/19, Desc: introduced the skip_save logic to consider the delay while asynchronus failed record creation via csv file.*/
		string taxopsId = apexPages.currentPage().getparameters().get('id');
		list<Tax_Ops_Task__c> lst_tempData = [SELECT Id, CSV_File_Processing__c FROM Tax_Ops_Task__c WHERE id = :taxopsId];

		if (lst_tempData.size() > 0 && lst_tempData.get(0).CSV_File_Processing__c == true) {
			apexPages.addMessage(new apexPages.Message(apexPages.severity.info, 'Data uploaded via csv file is still being processed. Please try again after some time.'));
			return;
		}

		if (apexPages.currentPage().getParameters().get('syncrec') != null && apexPages.currentPage().getParameters().get('syncrec') == '1') {
			syncRecBeforeMassUpdate = true;
		}
		if (syncRecBeforeMassUpdate) {
			createTaxOpsFailedRec_v2();
			syncRecBeforeMassUpdate = false;
			init();
		}
	}

	//populating the field api name list we are using to show fields on page
	public void populateFieldNameList(string recTypeName) {
		fieldsApiNameList = new List<Schema.FieldSetMember>();
		commonFieldsApiNameList = new List<Schema.FieldSetMember>();
		string fieldSetName;
		string commanFieldsSetName;

		if (string.isNotBlank(recTypeName)) {
			if (recTypeName.equalsIgnoreCase('ff')) {
				fieldSetName = 'Failed_Filing_Mass_Update';
				commanFieldsSetName = 'Failed_Filing_Mass_Update_Common_Fields';
			} else if (recTypeName.equalsIgnoreCase('fp')) {
				fieldSetName = 'Failed_Payment_Mass_Update';
				commanFieldsSetName = 'Failed_Payment_Mass_Update_Common_Fields';
			}
		}

		fieldsApiNameList.addAll(getFields(fieldSetName, 'Tax_Ops_Failed_Record__c'));
		commonFieldsApiNameList.addAll(getFields(commanFieldsSetName, 'Tax_Ops_Failed_Record__c'));
	}

	//return fields of the fieldSet whose name we have passed as a parameter
	public static List<Schema.FieldSetMember> getFields(String fieldSetName, String ObjectName) {
		Schema.DescribeSObjectResult DescribeSObjectResultObj = Utils.getSObjectDescribe(ObjectName);
		Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
		return fieldSetObj.getFields();
	}

	// this method is called on click of save button from page
	public void massUpdate() {
		list<Tax_Ops_Failed_Record__c> toMassUpdateFailedRecordList = new List<Tax_Ops_Failed_Record__c>();
		set<string> commonUpdateSelectedRecordsIdSet = new Set<string>();
		list<string> invalidFRfeinList = new List<string>();
		list<string> invalidFRAccNumList = new List<string>();

		if (selectedRecIdStr != null && selectedRecIdStr.length() > 0) {
			commonUpdateSelectedRecordsIdSet.addAll(selectedRecIdStr.split('selected__'));
			selectedRecIdStr = null;
		}

		// if we have selected some records, we are populating the command field values to all the selected ones.
		toMassUpdateFailedRecordList = selectedFailedRecordList;
		for (Tax_Ops_Failed_Record__c rec : toMassUpdateFailedRecordList) {
			if (isCommonUpdate && commonUpdateSelectedRecordsIdSet.contains(rec.id)) {
				Tax_Ops_Failed_Record__c tempRec = rec;
				for (Schema.FieldSetMember f : commonFieldsApiNameList) {
					if (
						toUpdateFailedRecord.get(f.getFieldPath()) != null &&
						toUpdateFailedRecord.get(f.getFieldPath()) != '' &&
						string.valueof(toUpdateFailedRecord.get(f.getFieldPath())).length() > 0
					) {
						tempRec.put(f.getFieldPath(), toUpdateFailedRecord.get(f.getFieldPath()));
					}
				}
			}

			if (rec.Inactive__c) {
				if (string.isnotBlank(rec.FEIN__c)) {
					invalidFRfeinList.add(rec.FEIN__c);
				}

				if (string.isnotBlank(rec.Account_Number__c)) {
					invalidFRAccNumList.add(rec.Account_Number__c);
				}
			}
		}

		if (invalidFRfeinList.size() > 0 || invalidFRAccNumList.size() > 0) {
			list<string> feinList = new List<string>();
			list<string> accNumList = new List<string>();
			if (taskRec.Process_Step__c.equalsIgnoreCase('Payments')) {
				if (string.isNotBlank(taskRec.Failed_Payment_FEINs__c))
					feinList.addAll(taskRec.Failed_Payment_FEINs__c.tolowerCase().deleteWhitespace().split(','));

				if (string.isNotBlank(taskRec.Failed_Payment_Account_Numbers__c))
					accNumList.addAll(taskRec.Failed_Payment_Account_Numbers__c.tolowerCase().deleteWhitespace().split(','));
			}

			if (taskRec.Process_Step__c.indexof('Filing') > -1) {
				if (string.isNotBlank(taskRec.Failed_Filing_FEINs__c))
					feinList.addAll(taskRec.Failed_Filing_FEINs__c.tolowerCase().deleteWhitespace().split(','));

				if (string.isNotBlank(taskRec.Failed_Filing_Account_Numbers__c))
					accNumList.addAll(taskRec.Failed_Filing_Account_Numbers__c.tolowerCase().deleteWhitespace().split(','));
			}

			for (string rec : invalidFRfeinList) {
				if (feinList.size() > 0 && feinList.indexOf(rec.toLowerCase()) > -1) {
					feinList.remove(feinList.indexOf(rec.toLowerCase()));
				}
			}

			for (string rec : invalidFRAccNumList) {
				if (accNumList.size() > 0 && accNumList.indexOf(rec.toLowerCase()) > -1) {
					accNumList.remove(accNumList.indexOf(rec.toLowerCase()));
				}
			}

			if (taskRec.Process_Step__c.equalsIgnoreCase('Payments')) {
				if (feinList.size() > 0) {
					taskRec.Failed_Payment_FEINs__c = string.join(feinList, ',');
				} else {
					taskRec.Failed_Payment_FEINs__c = '';
				}

				if (accNumList.size() > 0) {
					taskRec.Failed_Payment_Account_Numbers__c = string.join(accNumList, ',');
				} else {
					taskRec.Failed_Payment_Account_Numbers__c = '';
				}
			}

			if (taskRec.Process_Step__c.indexof('Filing') > -1) {
				if (feinList.size() > 0) {
					taskRec.Failed_Filing_FEINs__c = string.join(feinList, ',');
				} else {
					taskRec.Failed_Filing_FEINs__c = '';
				}

				if (accNumList.size() > 0) {
					taskRec.Failed_Filing_Account_Numbers__c = string.join(accNumList, ',');
				} else {
					taskRec.Failed_Filing_Account_Numbers__c = '';
				}
			}
		}

		try {
			if (toMassUpdateFailedRecordList.size() > 0) {
				update toMassUpdateFailedRecordList;
			}

			isCommonUpdate = false;

			if (invalidFRfeinList.size() > 0 || invalidFRAccNumList.size() > 0) {
				update taskRec;
				init();
			}
			apexPages.addMessage(new apexpages.message(apexPages.severity.info, 'Records updated successfully.'));
		} catch (exception ex) {
			apexPages.addMessage(new apexPages.Message(apexPages.severity.error, ex.getMessage()));
		}
	}

	//==========================Sync Failed record object's records===================
	//by: PR, 4/5/2019, Dec: On click of the "Sync Failed Records" button on the taxopstask detail page. We are calling the
	// below method to sync the "Failed Records" with the values of the Failed Payment FEINs and Failed Filing FEINs field of tax ops task record.
	public pageReference createTaxOpsFailedRec_v2() {
		string taxopsId = apexPages.currentPage().getparameters().get('id');

		if (taxopsId == null || taxopsId.indexof(Tax_Ops_Task__c.SObjectType.getDescribe().getKeyPrefix()) == -1) {
			return new pageReference('/' + taxopsId);
		}

		if (string.isNotBlank(taxopsId)) {
			list<Tax_Ops_Task__c> taxopsRecList = [
				SELECT id, Failed_Payment_FEINs__c, Failed_Filing_FEINs__c, Failed_Payment_Account_Numbers__c, Failed_Filing_Account_Numbers__c, Tax_Code__c, Process_Step__c
				FROM Tax_Ops_Task__c
				WHERE id = :taxopsId
			];
			/* these lists gets poopulated from the fein and account numeber field on Task object    
                helps keep track of fein/account number with corresponding FRs
            */
			list<string> feinsPresentInTaskRecList = new List<string>();
			list<string> accNumPresentInTaskRecList = new List<string>();

			// list of FR that we want to update with
			list<Tax_Ops_Failed_Record__c> toInactivateFRList = new List<Tax_Ops_Failed_Record__c>();
			list<Tax_Ops_Failed_Record__c> alreadyPresentDuplicateFRList = new List<Tax_Ops_Failed_Record__c>();

			/*keep track of records with unique fein/account number, helps in finding duplicates while creating new records
			 and updating appended tax code value from duplicate to */
			map<string, Tax_Ops_Failed_Record__c> uniqueFeinsMap = new Map<string, Tax_Ops_Failed_Record__c>();
			map<string, Tax_Ops_Failed_Record__c> uniqueAccNumMap = new Map<string, Tax_Ops_Failed_Record__c>();

			/*
                to populate already present FRs with empty Account field
            */
			list<Tax_Ops_Failed_Record__c> processedForAccountFRList = new List<Tax_Ops_Failed_Record__c>();
			set<string> processedForAccountFRFeinSet = new Set<string>();
			set<string> processedForAccountFRAccNumSet = new Set<string>();

			if (taxopsRecList.size() > 0) {
				Tax_Ops_Task__c parentTaxOpsRec = taxopsRecList.get(0);
				taskRec = taxopsRecList.get(0);
				string toProcessFailedRecord_RecordTypeId;

				// get all the feins and account numbers based on Process Step
				if (parentTaxOpsRec.Process_Step__c.equalsIgnoreCase('Payments')) {
					toProcessFailedRecord_RecordTypeId = Cache.getRecordTypeId('Tax_Ops_Failed_Record__c', 'Failed Payment');
					if (string.isNotBlank(parentTaxOpsRec.Failed_Payment_FEINs__c))
						feinsPresentInTaskRecList.addAll(parentTaxOpsRec.Failed_Payment_FEINs__c.toLowerCase().deleteWhitespace().split(','));

					if (string.isNotBlank(parentTaxOpsRec.Failed_Payment_Account_Numbers__c))
						accNumPresentInTaskRecList.addAll(parentTaxOpsRec.Failed_Payment_Account_Numbers__c.toLowerCase().deleteWhitespace().split(','));
				} else if (parentTaxOpsRec.Process_Step__c.contains('Filing')) {
					toProcessFailedRecord_RecordTypeId = Cache.getRecordTypeId('Tax_Ops_Failed_Record__c', 'Failed Filing');
					if (string.isNotBlank(parentTaxOpsRec.Failed_Filing_FEINs__c))
						feinsPresentInTaskRecList.addAll(parentTaxOpsRec.Failed_Filing_FEINs__c.toLowerCase().deleteWhitespace().split(','));

					if (string.isNotBlank(parentTaxOpsRec.Failed_Filing_Account_Numbers__c))
						accNumPresentInTaskRecList.addAll(parentTaxOpsRec.Failed_Filing_Account_Numbers__c.toLowerCase().deleteWhitespace().split(','));
				}

				// if fein or account number field is not nulll
				if (feinsPresentInTaskRecList.size() > 0 || accNumPresentInTaskRecList.size() > 0) {
					// we want the duplicate records to be present in the end of the list
					for (Tax_Ops_Failed_Record__c fRec : [
						SELECT id, FEIN__c, Tax_Ops_Task__c, Tax_Code__c, Account_Number__c, isDuplicate__c, Inactive__c, Error_Code__c, Account__c, Contact__c
						FROM Tax_Ops_Failed_Record__c
						WHERE Tax_Ops_Task__c = :parentTaxOpsRec.id AND recordTypeId = :toProcessFailedRecord_RecordTypeId AND Inactive__c = FALSE
						ORDER BY isDuplicate__c
					]) {
						/*going through present FRs for the task rec, and based on matching fein/acc num presence in task rec
                      1) we are removing from the candidate list for records to be created (making sure to keep the fein/acc num  and related FR count in sync)
                      2) adding them to the list of FRs to be inactivated (if FR is present but not mentioned in Task rec)
                      */
						boolean isPresent = false;
						string keyStr = (string.isNotBlank(fRec.FEIN__c) ? fRec.FEIN__c.toLowerCase().deleteWhitespace() : '');
						if (string.isNotBlank(keyStr) && feinsPresentInTaskRecList.size() > 0 && feinsPresentInTaskRecList.indexOf(keyStr) > -1) {
							integer tempIndex = feinsPresentInTaskRecList.indexOf(keyStr);
							feinsPresentInTaskRecList.remove(tempIndex);
							isPresent = true;
							if (!uniqueFeinsMap.containsKey(keyStr)) {
								Tax_Ops_Failed_Record__c tempRec = new Tax_Ops_Failed_Record__c(id = fRec.id, Error_Code__c = fRec.Error_Code__c);
								uniqueFeinsMap.put(keyStr, tempRec); // to be used for duplicate check later on
							} else {
								Tax_Ops_Failed_Record__c tempRec = new Tax_Ops_Failed_Record__c(id = fRec.id, isDuplicate__c = true);
								alreadyPresentDuplicateFRList.add(tempRec);
								if (string.isNotBlank(fRec.Error_Code__c)) {
									string errorCode = uniqueFeinsMap.get(keyStr).Error_Code__c;
									if (string.isBlank(errorCode)) {
										errorCode = frec.Error_Code__c;
									} else if (!errorCode.contains(fRec.Error_Code__c)) {
										errorCode += ';' + fRec.Error_Code__c;
									}
									uniqueFeinsMap.get(keyStr).Error_Code__c = errorCode;
								}
							}
						}

						keyStr = (string.isNotBlank(fRec.Account_Number__c) ? fRec.Account_Number__c.toLowerCase().deleteWhitespace() : '');
						if (string.isNotBlank(keyStr) && accNumPresentInTaskRecList.size() > 0 && accNumPresentInTaskRecList.indexOf(keyStr) > -1) {
							integer tempIndex = accNumPresentInTaskRecList.indexOf(keyStr);
							accNumPresentInTaskRecList.remove(tempIndex);
							isPresent = true;
							if (!uniqueAccNumMap.containsKey(keyStr)) {
								Tax_Ops_Failed_Record__c tempRec = new Tax_Ops_Failed_Record__c(id = fRec.id, Error_Code__c = fRec.Error_Code__c);
								uniqueAccNumMap.put(keyStr, fRec); // to be used for duplicate check later on
							} else {
								Tax_Ops_Failed_Record__c tempRec = new Tax_Ops_Failed_Record__c(id = fRec.id, isDuplicate__c = true);
								alreadyPresentDuplicateFRList.add(tempRec);
								if (string.isNotBlank(fRec.Error_Code__c)) {
									string errorCode = uniqueAccNumMap.get(keyStr).Error_Code__c;
									if (string.isBlank(errorCode)) {
										errorCode = frec.Error_Code__c;
									} else if (!errorCode.contains(fRec.Error_Code__c)) {
										errorCode += ';' + fRec.Error_Code__c;
									}
									uniqueAccNumMap.get(keyStr).Error_Code__c = errorCode;
								}
							} // to be used for duplicate check later on
						}

						if (!isPresent) {
							Tax_Ops_Failed_Record__c tempRec = new Tax_Ops_Failed_Record__c(id = fRec.id, inactive__c = true);
							toInactivateFRList.add(tempRec);
						}

						if (fRec.Account__c == null) {
							Tax_Ops_Failed_Record__c tempRec = new Tax_Ops_Failed_Record__c(id = fRec.id, Account_Number__c = fRec.Account_Number__c, FEIN__c = fRec.FEIN__c);
							processedForAccountFRList.add(tempRec);
							if (string.isNotBlank(fRec.Account_Number__c)) {
								processedForAccountFRAccNumSet.add(fRec.Account_Number__c);
							}

							if (string.isNotBlank(fRec.FEIN__c)) {
								processedForAccountFRFeinSet.add(fRec.FEIN__c);
							}
						}
					}
				} else {
					list<Tax_Ops_Failed_Record__c> toSoftDeleteList = new List<Tax_Ops_Failed_Record__c>();
					for (Tax_Ops_Failed_Record__c fRec : [
						SELECT id, inactive__c, Contact__c
						FROM Tax_Ops_Failed_Record__c
						WHERE Tax_Ops_Task__c = :parentTaxOpsRec.id AND recordTypeId = :toProcessFailedRecord_RecordTypeId AND Inactive__c = FALSE
					]) {
						fRec.Inactive__c = true;
						toSoftDeleteList.add(fRec);
					}

					if (toSoftDeleteList.size() > 0) {
						try {
							update toSoftDeleteList;
						} catch (exception ex) {
							apexPages.addMessage(new apexPages.Message(apexPages.Severity.Error, ex.getMessage()));
						}
					}
					return null;
				}

				list<Tax_Ops_Failed_Record__c> toInsertFRList = new List<Tax_Ops_Failed_Record__c>();
				list<Tax_Ops_Failed_Record__c> tList = new List<Tax_Ops_Failed_Record__c>();
				set<string> tempUniqueSet = new Set<string>();

				if (feinsPresentInTaskRecList.size() > 0) {
					tempUniqueSet = uniqueFeinsMap.keyset();
					tList = returnNewFRsForFeinAccNum(parentTaxOpsRec, feinsPresentInTaskRecList, tempUniqueSet, true);
					if (tList.size() > 0) {
						toInsertFRList.addAll(tList);
						tList = new List<Tax_Ops_Failed_Record__c>();
					}
				}

				if (accNumPresentInTaskRecList.size() > 0) {
					tempUniqueSet = uniqueAccNumMap.keyset();
					tList = returnNewFRsForFeinAccNum(parentTaxOpsRec, accNumPresentInTaskRecList, tempUniqueSet, false);
					if (tList.size() > 0) {
						toInsertFRList.addAll(tList);
						tList = new List<Tax_Ops_Failed_Record__c>();
					}
				}

				if (toInsertFRList.size() > 0) {
					try {
						insert toInsertFRList;
					} catch (exception ex) {
						apexPages.addMessage(new apexPages.Message(apexPages.Severity.Error, ex.getMessage()));
						return null;
					}
				}

				if (toInactivateFRList.size() > 0) {
					try {
						update toInactivateFRList;
					} catch (exception ex) {
						apexPages.addMessage(new apexPages.Message(apexPages.Severity.Error, ex.getMessage()));
						return null;
					}
				}

				if (uniqueFeinsMap.keyset().size() > 0) {
					list<Tax_Ops_Failed_Record__c> tempList = new List<Tax_Ops_Failed_Record__c>();
					tempList = uniqueFeinsMap.values();
					try {
						update tempList;
					} catch (exception ex) {
						apexPages.addMessage(new apexPages.Message(apexPages.Severity.Error, ex.getMessage()));
						return null;
					}
				}

				if (uniqueAccNumMap.keyset().size() > 0) {
					list<Tax_Ops_Failed_Record__c> tempList = new List<Tax_Ops_Failed_Record__c>();
					tempList = uniqueAccNumMap.values();
					try {
						update tempList;
					} catch (exception ex) {
						apexPages.addMessage(new apexPages.Message(apexPages.Severity.Error, ex.getMessage()));
						return null;
					}
				}

				if (alreadyPresentDuplicateFRList.size() > 0) {
					try {
						update alreadyPresentDuplicateFRList;
					} catch (exception ex) {
						apexPages.addMessage(new apexPages.Message(apexPages.Severity.Error, ex.getMessage()));
						return null;
					}
				}

				if (processedForAccountFRList.size() > 0) {
					map<string, id> feinAccIdMap = new Map<string, id>();
					map<string, id> accNumAccIdMap = new Map<string, id>();
					if (processedForAccountFRFeinSet.size() > 0) {
						feinAccIdMap = getFeinAccNumAccountMap(processedForAccountFRFeinSet, parentTaxOpsRec.Tax_Code__c, true);
					}

					if (processedForAccountFRAccNumSet.size() > 0) {
						accNumAccIdMap = getFeinAccNumAccountMap(processedForAccountFRAccNumSet, parentTaxOpsRec.Tax_Code__c, false);
					}

					for (Tax_Ops_Failed_Record__c rec : processedForAccountFRList) {
						if (string.isNotBlank(rec.Account_Number__c) && accNumAccIdMap.containsKey(rec.Account_Number__c)) {
							rec.Account__c = accNumAccIdMap.get(rec.Account_Number__c);
						}

						if (string.isNotBlank(rec.FEIN__c) && feinAccIdMap.containsKey(rec.FEIN__c)) {
							rec.Account__c = feinAccIdMap.get(rec.FEIN__c);
						}
					}

					try {
						update processedForAccountFRList;
					} catch (exception ex) {
						apexPages.addMessage(new apexPages.Message(apexPages.Severity.Error, ex.getMessage()));
						return null;
					}
				}
			}
		}

		if (!syncRecBeforeMassUpdate && string.isNotBlank(taxopsId))
			return new pageReference('/' + taxopsId);

		return null;
	}

	public list<Tax_Ops_Failed_Record__c> returnNewFRsForFeinAccNum(Tax_Ops_Task__c taskRec, list<string> toCreateFRsWithList, set<string> uniqueProcessedStrSet, boolean isFein) {
		list<Tax_Ops_Failed_Record__c> toReturnNewFRList = new List<Tax_Ops_Failed_Record__c>();
		set<string> uniqueTempSet = new Set<string>();
		uniqueTempSet.addAll(uniqueProcessedStrSet);

		if (toCreateFRsWithList != null && toCreateFRsWithList.size() > 0) {
			map<string, id> feinAccNumAccIdMap = new Map<string, id>();
			set<string> tempSet = new Set<string>();

			tempSet.addAll(toCreateFRsWithList);
			feinAccNumAccIdMap = getFeinAccNumAccountMap(tempSet, taskRec.Tax_Code__c, isFein);

			for (string keyStr : toCreateFRsWithList) {
				Tax_Ops_Failed_Record__c newFailedRec = new Tax_Ops_Failed_Record__c();
				newFailedRec.Tax_Ops_Task__c = taskRec.id;

				if (taskRec.Process_Step__c.contains('Filing')) {
					newFailedRec.RecordTypeId = Cache.getRecordTypeId('Tax_Ops_Failed_Record__c', 'Failed Filing');
				} else if (taskRec.Process_Step__c.equalsIgnoreCase('Payments')) {
					newFailedRec.RecordTypeId = Cache.getRecordTypeId('Tax_Ops_Failed_Record__c', 'Failed Payment');
				} else {
					return toReturnNewFRList;
				}

				if (feinAccNumAccIdMap.containsKey(keyStr)) {
					newFailedRec.Account__c = feinAccNumAccIdMap.get(keyStr);
				}

				if (isFein) {
					newFailedRec.FEIN__c = keyStr;
				} else {
					newFailedRec.Account_Number__c = keyStr;
				}

				//if already processed check the current rec as duplicate else add it to process set
				if (uniqueTempSet.contains(keyStr)) {
					newFailedRec.isDuplicate__c = true;
				}

				toReturnNewFRList.add(newFailedRec);
				uniqueTempSet.add(keyStr);
			}
		}

		return toReturnNewFRList;
	}

	public map<string, id> getFeinAccNumAccountMap(set<string> feinAccNumSet, string taxcode, boolean isFein) {
		if (feinAccNumSet != null && feinAccNumSet.size() > 0) {
			//We have introduced a new table to establish the relationship between FEINs and Accounts
			map<string, string> zpCompanyIdFeinMap = new Map<string, string>();
			map<string, string> zpCompanyIdAccNumMap = new Map<string, string>();

			string einQueryStr;

			if (isFein) {
				einQueryStr =
					'select id, ZP_Company_ID__c, Tax_Code__c, FEIN__c, Account_Number__c, Reference_Ein__c ' + ' from ZP_Company_Tax_Code_EIN__c where FEIN__c in: feinAccNumSet and FEIN__c != null ';
			} else {
				einQueryStr =
					'select id, ZP_Company_ID__c, Tax_Code__c, FEIN__c, Account_Number__c, Reference_Ein__c ' +
					' from ZP_Company_Tax_Code_EIN__c where (Account_Number__c in: feinAccNumSet or Reference_Ein__c in: feinAccNumSet) ' +
					' and Tax_Code__c=:taxcode ';
			}

			for (ZP_Company_Tax_Code_EIN__c rec : Database.query(einQueryStr)) {
				if (isFein && rec.FEIN__c != null) {
					string feinstr = rec.FEIN__c.toLowerCase();
					if (feinAccNumSet.contains(feinstr)) {
						zpCompanyIdFeinMap.put(rec.ZP_Company_ID__c, feinstr);
					}
				}

				if (!isFein) {
					boolean didexist = false;
					if (string.isNotBlank(rec.Account_Number__c)) {
						string accNumm = rec.Account_Number__c.tolowerCase();
						if (feinAccNumSet.contains(accNumm)) {
							zpCompanyIdAccNumMap.put(rec.ZP_Company_ID__c, accNumm);
							didexist = true;
						}
					}

					if (!didexist && string.isNotBlank(rec.Reference_Ein__c)) {
						string refEinn = rec.Reference_Ein__c.tolowerCase();
						if (feinAccNumSet.contains(refEinn)) {
							zpCompanyIdAccNumMap.put(rec.ZP_Company_ID__c, refEinn);
						}
					}
				}
			}

			// we are querying Account records based on ZP Company Id and are populating Fein/Account Num and Account Rec map
			map<string, id> feinAccountIdMap = new Map<string, id>();
			set<string> tempZPCompanyIdSet = new Set<string>();
			string queryStr = 'Select id, FEIN__c, ZP_Company_ID__c from Account';
			Boolean runQuery = false;

			if (isFein && zpCompanyIdFeinMap.keyset().size() > 0) {
				tempZPCompanyIdSet = zpCompanyIdFeinMap.keyset();
				queryStr += ' WHERE ZP_Company_ID__c IN: tempZPCompanyIdSet ';
				runQuery = true;
			}

			if (!isFein && zpCompanyIdAccNumMap.keyset().size() > 0) {
				tempZPCompanyIdSet = zpCompanyIdAccNumMap.keyset();
				queryStr += ' WHERE ZP_Company_ID__c IN: tempZPCompanyIdSet';
				runQuery = true;
			}

			if (runQuery) {
				for (Account accRec : database.query(queryStr)) {
					if (isFein && zpCompanyIdFeinMap.containsKey(accRec.ZP_Company_ID__c)) {
						feinAccountIdMap.put(zpCompanyIdFeinMap.get(accRec.ZP_Company_ID__c), accRec.id);
					}

					if (!isFein && zpCompanyIdAccNumMap.containsKey(accRec.ZP_Company_ID__c)) {
						feinAccountIdMap.put(zpCompanyIdAccNumMap.get(accRec.ZP_Company_ID__c), accRec.id);
					}
				}
			}

			return feinAccountIdMap;
		}

		return new Map<string, id>();
	}

	//======================Mass Email Functionality===========================
	//=================================Start===========================

	public void populateEmailBodySampleToFailedRecords() {
		set<string> commonUpdateSelectedRecordsIdSet = new Set<string>();
		list<Tax_Ops_Failed_Record__c> toProcessForMassEmailFailedRecordList = new List<Tax_Ops_Failed_Record__c>();

		if (selectedRecIdStr != null && selectedRecIdStr.length() > 0) {
			for (string recId : selectedRecIdStr.split('selected__')) {
				if (string.isNotBlank(recId)) {
					commonUpdateSelectedRecordsIdSet.add(recId.trim());
				}
			}
			selectedRecIdStr = null;
		}

		// if we have selected some records, we are populating the command field values to all the selected ones.
		for (Tax_Ops_Failed_Record__c rec : selectedFailedRecordList) {
			if (commonUpdateSelectedRecordsIdSet.contains(rec.id)) {
				toProcessForMassEmailFailedRecordList.add(rec);
			}
		}

		if (toProcessForMassEmailFailedRecordList.size() > 0) {
			populateContactForTaxOpsFailedRecords(toProcessForMassEmailFailedRecordList);
			sendEmailMessageForTaxOpsFailedRecords(toProcessForMassEmailFailedRecordList);
		}
	}

	map<string, EmailTemplate> templateExtIdRecMap = new Map<string, EmailTemplate>();

	public void sendEmailMessageForTaxOpsFailedRecords(list<Tax_Ops_Failed_Record__c> originalFailedRecordsList) {
		list<Tax_Ops_Failed_Record__c> eligibleCaseList = new List<Tax_Ops_Failed_Record__c>();
		set<id> accountIdSet = new Set<id>();
		set<string> templateIdSet = new Set<string>();
		list<EmailMessage> toInsertEmailMessageList = new List<EmailMessage>();
		map<Tax_Ops_Failed_Record__c, Messaging.SingleEmailMessage> toSendSingleEmailMap = new Map<Tax_Ops_Failed_Record__c, Messaging.SingleEmailMessage>();

		for (Tax_Ops_Failed_Record__c rec : originalFailedRecordsList) {
			templateIdSet.add(rec.Email_Templates__c);
		}

		string orgWideEmailString = label.Email_Message_From_Address;
		id orgwideEmailId;
		list<OrgWideEmailAddress> owEmailist = [SELECT id FROM OrgWideEmailAddress WHERE Address = :Label.Email_Message_From_Address];
		if (owEmailist.size() > 0) {
			orgwideEmailId = owEmailist.get(0).id;
		}

		for (Tax_Ops_Failed_Record__c rec : originalFailedRecordsList) {
			EmailTemplate templateRec = new EmailTemplate();
			if (templateExtIdRecMap.keyset().size() > 0 && templateExtIdRecMap.containsKey(rec.Email_Templates__c)) {
				templateRec = templateExtIdRecMap.get(rec.Email_Templates__c);
			} else {
				rec.Status__c = 'Failed';
				rec.Message__c = 'Template does not exist.';
			}

			Messaging.SingleEmailMessage emailRec = new Messaging.SingleEmailMessage();
			emailRec.setTemplateId(templateRec.id);

			emailRec.setToAddresses(new List<string>{ rec.Contact__c });
			if (rec.CC_Ids__c != null && rec.CC_Ids__c != '') {
				List<Id> ccList = rec.CC_Ids__c.split(',');
				emailRec.setccAddresses(ccList);
			}

			emailRec.setWhatId(rec.id);
			emailRec.settargetObjectId(rec.Contact__c);
			emailRec.saveAsActivity = false;
			emailRec.setUseSignature(false);

			emailRec.setOrgWideEmailAddressId(orgwideEmailId);
			toSendSingleEmailMap.put(rec, emailRec);
		}

		if (toSendSingleEmailMap.keyset().size() > 0) {
			try {
				if (sendMassEmail != null && sendMassEmail) {
					list<Messaging.SendEmailResult> emailResult = Messaging.sendEmail(toSendSingleEmailMap.values(), false);
					populateTaxOpsFailedRecordEmailDetails(toSendSingleEmailMap, true);
					populateFailedEmails(emailResult, originalFailedRecordsList);
					apexPages.addMessage(new apexPages.Message(apexPages.severity.info, 'Mass email successfully sent.'));
				} else {
					Savepoint sp = Database.setSavepoint();
					Messaging.sendEmail(toSendSingleEmailMap.values(), false);
					Database.rollback(sp);
				}
				if (saveEmailBody != null && saveEmailBody) {
					populateTaxOpsFailedRecordEmailDetails(toSendSingleEmailMap, false);
					apexPages.addMessage(new apexPages.Message(apexPages.severity.info, 'Email template applied successfully.'));
				}
				saveEmailBody = false;
				sendMassEmail = false;
			} catch (exception ex) {
				apexPages.addMessage(new apexPages.Message(apexPages.severity.error, 'Unexpected error has occured. Please contact system admin. ' + ex.getMessage()));
			}
		}
	}

	//By:PR, Date: 7/5/2019, Desc: Below we are logging the "error message" in the FR record if the related email is generating error during delivery.
	public static void populateFailedEmails(Messaging.SendEmailResult[] failedEmailList, list<Tax_Ops_Failed_Record__c> taxOpsRecordList) {
		list<Tax_Ops_Failed_Record__c> lst_toUpdateFailedRecords = new List<Tax_Ops_Failed_Record__c>();
		integer indexCounter = 0;
		for (Messaging.SendEmailResult emailRes : failedEmailList) {
			if (!emailRes.IsSuccess()) {
				Messaging.SendEmailError[] lst_emailError = emailRes.getErrors();
				if (taxOpsRecordList != null && taxOpsRecordList.size() > indexCounter && lst_emailError.size() > 0) {
					Tax_Ops_Failed_Record__c tempRec = new Tax_Ops_Failed_Record__c(id = taxOpsRecordList.get(indexCounter).id);
					tempRec.Email_Failure_Reason__c = lst_emailError.get(0).getMessage();
					lst_toUpdateFailedRecords.add(tempRec);
				}
			}
			indexCounter++;
		}

		if (lst_toUpdateFailedRecords.size() > 0) {
			update lst_toUpdateFailedRecords;
		}
	}

	public static void populateTaxOpsFailedRecordEmailDetails(map<Tax_Ops_Failed_Record__c, Messaging.SingleEmailMessage> failedFilingEmailMap, boolean isEmailSend) {
		if (failedFilingEmailMap.keyset().size() > 0) {
			list<Tax_Ops_Failed_Record__c> tempList = new List<Tax_Ops_Failed_Record__c>();
			set<string> contactIdSet = new Set<string>();
			map<string, string> contactIdEmailMap = new Map<string, string>();

			for (Tax_Ops_Failed_Record__c rec : failedFilingEmailMap.Keyset()) {
				contactIdSet.add(rec.Contact__c);
				if (rec.CC_Ids__c != null && rec.CC_Ids__c != '')
					contactIdSet.addAll(rec.CC_Ids__c.split(','));
			}

			if (contactIdSet.size() > 0) {
				for (Contact con : [SELECT id, email FROM Contact WHERE Id IN :contactIdSet]) {
					contactIdEmailMap.put(con.id, con.email);
				}
			}

			for (Tax_Ops_Failed_Record__c rec : failedFilingEmailMap.Keyset()) {
				//V2.0 - Chaitanya Kurra -09-16-2020 Added ContainsKey Check for null pointer exception
				if (failedFilingEmailMap.containsKey(rec)) {
					Messaging.SingleEmailMessage emailRec = failedFilingEmailMap.get(rec);
					Tax_Ops_Failed_Record__c tempRec = rec;
					tempRec.Subject__c = emailRec.getSubject();
					if (contactIdEmailMap != null && contactIdEmailMap.containsKey(string.join(emailRec.getToAddresses(), ','))) {
						tempRec.To_Address__c = contactIdEmailMap.get(string.join(emailRec.getToAddresses(), ','));
					}

					if (!string.isBlank(rec.CC_Ids__c)) {
						string ccStr;
						for (string conId : rec.CC_Ids__c.split(',')) {
							if (string.isBlank(ccStr)) {
								ccStr = contactIdEmailMap.get(conId);
							} else {
								string tempStr = ccStr + ', ' + contactIdEmailMap.get(conId);
								if (tempStr.length() > 255) {
									break;
								}
								ccStr += ', ' + contactIdEmailMap.get(conId);
							}
						}
						tempRec.CC_Address__c = ccStr;
					}

					tempRec.From_Address__c = Label.Email_Message_From_Address;
					tempRec.Body__c = emailRec.getHtmlBody();
					if (isEmailSend) {
						tempRec.Date_Sent__c = system.now().addSeconds(5);
					}

					tempList.add(tempRec);
				}
			}
			update tempList;
		}
	}

	public void populateContactForTaxOpsFailedRecords(list<Tax_Ops_Failed_Record__c> failedRecordList) {
		Set<String> compIdSet = new Set<String>();
		Set<String> templateIdSet = new Set<String>();
		for (Tax_Ops_Failed_Record__c rec : failedRecordList) {
			templateIdSet.add(rec.Email_Templates__c);

			if (rec.Account__c != null)
				compIdSet.add(rec.Account__c);
		}

		for (EmailTemplate rec : [
			SELECT Subject, Name, Id, HtmlValue, DeveloperName, Body
			FROM EmailTemplate
			WHERE DeveloperName IN :templateIdSet
		]) {
			templateExtIdRecMap.put(rec.DeveloperName, rec);
		}

		map<String, accountContact> compMap = getCompanyContactInfo(compIdSet);
		for (Tax_Ops_Failed_Record__c rec : failedRecordList) {
			if (templateExtIdRecMap.keyset().size() > 0 && templateExtIdRecMap.containsKey(rec.Email_Templates__c)) {
				//templateRec = templateExtIdRecMap.get(rec.Email_Templates__c);
			} else {
				rec.Status__c = 'Failed';
				rec.Message__c = 'Template does not exist.';
			}

			if (rec.Account__c != null && compMap.containsKey(rec.Account__c)) {
				accountContact accCont = compMap.get(rec.Account__c);
				if (accCont != null && accCont.primaryContactId != '') {
					rec.Contact__c = accCont.primaryContactId;
				} else {
					rec.Status__c = 'Failed';
				}
				if (accCont != null && string.isNotBlank(accCont.secondaryContactIds)) {
					rec.CC_Ids__c = accCont.secondaryContactIds;
				}
			} else {
				rec.Status__c = 'Failed';
			}
		}
	}

	private map<String, accountContact> getCompanyContactInfo(Set<String> accountIdSet) {
		Set<String> companyIdSet = new Set<string>();
		map<String, string> companyAccountIdSet = new Map<string, string>();

		for (Account rec : [SELECT id, ZP_Company_ID__c FROM Account WHERE id IN :accountIdSet]) {
			if (rec.ZP_Company_ID__c != null) {
				companyIdSet.add(rec.ZP_Company_ID__c);
				companyAccountIdSet.put(rec.ZP_Company_ID__c, rec.id);
			}
		}

		map<String, accountContact> compContactMap = new Map<String, accountContact>();
		List<ZP_User_Role__c> userRoleList = new List<ZP_User_Role__c>(
			[
				SELECT id, Company_Id__c, User_Id__c, Is_Primary__c
				FROM ZP_User_Role__c
				WHERE Company_id__c IN :companyIdSet AND Type__c = 'Role::PayrollAdmin' AND deleted_at__c = NULL
				ORDER BY Company_Id__c
			]
		);
		Set<String> userIdSet = new Set<String>();
		map<String, String> companyPrimaryUserMap = new Map<String, String>();
		map<String, List<String>> companyUserMap = new Map<String, List<String>>();
		for (ZP_User_Role__c role : userRoleList) {
			userIdSet.add(role.User_Id__c);
			if (role.Is_Primary__c == true) {
				companyPrimaryUserMap.put(role.Company_Id__c, role.User_Id__c);
			} else {
				List<String> compUsrList = new List<String>();
				if (companyUserMap.containsKey(role.Company_Id__c)) {
					compUsrList = companyUserMap.get(role.Company_Id__c);
				}
				compUsrList.add(role.User_Id__c);
				companyUserMap.put(role.Company_Id__c, compUsrList);
			}
		}
		map<String, String> userIdEmailMap = new Map<String, String>();
		for (ZP_User__c usr : [SELECT Id, id__c, email__c FROM ZP_User__c WHERE Deleted_at__c = NULL AND id__c IN :userIdSet]) {
			userIdEmailMap.put(usr.id__c, usr.email__c);
		}
		map<String, String> emailContactIdMap = new Map<String, String>();
		for (Contact cnt : [SELECT id, email FROM contact WHERE email IN :userIdEmailMap.values() AND email != NULL AND email != '']) {
			emailContactIdMap.put(cnt.email, cnt.id);
		}
		for (String compId : companyIdSet) {
			string accountId = companyAccountIdSet.get(compId);
			accountContact accCnt = new accountContact();
			accCnt.primaryContactId = '';
			accCnt.secondaryContactIds = '';
			accCnt.accountId = accountId;
			if (companyPrimaryUserMap.containsKey(compId)) {
				String userId = companyPrimaryUserMap.get(compId);
				if (userIdEmailMap.containsKey(userId)) {
					String email = userIdEmailMap.get(userId);

					if (emailContactIdMap.containsKey(email)) {
						accCnt.primaryContactId = emailContactIdMap.get(email);
					}
				}
			}
			if (companyUserMap.containsKey(compId)) {
				List<String> userIdList = companyUserMap.get(compId);

				for (String usrId : userIdList) {
					if (userIdEmailMap.containsKey(usrId)) {
						String email = userIdEmailMap.get(usrId);

						if (emailContactIdMap.containsKey(email)) {
							if (emailContactIdMap.get(email) != '') {
								if (accCnt.secondaryContactIds == '') {
									accCnt.secondaryContactIds = emailContactIdMap.get(email);
								} else {
									accCnt.secondaryContactIds += ',' + emailContactIdMap.get(email);
								}
							}
						}
					}
				}
			}
			compContactMap.put(accountId, accCnt);
		}
		return compContactMap;
	}

	private class accountContact {
		private string accountId;
		private string primaryContactId;
		private String secondaryContactIds;
	}

	//==========================================
	//==============create and attach failed records as csv====

	public void createAttachFailedRec() {
		string parentId = apexPages.currentPage().getParameters().get('id');

		if (string.isnotblank(parentId)) {
			apexpages.currentPage().getparameters().put('id', parentId);
			TaxOpsTaskCSVImportController contrl = new TaxOpsTaskCSVImportController();
			contrl.saveChildDetailsAsCSVAttachment();
		}
	}

	//======================pagination
	public void saveAndPrevious() {
		setcon.Save();
		setcon.Previous();
	}

	public pageReference saveAndNext() {
		setcon.Save();
		setcon.Next();
		return null;
	}

	public pageReference changePageSize() {
		setcon = null;
		init();
		setCon.setPageNumber(1);
		return null;
	}
}