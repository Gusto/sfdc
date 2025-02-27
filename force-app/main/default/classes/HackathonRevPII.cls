public class HackathonRevPII{
    public String transcribed_text;	//Jake, got it. Thanks. Wait, this file has full names, addresses, and even Social Security number.
    public PIIInfoWrapper pii_info;
    
    class PIIInfoWrapper {
        public List<PIIDetails> PII_Info;
        public SentimentInfo Sentiment_Info;
    }
    
    class PIIDetails {
        public String Type;	//NAME
        public Double Score;	//0.9999957084655762
        public String DetectedText;	//Jake
        public Integer BeginOffset;	//0
        public Integer EndOffset;	//4
    }
    
    class SentimentInfo {
        public String Sentiment;	//NEUTRAL
        public SentimentScoreWrapper SentimentScore;
    }
    
    class SentimentScoreWrapper {
        public Double Positive;	//0.2792975604534149
        public Double Negative;	//0.0008705260115675628
        public Double Neutral;	//0.7196993231773376
        public Double Mixed;	//0.00013266134192235768
    }
    
    public static HackathonRevPII parse(String json){
        return (HackathonRevPII) System.JSON.deserialize(json, HackathonRevPII.class);
    }
    
    @AuraEnabled
    public static void makeURL(Id recordId) {
        System.debug(recordId);
        ContentDocumentLink objCDL = [SELECT Id, ContentDocumentId, ContentDocument.Title, ContentDocument.LatestPublishedVersionId, ContentDocument.LatestPublishedVersion.filetype FROM ContentDocumentLink WHERE LinkedEntityId = :recordId][0];
        
        ContentDistribution objCD =  new ContentDistribution(
            Name = objCDL.ContentDocument.Title,
            ContentVersionId = objCDL.ContentDocument.LatestPublishedVersionId,
            PreferencesAllowOriginalDownload = true
        );
        
        insert objCD;
    }
    
    @AuraEnabled
    public static void makeApiCallout(Id recordId) {
        try {
            
            ContentDocumentLink objCDL = [SELECT Id, ContentDocumentId, ContentDocument.Title, ContentDocument.LatestPublishedVersionId, ContentDocument.LatestPublishedVersion.filetype FROM ContentDocumentLink WHERE LinkedEntityId = :recordId][0];
            List<ContentDistribution> list_CD = [SELECT Id, ContentDownloadUrl FROM ContentDistribution WHERE ContentDocumentId = :objCDL.ContentDocumentId];
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://z80ywxg7t5.execute-api.us-west-2.amazonaws.com/dev/PhiPIIDetection'); // Replace with your endpoint
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('x-api-key', 'KEFQf7kUmPakRCyXD0kPA3N08cYvhOpT6P365a8o');  // Include your API Key here
            req.setTimeout(60000); // Timeout is in milliseconds, 20000 ms = 20 seconds
            // Properly formatted request body without line breaks
            //req.setBody('{"body": \"{\\\"url\\\": \\\"https://files.soundoftext.com/82fc2e00-f3e5-11ef-bbfe-19a6f1097474.mp3\\\"}\"}');  // Test Deepak 1
            //req.setBody('{"body": \"{\\\"url\\\": \\\"https://gusto--uat.sandbox.file.force.com/sfc/dist/version/download/?oid=00D020000004i4T&ids=068TH000003ufTN&d=%2Fa%2FTH000001Dtyz%2FKzM7D1QXUJoxEvOjRTQXnWUDO1qRuOC3hxA6rYrBmpk&asPdf=false\\\"}\"}'); // Test Deepak 2
            req.setBody('{"body": \"{\\\"url\\\": \\\"'+list_CD[0].ContentDownloadUrl+'\\\"}\"}'); // Test actual
            // Send the request
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            delete list_CD;
            
            // Process response
            if (res.getStatusCode() == 200) {
                Map<String, object> map_responseBody = (Map<String, object>) JSON.deserializeUntyped(res.getBody());
                HackathonRevPII objHackathonRevPII = HackathonRevPII.parse((String)map_responseBody.get('body'));
                System.debug(objHackathonRevPII);
                Hackathon_Object__c objRecToUpdate = new Hackathon_Object__c(Id=recordId);
                objRecToUpdate.PII_Info_Found__c = objHackathonRevPII.pii_info.PII_Info.size();
                objRecToUpdate.Sentiment__c = objHackathonRevPII.pii_info.Sentiment_Info.Sentiment;
                List<String> piiDetectedTexts = new List<String>();
				for (HackathonRevPII.PIIDetails pii : objHackathonRevPII.pii_info.PII_Info) {
                    piiDetectedTexts.add(pii.Type + ': ' + pii.DetectedText);

    				//piiDetectedTexts.add(pii.DetectedText);
				}
				objRecToUpdate.PII_Details__c = String.join(piiDetectedTexts, ', ');
                objRecToUpdate.RawResponse__c = objHackathonRevPII.transcribed_text;
                update objRecToUpdate;
            } else {
                throw new HackathonRevPIIException('API returned error: ' + res.getStatusCode() + ' ' + res.getStatus());
            }
        } catch (Exception e) {
            System.debug('Error in makeApiCallout: ' + e.getMessage());
            System.debug(e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class HackathonRevPIIException extends Exception {}
    
    /*static testMethod void testParse() {
String json=		'{"transcribed_text": "Jake, got it. Thanks. Wait, this file has full names, addresses, and even Social Security number.", "pii_info": {"PII_Info": [{"Type": "NAME", "Score": 0.9999957084655762, "DetectedText": "Jake", "BeginOffset": 0, "EndOffset": 4}], "Sentiment_Info": {"Sentiment": "NEUTRAL", "SentimentScore": {"Positive": 0.2792975604534149, "Negative": 0.0008705260115675628, "Neutral": 0.7196993231773376, "Mixed": 0.00013266134192235768}}}}';
HackathonRevPII obj = parse(json);
System.assert(obj != null);
}*/
}