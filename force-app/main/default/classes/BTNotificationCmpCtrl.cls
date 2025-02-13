/**
 * @name         BTNotificationCmpCtrl
 * @author       Neha Dabas
 * @date         25/02/2019
 * @description  Controller for component used to include dynamic data in visualforce email templates for Benefits Transfer Notifications
 * @revisions    Date ------------ Name ------------ Comments
 **/
global with sharing class BTNotificationCmpCtrl {
	public String strDisplayFormat { get; set; } //To identify how to display the results
	public String strInfoNeeded { get; set; } // Indicates what information need to be retrieved
	public String strRecordIdToCompare { get; set; } // Record Id to compare while querying data
	public String strFieldNameToCompare { get; set; } // Field name that we need to check while querying data
	public String strObjectToBeQueried { get; set; } // Object name from which records need to be fetched

	/*
	 * To get the date which is  business days later than today
	 */
	public Date getTodayPlusFiveBusinessDays() {
		Date dtFiveBDays;
		try {
			long fiveDaysInMilliSecond = 5 * 8 * 60 * 60 * 1000;
			List<BusinessHours> listBusinessHours = [SELECT Id, TimeZoneSidKey, IsDefault FROM BusinessHours WHERE name = 'Gusto - Denver'];
			Datetime fiveWorkingDaysDatetime = BusinessHours.add(listBusinessHours[0].Id, system.now(), fiveDaysInMilliSecond);
			dtFiveBDays = fiveWorkingDaysDatetime.Date();
		} catch (Exception e) {
			ExceptionLogUtil.logException('BTNotificationCmpCtrl', 'getTodayPlusFiveBusinessDays', e.getMessage(), e.getStackTraceString());
		}
		return dtFiveBDays;
	}

	/*
	 * constructor
	 */
	public BTNotificationCmpCtrl() {
	}

	//Get the information that need to be fetched
	public Map<String, Object> mapResults {
		get {
			Map<String, Object> map_Results = new Map<String, Object>();
			try {
				String strQuery = contructQueryString();
				if (String.isBlank(strQuery)) {
					return map_Results;
				}
				List<sObject> lst_Results = Database.query(strQuery);
				if (lst_Results == null || lst_Results.size() == 0) {
					return map_Results;
				}

				//process records retrived to form appropriate data structure
				for (SObject objRes : lst_Results) {
					if (strInfoNeeded.equalsIgnoreCase('Benefits type with carrier')) {
						Carrier_Order__c objCO = (Carrier_Order__c) objRes;
						if (!objCO.TAdA__c) {
							//Iterate over Carrier order records to get the Benefit types and associated Carrier
							if (objCO.Carrier_Order_Line_Item__r != null && objCO.Carrier_Order_Line_Item__r.size() > 0) {
								for (Carrier_Order_Line_Item__c objCOLI : objCO.Carrier_Order_Line_Item__r) {
									List<String> lst_BenefitsTypes;
									if (!map_Results.containsKey(objCO.Name)) {
										lst_BenefitsTypes = new List<String>();
									} else {
										lst_BenefitsTypes = (List<String>) map_Results.get(objCO.Name);
									}
									if (objCOLI.Benefit_Types__c != null) {
										lst_BenefitsTypes.add(objCOLI.Benefit_Types__c + ' with ' + objCO.Carrier_Information_Name__c);
										map_Results.put(objCO.Name, lst_BenefitsTypes);
									}
								}
							}
						}
					}
					//Iterate over Carrier order Line Item records to get the Benefit types and associated Renewal Month
					else if (strInfoNeeded.equalsIgnoreCase('Benefits type with renewal month')) {
						//to map month number to name format
						Map<Integer, String> map_MonthNoToName = new Map<Integer, String>{
							1 => 'JAN',
							2 => 'FEB',
							3 => 'MAR',
							4 => 'APR',
							5 => 'MAY',
							6 => 'JUN',
							7 => 'JUL',
							8 => 'AUG',
							9 => 'SEP',
							10 => 'OCT',
							11 => 'NOV',
							12 => 'DEC'
						};
						Carrier_Order__c objCO = (Carrier_Order__c) objRes;
						if (!objCO.TAdA__c) {
							//Iterate over Carrier order records to get the Benefit types and associated Carrier
							if (objCO.Carrier_Order_Line_Item__r != null && objCO.Carrier_Order_Line_Item__r.size() > 0) {
								for (Carrier_Order_Line_Item__c objCOLI : objCO.Carrier_Order_Line_Item__r) {
									List<String> lst_BenefitsTypes;
									if (!map_Results.containsKey(objCO.Name)) {
										lst_BenefitsTypes = new List<String>();
									} else {
										lst_BenefitsTypes = (List<String>) map_Results.get(objCO.Name);
									}
                                    
									lst_BenefitsTypes.add(objCOLI.Benefit_Types__c + ' [Month]');
									map_Results.put(objCO.Name, lst_BenefitsTypes);
								}
							}
						}
					}
				}
			} catch (Exception e) {
				ExceptionLogUtil.logException('BTNotificationCmpCtrl', 'getResults', e.getMessage(), e.getStackTraceString());
			}
			return map_Results;
		}
		private set;
	}
	/*
	 * Description : Form query string based on
	 *                  1) the object from which information need to be retrieved (strRelatedRecName)
	 *                  2) What information need to be retrieved (strInfoNeeded)
	 */
	private String contructQueryString() {
		//If Object type or related record id is not specified, then return
		if (strObjectToBeQueried == null || String.isBlank(strObjectToBeQueried) || String.isBlank(strRecordIdToCompare)) {
			return null;
		}

		String strQuery = 'SELECT Id,Name,Carrier__c, TAdA__c';
		if (strObjectToBeQueried.equalsIgnoreCase('Carrier_Order__c')) {
			//Fetch Carrier Order Info
			if (strInfoNeeded.equalsIgnoreCase('Benefits type with carrier')) {
				strQuery += ',Carrier_Information_Name__c,(SELECT Id,Name,Benefit_Types__c FROM Carrier_Order_Line_Item__r)';
			} else if (strInfoNeeded.equalsIgnoreCase('Benefits type with renewal month')) {
				strQuery += ', (SELECT Name,Benefit_Types__c,Renewal_Date__c FROM Carrier_Order_Line_Item__r)';
			}
		}

		strQuery += ' FROM ' + strObjectToBeQueried;

		String strCondition = '';
		if (strInfoNeeded.equalsIgnoreCase('Benefits type with carrier') || strInfoNeeded.equalsIgnoreCase('Benefits type with renewal month')) {
			strCondition = ' WHERE RecordType.Name = \'Benefits BoR\'';
		}
		if (String.isnotBlank(strFieldNameToCompare) && String.isNotBlank(strRecordIdToCompare)) {
			if (String.isBlank(strCondition)) {
				strCondition += ' WHERE ';
			} else {
				strCondition += ' AND ';
			}
			strCondition += strFieldNameToCompare + ' = :strRecordIdToCompare';
		}
		strQuery += strCondition;
		return strQuery;
	}
}