public with sharing class ChiliPiper_DELETE_User {
    @InvocableMethod
    public static List<String> deleteRecords(List<String> recordIds) {
        List<String> results = new List<String>();
        
         // Get Custom Metadata Values
        String url;
        String token;
        if(Test.isRunningTest()){
            url = 'https://yourtesturl.com/';
            token = 'yourtesttoken';
        }else{     
        url = 'https://edge.chilipiper.com/users/';
        token = Chili_Piper_Settings__mdt.getInstance('Settings').Cookie__c;
        }

        for (String recordId : recordIds) {
            // Build the request URL with the record ID
            String requestUrl = url + recordId;

            // Set up the request headers
            Map<String, String> headers = new Map<String, String>();
            headers.put('accept', '*/*');
            headers.put('cookie', token);

            // Make the DELETE request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(requestUrl);
            req.setMethod('DELETE');
            for (String key : headers.keySet()) {
                req.setHeader(key, headers.get(key));
            }
            Http http = new Http();
            HTTPResponse res = http.send(req);

            // Check the response status code
            if (res.getStatusCode() == 200) {
                // Request was successful
                System.debug('ChiliPiper DELETE request was successful');
                results.add(recordId);
            } else {
                // Request failed
                System.debug('ChiliPiper DELETE request failed');
            }
        }

        return results;
    }
}