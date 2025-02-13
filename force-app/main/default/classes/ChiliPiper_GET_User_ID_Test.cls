@isTest
public class ChiliPiper_GET_User_ID_Test {
    @isTest
    static void test_processRecords_success() {
        // Create test data
        List<String> recordIds = new List<String> {'A000'};

        // Create a fake response
        String fakeResponse = '[{"id": "1"}]';

        // Create a mock for the HTTP callout
        HttpResponse fakeRes = new HttpResponse();
        fakeRes.setBody(fakeResponse);
        fakeRes.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new ChiliPiper_GET_User_ID_Mock(fakeRes));

        // Call the method being tested
        List<String> results = ChiliPiper_GET_User_ID.processRecords(recordIds);

        // Assert that the result is as expected
        System.assertNotEquals(null, results);
        System.assertEquals(1, results.size());
        System.assertEquals('1', results[0]);
    }

    @isTest
    static void test_processRecords_null_recordIds() {
        // Call the method being tested
        List<String> results = ChiliPiper_GET_User_ID.processRecords(null);

        // Assert that the result is as expected
        System.assertEquals(0, results.size());
    }

    @isTest
    static void test_processRecords_empty_recordIds() {
        // Call the method being tested
        List<String> results = ChiliPiper_GET_User_ID.processRecords(new List<String>());

        // Assert that the result is as expected
        System.assertEquals(0, results.size());
    }

    // Class to mock the HTTP callout
class ChiliPiper_GET_User_ID_Mock implements HttpCalloutMock {
    private HttpResponse fakeRes;
    public ChiliPiper_GET_User_ID_Mock(HttpResponse res) {
        this.fakeRes = res;
    }
    public HTTPResponse respond(HTTPRequest req) {
        return this.fakeRes;
    }
}
}