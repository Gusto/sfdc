/**
 * @description  Generic class used for retrieving fields from opportunity and account field sets
 * @author       Praveen Sethu
 * @date         09-07-2023
 * @see			 NBAMiniViewControllerTest
 **/
public class NBAMiniViewController {
	/**
	 * @description  Wrapper class to share response with Aura Component
	 * @author       Praveen Sethu
	 **/
	public class NBAMiniViewWrapperResponse {
		@AuraEnabled
		public Boolean blnSuccess;

		@AuraEnabled
		public String strMessage;

		@AuraEnabled
		public List<String> list_OppFields = new List<String>();

		@AuraEnabled
		public List<String> list_AccFields = new List<String>();

		@AuraEnabled
		public List<String> list_LeadFields = new List<String>();

		@AuraEnabled
		public Opportunity objOppty = new Opportunity();

		public NBAMiniViewWrapperResponse(Boolean blnSuccess, String strMessage, List<String> list_OppFields, List<String> list_AccFields, List<String> list_LeadFields, Opportunity objOppty) {
			this.blnSuccess = blnSuccess;
			this.strMessage = strMessage;
			this.list_OppFields = list_OppFields;
			this.list_AccFields = list_AccFields;
			this.list_LeadFields = list_LeadFields;
			this.objOppty = objOppty;
		}
	}

	/**
	 * @author      Praveen Sethu
	 * @description Method accepts names of opportunity and account field sets and returns list of fields from the set
	 * @param		Name of opportunity field set
	 * @param		Name of Account field set
	 * @param		Opportunity record Id
	 **/
	@AuraEnabled
	public static NBAMiniViewWrapperResponse getFieldsFromFieldSet(String strOppFieldSet, String strAccFieldSet, String strLeadFieldSet, Id oppRecordId) {
		List<String> list_OppFields = new List<String>();
		List<String> list_AccFields = new List<String>();
		List<String> list_LeadFields = new List<String>();
		Opportunity objOppToReturn = new Opportunity();

		try {
			// check if name of field set is not blank before retrieving opportunity fields
			if (String.isNotBlank(strOppFieldSet)) {
				for (Schema.FieldSetMember fld : Schema.SObjectType.Opportunity.fieldSets.getMap().get(strOppFieldSet).getFields()) {
					list_OppFields.add(fld.getFieldPath());
				}
			}

			// check if name of field set is not blank before retrieving account fields
			if (String.isNotBlank(strAccFieldSet)) {
				for (Schema.FieldSetMember fld : Schema.SObjectType.Account.fieldSets.getMap().get(strAccFieldSet).getFields()) {
					list_AccFields.add(fld.getFieldPath());
				}
			}

			// check if name of field set is not blank before retrieving lead fields
			if (String.isNotBlank(strLeadFieldSet)) {
				for (Schema.FieldSetMember fld : Schema.SObjectType.Lead.fieldSets.getMap().get(strLeadFieldSet).getFields()) {
					list_LeadFields.add(fld.getFieldPath());
				}
			}

			// Get data from Opportunity
			if (oppRecordId != null && oppRecordId.getSObjectType().getDescribe().getName() == 'Opportunity') {
				List<Opportunity> list_Opps = [SELECT Id, AccountId FROM Opportunity WHERE Id = :oppRecordId];

				if (!list_Opps.isEmpty()) {
					objOppToReturn = list_Opps.get(0);
				}
			}

			// Return response back to Aura component
			return new NBAMiniViewWrapperResponse(true, 'Field Sets retrieved successfully', list_OppFields, list_AccFields, list_LeadFields, objOppToReturn);
		} catch (Exception ex) {
			// In case of exception, set success flag and return exception message
			return new NBAMiniViewWrapperResponse(false, ex.getMessage(), list_OppFields, list_AccFields, list_LeadFields, null);
		}
	}
}