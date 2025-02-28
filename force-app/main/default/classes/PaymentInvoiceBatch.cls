/**
 * @author Praveen Sethu
 * @since 08/01/2022
 * Batch classes to process all invoices received from Zuora
 * Test class: PaymentInvoiceBatchTest
 **/
global class PaymentInvoiceBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
	// queued processing state
	public Set<String> set_ProcessingStates = new Set<String>{ IntegrationUtils.QUEUED_STATE, IntegrationUtils.ERROR_STATE };

	public Invoice_Run_Log__c objInvoiceRunLog = new Invoice_Run_Log__c();
	public String strWorkflowRunNumber;
	public Integer intInvoiceCount = 0;
	public List<String> list_BatchPendingStatus = new List<String>{ 'Holding', 'Queued', 'Preparing', 'Processing' };

	// batch query
	public String strQuery;
	// querying only CW company opportunities
	public final static String OPPTY_STAGE_CLOSED_WON = 'Closed Won';
	public final static Id COMPANY_OPPTY_REC_TYPE = Cache.getRecordTypeId('Opportunity', 'Company Opportunity');
	public final static String PAYMENT_INVOICE_BATCH = 'PaymentInvoiceBatch';
	public static Boolean blnException = false;
	public final static Id TIER_UPSELL_OPPTY_RT_ID = OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID;
	public final static Set<Id> SET_OPPTY_REC_IDS = new Set<Id>{ TIER_UPSELL_OPPTY_RT_ID, COMPANY_OPPTY_REC_TYPE , OpportunityUtil.ACQUISITION_OPPTY_RT_ID};

	// Error messages
	public final static String ERR_MSG_COMPANY_OPPTY_DOES_NOT_EXIST = 'Closed Won Company Opportunity not found on Account';
	public final static String PRICE_NOT_FOUND_MESSAGE = 'Rate plan Id not configured in ZP Pricing Plan';
	public final static String INVOICE_COUNT_MISMATCH = 'Payment Invoice Batch failed to kick off because of invoice count mismatch.';
	public final static String INVOICE_NOT_LINKED_TO_ACCOUNT = 'Invoice not linked to any account';
	public final static String FIRST_INVOICE_NO_ACCOUNT_JOIN_DATE = 'First Invoice No Account Join Date';

	// Parameterized constructor
	public PaymentInvoiceBatch(Invoice_Run_Log__c objRunLog) {
		Date dtPeriodStart;
		Date dtPeriodEnd;

		if (objRunLog == null) {
			// If run log from paramter is null, take most recent run log record
			this.objInvoiceRunLog = [
				SELECT Id, Workflow_Run_Number__c, Number_of_Invoice__c, Batch_Processing_State__c, Batch_Message__c, Period_Start__c, Period_End__c
				FROM Invoice_Run_Log__c
				WHERE Batch_Processing_State__c = :IntegrationUtils.QUEUED_STATE
				ORDER BY CreatedDate DESC
				LIMIT 1
			];
		} else {
			this.objInvoiceRunLog = objRunLog;
		}
		this.strWorkflowRunNumber = this.objInvoiceRunLog.Workflow_Run_Number__c;
		dtPeriodStart = this.objInvoiceRunLog.Period_Start__c;
		dtPeriodEnd = this.objInvoiceRunLog.Period_End__c;

		this.intInvoiceCount = [
			SELECT COUNT()
			FROM Payment_Invoice__c
			WHERE Workflow_Run_Number__c = :this.strWorkflowRunNumber 
		];
		//AND Period_Start_Date__c = :dtPeriodStart AND Period_End_Date__c = :dtPeriodEnd
		this.strQuery =
			'SELECT Id, Account__c, Account__r.Id, Account__r.ZP_Company_Id__c, Account__r.First_Month_Invoice_Generated__c, Account__r.Upsell_Opp_Open__c, Employee_Count__c, Contractor_Count__c, Amount__c, First_Day_of_Invoice_Month__c, Account__r.Joined_Date_Panda__c, ' +
			'Priority_Support__c, toLabel(Additional_Invoiced_Services__c), Processing_State__c, Message__c, Company_Id__c, Pricing__c, Is_First_Payment_Invoice__c, International_Employees__c, International_Contractors__c,Payment_Plan__c FROM Payment_Invoice__c ' +
			+'WHERE Processing_State__c IN :set_ProcessingStates AND Workflow_Run_Number__c = :strWorkflowRunNumber';
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext bc, List<Payment_Invoice__c> list_Invoices) {
		// Initialize Set variables
		Set<Id> set_AccountIds = new Set<Id>();
		System.debug('list_Invoices: ' + list_Invoices);
		// Initialize Map variables
		Map<Id, Opportunity> map_OpptysToUpdate = new Map<Id, Opportunity>();
		Map<Id, Account> map_AccountsToUpdate = new Map<Id, Account>();
		Map<String, String> map_dmlOpportunityUpdateErrors = new Map<String, String>();
		Map<String, String> map_dmlAccountUpdateErrors = new Map<String, String>();
		Map<Id, Opportunity> map_CompanyOpptyAccounts = new Map<Id, Opportunity>();
		Map<Id, Opportunity> map_TierUpsellOpptyAccounts = new Map<Id, Opportunity>();
		Map<Id,List<Opportunity>> map_AcquisitionOpptyAccounts = new Map<Id, List<Opportunity>>();

		try {
			if (blnException) {
				Integer intCount = 0 / 0;
			}

			System.debug('intInvoiceCount: ' + intInvoiceCount);
			System.debug('objInvoiceRunLog.Number_of_Invoice__c: ' + objInvoiceRunLog.Number_of_Invoice__c);
			// add initial validation to check if all invoices are receieved before starting batch
			// start batch only when invoice count matches
			if (intInvoiceCount == objInvoiceRunLog.Number_of_Invoice__c) {
				// Add to set of Account Ids
				for (Payment_Invoice__c objInvoice : list_Invoices) {
					set_AccountIds.add(objInvoice.Account__c);
				}

				System.debug('set_AccountIds11: ' + set_AccountIds);
				// Query CW Company Opportunities and build a map of Company Account and Company Opportunity
				for (Opportunity objOppty : [
					SELECT
						Id,
						AccountId,
						EE_Active_Count_At_Win__c,
						NumberOfEmployees__c,
						Number_of_Contractors__c,
						Payment_Invoice__c,
						ZP_First_Payment_Invoice_Amount__c,
						ZP_First_Payment_Invoice_For_Month__c,
						ZP_Company_Id__c,
						Additional_Opportunity_Services__c,
						CloseDate,
						RecordTypeId,
						Type,
						StageName,
						IsClosed
					FROM Opportunity
					WHERE AccountId IN :set_AccountIds AND StageName = :OPPTY_STAGE_CLOSED_WON AND Payment_Invoice__c = NULL AND RecordTypeId IN :SET_OPPTY_REC_IDS
				]) {
					if (objOppty.RecordTypeId == COMPANY_OPPTY_REC_TYPE) {
						map_CompanyOpptyAccounts.put(objOppty.AccountId, objOppty);
					} else if (objOppty.RecordTypeId == TIER_UPSELL_OPPTY_RT_ID) {
						map_TierUpsellOpptyAccounts.put(objOppty.AccountId, objOppty);
					} else if (objOppty.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID) {
						List<Opportunity> tempList = map_AcquisitionOpptyAccounts.get(objOppty.AccountId);
						if (tempList == null) {
							tempList = new List<Opportunity>();
						}
						tempList.add(objOppty);
						map_AcquisitionOpptyAccounts.put(objOppty.AccountId, tempList);
					}
				}

				System.debug('map_AcquisitionOpptyAccounts invoice:' + map_AcquisitionOpptyAccounts);
				// Iterate over all invoices
				for (Payment_Invoice__c objInvoice : list_Invoices) {
					if (objInvoice.Account__c == null) {
						objInvoice.Processing_State__c = IntegrationUtils.ERROR_STATE;
						objInvoice.Message__c = INVOICE_NOT_LINKED_TO_ACCOUNT;
					}

					System.debug('objInvoice.First_Month_Invoice_Generated__c:' + objInvoice.Account__r.First_Month_Invoice_Generated__c);
					System.debug('objInvoice.Is_First_Payment_Invoice__c:' + objInvoice.Is_First_Payment_Invoice__c);
					System.debug('objInvoice.Account__r.Upsell_Opp_Open__c:' + objInvoice.Account__r.Upsell_Opp_Open__c);

					if (objInvoice.Account__r.First_Month_Invoice_Generated__c && !objInvoice.Account__r.Upsell_Opp_Open__c) {
						// skip invoice record if account is already invoiced & upsell flag is false
						continue;
					}

					System.debug('objInvoice.Pricing__c: ' + objInvoice.Pricing__c);
					if (String.isBlank(objInvoice.Pricing__c)) {
						//objInvoice.Processing_State__c = IntegrationUtils.ERROR_STATE;
						//objInvoice.Message__c = PRICE_NOT_FOUND_MESSAGE;
						//continue;
					}
					
					if (!objInvoice.Account__r.First_Month_Invoice_Generated__c && objInvoice.Is_First_Payment_Invoice__c) {
						// if first month invoice is not generated, attach company opportunity
						// sync payment invoice with company opportunity
						// if map of contains payment invoice account, update opportunity with invoice data
						System.debug('map_CompanyOpptyAccounts.keySet(): ' + map_CompanyOpptyAccounts.keySet());
						System.debug('objInvoice.Account__c: ' + objInvoice.Account__c);

						System.debug('map_AcquisitionOpptyAccounts.keySet(): ' + map_AcquisitionOpptyAccounts);
						if (map_CompanyOpptyAccounts.containsKey(objInvoice.Account__c)) {
							// update opportunity with invoice data
							Opportunity objOppty = map_CompanyOpptyAccounts.get(objInvoice.Account__c);

							objOppty.EE_Active_Count_At_Win__c = objInvoice.Employee_Count__c;
							objOppty.NumberOfEmployees__c = objInvoice.Employee_Count__c;
							objOppty.Number_of_Contractors__c = objInvoice.Contractor_Count__c;
							objOppty.Payment_Invoice__c = objInvoice.Id;
							objOppty.ZP_First_Payment_Invoice_Amount__c = objInvoice.Amount__c;
							objOppty.ZP_First_Payment_Invoice_For_Month__c = objInvoice.First_Day_of_Invoice_Month__c;
							objOppty.Additional_Opportunity_Services__c = objInvoice.Additional_Invoiced_Services__c;

							map_OpptysToUpdate.put(objOppty.Id, objOppty);

							map_AccountsToUpdate.put(
								objInvoice.Account__r.Id,
								new Account(Id = objInvoice.Account__c, ZP_Company_Id__c = objInvoice.Account__r.ZP_Company_Id__c, First_Month_Invoice_Generated__c = true)
							);
						}
						
						if (!map_AcquisitionOpptyAccounts.isEmpty()) {
							
							if (map_AcquisitionOpptyAccounts.containsKey(objInvoice.Account__c)) {
								Boolean blnIsOpenWinBack = false;
								Boolean blnIsClosedAcquisition = false;
								Boolean blnIsOpenAcquisition = false;
								Opportunity objOpenAcquisitionOppty = null;
								Opportunity objClosedAcquisitionOppty = null;
								Opportunity objOpenWinBackOppty = null;
								for (Opportunity objAcquisitionOppty : map_AcquisitionOpptyAccounts.get(objInvoice.Account__c)) {
									if (objAcquisitionOppty.StageName != OPPTY_STAGE_CLOSED_WON && objAcquisitionOppty.Type == 'New Business') {
										blnIsOpenAcquisition = true;
										objOpenAcquisitionOppty = objAcquisitionOppty;
									} else if (objAcquisitionOppty.StageName == 'Closed Won' && objAcquisitionOppty.Type == 'New Business') {
										blnIsClosedAcquisition = true;
										objClosedAcquisitionOppty = objAcquisitionOppty;
									} else if (!objAcquisitionOppty.IsClosed && objAcquisitionOppty.Type == 'Winback') {
										blnIsOpenWinBack = true;
										objOpenWinBackOppty = objAcquisitionOppty;
									}
								}
	
								System.debug('objOpenAcquisitionOppty: ' + objOpenAcquisitionOppty);
								System.debug('objClosedAcquisitionOppty: ' + objClosedAcquisitionOppty);
								System.debug('objOpenWinBackOppty: ' + objOpenWinBackOppty);
								System.debug('blnIsOpenAcquisition: ' + blnIsOpenAcquisition);
								System.debug('blnIsClosedAcquisition: ' + blnIsClosedAcquisition);
								System.debug('blnIsOpenWinBack: ' + blnIsOpenWinBack);
								System.debug('objInvoice: ' + objInvoice);
	
								if (blnIsOpenWinBack) {
									objOpenWinBackOppty = mapOpportunityFields(objOpenWinBackOppty, objInvoice);
									objOpenWinBackOppty.CloseDate = System.Today();
									objOpenWinBackOppty.StageName = OPPTY_STAGE_CLOSED_WON;
									map_OpptysToUpdate.put(objOpenWinBackOppty.Id, objOpenWinBackOppty);
								} else if (blnIsClosedAcquisition && !blnIsOpenWinBack) {
									objClosedAcquisitionOppty = mapOpportunityFields(objClosedAcquisitionOppty, objInvoice);
									map_OpptysToUpdate.put(objClosedAcquisitionOppty.Id, objClosedAcquisitionOppty);
								} else if (blnIsOpenAcquisition && !blnIsOpenWinBack && !blnIsClosedAcquisition) {
									objOpenAcquisitionOppty = mapOpportunityFields(objOpenAcquisitionOppty, objInvoice);
									objOpenAcquisitionOppty.CloseDate = System.Today();
									objOpenAcquisitionOppty.StageName = OPPTY_STAGE_CLOSED_WON;
									map_OpptysToUpdate.put(objOpenAcquisitionOppty.Id, objOpenAcquisitionOppty);
								}
							}
						} else {
							// if closed-won company opportunity does not exist, check if Account has joined date
							if (objInvoice.Account__r.Joined_Date_Panda__c == null) {
								objInvoice.Processing_State__c = IntegrationUtils.PROCESSED_STATE;
								objInvoice.Message__c = FIRST_INVOICE_NO_ACCOUNT_JOIN_DATE;
							}
						}
					} else if (objInvoice.Account__r.Upsell_Opp_Open__c) {
						// if first month is generated & upsell opp open is true, attach Cross-Sell and Upsell opportunity
						// sync payment invoice with Cross-Sell and Upsell opportunity
						// if map of contains payment invoice account, update opportunity with invoice data

						if (map_TierUpsellOpptyAccounts.containsKey(objInvoice.Account__c)) {
							// update opportunity with invoice data
							Opportunity objOppty = map_TierUpsellOpptyAccounts.get(objInvoice.Account__c);

							if (objOppty.CloseDate != null && objInvoice.First_Day_of_Invoice_Month__c != null) {
								Date dtOpptyCloseDate = objOppty.CloseDate;
								Date dtInvoiceFirstMonth = objInvoice.First_Day_of_Invoice_Month__c;

								// check opportunity close date matches with invoice date
								if (dtOpptyCloseDate.month() == dtInvoiceFirstMonth.month() && dtOpptyCloseDate.year() == dtInvoiceFirstMonth.year()) {
									objOppty.NumberOfEmployees__c = objInvoice.Employee_Count__c;
									objOppty.Number_of_Contractors__c = objInvoice.Contractor_Count__c;
									objOppty.Payment_Invoice__c = objInvoice.Id;
									objOppty.Additional_Opportunity_Services__c = objInvoice.Additional_Invoiced_Services__c;
									objOppty.International_Employees__c = objInvoice.International_Employees__c;
									objOppty.International_Contractors__c = objInvoice.International_Contractors__c;

									map_OpptysToUpdate.put(objOppty.Id, objOppty);

									map_AccountsToUpdate.put(objInvoice.Account__r.Id, new Account(Id = objInvoice.Account__c, Upsell_Opp_Open__c = false));
								}
							}
						}
					}
				}

				// update opportunties with invoice data
				System.debug('map_OpptysToUpdate21: ' + map_OpptysToUpdate);
				if (!map_OpptysToUpdate.isEmpty()) {
					List<Database.SaveResult> saveResult = Database.update(map_OpptysToUpdate.values(), false);
					map_dmlOpportunityUpdateErrors = Utils.processSaveResult(saveResult, map_OpptysToUpdate.values(), 'ZP_Company_Id__c', true, 'PaymentInvoiceBatch-execute');
				}

				// update accounts and set first month invoice has been generated
				if (!map_AccountsToUpdate.isEmpty()) {
					AccountTriggerHelper.skipTrigger = true;
					List<Database.SaveResult> saveResult = Database.update(map_AccountsToUpdate.values(), false);
					map_dmlAccountUpdateErrors = Utils.processSaveResult(saveResult, map_AccountsToUpdate.values(), 'ZP_Company_Id__c', true, 'PaymentInvoiceBatch-execute');
					AccountTriggerHelper.skipTrigger = false;
				}

				// update processing state on payment invoices
				for (Payment_Invoice__c objInvoice : list_Invoices) {
					// check if there are any DML errors related to opportunity and account
					if (map_dmlOpportunityUpdateErrors.containsKey(objInvoice.Company_Id__c)) {
						objInvoice.Processing_State__c = IntegrationUtils.ERROR_STATE;
						objInvoice.Message__c = map_dmlOpportunityUpdateErrors.get(objInvoice.Company_Id__c);
					}

					if (map_dmlAccountUpdateErrors.containsKey(objInvoice.Company_Id__c)) {
						objInvoice.Processing_State__c = IntegrationUtils.ERROR_STATE;
						objInvoice.Message__c = map_dmlAccountUpdateErrors.get(objInvoice.Company_Id__c);
					}

					if (objInvoice.Processing_State__c == IntegrationUtils.QUEUED_STATE) {
						objInvoice.Processing_State__c = IntegrationUtils.PROCESSED_STATE;
						objInvoice.Message__c = IntegrationUtils.PROCESSED_STATE;
					}

					if (String.isNotBlank(objInvoice.Message__c) && objInvoice.Message__c.length() > 255) {
						objInvoice.Message__c = objInvoice.Message__c.subString(0, 255);
					}
				}
				PaymentInvoiceTriggerHandler.blnSkipTrigger = true;
				update list_Invoices;
			} else {
				// set processing state to Error and abort batch job
				objInvoiceRunLog.Batch_Processing_State__c = IntegrationUtils.ERROR_STATE;
				objInvoiceRunLog.Batch_Message__c = INVOICE_COUNT_MISMATCH + 'Expected Invoices: ' + objInvoiceRunLog.Number_of_Invoice__c + ', Available Invoices: ' + intInvoiceCount;
				update objInvoiceRunLog;

				// Abort current job
				List<AsyncApexJob> list_jobs = [
					SELECT Id, JobItemsProcessed, TotalJobItems
					FROM AsyncApexJob
					WHERE Status IN :list_BatchPendingStatus AND ApexClass.Name IN (:PAYMENT_INVOICE_BATCH)
					LIMIT 150
				];

				// Add dummy apex job during test runs
				if (Test.isRunningTest()) {
					list_jobs.add(new AsyncApexJob());
				}
				if (!list_jobs.isEmpty()) {
					try {
						for (AsyncApexJob job : list_jobs) {
							System.abortJob(job.Id);
						}
					} catch (Exception objException) {
						ExceptionLogUtil.logException('PaymentInvoiceBatch', 'execute', null, objException);
					}
				}
				return;
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException(PAYMENT_INVOICE_BATCH, 'execute', null, objException);
			String strException = objException.getMessage();
			objInvoiceRunLog.Batch_Processing_State__c = IntegrationUtils.ERROR_STATE;
			objInvoiceRunLog.Batch_Message__c = 'Exception: ' + objException.getMessage().left(255);
		}
	}

	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];
		if (String.isBlank(objInvoiceRunLog.Batch_Processing_State__c) || objInvoiceRunLog.Batch_Processing_State__c == IntegrationUtils.QUEUED_STATE) {
			if (objAsyncJob.NumberOfErrors == 0) {
				objInvoiceRunLog.Batch_Processing_State__c = IntegrationUtils.PROCESSED_STATE;
				objInvoiceRunLog.Batch_Message__c = IntegrationUtils.PROCESSED_STATE;
			} else if (objAsyncJob.NumberOfErrors > 0) {
				objInvoiceRunLog.Batch_Processing_State__c = IntegrationUtils.ERROR_STATE;
				objInvoiceRunLog.Batch_Message__c = 'Payment Invoice Batch failed with ' + objAsyncJob.NumberOfErrors + ' errors. Please check error records and re-process them';
			}
		}
		update objInvoiceRunLog;
	}

	global void execute(SchedulableContext SC) {
		Configuration_Settings__c config = Configuration_Settings__c.getOrgDefaults();
		Integer intBatchSize = config.Payment_Invoice_Batch_Size__c != null ? config.Payment_Invoice_Batch_Size__c.intValue() : 1;

		Database.executeBatch(new PaymentInvoiceBatch(null), intBatchSize);
	}

	public Opportunity mapOpportunityFields(Opportunity objOppty, Payment_Invoice__c objInvoice) {
		objOppty.NumberOfEmployees__c = objInvoice.Employee_Count__c;
		objOppty.Number_of_Contractors__c = objInvoice.Contractor_Count__c;
		objOppty.Payment_Invoice__c = objInvoice.Id;
		objOppty.Additional_Opportunity_Services__c = objInvoice.Additional_Invoiced_Services__c;
		objOppty.International_Employees__c = objInvoice.International_Employees__c;
		objOppty.International_Contractors__c = objInvoice.International_Contractors__c;
		objOppty.ZP_First_Payment_Invoice_Amount__c = objInvoice.Amount__c;
		objOppty.ZP_First_Payment_Invoice_For_Month__c = objInvoice.First_Day_of_Invoice_Month__c;
		objOppty.Current_Tier__c = objInvoice.Payment_Plan__c;
		objOppty.EE_Active_Count_At_Win__c = objInvoice.Employee_Count__c;
		return objOppty;
	}
}