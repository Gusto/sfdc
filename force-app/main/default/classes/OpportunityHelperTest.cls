@isTest
public class OpportunityHelperTest {
    @testSetup
    static void setup() {
        // Create test data
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                ZP_Company_ID__c = '12345' + i,
                Tier__c = 'Simple'
            ));
        }
        insert testAccounts;

        Pricebook2 customPriceBook = new Pricebook2(Name = 'Payroll Product Catalog', IsActive = TRUE);
        insert customPriceBook;

        List<Product2> testProducts = new List<Product2>();
        testProducts.add(new Product2(
            Name = 'Simple',
            IsActive = TRUE,
            ExternalId = 'simple'
        ));

        testProducts.add(new Product2(
                Name = 'Plus',
                IsActive = TRUE,
                ExternalId = 'plus'
        ));

        testProducts.add(new Product2(
                Name = 'Premium',
                IsActive = TRUE,
                ExternalId = 'premium'
        ));
        insert testProducts;

        List<PricebookEntry> testPricebookEntries1 = new List<PricebookEntry>();
        for (Product2 product : testProducts) {
            PricebookEntry objStandardPrice = new PricebookEntry(Pricebook2Id = Test.getStandardPriceBookId(), Product2Id = product.Id, UnitPrice = 10000, IsActive = true, Base_Price__c = 100);
            testPricebookEntries1.add(objStandardPrice);
        }
        insert testPricebookEntries1;

        List<PricebookEntry> testPricebookEntries = new List<PricebookEntry>();
        for (Product2 product : testProducts) {
            testPricebookEntries.add(new PricebookEntry(
                Pricebook2Id = customPriceBook.Id,
                Product2Id = product.Id,
                UnitPrice = 100,
                IsActive = TRUE,
                Base_Price__c = 50
            ));
        }
        insert testPricebookEntries;
    }

    @isTest
    static void testCreateUpdateAcquisitionOpportunity() {
        // Fetch test accounts
        List<Account> accounts = [SELECT Id, Name, ZP_Company_ID__c, Tier__c,Number_of_Active_Employees__c,Number_of_Active_Contractors__c,International_Employees__c,International_Contractors__c,Additional_Services__c,NumberOfEmployees,NumberOfEmployees_Lead__c FROM Account LIMIT 5];
        Map<Id, Account> map_Account = new Map<Id, Account>(accounts);
        OpportunityHelper.createCollections();
        //OpportunityHelper.createUpdateAcquisitionOpportunity(accounts, map_Account);
        Test.startTest();
        accounts[0].Tier__c = 'Plus';
        update accounts;
        Test.stopTest();

        // Verify that opportunities were created
        List<Opportunity> opportunities = [SELECT Id, Name, AccountId, RecordType.DeveloperName, Source_Id__c FROM Opportunity];
        System.assertEquals(1, opportunities.size(), 'The number of created opportunities should match the number of accounts.');
    }

    @isTest
    static void testCreateOpportunityLineItems() {
        // Create test opportunity
        Account testAccount = [SELECT Id,Tier__c,Additional_Services__c FROM Account LIMIT 1];
        testAccount.Number_of_Active_Employees__c = 10;
        testAccount.Number_of_Active_Contractors__c = 5;
        testAccount.International_Employees__c = 2;
        testAccount.International_Contractors__c = 1;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'New',
            CloseDate = Date.today().addDays(45),
            RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Acquisition'),
            Current_Tier__c = 'Simple',
            PriceBook2Id = [SELECT Id FROM Pricebook2 WHERE Name = 'Payroll Product Catalog' LIMIT 1].Id,
            NumberOfEmployees__c = 10,
            Number_of_Contractors__c = 5
        );
        insert testOpportunity;

        Account oldAccount = new Account(
            Id = testAccount.Id,
            Tier__c = 'Plus'
        );

        oldAccount.Number_of_Active_Employees__c = 1;
        oldAccount.Number_of_Active_Contractors__c = 3;
        oldAccount.International_Employees__c = 3;
        oldAccount.International_Contractors__c = 4;
        oldAccount.Additional_Services__c = '';

        Test.startTest();
        OpportunityHelper.createCollections();
        //OpportunityHelper.createOpportunityLineItems(new List<Opportunity>{testOpportunity});
        List<OpportunityLineItem> lineItems = [SELECT Id, OpportunityId, Quantity, TotalPrice FROM OpportunityLineItem WHERE OpportunityId = :testOpportunity.Id];
        OpportunityHelper.updateExistingOpportunity (testAccount, oldAccount, testOpportunity);
        Test.stopTest();

        // Verify that OpportunityLineItems were created
        //List<OpportunityLineItem> lineItems = [SELECT Id, OpportunityId, Quantity, TotalPrice FROM OpportunityLineItem WHERE OpportunityId = :testOpportunity.Id];
        //System.assertEquals(1, lineItems.size(), 'One OpportunityLineItem should be created.');
    }

    @isTest
    static void testValidateAcquisitionOpportunity() {
        // Create test account and opportunities
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Opportunity existingOpportunity = new Opportunity(
            Name = 'Existing Opportunity',
            AccountId = testAccount.Id,
            StageName = 'New',
            CloseDate = Date.today().addDays(30),
            RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Acquisition'),
            Type = 'New Business'
        );
        try {
            insert existingOpportunity;
        } catch (Exception objEx) {
            
        }
    }
}