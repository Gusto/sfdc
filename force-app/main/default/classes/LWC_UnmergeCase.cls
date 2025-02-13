public class LWC_UnmergeCase {
	@AuraEnabled
	public static WrapperResponse getCaseRecordType(String caseId) {
		WrapperResponse wrapperResponseObj;
		Map<String, Object> response = new Map<String, Object>();
		Case caseRec = [SELECT RecordTypeId, RecordType.Name, Status, Closed_Reason__c FROM case WHERE id = :caseId LIMIT 1];
		if (caseRec != null) {
			if (caseRec.RecordType.Name.contains('Read Only')) {
				response.put('caseRec', caseRec);
				wrapperResponseObj = new WrapperResponse(response, true, 'Success');
			} else {
				wrapperResponseObj = new WrapperResponse(null, false, 'No Record Found');
			}
		} else {
			wrapperResponseObj = new WrapperResponse(null, false, 'No Record Found');
		}
		return wrapperResponseObj;
	}
	@AuraEnabled
	public static WrapperResponse unmergeCaseRecord(Case caseRec) {
		WrapperResponse wrapperResponseObj;
		Map<String, Object> response = new Map<String, Object>();
		if (caseRec != null) {
			String ReadOnlyStr = caseRec.RecordType.Name;
			String withoutReadOnlyStr = ReadOnlyStr.SubStringBefore(' - Read Only');
			for (RecordType rt : [SELECT Id, Name, DeveloperName FROM RecordType WHERE sObjectType = 'Case']) {
				if (rt.Name == withoutReadOnlyStr) {
					caseRec.RecordTypeId = rt.Id;
					caseRec.Status = 'Open';
					caseRec.Closed_Reason__c = '';
				}
			}

			try {
				update caseRec;
				response.put('caseRec', caseRec);
				wrapperResponseObj = new WrapperResponse(response, true, 'Success');
			} catch (Exception ex) {
				wrapperResponseObj = new WrapperResponse(null, false, 'Error while updating case' + ex.getMessage());
			}
		} else {
			wrapperResponseObj = new WrapperResponse(null, false, 'No Record Found');
		}
		return wrapperResponseObj;
	}
	public class WrapperResponse {
		@AuraEnabled
		public map<String, Object> responseData;
		@AuraEnabled
		public Boolean isSuccess;
		@AuraEnabled
		public string message;
		public WrapperResponse(Map<String, Object> responseData, Boolean isSuccess, String responseMessage) {
			this.responseData = responseData;
			this.isSuccess = isSuccess;
			this.message = responseMessage;
		}
	}
}