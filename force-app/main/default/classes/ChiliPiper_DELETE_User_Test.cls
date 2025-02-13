@isTest
public class ChiliPiper_DELETE_User_Test {
	

     class TestHttpCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testDeleteRecords() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestHttpCalloutMock());

        // Call the deleteRecords method and store the result
        List<String> recordIds = new List<String>{'123', '456', '789'};
        List<String> result = ChiliPiper_DELETE_User.deleteRecords(recordIds);

        // Verify the results
        System.assertEquals(recordIds.size(), result.size(), 'Number of deleted records should match input');
        for (String id : recordIds) {
            System.assert(result.contains(id), 'Deleted record ID should be in the result list');
        }

        Test.stopTest();
    }
}