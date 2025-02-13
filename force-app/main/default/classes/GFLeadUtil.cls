/**
 * @description  Stores constant variables to be used in GF Lead Trigger
 * @author       Veeresh Kumar
 * @date         04-13-2022
 * @see          GFLeadTriggerHelperTest
 **/
public with sharing class GFLeadUtil {
	public static final String GRP_NAME_XERO_AE_ROTATOR = 'XERO AE Rotator';
	public static final String GRP_TYPE_QUEUE = 'Queue';

	// ERROR MESSAGES:
	public static final String ERR_MSG_FRAUDULENT_RECORD = 'Fraudulent record';
	public static final String ERR_MSG_EMAIL_TOO_LONG = 'Email: data value too long';
	public static final String MSG_INVALID_EMAIL = 'invalid email address';
	public static final String ERR_MSG_DUPLICATE_VALUE = 'duplicates value on record';
	public static final Set<String> set_ReprocessErrMsgs = new Set<String>{ ERR_MSG_DUPLICATE_VALUE };

	// LIMITS:
	public static final Integer LIMIT_LAST_NAME_CHARACTERS = 40;
}