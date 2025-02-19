public abstract with sharing class DataServiceProcessor {
    List<String> handledFieldTypes = new List<String>{ 'DATE', 'DATETIME' };
    Map<String, SObjectType> sobjectTypes = Schema.getGlobalDescribe();
    Map<String, SObjectField> sobjectFields;
    String sobjectName;
    List<Data_Service_Mapping__mdt> mappings;
    String keyField;
    String idField;

    public abstract Map<String, Object> execute(Object dataObj);

    public virtual void setValues(
        SObject sobj,
        Map<String, Object> dataObjMap
    ) {
        for (Data_Service_Mapping__mdt mapping : mappings) {
            if (dataObjMap.containsKey(mapping.Source__c)) {
                Object requestValue = getValue(mapping, dataObjMap);
                String objectField = mapping.Target__c;
                if (mapping.Target__c != 'GUID__c') {
                    sobj.put(objectField, requestValue);
                }
            }
        }
    }

    public String getKeyField() {
        return this.keyField;
    }

    public String getIdField() {
        return this.idField;
    }

    public String getSObjectName() {
        return this.sobjectName;
    }

    public void init(Data_Servicer__mdt servicerMdt) {
        this.keyField = servicerMdt.Key_Field__c;
        this.mappings = servicerMdt.Data_Service_Mappings__r;
        this.idField = servicerMdt.Id_Field__c;
        this.sobjectName = this.mappings[0].SObject__c;
    }

    public List<SObject> getRecords(List<String> guids) {
        String filterGuids = '(\'' + String.join(guids, '\', \'') + '\')';
        String query =
            'SELECT Id, ' +
            getIdField() +
            ' FROM ' +
            String.escapeSingleQuotes(sobjectName) +
            ' WHERE ' +
            String.escapeSingleQuotes(idField) +
            ' IN ' +
            filterGuids;

        return Database.query(query);
    }

    Object getValue(Data_Service_Mapping__mdt mapping, Map<String, Object> dataObjMap) {
        Object value = dataObjMap.get(mapping.Source__c);

        if (handledFieldTypes.contains(mapping.Data_Type__c) && value != null) {
            value = getHandledValue(mapping.Data_Type__c, value);
        }

        return value;
    }

    Object getHandledValue(String fieldType, Object value) {
        switch on fieldType {
            // when 'DATETIME' {
            //     value = getDateTime(value);
            // }
            when 'DATE' {
                value = getDate(value);
            }
        }
        return value;
    }

    // String getRelationshipName(String fieldName) {
    //     return sobjectFields.get(fieldName).getDescribe().getRelationshipName();
    // }

    // SObject getReferenceValue(String sRequestType, String idValue) {
    //     return sobjectTypes.get(sRequestType).newSObject();
    // }

    // void setSObjectFields(String sobjectName) {
    //     sobjectFields = sobjectTypes
    //         .get(sobjectName)
    //         .getDescribe(SObjectDescribeOptions.DEFERRED)
    //         .fields.getMap();
    // }

    // DateTime getDateTime(Object value) {
    //     String stringValue = String.valueOf(value);
    //     DateTime dt = DateTime.newInstance(Long.valueOf(stringValue));
    //     return dt;
    // }

    Date getDate(Object value) {
        String stringValue = String.valueOf(value);
        List<String> dateParts = stringValue.split('-');
        String dateString =
            dateParts[1] +
            '/' +
            dateParts[2] +
            '/' +
            dateParts[0];
        Date d = Date.parse(dateString);
        return d;
    }
}