public with sharing class HICommuterBenefitTriggerHelper extends TriggerHandler {
    public static boolean skipTrigger = false;
    public static boolean queue = false;
    private static map<String, HI_New_Plans_Application__c> newPlanOpenMap = new Map<String, HI_New_Plans_Application__c>();
    private static map<String, HI_New_Plans_Application__c> newPlanCompletedMap = new Map<String, HI_New_Plans_Application__c>();
    
    private static map<String, HI_BoR_Transfer__c> borOpenMap = new Map<String, HI_BoR_Transfer__c>();
    private static map<String, HI_BoR_Transfer__c> borCompletedMap = new Map<String, HI_BoR_Transfer__c>();
    public Map<String,Carrier__c> map_ProviderKeyWithCarrier = new Map<String,Carrier__c>(); // Added for BBO-1969
    set<String> set_ProviderKey = new Set<String>();//Added for BBO-1969
    
    public HICommuterBenefitTriggerHelper() {
        super('HICommuterBenefitTriggerHelper');
    }
    
    public override void beforeInsert() {
        List<HI_Commuter_Benefits__c> list_benefits = (List<HI_Commuter_Benefits__c>) Trigger.new;
        if (queue == true) {
            processInformation(list_benefits);
        } else {
            for (HI_Commuter_Benefits__c benefit : list_benefits) {
                benefit.Processing_State__c = IntegrationUtils.QUEUED_STATE;
            }
        }
    }
    
    public override void afterInsert() {
        List<HI_Commuter_Benefits__c> list_benefits = (List<HI_Commuter_Benefits__c>) Trigger.new;
        if (queue == false) {
            HICommuterBenefitQueue updateJob = new HICommuterBenefitQueue(list_benefits);
            ID jobID = System.enqueueJob(updateJob);
        }
    }
    
    public override void beforeUpdate() {
        List<HI_Commuter_Benefits__c> list_benefits = (List<HI_Commuter_Benefits__c>) Trigger.new;
        if (queue == true) {
            processInformation(list_benefits);
        } else {
            for (HI_Commuter_Benefits__c benefit : list_benefits) {
                benefit.Processing_State__c = IntegrationUtils.QUEUED_STATE;
            }
        }
    }
    
    public override void afterUpdate() {
        List<HI_Commuter_Benefits__c> list_benefits = (List<HI_Commuter_Benefits__c>) Trigger.new;
        if (queue == false) {
            HICommuterBenefitQueue updateJob = new HICommuterBenefitQueue(list_benefits);
            ID jobID = System.enqueueJob(updateJob);
        }
    }
    
    // maping all the related fields
    private Policy__c mapPolicyFields(HI_Commuter_Benefits__c hiBenefit, Policy__c toUpdatePolicyRec, String oppId) {
        toUpdatePolicyRec.Id__c = 'commuter-' + hiBenefit.Id__c;
        if (toUpdatePolicyRec.Opportunity__c == null) {
            toUpdatePolicyRec.Opportunity__c = oppId;
        }
        toUpdatePolicyRec.Benefit_Type__c = 'Commuter';
        if(map_ProviderKeyWithCarrier.containsKey(hiBenefit.Provider_Key__c)){
            toUpdatePolicyRec.Carrier__c = map_ProviderKeyWithCarrier.get(hiBenefit.Provider_Key__c).Id;//Updated for BBO-1969
        }
        toUpdatePolicyRec.Name = 'Commuter Benefit';//Updated for BBO-1969
        toUpdatePolicyRec.Coverage_Effective_Date__c = hiBenefit.Start_Date__c;
        toUpdatePolicyRec.Expiration_Date__c = hiBenefit.End_Date__c;
        map<String, String> waitingPeriodMap = IntegrationUtils.getIntegrationValueMap('Opportunity', 'Waiting_Period__c ');
        if (waitingPeriodMap.containsKey(hiBenefit.Waiting_Period__c)) {
            toUpdatePolicyRec.Waiting_Period__c = waitingPeriodMap.get(hiBenefit.Waiting_Period__c);
        }
        if (hiBenefit.deleted_at__c == null) {
            toUpdatePolicyRec.Is_Selected__c = true;
        } else {
            toUpdatePolicyRec.Is_Selected__c = false;
        }
        toUpdatePolicyRec.External_Key__c = hiBenefit.External_Key__c;
        return toUpdatePolicyRec;
    }
    
    private void processInformation(List<HI_Commuter_Benefits__c> benefitList) {
        set<string> hiBenefitKeySet = new Set<string>();
        set<string> companyIdSet = new Set<string>();
        list<HI_Commuter_Benefits__c> toUpsertBenefitList = new List<HI_Commuter_Benefits__c>();
        List<Policy__c> policyUpsertList = new List<Policy__c>();
        Map<String, String> dmlUpsertErrorsMap = new Map<String, String>();
        Map<String, String> dmlOpportunityUpsertErrorsMap = new Map<String, String>();
        
        for (HI_Commuter_Benefits__c benefit : benefitList) {
            if (benefit.Processing_State__c == IntegrationUtils.DEAD_STATE) {
                continue;
            }
            benefit.Processing_State__c = IntegrationUtils.QUEUED_STATE;
            benefit.Message__c = '';
            
            if (benefit.Id__c == null) {
                continue;
            }
            hiBenefitKeySet.add(benefit.External_Key__c);
            companyIdSet.add(benefit.Company_Id__c);
            //added for BBO-1969 Starts
            if(benefit.Provider_Key__c == null || benefit.Provider_Key__c == ''){
                setProcessingState(IntegrationUtils.DEAD_STATE, 'Provider Key is blank.', benefit);
            }
            else{
                set_ProviderKey.add(benefit.Provider_Key__c);
            }
            //BBO-1969 Ends
        }
        //Added for 1969
        map_ProviderKeyWithCarrier = HIFulfillmentEventHelperFunctions.getCarrierInfo(set_ProviderKey);
        // if External Id set contains some value
        if (hiBenefitKeySet.size() > 0) {
            setNewPlanApplicationData(companyIdSet);
            setBORData(companyIdSet);
            map<String, Account> companyMap = getAccounts(companyIdSet);
            map<string, Policy__c> policyMap = getBenefitPolicyData(hiBenefitKeySet);
            Map<String, Opportunity> commuterBenefitChangeOpp = getCommuterBenefitOpportunityData(hiBenefitKeySet);
            Map<String, Opportunity> opportunityDataMap = getCompanyOpportunityData(companyIdSet);
            Map<string, Map<String, Map<String, Opportunity>>> companyRecordTypeStatusMap = getBenefitOpportunityData(companyIdSet);
            
            List<Opportunity> opportunityUpsertList = new List<Opportunity>();
            
            for (HI_Commuter_Benefits__c benefit : benefitList) {
                if (benefit.Processing_State__c == IntegrationUtils.DEAD_STATE) {
                    continue;
                }
                
                if (!companyMap.containsKey(benefit.Company_Id__c)) {
                    setProcessingState(IntegrationUtils.ERROR_STATE, 'Company does not exist.', benefit);
                    continue;
                }
                
                if (commuterBenefitChangeOpp.containsKey(benefit.External_Key__c)) {
                    Opportunity opp = commuterBenefitChangeOpp.get(benefit.External_Key__c);
                    opp.Benefits_Current_Setup_Step__c = benefit.Status__c;
                    opp.CloseDate = benefit.Start_Date__c;
                    opportunityUpsertList.add(opp);
                    continue;
                }
                
                if (!policyMap.containsKey(benefit.External_Key__c)) {
                    if (newPlanCompletedMap.containsKey(benefit.company_id__c) || borCompletedMap.containsKey(benefit.company_id__c)) {
                        Opportunity opp = new Opportunity(
                            Type = 'TADA',
                        StageName = 'SAL',
                        Name = companyMap.get(benefit.Company_Id__c).Name,
                        AccountId = companyMap.get(benefit.Company_Id__c).Id,
                        RecordTypeId = cache.getRecordTypeId('Opportunity', 'Benefits Change'),
                        Benefits_Current_Setup_Step__c = benefit.Status__c,
                        ID__c = 'HICOMMUTER' + benefit.Id__c,
                        Source_id__c = benefit.External_Key__c,
                        CloseDate = (benefit.Start_Date__c != null) ? benefit.Start_Date__c : System.today() + 10
                            );
                        opportunityUpsertList.add(opp);
                        continue;
                    }
                }
            }
            
            if (opportunityUpsertList.size() > 0) {
                List<Database.UpsertResult> saveResult = database.upsert(opportunityUpsertList, Opportunity.Fields.Source_id__c, false);
                dmlOpportunityUpsertErrorsMap = Utils.processUpsertResult(saveResult, opportunityUpsertList, 'Source_id__c', true, 'HICommuterBenefitTriggerHelper-processInformation');
            }
            commuterBenefitChangeOpp = getCommuterBenefitOpportunityData(hiBenefitKeySet);
            opportunityDataMap = getCompanyOpportunityData(companyIdSet);
            
            for (HI_Commuter_Benefits__c benefit : benefitList) {
                if (benefit.Processing_State__c == IntegrationUtils.DEAD_STATE) {
                    continue;
                }
                
                if (policyMap.containsKey(benefit.External_Key__c)) {
                    Policy__c policy = policyMap.get(benefit.External_Key__c);
                    policy = mapPolicyFields(benefit, policy, policy.Opportunity__c);
                    policyUpsertList.add(policy);
                } else if (commuterBenefitChangeOpp.containsKey(benefit.External_Key__c)) {
                    Policy__c policy = new Policy__c();
                    policy = mapPolicyFields(benefit, policy, commuterBenefitChangeOpp.get(benefit.External_Key__c).Id);
                    policyUpsertList.add(policy);
                } else if (newPlanOpenMap.containsKey(benefit.Company_Id__c)) {
                    HI_New_Plans_Application__c app = newPlanOpenMap.get(benefit.Company_Id__c);
                    if (opportunityDataMap.containsKey(app.External_Key__c)) {
                        Policy__c policy = new Policy__c();
                        policy = mapPolicyFields(benefit, policy, opportunityDataMap.get(app.External_Key__c).Id);
                        policyUpsertList.add(policy);
                    } else {
                        setProcessingState(IntegrationUtils.ERROR_STATE, 'New Plan opp does not exist', benefit);
                        continue;
                    }
                } else {
                    setProcessingState(IntegrationUtils.ERROR_STATE, 'No application exists.', benefit);
                    continue;
                }
            }
            
            if (policyUpsertList.size() > 0) {
                List<Database.UpsertResult> saveResult = database.upsert(policyUpsertList, Policy__c.Fields.External_Key__c, false);
                dmlUpsertErrorsMap = Utils.processUpsertResult(saveResult, policyUpsertList, 'External_Key__c', true, 'HICommuterBenefitTriggerHelper-processInformation');
            }
        }
        
        for (HI_Commuter_Benefits__c benefit : benefitList) {
            if (benefit.Processing_State__c == IntegrationUtils.DEAD_STATE || benefit.Processing_State__c == IntegrationUtils.ERROR_STATE) {
                continue;
            }
            if (dmlOpportunityUpsertErrorsMap.containsKey(benefit.External_Key__c)) {
                setProcessingState(IntegrationUtils.ERROR_STATE, dmlOpportunityUpsertErrorsMap.get(benefit.External_Key__c), benefit);
            } else if (dmlUpsertErrorsMap.containsKey(benefit.External_Key__c)) {
                setProcessingState(IntegrationUtils.ERROR_STATE, dmlUpsertErrorsMap.get(benefit.External_Key__c), benefit);
            } else {
                setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Processed', benefit);
            }
        }
    }
    
    private static map<String, Account> getAccounts(Set<String> companyIdSet) {
        map<String, Account> accMap = new Map<String, Account>();
        for (Account acc : [SELECT Id, ZP_Company_Id__c, Name FROM Account WHERE ZP_Company_Id__c IN :companyIdSet]) {
            accMap.put(acc.ZP_Company_Id__c, acc);
        }
        return accMap;
    }
    
    private static void setNewPlanApplicationData(Set<String> companyIdSet) {
        newPlanOpenMap = new Map<String, HI_New_Plans_Application__c>();
        newPlanCompletedMap = new Map<String, HI_New_Plans_Application__c>();
        Set<String> openOrderSet = new Set<String>();
        
        for (Benefit_Order__c order : [
			SELECT Id, Closed__c, Opportunity__c, Opportunity__r.Source_Id__c, ZP_Company_ID__c
			FROM Benefit_Order__c
			WHERE ZP_Company_ID__c IN :companyIdSet AND Closed__c = FALSE AND Opportunity__r.Source_Id__c != NULL
		]) {
            openOrderSet.add(order.Opportunity__r.Source_Id__c);
        }
        
        for (HI_New_Plans_Application__c application : [
			SELECT Id, Id__c, External_Key__c, Company_id__c, Status__c
			FROM HI_New_Plans_Application__c
			WHERE company_id__c IN :companyIdSet AND Status__c != 'dismissed' AND deleted_at__c = NULL
		]) {
            if (openOrderSet.contains(application.External_Key__c)) {
                newPlanOpenMap.put(application.Company_id__c, application);
            } else if (application.Status__c == 'completed' || application.Status__c == 'complete') {
                newPlanCompletedMap.put(application.Company_id__c, application);
            } else {
                newPlanOpenMap.put(application.Company_id__c, application);
            }
        }
    }
    
    private static void setBoRData(Set<String> companyIdSet) {
        borOpenMap = new Map<String, HI_BoR_Transfer__c>();
        borCompletedMap = new Map<String, HI_BoR_Transfer__c>();
        for (HI_BOR_Transfer__c application : [
			SELECT Id, Id__c, External_Key__c, Company_id__c, Status__c
			FROM HI_BOR_Transfer__c
			WHERE company_id__c IN :companyIdSet AND Status__c != 'dismissed' AND deleted_at__c = NULL
		]) {
            if (application.Status__c == 'completed' || application.Status__c == 'bor_complete') {
                borCompletedMap.put(application.Company_id__c, application);
            } else {
                borOpenMap.put(application.Company_id__c, application);
            }
        }
    }
    
    // querying State object records present in the org using ID__c field
    private Map<string, Policy__c> getBenefitPolicyData(set<string> hiBenefitKeySet) {
        map<string, Policy__c> toReturnPolicyRecMap = new Map<string, Policy__c>();
        if (hiBenefitKeySet != null && hiBenefitKeySet.size() > 0) {
            for (Policy__c policy : [SELECT id, External_Key__c, Opportunity__c FROM Policy__c WHERE External_Key__c IN :hiBenefitKeySet]) {
                toReturnPolicyRecMap.put(policy.External_Key__c, policy);
            }
        }
        return toReturnPolicyRecMap;
    }
    
    private Map<String, Opportunity> getCommuterBenefitOpportunityData(set<string> hiBenefitKeySet) {
        Map<String, Opportunity> oppMap = new Map<String, Opportunity>();
        for (Opportunity opp : [SELECT id, Name, IsClosed, IsWon, RecordType.name, Account.ZP_Company_Id__c, Source_Id__c, Id__c FROM Opportunity WHERE Source_Id__c IN :hiBenefitKeySet]) {
            oppMap.put(opp.Source_ID__c, opp);
        }
        return oppMap;
    }
    
    private Map<String, Opportunity> getCompanyOpportunityData(set<string> companyIdSet) {
        Map<String, Opportunity> companyOpportunityMap = new Map<String, Opportunity>();
        if (companyIdSet != null && companyIdSet.size() > 0) {
            for (Opportunity opp : [
				SELECT id, Name, IsClosed, IsWon, RecordType.name, Account.ZP_Company_Id__c, Source_Id__c
				FROM Opportunity
				WHERE Account.ZP_Company_Id__c IN :companyIdSet AND Source_Id__c != NULL
			]) {
                companyOpportunityMap.put(opp.Source_Id__c, opp);
            }
        }
        return companyOpportunityMap;
    }
    
    private Map<string, Map<String, Map<String, Opportunity>>> getBenefitOpportunityData(set<string> companyIdSet) {
        Map<string, Map<String, Map<String, Opportunity>>> companyRecordTypeStatusMap = new Map<string, Map<String, Map<String, Opportunity>>>();
        if (companyIdSet != null && companyIdSet.size() > 0) {
            for (Opportunity opp : [
				SELECT id, Name, IsClosed, IsWon, RecordType.name, Account.ZP_Company_Id__c, Source_Id__c
				FROM Opportunity
				WHERE (ISClosed = FALSE OR ISWon = TRUE) AND Account.ZP_Company_Id__c IN :companyIdSet
			]) {
                Map<String, Map<String, Opportunity>> recordTypeStatusMap = new Map<String, Map<String, Opportunity>>();
                if (companyRecordTypeStatusMap.containsKey(opp.Account.ZP_Company_Id__c)) {
                    recordTypeStatusMap = companyRecordTypeStatusMap.get(opp.Account.ZP_Company_Id__c);
                }
                
                Map<String, Opportunity> statusMap = new Map<String, Opportunity>();
                if (recordTypeStatusMap.containsKey(opp.RecordType.name)) {
                    statusMap = recordTypeStatusMap.get(opp.RecordType.name);
                }
                
                if (opp.IsWon) {
                    statusMap.put('Won', opp);
                } else if (opp.IsClosed == false) {
                    statusMap.put('Open', opp);
                }
                
                recordTypeStatusMap.put(opp.RecordType.Name, statusMap);
                companyRecordTypeStatusMap.put(opp.Account.ZP_Company_Id__c, recordTypeStatusMap);
            }
        }
        return companyRecordTypeStatusMap;
    }
    
    // populating HI_State__c object fields
    public HI_Commuter_Benefits__c setProcessingState(String ProcessingState, String message, HI_Commuter_Benefits__c benefit) {
        benefit.Processing_State__c = ProcessingState;
        benefit.Message__c = benefit.Message__c + '-' + message;
        benefit.Last_Processed__c = System.now();
        return benefit;
    }
}