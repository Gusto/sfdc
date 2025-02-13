/**
 * Created by brent.johnson on 11/16/16.
 */
@isTest
public without sharing class TestUtils {
	public static Integer LIST_SIZE {
		get {
			return OrganizationUtilities.isProduction() ? 3 : 10;
		}
	}

	public static Integer BULK_LIST_SIZE {
		get {
			return OrganizationUtilities.isProduction() ? 10 : 200;
		}
	}

	public static void create_price_book_entries() {
		List<Product2> list_Products = new List<Product2>();
		list_Products.add(new TestDataFactory.ProductBuilder().setName('Medical').setFamily('Benefit').build());
		list_Products.add(new TestDataFactory.ProductBuilder().setName('Dental').setFamily('Employee').build());
		list_Products.add(new TestDataFactory.ProductBuilder().setName('Vision').setFamily('Employee').build());
		list_Products.add(new TestDataFactory.ProductBuilder().setName('Life').setFamily('Employee').build());
		insert list_Products;

		List<PricebookEntry> list_PricebooksEntries = new List<PricebookEntry>();
		list_PricebooksEntries.add(
			new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[0].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(true).build()
		);
		list_PricebooksEntries.add(
			new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[1].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(true).build()
		);
		list_PricebooksEntries.add(
			new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[2].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(true).build()
		);
		list_PricebooksEntries.add(
			new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[3].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(true).build()
		);

		Id standardPricebookId = Test.getStandardPricebookId();
		List<PricebookEntry> list_StandardEntries = list_PricebooksEntries.deepClone(false);
		for (PricebookEntry pbe : list_StandardEntries) {
			pbe.Pricebook2Id = standardPricebookId;
		}
		insert list_StandardEntries;
		insert list_PricebooksEntries;
	}

	/*** Creates a new GF Lead record with basic details ***/
	public static GF_Lead__c createNewGFLead(String strType, String strEmail, String strFirstName, String strLastName, String strPhone, Boolean blnIsInsert) {
		GF_Lead__c objGFLead = new GF_Lead__c(
			Lead_Type__c = strType,
			First_Name__c = strFirstName,
			Last_Name__c = strLastName,
			Email__c = strEmail,
			Phone__c = strPhone,
			Source__c = 'LinkedIn Lead Gen'
		);

		if (blnIsInsert) {
			insert objGFLead;
		}
		return objGFLead;
	}

	/*** Creates a new Lead record with basic details ***/
	public static Lead createNewLead(Id idRecordType, String strFirstName, String strLastName, String strEmail, String strPhone, String strCompany, Boolean blnIsInsert) {
		Lead objLead = new Lead(RecordTypeId = idRecordType, FirstName = strFirstName, LastName = strLastName, Email = strEmail, Phone = strPhone, Company = strCompany);

		if (blnIsInsert) {
			insert objLead;
		}
		return objLead;
	}

	/*** Creates a ZP Accounting Firm record with basic details ***/
	public static ZP_Accounting_Firm__c createZPAccountingFirm(String strId, String strName, String strCreatedByEmail, Boolean blnIsInsert) {
		ZP_Accounting_Firm__c objFirm = new ZP_Accounting_Firm__c(Id__c = strId, Name__c = strName, Created_by_Email__c = strCreatedByEmail);

		if (blnIsInsert) {
			insert objFirm;
		}
		return objFirm;
	}

	/*** Creates a ZP Company record with basic details ***/
	public static ZP_Company__c createZPCompany(String strId, String strName, String strCreatedByEmail, Boolean blnIsInsert) {
		ZP_Company__c objZPCompany = new ZP_Company__c(Id__c = strId, Name__c = strName, Created_by_Email__c = strCreatedByEmail);

		if (blnIsInsert) {
			insert objZPCompany;
		}
		return objZPCompany;
	}

	/*** Creates Task record with basic details ***/
	public static Task createTask(Id idRecordType, String strSubject, Id idWhatId, Boolean blnIsInsert) {
		Task objTask = new Task(RecordTypeId = idRecordType, Subject = strSubject, WhatId = idWhatId);
		if (blnIsInsert) {
			insert objTask;
		}
		return objTask;
	}

	/*** Create Account record with basic details ***/
	public static Account createAccount(Id idRecordType, String strName, Boolean blnIsInsert) {
		Account objAccount = new Account(RecordTypeId = idRecordType, Name = strName);
		if (blnIsInsert) {
			insert objAccount;
		}
		return objAccount;
	}

	/*** Create Opportunity record with basic details ***/
	public static Opportunity createOpportunity(Id idRecordType, Id idAccount, Date dtCloseDate, String strName, String strStage, Boolean blnIsInsert) {
		Opportunity objOppty = new Opportunity(RecordTypeId = idRecordType, AccountId = idAccount, CloseDate = dtCloseDate, Name = strName, StageName = strStage);
		if (blnIsInsert) {
			insert objOppty;
		}
		return objOppty;
	}

	/*** Create Contact record with basic details ***/
	public static Contact createContact(Id idAccount, String strFirstName, String strLastName, String strEmail, Boolean blnIsInsert) {
		Contact objContact = new Contact(AccountId = idAccount, FirstName = strFirstName, LastName = strLastName, Email = strEmail);
		if (blnIsInsert) {
			insert objContact;
		}
		return objContact;
	}
}