global class HCProEmailService implements Messaging.InboundEmailHandler {
	global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
		String body = '';

		if (email.plainTextBody != null) {
			body = email.plainTextBody;
		} else if (email.htmlBody != null) {
			body = email.htmlBody;
		}

		processEmail(body);

		Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
		return result;
	}

	public void processEmail(String body) {
		List<State_Name_to_abbreviations_Mapping__c> stateNameMappingList = State_Name_to_abbreviations_Mapping__c.getall().values();
		Map<String, String> stateNameMap = new Map<String, String>();

		if (stateNameMappingList.size() > 0) {
			for (State_Name_to_abbreviations_Mapping__c st : stateNameMappingList) {
				if (!stateNameMap.containsKey(st.State_Name__c))
					stateNameMap.put(st.State_Name__c, st.State_Abbreviation__c);
			}
		}

		try {
			String[] rows = body.split('\n');
			map<String, String> fieldMap = new Map<String, String>();
			for (String fieldValue : rows) {
				if (string.isNotEmpty(fieldValue)) {
					string[] fieldValues = fieldValue.split(':');
					if (fieldValues.size() > 1) {
						fieldMap.put(fieldValues[0], fieldValues[1]);
					}
				}
			}
            
			if (fieldMap.containsKey('pro email')) {
				String leadEmail = fieldMap.get('pro email').trim();
				List<Lead> leadlist = new List<Lead>([SELECT id, email FROM Lead WHERE RecordType.name = 'company' AND email = :leadEmail]);
				if (leadlist.size() == 0) {
					Lead lead = new lead();
					if (fieldMap.containsKey('pro_name')) {
						String leadname = fieldMap.get('pro_name');
						leadname = leadname.trim();
						if (leadname.indexOf(' ') > -1) {
							lead.firstName = leadname.split(' ')[0];
							lead.LastName = leadname.split(' ')[1];
						} else {
							lead.firstName = leadname;
							lead.LastName = 'NA';
						}
					}
                    
					if (fieldMap.containsKey('organization name')) {
						lead.Company = fieldMap.get('organization name').trim();
					}
                    
					if (fieldMap.containsKey('pro email')) {
						String email = fieldMap.get('pro email');
						lead.Email = email.replaceall(' ', '').replaceAll(' ', '').trim();
					}
                    
					if (fieldMap.containsKey('pro mobile number')) {
						lead.Phone = fieldMap.get('pro mobile number').trim();
					}
                    
					if (fieldMap.containsKey('service address')) {
						String address = fieldMap.get('service address');
						String[] addressArr = address.split(', ');
						if (addressArr.size() >= 2) {
							String stateZip = addressArr[addressArr.size() - 1];
							if (stateZip.indexOf(' ') > -1) {
								lead.PostalCode = stateZip.split(' ')[1];
								if (stateNameMap.containskey(stateZip.split(' ')[0])) {
									lead.State = stateNameMap.get(stateZip.split(' ')[0]);
								}
							}
							lead.Country = 'United States';
							lead.City = addressArr[addressArr.size() - 2];
							lead.Street = addressArr[0];
						}
					}
                    
					lead.LeadSource = 'housecallpro';
					lead.RecordTypeId = cache.getRecordTypeId('Lead', 'Company');
                    
					insert lead;
				}
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('HCProEmailService', 'processEmail', ex);
		}
	}
}