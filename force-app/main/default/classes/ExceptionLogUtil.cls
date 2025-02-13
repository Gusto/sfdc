/**
 * @name         ExceptionLogUtil
 * @author       Sanjay Paryani
 * @since        12/11/2019
 * @author       David Schach
 * @description  objLog errors into the Exception objLog Object
 * @see          ExceptionLogUtilTest
 * @group        Exceptions
 */
public without sharing class ExceptionLogUtil {
    /**
     * @author       David Schach
     * @since         10/21/2021
     * @description Method used for logging exception from a try/catch, parsing the exception in this method
     * @param strClassName accepts apex class name.
     * @param strMethodName accepts method name.
     * @param recordId accepts Id of record for which the exception has occured.
     * @param ex The exception object to be parsed
     */
    public static void logException(String strClassName, String strMethodName, Id recordId, Exception ex) {
        Exception_Log__c objLog = parseException(ex);
        objLog.Record_ID__c = recordId;
        objLog.Class_Name__c = strClassName;
        objLog.Method_Name__c = strMethodName;
        if (ex.getTypeName().containsIgnoreCase('DMLException') || ex.getTypeName().containsIgnoreCase('EmailException')) {
            objLog.Record_ID__c = ex.getDMLId(0);
            objLog.Field_Names__c = String.join((ex.getDmlFieldNames(0)), ',').left(255);
            objLog.DML_Type__c = objLog.Type__c + ' - ' + ex.getDmlType(0).name();
        }
        debugErrorLog(objLog);
        if (Test.isRunningTest()) {
            System.debug(ex);
        }
        insert objLog;
    }

    /**
     * Method used for logging exception from a try/catch, parsing the exception in this method
     * @author David Schach
     * @since 2022-01-03
     * @param strClassName accepts apex class name.
     * @param strMethodName accepts method name.
     * @param ex The exception object, to be parsed
     */
    public static void logException(String strClassName, String strMethodName, Exception ex) {
        Exception_Log__c objLog = parseException(ex);
        objLog.Class_Name__c = strClassName;
        objLog.Method_Name__c = strMethodName;
        debugErrorLog(objLog);
        if (Test.isRunningTest()) {
            System.debug(ex);
        }
        insert objLog;
    }

    /**
     * @description A single method for parsing all base fields from an Exception. We do not do DML here so we can later bulkify exception handling
     *
     * @param ex    The exception passed to be parsed
     * @return      `Exception_Log__c`
     */
    public static Exception_Log__c parseException(Exception ex) {
        Exception_Log__c objLog = new Exception_Log__c(
            User__c = UserInfo.getUserId(),
            Line_Number__c = ex.getLineNumber(),
            Stack_Trace__c = ex.getStackTraceString().left(131072),
            Message__c = ex.getMessage().left(131072),
            Type__c = ex.getTypeName(),
            OwnerId = System.Label.Dev_Team_Queue
        );
        if (ex.getTypeName().containsIgnoreCase('DMLException') || ex.getTypeName().containsIgnoreCase('EmailException')) {
            objLog.Record_ID__c = ex.getDMLId(0);
            objLog.Field_Names__c = String.join((ex.getDmlFieldNames(0)), ',').left(255);
            objLog.DML_Type__c = objLog.Type__c + ' - ' + ex.getDmlType(0).name();
        }
        // * TODO: For DML exceptions, iterate through and return one Exception line per DML error? Or is a objLog for the first line enough?
        return objLog;
    }

    /**
     * @author       Sanjay Paryani
     * @since         12/11/2019
     * @description Method used for logging exception from a try/catch, where additional information is available, such as Stack Trace, Line Number, etc.
     * @param userId accepts User Id.
     * @param recordId accepts Id of record for which the exception has occured.
     * @param strClassName accepts apex class name.
     * @param strMethodName accepts method name.
     * @param exString accepts exception string.
     * @param line accepts exception line number.
     * @param message accepts exception message.
     * @param urgency accepts exception urgency - High, Medium, Low.
     */
    public static void logException(Id userId, Id recordId, String strClassName, String strMethodName, String[] exString, Integer line, String message, String urgency) {
        String errorMessage = (message != null) ? exString[0] + '\n\n' + message : exString[0];

        Exception_Log__c objLog = new Exception_Log__c(
            User__c = userId,
            Record_ID__c = recordId,
            Class_Name__c = strClassName,
            Method_Name__c = strMethodName,
            Urgency__c = urgency,
            Line_Number__c = line,
            Stack_Trace__c = exString[1],
            Message__c = errorMessage,
            Type__c = exString[2],
            OwnerId = Label.Dev_Team_Queue
        );
        debugErrorLog(objLog);
        if (Test.isRunningTest()) {
            System.debug(objLog);
        }
        insert objLog;
    }

    /**
     * @author       Sanjay Paryani
     * @since         12/11/2019
     * @description Method used for logging exception using Database.Error, where return details are simplified.
     * @param userId accepts User Id.
     * @param strClassName accepts apex class name.
     * @param strMethodName accepts method name.
     * @param results accepts exception message.
     * @param urgency accepts exception urgency - High, Medium, Low.
     */
    public static void logException(Id userId, String strClassName, String strMethodName, String[] results, String urgency) {
        String error = 'ERROR: \n';
        for (String sr : results) {
            error += sr;
        }

        // Message__c has maximum length of 131072.. In case where Message__c exceeds this, truncate the message to fit
        // and append ellipse (...) to indicate that message is cropped to fit
        error = error.length() > 131072 ? error.left(131068) + '...' : error;

        if (error != '') {
            Exception_Log__c objLog = new Exception_Log__c(
                User__c = userId,
                Type__c = 'DMLException',
                Class_Name__c = strClassName,
                Method_Name__c = strMethodName,
                Urgency__c = urgency,
                Line_Number__c = 0,
                Record_ID__c = 'N/A',
                Message__c = error,
                OwnerId = Label.Dev_Team_Queue
            );
            debugErrorLog(objLog);
            if (Test.isRunningTest()) {
                System.debug(objLog);
            }
            insert objLog;
        }
    }

    /**
     * @author       Sanjay Paryani
     * @since         12/11/2019
     * @description Method used for logging exception using Database.Error, where return details are simplified.
     * @param userId accepts User Id.
     * @param strClassName accepts apex class name.
     * @param strMethodName accepts method name.
     * @param message accepts exception message.
     * @param stacktrace accepts exception urgency - High, Medium, Low.
     */
    public static void logException(String strClassName, String strMethodName, String message, String stacktrace) {
        logException('ERROR', strClassName, strMethodName, message, stacktrace);
    }

    /**
     * @author       Sanjay Paryani
     * @since         12/11/2019
     * @description Method used for logging exception using Database.Error, where return details are simplified.
     * @param logType accepts objLog type.
     * @param strClassName accepts apex class name.
     * @param strMethodName accepts method name.
     * @param strMessage accepts exception message.
     * @param strStacktrace accepts exception urgency - High, Medium, Low.
     */
    public static void logException(String logType, String strClassName, String strMethodName, String strMessage, String strStacktrace) {
        // Message__c has maximum length of 131072.. In case where Message__c exceeds this, truncate the message to fit
        // and append ellipse (...) to indicate that message is cropped to fit
        strMessage = strMessage != null && strMessage.length() > 131072 ? strMessage.left(131072) : strMessage;
        // Stack_Trace__c has maximum length of 131072.. In case where Stack_Trace__c exceeds this, truncate the message to fit
        // and append ellipse (...) to indicate that message is cropped to fit
        strStacktrace = strStacktrace != null && strStacktrace.length() > 131072 ? strStacktrace.left(131068) + '...' : strStacktrace;
        if (String.isNotBlank(strMethodName) && strMethodName.length() > 255) {
            strMethodName = strMethodName.subString(0, 252) + '...';
        }
        if (strMessage != '') {
            Exception_Log__c objLog = new Exception_Log__c(
                Type__c = logType,
                Class_Name__c = strClassName,
                Method_Name__c = strMethodName,
                Line_Number__c = 0,
                Record_ID__c = 'N/A',
                Message__c = strMessage,
                Stack_Trace__c = strStacktrace,
                OwnerId = Label.Dev_Team_Queue
            );
            debugErrorLog(objLog);
            if (Test.isRunningTest()) {
                System.debug(objLog);
            }
            insert objLog;
        }
    }

    /**
     * @author       Neha Dabas
     * @since         1/13/2021
     * @description Method used for logging exception using Database.Error, where return details are simplified.
     * @param logType accepts objLog type.
     * @param strClassName accepts apex class name.
     * @param strMethodName accepts method name.
     * @param list_Excep (List of Exceptions)
     */
    public static void logException(String strLogType, String strClassName, String strMethodName, List<Exception> list_Excep) {
        List<Exception_Log__c> list_Logs = new List<Exception_Log__c>();
        if (list_Excep.isEmpty()) {
            return;
        }

        for (Exception objException : list_Excep) {
            // Message__c has maximum length of 131072.. In case where Message__c exceeds this, truncate the message to fit
            // and append ellipse (...) to indicate that message is cropped to fit
            String strMessage = objException.getMessage();
            strMessage = strMessage.length() > 131072 ? strMessage.left(131072) : strMessage;
            // Stack_Trace__c has maximum length of 131072.. In case where Stack_Trace__c exceeds this, truncate the message to fit
            // and append ellipse (...) to indicate that message is cropped to fit
            String strStacktrace = objException.getStackTraceString();
            strStacktrace = strStacktrace != null && strStacktrace.length() > 131072 ? strStacktrace.left(131068) + '...' : strStacktrace;

            Exception_Log__c objLog = new Exception_Log__c(
                Type__c = strLogType,
                Class_Name__c = strClassName,
                Method_Name__c = strMethodName,
                Line_Number__c = 0,
                Record_ID__c = 'N/A',
                Message__c = strMessage,
                Stack_Trace__c = strStacktrace,
                OwnerId = Label.Dev_Team_Queue
            );
            debugErrorLog(objLog);
            if (Test.isRunningTest()) {
                System.debug(objException);
            }
            list_Logs.add(objLog);
        }

        if (!list_Logs.isEmpty()) {
            insert list_Logs;
        }
    }

    /**
     * @author      Midhuna KB
     * @since        01/04/2021
     * @description Method used for logging exception using Database.Error, where return details are simplified.
     * @param logType accepts objLog type.
     * @param strClassName accepts apex class name.
     * @param strMethodName accepts method name.
     * @param message accepts exception message.
     * @param stacktrace accepts exception urgency - High, Medium, Low.
     * @return Exception objLog record Id.
     */
    public static String logExceptionWithId(String strClassName, String strMethodName, String strMessage, String strStackTrace, Set<String> set_RecordIds) {
        Exception_Log__c objExceptionLog = new Exception_Log__c();
        String strFailedRecordIds = '';
        if (!set_RecordIds.isEmpty()) {
            for (String strRecordId : set_RecordIds) {
                if (string.isBlank(strFailedRecordIds)) {
                    strFailedRecordIds += strRecordId;
                } else {
                    strFailedRecordIds = strFailedRecordIds + ',' + strRecordId;
                }
            }
        }
        if (String.isNotBlank(strFailedRecordIds)) {
            strFailedRecordIds = strFailedRecordIds.removeEnd(',');
            strMessage += strFailedRecordIds;
        }
        if (String.isNotBlank(strMessage)) {
            strMessage = strMessage.length() > 131072 ? strMessage.left(131068) + '...' : strMessage;
        }
        if (String.isNotBlank(strStackTrace)) {
            strStackTrace = strStackTrace.length() > 131072 ? strStackTrace.left(131068) + '...' : strStackTrace;
        }
        if (strMessage != '') {
            objExceptionLog.Type__c = 'Error';
            objExceptionLog.Class_Name__c = strClassName;
            objExceptionLog.Method_Name__c = strMethodName;
            objExceptionLog.Line_Number__c = 0;
            objExceptionLog.Record_ID__c = 'N/A';
            objExceptionLog.Message__c = strMessage;
            objExceptionLog.Stack_Trace__c = strStackTrace;
            objExceptionLog.OwnerId = Label.Dev_Team_Queue;

            insert objExceptionLog;
            debugErrorLog(objExceptionLog);
            if (Test.isRunningTest()) {
                System.debug(objExceptionLog);
            }
        }
        return objExceptionLog.Id;
    }

    private static void debugErrorLog(Exception_Log__c el) {
        String logMessage = 'Error on line ' + el.Line_Number__c + ' in ' + el.Class_Name__c + '.' + el.Method_Name__c + ' StackTrace: ' + el.Stack_Trace__c;
        System.debug(logMessage);
    }
}