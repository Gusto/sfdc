public with sharing class ZPNachaEntryReturnsTriggerHelper {
    
    public static boolean skipTrigger = false;
    public static integer counter = 0;
    public static boolean queue = false;
    // We are expecting for the following String to be part of the Integration Key on case. 
    public static final String strPayrollPrefix = 'zenpayroll-payroll-';
    public static final String strContractorPaymentPrefix = 'zenpayroll-contractor-payment-';
    public static final String strInternationalContractorPaymentPrefix = 'zenpayroll-international-contractor-payment-';
    public static final String PAYROLL = 'Payroll';
    public static final String CONTRACTOR_PAYMENT = 'ContractorPayment';
    public static final String INT_CONTRACTOR_PAYMENT = 'InternationalContractorPayment';
    public static Boolean blnBypassContinue = false; //for testing only

    public void OnBeforeInsert(List<ZP_Nacha_Entry_Returns__c> nachaReturns) {
        counter++;
        if (queue == true) {
            processInformation(nachaReturns);
        } else {
            for (ZP_Nacha_Entry_Returns__c entry : nachaReturns) {
                entry.Processing_Status__c = IntegrationUtils.QUEUED_STATE;
            }
        }
    }
    
    public void OnAfterInsert(Map<Id, ZP_Nacha_Entry_Returns__c> newNachaReturnsMap) {
        if (queue == false) {
            ZPNachaEntryReturnsQueue  insertJob = new ZPNachaEntryReturnsQueue (newNachaReturnsMap.values());
            ID jobID = System.enqueueJob(insertJob);
        } else {
            //upsertNachaEntryReturnRec(newNachaReturnsMap.values());
        }
    }
    
    @future
    public static void OnAfterInsertAsync(Set<Id> insertedNachaReturnsIDs) {
        
    }
    
    public void OnBeforeUpdate(
        Map<Id, ZP_Nacha_Entry_Returns__c> oldNachaReturnsMap,
        Map<Id, ZP_Nacha_Entry_Returns__c> newNachaReturnsMap
    ) {
        counter++;
        
        if (queue == true) {
            processInformation(newNachaReturnsMap.values());
        } else {
            for (ZP_Nacha_Entry_Returns__c entry : newNachaReturnsMap.values()) {
                entry.Processing_Status__c = IntegrationUtils.QUEUED_STATE;
            }
        }
    }
    
    public void OnAfterUpdate(
        Map<Id, ZP_Nacha_Entry_Returns__c> oldNachaReturnsMap,
        Map<Id, ZP_Nacha_Entry_Returns__c> newNachaReturnsMap
    ) {
        if (queue == false) {
            ZPNachaEntryReturnsQueue insertJob = new ZPNachaEntryReturnsQueue(newNachaReturnsMap.values());
            ID jobID = System.enqueueJob(insertJob);
        }
    }
    
    @future
    public static void OnAfterUpdateAsync(Set<Id> updatedNachaReturnsIDs) {
        
    }
    
    public void OnBeforeDelete(ZP_Nacha_Entry_Returns__c[] nachaReturnsToDelete, Map<Id, ZP_Nacha_Entry_Returns__c> oldNachaReturnsMap) {
        counter++;
    }
    
    public void OnAfterDelete(ZP_Nacha_Entry_Returns__c[] deletedNachaReturns, Map<Id, ZP_Nacha_Entry_Returns__c> oldNachaReturnsMap) {
        counter++;
    }
    
    @future
    public static void OnAfterDeleteAsync(Set<Id> deletedNachaReturnsIDs) {
        
    }
    
    public void OnUndelete(ZP_Nacha_Entry_Returns__c[] restoredNachaReturns) {
        counter++;
    }
    
    // this method is called from the queue functionality
    public void processInformation(List<ZP_Nacha_Entry_Returns__c> list_ZPNachaEntryReturns) {
        
        if (list_ZPNachaEntryReturns == null) {
            return;
        }
        
        Set<String> eventIdSet = new Set<String>();
        Set<String> companyIdSet = new Set<String>();
        Map<String, String> debitFailureNachaMap = new Map<String, String>();
        Set<String> firstTimeDebitFailureNachaSet = new Set<String>();
        Map<String, String> map_EventIdZPNacha = new Map<String, String>();
        
        /** to search the cases and additional information we are storing event ID (with prefix mentioned on top)
        * and company Id **/
        for (ZP_Nacha_Entry_Returns__c objZPNachaEntryReturn : list_ZPNachaEntryReturns) {
            eventIdSet.add(strPayrollPrefix + objZPNachaEntryReturn.Event_Id__c);
            eventIdSet.add(strContractorPaymentPrefix + objZPNachaEntryReturn.Event_Id__c);
            eventIdSet.add(strInternationalContractorPaymentPrefix + objZPNachaEntryReturn.Event_Id__c);
            companyIdSet.add(objZPNachaEntryReturn.Company_Id__c);
            
            if (String.isNotBlank(objZPNachaEntryReturn.Error_Code__c) && objZPNachaEntryReturn.Error_Code__c == 'R01') {
                String tempStr = objZPNachaEntryReturn.Event_Id__c + objZPNachaEntryReturn.Transaction_Type__c + objZPNachaEntryReturn.Amount__c;
                //payroll ID, transaction type, and NACHA amount
                debitFailureNachaMap.put(objZPNachaEntryReturn.Event_Id__c, tempStr);
                map_EventIdZPNacha.put(objZPNachaEntryReturn.Event_Id__c, objZPNachaEntryReturn.Id);
            }
        }
        
        if (!eventIdSet.isEmpty()) {
            
            Map<String, Case> integrationKeyCaseRecMap = new Map<String, Case>();
            Map<String, String> signatoryUserIdCompanyIdMap = new Map<String, String>();
            Map<String, String> companyIdSinatoryContactIdMap = new Map<String, String>();
            Map<String, Account> companyIdAccountIdMap = new Map<String, Account>();
            Map<String, Case> integrationKeytoUpsertCaseMap = new Map<String, Case>();
            
            firstTimeDebitFailureNachaSet = getFirstTimeDebitFailureNachaIds(debitFailureNachaMap, map_EventIdZPNacha, eventIdSet);
            
            //querying already present case records based on Integration Key
            for (Case rec : [SELECT Id, Integration_Key__c, Bank_Error_Code__c, 
                            Initial_Recovery_Amount__c, Recovery_Case_ID__c, 
                            Expedite_Reason__c, Event_Type__c, Event_ID__c, 
                            Subject, Origin, AccountId, ContactId, OwnerId
                            FROM Case 
                            WHERE Integration_Key__c IN :eventIdSet]
            ) {
                integrationKeyCaseRecMap.put(rec.Integration_Key__c, rec);
            }
            
            // querying zp user role to finnaly get a list of companies based on Company_id present in the zp User role record.
            for (ZP_User_Role__c rec : [SELECT Id, User_Id__c, Company_Id__c, Type__c FROM ZP_User_Role__c 
                                        WHERE Company_Id__c IN :companyIdSet]) {
                                            if (rec.Type__c.indexOf('Signatory') > -1 ) {
                                                signatoryUserIdCompanyIdMap.put(rec.User_Id__c, rec.Company_Id__c);
                                            }
                                        }
            
            for (Account rec : [SELECT Id, ZP_Company_ID__c, Name FROM Account WHERE ZP_Company_ID__c IN :companyIdSet]) {
                companyIdAccountIdMap.put(rec.ZP_Company_ID__c, rec);
            }
            
            /*
                We need signatory contact to attach to the new case.
                We are using ZP_User_id for the realted company_id  via ZP User role object details 
            */
            if (signatoryUserIdCompanyIdMap.keySet().size() > 0) {
                for (Contact con : [SELECT Id, ZP_User_Id__c FROM Contact WHERE ZP_User_Id__c IN :signatoryUserIdCompanyIdMap.keySet()]) {
                    if (signatoryUserIdCompanyIdMap.containsKey(con.ZP_User_Id__c)) {
                        companyIdSinatoryContactIdMap.put(signatoryUserIdCompanyIdMap.get(con.ZP_User_Id__c),con.id);
                    }
                }
            }
            
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule = true;
            //Alex: get new recovery queue for contractor payments
            String strRecoveryFasterContractorQueueId = GlobalQueryHelper.getQueueIdByName('Recovery Faster Contractor Payments');
            
            /*
                AFter getting all the required information we are looping through event triggering "ZP Nacha Entry Return" records
                In case there is already a case present based on matching "Integartion Key" we are updating or creating a new case rec.
            */
            for (ZP_Nacha_Entry_Returns__c rec : list_ZPNachaEntryReturns) {
                Case objCase;
                
                // BY: PR, Desc: If this the first occurance of the R01 Zp Nacha record we do not want to create the Nacha
                if (firstTimeDebitFailureNachaSet.contains(rec.Event_Id__c) && blnBypassContinue == false) {
                    continue;
                }
                
                if (
                    integrationKeyCaseRecMap.containsKey(strPayrollPrefix + rec.Event_Id__c) ||
                    integrationKeyCaseRecMap.containsKey(strContractorPaymentPrefix + rec.Event_Id__c) ||
                    integrationKeyCaseRecMap.containsKey(strInternationalContractorPaymentPrefix + rec.Event_Id__c)
                ) {
                    if (integrationKeyCaseRecMap.containsKey(strPayrollPrefix + rec.Event_Id__c)) {
                        objCase = integrationKeyCaseRecMap.get(strPayrollPrefix + rec.Event_Id__c);
                    } else if (integrationKeyCaseRecMap.containsKey(strContractorPaymentPrefix + rec.Event_Id__c)) {
                        objCase = integrationKeyCaseRecMap.get(strContractorPaymentPrefix + rec.Event_Id__c);
                    } else if (integrationKeyCaseRecMap.containsKey(strInternationalContractorPaymentPrefix + rec.Event_Id__c)) {
                        objCase = integrationKeyCaseRecMap.get(strInternationalContractorPaymentPrefix + rec.Event_Id__c);
                    }
                    
                    // append unique error code
                    if (objCase.Bank_Error_Code__c == null) {
                        objCase.Bank_Error_Code__c = rec.Error_Code__c;
                    } else {
                        Set<String> tempSet = new Set<String>();
                        objCase.Bank_Error_Code__c.replaceAll(' ', '');
                        tempSet.addAll(objCase.Bank_Error_Code__c.split(','));
                        tempSet.add(rec.Error_Code__c);
                        List<String> tempList = new List<String>();
                        tempList.addAll(tempSet);
                        objCase.Bank_Error_Code__c = String.join(tempList, ',');
                    }                       
                    
                    if (objCase.AccountId == null && companyIdAccountIdMap.containsKey(rec.Company_Id__c)) {
                        objCase.AccountId = companyIdAccountIdMap.get(rec.Company_Id__c).Id;
                    }
                    
                    if (objCase.Subject == null && companyIdAccountIdMap.containsKey(rec.Company_Id__c)) {
                        objCase.Subject = companyIdAccountIdMap.get(rec.Company_Id__c).Name + '\'s: Payroll Debit Failed';
                    }
                    
                    if (objCase.ContactId == null && companyIdSinatoryContactIdMap.containsKey(rec.Company_Id__c)) {
                        objCase.ContactId = companyIdSinatoryContactIdMap.get(rec.Company_Id__c);
                    }
                    
                    objCase.Origin = 'Panda';
                    
                    if (String.isBlank(objCase.Expedite_Reason__c)) {
                        objCase.Expedite_Reason__c = rec.Expedite_Reason__c;
                    }
                    
                    if (String.isBlank(objCase.Event_Type__c)) {
                        if (rec.Event_Type__c == CONTRACTOR_PAYMENT) {
                            objCase.Event_Type__c = CONTRACTOR_PAYMENT;
                        } else if (rec.Event_Type__c.contains(INT_CONTRACTOR_PAYMENT)) {
                            objCase.Event_Type__c = INT_CONTRACTOR_PAYMENT;
                        } else {
                            objCase.Event_Type__c = rec.Event_Type__c.replaceAll('_', ' ');
                        }
                    } 
                    
                    if (String.isBlank(objCase.Event_ID__c)) {
                        objCase.Event_ID__c = rec.Event_Id__c;
                    }

                    if (objCase.OwnerId == GlobalQueryHelper.getQueueIdByName('Recovery Cases - Non-actionable')) {
                        if (
                            rec.Event_Type__c == CONTRACTOR_PAYMENT || 
                            rec.Event_Type__c.contains(INT_CONTRACTOR_PAYMENT)
                        ) {
                            if (String.isNotBlank(strRecoveryFasterContractorQueueId)) {
                                objCase.OwnerId = strRecoveryFasterContractorQueueId;
                            }
                        } else {
                            String strRecoveryCaseQueueId = GlobalQueryHelper.getQueueIdByName('Recovery Case');
                            if (String.isNotBlank(strRecoveryCaseQueueId)) {
                                objCase.OwnerId = strRecoveryCaseQueueId;
                            }
                        }
                    }
                } else {
                    objCase = new Case();
                    if (rec.Event_Type__c == CONTRACTOR_PAYMENT && String.isNotBlank(strRecoveryFasterContractorQueueId)) {
                        objCase.OwnerId = strRecoveryFasterContractorQueueId;
                    } else {
                        objCase.setOptions(dmo);
                    }

                    String strPrefix = '';
                    if (rec.Event_Type__c == PAYROLL) {
                        strPrefix = strPayrollPrefix;
                    } else if (rec.Event_Type__c == CONTRACTOR_PAYMENT) {
                        strPrefix = strContractorPaymentPrefix;
                    } else if (rec.Event_Type__c.contains(INT_CONTRACTOR_PAYMENT)) {
                        strPrefix = strInternationalContractorPaymentPrefix;
                    }       

                    objCase.Integration_Key__c = strPrefix + rec.Event_Id__c;
                    objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Recovery Cases');
                    objCase.Type = 'Recovery';
                    objCase.Origin = 'Panda';
                    objCase.Status = 'New';

                    if (companyIdAccountIdMap.containsKey(rec.Company_Id__c)) {
                        objCase.AccountId = companyIdAccountIdMap.get(rec.Company_Id__c).Id;
                        objCase.Subject = companyIdAccountIdMap.get(rec.Company_Id__c).Name + '\'s: Payroll Debit Failed';
                    }
                    
                    if (companyIdSinatoryContactIdMap.containsKey(rec.Company_Id__c)) {
                        objCase.ContactId = companyIdSinatoryContactIdMap.get(rec.Company_Id__c);
                    }
                    
                    objCase.Expedite_Reason__c = rec.Expedite_Reason__c;
                    if (rec.Event_Type__c == CONTRACTOR_PAYMENT) {
                        objCase.Event_Type__c = CONTRACTOR_PAYMENT;
                    } else if (rec.Event_Type__c.contains(INT_CONTRACTOR_PAYMENT)) {
                        objCase.Event_Type__c = INT_CONTRACTOR_PAYMENT;
                    } else {
                        objCase.Event_Type__c = rec.Event_Type__c.replaceAll('_', ' ');
                    }
                    objCase.Event_ID__c = rec.Event_Id__c;
                    objCase.Bank_Error_Code__c = rec.Error_Code__c;
                }
                
                integrationKeytoUpsertCaseMap.put(objCase.Integration_Key__c, objCase);
            }
            
            Map<String, String> dmlUpsertErrorsMap = new Map <String, String>();
            
            if (integrationKeytoUpsertCaseMap.values().size() > 0) {
                List<Database.UpsertResult> saveResult = Database.upsert(integrationKeytoUpsertCaseMap.values(), false);
                dmlUpsertErrorsMap = Utils.processUpsertResult(
                    saveResult,
                    integrationKeytoUpsertCaseMap.values(),
                    'Integration_Id__c',
                    true,
                    'ZPNachaEntryReturnsTriggerHelper-processInformation'
                );
            }
            
            // following code is updating the ZP Nacha Entry Returns processing Status field.
            for (ZP_Nacha_Entry_Returns__c objZPNachaEntryReturns : list_ZPNachaEntryReturns) {
                if (dmlUpsertErrorsMap.containsKey(strPayrollPrefix + objZPNachaEntryReturns.Event_ID__c)) {
                    setProcessingState(IntegrationUtils.ERROR_STATE, dmlUpsertErrorsMap.get(strPayrollPrefix + objZPNachaEntryReturns.Event_ID__c), objZPNachaEntryReturns);
                } else if (dmlUpsertErrorsMap.containsKey(strContractorPaymentPrefix + objZPNachaEntryReturns.Event_ID__c)) {
                    setProcessingState(IntegrationUtils.ERROR_STATE, dmlUpsertErrorsMap.get(strContractorPaymentPrefix + objZPNachaEntryReturns.Event_ID__c), objZPNachaEntryReturns);
                } else if (dmlUpsertErrorsMap.containsKey(strInternationalContractorPaymentPrefix + objZPNachaEntryReturns.Event_ID__c)) {
                    setProcessingState(IntegrationUtils.ERROR_STATE, dmlUpsertErrorsMap.get(strInternationalContractorPaymentPrefix + objZPNachaEntryReturns.Event_ID__c), objZPNachaEntryReturns);
                } else if (dmlUpsertErrorsMap.containsKey('' + objZPNachaEntryReturns.Event_ID__c)) {
                    setProcessingState(IntegrationUtils.ERROR_STATE, dmlUpsertErrorsMap.get('' + objZPNachaEntryReturns.Event_ID__c), objZPNachaEntryReturns);
                } else {
                    setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Information is successfully processed', objZPNachaEntryReturns);
                    if (!firstTimeDebitFailureNachaSet.contains(objZPNachaEntryReturns.Event_ID__c)) {
                        if (integrationKeytoUpsertCaseMap.containsKey(strPayrollPrefix + objZPNachaEntryReturns.Event_ID__c)) {
                            objZPNachaEntryReturns.Case_Id__c = integrationKeytoUpsertCaseMap.get(strPayrollPrefix + objZPNachaEntryReturns.Event_ID__c).Id; 
                        } else if (integrationKeytoUpsertCaseMap.containsKey(strContractorPaymentPrefix + objZPNachaEntryReturns.Event_ID__c)) {
                        	objZPNachaEntryReturns.Case_Id__c = integrationKeytoUpsertCaseMap.get(strContractorPaymentPrefix + objZPNachaEntryReturns.Event_ID__c).Id;    
                        } else if (integrationKeytoUpsertCaseMap.containsKey(strInternationalContractorPaymentPrefix + objZPNachaEntryReturns.Event_ID__c)) {
                            objZPNachaEntryReturns.Case_Id__c = integrationKeytoUpsertCaseMap.get(strInternationalContractorPaymentPrefix + objZPNachaEntryReturns.Event_ID__c).Id;
                        }
                    }                
                }
            }
        }
        // once case part is completed we want to create synced Nacha Entry Return records
        upsertNachaEntryReturnRec(list_ZPNachaEntryReturns);
    }
    
    private ZP_Nacha_Entry_Returns__c setProcessingState(String ProcessingState, String message, ZP_Nacha_Entry_Returns__c returnInfo) {
        returnInfo.Processing_Status__c = ProcessingState;
        returnInfo.Message__c = message;
        returnInfo.Last_Processed__c = System.now();
        return returnInfo;
    }
    
    /*
        This method is accepting list of  "zp nacha entry return" records as parameters
        This method is Creating/updating "Nacha Entry Return" object records based on Event Id
    */
    public void upsertNachaEntryReturnRec(List<ZP_Nacha_Entry_Returns__c> zpNachaList) {
        
        List<Nacha_Entry_Return__c> nachaListToInsert = new List<Nacha_Entry_Return__c>();
        
        if (zpNachaList != null && zpNachaList.size() > 0) {
            
            Map<String, String> caseIdAccoutIdMap = new Map<String, String>();
            Set<String> nachaIdSet = new Set<String>();
            Map<String, Nacha_Entry_Return__c> nachaIdNachRecMap = new Map<String, Nacha_Entry_Return__c>();
            
            for (ZP_Nacha_Entry_Returns__c objZPNachaEntryReturn : zpNachaList) {
                if (objZPNachaEntryReturn.Case_Id__c != null) {
                    caseIdAccoutIdMap.put(objZPNachaEntryReturn.Case_Id__c, '');
                }
                if (objZPNachaEntryReturn.Id__c != null) {
                    nachaIdSet.add(objZPNachaEntryReturn.Id__c);
                }
            }
            
            if (nachaIdSet.size() > 0) {
                
                for (Nacha_Entry_Return__c objNachaEntryReturn : [SELECT Id, Event_Id__c, Account__c, Amount__c, Case__c, Company_Id__c, Id__c, External_Key__c,
                                                                  Created_At__c, Error_Code__c, Error_Code_Description__c, Event_Type__c, Expedite_Reason__c,
                                                                  Nacha_Entry_Id__c, Processing_State__c, Return_Code_At__c, Updated_At__c
                                                                  FROM Nacha_Entry_Return__c WHERE Id__c IN :nachaIdSet]
                    ) {
                        nachaIdNachRecMap.put(objNachaEntryReturn.Id__c, objNachaEntryReturn);
                    }
                
                for (Case objCase : [SELECT Id, AccountId FROM Case WHERE Id IN :caseIdAccoutIdMap.keySet()]) {
                    caseIdAccoutIdMap.put(objCase.Id, objCase.AccountId);
                }
                
                for (ZP_Nacha_Entry_Returns__c objZPNachaEntryReturn : zpNachaList) {
                    Nacha_Entry_Return__c newRec;
                    if (nachaIdNachRecMap.containsKey(objZPNachaEntryReturn.Id__c)) {
                        newRec = nachaIdNachRecMap.get(objZPNachaEntryReturn.Id__c);
                    } else {
                        newRec = new Nacha_Entry_Return__c();
                    }
                    
                    newRec.Id__c = objZPNachaEntryReturn.Id__c;
                    newRec.External_Key__c = objZPNachaEntryReturn.External_Key__c;
                    newRec.Account__c = (caseIdAccoutIdMap.containsKey(objZPNachaEntryReturn.Case_Id__c) && caseIdAccoutIdMap.get(objZPNachaEntryReturn.Case_Id__c) != null ? caseIdAccoutIdMap.get(objZPNachaEntryReturn.Case_Id__c) : null);
                    newRec.Amount__c = objZPNachaEntryReturn.Amount__c;
                    newRec.Created_At__c = objZPNachaEntryReturn.Created_At__c;
                    newRec.Case__c = objZPNachaEntryReturn.Case_Id__c;
                    newRec.Company_Id__c = objZPNachaEntryReturn.Company_Id__c;
                    newRec.Error_Code__c = objZPNachaEntryReturn.Error_Code__c;
                    newRec.Error_Code_Description__c = objZPNachaEntryReturn.Error_Code_Description__c;
                    newRec.Event_Id__c = objZPNachaEntryReturn.Event_Id__c;
                    newRec.Event_Type__c = objZPNachaEntryReturn.Event_Type__c;
                    newRec.Expedite_Reason__c = objZPNachaEntryReturn.Expedite_Reason__c;
                    newRec.Nacha_Entry_Id__c = objZPNachaEntryReturn.Nacha_Entry_Id__c;
                    newRec.Return_Code_At__c = objZPNachaEntryReturn.Return_Code_At__c;
                    newRec.Updated_At__c = objZPNachaEntryReturn.Updated_At__c;
                    if (objZPNachaEntryReturn.Processing_State__c != null) {
                        List<String> list_ProcessingStateSplits = objZPNachaEntryReturn.Processing_State__c.split('_');
                        String strCamelCase = '';
                        for (String strProcessingStateSplit : list_ProcessingStateSplits) {
                            strCamelCase += strProcessingStateSplit.subString(0, 1).toUpperCase() + strProcessingStateSplit.subString(1, strProcessingStateSplit.length()) + ' ';
                        }
                        newRec.Processing_State__c = strCamelCase;
                    }
                    if (String.isBlank(objZPNachaEntryReturn.Case_Id__c)) {
                        newRec.First_Debit_Failure_Nacha__c = true;
                    }
                    
                    newRec.ZP_Nacha_Entry_Return__c = objZPNachaEntryReturn.Id;
                    nachaListToInsert.add(newRec);
                }
            }         
        }
        
        Map < String, String > dmlUpsertErrorsMap = new Map < String, String >();
        
        if (nachaListToInsert.size() > 0) {
            List<Database.UpsertResult> saveResult = database.upsert(nachaListToInsert,false);
            dmlUpsertErrorsMap = Utils.processUpsertResult(
                saveResult,
                nachaListToInsert,
                'Event_ID__c',
                true,
                'ZPNachaEntryReturnsTriggerHelper-upsertNachaEntryReturnRec'
            );
        }
        
        // following code is updating the ZP Nacha Entry Returns processing Status field.
        for (ZP_Nacha_Entry_Returns__c rec : zpNachaList) {
            if (dmlUpsertErrorsMap.containsKey(rec.Event_ID__c)) {
                setProcessingState(IntegrationUtils.ERROR_STATE,dmlUpsertErrorsMap.get(rec.Event_ID__c), rec);
            } 
        }        
    }   
    
    //By: PR, Date:7/9/19, Desc: We are trying to those ZP nacha records that already have a nacha entry in the org
    public Set<String> getFirstTimeDebitFailureNachaIds(Map<String, String> debitFailureNachaMap, Map<String, String> map_eventIdZPNachaId, Set<String> set_EventIds) {
        Set<String> secondTimeDebitFailureNachaIdSet = new Set<String>();
        //value ==  payroll ID, transaction type, and NACHA amount
        Set<String> eligiblilityCriteriaKey = new Set<String>();
        eligiblilityCriteriaKey.addAll(debitFailureNachaMap.values());
        if (debitFailureNachaMap != null && debitFailureNachaMap.keySet().size() > 0) {
            List<Nacha_Entry_Return__c> list_Nacha = [SELECT Id,
                                                      Event_ID__c,
                                                      Error_Code__c,
                                                      ZP_Nacha_Entry_Return__c, 
                                                      ZP_Nacha_Entry_Return__r.Transaction_Type__c,
                                                      Amount__c
                                                      FROM Nacha_Entry_Return__c 
                                                      WHERE Event_ID__c IN :debitFailureNachaMap.keySet()];
            
            for (Nacha_Entry_Return__c objNachaEntryReturn : list_Nacha) {
                String tempKey = objNachaEntryReturn.Event_ID__c + objNachaEntryReturn.ZP_Nacha_Entry_Return__r.Transaction_Type__c + objNachaEntryReturn.Amount__c;
                if (String.isNotBlank(objNachaEntryReturn.Error_Code__c) && objNachaEntryReturn.Error_Code__c == 'R01' && eligiblilityCriteriaKey.contains(tempKey)) {
                    if (map_eventIdZPNachaId != null && map_eventIdZPNachaId.containsKey(objNachaEntryReturn.Event_ID__c) && 
                        map_eventIdZPNachaId.get(objNachaEntryReturn.Event_ID__c) == objNachaEntryReturn.ZP_Nacha_Entry_Return__c) {
                            continue;
                        }
                    secondTimeDebitFailureNachaIdSet.add(objNachaEntryReturn.Event_ID__c);
                }
            }
        }
        
        Set<String> nonEligibleNachaSet = debitFailureNachaMap.keySet();
        nonEligibleNachaSet.removeAll(secondTimeDebitFailureNachaIdSet);
        return nonEligibleNachaSet;
    }
}