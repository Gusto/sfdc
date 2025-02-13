/**
 * Author: Todd Dowdy
 * Date: 08/12/2022
 * Desc: Batch to update Case records with auto email content that will trigger flow to send email alert
 **/
public with sharing class TaxNoticePackageBatch implements Database.Batchable<sObject> {
	public String strQueryUsed;
	public Database.QueryLocator start(Database.Batchablecontext bc) {
		// Query for all Auto Response Packages
		String strPkgQuery =
			'SELECT Name, RecordType.DeveloperName, Notice_Period__c, Active__c, Related_Agency_IDs__c, Large_Scale_Issue_Classification__c, ' +
			'Agency_Information__c, Status__c, Email_Template__c, Tax_Notice_Date__c, Tax_Notice_Start_Date__c, Tax_Notice_End_Date__c, ' +
			'Tax_Notice_Form_Number__c, Tax_Notice_Numeration__c, Tax_Notice_Type__c, Tax_Notice_Amount_Total__c, Lowest_Tax_Notice_Amount__c, ' +
			'Highest_Tax_Notice_Amount__c, Sub_Root_Cause__c, Root_Cause__c, Customer_Journey__c , Gusto_Is_Addressee_Of_Record__c, Case_Origin_is_Electronic_Notice__c, Client_Ids__c ' +
			'FROM Auto_Solve_Package__c ' +
			'WHERE RecordType.DeveloperName = \'Auto_Solve_Batch\' ' +
			'AND AutoSolvePackageStatus__c = \'Active\' ';
		return Database.getQueryLocator(strPkgQuery);
	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		try {
			List<Auto_Solve_Package__c> list_NoticePkge = (List<Auto_Solve_Package__c>) scope;
			Map<Id, Case> map_UpdateCases = new Map<ID, Case>();
			String strDynamicQry = '';
			String strQuery = '';
			String strSelectQry =
				'SELECT Id, Case__c, Case__r.Mass_Email_Step__c  ' +
				'FROM Tax_Notice_Index__c ' +
				'WHERE RecordType.Name = \'Manual Indexing\' ' +
				'AND Case__r.RecordType.Name = \'Tax Res\' ' +
				'AND Case__r.ContactId != NULL ' +
				'AND Case__r.IsClosed = false ' +
				'AND Case__r.Status != \'Solved\' ' +
				'AND Case__r.Tax_Res_Auto_Response_Sent__c = false ' +
				'AND Case__r.Mass_Email_Step__c EXCLUDES (\'' +
				TaxResAutoSolveUtil.DUPLICATE_NOTICE_AUTO_SOLVED_FIRED +
				'\') ';

			for (Auto_Solve_Package__c objPkg : list_NoticePkge) {
				strDynamicQry += ' AND Case__r.Mass_Email_Step__c EXCLUDES (\'' + objPkg.Name + '\') ';

				if (String.isNotBlank(objPkg.Tax_Notice_Form_Number__c)) {
					List<String> list_PkgForm = new List<String>();
					list_PkgForm = objPkg.Tax_Notice_Form_Number__c.split(',');
					String strForm = '(\'' + String.join(list_PkgForm, '\',\'') + '\')';
					strDynamicQry += 'AND Tax_Notice_Form_Number__c IN' + strForm + ' ';
				}
				
				if (objPkg.Case_Origin_is_Electronic_Notice__c) {
					strDynamicQry += 'AND Case__r.Origin = \'' + CaseUtils.ORIGIN_ELECTRONIC_NOTICE + '\' ';
				} else {
					strDynamicQry += 'AND Case__r.Origin != \'' + CaseUtils.ORIGIN_ELECTRONIC_NOTICE + '\' ';
				}

				if (objPkg.Agency_Information__c != null) {
					strDynamicQry += 'AND Agency_Information__c = \'' + objPkg.Agency_Information__c + '\' ';
				}

				if (String.isNotBlank(objPkg.Related_Agency_IDs__c)) {
					List<String> list_PkgAgencies = new List<String>();
					list_PkgAgencies = objPkg.Related_Agency_IDs__c.split(',');
					String strAgencies = '(\'' + String.join(list_PkgAgencies, '\',\'') + '\')';
					strDynamicQry += 'AND Agency_Information__c IN' + strAgencies + ' ';
				}

				if (objPkg.Tax_Notice_Type__c != null) {
					List<String> list_PkgNoticeType = new List<String>();
					list_PkgNoticeType = objPkg.Tax_Notice_Type__c.split(';');
					String strNoticeType = '(\'' + String.join(list_PkgNoticeType, '\',\'') + '\')';
					strDynamicQry += 'AND Tax_Notice_Type__c IN' + strNoticeType + ' ';
				}

				if (objPkg.Tax_Notice_Date__c != null) {
					Date dtNotice = Date.newInstance(objPkg.Tax_Notice_Date__c.year(), objPkg.Tax_Notice_Date__c.month(), objPkg.Tax_Notice_Date__c.day());
					strDynamicQry += 'AND Tax_Notice_Date__c = ' + String.valueOf(dtNotice) + ' ';
				}

				if (objPkg.Tax_Notice_Start_Date__c != null && objPkg.Tax_Notice_End_Date__c != null) {
					Date dtNoticeStart = Date.newInstance(objPkg.Tax_Notice_Start_Date__c.year(), objPkg.Tax_Notice_Start_Date__c.month(), objPkg.Tax_Notice_Start_Date__c.day());
					Date dtNoticeEnd = Date.newInstance(objPkg.Tax_Notice_End_Date__c.year(), objPkg.Tax_Notice_End_Date__c.month(), objPkg.Tax_Notice_End_Date__c.day());
					strDynamicQry += 'AND Tax_Notice_Date__c >= ' + String.valueOf(dtNoticeStart) + ' ' + 'AND Tax_Notice_Date__c <= ' + String.valueOf(dtNoticeEnd) + ' ';
				}

				if (objPkg.Tax_Notice_Numeration__c != null) {
					List<String> list_PkgNoticeNum = new List<String>();
					list_PkgNoticeNum = objPkg.Tax_Notice_Numeration__c.split(';');
					String strNoticeNum = '(\'' + String.join(list_PkgNoticeNum, '\',\'') + '\')';
					strDynamicQry += 'AND Tax_Notice_Numeration__c IN' + strNoticeNum + ' ';
				}

				if (objPkg.Status__c != null) {
					List<String> list_PkgStatuses = new List<String>();
					list_PkgStatuses = objPkg.Status__c.split(';');
					String strStatus = '(\'' + String.join(list_PkgStatuses, '\',\'') + '\')';
					strDynamicQry += 'AND Case__r.Status IN' + strStatus + ' ';
				}

				if (objPkg.Tax_Notice_Amount_Total__c != null) {
					if (objPkg.Tax_Notice_Amount_Total__c == 0) {
						strDynamicQry += 'AND ( Tax_Notice_Amount_Total__c = null OR Tax_Notice_Amount_Total__c = ' + objPkg.Tax_Notice_Amount_Total__c + ') ';
					} else {
						strDynamicQry += 'AND Tax_Notice_Amount_Total__c = ' + objPkg.Tax_Notice_Amount_Total__c + ' ';
					}
				}

				if (objPkg.Lowest_Tax_Notice_Amount__c != null && objPkg.Highest_Tax_Notice_Amount__c != null) {
					if (objPkg.Lowest_Tax_Notice_Amount__c == 0) {
						strDynamicQry +=
							'AND ( Tax_Notice_Amount_Total__c = null OR ( Tax_Notice_Amount_Total__c >= ' +
							objPkg.Lowest_Tax_Notice_Amount__c +
							' AND Tax_Notice_Amount_Total__c <= ' +
							objPkg.Highest_Tax_Notice_Amount__c +
							')) ';
					} else {
						strDynamicQry += 'AND Tax_Notice_Amount_Total__c >= ' + objPkg.Lowest_Tax_Notice_Amount__c + ' AND Tax_Notice_Amount_Total__c <= ' + objPkg.Highest_Tax_Notice_Amount__c + ' ';
					}
				}

				if (objPkg.Notice_Period__c != null) {
					List<String> list_PkgNoticePeriod = new List<String>();
					list_PkgNoticePeriod = objPkg.Notice_Period__c.split(';');
					String strNoticePeriod = '(\'' + String.join(list_PkgNoticePeriod, '\',\'') + '\')';
					strDynamicQry += 'AND Yr_Qtr__c IN ' + strNoticePeriod + ' ';
				}
				//Added filter for Client Ids
				if (objPkg.Client_Ids__c != null) {
					Set<String> set_ClientIds = new Set<String>();
					for (String strClientId : objPkg.Client_Ids__c.split('\\n')) {
						if (strClientId != null && strClientId.length() > 0)
							set_ClientIds.add(strClientId.trim());
					}
					strDynamicQry += 'AND Client_Name__r.ZP_Company_ID__c IN :set_ClientIds' + ' ';
				}

				strDynamicQry += 'AND Case__r.Physical_Mail__c = ' + objPkg.Gusto_Is_Addressee_Of_Record__c + ' ';
				strDynamicQry += ' ORDER BY Client_Name__c'; // Reduce UNABLE_TO_LOCK_ROW error

				if (strDynamicQry != null) {
					strQuery = strSelectQry + ' ' + strDynamicQry;
					strQueryUsed = strQuery;
					List<Tax_Notice_Index__c> list_TaxNoticeIndexs = Database.query(strQuery);
					if (!list_TaxNoticeIndexs?.isEmpty()) {
						for (Tax_Notice_Index__c objTaxNotice : list_TaxNoticeIndexs) {
							Case objCasestoUpdate = new Case(Id = objTaxNotice.Case__c, Mass_Email_Step__c = objTaxNotice.Case__r.Mass_Email_Step__c);
							objCasestoUpdate.Auto_Response_Email_Content__c = objPkg.Email_Template__c;
							objCasestoUpdate.Customer_Journey__c = objPkg.Customer_Journey__c;
							objCasestoUpdate.Root_Cause__c = objPkg.Root_Cause__c;
							objCasestoUpdate.Sub_Root_Cause__c = objPkg.Sub_Root_Cause__c;
							objCasestoUpdate.Automation_Status__c = 'Started';
							objCasestoUpdate.Automation_Message__c = 'Auto-Solve Batch';
							objCasestoUpdate.Mass_Email_Step__c = objCasestoUpdate.Mass_Email_Step__c == null ? objPkg.Name : objCasestoUpdate.Mass_Email_Step__c + ';' + objPkg.Name;
							//Update LSI classification
							objCasestoUpdate.Large_Scale_Issue_Classification__c = objPkg.Large_Scale_Issue_Classification__c;
							map_UpdateCases.put(objCasestoUpdate.Id, objCasestoUpdate);
						}
					}
					strDynamicQry = '';
				}
			}

			if (!map_UpdateCases.isEmpty()) {
				CaseTriggerHelper.skipTrigger = true;
				update map_UpdateCases.values();
				CaseTriggerHelper.skipTrigger = false;
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('TaxNoticePackageBatch', 'execute', ex.getMessage() + '- Query: ' + strQueryUsed, ex.getStackTraceString());
		}
	}

	public void finish(Database.BatchableContext bc) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :bc.getJobId()];
		if (objAsyncJob.NumberOfErrors > 0) {
			Utils.processBatchFinish(objAsyncJob, '', false);
		}
	}
}