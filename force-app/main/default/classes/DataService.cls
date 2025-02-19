@RestResource(urlMapping='/DataService/*')
global with sharing class DataService {
    static Map<String, Object> requestMap = new Map<String, Object>();
    static Map<String, Object> responseMap = new Map<String, Object>{
        'success' => true
    };
    static String requestName;
    public static DataResponse response = new DataResponse();

    @HttpPut
    global static void doPut() {
        RestContext.response.statusCode = 201;
        String requestJson = RestContext.request.requestBody.toString();
        try {
            requestMap = (Map<String, Object>) JSON.deserializeUntyped(
                requestJson
            );
            requestName = (String) requestMap.get('requestName');
            processRequest();
            RestContext.response.responseBody = Blob.valueOf(
                JSON.serialize(response)
            );
        } catch (Exception e) {
            response.success = false;
            response.message =
                'Error: ' +
                e.getMessage() +
                '\n\n\n' +
                e.getStackTraceString();
            RestContext.response.statusCode = 500;
        }
    }

    static void processRequest() {
        DataServiceProcessor processor = getProcessor();
        if (processor == null) {
            response.success = false;
            response.message = 'Invalid Request';
            return;
        }

        response.init(processor.execute(requestMap.get('data')));
    }

    static DataServiceProcessor getProcessor() {
        List<Data_Servicer__mdt> servicerMdts = [
            SELECT
                Apex_Class__c,
                Key_Field__c,
                Id_Field__c,
                (
                    SELECT Source__c, Target__c, SObject__c, Data_Type__c
                    FROM Data_Service_Mappings__r
                )
            FROM Data_Servicer__mdt
            WHERE Label = :requestName
        ];
        if (servicerMdts.isEmpty()) {
            return null;
        }
        DataServiceProcessor processor;
        Type myType = Type.forName(servicerMdts[0].Apex_Class__c);
        if (myType != null) {
            processor = (DataServiceProcessor) myType.newInstance();
            processor.init(servicerMdts[0]);
        }

        return processor;
    }

    global class DataResponse {
        public String data;
        public Boolean success;
        public String message;

        public void init(Map<String, Object> processorData) {
            this.success = (Boolean) processorData.get('success');
            if (processorData.containsKey('message')) {
                this.message = (String) processorData.get('message');
            }
            if (processorData.containsKey('data')) {
                this.data = Json.serialize(processorData.get('data'));
            }
        }
    }
}