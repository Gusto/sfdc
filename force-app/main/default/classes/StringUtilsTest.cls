/**
 * @description Classes for String Utilities
 * @author Rushi Ravisaheb
 * @author David Schach
 * @see StringUtils
 **/
@isTest
private class StringUtilsTest {
	/**
	 * @author      Rushi Ravisaheb
	 * @description Test getJoinedString method with all parameters
	 **/
	@isTest
	static void testStringJoinMethod() {
		String strResult = '';
		Test.startTest();
		strResult = StringUtils.getJoinedString('Switchable Responsive System Engine - Repurpose Intuitive Niches Complete Corporation Pvt Ltd.', 'Company', 'Opportunity Renewal', null, 120);
		Test.stopTest();

		System.assert(String.isNotBlank(strResult));
		System.assert(strResult.length() <= 120);
		System.assert(!strResult.contains('Renewal'));
	}

	/**
	 * @author      David Schach
	 * @description Test getJoinedString method for custom object name field
	 **/
	@isTest
	static void testCustomObjectName() {
		String strResult = '';
		Test.startTest();
		strResult = StringUtils.getRecordName('Switchable Responsive System Engine - Repurpose Intuitive Niches Complete Corporation Pvt Ltd.', 'This is also a long string');
		Test.stopTest();

		System.assert(String.isNotBlank(strResult));
		System.assert(strResult.length() <= 80);
		System.assert(!strResult.contains('long'));
	}

	/**
	 * @author      Rushi Ravisaheb
	 * @description Test getOppName method with all parameters
	 **/
	@isTest
	static void testOppNameMethod() {
		String strResult = '';
		Test.startTest();
		strResult = StringUtils.getOppName('Company - Switchable Responsive System Engine - Repurpose Intuitive Niches Complete Corporation Pvt Ltd.', 'Opportunity Renewal');
		Test.stopTest();

		System.assert(String.isNotBlank(strResult));
		System.assert(strResult.length() <= 120);
		System.assert(!strResult.contains('Renewal'));
	}
}