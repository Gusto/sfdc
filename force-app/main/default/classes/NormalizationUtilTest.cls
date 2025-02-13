/**
 * @name         NormalizationUtilTest
 * @author       David (Dato) Tsamalashvili
 * @date         20/05/2022
 * @description  Test class for NormalizationUtil
 * @see NormalizationUtil
 **/
@isTest
public with sharing class NormalizationUtilTest {
	@testSetup
	private static void setup() {
		skipTrigger(true);

		List<Account> list_AccountsToInsert = new List<Account>();
		
		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setName('Test Company Account')
			.setRecordTypeId('Company')
			.setZPCompanyId('1234567890')
			.build(); 

		list_AccountsToInsert.add(objCompanyAccount);

		Account objResellerAccount = new TestDataFactory.AccountBuilder()
			.setName('Test Company Account')
			.setRecordTypeId('Company')
			.build();

		list_AccountsToInsert.add(objResellerAccount);

		insert list_AccountsToInsert;

		String strContactZPUserId = '789456123';
		Contact objContact = new Contact(
			LastName = 'Test Contact',
			RecordTypeId = ContactUtil.COMPANY_CONTACT_RT_ID,
			AccountId = objCompanyAccount.Id,
			Email = 'test@company.com',
			ZP_User_Id__c = strContactZPUserId
		);
		insert objContact;

        Email_Domain__c objEmailDomain = new TestDataFactory.EmailDomainBuilder().setName('nameTest').build();
		insert objEmailDomain;

        Company_acronyms__c objCompAcro = new TestDataFactory.CompanyAcronymsBuilder().setName('corp').build();
        insert objCompAcro;

        Street_Suffix_Abbrevation__c objStrSuffix = new TestDataFactory.StreetSufAbbrevationBuilder().setName('ALLEY').setStandardized('ALY').build();
        insert objStrSuffix;

        Secondary_Unit_Designators__c objSecUnitDes = new TestDataFactory.SecondaryUnitDesignatorsBuilder().setName('Apartment').setStandardized('APT').build();
        insert objSecUnitDes;

        Geographical_Directions_Acronyms__c objGoeDirectAcr = new TestDataFactory.GeoDirecAcrBuilder().setName('East').setStandardizedValue('E').build();
        insert objGoeDirectAcr;

		skipTrigger(false);
	}

	@isTest
	private static void testNormalizationOnInsert() {
		Test.startTest();
		Account objAccount = [SELECT Id FROM Account WHERE ZP_Company_ID__c = '1234567890' LIMIT 1];
		NormalizationUtil objNormalization = new NormalizationUtil();

		Map<String, String> map_EmailToNormalizedValue = new Map<String, String>();

		map_EmailToNormalizedValue = objNormalization.normaliseDomainFieldBulkified(new Set<String>{ 'TESTEMAIL@TESTING.COM' });

		Contact objContact = new Contact(
			LastName = 'Test Contact',
			RecordTypeId = ContactUtil.COMPANY_CONTACT_RT_ID,
			AccountId = objAccount.Id,
			Email = 'TESTEMAIL@zenefits.com',
			Alternate_Email__c = 'TESTEMAIL@zenefits.com',
			Phone = '(123)-456-7890',
			MobilePhone = '(123)-456-7890',
			OtherPhone = '(123)-456-7890'
		);
		insert objContact;

		Contact objContactAssert = [
			SELECT
				Id,
				Normalized_Email_Domain__c,
				Normalized_Alternate_Email_Domain__c,
				Email,
				Alternate_Email__c,
				Phone,
				Normalized_Phone__c,
				MobilePhone,
				Normalized_Mobile_Phone__c,
				OtherPhone,
				Normalized_Other_Phone__c
			FROM Contact
			WHERE Id = :objContact.Id
		];

		System.assertEquals(objContactAssert.Normalized_Phone__c, objNormalization.normalisePhoneField(objContactAssert.Phone), 'Phone number not normalized successfully');
		System.assertEquals(objContactAssert.Normalized_Mobile_Phone__c, objNormalization.normalisePhoneField(objContactAssert.MobilePhone), 'Mobile Phone number not normalized successfully');
		System.assertEquals(objContactAssert.Normalized_Other_Phone__c, objNormalization.normalisePhoneField(objContactAssert.OtherPhone), 'Other Phone number not normalized successfully');

		if (map_EmailToNormalizedValue.containsKey(objContactAssert.Email)) {
			System.assertEquals(objContactAssert.Normalized_Email_Domain__c, map_EmailToNormalizedValue.get(objContactAssert.Email), 'Email domains not normalized successfully');
			System.assertEquals(
				objContactAssert.Normalized_Alternate_Email_Domain__c,
				map_EmailToNormalizedValue.get(objContactAssert.Alternate_Email__c),
				'Alternate Email domains not normalized successfully'
			);
		}
		Test.stopTest();
	}

	@isTest
	private static void testNormaliseDomainField() {
		Test.startTest();
		NormalizationUtil objNormalization = new NormalizationUtil();
		String strDomainRes = objNormalization.normaliseDomainField('test@nameTest.com');
        String strNameRes = objNormalization.normaliseNameField('TestName');
        String strEmailRes = objNormalization.normaliseAddressField('www.gustotest@test.com');
        String strPostalCodeRes = objNormalization.normalisePostalCodeField('80111000');

		Test.stopTest();
	}

	public static void skipTrigger(Boolean blnFlag) {
		AccountTriggerHelper.skipTrigger = blnFlag;
		ContactTriggerHelper.skipTrigger = blnFlag;
		OpportunityTriggerHelper.skipTrigger = blnFlag;
		CaseTriggerHelper.skipTrigger = blnFlag;
	}
}