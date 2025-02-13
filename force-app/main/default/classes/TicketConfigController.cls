/**
 * @name         : TicketConfigController
 * @author       : Praveen Sethu
 * @date         : 09-16-2020
 * @description  : Apex Class used for creating and retrieving data from Ticket_Config__c object
 * @test classes : TicketConfigControllerTest
**/
public with sharing class TicketConfigController {
    /**
     * @name         : TicketConfigResponseWrapper
     * @author       : Praveen Sethu
     * @date         : 09-16-2020
     * @description  : Wrapper Class
     * @test classes : TicketConfigControllerTest
    **/
    public class TicketConfigResponseWrapper {

        @AuraEnabled
        public Ticket_Config__c objTicketConfig;

        // List of Ticket__c record types
        @AuraEnabled
        public List<String> list_TicketRecordTypes;

        // List of ticket reason
        @AuraEnabled
        public List<String> list_TicketReasons;

        // List of ticket sub reason
        @AuraEnabled
        public List<String> list_TicketSubReasons;

        // List of Ticket__c fields
        @AuraEnabled
        public List<String> list_TicketFields;
        
        // Success Indicator
        @AuraEnabled 
        public Boolean blnIsSuccess;

        // List of Queues related to Ticket__c object
        @AuraEnabled
        public List<String> list_OwnerQueues;

        // Success or error Message
        @AuraEnabled
        public String strMessage;

        // Parameterized Constructor
        public TicketConfigResponseWrapper(Boolean blnIsSuccess, String strMessage, 
        Ticket_Config__c objTicketConfig, 
        List<String> list_TicketRecordTypes, List<String> list_TicketReasons, 
        List<String> list_TicketSubReasons, List<String> list_TicketFields, List<String> list_OwnerQueues) {
            this.blnIsSuccess = blnIsSuccess;
            this.strMessage = strMessage;
            this.objTicketConfig  = objTicketConfig;
            this.list_TicketRecordTypes = list_TicketRecordTypes;
            this.list_TicketReasons = list_TicketReasons;
            this.list_TicketSubReasons = list_TicketSubReasons;
            this.list_TicketFields = list_TicketFields;
            this.list_OwnerQueues = list_OwnerQueues;
        }

    }

    /**
     * @name         : CreateTicketResponseWrapper
     * @author       : Praveen Sethu
     * @date         : 09-16-2020
     * @description  : Create Ticket Response Wrapper
     * @test classes : TicketConfigControllerTest
    **/
    public class CreateTicketResponseWrapper {

        @AuraEnabled
        public Ticket_Config__c objTicketConfig;

        @AuraEnabled
        public List<Benefit_Order__c> list_BenefitOrders = new List<Benefit_Order__c>();

        @AuraEnabled
        public List<Opportunity> list_Opportunities = new List<Opportunity>();

        @AuraEnabled
        public List<Case> list_RelatedCases = new List<Case>();        
    }

    /**
     * @Author      : Praveen Sethu
     * @Description : Loading Ticket Config
     * @Parm        : NA
     * @Return      : TicketConfigResponseWrapper 
    **/
    @AuraEnabled public static TicketConfigResponseWrapper loadTicketConfig() {

        // Initialize Variables
        Ticket_Config__c objTicketConfig;
        List<String> list_TicketRecordTypes;
        List<String> list_TicketReasons;
        List<String> list_TicketSubReasons;
        List<String> list_TicketFields;
        List<String> list_OwnerQueues;

        try {
            if (TicketConfigControllerTest.blnThrowException 
                && Test.isRunningTest()) {
                Integer intSample = 1/0;
            }
            // Load Ticket Record Types
            list_TicketRecordTypes = new List<String>();
            for (RecordType objRecordType : [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Ticket__c']) {
                list_TicketRecordTypes.add(objRecordType.Name);
            }
            // Load Ticket Fields
            list_TicketFields = new List<String>();
            list_TicketFields = CaseActionsFieldConfigurationController.getCaseFieldList('Ticket__c');

            // Load Ticket Reason List
            list_TicketReasons = new List<String>();
            list_TicketReasons = returnPicklistValues('Ticket__c', 'UI_Ticket_Reason__c');

            // Load Ticket Sub Reason List
            list_TicketSubReasons = new List<String>();
            list_TicketSubReasons = returnPicklistValues('Ticket__c', 'UI_Ticket_Sub_Reason__c');

            // Populate Queue Owner List
            list_OwnerQueues = new List<String>();
            for (QueueSobject objQueueSObject : [SELECT QueueId, Queue.Name, SobjectType 
                                                 FROM QueueSobject WHERE SobjectType = 'Ticket__c']) {
                list_OwnerQueues.add(objQueueSObject.Queue.Name);
            }

            // Send success flag set to true
            return new TicketConfigResponseWrapper(
                true, 
                null, 
                objTicketConfig, 
                list_TicketRecordTypes, 
                list_TicketReasons, 
                list_TicketSubReasons, 
                list_TicketFields, 
                list_OwnerQueues
            );
        } catch(Exception objException) {
            ExceptionLogUtil.logException(
                'TicketConfigController', 
                'loadTicketConfig', 
                objException.getMessage(), 
                objException.getStackTraceString()
            );
            return new TicketConfigResponseWrapper(
                false, 
                objException.getMessage(), 
                objTicketConfig, 
                list_TicketRecordTypes, 
                list_TicketReasons, 
                list_TicketSubReasons, 
                list_TicketFields, 
                list_OwnerQueues
            );
        }
    }

    /**
     * @Author      : Praveen Sethu
     * @Description : Return Picklist Values for strObjectName and strFieldName
     * @Parm        : strObjectName - Object Name, strFieldName - Field name
     * @Return      : List<String> - List of picklist values 
    **/
    public static List<String> returnPicklistValues(String strObjectName, String strFieldName) {
        // List of Picklist Values
        List<String> list_PickListValues = new List<String>();
        Schema.DescribeSObjectResult objResult = Utils.getSObjectDescribe(strObjectName);
        Map<String, Schema.SObjectField> map_FieldsByName = objResult.fields.getMap();
        Schema.DescribeFieldResult objFieldResult = map_FieldsByName.get(strFieldName).getDescribe();
        List<Schema.PicklistEntry> objPicklistEntry = objFieldResult.getPicklistValues();
        for (Schema.PicklistEntry objPickListVal : objPicklistEntry) {
            list_PickListValues.add(objPickListVal.getValue());
        }

        return list_PickListValues;

    }

    /**
     * @Author      : Elavarasan Nagarathinam
     * @Description : Retrieves Ticket Config record related to selected team
     * @Parm        : strTeam - Team
     * @Return      : List<String> 
    **/
    @AuraEnabled
    public static List<String> getTicketReasonInfo(String strTeam) {
        Set<String> set_TicketReasons = new Set<String>();
        List<String> list_TicketReasons = new List<String>();
        // Query Ticket Config to find records that match ticket reason and sub reason
        for (Ticket_Config__c objTicketConfigRecord : [
            SELECT
            Id,
            Ticket_Reason__c
            FROM
            Ticket_Config__c
            WHERE
            Team__c = :strTeam
            AND
            Ticket_Reason__c != null
            AND
            Is_Active__c = true
        ]) {
            set_TicketReasons.add(objTicketConfigRecord.Ticket_Reason__c);
        }
        list_TicketReasons.addAll(set_TicketReasons);
        return list_TicketReasons;
    }
	
    /**
     * @Author      : Elavarasan Nagarathinam 
     * @Description : Retrieves Ticket Config Info
     * @Parm        : strTicketReason - Ticket Reason, strTicketSubReason - Ticket Sub Reason, idCase - Case Id
     * @Return      : CreateTicketResponseWrapper 
    **/
    @AuraEnabled
    public static CreateTicketResponseWrapper getTicketConfigInfo(String strTicketReason, String strTicketSubReason, Id idCase) {
        CreateTicketResponseWrapper objResponseWrapper = new CreateTicketResponseWrapper();
        objResponseWrapper = getTicketConfigInfo(null, strTicketReason, strTicketSubReason, idCase);
        return objResponseWrapper;
    }
    /**
     * @Author      : Praveen Sethu 
     * @Description : Retrieves Ticket Config Info
     * @Parm        : strTeam - Team, strTicketReason - Ticket Reason, strTicketSubReason - Ticket Sub Reason, idCase - Case Id
     * @Return      : CreateTicketResponseWrapper 
    **/
    @AuraEnabled
    public static CreateTicketResponseWrapper getTicketConfigInfo(String strTeam, String strTicketReason, String strTicketSubReason, Id idCase) {
        // Ticket Config record
        Ticket_Config__c objTicketToReturn;
        CreateTicketResponseWrapper objResponseWrapper = new CreateTicketResponseWrapper();
        try {
            if (TicketConfigControllerTest.blnThrowException 
                && Test.isRunningTest()) {
                Integer intSample = 1/0;
            }
            String strQuery = 'SELECT Id, Ticket_Sub_Reason_List__c, Ticket_Sub_Reason__c, Description__c, Talking_Points__c, Configuration_Json__c, Owner_Type__c, Queue_Id__c, Ticket_Record_Type__c, Stamp_Ticket_Reason__c FROM Ticket_Config__c';
            strQuery += ' WHERE Ticket_Reason__c = :strTicketReason AND Ticket_Sub_Reason__c = :strTicketSubReason AND Is_Active__c = true';
            
            if (String.isNotBlank(strTeam)) {
                strQuery += ' AND Team__c = :strTeam'; 
            }

            List<Ticket_Config__c> list_TicketConfigs  = Database.query(strQuery);
            
            if (!list_TicketConfigs.isEmpty()) {
                objTicketToReturn = list_TicketConfigs.get(0);
                objResponseWrapper.objTicketConfig = objTicketToReturn;
            }
            
            // If valid ticket exists and valid case id exists
            if (objTicketToReturn != null && idCase != null) {
                // fetch case's account id
                List<Case> list_Cases = [SELECT Id, AccountId FROM Case WHERE Id = :idCase];
                // Check if case is not empty
                if (!list_Cases.isEmpty()) {
                    // get the first value on the case
                    Case objCase = list_Cases.get(0);
                    // Check if case has an AccountId
                    if (objCase.AccountId != null) {
                        // Fetch Accounts most recent benefit order and opportunity
                        List<Account> list_Accounts = [
                            SELECT
                            Id,
                            (SELECT Id, Name, CreatedDate, Owner.Name, Order_Status__c, Coverage_Effective_Date__c, Submission_Deadline__c 
                             FROM Benefit_Orders__r 
                             ORDER BY CreatedDate DESC
                             LIMIT 2),
                            (SELECT Id, Name, RecordType.Name, CreatedDate, Owner.Name, StageName, Type 
                             FROM Opportunities 
                             ORDER BY CreatedDate DESC 
                             LIMIT 2),
                            (SELECT Id, RecordType.Name, Status, CreatedDate, Owner.Name, CaseNumber 
                             FROM Cases 
                             WHERE RecordType.Name NOT IN ('Payroll Care', 'Benefits Care') 
                             AND Type NOT IN ('Payroll Care', 'Benefits Care') 
                             ORDER BY CreatedDate DESC 
                             LIMIT 5)
                            FROM
                            Account
                            WHERE
                            Id = :objCase.AccountId
                        ];
                        
                        // If the list is not empty, set them to variables on wrapper object and return
                        if (!list_Accounts.isEmpty()) {
                            Account objAccount = list_Accounts.get(0);
                            objResponseWrapper.list_BenefitOrders = objAccount.Benefit_Orders__r;
                            objResponseWrapper.list_Opportunities = objAccount.Opportunities;
                            objResponseWrapper.list_RelatedCases = objAccount.Cases;
                        }
                    }
                }
            }
            
            return objResponseWrapper;
        } catch (Exception objException) {
            ExceptionLogUtil.logException(
                'TicketConfigController', 
                'getTicketConfigInfo', 
                objException.getMessage(), 
                objException.getStackTraceString()
            );
            
            return objResponseWrapper;
        }  
    }
	
    /**
     * @Author      : Praveen Sethu
     * @Description : Saves Ticket Config 
     * @Parm        : objTicketConfig - Instance of Ticket_Config__c
     * @Return      : Ticket_Config__c 
    **/
    // Saves Ticket Config 
    @AuraEnabled
    public static Ticket_Config__c saveTicketConfig(Ticket_Config__c objTicketConfig) {
        Ticket_Config__c objTicketToReturn;
        Map<String, String> map_FieldLabelToApi = new Map<String, String>();
        try {
            if (TicketConfigControllerTest.blnThrowException 
                && Test.isRunningTest()) {
                Integer intSample = 1/0;
            }
            if (!String.isBlank(objTicketConfig.Configuration_Json__c)) {
                map_FieldLabelToApi = CaseActionsFieldConfigurationController.getCaseFieldLabelToApiMap('Ticket__c');
                List<CaseActionsFieldConfigurationController.CaseFieldWrapper> list_Wrapper = (List<CaseActionsFieldConfigurationController.CaseFieldWrapper>) 
                    System.JSON.deserialize(
                        objTicketConfig.Configuration_Json__c, 
                        List<CaseActionsFieldConfigurationController.CaseFieldWrapper>.class
                    );
                for (CaseActionsFieldConfigurationController.CaseFieldWrapper objWrapper : list_Wrapper) {
                    if (map_FieldLabelToApi.containsKey(objWrapper.label)) {
                        objWrapper.api = map_FieldLabelToApi.get(objWrapper.label);
                    }
                }
                objTicketConfig.Configuration_Json__c = System.JSON.serialize(list_Wrapper);
            }

            upsert objTicketConfig;
            List<Ticket_Config__c> list_TicketConfigs = [
                SELECT
                Id,
                Ticket_Sub_Reason_List__c,
                Ticket_Sub_Reason__c,
                Description__c,
                Talking_Points__c,
                Configuration_Json__c,
                Owner_Type__c,
                Queue_Id__c,
                Ticket_Record_Type__c,
                Stamp_Ticket_Reason__c 
                FROM 
                Ticket_Config__c
                WHERE
                Id = :objTicketConfig.Id
            ];

            if (!list_TicketConfigs.isEmpty()) {
                objTicketToReturn = list_TicketConfigs.get(0);
            }

            return objTicketToReturn;
        } catch(Exception objException) {
            ExceptionLogUtil.logException(
                'TicketConfigController', 
                'saveTicketConfig', 
                objException.getMessage(), 
                objException.getStackTraceString()
            );

            return objTicketToReturn;
        }
    }
}