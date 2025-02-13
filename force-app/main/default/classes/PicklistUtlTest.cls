/**
 * Created by brent.johnson on 3/30/16.
 */

@isTest
private class PicklistUtlTest {
	private static String testObject;
	private static String testField;
	private static String testCurrentValue;

	@isTest
	private static void lastItemNext() {
		givenFieldIsOpportunityStageName();
		whenCurrentValueIsLastItem();
		thenGetNextIs(false);
	}

	@isTest
	private static void valueIsNullNext() {
		givenFieldIsOpportunityStageName();
		whenCurrentValueIsNull();
		thenGetNextIs(false);
	}

	@isTest
	private static void valueIsInvalidNext() {
		givenFieldIsOpportunityStageName();
		whenCurrentValueIsInvalid();
		thenGetNextIs(false);
	}

	@isTest
	private static void fieldIsNullNext() {
		givenFieldIsOpportunityStageName();
		whenCurrentValueIsInvalid();
		thenGetNextIs(false);
	}

	@isTest
	private static void fieldIsNotAPicklistNext() {
		givenFieldIsOpportunityCloseDate();
		thenGetNextIs(false);
	}

	private static void givenFieldIsOpportunityStageName() {
		testObject = 'Opportunity';
		testField = 'StageName';
	}

	private static void givenFieldIsOpportunityCloseDate() {
		testObject = 'Opportunity';
		testField = 'CloseDate';
	}

	private static void whenCurrentValueIsFirstItem() {
		List<PicklistEntry> entries = Opportunity.StageName.getDescribe().getPicklistValues();
		testCurrentValue = entries.get(0).getValue();
	}

	private static void whenCurrentValueIsLastItem() {
		List<PicklistEntry> entries = Opportunity.StageName.getDescribe().getPicklistValues();
		testCurrentValue = entries.get(entries.size() - 1).getValue();
	}

	private static void whenCurrentValueIsNull() {
		testCurrentValue = null;
	}

	private static void whenCurrentValueIsInvalid() {
		testCurrentValue = 'INVALID VALUE';
	}

	private static void thenGetNextIs(Boolean success) {
		List<PicklistUtl.PicklistRequest> requests = new List<PicklistUtl.PicklistRequest>();
		requests.add(setPicklistRequest());
		List<PicklistUtl.PicklistResult> results = PicklistUtl.getNext(requests);
		System.assertEquals(success, results[0].isSuccess(), results[0].getMessage());
	}

	private static PicklistUtl.PicklistRequest setPicklistRequest() {
		PicklistUtl.PicklistRequest request = new PicklistUtl.PicklistRequest();
		request.objectName = testObject;
		request.fieldName = testField;
		request.currentValue = testCurrentValue;
		return request;
	}
}