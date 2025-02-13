/**
 * @description  Send Product Upsell records to External Partners
 * @author       Debasmita Rawooth
 * @date         29-04-2024
 * @see          SendProductUpsellToExternalPartnerTest
 **/
public with sharing class SendProductUpsellToExternalPartner {
	public static final String HUMAN_INTEREST = 'humanInterest';
	public static final String REMOTE = 'remote';
	public static final String GUIDELINE = 'guideline';
	public static final String NEXT_INSURANCE = 'nextInsurance';

	/**
	 * @description  Wrapper used to receieve input from Flow
	 * @author       Debasmita Rawooth
	 **/
	public class RequestWrapper {
		// Id of Product Upsell
		@InvocableVariable
		public Id idRecord;

		@InvocableVariable
		public Boolean isRetry = false;

		@InvocableVariable
		public String strAPIName;

		// Default Constructor
		public RequestWrapper() {
		}

		// Paramterized Constructor
		public RequestWrapper(Id idRecord, String strAPIName) {
			this.idRecord = idRecord;
			this.strAPIName = strAPIName;
		}
	}

	/**
	 * @description	Invocable method to be called from flow with Product Upsell Id
	 * @author		Debasmita Rawooth
	 * @param       list_ReqWrappers - List of Invocable wrapper object
	 * @return      NA
	 **/
	@InvocableMethod(callout=true label='Send Product Upsell To External Partner' description='Send record to Mulesoft for sending product upsell data to external partners.')
	public static void sendPUToExternalPartner(List<RequestWrapper> list_ReqWrappers) {
		List<Id> list_productUpsellIds = new List<Id>();
		Boolean isRetry = false;
		String strAPIName = '';
		try {
			// Iterate over all wrapper objects
			for (RequestWrapper objWrapper : list_ReqWrappers) {
				isRetry = objWrapper.isRetry;
				strAPIName = objWrapper.strAPIName;
				list_productUpsellIds.add(objWrapper.idRecord);
			}
			if (!isRetry) {
				sendCalloutFuture(list_productUpsellIds, strAPIName);
			} else {
				sendCalloutNow(list_productUpsellIds, strAPIName);
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('SendProductUpsellToExternalPartner', 'sendPUToExternalPartner', null, objException);
		}
	}

	/**
	 * @description	Make the Humaninterest API callout immediately on Retry Integration button click to show sync status
	 * @author		Deepak Jadhav
	 * @param       list_ProductUpsellId - List of Product Upsell Ids\
	 * @return      NA
	 **/
	private static void sendCalloutNow(List<Id> list_productUpsellIds, String strAPIName) {
		sendCallout(list_productUpsellIds, strAPIName);
	}

	/**
	 * @description	Future method to make the Humaninterest API callout
	 * @author		Deepak Jadhav
	 * @param       list_ProductUpsellId - List of Product Upsell Ids
	 * @return      NA
	 **/
	@Future(callout=true)
	private static void sendCalloutFuture(List<Id> list_productUpsellIds, String strAPIName) {
		sendCallout(list_productUpsellIds, strAPIName);
	}

	/**
	 * @description	Humaninterest API callout
	 * @author		Debasmita Rawooth
	 * @param       list_ProductUpsellId - List of Product Upsell Ids\
	 * @return      NA
	 **/
	public static void sendCallout(List<Id> list_ProductUpsellId, String strAPIName) {
		List<Partnership_Interest__c> list_ProductUpsell = new List<Partnership_Interest__c>();
		String payload = '';
		HTTPResponse objHTTPRes = new HTTPResponse();
		try {
			//Send callout to Mulesoft endpoint
			list_ProductUpsell = getProductUpsells(list_ProductUpsellId[0]);
			if (!list_ProductUpsell.isEmpty()) {
				if (strAPIName == HUMAN_INTEREST) {
					payload = getHIAPIPayload(list_ProductUpsell[0]);
				} else if (strAPIName == REMOTE) {
					payload = getRemoteAPIPayload(list_ProductUpsell[0]);
				} else if (strAPIName == GUIDELINE) {
					payload = getGuidelineAPIPayload(list_ProductUpsell[0]);
				} else if (strAPIName == NEXT_INSURANCE) {
					payload = getNextAPIPayload(list_ProductUpsell[0]);
				}
				objHTTPRes = sendHttpRequest(payload);

				if (objHTTPRes.getStatusCode() == 200) {
					updateProductUpsellFlag(list_ProductUpsell[0]);
				} else {
					ExceptionLogUtil.logException('SendProductUpsellToExternalPartner', 'sendPUToExternalPartner', null, objHTTPRes.getStatusCode() + objHTTPRes.getBody());
					updateProductUpsellErrorMsg(list_ProductUpsell[0], objHTTPRes.getStatusCode() + objHTTPRes.getBody());
				}
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('SendProductUpsellToExternalPartner', 'sendCallout', null, objException);
			try {
				updateProductUpsellErrorMsg(list_ProductUpsell[0], objException.getMessage());
			} catch (Exception exp) {
				ExceptionLogUtil.logException('SendProductUpsellToExternalPartner', 'sendCallout', null, exp);
			}
		}
	}

	/**
	 * @description	Method get Product Upsell records for
	 * @author		Deepak Jadhav
	 * @param       productUpsellId
	 * @return      List of Product Upsell
	 **/
	private static List<Partnership_Interest__c> getProductUpsells(Id productUpsellId) {
		return [
			SELECT
				Id,
				Name,
				PUID__c,
				OwnerId,
				Owner.FirstName,
				Owner.LastName,
				Owner.Email,
				Owner.UserRole.Name,
				Contact__c,
				Contact__r.FirstName,
				Contact__r.LastName,
				Contact__r.Email,
				Contact__r.Phone,
				Contact__r.MobilePhone,
				Account__c,
				Account__r.Name,
				Account__r.Website,
				Account__r.BillingStreet,
				Account__r.BillingCity,
				Account__r.BillingState,
				Account__r.BillingPostalCode,
				Account__r.BillingCountry,
				Account__r.Joined_Date_Panda__c,
				Account__r.Has_Benefits_401k__c,
				Account__r.ZP_Company_ID__c,
				Account__r.NAICS_Code__c,
				Account__r.ParentId,
				Account__r.Parent.Name,
				Secondary_Contact_from_Account__c,
				Secondary_Contact_from_Account__r.FirstName,
				Secondary_Contact_from_Account__r.LastName,
				Secondary_Contact_from_Account__r.Email,
				Secondary_Contact_from_Account__r.Phone,
				Secondary_Contact_from_Account__r.MobilePhone,
				Opportunity__c,
				Workers_Comp_Notes__c,
				X401k_Notes__c,
				toLabel(Tier_Upgrade__c),
				Is_Reseller__c,
				Work_Location__c,
				Employees__c,
				Product_Interest_Countries__c,
				toLabel(Product_Upsell_Source__c)
			FROM Partnership_Interest__c
			WHERE Id = :productUpsellId
		];
	}

	/**
	 * @description	Method to callout HumanInterest API
	 * @author		Deepak Jadhav
	 * @param       payload
	 * @return      HTTPResponse
	 **/
	private static HTTPResponse sendHttpRequest(String payload) {
		HttpRequest objHTTPReq = new HttpRequest();
		objHTTPReq.setEndpoint('callout:Partner_Mulesoft_API');
		objHTTPReq.setMethod('POST');
		objHTTPReq.setBody(payload);
		objHTTPReq.setHeader('client_id', '{!$Credential.Username}');
		objHTTPReq.setHeader('client_secret', '{!$Credential.Password}');
		objHTTPReq.setHeader('Content-Type', 'application/json');
		Http objHTTP = new Http();
		return objHTTP.send(objHTTPReq);
	}

	/**
	 * @description	Method to update product upsell record is case of successful API response
	 * @author		Debasmita Rawooth
	 * @param       objProdUpsell - Product Upsell record
	 * @return      NA
	 **/
	public static void updateProductUpsellFlag(Partnership_Interest__c objProdUpsell) {
		objProdUpsell.Product_Upsell_Synced__c = true;
		objProdUpsell.Error_Message__c = '';
		update objProdUpsell;
	}

	/**
	 * @description	Method to update error msg on product upsell if sync failed or exception occurs
	 * @author		Deepak Jadhav
	 * @param       objProdUpsell - Product Upsell record
	 * @return      NA
	 **/
	private static void updateProductUpsellErrorMsg(Partnership_Interest__c objProdUpsell, String msg) {
		objProdUpsell.Error_Message__c = msg;
		update objProdUpsell;
	}

	/**
	 * @description	Method to generate JSON string for Human Interest
	 * @author		Debasmita Rawooth
	 * @param       objProdUpsell - Product Upsell record
	 * @return      String
	 **/
	public static String getHIAPIPayload(Partnership_Interest__c objProdUpsell) {
		if (objProdUpsell == null) {
			return null;
		} else {
			JSONGenerator objJsonGen = JSON.createGenerator(true);
			objJsonGen.writeStartObject();
			objJsonGen.writeStringField('target_system', HUMAN_INTEREST);
			objJsonGen.writeStringField('puid', objProdUpsell.PUID__c);
			objJsonGen.writeStringField('partner_rep_id', objProdUpsell.OwnerId);

			if (objProdUpsell.OwnerId != null) {
				if (objProdUpsell.Owner.FirstName != null) {
					objJsonGen.writeStringField('partner_rep_first_name', objProdUpsell.Owner.FirstName);
				}
				if (objProdUpsell.Owner.LastName != null) {
					objJsonGen.writeStringField('partner_rep_last_name', objProdUpsell.Owner.LastName);
				}
				if (objProdUpsell.Owner.Email != null) {
					objJsonGen.writeStringField('partner_rep_email', objProdUpsell.Owner.Email);
				}
			}

			if (objProdUpsell.Contact__c != null) {
				if (objProdUpsell.Contact__r.FirstName != null) {
					objJsonGen.writeStringField('referral_first_name', objProdUpsell.Contact__r.FirstName);
				}

				if (objProdUpsell.Contact__r.LastName != null) {
					objJsonGen.writeStringField('referral_last_name', objProdUpsell.Contact__r.LastName);
				}

				if (objProdUpsell.Contact__r.Email != null) {
					objJsonGen.writeStringField('referral_email', objProdUpsell.Contact__r.Email);
				}

				if (objProdUpsell.Contact__r.Phone != null) {
					objJsonGen.writeStringField('referral_phone_number', objProdUpsell.Contact__r.Phone);
				} else if (objProdUpsell.Contact__r.MobilePhone != null) {
					objJsonGen.writeStringField('referral_phone_number', objProdUpsell.Contact__r.MobilePhone);
				}
			}

			if (objProdUpsell.Account__c != null) {
				objJsonGen.writeStringField('referral_id', objProdUpsell.Account__c);

				if (objProdUpsell.Account__r.Name != null) {
					objJsonGen.writeStringField('referral_company_name', objProdUpsell.Account__r.Name);
				}

				if (objProdUpsell.Account__r.Website != null) {
					objJsonGen.writeStringField('referral_company_website', objProdUpsell.Account__r.Website);
				}
				if (objProdUpsell.Account__r.BillingState != null) {
					objJsonGen.writeStringField('referral_state', objProdUpsell.Account__r.BillingState);
				}
				if (objProdUpsell.Account__r.BillingPostalCode != null) {
					objJsonGen.writeStringField('referral_zip_code', objProdUpsell.Account__r.BillingPostalCode);
				}
				if (objProdUpsell.Account__r.Joined_Date_Panda__c != null) {
					objJsonGen.writeDateTimeField('first_payroll_date', objProdUpsell.Account__r.Joined_Date_Panda__c);
				}
			}

			if (objProdUpsell.Employees__c != null) {
				objJsonGen.writeNumberField('referral_number_of_employees', objProdUpsell.Employees__c);
			}

			if (objProdUpsell.Work_Location__c != null) {
				objJsonGen.writeStringField('referral_address', objProdUpsell.Work_Location__c);
			}

			if (objProdUpsell.X401k_Notes__c != null) {
				objJsonGen.writeStringField('referral_rep_notes', objProdUpsell.X401k_Notes__c);
			}

			if (objProdUpsell.Tier_Upgrade__c != null) {
				objJsonGen.writeStringField('tier', objProdUpsell.Tier_Upgrade__c);
			}

			if (objProdUpsell.Is_Reseller__c) {
				objJsonGen.writeStringField('is_accountant', 'yes');
			} else {
				objJsonGen.writeStringField('is_accountant', 'no');
			}

			if (objProdUpsell.Account__r.Has_Benefits_401k__c) {
				objJsonGen.writeBooleanField('referral_existing_401k_bool', true);
			} else {
				objJsonGen.writeBooleanField('referral_existing_401k_bool', false);
			}

			objJsonGen.writeEndObject();

			String strJSON = objJsonGen.getAsString();

			return strJSON;
		}
	}

	/**
	 * @description	Method to generate JSON string for Remote
	 * @author		Debasmita Rawooth
	 * @param       objProdUpsell - Product Upsell record
	 * @return      String
	 **/
	public static String getRemoteAPIPayload(Partnership_Interest__c objProdUpsell) {
		if (objProdUpsell == null) {
			return null;
		} else {
			JSONGenerator objJsonGen = JSON.createGenerator(true);
			objJsonGen.writeStartObject();
			objJsonGen.writeStringField('target_system', REMOTE);
			objJsonGen.writeStringField('puid', objProdUpsell.PUID__c);

			if (objProdUpsell.Contact__c != null) {
				if (objProdUpsell.Contact__r.FirstName != null) {
					objJsonGen.writeStringField('referral_first_name', objProdUpsell.Contact__r.FirstName);
				}

				if (objProdUpsell.Contact__r.LastName != null) {
					objJsonGen.writeStringField('referral_last_name', objProdUpsell.Contact__r.LastName);
				}

				if (objProdUpsell.Contact__r.Email != null) {
					objJsonGen.writeStringField('referral_email', objProdUpsell.Contact__r.Email);
				}

				if (objProdUpsell.Contact__r.Phone != null) {
					objJsonGen.writeStringField('referral_phone_number', objProdUpsell.Contact__r.Phone);
				} else if (objProdUpsell.Contact__r.MobilePhone != null) {
					objJsonGen.writeStringField('referral_phone_number', objProdUpsell.Contact__r.MobilePhone);
				}
			}

			if (objProdUpsell.Account__c != null) {
				objJsonGen.writeStringField('account_id', objProdUpsell.Account__c);

				if (objProdUpsell.Account__r.Name != null) {
					objJsonGen.writeStringField('referral_company_name', objProdUpsell.Account__r.Name);
				}

				if (objProdUpsell.Account__r.Website != null) {
					objJsonGen.writeStringField('referral_company_website', objProdUpsell.Account__r.Website);
				}
				if (objProdUpsell.Account__r.BillingState != null) {
					objJsonGen.writeStringField('referral_state', objProdUpsell.Account__r.BillingState);
				}
				if (objProdUpsell.Account__r.BillingPostalCode != null) {
					objJsonGen.writeStringField('referral_zip_code', objProdUpsell.Account__r.BillingPostalCode);
				}
				if (objProdUpsell.Account__r.BillingCountry != null) {
					objJsonGen.writeStringField('referral_country', objProdUpsell.Account__r.BillingCountry);
				}
			}

			if (objProdUpsell.Product_Upsell_Source__c != null) {
				objJsonGen.writeStringField('leadSource', objProdUpsell.Product_Upsell_Source__c);
			}

			if (objProdUpsell.Work_Location__c != null) {
				objJsonGen.writeStringField('referral_address', objProdUpsell.Work_Location__c);
			}
			if (objProdUpsell.Product_Interest_Countries__c != null) {
				List<String> strPicklistValues = objProdUpsell.Product_Interest_Countries__c.split(';');
				Map<String, String> mapPicklistValues = getPicklistValueMap();
				List<String> listPicklistLabels = new List<String>();
				for (String strValue : strPicklistValues) {
					listPicklistLabels.add(mapPicklistValues.get(strValue));
				}
				objJsonGen.writeStringField('international_countries', String.join(listPicklistLabels, ','));
			}

			objJsonGen.writeEndObject();

			String strJSON = objJsonGen.getAsString();

			return strJSON;
		}
	}

	/**
	 * @description	Method to get a map of picklist api name and label for Product_Interest_Countries__c
	 * @author		Debasmita Rawooth
	 * @return      mapPicklistValues
	 **/
	public static Map<String, String> getPicklistValueMap() {
		List<Schema.PicklistEntry> listPicklistValues = Partnership_Interest__c.Product_Interest_Countries__c.getDescribe().getPicklistValues();
		Map<String, String> mapPicklistValues = new Map<String, String>();
		for (Schema.PicklistEntry objEntry : listPicklistValues) {
			//Map to hold Picklist API as Key and Picklist Label as Value
			mapPicklistValues.put(objEntry.getValue(), objEntry.getLabel());
		}
		return mapPicklistValues;
	}

	/**
	 * @description	Method to generate JSON string for Guideline
	 * @author		Debasmita Rawooth
	 * @param       objProdUpsell - Product Upsell record
	 * @return      String
	 **/
	public static String getGuidelineAPIPayload(Partnership_Interest__c objProdUpsell) {
		if (objProdUpsell == null) {
			return null;
		} else {
			JSONGenerator objJsonGen = JSON.createGenerator(true);
			objJsonGen.writeStartObject();
			objJsonGen.writeStringField('target_system', GUIDELINE);
			objJsonGen.writeStringField('puid', objProdUpsell.PUID__c);

			if (objProdUpsell.OwnerId != null) {
				if (objProdUpsell.Owner.FirstName != null) {
					objJsonGen.writeStringField('partner_rep_first_name', objProdUpsell.Owner.FirstName);
				}
				if (objProdUpsell.Owner.LastName != null) {
					objJsonGen.writeStringField('partner_rep_last_name', objProdUpsell.Owner.LastName);
				}
				if (objProdUpsell.Owner.Email != null) {
					objJsonGen.writeStringField('partner_rep_email', objProdUpsell.Owner.Email);
				}
				if (objProdUpsell.Owner.UserRole.Name != null) {
					objJsonGen.writeStringField('owner_role', objProdUpsell.Owner.UserRole.Name);
				}
			}

			if (objProdUpsell.Contact__c != null) {
				if (objProdUpsell.Contact__r.FirstName != null) {
					objJsonGen.writeStringField('referral_first_name', objProdUpsell.Contact__r.FirstName);
				}

				if (objProdUpsell.Contact__r.LastName != null) {
					objJsonGen.writeStringField('referral_last_name', objProdUpsell.Contact__r.LastName);
				}

				if (objProdUpsell.Contact__r.Email != null) {
					objJsonGen.writeStringField('referral_email', objProdUpsell.Contact__r.Email);
				}

				if (objProdUpsell.Contact__r.Phone != null) {
					objJsonGen.writeStringField('referral_phone_number', objProdUpsell.Contact__r.Phone);
				} else if (objProdUpsell.Contact__r.MobilePhone != null) {
					objJsonGen.writeStringField('referral_phone_number', objProdUpsell.Contact__r.MobilePhone);
				}
			}

			if (objProdUpsell.Account__c != null) {
				objJsonGen.writeStringField('partner_rep_id', objProdUpsell.Account__c);

				if (objProdUpsell.Account__r.Name != null) {
					objJsonGen.writeStringField('referral_company_name', objProdUpsell.Account__r.Name);
				}

				if (objProdUpsell.Account__r.BillingStreet != null) {
					objJsonGen.writeStringField('referral_address', objProdUpsell.Account__r.BillingStreet);
				}
				if (objProdUpsell.Account__r.BillingCity != null) {
					objJsonGen.writeStringField('referral_city', objProdUpsell.Account__r.BillingCity);
				}
				if (objProdUpsell.Account__r.BillingState != null) {
					objJsonGen.writeStringField('referral_state', objProdUpsell.Account__r.BillingState);
				}
				if (objProdUpsell.Account__r.BillingPostalCode != null) {
					objJsonGen.writeStringField('referral_zip_code', objProdUpsell.Account__r.BillingPostalCode);
				}
				if (objProdUpsell.Account__r.Joined_Date_Panda__c != null) {
					objJsonGen.writeDateTimeField('first_payroll_date', objProdUpsell.Account__r.Joined_Date_Panda__c);
				}
				if (objProdUpsell.Account__r.NAICS_Code__c != null) {
					objJsonGen.writeStringField('referral_NAICS_code', objProdUpsell.Account__r.NAICS_Code__c);
				}
				if (objProdUpsell.Account__r.Parent.Name != null) {
					objJsonGen.writeStringField('referral_parent_company_name', objProdUpsell.Account__r.Parent.Name);
				}
			}

			if (objProdUpsell.Employees__c != null) {
				objJsonGen.writeNumberField('referral_number_of_employees', objProdUpsell.Employees__c);
			}

			if (objProdUpsell.X401k_Notes__c != null) {
				objJsonGen.writeStringField('referral_rep_notes', objProdUpsell.X401k_Notes__c);
			}

			if (objProdUpsell.Is_Reseller__c) {
				objJsonGen.writeStringField('is_accountant', 'yes');
			} else {
				objJsonGen.writeStringField('is_accountant', 'no');
			}

			if (objProdUpsell.Account__r.Has_Benefits_401k__c) {
				objJsonGen.writeBooleanField('referral_existing_401k_bool', true);
			} else {
				objJsonGen.writeBooleanField('referral_existing_401k_bool', false);
			}

			objJsonGen.writeEndObject();

			String strJSON = objJsonGen.getAsString();

			return strJSON;
		}
	}

	/**
	 * @description	Method to generate JSON string for NEXT Insurance
	 * @author		Debasmita Rawooth
	 * @param       objProdUpsell - Product Upsell record
	 * @return      String
	 **/
	public static String getNextAPIPayload(Partnership_Interest__c objProdUpsell) {
		if (objProdUpsell == null) {
			return null;
		} else {
			JSONGenerator objJsonGen = JSON.createGenerator(true);
			objJsonGen.writeStartObject();
			objJsonGen.writeStringField('target_system', NEXT_INSURANCE);
			objJsonGen.writeStringField('puid', objProdUpsell.PUID__c);

			if (objProdUpsell.OwnerId != null) {
				if (objProdUpsell.Owner.FirstName != null) {
					objJsonGen.writeStringField('partner_rep_first_name', objProdUpsell.Owner.FirstName);
				}
				if (objProdUpsell.Owner.LastName != null) {
					objJsonGen.writeStringField('partner_rep_last_name', objProdUpsell.Owner.LastName);
				}
				if (objProdUpsell.Owner.Email != null) {
					objJsonGen.writeStringField('partner_rep_email', objProdUpsell.Owner.Email);
				}
				if (objProdUpsell.Owner.UserRole.Name != null) {
					objJsonGen.writeStringField('owner_role', objProdUpsell.Owner.UserRole.Name);
				}
			}

			if (objProdUpsell.Contact__c != null) {
				if (objProdUpsell.Contact__r.FirstName != null) {
					objJsonGen.writeStringField('referral_first_name', objProdUpsell.Contact__r.FirstName);
				}

				if (objProdUpsell.Contact__r.LastName != null) {
					objJsonGen.writeStringField('referral_last_name', objProdUpsell.Contact__r.LastName);
				}

				if (objProdUpsell.Contact__r.Email != null) {
					objJsonGen.writeStringField('referral_email', objProdUpsell.Contact__r.Email);
				}

				if (objProdUpsell.Contact__r.Phone != null) {
					objJsonGen.writeStringField('referral_phone_number', objProdUpsell.Contact__r.Phone);
				} else if (objProdUpsell.Contact__r.MobilePhone != null) {
					objJsonGen.writeStringField('referral_phone_number', objProdUpsell.Contact__r.MobilePhone);
				}
			}

			if (objProdUpsell.Account__c != null) {
				if (objProdUpsell.Account__r.ZP_Company_ID__c != null) {
					objJsonGen.writeStringField('company_id', objProdUpsell.Account__r.ZP_Company_ID__c);
				}
				if (objProdUpsell.Account__r.Name != null) {
					objJsonGen.writeStringField('referral_company_name', objProdUpsell.Account__r.Name);
				}

				if (objProdUpsell.Account__r.Website != null) {
					objJsonGen.writeStringField('referral_company_website', objProdUpsell.Account__r.Website);
				}
				if (objProdUpsell.Account__r.BillingState != null) {
					objJsonGen.writeStringField('referral_state', objProdUpsell.Account__r.BillingState);
				}
				if (objProdUpsell.Account__r.BillingPostalCode != null) {
					objJsonGen.writeStringField('referral_zip_code', objProdUpsell.Account__r.BillingPostalCode);
				}
			}

			if (objProdUpsell.Employees__c != null) {
				objJsonGen.writeNumberField('referral_number_of_employees', objProdUpsell.Employees__c);
			}

			if (objProdUpsell.Work_Location__c != null) {
				objJsonGen.writeStringField('referral_address', objProdUpsell.Work_Location__c);
			}

			if (objProdUpsell.Workers_Comp_Notes__c != null) {
				objJsonGen.writeStringField('workers_comp_notes', objProdUpsell.Workers_Comp_Notes__c);
			}

			if (objProdUpsell.Secondary_Contact_from_Account__c != null) {
				if (objProdUpsell.Secondary_Contact_from_Account__r.FirstName != null) {
					objJsonGen.writeStringField('secondary_contact_first_name', objProdUpsell.Secondary_Contact_from_Account__r.FirstName);
				}

				if (objProdUpsell.Secondary_Contact_from_Account__r.LastName != null) {
					objJsonGen.writeStringField('secondary_contact_last_name', objProdUpsell.Secondary_Contact_from_Account__r.LastName);
				}

				if (objProdUpsell.Secondary_Contact_from_Account__r.Email != null) {
					objJsonGen.writeStringField('secondary_contact_email', objProdUpsell.Secondary_Contact_from_Account__r.Email);
				}

				if (objProdUpsell.Secondary_Contact_from_Account__r.Phone != null) {
					objJsonGen.writeStringField('secondary_contact_phone_number', objProdUpsell.Secondary_Contact_from_Account__r.Phone);
				} else if (objProdUpsell.Secondary_Contact_from_Account__r.MobilePhone != null) {
					objJsonGen.writeStringField('secondary_contact_phone_number', objProdUpsell.Secondary_Contact_from_Account__r.MobilePhone);
				}
			}

			objJsonGen.writeEndObject();

			String strJSON = objJsonGen.getAsString();

			return strJSON;
		}
	}
}