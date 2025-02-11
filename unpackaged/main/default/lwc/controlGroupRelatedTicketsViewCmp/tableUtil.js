/**
 * Record View Redirect field identifier
 */
export const RECORD_VIEW_FIELD_NAME = "_record_view_field_name";

/**
 * Get Queryable Fields
 * @param {Array} list_Columns
 * @returns {Array}
 */
export function getQueryFields(list_Columns) {
	const set_Fields = new Set();

	list_Columns.forEach((objColumnConfig) => {
		set_Fields.add(objColumnConfig.fieldName);

		if (Array.isArray(objColumnConfig.list_AdditionalFields)) {
			objColumnConfig.list_AdditionalFields.forEach((strField) => set_Fields.add(strField));
		}
	});

	set_Fields.delete(RECORD_VIEW_FIELD_NAME);
	set_Fields.delete(undefined);

	return Array.from(set_Fields);
}

/**
 * Get Field Name Resolved Columns (Account__r.Name ==> _Account__rName)
 * Required Since DataTable support only direct first level field value
 * @param {Array} list_Columns
 * @returns {Array}
 */
export function transformMultiLevelFieldColumns(list_Columns) {
	return list_Columns.map((objColumnConfig) => {
		return {
			...objColumnConfig,
			fieldName: resolveMultiLevelField(objColumnConfig.fieldName),
			strOriginalFieldName: objColumnConfig.fieldName
		};
	});
}

/**
 * Transform Data returned by Apex
 * Required Since DataTable support only direct first level field value
 * @param {Array} list_Records
 * @param {Array} list_Columns
 * @returns
 */
export function transformMultiLevelFieldData(list_Records, list_Columns) {
	const map_FieldNameToResolved = new Map();

	list_Columns.forEach((objConfig) => {
		map_FieldNameToResolved.set(objConfig.strOriginalFieldName, objConfig.fieldName);
	});

	return list_Records.map((objRecord) => {
		return resolveRecord(objRecord, map_FieldNameToResolved);
	});
}

/**
 * Resolve Multi Level field into One level (Account__r.Name ==> _Account__rName)
 * @param {String} strFieldName
 * @returns {String}
 */
function resolveMultiLevelField(strFieldName) {
	if (!strFieldName) {
		return strFieldName;
	}

	if (strFieldName.includes(".")) {
		return "_" + strFieldName.replaceAll(".", "");
	}

	return strFieldName;
}

/**
 * Resolve Record, Convert multi level fields into single level
 * @param {Object} objRecord
 * @param {Map} map_FieldNameToResolved
 * @returns {Object}
 */
function resolveRecord(objRecord, map_FieldNameToResolved) {
	const objResult = { ...objRecord };

	Array.from(map_FieldNameToResolved.keys()).forEach((strOriginalField) => {
		const strResolvedField = map_FieldNameToResolved.get(strOriginalField);
		objResult[strResolvedField] = getFieldValue(objRecord, strOriginalField.split("."));
	});

	objResult[RECORD_VIEW_FIELD_NAME] = getRecordViewUrl(objRecord);
	return objResult;
}

/**
 * Return Field value, Supports Multi level fields like Account__r.Anc__r.Name
 * @param {Object} objRecord
 * @param {Array} list_FieldsInLevel
 * @returns {Object}
 */
function getFieldValue(objRecord, list_FieldsInLevel) {
	if (!objRecord || list_FieldsInLevel.length === 0) {
		return objRecord;
	}

	const strField = list_FieldsInLevel.shift();
	objRecord = objRecord[strField];
	return getFieldValue(objRecord, list_FieldsInLevel);
}

/**
 * Returns Record view URL
 * @param {Object} objRecord
 * @returns {String}
 */
function getRecordViewUrl(objRecord) {
	return `/lightning/r/${objRecord.Id}/view`;
}