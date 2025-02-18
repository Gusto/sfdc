@isTest
public class OpportunityProductControllerTest {
    @testSetup
    static void setupTestData() {
        // Create test Account
        Account acc = new Account(Name = 'Test Account', Tier__c = 'Simple');
        insert acc;

        // Create test Opportunity
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today(), AccountId = acc.Id);
        insert opp;

        // Create test Products
        Product2 prod1 = new Product2(Name = 'Test Product 1', IsActive = true);
        Product2 prod2 = new Product2(Name = 'Test Product 2', IsActive = true);
        insert new List<Product2>{prod1, prod2};

        // Create PricebookEntry
        PricebookEntry pbe1 = new PricebookEntry(Product2Id = prod1.Id, Pricebook2Id = Test.getStandardPriceBookId(), UnitPrice = 100, IsActive = true);
        PricebookEntry pbe2 = new PricebookEntry(Product2Id = prod2.Id, Pricebook2Id = Test.getStandardPriceBookId(), UnitPrice = 200, IsActive = true);
        insert new List<PricebookEntry>{pbe1, pbe2};



        Pricebook2 customPriceBook = new Pricebook2(Name = 'Payroll Product Catalog', IsActive = TRUE);
        insert customPriceBook;

        List<Product2> testProducts = new List<Product2>();
        testProducts.add(new Product2(
            Name = 'Simple',
            IsActive = TRUE
        ));

        testProducts.add(new Product2(
                Name = 'Plus',
                IsActive = TRUE
        ));

        testProducts.add(new Product2(
                Name = 'Premium',
                IsActive = TRUE
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

        // Create OpportunityLineItem
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id, Product2Id = prod1.Id, PricebookEntryId = pbe1.Id, Quantity = 2, Unit_Price__c = 100, Base_Price__c = 100);
        insert oli;
    }

    @isTest
    static void testGetOpportunityProducts() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<OpportunityLineItem> result = OpportunityProductController.getOpportunityProducts(opp.Id);
        Test.stopTest();
        OpportunityProductController.updateOpportunityProducts(result);
        System.assertEquals(1, result.size());
    }

    @isTest
    static void testLoadPriceBookEntries() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<OpportunityProductController.PriceBookEntryWrapper> result = OpportunityProductController.loadPriceBookEntries(opp.Id);
        OpportunityProductController.getOpportunityData(opp.Id);
        Test.stopTest();
        //System.assertNotEquals(0, result.size());
    }

    @isTest
    static void testAddOpportunityProducts() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id,Product2Id,Pricebook2Id FROM PricebookEntry WHERE IsActive = true LIMIT 1];

        OpportunityProductController.PriceBookEntryWrapper wrapper = new OpportunityProductController.PriceBookEntryWrapper(
            pbe.Id, 200, pbe.Product2Id, 'Test Product', 'Type B', 'Category B', '10%', 200, pbe.Pricebook2Id, 'Standard Price Book', 1
        );

        Map<String, String> draftValues = new Map<String, String>{ pbe.Id => '3' };

        Test.startTest();
        OpportunityProductController.addOpportunityProducts(opp.Id, new List<OpportunityProductController.PriceBookEntryWrapper>{wrapper}, draftValues);
        Test.stopTest();

        List<OpportunityLineItem> olis = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
        System.assertEquals(2, olis.size());
    }

    @isTest
    static void testValidateSelectedProducts() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

        Test.startTest();
        String result = OpportunityProductController.validateSelectedProducts(opp.Id, new List<Id>{prod.Id});
        Test.stopTest();

        System.assertEquals(null, result);
    }

    @isTest
    static void testDeleteOpportunityLineItem() {
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];

        Test.startTest();
        String result = OpportunityProductController.deleteOpportunityLineItem(oli.Id);
        Test.stopTest();

        OpportunityLineItem deletedOLI = [SELECT Id FROM OpportunityLineItem WHERE Id = :oli.Id ALL ROWS];
        //System.assert(deletedOLI == null, 'OpportunityLineItem should be deleted');
    }

    @IsTest
    static void testSearchPriceBookEntries() {
        // Start test setup
        Test.startTest();
        
        // Create a Price Book
        PriceBook2 priceBook = new PriceBook2(
            Name = 'Payroll Product Catalog',
            IsActive = true
        );
        insert priceBook;

        // Create a Product
        Product2 product1 = new Product2(
            Name = 'Product A',
            IsActive = true
        );
        insert product1;

        // Create a Product in a different Price Book
        Product2 product2 = new Product2(
            Name = 'Product B',
            IsActive = true
        );
        insert product2;

        PricebookEntry objPBE1 = new PricebookEntry(Product2Id = product1.Id, Pricebook2Id = Test.getStandardPriceBookId(), UnitPrice = 100, IsActive = true);
        PricebookEntry objPBE2 = new PricebookEntry(Product2Id = product2.Id, Pricebook2Id = Test.getStandardPriceBookId(), UnitPrice = 200, IsActive = true);
        insert new List<PricebookEntry>{objPBE1, objPBE2};

        // Create Price Book Entries
        PriceBookEntry pbe1 = new PriceBookEntry(
            PriceBook2Id = priceBook.Id,
            Product2Id = product1.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbe1;

        PriceBookEntry pbe2 = new PriceBookEntry(
            PriceBook2Id = priceBook.Id,
            Product2Id = product2.Id,
            UnitPrice = 200.00,
            IsActive = true
        );
        insert pbe2;

        // Create an Opportunity
        Opportunity opportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            PriceBook2Id = priceBook.Id
        );
        insert opportunity;

        // Add an Opportunity Line Item to the Opportunity
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opportunity.Id,
            PriceBookEntryId = pbe1.Id,
            Quantity = 1,
            UnitPrice = 100.00
        );
        insert oli;

        // Call the method
        String searchTerm = 'Product B';
        OpportunityProductController.searchPriceBookEntries(searchTerm, opportunity.Id);
        OpportunityProductController.loadPriceBookEntries(opportunity.Id);
        Test.stopTest();
    }
}