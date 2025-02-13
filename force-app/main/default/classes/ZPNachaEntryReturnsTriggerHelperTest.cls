/**
 * @author Alex Xiong
 * @description Test class for ZPNachaEntryReturnsTriggerHelper
 */
@isTest
private class ZPNachaEntryReturnsTriggerHelperTest {
    
    @testsetup
    static void dataMethod(){
        ZP_User_Role__c objZPUserRole = new ZP_User_Role__c();
        objZPUserRole.User_Id__c = '000099990000';
        objZPUserRole.Company_Id__c = '0000999900001';
        objZPUserRole.Type__c = 'Role:Signatory';
        insert objZPUserRole;
        
        Account objAccount = TestUtility.CompanyAccount();
        objAccount.ZP_Company_ID__c = '0000999900001';
        update objAccount;
        
        Contact objContact = new TestDataFactory.ContactBuilder()
            .setRecordTypeId(Cache.getRecordTypeId('Contact', 'Company'))
            .setPhone('999999123')
            .setFirstName('Test Contact')
			.setLastName('ZPNachaEntry')
            .setAccountId(objAccount.Id)
            .setEmail('ZPNachaEntry@gusto.com')
			.setZPUserId('000099990000')
            .build();
            
        insert objContact;

        List<Case> list_Cases = new List<Case>();
        
        Case objCase = new TestDataFactory.CaseBuilder()
            .setRecordTypeId('Recovery Cases')
            .setType('Recovery')
            .setSubject('Test')
            .setOrigin('Panda')
            .setAccountId(objAccount.Id)
            .setDescription('Test')
            .setEventType(ZPNachaEntryReturnsTriggerHelper.PAYROLL)
            .setIntegrationKey('zenpayroll-payroll-0101010101010')
            .build();
        list_Cases.add(objCase);

        objCase = new TestDataFactory.CaseBuilder()
            .setRecordTypeId('Recovery Cases')
            .setType('Recovery')
            .setSubject('Test ContractorPayment')
            .setOrigin('Panda')
            .setAccountId(objAccount.Id)
            .setDescription('Test ContractorPayment')
            .setEventType(ZPNachaEntryReturnsTriggerHelper.PAYROLL)
            .setIntegrationKey('zenpayroll-contractor-payment-123456')
            .setOwnerId(GlobalQueryHelper.getQueueIdByName('Recovery Cases - Non-actionable'))
            .build();
        list_Cases.add(objCase);

        CaseTriggerHelper.skipTrigger = true;
        insert list_Cases;
        CaseTriggerHelper.skipTrigger = false;

        createZPNachaFuture();
    }

    @future
    private static void createZPNachaFuture() {
        List<ZP_Nacha_Entry_Returns__c> list_ZPNachaEntryReturns = createZPNachaEntryReturn('99', '0000999900001', '999', ZPNachaEntryReturnsTriggerHelper.CONTRACTOR_PAYMENT, '9');

        ZPNachaEntryReturnsTriggerHelper.queue = true;
        insert list_ZPNachaEntryReturns[0];
        ZPNachaEntryReturnsTriggerHelper.blnBypassContinue = true;
        insert list_ZPNachaEntryReturns[1];
        ZPNachaEntryReturnsTriggerHelper.blnBypassContinue = false;
    }
    
    /**
     * @Author      : Alex Xiong
     * @Description : creates 2 zp nacha records
     * @Parm        : strId - the external Id for ZP nacha records. The second one will have '1' appended to keep it different
     *                strCompanyId - the company id to attach to the zp nachas
     *                strEventId - the event Id for the zp nachas and Case that gets created
     *                strEventType - the event type for the zp nachas
     *                strNachaEntryId - the nacha entry id for the zp nachas. The second record will have '1' appended to keep it different.
     */
    public static List<ZP_Nacha_Entry_Returns__c> createZPNachaEntryReturn(String strId, String strCompanyId, String strEventId, String strEventType, String strNachaEntryId) {
        List<ZP_Nacha_Entry_Returns__c> list_ZPNachaEntryReturns = new List<ZP_Nacha_Entry_Returns__c>();
            String strId2 = strId + '1';
            String strNachaEntryId2 = strNachaEntryId + '1';

            ZP_Nacha_Entry_Returns__c objZPNacha1 = new TestDataFactory.ZPNachaEntryReturnsBuilder()
                .setCustomId(strId)
                .setAmount(1234)
                .setCompanyId(strCompanyId)
                .setEventId(strEventId)
                .setCreatedAt(System.now())
                .setUpdatedAt(System.now())
                .setTransactionType('Debit net pay')
                .setErrorCode('R01')
                .setEventType(strEventType)
                .setExpediteReason('Two day')
                .setErrorCodeDescription('Insufficient Funds')
                .setExternalKey('zenpayroll-nacha_entry_return-' + strId)
                .setNachaEntryId(strNachaEntryId)
                .setProcessingState('Queued')
                .build();

            ZP_Nacha_Entry_Returns__c objZPNacha2 = new TestDataFactory.ZPNachaEntryReturnsBuilder()
                .setCustomId(strId2)
                .setAmount(1234)
                .setCompanyId(strCompanyId)
                .setEventId(strEventId)
                .setCreatedAt(System.now())
                .setUpdatedAt(System.now())
                .setTransactionType('Debit net pay')
                .setErrorCode('R01')
                .setEventType(strEventType)
                .setExpediteReason('Two day')
                .setErrorCodeDescription('Insufficient Funds')
                .setExternalKey('zenpayroll-nacha_entry_return-' + strId2)
                .setNachaEntryId(strNachaEntryId2)
                .setProcessingState('Queued')
                .build();


            list_ZPNachaEntryReturns.add(objZPNacha1);
            list_ZPNachaEntryReturns.add(objZPNacha2);

            return list_ZPNachaEntryReturns;
        }

    /**
     * @Author      : Alex Xiong
     * @Description : create 2 zp nacha records and assert the case was created with Recovery Faster Contractor Payments as the owner
     */
    @isTest
    static void createNachaCaseRecTest() {
        Test.startTest();
        List<Case> list_Case = [SELECT Id, OwnerId FROM Case WHERE Event_Id__c = '999'];
        List<Group> list_Group = [SELECT Name FROM Group WHERE Id = :list_Case[0].OwnerId];
        List<Nacha_Entry_Return__c> list_NachaEntries = [SELECT Id, Case__c FROM Nacha_Entry_Return__c WHERE Event_Id__c = '999'];

        System.assertEquals(2, list_NachaEntries.size());
        System.assertEquals('Recovery Faster Contractor Payments', list_Group[0].Name, 'Owner should be Recovery Faster Contractor Payments');
        Test.stopTest();
    }
    
    @isTest
    static void updateNachaCaseRecTest(){
        
        Test.startTest();
        List<ZP_Nacha_Entry_Returns__c> list_ZPNachaEntryReturns = new List<ZP_Nacha_Entry_Returns__c>();
        ZP_Nacha_Entry_Returns__c objZPNachaEntryReturn = new TestDataFactory.ZPNachaEntryReturnsBuilder()
            .setEventId('0101010101011')
            .setEventType(ZPNachaEntryReturnsTriggerHelper.PAYROLL)
            .setCustomId('999222000')
            .setErrorCode('R01')
            .setCompanyId('0000999900001')
            .setAmount(200)
            .setTransactionType('TestTransaction')
            .setExternalKey('zenpayroll-nacha_entry_return-999222000')
            .build();                                                   
        list_ZPNachaEntryReturns.add(objZPNachaEntryReturn);

        objZPNachaEntryReturn = new TestDataFactory.ZPNachaEntryReturnsBuilder()
            .setEventId('0101010101010')
            .setEventType(ZPNachaEntryReturnsTriggerHelper.PAYROLL)
            .setCustomId('9992220001')
            .setErrorCode('R02')
            .setCompanyId('0000999900001')
            .setAmount(200)
            .setTransactionType('TestTransaction')
            .setExternalKey('zenpayroll-nacha_entry_return-9992220001')
            .build();                                                    
        list_ZPNachaEntryReturns.add(objZPNachaEntryReturn);
        
        objZPNachaEntryReturn = new TestDataFactory.ZPNachaEntryReturnsBuilder()
            .setEventId('12345')
            .setEventType(ZPNachaEntryReturnsTriggerHelper.PAYROLL)
            .setCustomId('9992220002')
            .setCompanyId('0000999900001')
            .setAmount(200)
            .setTransactionType('TestTransaction')
            .setExternalKey('zenpayroll-nacha_entry_return-9992220002')
            .build();                                                    
        list_ZPNachaEntryReturns.add(objZPNachaEntryReturn);

        objZPNachaEntryReturn = new TestDataFactory.ZPNachaEntryReturnsBuilder()
            .setEventId('123456')
            .setEventType(ZPNachaEntryReturnsTriggerHelper.CONTRACTOR_PAYMENT)
            .setCustomId('9992220003')
            .setCompanyId('0000999900001')
            .setAmount(200)
            .setTransactionType('TestTransaction')
            .setExternalKey('zenpayroll-contractor-payment-9992220003')
            .build();                                                    
        list_ZPNachaEntryReturns.add(objZPNachaEntryReturn);

        objZPNachaEntryReturn = new TestDataFactory.ZPNachaEntryReturnsBuilder()
            .setEventId('1234567')
            .setEventType(ZPNachaEntryReturnsTriggerHelper.INT_CONTRACTOR_PAYMENT)
            .setCustomId('9992220004')
            .setCompanyId('0000999900001')
            .setAmount(200)
            .setTransactionType('TestTransaction')
            .setExternalKey('zenpayroll-international-contractor-payment-9992220004')
            .build();                                                    
        list_ZPNachaEntryReturns.add(objZPNachaEntryReturn);

        insert list_ZPNachaEntryReturns;
        Test.stopTest();
        
        List<Case> list_TempCases = [SELECT Id, Integration_Key__c, Event_ID__c, Bank_Error_Code__c from Case WHERE Event_ID__c = '0101010101010'];
        
        String strPayroll = ZPNachaEntryReturnsTriggerHelper.strPayrollPrefix;
        System.assertEquals(list_TempCases[0].Integration_Key__c, strPayroll + list_TempCases[0].Event_ID__c);
        System.assert(list_TempCases.get(0).Bank_Error_Code__c == list_ZPNachaEntryReturns[1].Error_Code__c );
        
        Map<String, Case> map_CasesByEventId = new Map<String, Case>();
        for (Case objCase : [SELECT Id, Integration_Key__c, Event_ID__c, OwnerId
                            FROM Case 
                            WHERE Event_ID__c = '12345' 
                            OR Event_ID__c = '123456']) {
            map_CasesByEventId.put(objCase.Event_ID__c, objCase);
        }
        System.assertEquals(
            map_CasesByEventId.get('12345').Integration_Key__c, 
            strPayroll + map_CasesByEventId.get('12345').Event_ID__c
        );
        System.assertEquals(
            GlobalQueryHelper.getQueueIdByName('Recovery Faster Contractor Payments'), 
            map_CasesByEventId.get('123456').OwnerId
        );
    }

    /**
     * @Author      : Alex Xiong
     * @Description : update a ZP Nacha record and assert that the associated Case's owner isn't changed to Recovery Faster Contractor Payments
     */
    @isTest
    static void assertCaseOwnerIsNotUpdated() {
        List<Case> list_Case = [SELECT Id, OwnerId FROM Case WHERE Event_Id__c = '999'];
        List<Group> list_Group = [SELECT Name FROM Group WHERE Id = :list_Case[0].OwnerId];
        Id idPreviousCaseOwner = list_Case[0].OwnerId;

        System.assertEquals('Recovery Faster Contractor Payments', list_Group[0].Name, 'Owner should be Recovery Faster Contractor Payments');
        
        list_Case[0].OwnerId = UserInfo.getUserId();
        update list_Case;

        Test.startTest();

        List<ZP_Nacha_Entry_Returns__c> list_ZPNacha = [SELECT Id FROM ZP_Nacha_Entry_Returns__c WHERE Case_Id__c != null];
        ZPNachaEntryReturnsTriggerHelper.queue = true;
        update list_ZPNacha;

        Test.stopTest();

        List<Case> list_CaseAfterUpdate = [SELECT Id, OwnerId FROM Case WHERE Event_Id__c = '999'];

        System.assertNotEquals(idPreviousCaseOwner, list_CaseAfterUpdate[0].OwnerId);
    }

    /**
     * @Author      : Ankit C
     * @Description : Test method to test deletion logic
     */
    @isTest
    static void testZPNachaDeletion() {
        Test.startTest();
        ZP_Nacha_Entry_Returns__c objZPNachaEntryReturn = new TestDataFactory.ZPNachaEntryReturnsBuilder()
            .setEventId('2343232')
            .setEventType(ZPNachaEntryReturnsTriggerHelper.INT_CONTRACTOR_PAYMENT)
            .setCustomId('122131')
            .setCompanyId('11223344')
            .setAmount(400)
            .setTransactionType('TestTransaction')
            .setExternalKey('zenpayroll-international-contractor-payment-11223344')
            .build();                                                    

        ZPNachaEntryReturnsTriggerHelper.skipTrigger = true;
        insert objZPNachaEntryReturn;
        ZPNachaEntryReturnsTriggerHelper.skipTrigger = false;
        delete objZPNachaEntryReturn;
        undelete objZPNachaEntryReturn;
        Test.stopTest();
    }
}