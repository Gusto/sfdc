public with sharing class DefaultDataServiceProcessor extends DataServiceProcessor {
    Map<String, Object> requestDataMap;
    Object requestData;
    List<Object> dataObjs = new List<Object>();
    Map<String, Object> responseMap = new Map<String, Object>{
        'success' => true
    };
    Map<String, SObject> sobjs = new Map<String, SObject>();
    String sobjectName;

    public override Map<String, Object> execute(Object requestData) {
        this.requestData = requestData;
        this.sobjectName = super.getSObjectName();

        dataObjs.add(requestData);
        if (isListType()) {
            dataObjs = (List<Object>) requestData;
        }

        sobjs = getRecords();

        List<SObject> records = new List<SObject>();
        for (Object dataObj : dataObjs) {
            Map<String, Object> requestDataMap = (Map<String, Object>) dataObj;
            SObject sobj = getSObject(requestDataMap);

            super.setValues(sobj, requestDataMap);
            records.add(sobj);
        }

        upsert records;
        return responseMap;
    }

    private SObject getSObject(Map<String, Object> requestDataMap) {
        if (
            requestDataMap.containsKey(super.getKeyField()) &&
            sobjs.containsKey((String) requestDataMap.get(super.getKeyField()))
        ) {
            return sobjs.get((String) requestDataMap.get(super.getKeyField()));
        }
        return Schema.getGlobalDescribe().get(sobjectName).newSObject();
    }

    private Map<String, SObject> getRecords() {
        Map<String, SObject> sobjs = new Map<String, SObject>();

        List<String> guids = new List<String>();

        for (Object dataObj : dataObjs) {
            Map<String, Object> requestDataMap = (Map<String, Object>) dataObj;
            if (requestDataMap.containsKey(super.getKeyField())) {
                String systemId = (String) requestDataMap.get(
                    super.getKeyField()
                );
                guids.add(systemId);
            }
        }

        for (SObject sobj : super.getRecords(guids)) {
            sobjs.put((String) sobj.get(super.getIdField()), sobj);
        }
        return sobjs;
    }

    private Boolean isListType() {
        return requestData instanceof List<Object>;
    }
}