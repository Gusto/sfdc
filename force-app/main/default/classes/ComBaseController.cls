/**
 * @name         : ComBaseController
 * @author       : Nigam Goyal
 * @date         : 06-22-2022
 * @description  : Used for Common Base Methods related to LWC c
 * @test classes : ComBaseControllerTest
 **/
public with sharing class ComBaseController {
	/**
	 * @Author      : Nigam Goyal
	 * @Description : log an exception in record
	 * @Parm        : String message, String cmpntName, String mthdName
	 * @Return      : N/A
	 **/
	@AuraEnabled
	public static void createErrorLog(String message, String componentName, String methodName) {
		ExceptionLogUtil.logException('ERROR', componentName, methodName, message, 'Javascript');
	}

	/**
	 * @Author      : Nigam Goyal
	 * @Description : log an exception in record
	 * @Parm        : String message, String cmpntName, String mthdName
	 * @Return      : N/A
	 **/
	@AuraEnabled
	public static String getSObjectName(Id IdObjectId) {
		String strObjName = IdObjectId.getSObjectType().getDescribe().getName();
		return strObjName;
	}
}