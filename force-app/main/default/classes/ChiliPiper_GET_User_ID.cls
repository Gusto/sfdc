public with sharing class ChiliPiper_GET_User_ID {
    @InvocableMethod
    public static List<String> processRecords(List<String> recordIds) {
        if(recordIds == null || recordIds.isEmpty()) {
            return new List<String>();
        }
        List<String> results = new List<String>();
        
        // Get Custom Metadata Values
        String url;
        String token;
        if(Test.isRunningTest()){
            url = 'https://yourtesturl.com/';
            token = 'yourtesttoken';
        }else{
            url = 'https://edge.chilipiper.com/users/find?sfid=';
            token = Chili_Piper_Settings__mdt.getInstance('Settings').Cookie__c;
        }
        for (String recordId : recordIds) {
            // Build the request URL with the record ID
            String requestUrl = url + recordId;

            // Set up the request headers
            Map<String, String> headers = new Map<String, String>();
            headers.put('accept', '*/*');
            headers.put('cookie', token);

            // Make the GET request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(requestUrl);
            req.setMethod('GET');
            for (String key : headers.keySet()) {
                req.setHeader(key, headers.get(key));
            }
            Http http = new Http();
            HTTPResponse res = http.send(req);

            // Check the response status code
            if (res.getStatusCode() == 200) {
                // Request was successful
                System.debug('ChiliPiper request was successful');

                // Parse the response to get the "Chili Piper User id"
                List<Object> responseJson = (List<Object>)JSON.deserializeUntyped(res.getBody());
                if(responseJson != null && !responseJson.isEmpty()){
                    Map<String, Object> userInfo = (Map<String, Object>)responseJson[0];
                    if(userInfo != null && userInfo.get('id') != null){
                        String id = (String)userInfo.get('id');
                        results.add(id);
                    }
                }
            } else {
                // Request failed
                System.debug('ChiliPiper request failed');
            }
        }

        return results;
    }
}