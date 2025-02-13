/*
    By: Deepak Tyagi
    Date: December 4, 2018
    Description: Renewal Survey Requirements: Create Survey for HI Renewal.
*/
public class HIRenewalSurvey {
	public void processInformation(List<HI_Renewal__c> list_hiRenewals) {
		Set<String> set_carrierIds = new Set<String>();
		Set<String> set_oppIds = new Set<String>();
		Set<String> set_renewalSurveys = new Set<String>();
		Map<String, HIRenewalSurveyJSON> map_renewalInfo = new Map<String, HIRenewalSurveyJSON>();
		Map<String, String> map_carrierIdName = new Map<String, String>();
		Map<String, Opportunity> map_oppty = new Map<String, Opportunity>();
		Map<String, Renewal_Survey__c> map_renewalSurvey = new Map<String, Renewal_Survey__c>();
		List<Renewal_Survey__c> list_renewalSurveys = new List<Renewal_Survey__c>();

		for (HI_Renewal__c objHiRenewal : list_hiRenewals) {
			set_renewalSurveys.add(objHiRenewal.Id__c);
		}

		if (set_renewalSurveys != null && set_renewalSurveys.size() > 0) {
			for (Renewal_Survey__c renewalSurveyObj : [SELECT Id, Id__c FROM Renewal_Survey__c WHERE Id__c != NULL AND Id__c IN :set_renewalSurveys]) {
				map_renewalSurvey.put(renewalSurveyObj.Id__c, renewalSurveyObj);
			}
		}

		for (HI_Renewal__c objHiRenewal : list_hiRenewals) {
			if (!map_renewalSurvey.containsKey(objHiRenewal.Id__c)) {
				set_oppIds.add('HIRENEWAL' + objHiRenewal.Id__c);
				HIRenewalSurveyJSON objHiRenewalInfoParsed;
				if (objHiRenewal.Survey_Answers__c != null) {
					String jsonString = objHiRenewal.Survey_Answers__c.replaceAll('=>', ':');
					try {
						objHiRenewalInfoParsed = HIRenewalSurveyJSON.parse(jsonString);
					} catch (Exception objException) {
						ExceptionLogUtil.logException('HIRenewalSurvey', 'processInformation', objException.getMessage(), objException.getStackTraceString());
					}
				}

				if (objHiRenewalInfoParsed != null) {
					map_renewalInfo.put(objHiRenewal.Id, objHiRenewalInfoParsed);
					if (objHiRenewalInfoParsed.carrier_providers_coverage != null) {
						set_carrierIds = objHiRenewalInfoParsed.carrier_providers_coverage.keySet();
					}
				}
			}
		}

		if (set_oppIds != null && set_oppIds.size() > 0) {
			for (Opportunity oppObj : [SELECT Id, Id__c, OwnerId FROM Opportunity WHERE Id__c != NULL AND Id__c IN :set_oppIds]) {
				map_oppty.put(oppObj.Id__c, oppObj);
			}
		}

		if (set_carrierIds != null && set_carrierIds.size() > 0) {
			for (Carrier__c carObj : [SELECT Id, Name, Carrier_Id__c FROM Carrier__c WHERE Carrier_Id__c != NULL AND Carrier_Id__c IN :set_carrierIds]) {
				map_carrierIdName.put(carObj.Carrier_Id__c, carObj.Name);
			}
		}

		for (HI_Renewal__c objHiRenewal : list_hiRenewals) {
			if (!map_renewalSurvey.containsKey(objHiRenewal.Id__c) && map_oppty.containsKey('HIRENEWAL' + objHiRenewal.Id__c)) {
				Set<String> set_carrierWithYes = new Set<String>();
				Set<String> set_carrierWithNo = new Set<String>();
				Set<String> set_benefitsWithYes = new Set<String>();
				Set<String> set_benefitsWithNo = new Set<String>();

				if (map_renewalInfo.containsKey(objHiRenewal.Id)) {
					HIRenewalSurveyJSON renewalObj = map_renewalInfo.get(objHiRenewal.Id);
					// BBO-938 - carrier_providers_coverage is dynamic such as carrier_providers_coverage_36
					if (renewalObj.carrier_providers_coverage != null) {
						for (String strCarrier : renewalObj.carrier_providers_coverage.keySet()) {
							String strCarrierId = renewalObj.carrier_providers_coverage.get(strCarrier);
							if (strCarrierId == 'Yes') {
								set_carrierWithYes.add(map_carrierIdName.get(strCarrier));
                            }

							if (strCarrierId == 'No') {
								set_carrierWithNo.add(map_carrierIdName.get(strCarrier));
							}
						}
					}

					if (renewalObj.interested_benefit_types != null) {
						for (String strBenefit : renewalObj.interested_benefit_types.keySet()) {
							if (renewalObj.interested_benefit_types.get(strBenefit)) {
								set_benefitsWithYes.add(strBenefit);
							} else {
								set_benefitsWithNo.add(strBenefit);
                            }
						}
					}

					Renewal_Survey__c objRenewalSurvey = new Renewal_Survey__c(
						Id__c = objHiRenewal.Id__c,
						Primary_Work_Location__c = renewalObj.address_on_file,
						OwnerId = map_oppty.get('HIRENEWAL' + objHiRenewal.Id__c).OwnerId,
						Opportunity__c = map_oppty.get('HIRENEWAL' + objHiRenewal.Id__c).Id,
						Carrier_Satisfaction_Yes__c = String.join(new List<String>(set_carrierWithYes), ', '),
						Carrier_Satisfaction_No__c = String.join(new List<String>(set_carrierWithNo), ', '),
						Interest_in_Adding_Benefits__c = String.join(new List<String>(set_benefitsWithYes), ', '),
						Interest_in_Adding_Benefits_No__c = String.join(new List<String>(set_benefitsWithNo), ', '),
						Preferences__c = renewalObj.comment
					);
					list_renewalSurveys.add(objRenewalSurvey);
				}
			}
		}

		if (list_renewalSurveys != null && list_renewalSurveys.size() > 0) {
			upsert list_renewalSurveys Id__c;
		}
	}
}