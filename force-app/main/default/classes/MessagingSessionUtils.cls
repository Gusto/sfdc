/**
 * @name         : MessagingSessionUtils
 * @author       : Pradeep Chary
 * @date         : 09-09-2024
 * @description  : Utils Class for trigger on Messaging Session object
 * @test classes : MessagingSessionTriggerHelperTest
**/
public class MessagingSessionUtils {
    
    // Statuses
    public static final String STATUS_NEW = 'New';
    public static final String STATUS_ACTIVE = 'Active';
    public static final String STATUS_ENDED = 'Ended';
    public static final String STATUS_WAITING = 'Waiting';
    public static final String STATUS_ERROR = 'Error';
    
    // Personas
    public static final String PERSONA_ACCOUNTANT = 'Accountant';
    public static final String PERSONA_ADMIN = 'Admin';
    public static final String PERSONA_MEMBER = 'Member';
    
    // Company Sizes
    public static final String COMPANY_SIZE_MICRO = 'Micro 0-4';
    public static final String COMPANY_SIZE_STANDARD = 'Standard 5-24';
    public static final String COMPANY_SIZE_GROWER_25_49 = 'Grower 25-49';
    public static final String COMPANY_SIZE_GROWER_50 = 'Grower 50';
    
    // Gusto Global
    public static final String STR_GUSTO_GLOBAL = 'Gusto Global';
    
    // Record Types
    public static final String RECTYPE_CUSTOMER_CARE = Cache.getRecordTypeId('MessagingSession', 'Customer Care');
    
}