/*
    By: Deepak Tyagi
    Dec 5, 2018 
    Desc: Renewal Survey Requirements: Parse Survey for HI Renewal.
*/

public class HIRenewalSurveyJSON {
	public String comment;
	public String address_on_file;
	public Map<String, Boolean> interested_benefit_types;
	public Map<String, String> carrier_providers_coverage;

	public static HIRenewalSurveyJSON parse(String strJsonString) {
		return (HIRenewalSurveyJSON) System.JSON.deserialize(strJsonString, HIRenewalSurveyJSON.class);
	}
}