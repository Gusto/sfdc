/**
Created by : Praveen Sethu
Created Date : 11/26/2020
Description: This class is used for creating utilities common to all staging tables.
**/
public class StagingTableUtil {
	
    // Various processing states
    public static final String ERROR_STATE = 'Error';
    public static final String QUEUED_STATE = 'Queued';
    public static final String PROCESSED_STATE = 'Processed';
    public static final String DEAD_STATE = 'Dead';
    public static final String BACKLOG = 'Backlog';
    
    public static final String UN_PROCESSED_STATE = 'Unprocessed';
    
    
}