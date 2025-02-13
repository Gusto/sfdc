/**
 * @name         TaxResSUIWrapper
 * @author       Elavarasan Nagarathinam
 * @date         07/20/2023
 * @description  SUI rate is pushed through OCR on TNDC record as JSON and that will create a Tax Rate Types records under TNDC record.
 **/
public class TaxResSUIWrapper {

	//declare variables which is passed from OCR
	public String TaxRate;
	public String TaxRateKey;

	/*
	Author: Elavarasan Nagarathinam
	Date: 07/20/2023
	Description: Method to parse the JSON into TaxResSUIWrapper
	Sample JSON: [{"tax_rate": 0.001,"tax_rate_key": "ca_ett_rate"},{"tax_rate": 0.06,"tax_rate_key": "ca_sui_rate"}]
	*/
	public static List<TaxResSUIWrapper> parse(String json) {
		return (List<TaxResSUIWrapper>) System.JSON.deserialize(json, List<TaxResSUIWrapper>.class);
	}
}