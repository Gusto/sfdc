/**
 * @description  Wrapper class used to hold request criteria for the NBA Serve Record component
 * @author       Praveen Sethu
 * @see          NBAServeRecordTest
 **/
public class NBARequestWrapper {
	@AuraEnabled
	public String baseObject;
	@AuraEnabled
	public String objectLabel;
	@AuraEnabled
	public List<FilterFieldsList> filterFieldsList;
	@AuraEnabled
	public String criteriaLogic;
	@AuraEnabled
	public List<DisplayFieldsList> displayFieldsList;
	@AuraEnabled
	public String talkingPoints;
	@AuraEnabled
	public String soqlQuery;
	@AuraEnabled
	public String servingField;
	@AuraEnabled
	public String servingObject;
	@AuraEnabled
	public List<OrderByField> list_OrderByFields;
	@AuraEnabled
	public Boolean assignRecordOwner;
	@AuraEnabled
	public List<String> userFieldsAssignment;
	@AuraEnabled
	public List<FieldMapping> fieldMapping;
	@AuraEnabled
	public String strPerformance;
	@AuraEnabled
	public Double dblTimeTakenSeconds;

	public class DisplayFieldsList {
		@AuraEnabled
		public String selectedField;
		@AuraEnabled
		public String selectedFieldAPI;
		@AuraEnabled
		public String customText;

		public DisplayFieldsList(String selectedField, String selectedFieldAPI, String customText) {
			this.selectedField = selectedField;
			this.selectedFieldAPI = selectedFieldAPI;
			this.customText = customText;
		}

		public DisplayFieldsList() {
		}
	}

	public class InnerTables {
		@AuraEnabled
		public String strRelationshipName;
		@AuraEnabled
		public String strObjectLabel;
		@AuraEnabled
		public String selectedField;
		@AuraEnabled
		public String strFieldLabel;
		@AuraEnabled
		public String strReferenceObject;
	}

	public class FilterFieldsList {
		@AuraEnabled
		public String filterType;
		@AuraEnabled
		public String selectedFieldLabel;
		@AuraEnabled
		public String selectedFieldApiName;
		@AuraEnabled
		public String soqlQuery;
		@AuraEnabled
		public String selectedField;
		@AuraEnabled
		public String selectedFieldType;
		@AuraEnabled
		public String selectedOperator;
		@AuraEnabled
		public List<InnerTables> innerTables;
		@AuraEnabled
		public String selectedValue;
	}

	public class OrderByField {
		@AuraEnabled
		public String selectedField;
		@AuraEnabled
		public String selectedOrder;
		@AuraEnabled
		public String selectedFieldLabel;
		@AuraEnabled
		public List<InnerTables> innerTables;
		@AuraEnabled
		public String selectedFieldType;
		@AuraEnabled
		public String selectedRelationField;
		@AuraEnabled
		public String orderNulls;
	}

	public class FieldMapping {
		@AuraEnabled
		public String fieldMappingType;
		@AuraEnabled
		public String fieldType;
		@AuraEnabled
		public String selectedField;
		@AuraEnabled
		public List<Mapping> mapping;
	}

	public class Mapping {
		@AuraEnabled
		public String fromValue;
		@AuraEnabled
		public String toValue;
		@AuraEnabled
		public Boolean fromQueueEnabled;
		@AuraEnabled
		public Boolean toQueueEnabled;
	}
}