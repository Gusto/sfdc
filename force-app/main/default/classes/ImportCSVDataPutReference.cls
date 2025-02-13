public with sharing class ImportCSVDataPutReference {
	final SObjectField objField;
	final ImportCSVDataValueIConverter objConverter;
	public ImportCSVDataPutReference(SObjectField objField, SoapType objSoapType) {
		this.objField = objField;
		this.objConverter = (ImportCSVDataValueIConverter) converters.get(objSoapType).newInstance();
	}
	public SObject putTo(SObject objRecord, String strInputValue) {
		objRecord.put(objField, objConverter.getValue(strInputValue));
		return objRecord;
	}
	// Need to add
	// Date class
	// ID Class
	// Integer Class
	// Time Class
	public static final Map<SoapType, Type> converters = new Map<SoapType, Type>{
		SoapType.DOUBLE => DoubleConverter.class,
		SoapType.STRING => StringConverter.class,
		SoapType.DATETIME => DateTimeConverter.class,
		SoapType.BOOLEAN => BooleanConverter.class
	};

	public class DoubleConverter implements ImportCSVDataValueIConverter {
		public Object getValue(String strInputValue) {
			if (String.isNotBlank(strInputValue)) {
				return Double.valueOf(strInputValue);
			} else {
				return null;
			}
		}
	}
	public class StringConverter implements ImportCSVDataValueIConverter {
		public Object getValue(String strInputValue) {
			if (String.isNotBlank(strInputValue)) {
				return String.valueOf(strInputValue);
			} else {
				return null;
			}
		}
	}

	public class DateTimeConverter implements ImportCSVDataValueIConverter {
		public Object getValue(String strInputValue) {
			DateTime dtValue;
			if (String.isNotBlank(strInputValue)) {
				if (strInputValue.contains(',')) {
					strInputValue = strInputValue.replace(',', '');
					dtValue = DateTime.parse(strInputValue);
				} else if (strInputValue.contains('T')) {
					dtValue = DateTime.Valueof(strInputValue.replace('T', ' '));
				}
				return dtValue;
			} else {
				return null;
			}
		}
	}

	public class BooleanConverter implements ImportCSVDataValueIConverter {
		public Object getValue(String strInputValue) {
			if (String.isNotBlank(strInputValue)) {
				return Boolean.valueOf(strInputValue);
			} else {
				return null;
			}
		}
	}
}