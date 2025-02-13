@isTest
private class AnswerIQConfidenceJSONTest {
	@isTest
	static void testJSONParse() {
		String jsonStr = '{"cls_Confirm_Case_Reason":{"confident":true, "tag":"test tag"}}';
		AnswerIQConfidenceJSON.parse(jsonStr);
	}
}