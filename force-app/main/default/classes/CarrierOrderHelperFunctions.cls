/**
* @name         CarrierOrderHelperFunctions
* @author       Sourav Mitra
* @date         05/31/2019
* @description  
* @test class   CarrierOrderHelperFunctionsTest
* @revisions    Date ------------ Name ------------ Comments
*               1/2/2020          Pravesh           Carrier Order creation logic for "Benefits BOR" type
                02/01/2020        Deepika           logic for for updating the OrderAssignment
**/

public class CarrierOrderHelperFunctions {
	public CarrierOrderHelperFunctions() {
	}

	static Id CARRIER_ORDER_BOR_RT = Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');
	public static Id CARRIER_ORDER_NEW_PLAN_RT = Cache.getRecordTypeId('Carrier_Order__c', 'New Plan');
	public static Id CARRIER_ORDER_RENEWAL_RT = Cache.getRecordTypeId('Carrier_Order__c', 'Renewal');
	public static Id CARRIER_ORDER_CHANGE_RT = Cache.getRecordTypeId('Carrier_Order__c', 'Benefit Change');
	static Id BENEFIT_ORDER_BOR_RT = Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR');
	static final Id BENEFIT_ORDER_RT_NEW_PLAN = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');
	static final Id BENEFIT_ORDER_RT_RENEWAL = Cache.getRecordTypeId('Benefit_Order__c', 'Renewal');
	static final Id BENEFIT_ORDER_RT_CHANGE = Cache.getRecordTypeId('Benefit_Order__c', 'Change');
	static final String INITIAL_TADA_SETUP = '-InitialTadaSetup';
	//this set contains BO Ids if they have related Tada Carrier Order
	set<Id> set_IsTadaBOId = new Set<Id>();
	//this set contains BO Ids if they have related non-Tada Carrier Orders
	set<Id> set_IsBORBOId = new Set<Id>();
	//this map Maintains HI_Carrier_Id and related Carrier_Order_LIne_Items mapping
	Map<String, Carrier_Order_Line_Item__c> map_CarrierOrderIdBenefitTypeKeyLineItemRecord = new Map<String, Carrier_Order_Line_Item__c>();
	//this map Maintains HI_Carrier_Id and related HI_Carrier_Information mapping
	Map<String, HI_Carrier_Information__c> map_hicarrierIdCarrierInfoRecord = new Map<String, HI_Carrier_Information__c>();
	//this map Maintains HI_Benefit_Id and related Benefits BoR type - Benefit Order record mapping
	Map<String, Benefit_Order__c> map_borTransferOppIdBORecord = new Map<String, Benefit_Order__c>();
	//this maps uses HI_Benefit_Id and Carrier_Key as a composit key to maintain their relationship with Carrier_Order records
	map<string, Carrier_Order__c> map_CarrierIdBenefitIdCarrierRecord = new Map<string, Carrier_Order__c>();
	//We are using this map to maintain benefitOrder and related TTF record mapping
	map<string, string> map_benefitOrderIdTTFId = new Map<String, String>();
	//this map manages BO and 'sales' provided carrier based renewal date mapping
	map<string, map<string, Date>> map_BOIdAndCarrierKeyRenewalDate = new Map<string, map<string, Date>>();
	//BY:PR, Date:Oct-8-2020, Desc: To implement "Special Enrollment" functionality, we are getting the fixed date from the custom setting
	static Date dtSpecial_Enrollment_Deadline_Date = Configuration_Settings__c.getOrgDefaults().Special_Enrollment_Deadline_Date__c;
	// BY: PR, Date:Oct-15-2020, Desc: need the bo values to calcualte "special enrollment" deadline for termination CO
	static Map<Id, Benefit_Order__c> map_BOIdRec = new Map<Id, Benefit_Order__c>();
	Map<String, integer> map_OrderTypePrecedents = new Map<String, integer>{
		'carrier switch' => 1,
		'same carrier, no plan/group level changes' => 4,
		'same carrier, plan/group level changes' => 2,
		'new line of coverage' => 3
	};

	public static map<Id, Benefit_Order__c> getBenefitOrdersById(Set<Id> orderIdSet) {
		map<Id, Benefit_Order__c> orderMap = new Map<Id, Benefit_Order__c>();
		orderMap = new Map<Id, Benefit_Order__c>(
			[
				SELECT
					Id,
					Opportunity__c,
					Account__c,
					Opportunity__r.AccountId,
					recordType.Name,
					recordTypeId,
					Renewal_Date__c,
					Special_Enrollment__c,
					Order_Status__c,
					Status_Detail__c,
					Coverage_Effective_Date__c,
					Opportunity__r.HI_Effective_Date__c,
					Type__c,
					Initial_Owner__c,
					Is_Multi_EIN__c,
					(SELECT Id FROM Cases__r),
					(SELECT Id, Special_Enrollment__c FROM Transition_to_Fulfillments__r)
				FROM Benefit_Order__c
				WHERE Id IN :orderIdSet
			]
		);
		return orderMap;
	}

	/*
	 * @author:         Deepika Saini
	 * @description:    get Carrier data
	 * @parm:           NA
	 * @return:         NA
	 */
	public static Map<Id, Carrier__c> getCarrierById(Set<Id> set_Carrier) {
		Map<Id, Carrier__c> map_Carrier = new Map<Id, Carrier__c>();
		map_Carrier = new Map<Id, Carrier__c>(
			[
				SELECT Id, Name, Partner_Type__c
				FROM Carrier__c
				WHERE Id IN :set_Carrier
			]
		);
		return map_Carrier;
	}

	static final string CARRIER_BASIC_PACIFIC_RENEWAL = 'BASIC PACIFIC Renewal';
	static final string CARRIER_BASIC_PACIFIC_SETUP = 'BASIC PACIFIC Setup';
	static final string SUBJECT_TO_FEDERAL = 'Federal';

	//>>>>>>>>>>>>>>>>>>>>>>>Carrier Order creation logic of "Benefits BOR" type  ==============START=================
	/*following method is used to create or edit an instance of the Carrier order. In this instance we also map field values from HiCarrierInformation
	 record to related Carrier Order records. */
	private Carrier_Order__c mapFields(HI_Carrier_Information__c hiInfo, Map<String, Carrier__c> carrierInformationMap) {
		Carrier_Order__c coRec;

		string keyStr = 'HIBORTRANSFER' + hiInfo.BOR_Transfer_Id__c + hiInfo.Key__c;
		if (map_CarrierIdBenefitIdCarrierRecord != null && map_CarrierIdBenefitIdCarrierRecord.size() > 0 && map_CarrierIdBenefitIdCarrierRecord.containsKey(keyStr)) {
			if (hiInfo.Deleted_At__c != null && hiInfo.Old_Deleted_At__c == hiInfo.Deleted_At__c) {
				return null;
			}
			coRec = map_CarrierIdBenefitIdCarrierRecord.get(keyStr);

			string benefitTypeStr = getBenefitTypes(hiInfo.Plan_Type__c.toUpperCase());
			if (benefitTypeStr == hiInfo.Plan_Type__c.toUpperCase()) {
				benefitTypeStr = Utils.humanize(benefitTypeStr);
			}

			if (hiInfo.Deleted_At__c != null && string.isNotBlank(coRec.Benefit_Types__c) && coRec.Benefit_Types__c.indexOf(benefitTypeStr) > -1) {
				coRec.Benefit_Types__c = coRec.Benefit_Types__c.replace(benefitTypeStr, '').replace(';;', ';');
			}
		} else {
			if (hiInfo.Deleted_At__c != null) {
				return null;
			}
			coRec = new Carrier_Order__c();
			//DS[21-05-2020]:- add check for 80 charcter limit
			String strCarrierOrderName =
				map_borTransferOppIdBORecord.get('HIBORTRANSFER' + hiInfo.BOR_Transfer_Id__c).opportunity__r.Account.Name +
				' - ' +
				carrierInformationMap.get(hiInfo.Key__c).Name;
			if (String.isNotBlank(strCarrierOrderName) && strCarrierOrderName.length() > 80) {
				strCarrierOrderName = carrierInformationMap.get(hiInfo.Key__c).Name;
			}
			coRec.Name = strCarrierOrderName;
			coRec.RecordTypeId = CARRIER_ORDER_BOR_RT;
			coRec.carrier__c = carrierInformationMap.get(hiInfo.Key__c).Id;
			coRec.Benefit_Order__c = map_borTransferOppIdBORecord.get('HIBORTRANSFER' + hiInfo.BOR_Transfer_Id__c).Id;
			coRec.Is_Multi_EIN__c = map_borTransferOppIdBORecord.get('HIBORTRANSFER' + hiInfo.BOR_Transfer_Id__c).Is_Multi_EIN__c;

			if (coRec.Benefit_Order__c != null && map_BOIdAndCarrierKeyRenewalDate.containsKey('HIBORTRANSFER' + hiInfo.BOR_Transfer_Id__c)) {
				map<string, Date> map_carrierKeyRenewalDate = map_BOIdAndCarrierKeyRenewalDate.get('HIBORTRANSFER' + hiInfo.BOR_Transfer_Id__c);
				if (map_carrierKeyRenewalDate != null && map_carrierKeyRenewalDate.size() > 0 && map_carrierKeyRenewalDate.containsKey(hiInfo.Key__c)) {
					coRec.Renewal_Date__c = map_carrierKeyRenewalDate.get(hiInfo.Key__c);
				}
			}
		}

		if (hiInfo.Authorized_Date__c != null) {
			coRec.Authorized_Date__c = date.newinstance(hiInfo.Authorized_Date__c.year(), hiInfo.Authorized_Date__c.month(), hiInfo.Authorized_Date__c.day());
		}

		return coRec;
	}

	public String getBenefitTypes(String strLineOfCoverage) {
		String strBenefitType;
		switch on strLineOfCoverage {
			when 'LTD' {
				strBenefitType = 'Long Term Disability';
			}
			when 'STD' {
				strBenefitType = 'Short Term Disability';
			}
			when 'FSA' {
				strBenefitType = 'Flexible Spending Account - Medical';
			}
			when 'DCA' {
				strBenefitType = 'Flexible Spending Account - Dependent Care';
			}
			when else {
				strBenefitType = strLineOfCoverage;
			}
		}

		return strBenefitType;
	}

	/*This method gets called from HICarrierInformation Trigger Helper. This methods queries all the related information based on external ids
	 and process the HICarrierInformation records.*/
	public void processHICarrierInformation(List<HI_Carrier_Information__c> informations) {
		Set<String> borTransferIdSet = new Set<String>();
		Set<String> carrierKeySet = new Set<String>();
		Map<String, HI_Carrier_Information__c> HiCarrierIdmap = new Map<String, HI_Carrier_Information__c>();

		for (HI_Carrier_Information__c hiInfo : informations) {
			borTransferIdSet.add('HIBORTRANSFER' + hiInfo.BOR_Transfer_Id__c);
			HiCarrierIdmap.put(hiInfo.Id__c, hiInfo);
			carrierKeySet.add(hiInfo.Key__c);
		}

		set<string> set_BenefitOrderIds = new Set<String>();
		for (Benefit_Order__c objBO : [
			SELECT Id, Opportunity__c, Additional_Details__c, Special_Enrollment__c, opportunity__r.Account.Name, Opportunity__r.Id__c, Is_Multi_EIN__c
			FROM Benefit_Order__c
			WHERE RecordTypeId = :BENEFIT_ORDER_BOR_RT AND Opportunity__r.Id__c IN :borTransferIdSet
		]) {
			map_borTransferOppIdBORecord.put(objBO.Opportunity__r.Id__c, objBO);
			set_BenefitOrderIds.add(objBO.Id);
		}

		//following logic is processing Sales provided "Renewal Date" according to "carrier Key" and  "Benefit Order"
		if (set_BenefitOrderIds.size() > 0) {
			map<string, list<string>> map_boIdCarrierInfoList = new Map<string, list<string>>();

			for (Transition_to_Fulfillment__c ttfRec : [
				SELECT
					Id,
					Benefit_Order__c,
					Opportunity__r.Id__c,
					Vision_Renewal_Date__c,
					TAdA_Renewal_Date__c,
					Commuter_Renewal_Date__c,
					Dental_Renewal_Date__c,
					DCA_Renewal_Date__c,
					FSA_Renewal_Date__c,
					HSA_Renewal_Date__c,
					Medical_Renewal_Date__c,
					Life_Renewal_Date__c,
					LTD_Renewal_Date__c,
					STD_Renewal_Date__c,
					Type_of_Transfer_TADA_s__c,
					Type_of_TADA_s__c
				FROM Transition_to_Fulfillment__c
				WHERE Opportunity__r.Id__c IN :borTransferIdSet
			]) {
				map<string, Date> map_carrierKeyRenewalDate = processRenewalDateStr(ttfRec);

				if (map_carrierKeyRenewalDate != null && map_carrierKeyRenewalDate.size() > 0) {
					map_BOIdAndCarrierKeyRenewalDate.put(ttfRec.Opportunity__r.Id__c, map_carrierKeyRenewalDate);
				}
			}
		}

		Map<String, Carrier__c> carrierInformationMap = new Map<String, Carrier__c>();
		for (Carrier__c carrier : [SELECT Name, Id, Id__c, Key__c FROM Carrier__c WHERE Key__c IN :carrierKeySet FOR UPDATE]) {
			Carrier__c objTempCarrier = new Carrier__c();
			objTempCarrier = new Carrier__c(Id = carrier.Id);
			objTempCarrier.Name = carrier.Name;
			objTempCarrier.Id__c = carrier.Id__c;
			objTempCarrier.Key__c = carrier.Key__c;
			carrierInformationMap.put(objTempCarrier.Key__c, objTempCarrier);
		}

		for (Carrier_Order__c coRec : [
			SELECT
				Id,
				Benefit_Order__r.Opportunity__r.Id__c,
				Carrier__r.Key__c,
				RecordTypeId,
				Unique_Id__c,
				Authorized_Date__c,
				carrier__c,
				Benefit_Types__c,
				Group_Number__c,
				Secondary_Policy_Number__c,
				Benefit_Order__c,
				Renewal_Date__c,
				(
					SELECT Id, Benefit_Types__c, Carrier_Order__c, Group_Number__c, HI_Carrier_Information_Id__c, Policy_Number__c, Secondary_Policy_Number__c, Renewal_Date__c
					FROM Carrier_Order_Line_Item__r
				)
			FROM Carrier_Order__c
			WHERE Benefit_Order__r.Opportunity__r.Id__c IN :borTransferIdSet
			FOR UPDATE
		]) {
			string keystr = coRec.Benefit_Order__r.Opportunity__r.Id__c + coRec.Carrier__r.Key__c;
			map_CarrierIdBenefitIdCarrierRecord.put(keystr, coRec);
			if (coRec.Carrier_Order_Line_Item__r.size() > 0) {
				for (Carrier_Order_Line_Item__c rec : coRec.Carrier_Order_Line_Item__r) {
					string strKeyTemp = string.valueOf(coRec.Id) + ';' + rec.Benefit_Types__c;
					map_CarrierOrderIdBenefitTypeKeyLineItemRecord.put(strKeyTemp, rec);
				}
			}
		}

		for (HI_Carrier_Information__c hiInfo : informations) {
			if (hiInfo.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			if (!carrierInformationMap.containsKey(hiInfo.Key__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, 'Carrier does not exist for this record.', hiInfo);
				continue;
			}
			if (!map_borTransferOppIdBORecord.containskey('HIBORTRANSFER' + hiInfo.BOR_Transfer_Id__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, 'BOR Transfer does not exist.', hiInfo);
				continue;
			}
			if (hiInfo.Deleted_At__c != null) {
				setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Carrier Information is deleted.', hiInfo);
			}
			Carrier_Order__c info = mapFields(hiInfo, carrierInformationMap);

			//BY:PR, Date:Oct-15-2020, Desc: To handle "special enrollment" we want to process only new carrierorders
			if (
				info != null &&
				info.Id == null &&
				map_borTransferOppIdBORecord != null &&
				hiInfo.Plan_Type__c != null &&
				map_borTransferOppIdBORecord.containsKey('HIBORTRANSFER' + hiInfo.BOR_Transfer_Id__c)
			) {
				handleSpecialEnrollmentDates(
					hiInfo.Plan_Type__c,
					map_borTransferOppIdBORecord.get('HIBORTRANSFER' + hiInfo.BOR_Transfer_Id__c).Special_Enrollment__c,
					dtSpecial_Enrollment_Deadline_Date,
					info,
					info.RecordTypeId
				);
			}

			if (info != null) {
				string keyStr = 'HIBORTRANSFER' + hiInfo.BOR_Transfer_Id__c + hiInfo.Key__c;
				map_CarrierIdBenefitIdCarrierRecord.put(keyStr, info);
				set_IsBORBOId.add(info.Benefit_Order__c);
			}

			map_hicarrierIdCarrierInfoRecord.put(hiInfo.Id__c, hiInfo);
		}

		if (map_CarrierIdBenefitIdCarrierRecord.values().size() > 0) {
			try {
				database.upsert(map_CarrierIdBenefitIdCarrierRecord.values(), Carrier_Order__c.Fields.Id, false);
			} catch (Exception ex) {
				ExceptionLogUtil.logException(
					'CarrierOrderHelperFunctions',
					'processHICarrierInformation',
					'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(),
					ex.getStackTraceString()
				);
			}
		}

		syncCarrierOrderLineItems();

		if (HICarrierInformationTriggerHelper.isBOInsert) {
			//this filter will only be true at the time of BO Insert
			syncTadaCarrierOrderRecordsAndLineItem();
		}

		if (list_CarrierOrderLineItemToUpsert.size() > 0) {
			try {
				upsert list_CarrierOrderLineItemToUpsert;
			} catch (exception ex) {
				ExceptionLogUtil.logException(
					'CarrierOrderHelperFunctions',
					'processHICarrierInformation',
					'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(),
					ex.getStackTraceString()
				);
			}
		}
	}

	list<Carrier_Order_Line_Item__c> list_CarrierOrderLineItemToUpsert = new List<Carrier_Order_Line_Item__c>();

	/**This Method gets TTF record as a parameter and process Sales provided renewal date information. */
	private map<string, Date> processRenewalDateStr(Transition_to_Fulfillment__c objTTFRec) {
		//this map manages mapping of [carrierKey & Renewal date] in case of non-tada and [Benefit Type & Renewal Date] in case of Tada.
		map<string, date> map_carrierKeyRenewalDate = new Map<string, date>();

		if (objTTFRec != null) {
			//used to store non tada renewal dates
			list<string> lst_multipleCarrierRenewalDateStr = new List<String>();

			if (objTTFRec.HSA_Renewal_Date__c != null) {
				map_carrierKeyRenewalDate.put('hsa', objTTFRec.HSA_Renewal_Date__c);
			}

			if (objTTFRec.FSA_Renewal_Date__c != null) {
				map_carrierKeyRenewalDate.put('fsa', objTTFRec.FSA_Renewal_Date__c);
			}

			if (objTTFRec.DCA_Renewal_Date__c != null) {
				map_carrierKeyRenewalDate.put('dca', objTTFRec.DCA_Renewal_Date__c);
			}

			if (string.isNotBlank(objTTFRec.Type_of_Transfer_TADA_s__c)) {
				for (string strTada : objTTFRec.Type_of_Transfer_TADA_s__c.toLowerCase().split(';')) {
					if (!map_carrierKeyRenewalDate.containsKey(strTada)) {
						map_carrierKeyRenewalDate.put(strTada, null);
					}
				}
			}

			if (string.isNotBlank(objTTFRec.Type_of_TADA_s__c)) {
				for (string strTada : objTTFRec.Type_of_TADA_s__c.toLowerCase().split(';')) {
					if (string.isBlank(strTada)) {
						continue;
					}
					if (strTada.equalsIgnoreCase('Flexible Spending Account - Dependent Care')) {
						strTada = 'dca';
					} else if (strTada.equalsIgnoreCase('Flexible Spending Account - Medical')) {
						strTada = 'fsa';
					}
					if (!map_carrierKeyRenewalDate.containsKey(strTada)) {
						map_carrierKeyRenewalDate.put(strTada, null);
					}
				}
			}

			if (string.isNotBlank(objTTFRec.Medical_Renewal_Date__c) && objTTFRec.Medical_Renewal_Date__c.indexOf(';') > -1) {
				lst_multipleCarrierRenewalDateStr.addAll(objTTFRec.Medical_Renewal_Date__c.split(';'));
			} else if (string.isNotBlank(objTTFRec.Medical_Renewal_Date__c)) {
				lst_multipleCarrierRenewalDateStr.add(objTTFRec.Medical_Renewal_Date__c);
			}

			if (string.isNotBlank(objTTFRec.Dental_Renewal_Date__c) && objTTFRec.Dental_Renewal_Date__c.indexOf(';') > -1) {
				lst_multipleCarrierRenewalDateStr.addAll(objTTFRec.Dental_Renewal_Date__c.split(';'));
			} else if (string.isNotBlank(objTTFRec.Dental_Renewal_Date__c)) {
				lst_multipleCarrierRenewalDateStr.add(objTTFRec.Dental_Renewal_Date__c);
			}

			if (string.isNotBlank(objTTFRec.Vision_Renewal_Date__c) && objTTFRec.Vision_Renewal_Date__c.indexOf(';') > -1) {
				lst_multipleCarrierRenewalDateStr.addAll(objTTFRec.Vision_Renewal_Date__c.split(';'));
			} else if (string.isNotBlank(objTTFRec.Vision_Renewal_Date__c)) {
				lst_multipleCarrierRenewalDateStr.add(objTTFRec.Vision_Renewal_Date__c);
			}

			if (string.isNotBlank(objTTFRec.LTD_Renewal_Date__c) && objTTFRec.LTD_Renewal_Date__c.indexOf(';') > -1) {
				lst_multipleCarrierRenewalDateStr.addAll(objTTFRec.LTD_Renewal_Date__c.split(';'));
			} else if (string.isNotBlank(objTTFRec.LTD_Renewal_Date__c)) {
				lst_multipleCarrierRenewalDateStr.add(objTTFRec.LTD_Renewal_Date__c);
			}

			if (string.isNotBlank(objTTFRec.STD_Renewal_Date__c) && objTTFRec.STD_Renewal_Date__c.indexOf(';') > -1) {
				lst_multipleCarrierRenewalDateStr.addAll(objTTFRec.STD_Renewal_Date__c.split(';'));
			} else if (string.isNotBlank(objTTFRec.STD_Renewal_Date__c)) {
				lst_multipleCarrierRenewalDateStr.add(objTTFRec.STD_Renewal_Date__c);
			}

			if (string.isNotBlank(objTTFRec.Life_Renewal_Date__c) && objTTFRec.Life_Renewal_Date__c.indexOf(';') > -1) {
				lst_multipleCarrierRenewalDateStr.addAll(objTTFRec.Life_Renewal_Date__c.split(';'));
			} else if (string.isNotBlank(objTTFRec.Life_Renewal_Date__c)) {
				lst_multipleCarrierRenewalDateStr.add(objTTFRec.Life_Renewal_Date__c);
			}

			//for non tada carriers
			if (lst_multipleCarrierRenewalDateStr.size() > 0) {
				for (string strTemp : lst_multipleCarrierRenewalDateStr) {
					if (strTemp.indexOf('>') > -1) {
						list<string> lstTemp = strTemp.split('>');
						if (lstTemp != null && lstTemp.size() > 0) {
							integer intYear = integer.valueOf(lstTemp.get(1).trim().split('/').get(0));
							integer intMonth = integer.valueOf(lstTemp.get(1).trim().split('/').get(1));
							integer intDay = integer.valueOf(lstTemp.get(1).trim().split('/').get(2));
							date dtRenewalDateTemp = date.newInstance(intYear, intMonth, intDay);
							map_carrierKeyRenewalDate.put(lstTemp.get(0).trim(), dtRenewalDateTemp);
						}
					}
				}
			}

			return map_carrierKeyRenewalDate;
		}

		return null;
	}

	/*
        Desc: Following method is syncing "CO Line Item" based on "HI Carrier Information" records
    */
	public void syncCarrierOrderLineItems() {
		map<string, String> map_BenefitCarrierOrderKeyBenefitsStr = new Map<String, String>();
		map<string, Carrier_Order_Line_Item__c> map_toDeleteLineItemRec = new Map<string, Carrier_Order_Line_Item__c>();
		map<string, Carrier_Order_Line_Item__c> map_toUpsertLineItemRec = new Map<string, Carrier_Order_Line_Item__c>();

		for (string carrierInfoId : map_hicarrierIdCarrierInfoRecord.keyset()) {
			Carrier_Order_Line_Item__c lineItemrec;
			HI_Carrier_Information__c carrierInfoRec = map_hicarrierIdCarrierInfoRecord.get(carrierInfoId);
			string keyStr = 'HIBORTRANSFER' + carrierInfoRec.BOR_Transfer_Id__c + carrierInfoRec.Key__c;
			Carrier_Order__c carrierOrderRec = map_CarrierIdBenefitIdCarrierRecord.get(keyStr);

			string strPlanTypeTemp;
			if (carrierInfoRec.Plan_Type__c.equalsIgnoreCase('ltd')) {
				strPlanTypeTemp = 'Long term disability';
			} else if (carrierInfoRec.Plan_Type__c.equalsIgnoreCase('std')) {
				strPlanTypeTemp = 'Short term disablity';
			} else {
				strPlanTypeTemp = Utils.humanize(carrierInfoRec.Plan_Type__c);
			}

			string strKeyTempForLineItem = string.valueOf(carrierOrderRec.Id) + ';' + strPlanTypeTemp;
			if (map_CarrierOrderIdBenefitTypeKeyLineItemRecord.containsKey(strKeyTempForLineItem)) {
				lineItemrec = map_CarrierOrderIdBenefitTypeKeyLineItemRecord.get(strKeyTempForLineItem);
				if (lineItemrec.Id != null && carrierInfoRec.Deleted_At__c == null) {
					//check for new CO-line-item
					setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Information is successfully processed. Duplicate record found.', carrierInfoRec);
				}
				if (lineItemrec.Id != null && carrierInfoRec.Deleted_At__c != null && carrierInfoRec.Old_Deleted_At__c != carrierInfoRec.Deleted_At__c) {
					map_toDeleteLineItemRec.put(carrierInfoRec.BOR_Transfer_Id__c + ';' + carrierInfoRec.Key__c + ';' + carrierInfoRec.Plan_Type__c, lineItemrec);
					continue;
				}
			} else {
				if (carrierInfoRec.Deleted_At__c != null) {
					continue;
				}
				lineItemrec = new Carrier_Order_Line_Item__c();
				lineItemrec.Carrier_Order__c = carrierOrderRec.Id;
				lineItemrec.Benefit_Types__c = strPlanTypeTemp;
				lineItemrec.HI_Carrier_Information_Id__c = carrierInfoId;

				if (carrierOrderRec.Renewal_Date__c != null) {
					lineItemrec.Renewal_Date__c = carrierOrderRec.Renewal_Date__c;
				}
			}

			list<String> list_temp = new List<String>();
			if (String.isNotBlank(carrierInfoRec.Policy_Number__c)) {
				set<string> set_PolicyNumber = new Set<string>();
				if (string.isNotBlank(lineItemrec.Policy_Number__c)) {
					set_PolicyNumber.addAll(lineItemrec.Policy_Number__c.split(','));
					set_PolicyNumber.add(carrierInfoRec.Policy_Number__c);
					list_temp.addAll(set_PolicyNumber);
					lineItemrec.Policy_Number__c = string.join(list_temp, ',');
				} else {
					lineItemrec.Policy_Number__c = carrierInfoRec.Policy_Number__c;
				}

				lineItemrec.Group_Number__c = lineItemrec.Policy_Number__c;
			}

			if (string.isNotBlank(carrierInfoRec.Secondary_Policy_Number__c)) {
				set<string> set_SecondPolicyNumber = new Set<string>();
				if (string.isNotBlank(lineItemrec.Secondary_Policy_Number__c)) {
					set_SecondPolicyNumber.addAll(lineItemrec.Secondary_Policy_Number__c.split(','));
					set_SecondPolicyNumber.add(carrierInfoRec.Secondary_Policy_Number__c);
					list_temp = new List<String>();
					list_temp.addAll(set_SecondPolicyNumber);
					lineItemrec.Secondary_Policy_Number__c = string.join(list_temp, ',');
				} else {
					lineItemrec.Secondary_Policy_Number__c = carrierInfoRec.Secondary_Policy_Number__c;
				}
			}

			map_toUpsertLineItemRec.put(strKeyTempForLineItem, lineItemrec);
			//check for duplicte HI Carrier Information record at the time of CO and Line Item creation
			map_CarrierOrderIdBenefitTypeKeyLineItemRecord.put(strKeyTempForLineItem, lineItemrec);
		}

		try {
			if (map_toUpsertLineItemRec.size() > 0) {
				list_CarrierOrderLineItemToUpsert.addAll(map_toUpsertLineItemRec.values());
			}

			if (map_toDeleteLineItemRec.size() > 0) {
				deleteUpdateLineItemRecords(map_toDeleteLineItemRec);
			}
		} catch (exception ex) {
			ExceptionLogUtil.logException('CarrierOrderHelperFunctions', 'syncCarrierOrderLineItems', ex.getMessage(), 'High');
		}
	}

	/*BY: PR, Date: May/18/2020,
	 * Desc: we want to filter out all the CarrierOrderLineItem records that have a duplicate non deleted HI Carrier Info
	 *      Record present in the database. We also want to update HI_Carrier_Information Id in the CarrierOrderLineItem
	 *      records that we are not deleting.
	 *  Jira: https://app.asana.com/0/1149920908637905/1175613125180347/f
	 */
	public void deleteUpdateLineItemRecords(map<string, Carrier_Order_Line_Item__c> map_BorIDCarKeyPlanTypeCOLIToBeDeleted) {
		if (map_BorIDCarKeyPlanTypeCOLIToBeDeleted.size() > 0) {
			set<string> set_BORId = new Set<string>();
			set<string> set_CarrierKey = new Set<string>();
			set<string> set_PlanType = new Set<string>();

			list<Carrier_Order_Line_Item__c> list_COLIRecordsWithUpdatedHICarrierParent = new List<Carrier_Order_Line_Item__c>();

			for (string strKey : map_BorIDCarKeyPlanTypeCOLIToBeDeleted.keyset()) {
				if (string.isNotBlank(strKey)) {
					list<string> list_TempKeys = strKey.split(';');
					set_BORId.add(list_TempKeys[0]);
					set_CarrierKey.add(list_TempKeys[1]);
					set_PlanType.add(list_TempKeys[2]);
				}
			}

			if (set_BORId.size() > 0 && set_CarrierKey.size() > 0 && set_PlanType.size() > 0) {
				for (HI_Carrier_Information__c hiRec : [
					SELECT Id, Id__c, BOR_Transfer_Id__c, Old_Deleted_At__c, Key__c, Plan_Type__c, Deleted_At__c
					FROM HI_Carrier_Information__c
					WHERE Deleted_At__c = NULL AND BOR_Transfer_Id__c IN :set_BORId AND Key__c IN :set_CarrierKey AND Plan_Type__c IN :set_PlanType
				]) {
					string strKey = hiRec.BOR_Transfer_Id__c + ';' + hiRec.Key__c + ';' + hiRec.Plan_Type__c;

					if (map_BorIDCarKeyPlanTypeCOLIToBeDeleted.containsKey(strKey)) {
						Carrier_Order_Line_Item__c objTempLineItemRec = map_BorIDCarKeyPlanTypeCOLIToBeDeleted.get(strKey);
						objTempLineItemRec.HI_Carrier_Information_Id__c = hiRec.Id__c;
						list_COLIRecordsWithUpdatedHICarrierParent.add(objTempLineItemRec);
						map_BorIDCarKeyPlanTypeCOLIToBeDeleted.remove(strKey);
					}
				}

				if (map_BorIDCarKeyPlanTypeCOLIToBeDeleted.size() > 0) {
					delete map_BorIDCarKeyPlanTypeCOLIToBeDeleted.values();
				}

				if (list_COLIRecordsWithUpdatedHICarrierParent.size() > 0) {
					update list_COLIRecordsWithUpdatedHICarrierParent;
				}
			}
		}
	}

	/*  By: PR, Date: Dec 20,2019
        Desc: following method is getting called when BO is inserted. Following method is reading json present in Additional_Details__c field of
        related "HI BOR Transfer" record and according to the json we are creating Tada "CO" and related "CO Line Item"
    */
	public void syncTadaCarrierOrderRecordsAndLineItem() {
		//'HIBORTRANSFER'+hiInfo.BOR_Transfer_Id__c
		Carrier__c objCOTada;
		String strCOTadaKey = '';
		Configuration_Settings__c configRec = Configuration_Settings__c.getOrgDefaults();

		if (configRec != null && configRec.Active_TAdA_Provider__c != null) {
			strCOTadaKey = String.valueOf(configRec.Active_TAdA_Provider__c);
			list<Carrier__c> lst_Carrier = [SELECT Id, Key__c, Name FROM Carrier__c WHERE Key__c = :strCOTadaKey];
			if (lst_Carrier.size() > 0) {
				objCOTada = lst_Carrier.get(0);
			} else {
				return;
			}
		}

		Map<Id, list<Carrier_Order_Line_Item__c>> map_boIdCarrierOrderList = new Map<Id, list<Carrier_Order_Line_Item__c>>();
		list<Carrier_Order__c> lst_toInsertCarrierOrder = new List<Carrier_Order__c>();

		if (map_borTransferOppIdBORecord.size() > 0) {
			set<string> set_borId = new Set<string>();
			for (string strBorId : map_borTransferOppIdBORecord.keyset()) {
				set_borId.add(strBorId.replace('HIBORTRANSFER', ' ').trim());
			}

			for (HI_BoR_Transfer__c objHIBoR : [SELECT Id, Additional_Information__c, Id__c FROM HI_BoR_Transfer__c WHERE Id__c IN :set_borId]) {
				if (string.isNotBlank(objHIBoR.Additional_Information__c) || map_BOIdAndCarrierKeyRenewalDate.containsKey('HIBORTRANSFER' + objHIBoR.Id__c)) {
					Benefit_Order__c objBO = map_borTransferOppIdBORecord.get('HIBORTRANSFER' + objHIBoR.Id__c);
					map<string, Date> map_carrierKeyRenewalDate = new Map<string, Date>();
					date dt_minRenewalDate;

					BORAdditionalInformationJSON parsedData;

					if (string.isNotBlank(objHIBoR.Additional_Information__c)) {
						parsedData = (BORAdditionalInformationJSON) JSON.deserialize(objHIBoR.Additional_Information__c.replace('=>', ': '), BORAdditionalInformationJSON.class);
					}

					string strKey = objBO.Opportunity__r.Id__c + objCOTada.Key__c;
					Carrier_Order__c objcarrierOrder;
					if (map_CarrierIdBenefitIdCarrierRecord.containsKey(strKey)) {
						objcarrierOrder = map_CarrierIdBenefitIdCarrierRecord.get(strKey);
					} else {
						objcarrierOrder = new Carrier_Order__c();
						objcarrierOrder.RecordTypeId = CARRIER_ORDER_BOR_RT;
						objcarrierOrder.Benefit_Order__c = objBO.Id;
						objcarrierOrder.Carrier__c = objCOTada.Id;
						//DS[21-05-2020]:- add check for 80 charcter limit
						String strCarrierOrderName = objBO.opportunity__r.Account.Name + ' - ' + objCOTada.Name;
						if (String.isNotBlank(strCarrierOrderName) && strCarrierOrderName.length() > 80) {
							strCarrierOrderName = objCOTada.Name;
						}
						objcarrierOrder.Name = strCarrierOrderName;
					}

					if (objBO.Is_Multi_EIN__c) {
						objcarrierOrder.Is_Multi_EIN__c = true;
					}

					if (objcarrierOrder.Benefit_Order__c != null && map_BOIdAndCarrierKeyRenewalDate.containsKey('HIBORTRANSFER' + objHIBoR.Id__c)) {
						map_carrierKeyRenewalDate = map_BOIdAndCarrierKeyRenewalDate.get('HIBORTRANSFER' + objHIBoR.Id__c);
					}

					// if data is present in json or introduced by user manually in TTF
					if ((parsedData != null && parsedData.administrators != null) || map_carrierKeyRenewalDate.size() > 0) {
						BORAdditionalInformationJSON.cls_administrators administrators;
						if (parsedData != null && parsedData.administrators != null) {
							administrators = parsedData.administrators;
						}

						list<Carrier_Order_Line_Item__c> lst_tadaCarrierLineItems = new List<Carrier_Order_Line_Item__c>();

						if ((administrators != null && administrators.fsa != null) || map_carrierKeyRenewalDate.containsKey('fsa')) {
							Carrier_Order_Line_Item__c objCOTemp = createCarrierOrderLineItemsForTaDa('fsa', (administrators != null && administrators.fsa != null ? administrators.fsa : ''));

							if (map_carrierKeyRenewalDate != null && map_carrierKeyRenewalDate.size() > 0) {
								if (map_carrierKeyRenewalDate.containsKey('fsa')) {
									dt_minRenewalDate = map_carrierKeyRenewalDate.get('fsa');
									objCOTemp.Renewal_Date__c = map_carrierKeyRenewalDate.get('fsa');
								}
							}
							lst_tadaCarrierLineItems.add(objCOTemp);
							/**Tada Carrier Order "Benefit Type" handling code */
							String strBenefitType = 'Flexible Spending Account - Medical';
							if (string.isBlank(objcarrierOrder.Benefit_Types__c)) {
								objcarrierOrder.Benefit_Types__c = strBenefitType;
							} else if (string.isNotBlank(objcarrierOrder.Benefit_Types__c) && objcarrierOrder.Benefit_Types__c.indexOf(strBenefitType) < 0) {
								objcarrierOrder.Benefit_Types__c = objcarrierOrder.Benefit_Types__c + ';' + strBenefitType;
							}
						}
						if ((administrators != null && administrators.hsa != null) || map_carrierKeyRenewalDate.containsKey('hsa')) {
							Carrier_Order_Line_Item__c objCOTemp = createCarrierOrderLineItemsForTaDa('hsa', (administrators != null && administrators.hsa != null ? administrators.hsa : ''));

							if (map_carrierKeyRenewalDate != null && map_carrierKeyRenewalDate.size() > 0) {
								if (map_carrierKeyRenewalDate.containsKey('hsa')) {
									if (dt_minRenewalDate != null && dt_minRenewalDate > map_carrierKeyRenewalDate.get('hsa')) {
										dt_minRenewalDate = map_carrierKeyRenewalDate.get('hsa');
									} else if (dt_minRenewalDate == null) {
										dt_minRenewalDate = map_carrierKeyRenewalDate.get('hsa');
									}
									objCOTemp.Renewal_Date__c = map_carrierKeyRenewalDate.get('hsa');
								}
							}

							lst_tadaCarrierLineItems.add(objCOTemp);

							/**Tada Carrier Order "Benefit Type" handling code */
							if (string.isBlank(objcarrierOrder.Benefit_Types__c)) {
								objcarrierOrder.Benefit_Types__c = CarrierOrderUtil.TADA_BEN_TYPE_HSA;
							} else if (string.isNotBlank(objcarrierOrder.Benefit_Types__c) && objcarrierOrder.Benefit_Types__c.indexOf(CarrierOrderUtil.TADA_BEN_TYPE_HSA) < 0) {
								objcarrierOrder.Benefit_Types__c = objcarrierOrder.Benefit_Types__c + ';' + CarrierOrderUtil.TADA_BEN_TYPE_HSA;
							}
						}
						if ((administrators != null && administrators.dca != null) || map_carrierKeyRenewalDate.containsKey('dca')) {
							Carrier_Order_Line_Item__c objCOTemp = createCarrierOrderLineItemsForTaDa('dca', (administrators != null && administrators.dca != null ? administrators.dca : ''));

							if (map_carrierKeyRenewalDate != null && map_carrierKeyRenewalDate.size() > 0) {
								if (map_carrierKeyRenewalDate.containsKey('dca')) {
									if (dt_minRenewalDate != null && dt_minRenewalDate > map_carrierKeyRenewalDate.get('dca')) {
										dt_minRenewalDate = map_carrierKeyRenewalDate.get('dca');
									} else if (dt_minRenewalDate == null) {
										dt_minRenewalDate = map_carrierKeyRenewalDate.get('dca');
									}
									objCOTemp.Renewal_Date__c = map_carrierKeyRenewalDate.get('dca');
								}
							}

							lst_tadaCarrierLineItems.add(objCOTemp);

							/**Tada Carrier Order "Benefit Type" handling code */
							String strBenefitType = 'Flexible Spending Account - Dependent Care';
							if (string.isBlank(objcarrierOrder.Benefit_Types__c)) {
								objcarrierOrder.Benefit_Types__c = strBenefitType;
							} else if (string.isNotBlank(objcarrierOrder.Benefit_Types__c) && objcarrierOrder.Benefit_Types__c.indexOf(strBenefitType) < 0) {
								objcarrierOrder.Benefit_Types__c = objcarrierOrder.Benefit_Types__c + ';' + strBenefitType;
							}
						}

						if ((administrators != null && administrators.commuter != null) || map_carrierKeyRenewalDate.containsKey('commuter')) {
							lst_tadaCarrierLineItems.add(createCarrierOrderLineItemsForTaDa('commuter', (administrators != null && administrators.commuter != null ? administrators.commuter : '')));

							/**Tada Carrier Order "Benefit Type" handling code */
							String strBenefitType = Utils.humanize('commuter');
							if (string.isBlank(objcarrierOrder.Benefit_Types__c)) {
								objcarrierOrder.Benefit_Types__c = strBenefitType;
							} else if (string.isNotBlank(objcarrierOrder.Benefit_Types__c) && objcarrierOrder.Benefit_Types__c.indexOf(strBenefitType) < 0) {
								objcarrierOrder.Benefit_Types__c = objcarrierOrder.Benefit_Types__c + ';' + strBenefitType;
							}
						}

						if (dt_minRenewalDate != null) {
							objcarrierOrder.Renewal_Date__c = dt_minRenewalDate;
						}

						if (lst_tadaCarrierLineItems.size() > 0) {
							lst_toInsertCarrierOrder.add(objcarrierOrder);
							map_boIdCarrierOrderList.put(objBO.Id, lst_tadaCarrierLineItems);
							set_IsTadaBOId.add(objBO.Id);
						}
					}
				}
			}

			// following code is upserting the Carrier Order records and then inserting the Line Item recods for the COs
			if (lst_toInsertCarrierOrder.size() > 0) {
				try {
					upsert lst_toInsertCarrierOrder;
				} catch (exception ex) {
					ExceptionLogUtil.logException('CarrierOrderHekperFunctions', 'syncTadaCarrierOrderRecordsAndLineItem', ex.getMessage(), 'High');
				}

				list<Carrier_Order_Line_Item__c> lst_lineItemTemp = new List<Carrier_Order_Line_Item__c>();
				for (Carrier_Order__c objCO : lst_toInsertCarrierOrder) {
					if (map_boIdCarrierOrderList.containsKey(objCO.Benefit_Order__c)) {
						for (Carrier_Order_Line_Item__c objLineItem : map_boIdCarrierOrderList.get(objCO.Benefit_Order__c)) {
							objLineItem.Carrier_Order__c = objCO.Id;
							lst_lineItemTemp.add(objLineItem);
						}
					}
				}

				if (lst_lineItemTemp.size() > 0) {
					list_CarrierOrderLineItemToUpsert.addAll(lst_lineItemTemp);
				}
			}
		}
	}

	private HI_Carrier_Information__c setProcessingState(String ProcessingState, String message, HI_Carrier_Information__c carrierInfo) {
		carrierInfo.Processing_State__c = ProcessingState;
		carrierInfo.Message__c = message;
		carrierInfo.Last_Processed__c = System.now();
		return carrierInfo;
	}

	private Carrier_Order_Line_Item__c createCarrierOrderLineItemsForTaDa(String strTaDaType, String strAdministratorsValue) {
		Carrier_Order_Line_Item__c objLineItem = new Carrier_Order_Line_Item__c();
		objLineItem.TADA_TPA__c = strAdministratorsValue;
		string strBenefitVal;
		if (string.isNotBlank(strTaDaType)) {
			if (strTaDaType.equalsIgnoreCase('hsa'))
				strBenefitVal = CarrierOrderUtil.TADA_BEN_TYPE_HSA;
			else if (strTaDaType.equalsIgnoreCase('fsa'))
				strBenefitVal = CarrierOrderUtil.TADA_BEN_TYPE_FSA_MEDICAL;
			else if (strTaDaType.equalsIgnoreCase('dca'))
				strBenefitVal = CarrierOrderUtil.TADA_BEN_TYPE_FSA_DEPENDENT_CARE;
			else if (strTaDaType.equalsIgnoreCase('commuter'))
				strBenefitVal = CarrierOrderUtil.TADA_BEN_TYPE_COMMUTER;
		}
		objLineItem.Benefit_Types__c = strBenefitVal;
		return objLineItem;
	}

	static set<string> set_strHICarrierInformationIds = new Set<string>();
	//<<<<<<<<<<<<<<<<<<<<<<<<<Carrier Order creation logic for "Benefits BOR" type  ==============END=================

	//>>>>>>>>>>>>>>>>>>>>>>>>Carrier Order creation logic for "New Plan, Renewal, Benefits Change"  type  ==============START=================
	/*following method gets called from "OpportunityTriggerHelper" */
	public void createCarrierOrdersAgainstBO(List<Benefit_Order__c> newBenefitOrders, Map<Id, Benefit_Order__c> oldBenefitOrderMap, map<id, Opportunity> opportunityMap) {
		Set<String> set_EarlySubmissionRequired = new Set<String>();
		Map<Id, Id> map_BOIdVSOppId = new Map<Id, Id>();
		Map<Id, QA_Sheet__c> map_OppIdVSQASheet = new Map<Id, QA_Sheet__c>();
		for (Benefit_Order__c boObj : newBenefitOrders) {
			map_BOIdVSOppId.put(boObj.Id, boObj.Opportunity__c);
		}

		for (QA_Sheet__c objQA : [
			SELECT
				Id,
				Opportunity__c,
				Opportunity__r.AccountId,
				Opportunity__r.Account.Name,
				Renewing_TAdAs__c,
				Subject_to_Federal_or_State_Cobra__c,
				(
					SELECT Id, Benefits_selected_Carrier__c, Early_Submission_Required__c
					FROM QA_Lines_Of_Coverage_del__r
				)
			FROM QA_Sheet__c
			WHERE Opportunity__c IN :opportunityMap.keySet()
		]) {
			if (!objQA.QA_Lines_Of_Coverage_del__r.isEmpty()) {
				for (QA_Lines_Of_Coverage__c objQALOC : objQA.QA_Lines_Of_Coverage_del__r) {
					if (objQALOC.Early_Submission_Required__c)
						set_EarlySubmissionRequired.add(objQA.Opportunity__c + '-' + objQALOC.Benefits_selected_Carrier__c);
				}
			}
			map_OppIdVSQASheet.put(objQA.Opportunity__c, objQA);
		}
		Map<Id, Benefit_Order__c> map_OppIdToBO = new Map<Id, Benefit_Order__c>();
		Set<String> set_BTIds = new Set<String>();
		Map<Id, List<Policy__c>> map_OppIdToPolicy = new Map<Id, List<Policy__c>>();
		List<Carrier_Order__c> list_COsToInsert = new List<Carrier_Order__c>();

		if (newBenefitOrders == null || newBenefitOrders.isEmpty()) {
			return;
		}

		Id idBORecType = newBenefitOrders[0].RecordTypeId;
		String idCORecType = null;
		if (BENEFIT_ORDER_RT_NEW_PLAN == idBORecType) {
			idCORecType = CARRIER_ORDER_NEW_PLAN_RT;
		} else if (BENEFIT_ORDER_RT_CHANGE == idBORecType) {
			idCORecType = CARRIER_ORDER_CHANGE_RT;
		} else if (BENEFIT_ORDER_RT_RENEWAL == idBORecType) {
			idCORecType = CARRIER_ORDER_RENEWAL_RT;
		} else if (BENEFIT_ORDER_BOR_RT != idBORecType) {
			return;
		}

		Map<Id, Id> map_ChildToParentBO = new Map<Id, Id>();
		map_BOIdRec.putAll(newBenefitOrders);
		for (Benefit_Order__c objBO : newBenefitOrders) {
			//Lirik- Migration for BOR to BO -- Start ---
			if (objBO.recordTypeId == BENEFIT_ORDER_BOR_RT) {
				if (String.isNotBlank(objBO.BoR_Id__c)) {
					set_BTIds.add(objBO.BoR_Id__c);
				}
			} else {
				//Lirik- Migration for BOR to BO -- End ---
				// SJay - 09/23/2020 - Added null check for Opportunity on a Benefit Order.
				if (objBO.Opportunity__c != null)
					map_OppIdToBO.put(objBO.Opportunity__c, objBO);
				if (objBO.Parent_Benefit_Order__c != null) {
					map_ChildToParentBO.put(objBO.Id, objBO.Parent_Benefit_Order__c);
				}
			}
		}
		//Lirik- Migration for BOR to BO -- Start ---
		if (!set_BTIds.isEmpty()) {
			List<HI_Carrier_Information__c> list_HICarrierInfos = new List<HI_Carrier_Information__c>();
			for (HI_Carrier_Information__c objHICarrier : [SELECT Id FROM HI_Carrier_Information__c WHERE BOR_Transfer_Id__c IN :set_BTIds]) {
				if (!set_strHICarrierInformationIds.contains(objHICarrier.Id)) {
					set_strHICarrierInformationIds.add(objHICarrier.Id);
					list_HICarrierInfos.add(objHICarrier);
				}
			}

			if (list_HICarrierInfos.size() > 0) {
				HICarrierInformationTriggerHelper.isBOInsert = true;
				update list_HICarrierInfos;
			}
		}
		//Lirik- Migration for BOR to BO -- End ---
		if (!map_OppIdToBO.isEmpty()) {
			//DS:[06-11-2019] Solving 101 Query
			Set<String> set_QueueNames = new Set<String>{ 'Carrier Implementation Queue' };
			Map<String, Id> map_QueueNameToId = GlobalQueryHelper.getNameQueueMap(set_QueueNames);
			Map<Id, Map<String, Carrier_Order__c>> map_TadaCOPerOpp = new Map<Id, Map<String, Carrier_Order__c>>();
			Set<String> set_COUniqueIdsToInsert = new Set<String>();
			Map<Id, String> map_CarriersIdName = new Map<Id, String>();

			for (Policy__c objPolicy : [
				SELECT Id, Carrier__c, Carrier__r.Name, Opportunity__c, Opportunity__r.Account.Name, Carrier_Order__c, Carrier__r.Composite_Rated__c, Benefit_Type__c
				FROM Policy__c
				WHERE Is_Selected__c = TRUE AND Opportunity__c != NULL AND Carrier__c != NULL AND Opportunity__c IN :map_OppIdToBO.keySet()
			]) {
				List<Policy__c> list_PoliciesPerOpp;
				if (map_OppIdToPolicy.containsKey(objPolicy.Opportunity__c)) {
					list_PoliciesPerOpp = map_OppIdToPolicy.get(objPolicy.Opportunity__c);
				} else {
					list_PoliciesPerOpp = new List<Policy__c>();
				}
				list_PoliciesPerOpp.add(objPolicy);
				map_OppIdToPolicy.put(objPolicy.Opportunity__c, list_PoliciesPerOpp);
				map_CarriersIdName.put(objPolicy.Carrier__c, objPolicy.Carrier__r.Name);
			}
			map<String, Carrier_Order__c> map_TerminatedCarriers = new Map<String, Carrier_Order__c>();
			map<Id, Policy__c> map_MedicalPolicies = new Map<Id, Policy__c>();

			if (map_OppIdToPolicy.size() > 0) {
				String BenOrderId = '';
				String BenOrderName = '';
				// String terminatedCOName = '';
				String BenOrderRecTypeId = '';
				String BenOrderOwnerId = '';

				for (Id idOpp : map_OppIdToPolicy.keySet()) {
					Map<String, Carrier_Order__c> map_COPerOrderType;
					if (map_TadaCOPerOpp != null && map_TadaCOPerOpp.containsKey(idOpp)) {
						map_COPerOrderType = map_TadaCOPerOpp.get(idOpp);
					}
					if (map_COPerOrderType == null) {
						map_COPerOrderType = new Map<String, Carrier_Order__c>();
					}
					if (map_OppIdToBO.containsKey(idOpp)) {
						for (Policy__c objPolicy : map_OppIdToPolicy.get(idOpp)) {
							if(objPolicy.Benefit_Type__c == CarrierOrderUtil.TADA_BEN_TYPE_HSA &&
								map_OppIdVSQASheet.get(map_BOIdVSOppId.get(map_OppIdToBO.get(idOpp).Id)).Renewing_TAdAs__c.contains(CarrierOrderUtil.TADA_BEN_TYPE_HSA)){
								continue;
							}
							if (objPolicy.Benefit_Type__c == CarrierOrderUtil.POLICY_BENEFIT_TYPE_MEDICAL) {
								map_MedicalPolicies.put(objPolicy.Carrier__c, objPolicy);
							}

							Carrier_Order__c objCO = new Carrier_Order__c(
								Benefit_Order__c = map_OppIdToBO.get(idOpp).Id,
								Carrier__c = objPolicy.Carrier__c,
								Type__c = CarrierOrderUtil.TYPE_CARRIER_ADDED,
								Order_Type__c = ''
							);
							objCO.Is_Multi_EIN__c = map_OppIdToBO.get(idOpp).Is_Multi_EIN__c;
							objCO.Unique_id__c = objCO.Benefit_Order__c + '-' + objCO.Carrier__c;

							String coName = objPolicy.Opportunity__r.Account.Name + ' ' + objPolicy.Carrier__r.Name + ' Order';
							String coNameT = objPolicy.Carrier__r.Name;

							if (coName.length() > 80) {
								objCO.Name = objPolicy.Carrier__r.Name + ' Order';
							} else {
								objCO.Name = coName;
							}

							if (idCORecType != null)
								objCO.RecordTypeId = idCORecType;

							objCO.Benefit_Type_Details__c = '';
							//BY:PR, Date: oct-15-2020, Desc: following code is calling method that handles "special enrollment" deadline calculations
							handleSpecialEnrollmentDates(objPolicy.Benefit_Type__c, map_OppIdToBO.get(idOpp).Special_Enrollment__c, dtSpecial_Enrollment_Deadline_Date, objCO, objCO.RecordTypeId);

							String strCOOrderType = '';
							if (!map_QueueNameToId.isEmpty())
								objCO.OwnerId = map_QueueNameToId.get('Carrier Implementation Queue');

							if (
								!set_COUniqueIdsToInsert.contains(objCO.Unique_Id__c) &&
								NewTransitionToFulfillmentController.CO_order_type_Map != null &&
								NewTransitionToFulfillmentController.CO_order_type_Map.containsKey(objCO.Carrier__c)
							) {
								for (String ot : NewTransitionToFulfillmentController.CO_order_type_Map.get(objCO.Carrier__c)) {
									if (String.isblank(objCO.Benefit_Type_Details__c)) {
										objCO.Benefit_Type_Details__c = ot;
										strCOOrderType = ot;
									} else {
										objCO.Benefit_Type_Details__c += '\n' + ot;
										strCOOrderType += ';' + ot;
									}
								}
								objCO.Order_Type__c = strCOOrderType;
								objCO.Order_Assignment__c = calculateOrderAssignmentForCO(objCO);

								list_COsToInsert.add(objCO);
								set_COUniqueIdsToInsert.add(objCO.Unique_Id__c);
							} else {
								String strCarrierUniqueKey = objCO.Carrier__c;
								if ((objPolicy.Benefit_Type__c == CarrierOrderUtil.TADA_BEN_TYPE_FSA_DEPENDENT_CARE || objPolicy.Benefit_Type__c == CarrierOrderUtil.TADA_BEN_TYPE_FSA_MEDICAL)) {
									strCarrierUniqueKey = strCarrierUniqueKey + '-InitialTadaSetup';
								}
								Carrier_Order__c objTadaCO = new Carrier_Order__c();
								if (map_COPerOrderType != null && map_COPerOrderType.containsKey(strCarrierUniqueKey)) {
									objTadaCO = map_COPerOrderType.get(strCarrierUniqueKey);
								} else {
									objTadaCO = new Carrier_Order__c(
										Benefit_Order__c = map_OppIdToBO.get(idOpp).Id,
										Carrier__c = objPolicy.Carrier__c,
										Type__c = CarrierOrderUtil.TYPE_CARRIER_ADDED,
										Order_Type__c = '',
										RecordTypeId = idCORecType
									);
									objTadaCO.Is_Multi_EIN__c = map_OppIdToBO.get(idOpp).Is_Multi_EIN__c;
									objTadaCO.Unique_id__c = objCO.Benefit_Order__c + '-' + objCO.Carrier__c;
									if ((objPolicy.Benefit_Type__c == CarrierOrderUtil.TADA_BEN_TYPE_FSA_DEPENDENT_CARE  || objPolicy.Benefit_Type__c == CarrierOrderUtil.TADA_BEN_TYPE_FSA_MEDICAL)) {
										objTadaCO.Order_Type__c = CarrierOrderUtil.ORDER_TYPE_TADA_NO_PRE_OE;
									} else if ((objPolicy.Benefit_Type__c == CarrierOrderUtil.TADA_BEN_TYPE_HSA|| objPolicy.Benefit_Type__c == CarrierOrderUtil.TADA_BEN_TYPE_COMMUTER)) {
										objTadaCO.Order_Type__c = CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP;
									}
									objTadaCO.Order_Assignment__c = calculateOrderAssignmentForCO(objTadaCO);
									if (!map_QueueNameToId.isEmpty()) {
										objTadaCO.OwnerId = map_QueueNameToId.get('Carrier Implementation Queue');
									}
									String strCarrierOrderName = opportunityMap.values()[0].Account.Name + ' ' + objPolicy.Carrier__r.Name + ' Order';

									if (String.isNotBlank(strCarrierOrderName) && strCarrierOrderName.length() > 80) {
										strCarrierOrderName = objPolicy.Carrier__r.Name + ' Order';
									}
									objTadaCO.Name = strCarrierOrderName;
									if (objTadaCO.Order_Type__c == CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP) {
										objTadaCO.Unique_Id__c = objTadaCO.Unique_Id__c + '-InitialTadaSetup';
									}
								}
								objTadaCO.Benefit_Types__c = String.isBlank(objTadaCO.Benefit_Types__c)
									? objPolicy.Benefit_Type__c
									: objTadaCO.Benefit_Types__c.indexOf(objPolicy.Benefit_Type__c) == -1 ? objTadaCO.Benefit_Types__c + ';' + objPolicy.Benefit_Type__c : objTadaCO.Benefit_Types__c;

								if (String.isBlank(objTadaCO.Benefit_Type_Details__c) || !objTadaCO.Benefit_Type_Details__c.containsIgnoreCase(objPolicy.Benefit_Type__c)) {
									objTadaCO.Benefit_Type_Details__c = String.isBlank(objTadaCO.Benefit_Type_Details__c)
										? objPolicy.Benefit_Type__c
										: objTadaCO.Benefit_Type_Details__c.indexOf(objPolicy.Benefit_Type__c) == -1
												? objTadaCO.Benefit_Type_Details__c + '\n' + objPolicy.Benefit_Type__c
												: objTadaCO.Benefit_Type_Details__c;
								}
								
								map_COPerOrderType.put(objTadaCO.Unique_Id__c, objTadaCO);
							}
							// for terminate Plan
							BenOrderId = map_OppIdToBO.get(idOpp).Id;
							BenOrderName = objPolicy.Opportunity__r.Account.Name + ' ' + objPolicy.Carrier__r.Name + ' Order';
							// terminatedCOName = objPolicy.Opportunity__r.Account.Name + ' ' + '{0}' + ' Terminated Order';
							BenOrderRecTypeId = idCORecType;
							BenOrderOwnerId = map_QueueNameToId.get('Carrier Implementation Queue');
						}
					}

					map_TadaCOPerOpp.put(idOpp, map_COPerOrderType);
				}
			}

			if (!map_TadaCOPerOpp.isEmpty()) {
				for (Id idOpp : map_TadaCOPerOpp.keySet()) {
					Map<String, Carrier_Order__c> map_COPerOrderType = map_TadaCOPerOpp.get(idOpp);
					if (!map_COPerOrderType.isEmpty()) {
						for (Carrier_Order__c objCarrierOrder : map_COPerOrderType.values()) {
							if (!set_COUniqueIdsToInsert.contains(objCarrierOrder.Unique_Id__c)) {
								list_COsToInsert.add(objCarrierOrder);
							}
							set_COUniqueIdsToInsert.add(objCarrierOrder.Unique_Id__c);
						}
					}
				}
			}

			if (list_COsToInsert.size() > 0) {
				map<Id, list<Carrier_Order__c>> map_ParentCOs = new Map<Id, list<Carrier_Order__c>>();
				if (map_ChildToParentBO != null && map_ChildToParentBO.size() > 0) {
					for (Carrier_Order__c co : [SELECT id, Benefit_Order__c, Carrier__c FROM Carrier_Order__c WHERE Benefit_Order__c IN :map_ChildToParentBO.values()]) {
						if (map_ParentCOs.containsKey(co.Benefit_Order__c)) {
							map_ParentCOs.get(co.Benefit_Order__c).add(co);
						} else {
							map_ParentCOs.put(co.Benefit_Order__c, new List<Carrier_Order__c>{ co });
						}
					}
				}

				//Assigning Implementation Stage As Ready For Qualification for order typer other than Termination Order & Tada: Pre OE setup
				for (Carrier_Order__c objCO : list_COsToInsert) {
					List<String> combinationType = new List<String>();
					if (objCO.Order_Type__c != null)
						combinationType = objCO.Order_Type__c.split(',');

					if (objCO.Order_Type__c != CarrierOrderUtil.ORDER_TYPE_TERMINATED_ORDER && objCO.Order_Type__c != null) {
						objCO.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_OE_PREP;
						if (
							set_EarlySubmissionRequired != null &&
							map_BOIdVSOppId != null &&
							!set_EarlySubmissionRequired.isEmpty() &&
							!map_BOIdVSOppId.isEmpty() &&
							objCO.Carrier__c != null &&
							objCO.Benefit_Order__c != null &&
							map_BOIdVSOppId.containsKey(objCO.Benefit_Order__c) &&
							set_EarlySubmissionRequired.contains(map_BOIdVSOppId.get(objCO.Benefit_Order__c) + '-' + objCO.Carrier__c)
						) {
							objCO.Implementation_Stage__c = CarrierOrderUtil.IMPLEMENTATION_STAGE_READY_FOR_EARLY_SUBMISSION;
						}
						if (objCO.Carrier__c != null && objCO.Benefit_Order__c != null && objCO.Order_Type__c == CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP) {
							objCO.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP;
						}
					}

					if (map_ParentCOs.size() > 0 && objCO.Benefit_Order__c != null && map_ChildToParentBO.containsKey(objCO.Benefit_Order__c)) {
						for (Carrier_Order__c objParentCO : map_ParentCOs.get(map_ChildToParentBO.get(objCO.Benefit_Order__c))) {
							if (objParentCO.Carrier__c == objCO.Carrier__c) {
								objCO.Parent_Carrier_Order__c = objParentCO.Id;
								break;
							}
						}
					}
				}

				Set<Carrier_Order__c> set_BasicCarrierOrder = new Set<Carrier_Order__c>();
				if (!list_COsToInsert.isEmpty()) {
					for (Carrier_Order__c co : list_COsToInsert) {
						if (
							co.benefit_order__c != null &&
							map_BOIdVSOppId.containsKey(co.benefit_order__c) &&
							map_OppIdVSQASheet.containsKey(map_BOIdVSOppId.get(co.benefit_order__c)) &&
							map_OppIdVSQASheet.get(map_BOIdVSOppId.get(co.benefit_order__c)).Subject_to_Federal_or_State_Cobra__c == SUBJECT_TO_FEDERAL
						) {
							if (co.Carrier__c != null && co.Carrier__c != Label.BASIC_Carrier) {
								Carrier_Order__c objBasicCarrierOrder;
								if (co.RecordTypeId == CARRIER_ORDER_RENEWAL_RT) {
									objBasicCarrierOrder = new Carrier_Order__c();
									objBasicCarrierOrder.Order_Type__c = CarrierOrderUtil.ORDER_TYPE_SAME_CARRIER_NO_PLAN_GROUP_LEVEL_CHANGES;
									objBasicCarrierOrder.RecordTypeId = CARRIER_ORDER_RENEWAL_RT;
									if (map_OppIdVSQASheet.get(map_BOIdVSOppId.get(co.benefit_order__c)).Opportunity__r.AccountId != null) {
										objBasicCarrierOrder.name = map_OppIdVSQASheet.get(map_BOIdVSOppId.get(co.benefit_order__c)).Opportunity__r.Account.Name + ' ' + CARRIER_BASIC_PACIFIC_RENEWAL;
									} else {
										objBasicCarrierOrder.name = CARRIER_BASIC_PACIFIC_RENEWAL;
									}
								}

								if (co.RecordTypeId == CARRIER_ORDER_NEW_PLAN_RT) {
									objBasicCarrierOrder = new Carrier_Order__c();
									objBasicCarrierOrder.Order_Type__c = CarrierOrderUtil.ORDER_TYPE_NEW_TO_GUSTO;
									objBasicCarrierOrder.RecordTypeId = CARRIER_ORDER_NEW_PLAN_RT;
									if (map_OppIdVSQASheet.get(map_BOIdVSOppId.get(co.benefit_order__c)).Opportunity__r.AccountId != null) {
										objBasicCarrierOrder.name = map_OppIdVSQASheet.get(map_BOIdVSOppId.get(co.benefit_order__c)).Opportunity__r.Account.Name + ' ' + CARRIER_BASIC_PACIFIC_SETUP;
									} else {
										objBasicCarrierOrder.name = CARRIER_BASIC_PACIFIC_SETUP;
									}
								}

								if (objBasicCarrierOrder != null) {
									if (objBasicCarrierOrder.Name.length() > 80) {
										objBasicCarrierOrder.Name = objBasicCarrierOrder.Name.subString(0, 80);
									}
									objBasicCarrierOrder.benefit_order__c = co.benefit_order__c;
									objBasicCarrierOrder.Benefit_Types__c = TransitiontoFulfilmentUtil.CARRIER_NAME_BASIC;
									objBasicCarrierOrder.Carrier__c = Label.BASIC_Carrier;
									objBasicCarrierOrder.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_OE_PREP;
									set_BasicCarrierOrder.add(objBasicCarrierOrder);
								}
							}
						}
					}
				}

				if (!set_BasicCarrierOrder.isEmpty()) {
					list_COsToInsert.addAll(set_BasicCarrierOrder);
				}

				if (Test.isRunningTest())
					BenefitOrderHelper.skipTrigger = true;
				insert list_COsToInsert;
				if (Test.isRunningTest())
					BenefitOrderHelper.skipTrigger = false;
			}

			Id id_childCO, id_parentCO;
			Map<Id, Carrier_Order__c> map_CarrierOrdersToUpdate = terminatedCOReparenting(list_COsToInsert, map_TerminatedCarriers, id_childCO, id_parentCO);

			if (id_parentCO != null && id_childCO != null && map_CarrierOrdersToUpdate.containsKey(id_childCO)) {
				map_CarrierOrdersToUpdate.get(id_childCO).Parent__c = id_parentCO;
			}

			if (!map_CarrierOrdersToUpdate.isEmpty()) {
				boolean blnCOSkipTrigger = CarrierOrderTriggerHelper.skipTrigger;
				CarrierOrderTriggerHelper.skipTrigger = true;
				update map_CarrierOrdersToUpdate.values();
				CarrierOrderTriggerHelper.skipTrigger = blnCOSkipTrigger;
			}
		}
	}

	//BY:PR, Date:Oct-15-2020, Desc: following code based on filters handles "Special Enrollment" deadline calculations
	public static void handleSpecialEnrollmentDates(string strBenefitType, boolean blnIsSpecialEnrollment, date dtDeadline, Carrier_Order__c objCarrierOrder, Id IdRecordType) {
		//BY:PR, Date
		if (string.isNotBlank(strBenefitType) && strBenefitType.equalsIgnoreCase('Medical') && blnIsSpecialEnrollment == true && dtDeadline != null && dtDeadline.year() == System.today().year()) {
			objCarrierOrder.Submission_Deadline__c = dtDeadline;
			if (IdRecordType != null && IdRecordType != CarrierOrderUtil.RECTYPE_NEW_PLAN) {
				objCarrierOrder.Group_Submission_Date__c = dtDeadline;
				objCarrierOrder.Member_Submission_Date__c = dtDeadline;
			}
		}
	}

	/* private static list<Carrier_Order__c> getTerminatedCO(String boId, String coName, String RecTypeId, String ownerId, map<String, Carrier_Order__c> terminatedCarrierMap) {
		list<Carrier_Order__c> coList = new List<Carrier_Order__c>();
		for (Policy__c co : NewTransitionToFulfillmentController.terminatedCarrierList) {
			if (co.Carrier__c == null) {
				continue;
			}
			// to create unique terminated Carrier Order
			// [SM 07/10/2019] : Changing Map key to just 'Carrier Id' instead of 'Carrier Id + Policy Name' to prevent duplication of Termination Orders
			if (terminatedCarrierMap.containsKey(co.Carrier__c)) {
				if (String.isNotBlank(co.Benefit_Type__c))
					terminatedCarrierMap.get(co.Carrier__c).Benefit_Types__c += ';' + co.Benefit_Type__c;

				continue;
			}

			Carrier_Order__c coRec = new Carrier_Order__c(Benefit_Order__c = boId, Carrier__c = co.Carrier__c, Unique_Id__c = boId + '-' + co.Carrier__c + '-Termination');
			String terCoName = String.format(coName, new List<String>{ co.Policy_Number__c });
			//DS[21-05-2020]:- add check for 80 charcter limit
			if (String.isNotBlank(terCoName) && terCoName.length() > 80) {
				terCoName = co.Policy_Number__c + ' Terminated Order';
			}
			coRec.Name = terCoName;
			coRec.Type__c = 'Carrier Removed';
			coRec.RecordTypeId = RecTypeId;
			coRec.Order_Type__c = 'Terminated Order';
			coRec.Order_Assignment__c = 'Terminated Order';
			coRec.OwnerId = ownerId;
			coRec.New_Carrier_is__c = co.Name;
			coRec.Benefit_Types__c = co.Benefit_Type__c;
			coRec.Is_Multi_EIN__c = map_BOIdRec.get(boId).Is_Multi_EIN__c;
			//BY:PR, Date: oct-15-2020, Desc: following code is calling method that handles "special enrollment" deadline calculations
			handleSpecialEnrollmentDates(co.Benefit_Type__c, map_BOIdRec.get(boId).Special_Enrollment__c, dtSpecial_Enrollment_Deadline_Date, coRec, coRec.RecordTypeId);

			coList.add(coRec);
			terminatedCarrierMap.put(co.Carrier__c, coRec);
		}
		return coList;
	} */

	//<<<<<<<<<<<<<<<<<<<<<<<<<Carrier Order creation logic for "New Plan, Renewal, Benefits Change"  type  ==============END=================

	//>>>>>>>>>>>>>>>>>>>>>>>>>logic for Order Assignment "New Plan, Renewal, Benefits Change"  type  ==============Start=================
	public String calculateOrderAssignmentForCO(Carrier_Order__c objCarrierOrder) {
		//Order Assignment Should be calacuate on the basis of the order precedent.
		String strOrderAssignment = '';
		Integer intTemp = 10;
		if (String.isNotBlank(objCarrierOrder.Order_Type__c)) {
			List<String> lst_OrderType = objCarrierOrder.Order_Type__c.split(';');
			if (lst_OrderType.size() == 1) {
				// Order type selected is only one
				strOrderAssignment = objCarrierOrder.Order_Type__c;
			} else {
				// for multiple order type
				for (String strOT : lst_OrderType) {
					//check for new to gusto, tada nd terminated, if present order assignment should be that
					if (
						strOT.equalsIgnoreCase(CarrierOrderUtil.ORDER_TYPE_NEW_TO_GUSTO) ||
						strOT.equalsIgnoreCase(CarrierOrderUtil.ORDER_TYPE_TADA_NO_PRE_OE) ||
						strOT.equalsIgnoreCase(CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP) ||
						strOT.equalsIgnoreCase(CarrierOrderUtil.ORDER_TYPE_TERMINATED_ORDER)
					) {
						strOrderAssignment = strOT;
						break;
					}
					// check for the order type precedents
					if (map_OrderTypePrecedents.containsKey(strOT.toLowerCase()) && intTemp > map_OrderTypePrecedents.get(strOT.toLowerCase())) {
						intTemp = map_OrderTypePrecedents.get(strOT.toLowerCase());
						strOrderAssignment = strOT;
					}
				}
			}
		}
		return strOrderAssignment;
	}
	//<<<<<<<<<<<<<<<<<<<<<<<<<logic for Order Assignment "New Plan, Renewal, Benefits Change"  type  ==============END=================
	/**BY: DS,
    Desc: This method is called from "UserTRiggerHelper.cls" after update event. this method is querying all the "Benefit transfer" CO records and then
        we are reassigning the record to the "Initial Owner" who is back in office. */
	public static void reAssignCOtoInitialFacilitator1OnReturnToOffice(set<string> set_ReturnToOfficeUserIds) {
		if (set_ReturnToOfficeUserIds == null || set_ReturnToOfficeUserIds.size() == 0) {
			return;
		}

		List<Carrier_Order__c> list_ToReAssignCOs = new List<Carrier_Order__c>();

		for (Carrier_Order__c objCO : [
			SELECT Id, OwnerId, Initial_Owner__c
			FROM Carrier_Order__c
			WHERE
				Initial_Owner__c IN :set_ReturnToOfficeUserIds
				AND OwnerId NOT IN :set_ReturnToOfficeUserIds
				AND recordTypeId = :CARRIER_ORDER_BOR_RT
				AND TAdA__c = FALSE
				AND Implementation_Stage__c NOT IN :Utils.setCOExclude
		]) {
			if (objCO.OwnerId != objCO.Initial_Owner__c) {
				objCO.OwnerId = objCO.Initial_Owner__c;
				list_ToReAssignCOs.add(objCO);
			}
		}

		if (list_ToReAssignCOs.size() > 0) {
			try {
				update list_ToReAssignCOs;
			} catch (exception ex) {
				ExceptionLogUtil.logException('CarrierOrderHelperFunctions', 'reAssignCOtoInitialFacilitator1OnReturnToOffice', ex.getMessage(), 'High');
			}
		}
	}

	public static void updateBOTadaNonTadaFieldValue(Set<Id> set_BOIds) {
		Map<string, Integer> map_TadaBOIdCount = new Map<string, Integer>();
		Map<string, Integer> map_NONTadaBOIdCount = new Map<string, Integer>();
		Set<String> set_COExclude = UtilitiesFactory.set_FWExcludeCOBO;
		Integer intCount = 0;
		list<Carrier_Order__c> list_CarrierOrder = [
			SELECT Id, Benefit_Order__c, Carrier__c, Carrier__r.Partner_Type__c, TAdA__c
			FROM Carrier_Order__c
			WHERE Benefit_Order__c IN :set_BOIds AND Implementation_Stage__c NOT IN :set_COExclude
		];
		for (Carrier_Order__c objCarrier : list_CarrierOrder) {
			if (objCarrier.Carrier__r.Partner_Type__c == CarrierOrderUtil.PARTNER_TYPE_TADA) {
				if (map_TadaBOIdCount.containsKey(objCarrier.Benefit_Order__c)) {
					intCount = map_TadaBOIdCount.get(objCarrier.Benefit_Order__c);
					intCount = intCount + 1;
					map_TadaBOIdCount.put(objCarrier.Benefit_Order__c, intCount);
				} else {
					map_TadaBOIdCount.put(objCarrier.Benefit_Order__c, 1);
				}
			} else {
				if (map_NONTadaBOIdCount.containsKey(objCarrier.Benefit_Order__c)) {
					intCount = map_NONTadaBOIdCount.get(objCarrier.Benefit_Order__c);
					intCount = intCount + 1;
					map_NONTadaBOIdCount.put(objCarrier.Benefit_Order__c, intCount);
				} else {
					map_NONTadaBOIdCount.put(objCarrier.Benefit_Order__c, 1);
				}
			}
		}

		Map<Id, Benefit_Order__c> map_BOs = new Map<Id, Benefit_Order__c>();
		List<Benefit_Order__c> list_BenefitOrder = new List<Benefit_Order__c>();
		for (Id boId : set_BOIds) {
			Benefit_Order__c objBO = new Benefit_Order__c(Id = boId);
			if (map_TadaBOIdCount.containsKey(boId)) {
				objBO.No_Of_TADA_Carrier_Order__c = map_TadaBOIdCount.get(boId);
			} else {
				objBO.No_Of_TADA_Carrier_Order__c = 0;
			}

			if (map_NONTadaBOIdCount.containsKey(boId)) {
				objBO.No_Of_Non_TADA_Carrier_Order__c = map_NONTadaBOIdCount.get(boId);
			} else {
				objBO.No_Of_Non_TADA_Carrier_Order__c = 0;
			}
			list_BenefitOrder.add(objBO);
			map_BOs.put(objBO.Id, objBO);
		}

		if (list_BenefitOrder.size() > 0) {
			BenefitOrderHelper.skipTrigger = true;
			if (TicketTriggerHelper.blnUpdateBOStatusAsFulfilled) {
				Boolean blnBOStatusChange = TicketTriggerHelper.setBOStatusAsFulfilled(map_BOs);
				TicketTriggerHelper.blnUpdateBOStatusAsFulfilled = false;
				if (blnBOStatusChange) {
					BenefitOrderHelper.skipTrigger = false;
				}
			}

			update list_BenefitOrder;
			BenefitOrderHelper.skipTrigger = false;
		}
	}

	/**
	 * @author       Deepika Saini
	 * @description  update preceding CO of terminated co if old precedding CO is Canceld.
	 * @param        list of new Carrier orders values
	 * @return       N/A
	 **/
	public Map<Id, Carrier_Order__c> terminatedCOReparenting(List<Carrier_Order__c> list_COs, Map<String, Carrier_Order__c> map_TerminatedCarriers, Id id_childCO, Id id_parentCO) {
		Map<Id, Carrier_Order__c> map_CarrierOrdersToUpdateTemp = new Map<Id, Carrier_Order__c>();
		if (map_TerminatedCarriers.size() > 0) {
			Id idBO;
			for (Carrier_Order__c objTerminatedCO : map_TerminatedCarriers.values()) {
				idBO = objTerminatedCO.Benefit_Order__c;
				for (Carrier_Order__c objCO : list_COs) {
					if (objTerminatedCO.Parent__c == null) {
						if (objCO.Order_Type__c == CarrierOrderUtil.ORDER_TYPE_TADA_NO_PRE_OE) {
							id_childCO = objCO.Id;
						}
						if (objCO.Order_Type__c == CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP) {
							id_parentCO = objCO.Id;
						}
						if (objCO.Order_Type__c != CarrierOrderUtil.ORDER_TYPE_TERMINATED_ORDER) {
							if (!CarrierOrderTriggerHelper.map_TerminationCO.isEmpty() && CarrierOrderTriggerHelper.map_TerminationCO.containsKey(objTerminatedCO.Id)) {
								Carrier_Order__c objPreecedingCO = objCO;
								map_CarrierOrdersToUpdateTemp.put(objPreecedingCO.Id, objPreecedingCO);
							}
							objTerminatedCO.Parent__c = objCO.Id;
							map_CarrierOrdersToUpdateTemp.put(objTerminatedCO.Id, objTerminatedCO);
							break;
						}
					}

					if (
						objTerminatedCO.Parent__c != null &&
						objCO.Benefit_Order__c == objTerminatedCO.Benefit_Order__c &&
						objTerminatedCO.Benefit_Types__c == objCO.Benefit_Types__c &&
						objCO.Implementation_Stage__c != CarrierOrderUtil.STAGE_CANCELLED
					) {
						objTerminatedCO.Parent__c = objCO.Id;
						map_CarrierOrdersToUpdateTemp.put(objTerminatedCO.Id, objTerminatedCO);
						break;
					}
				}
			}
		}

		return map_CarrierOrdersToUpdateTemp;
	}
}