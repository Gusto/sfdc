/**
 * @description       Test class for HIBatchUtilMethods
 * @author            Nigam Goyal
 **/
@isTest
private class HIBatchUtilTest {
	/**
	 * @description Test HIFulfillmentEventBatch Query
	 * @author Nigam Goyal | 05-29-2024
	 **/
	@isTest
	static void testHIFulfillmentEventBatchQuery() {
		Map<String, HI_Configuration__mdt> map_HIConfigurations = HIBatchUtil.fetchHIConfigurations(HIFulfillmentEventBatch.BATCH_CLASS_NAME);
		String strQuery = '';
		if (map_HIConfigurations != null) {
			if (
				map_HIConfigurations.containsKey(HIFulfillmentEventBatch.FILTER_TYPE_BASE_QUERY) && String.isNotBlank(map_HIConfigurations.get(HIFulfillmentEventBatch.FILTER_TYPE_BASE_QUERY).Value__c)
			) {
				strQuery = map_HIConfigurations.get(HIFulfillmentEventBatch.FILTER_TYPE_BASE_QUERY).Value__c;
			}

			if (
				map_HIConfigurations.containsKey(HIFulfillmentEventBatch.FILTER_TYPE_WHERE_CLAUSE) &&
				String.isNotBlank(map_HIConfigurations.get(HIFulfillmentEventBatch.FILTER_TYPE_WHERE_CLAUSE).Value__c)
			) {
				strQuery +=
					' ' +
					HIBatchUtil.getHIBatchConfigWhereClause(
						map_HIConfigurations.get(HIFulfillmentEventBatch.FILTER_TYPE_WHERE_CLAUSE).Value__c,
						HIFulfillmentEventBatch.intMarkDeadAfterDays,
						HIFulfillmentEventBatch.intDeleteAfterDays
					);
			}

			if (map_HIConfigurations.containsKey(HIFulfillmentEventBatch.FILTER_TYPE_ORDER_BY) && String.isNotBlank(map_HIConfigurations.get(HIFulfillmentEventBatch.FILTER_TYPE_ORDER_BY).Value__c)) {
				strQuery += ' ' + map_HIConfigurations.get(HIFulfillmentEventBatch.FILTER_TYPE_ORDER_BY).Value__c;
			}
		}
		System.assertEquals(true, isValidSOQL(strQuery, System.now().addDays(-HIFulfillmentEventBatch.intMarkDeadAfterDays), System.now().addDays(-HIFulfillmentEventBatch.intDeleteAfterDays)), strQuery);
	}

	/**
	 * @description Test HIAasmEventsBatch Query
	 * @author Nigam Goyal | 05-29-2024
	 **/
	@isTest
	static void testHIAasmEventsBatchQuery() {
		Map<String, HI_Configuration__mdt> map_HIConfigurations = HIBatchUtil.fetchHIConfigurations(HIAasmEventsBatch.BATCH_CLASS_NAME);
		String strQuery = '';
		if (map_HIConfigurations != null) {
			if (map_HIConfigurations.containsKey(HIAasmEventsBatch.FILTER_TYPE_BASE_QUERY) && String.isNotBlank(map_HIConfigurations.get(HIAasmEventsBatch.FILTER_TYPE_BASE_QUERY).Value__c)) {
				strQuery = map_HIConfigurations.get(HIAasmEventsBatch.FILTER_TYPE_BASE_QUERY).Value__c;
			}

			if (map_HIConfigurations.containsKey(HIAasmEventsBatch.FILTER_TYPE_WHERE_CLAUSE) && String.isNotBlank(map_HIConfigurations.get(HIAasmEventsBatch.FILTER_TYPE_WHERE_CLAUSE).Value__c)) {
				strQuery +=
					' ' +
					HIBatchUtil.getHIBatchConfigWhereClause(
						map_HIConfigurations.get(HIAasmEventsBatch.FILTER_TYPE_WHERE_CLAUSE).Value__c,
						HIAasmEventsBatch.intMarkDeadAfterDays,
						HIAasmEventsBatch.intDeleteAfterDays
					);
			}

			if (map_HIConfigurations.containsKey(HIAasmEventsBatch.FILTER_TYPE_ORDER_BY) && String.isNotBlank(map_HIConfigurations.get(HIAasmEventsBatch.FILTER_TYPE_ORDER_BY).Value__c)) {
				strQuery += ' ' + map_HIConfigurations.get(HIAasmEventsBatch.FILTER_TYPE_ORDER_BY).Value__c;
			}
		}
		System.assertEquals(true, isValidSOQL(strQuery, System.now().addDays(-HIAasmEventsBatch.intMarkDeadAfterDays), System.now().addDays(-HIAasmEventsBatch.intDeleteAfterDays)), strQuery);
	}

	/**
	 * @description Test HIBenefitApplicationUserBatch Query
	 * @author Nigam Goyal | 05-29-2024
	 **/
	@isTest
	static void testHIBenefitApplicationUserBatchQuery() {
		Map<String, HI_Configuration__mdt> map_HIConfigurations = HIBatchUtil.fetchHIConfigurations(HIBenefitApplicationUserBatch.BATCH_CLASS_NAME);
		String strQuery = '';
		if (map_HIConfigurations != null) {
			if (
				map_HIConfigurations.containsKey(HIBenefitApplicationUserBatch.FILTER_TYPE_BASE_QUERY) &&
				String.isNotBlank(map_HIConfigurations.get(HIBenefitApplicationUserBatch.FILTER_TYPE_BASE_QUERY).Value__c)
			) {
				strQuery = map_HIConfigurations.get(HIBenefitApplicationUserBatch.FILTER_TYPE_BASE_QUERY).Value__c;
			}

			if (
				map_HIConfigurations.containsKey(HIBenefitApplicationUserBatch.FILTER_TYPE_WHERE_CLAUSE) &&
				String.isNotBlank(map_HIConfigurations.get(HIBenefitApplicationUserBatch.FILTER_TYPE_WHERE_CLAUSE).Value__c)
			) {
				strQuery +=
					' ' +
					HIBatchUtil.getHIBatchConfigWhereClause(
						map_HIConfigurations.get(HIBenefitApplicationUserBatch.FILTER_TYPE_WHERE_CLAUSE).Value__c,
						HIBenefitApplicationUserBatch.intMarkDeadAfterDays,
						HIBenefitApplicationUserBatch.intDeleteAfterDays
					);
			}

			if (
				map_HIConfigurations.containsKey(HIBenefitApplicationUserBatch.FILTER_TYPE_ORDER_BY) &&
				String.isNotBlank(map_HIConfigurations.get(HIBenefitApplicationUserBatch.FILTER_TYPE_ORDER_BY).Value__c)
			) {
				strQuery += ' ' + map_HIConfigurations.get(HIBenefitApplicationUserBatch.FILTER_TYPE_ORDER_BY).Value__c;
			}
		}
		System.assertEquals(true, isValidSOQL(strQuery, System.now().addDays(-HIBenefitApplicationUserBatch.intMarkDeadAfterDays), System.now().addDays(-HIBenefitApplicationUserBatch.intDeleteAfterDays)), strQuery);
	}

	/**
	 * @description Test HICarrierVersionDetailBatch Query
	 * @author Nigam Goyal | 05-29-2024
	 **/
	@isTest
	static void testHICarrierVersionDetailBatchQuery() {
		Map<String, HI_Configuration__mdt> map_HIConfigurations = HIBatchUtil.fetchHIConfigurations(HICarrierVersionDetailBatch.BATCH_CLASS_NAME);
		String strQuery = '';
		if (map_HIConfigurations != null) {
			if (
				map_HIConfigurations.containsKey(HICarrierVersionDetailBatch.FILTER_TYPE_BASE_QUERY) &&
				String.isNotBlank(map_HIConfigurations.get(HICarrierVersionDetailBatch.FILTER_TYPE_BASE_QUERY).Value__c)
			) {
				strQuery = map_HIConfigurations.get(HICarrierVersionDetailBatch.FILTER_TYPE_BASE_QUERY).Value__c;
			}

			if (
				map_HIConfigurations.containsKey(HICarrierVersionDetailBatch.FILTER_TYPE_WHERE_CLAUSE) &&
				String.isNotBlank(map_HIConfigurations.get(HICarrierVersionDetailBatch.FILTER_TYPE_WHERE_CLAUSE).Value__c)
			) {
				strQuery +=
					' ' +
					HIBatchUtil.getHIBatchConfigWhereClause(
						map_HIConfigurations.get(HICarrierVersionDetailBatch.FILTER_TYPE_WHERE_CLAUSE).Value__c,
						HICarrierVersionDetailBatch.intMarkDeadAfterDays,
						HICarrierVersionDetailBatch.intDeleteAfterDays
					);
			}

			if (
				map_HIConfigurations.containsKey(HICarrierVersionDetailBatch.FILTER_TYPE_ORDER_BY) &&
				String.isNotBlank(map_HIConfigurations.get(HICarrierVersionDetailBatch.FILTER_TYPE_ORDER_BY).Value__c)
			) {
				strQuery += ' ' + map_HIConfigurations.get(HICarrierVersionDetailBatch.FILTER_TYPE_ORDER_BY).Value__c;
			}
		}
		System.assertEquals(true, isValidSOQL(strQuery, System.now().addDays(-HICarrierVersionDetailBatch.intMarkDeadAfterDays), System.now().addDays(-HICarrierVersionDetailBatch.intDeleteAfterDays)), strQuery);
	}

	/**
	 * @description Test HIGroupEventBatch Query
	 * @author Nigam Goyal | 05-29-2024
	 **/
	@isTest
	static void testHIGroupEventBatchQuery() {
		Map<String, HI_Configuration__mdt> map_HIConfigurations = HIBatchUtil.fetchHIConfigurations(HIGroupEventBatch.BATCH_CLASS_NAME);
		String strQuery = '';
		if (map_HIConfigurations != null) {
			if (map_HIConfigurations.containsKey(HIGroupEventBatch.FILTER_TYPE_BASE_QUERY) && String.isNotBlank(map_HIConfigurations.get(HIGroupEventBatch.FILTER_TYPE_BASE_QUERY).Value__c)) {
				strQuery = map_HIConfigurations.get(HIGroupEventBatch.FILTER_TYPE_BASE_QUERY).Value__c;
			}

			if (map_HIConfigurations.containsKey(HIGroupEventBatch.FILTER_TYPE_WHERE_CLAUSE) && String.isNotBlank(map_HIConfigurations.get(HIGroupEventBatch.FILTER_TYPE_WHERE_CLAUSE).Value__c)) {
				strQuery +=
					' ' +
					HIBatchUtil.getHIBatchConfigWhereClause(
						map_HIConfigurations.get(HIGroupEventBatch.FILTER_TYPE_WHERE_CLAUSE).Value__c,
						HIGroupEventBatch.intMarkDeadAfterDays,
						HIGroupEventBatch.intDeleteAfterDays
					);
			}

			if (map_HIConfigurations.containsKey(HIGroupEventBatch.FILTER_TYPE_ORDER_BY) && String.isNotBlank(map_HIConfigurations.get(HIGroupEventBatch.FILTER_TYPE_ORDER_BY).Value__c)) {
				strQuery += ' ' + map_HIConfigurations.get(HIGroupEventBatch.FILTER_TYPE_ORDER_BY).Value__c;
			}
		}
		System.assertEquals(true, isValidSOQL(strQuery, System.now().addDays(-HIGroupEventBatch.intMarkDeadAfterDays), System.now().addDays(-HIGroupEventBatch.intDeleteAfterDays)), strQuery);
	}

	/**
	 * @description To check if query is valid or not
	 * @author Nigam Goyal | 05-29-2024
	 * @param query Dynamic Query
	 * @return Boolean True or False
	 **/
	private static Boolean isValidSOQL(String query, DateTime dtDeadCheck, DateTime dtDeleteCheck) {
		try {
			Database.query(query);
			return true;
		} catch (Exception e) {
			return false;
		}
	}
}