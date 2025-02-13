/**
 * @name         DailyLimitsMonitoringController
 * @author       Sanjay Paryani
 * @date         03-30-2020
 * @description Apex controller for Visualforce page OrgLimitsMonitoring
 *              Revision is to make the page real-time
 * @author David Schach
 * @test DailyLimitsMonitoringTest
 * @date 11-10-2021
 */
public without sharing class DailyLimitsMonitoringController {
	
	public static final String CHART_TYPE_STAGING_OBJECT = 'Staging Object';
	public static final String CHART_TYPE_EXCEPTION_LOG = 'Exception Log';
	
	/**
	 * @description Hold all limits in one map so additional limits can be added by just updating the Visualforce page
	 * @author David Schach
	 * @return   Map of limit wrappers by limit name
	 */
	public Map<String, OrgLimitWrapper> map_Limits { get; private set; }

	/**
	 * @description Hold all staging object limits in one map
	 * @author Praveen
	 * @return   list of staging object limits
	 */
	public List<OrgLimitWrapper> list_StagingObjects { get; set; }

	/**
	 * @description Hold all exception log limits in one map
	 * @author Praveen
	 * @return   list of exception log limits
	 */
	public List<OrgLimitWrapper> list_ExceptionLogs { get; set; }

	// Set of pending states of pending states
	public static Set<String> set_PendingStates = new Set<String>{ IntegrationUtils.QUEUED_STATE, IntegrationUtils.ERROR_STATE };

	/**
	 * @description List of all limits for creating table on last tab
	 * @author David Schach
	 * @return   List of limit wrappers
	 */
	public List<OrgLimitWrapper> list_Limits { get; private set; }

	public DailyLimitsMonitoringController() {
		map_Limits = new Map<String, OrgLimitWrapper>();
		list_Limits = new List<OrgLimitWrapper>();
		for (System.OrgLimit objOL : OrgLimits.getAll()) {
			OrgLimitWrapper objOLW = new OrgLimitWrapper(objOL);
			map_Limits.put(objOL.getName(), objOLW);
			if (OrganizationUtilities.isSandbox()) {
				map_Limits.put('DailyScratchOrgs', new OrgLimitWrapper('DailyScratchOrgs', 0, 0, '', ''));
				map_Limits.put('ActiveScratchOrgs', new OrgLimitWrapper('ActiveScratchOrgs', 0, 0, '', ''));
			}
		}
		for (OrgLimitWrapper clsOLW : map_Limits.values()) {
			if (clsOLW.intLLimit > 0) {
				list_Limits.add(clsOLW);
			}
		}
		list_Limits.sort();

		// initialze staging object limits
		this.list_StagingObjects = new List<OrgLimitWrapper>();
		for (Staging_Object_Dashboard_Limits__c objLimit : Staging_Object_Dashboard_Limits__c.getAll().values()) {
			if (objLimit.Is_Active__c && String.isNotBlank(objLimit.Chart_Type__c)) {
				if (objLimit.Chart_Type__c.equalsIgnoreCase(CHART_TYPE_STAGING_OBJECT) && String.isNotBlank(objLimit.Staging_Object__c)) {
					list_StagingObjects.add(new OrgLimitWrapper(objLimit.Staging_Object__c, Integer.valueOf(objLimit.Max_Limit__c), 0, objLimit.Title__c, objLimit.Sub_Title__c));
				}
			}
		}

		// initialze exception log limits
		this.list_ExceptionLogs = new List<OrgLimitWrapper>();
		for (Staging_Object_Dashboard_Limits__c objLimit : Staging_Object_Dashboard_Limits__c.getAll().values()) {
			if (objLimit.Is_Active__c && String.isNotBlank(objLimit.Chart_Type__c)) {
				if (objLimit.Chart_Type__c.equalsIgnoreCase(CHART_TYPE_EXCEPTION_LOG) && String.isNotBlank(objLimit.Class_Name__c)) {
					list_ExceptionLogs.add(new OrgLimitWrapper(objLimit.Class_Name__c, Integer.valueOf(objLimit.Max_Limit__c), 0, objLimit.Title__c, objLimit.Sub_Title__c));
				}
			}
		}
	}

	/**
	 * refresh page on click
	 * @author David Schach
	 * @return   same page
	 */
	public pageReference refreshPage() {
		Pagereference objPR = Page.DailyLimitsMonitoringPage;
		objPR.setRedirect(true);
		return objPR;
	}

	/**
	 * @description Conditional display of gauges if Sandbox (e.g. no Scratch orgs available)
	 * @author David Schach
	 * @return   Boolean true if is Productionf
	 */
	public Boolean getIsProduction() {
		return OrganizationUtilities.isProduction();
	}

	/**
	 * Set page load datetime to now, since data is real-time
	 * @author David Schach
	 * @return   return now
	 */
	public DateTime getRefreshTime() {
		return System.now();
	}

	/**
	 * @description query pending records in staging objects and display them in dashboard
	 * @author  Praveen Sethu
	 * @return  Pagereference
	 */
	public PageReference queryStagingObjectLimits() {
		// initialize list of staging objects
		this.list_StagingObjects = new List<OrgLimitWrapper>();
		// iterate over all values from custom settings
		for (Staging_Object_Dashboard_Limits__c objLimit : Staging_Object_Dashboard_Limits__c.getAll().values()) {
			// display chart when custom setting record is active and chart type is not blank
			if (objLimit.Is_Active__c && String.isNotBlank(objLimit.Chart_Type__c)) {
				// check if chart type is staging object, then query pending records
				if (objLimit.Chart_Type__c.equalsIgnoreCase(CHART_TYPE_STAGING_OBJECT) && String.isNotBlank(objLimit.Staging_Object__c)) {
					// query pending records
					AggregateResult objAggResult = Database.query('SELECT COUNT(Id) ROW_COUNT FROM ' + objLimit.Staging_Object__c + ' WHERE Processing_State__c IN :set_PendingStates');
					// initialze instance of org limit wrapper and add them to to list
					list_StagingObjects.add(
						new OrgLimitWrapper(
							objLimit.Staging_Object__c,
							Integer.valueOf(objLimit.Max_Limit__c),
							Integer.valueOf(objAggResult.get('ROW_COUNT')),
							objLimit.Title__c,
							objLimit.Sub_Title__c
						)
					);
				}
			}
		}
		return null;
	}

	/**
	 * @description query number of exception logs created today and display them in dashboard
	 * @author 	Praveen Sethu
	 * @return   Pagereference
	 */
	public PageReference queryExceptionLogLimits() {
		// initialize list of exception log limits
		this.list_ExceptionLogs = new List<OrgLimitWrapper>();
		// iterate over all values from custom settings
		for (Staging_Object_Dashboard_Limits__c objLimit : Staging_Object_Dashboard_Limits__c.getAll().values()) {
			// display chart when custom setting record is active and chart type is not blank
			if (objLimit.Is_Active__c && String.isNotBlank(objLimit.Chart_Type__c)) {
				// check if chart type is exception log and class name is not blank
				if (objLimit.Chart_Type__c.equalsIgnoreCase(CHART_TYPE_EXCEPTION_LOG) && String.isNotBlank(objLimit.Class_Name__c)) {
					// query pending records
					String strClassName = objLimit.Class_Name__c;
					AggregateResult objAggResult = Database.query('SELECT COUNT(Id) ROW_COUNT FROM Exception_Log__c WHERE CreatedDate = TODAY AND Class_Name__c = :strClassName');
					// initialze instance of org limit wrapper and add them to to list
					list_ExceptionLogs.add(
						new OrgLimitWrapper(objLimit.Class_Name__c, Integer.valueOf(objLimit.Max_Limit__c), Integer.valueOf(objAggResult.get('ROW_COUNT')), objLimit.Title__c, objLimit.Sub_Title__c)
					);
				}
			}
		}
		return null;
	}
}