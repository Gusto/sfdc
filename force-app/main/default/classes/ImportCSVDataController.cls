/**
 * @name         : ImportCSVDataController
 * @author       : Nigam Goyal
 * @date         : 12-08-2022
 * @description  : All data import from csv related operation
 * @test classes : ImportCSVDataControllerTest
 **/
/** Overall process for future reference
    1. Login to DataLoader
    2. Export GF_Lead__c Records FROM UAT and upload in static resource
    3. Extract collection of emails from GF_Lead__c sheet 
       for example: 'johnathon.cole@schmelerchamplin.ca','malissa@bins.name','santiago@mitchellritchie.name','madelaine@ullrichherzog.co.uk','lakeesha_jacobson@paucek.us','ka.rowe@baileyprosacco.info','beaulah@quigley.com','otis_kertzmann@lakin.info','roland@lind.co.uk','roosevelt@treutel.biz','eneida_crist@marvingoyette.com','ngan@mueller.name','maple_zulauf@rohan.ca','chester@mayerdamore.biz','janice@jakubowskicremin.com','janice@jakubowskicremin.com','natashia@feest.co.uk','tama.schmitt@deckowconsidine.name','lakendra.quigley@bernhardbergnaum.com','cristin_wilkinson@mcclure.com','luciana@collins.us','kelvin@blick.us','may@lueilwitzreinger.co.uk','giuseppina@ferrycarroll.com' 
    4. Export ZP_Company__c Records based on GF_Lead__c Emails
       Here is query to export in ZP_Company__c in Data loader: SELECT Select ID__c, Number_of_Active_Contractors__c, Number_of_Active_Employees__c, Mailing_Street__c, Mailing_City__c, Mailing_Postal_Code__c, Filing_Street__c, Filing_State_Code__c, Filing_Postal_Code__c, Filing_Country_Code__c, Created_At__c, Updated_At__c, Name__c, On_Boarding__c, Created_By_Email__c, Partner_Program_Company_Data_Id__c, Original_Accounting_Firm_Id__c, Managing_Accounting_Firm_Id__c FROM ZP_Company__c WHERE Created_By_Email__c IN ('johnathon.cole@schmelerchamplin.ca','malissa@bins.name','santiago@mitchellritchie.name','madelaine@ullrichherzog.co.uk','lakeesha_jacobson@paucek.us','ka.rowe@baileyprosacco.info','beaulah@quigley.com','otis_kertzmann@lakin.info','roland@lind.co.uk','roosevelt@treutel.biz','eneida_crist@marvingoyette.com','ngan@mueller.name','maple_zulauf@rohan.ca','chester@mayerdamore.biz','janice@jakubowskicremin.com','janice@jakubowskicremin.com','natashia@feest.co.uk','tama.schmitt@deckowconsidine.name','lakendra.quigley@bernhardbergnaum.com','cristin_wilkinson@mcclure.com','luciana@collins.us','kelvin@blick.us','may@lueilwitzreinger.co.uk','giuseppina@ferrycarroll.com')
    5. Extract Id__c's from exported sheet '7757616924005730','7757616924005740','7757616924005750','7757616924005730','7757616924005760','7757616924005740','7757616924005700','7757616924005730','7757616924005750','7757616924005730','7757616924005740','7757616924005750','7757616924005730','7757616924005720','7757616924005740','7757616924005750','7757616924005740','7757616924005740','7757616924005730','7757616924005730','7757616924005730','7757616924005720','7757616924005740'
    6. Export ZP_User__c by Select Name, Created_At__c, Updated_At__c, Id__c, Email__c FROM ZP_User__c
    7. Export ZP_User_Role__c by Select Name, Id__c, First_Name__c, Last_Name__c, Type__c, Phone__c, Created_At__c, Updated_At__c, User_Id__c, Company_Id__c, Accounting_Firm_Id__c FROM ZP_User_Role__c WHERE Company_Id__c IN ('7757616924005730','7757616924005740','7757616924005750','7757616924005730','7757616924005760','7757616924005740','7757616924005700','7757616924005730','7757616924005750','7757616924005730','7757616924005740','7757616924005750','7757616924005730','7757616924005720','7757616924005740','7757616924005750','7757616924005740','7757616924005740','7757616924005730','7757616924005730','7757616924005730','7757616924005720','7757616924005740')
    8. To reset all objects -> make sure [Trigger Bypass] in (custom setting) AccountTrigger(field) should be true; 
    Caution!! Please check the env before running below delete logic
        delete [SELECT Id FROM Entitlement];
        delete [SELECT Id FROM Lead];
        delete [SELECT Id FROM GF_Lead__c];
        delete [SELECT Id FROM ZP_Company__c];
        delete [SELECT Id FROM ZP_User__c];
        delete [SELECT Id FROM ZP_User_Role__c];
        delete [SELECT Id FROM OpportunityContactRole];
        delete [SELECT Id FROM Opportunity];
        delete [SELECT Id FROM Contact];
        delete [SELECT Id FROM Account];
		delete [SELECT Id FROM ZP_Accounting_Firm__c];
		delete [SELECT Id FROM Exception_Log__c];
		

    */
public with sharing class ImportCSVDataController {
	private static String GF_LEAD_OBJECT_APINAME = 'GF_Lead__c';
	private static String ZP_ACCOUNTING_FIRM_APINAME = 'ZP_Accounting_Firm__c';
	private static String ZP_COMPANY_OBJECT_APINAME = 'ZP_Company__c';
	private static String ZP_User_OBJECT_APINAME = 'ZP_User__c';
	private static String ZP_USER_ROLE_OBJECT_APINAME = 'ZP_User_Role__c';

	private static String GF_LEAD_STATICRESOURCE = 'GF_Lead2';
	private static String ZP_ACCOUNTING_STATICRESOURCE = 'ZP_Accounting';
	private static String ZP_COMPANY_STATICRESOURCE = 'ZP_Company';
	private static String ZP_User_STATICRESOURCE = 'ZP_User';
	private static String ZP_USER_ROLE_STATICRESOURCE = 'ZP_User_Role';

	/**
	 * @name         : ImportGFLeadData
	 * @author       : Nigam Goyal
	 * @date         : 12-08-2022
	 * @description  : Import GF_Lead__c records from GF_Lead2 csv file in static resource
	 * @test classes : ImportCSVDataControllerTest
	 **/
	public class ImportGFLeadData implements Queueable {
		public void execute(QueueableContext context) {
			// Setting this custom setting to skip the async flow related to lead object
			// for e.g. Send Lead To Ring Lead flow, we have added the entry criteria to skip the whole flow logic.
			// We were facing issue of Unable to convert Lead due to dependance on workflow rule
			ProcessBypass__c objProcessByPassCustomSetting = ProcessBypass__c.getOrgDefaults();
			objProcessByPassCustomSetting.User_Automation_Bypass__c = true;
			upsert objProcessByPassCustomSetting;

			GFLeadTriggerHelper.queue = true;
			ImportCSVDataController objImportCSVDataController = new ImportCSVDataController();
			List<sObject> listLeadList = objImportCSVDataController.csvToObjectListGeneration(GF_LEAD_OBJECT_APINAME, GF_LEAD_STATICRESOURCE);
			objImportCSVDataController.saveSobjectList(listLeadList);

			if (!Test.isRunningTest()) {
				System.enqueueJob(new ImportZPAccountingFirm());
			}
		}
	}

	/**
	 * @name         : ImportZPAccountingFirm
	 * @author       : Todd Dowdy
	 * @date         : 12-20-2022
	 * @description  : Import ZP_Accounting_Firm__c records from ZP_Accounting_Firm csv file in static resource
	 * @test classes : ImportCSVDataControllerTest
	 **/
	public class ImportZPAccountingFirm implements Queueable {
		public void execute(QueueableContext context) {
			ZPAccountingFirmTriggerHelper.queue = true;
			ImportCSVDataController objImportCSVDataController = new ImportCSVDataController();
			List<sObject> listZPAccountantList = objImportCSVDataController.csvToObjectListGeneration(ZP_ACCOUNTING_FIRM_APINAME, ZP_ACCOUNTING_STATICRESOURCE);
			objImportCSVDataController.saveSobjectList(listZPAccountantList);
			if (!Test.isRunningTest()) {
				System.enqueueJob(new ImportZPCompanyData());
			}
		}
	}

	/**
	 * @name         : ImportZPCompanyData
	 * @author       : Nigam Goyal
	 * @date         : 12-08-2022
	 * @description  : Import ZP_Company__c records from ZP_Company csv file in static resource
	 * @test classes : ImportCSVDataControllerTest
	 **/
	public class ImportZPCompanyData implements Queueable {
		public void execute(QueueableContext context) {
			ZPCompanyTriggerHelper.queue = true;
			ImportCSVDataController objImportCSVDataController = new ImportCSVDataController();
			List<sObject> listZPList = objImportCSVDataController.csvToObjectListGeneration(ZP_COMPANY_OBJECT_APINAME, ZP_COMPANY_STATICRESOURCE);
			objImportCSVDataController.saveSobjectList(listZPList);
			if (!Test.isRunningTest()) {
				System.enqueueJob(new ImportZPUserData());
			}
		}
	}

	/**
	 * @name         : ImportZPUserData
	 * @author       : Nigam Goyal
	 * @date         : 12-08-2022
	 * @description  : Import ZP_User__c  records from ZP_User csv file in static resource
	 * @test classes : ImportCSVDataControllerTest
	 **/
	public class ImportZPUserData implements Queueable {
		public void execute(QueueableContext context) {
			ImportCSVDataController objImportCSVDataController = new ImportCSVDataController();
			List<sObject> listZPList = objImportCSVDataController.csvToObjectListGeneration(ZP_User_OBJECT_APINAME, ZP_User_STATICRESOURCE);
			objImportCSVDataController.saveSobjectList(listZPList);
			if (!Test.isRunningTest()) {
				System.enqueueJob(new ImportZPUserRoleData());
			}
		}
	}

	/**
	 * @name         : ImportZPUserData
	 * @author       : Nigam Goyal
	 * @date         : 12-08-2022
	 * @description  : Import ZP_User_Role__c records from ZP_User_Role csv file in static resource
	 * @test classes : ImportCSVDataControllerTest
	 **/
	public class ImportZPUserRoleData implements Queueable {
		public void execute(QueueableContext context) {
			ImportCSVDataController objImportCSVDataController = new ImportCSVDataController();
			List<sObject> listZPList = objImportCSVDataController.csvToObjectListGeneration(ZP_USER_ROLE_OBJECT_APINAME, ZP_USER_ROLE_STATICRESOURCE);
			objImportCSVDataController.saveSobjectList(listZPList);
			//
			ProcessBypass__c objProcessByPassCustomSetting = ProcessBypass__c.getOrgDefaults();
			objProcessByPassCustomSetting.User_Automation_Bypass__c = false;
			upsert objProcessByPassCustomSetting;
		}
	}

	/**
	 * @Author      : Nigam Goyal
	 * @Description : Read csv file from static resource, build sobjectList and create the records
	 * @Parm        : String strObjName, String strSheetName
	 * @Return      : List<sObject>
	 **/
	public List<sObject> csvToObjectListGeneration(String strObjName, String strSheetName) {
		List<sObject> listSobject = new List<sObject>();
		try {
			List<StaticResource> listStaticResources = getStaticResource(strSheetName);
			if (listStaticResources.size() > 0) {
				String strStaticResourceBody = listStaticResources[0].Body.toString();
				if (String.IsBlank(strStaticResourceBody)) {
					return new List<sObject>();
				}

				Map<String, Schema.SObjectField> mapsObjField = Utils.getSObjectDescribe(strObjName).fields.getMap();
				List<String> listHeader = new List<String>();
				Integer intCounter = 0;

				for (String strRow : strStaticResourceBody.split('\n')) {
					if (intCounter == 0) {
						listHeader = strRow.split(',');
						intCounter++;
						continue;
					}
					Integer intStartIndex;
					Integer intEndIndex;
					while (strRow.indexOf('"') > -1) {
						if (intStartIndex == null) {
							intStartIndex = strRow.indexOf('"');
							strRow = strRow.substring(0, intStartIndex) + ':quotes:' + strRow.substring(intStartIndex + 1, strRow.length());
						} else {
							if (intEndIndex == null) {
								intEndIndex = strRow.indexOf('"');
								strRow = strRow.substring(0, intEndIndex) + ':quotes:' + strRow.substring(intEndIndex + 1, strRow.length());
							}
						}

						if (intStartIndex != null && intEndIndex != null) {
							String sub = strRow.substring(intStartIndex, intEndIndex);
							sub = sub.replaceAll(',', ':comma:');
							strRow = strRow.substring(0, intStartIndex) + sub + strRow.substring(intEndIndex, strRow.length());
							intStartIndex = null;
							intEndIndex = null;
						}
					}
					String[] listColumns;
					if (strRow.contains('","')) {
						listColumns = strRow.split('","');
					} else {
						listColumns = strRow.split(',');
					}

					sObject objsObject = Utils.getSObjectDescribe(strObjName).getSObjectType().newSObject();

					Integer intSizeOfColumn = listColumns.size();
					Integer intSizeOfHeader = listHeader.size();
					Map<Schema.SObjectField, SoapType> mapFieldToSoapType = new Map<Schema.SObjectField, SoapType>();
					for (Integer ii = 0; ii < intSizeOfHeader; ii++) {
						if (!String.isBlank(listHeader[ii])) {
							String strColumn = listHeader[ii].trim();
							strColumn = strColumn.replace('"', '');
							if (mapsObjField.containsKey(strColumn)) {
								Schema.SObjectField objField = mapsObjField.get(strColumn);
								SoapType objSoapType;
								if (mapFieldToSoapType.containsKey(objField)) {
									objSoapType = mapFieldToSoapType.get(objField);
								} else {
									objSoapType = objField.getDescribe().getSoapType();
									if (!objField.getDescribe().isUpdateable()) {
										continue;
									}
									mapFieldToSoapType.put(objField, objSoapType);
								}

								String strValue;
								if (intSizeOfColumn > ii) {
									strValue = listColumns[ii];
								}

								if (!String.isBlank(strValue)) {
									strValue = strValue.replaceAll(':quotes:', '').replaceAll(':comma:', ',');
									strValue = strValue.replace('"', '');
								}
								ImportCSVDataPutReference objImportCSVDataPutReference = new ImportCSVDataPutReference(objField, objSoapType);
								objsObject = objImportCSVDataPutReference.putTo(objsObject, strValue);
							}
						}
					}
					listSobject.add(objsObject);
				}
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('SandboxPostRefresh', 'dataGenerationMapping', ex.getMessage() + '::' + ex.getLineNumber(), ex.getStackTraceString());
		}
		return listSobject;
	}

	/**
	 * @Author      : Nigam Goyal
	 * @Description : save records
	 * @Parm        : String strObjName, String strSheetName
	 * @Return      : List<sObject>
	 **/
	public Database.SaveResult[] saveSobjectList(List<sObject> list_Sobject) {
		Database.SaveResult[] listSaveResults = Database.insert(list_Sobject, false);
		string strMessage = '';
		for (Database.SaveResult objSaveResult : listSaveResults) {
			if (!objSaveResult.isSuccess()) {
				for (Database.Error objError : objSaveResult.getErrors()) {
					strMessage += objError.getMessage() + ';';
				}
			}
		}
		if (!String.isNotBlank(strMessage)) {
			ExceptionLogUtil.logException('SandboxPostRefresh', 'dataGenerationMapping', strMessage, '');
		}
		return listSaveResults;
	}

	/**
	 * @Author      : Nigam Goyal
	 * @Description : get the static resource based on name
	 * @Parm        : String strName
	 * @Return      : List<StaticResource>
	 **/
	public List<StaticResource> getStaticResource(String strName) {
		return [SELECT Body FROM StaticResource WHERE NAME = :strName];
	}
}