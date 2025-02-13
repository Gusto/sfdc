/**
 * @author       Neha Dabas
 * @date         3rd March 2020
 * @description  Methods to process BenefitOrder and Carrier Order history records, and create respective Analytics_time_Tracker records based on the configurations
 * @revisions    Date ------------ Name ------------ Comments
 **/
public with sharing class BTTimeTrackingUtil {
    //To hold Analytics configuration records as per Category for non-TaDa plans
    /*
     * Map Structure : Map<Metric_Type__c(Cycle Time/Processing Time),Map<Category__c(Qualification etc.),Map<Date_Type__c(Start/End),Analytics_Configurations__mdt record>>>
     */
    Map<String,map<String,Map<String,Analytics_Configurations__mdt>>> map_categoryConfig = new Map<String,map<string,Map<String,Analytics_Configurations__mdt>>>(); 
    
    //To hold Analytics configuration records as per Category for TaDa plans
    Map<String,map<string,Map<String,Analytics_Configurations__mdt>>> map_categoryConfigTaDa = new Map<String,map<string,Map<String,Analytics_Configurations__mdt>>>(); 
    
    //To hold Analytics Time Tracker records as per Order per Metric and per Category
    map<Id,Map<String,map<string,Analytics_Time_Tracker__c>>> map_orderId_CategoryTrackerRecord = new map<Id,Map<String,map<string,Analytics_Time_Tracker__c>>>();  
	
	Static final String MIN_VALUE 	= 'min', MAX_VALUE 	= 'max', START_DATE_TYPE = 'Start', END_DATE_TYPE = 'End', EARLIEST_VALUE = 'Earliest', LATEST_VALUE = 'Latest';

    Static final String BTBenefitOrderRelatedFieldName = 'Benefit_Order__c', BTCarrierOrderRelatedFieldName = 'Carrier_Order__c';
   	Id idBTTimeTrackerRecordType;
   	
   	//Contructor
   	public BTTimeTrackingUtil(){
   		idBTTimeTrackerRecordType = Cache.getRecordTypeId('Analytics_Time_Tracker__c','Benefits Transfer');
   	}
    /*
	 * Created By ND, 3rd March 2020
	 * Desc: fetch analytics configuration data and segregate it based on Metric Type and Categories
	 */
    public void getConfigData(String strRecTypeName){
        for(Analytics_Configurations__mdt config: [SELECT Id,Metric_Type__c, Category__c,Date_Type__c,Event__c,Event_Criteria__c,Event_Value__c,Additional_Info__c,Record_Type__c 
        												FROM  Analytics_Configurations__mdt WHERE Record_Type__c = :strRecTypeName]){
            
            Map<String,Map<String,Analytics_Configurations__mdt>> map_PerMetricConfig; // key is Date Type (Start or End)
            Map<String,Analytics_Configurations__mdt> map_config; // key is Date Type (Start or End)
            
            //If Additional info Contains TaDa, then it is used for TaDa Order
            if(config.Additional_Info__c != NULL && config.Additional_Info__c.containsIgnoreCase('TaDa')){
            	//Check for metric type (Cycle Time or Processing Time)
            	if(map_categoryConfigTaDa.containsKey(config.Metric_Type__c)){
            		map_PerMetricConfig = map_categoryConfigTaDa.get(config.Metric_Type__c);
            	}
            	else{
            		map_PerMetricConfig = new Map<String,Map<String,Analytics_Configurations__mdt>>();
            	}
            	//Check for Category
            	if(map_PerMetricConfig.containsKey(config.Category__c)){
	            	map_config = map_PerMetricConfig.get(config.Category__c);
	            }
	            else map_config = new Map<String,Analytics_Configurations__mdt>();
	            
	            map_config.put(config.Date_Type__c,config); // Key is Date Type (Start or End)
           		map_PerMetricConfig.put(config.Category__c,map_config); // Key is category (Qualification, Advocate Collection,...etc)
           		map_categoryConfigTaDa.put(config.Metric_Type__c,map_PerMetricConfig); // Key is Metric Type (Cycle Time, Processing Time)
	           		
            }
            //If Either Additional Info is Blank or it contains BOR, then it is used for a regular Order(non-TaDa)
            if(config.Additional_Info__c == NULL || String.isBlank(config.Additional_Info__c) || config.Additional_Info__c.containsIgnoreCase('BOR')){
           		//Check for Metric Type
           		if(map_categoryConfig.containsKey(config.Metric_Type__c)){
            		map_PerMetricConfig = map_categoryConfig.get(config.Metric_Type__c);
            	}
            	else{
            		map_PerMetricConfig = new Map<String,Map<String,Analytics_Configurations__mdt>>();
            	}
            	//Check for CAtegory
            	if(map_PerMetricConfig.containsKey(config.Category__c)){
	            	map_config = map_PerMetricConfig.get(config.Category__c);
	            }
	            else map_config = new Map<String,Analytics_Configurations__mdt>();
	            
	            map_config.put(config.Date_Type__c,config); // Key is Date Type (Start or End)
           		map_PerMetricConfig.put(config.Category__c,map_config); // Key is category (Qualification, Advocate Collection,...etc)
           		map_categoryConfig.put(config.Metric_Type__c,map_PerMetricConfig); // Key is Metric Type (Cycle Time, Processing Time)
            }
            
        }
    }
	/*
	 * Created By ND, 3rd March 2020
	 * Desc: Fetch existing analytics time tracker records based on Related Record Ids and type of related record and segregate it based on Order, Metric type and Config Categories i.e. Event Type
	 */
    public void getTimeStampData(set<Id> set_RelatedRecId,String strRelatedRecType){
        if(set_RelatedRecId != null && set_RelatedRecId.size()>0){
            map_orderId_CategoryTrackerRecord = new map<Id,Map<String,map<string,Analytics_Time_Tracker__c>>>();
            
            map<String,Map<string,Analytics_Time_Tracker__c>> map_PerMetricTrackerRecord;
            
            map<string,Analytics_Time_Tracker__c> map_categoryTrackerRecord;
			
			String strTimeTrackerQuery = 'SELECT Start_Date__c,Metric_Type__c,End_Date__c,Event_Type__c,Benefit_Order__c,Carrier_Order__c,Record_Id__c,Object_Name__c FROM Analytics_Time_Tracker__c WHERE ';
			strTimeTrackerQuery += ' '+strRelatedRecType+' IN :set_RelatedRecId AND RecordType.Id = :idBTTimeTrackerRecordType';

			List<Analytics_Time_Tracker__c> lst_ExistingTimetracker = new List<Analytics_Time_Tracker__c>();
			lst_ExistingTimetracker = database.query(strTimeTrackerQuery);
			
			//Construct map to hold the time tracker records for each category for each relatedRecord(BO or CO)
			if(lst_ExistingTimetracker != NULL && lst_ExistingTimetracker.size() > 0){
	            for(Analytics_Time_Tracker__c objTracker: lst_ExistingTimetracker){
	                Id idRelatedRec = (Id)objTracker.get(strRelatedRecType);
	                
	                //Check for Record Id
	                if(map_orderId_CategoryTrackerRecord.containsKey(idRelatedRec)){
	                    map_PerMetricTrackerRecord = map_orderId_CategoryTrackerRecord.get(idRelatedRec);
	                }
	                else{
	                	map_PerMetricTrackerRecord = new map<String,Map<string,Analytics_Time_Tracker__c>>();
	                }
	                
	                //Check for Metric Type
	                if(map_PerMetricTrackerRecord.containsKey(objTracker.Metric_Type__c)){
	                	map_categoryTrackerRecord = map_PerMetricTrackerRecord.get(objTracker.Metric_Type__c);
	                }
	                else{
	                	map_categoryTrackerRecord = new Map<String,Analytics_Time_Tracker__c>();
	                }
	                
	                //Put the existing Time_Tracker record for a given category in the map
	                map_categoryTrackerRecord.put(objTracker.Event_Type__c,objTracker);
	                
	                map_PerMetricTrackerRecord.put(objTracker.Metric_Type__c,map_categoryTrackerRecord);
	                map_orderId_CategoryTrackerRecord.put(idRelatedRec,map_PerMetricTrackerRecord);
	            }
			}
        }
    }
    /*
     * Created By ND, 3rd March 2020
     * Compare different metrics for each Order, to update/ create Time TRacker information
     */
    public void syncTimeTrackingDetails(list<sObject> list_COorBO,String strBTConfigRecType){

        if(list_COorBO == null || list_COorBO.size() == 0){
        	return;
        }
        //Fetch configuration records based on Record Type field on Analytics Configuration
        getConfigData(strBTConfigRecType);
        
        List<Analytics_Time_Tracker__c> list_TimeTracker = new List<Analytics_Time_Tracker__c>();
        
        if(strBTConfigRecType.equalsIgnoreCase('Benefits Transfer BO')){
        	list_TimeTracker = syncTimeTrackingDetailsforBO((List<Benefit_Order__c>) list_COorBO,list_TimeTracker);
        }
        else if(strBTConfigRecType.equalsIgnoreCase('Benefits Transfer CO')){
        	list_TimeTracker = syncTimeTrackingDetailsforCO((List<Carrier_Order__c>) list_COorBO,list_TimeTracker);
        }
        
        // if there are time tracker records to be updated, then update/insert those records
        if(list_TimeTracker.size() > 0){
        	Database.upsert(list_TimeTracker);
        }
    }
    /*
     * Created By ND, 4th March 2020
     * Compare different metrics for each Benefit Order, to update/ create Time TRacker information
     */
    public List<Analytics_Time_Tracker__c> syncTimeTrackingDetailsforBO(list<Benefit_Order__c> list_BO,List<Analytics_Time_Tracker__c> list_TimeTracker){
     	//To get related BO ids in order to fetch existing time tracker records
     	Set<Id> set_RelatedRecId = new Set<Id>();
     	
     	for(Benefit_Order__c objBO : list_BO){
	        set_RelatedRecId.add(objBO.Id);
        }
        
        //fetch existing timestamp records
        getTimeStampData(set_RelatedRecId,BTBenefitOrderRelatedFieldName);
        
        for(Benefit_Order__c objBO : list_BO){
        	map<string,Map<String,Map<String,Analytics_Configurations__mdt>>> map_categoryConfigRecord;
			
			//Check if Benefit Order is TaDa or not
			/* //uncomment this when we have TaDa values at BO Level
			if(objBO.Type__c != NULL && objBO.Type__c.containsIgnoreCase('TaDa'){
				map_categoryConfigRecord = map_categoryConfigTaDa;
			}
			else{*/
				map_categoryConfigRecord = map_categoryConfig;
			/*}*/
			//for each Metric Type and Category, compare the metrics
			if(map_categoryConfigRecord != NULL && map_categoryConfigRecord.size() > 0){
				for(string metricName: map_categoryConfigRecord.keyset()){
					Map<String,Map<String,Analytics_Configurations__mdt>> map_PerCategoryConfig = map_categoryConfigRecord.get(metricName);
		            for(string categoryName: map_PerCategoryConfig.keyset()){
		            	//this map will always have 2 values, one config record for End date and one for START date
		                Map<String,Analytics_Configurations__mdt> map_configRec = map_PerCategoryConfig.get(categoryName); 
		                Analytics_Time_Tracker__c objTracker;  // current tracker record
		                Analytics_Configurations__mdt configRec;  // current config record
		               
		               	map<string,Map<String,Analytics_Time_Tracker__c>> map_MetricViseTrackerRec;
		                map<string,Analytics_Time_Tracker__c> map_categoryTrackerRecord;
		                if(map_orderId_CategoryTrackerRecord != NULL && map_orderId_CategoryTrackerRecord.containsKey(objBO.Id)){
		                	
		                	map_MetricViseTrackerRec = map_orderId_CategoryTrackerRecord.get(objBO.Id);
		                	
		                	if(map_MetricViseTrackerRec != NULL && map_MetricViseTrackerRec.containsKey(metricName)){
			                	map_categoryTrackerRecord =	map_MetricViseTrackerRec.get(metricName); 
			                 	
			                 	//Time Tracker record already exists
			                 	if(map_categoryTrackerRecord != NULL && map_categoryTrackerRecord.containsKey(categoryName)){
			                 		objTracker = map_categoryTrackerRecord.get(categoryName);
			                 	}
		                	}
		                }
		                //Time Tracker record doesnot exist
		                if(objTracker == NULL){
		                	//create a new instance of Time TRacker
				 			objTracker = new Analytics_Time_Tracker__c( Benefit_Order__c = objBO.Id,
				 														Event_Type__c = categoryName, 
				 														Object_Name__c = 'Benefit_Order__c',
				 														Record_Id__c = objBO.Id,
				 														RecordTypeId = idBTTimeTrackerRecordType,
				 														Metric_Type__c = metricName);
				 		}
		               	if(map_configRec != NULL && map_configRec.size() > 0){
		               		//this loop will have only 2 iterations per Config Category, one for START date and another for END Date
		               		for(String dateType : map_configRec.keySet()){
		               			configRec = map_configRec.get(dateType);
		               			
		               			if(configRec != NULL){
		               				//if Event is Status Update on Benefit Order, then we have to check related Benefit_Order_Status_Change_History__c records
		               				if('Status Update'.equalsIgnoreCase(configRec.Event__c)){
		               					orderStatusCheck(objTracker,configRec, objBO.Benefit_Order_Status_Change_History__r);
		               				}
		               				//if Event is Order Field Update, then we just check the corresponding field on Benefit Order
	                   				else if('Order Field Update'.equalsIgnoreCase(configRec.Event__c)){
	                   					if(START_DATE_TYPE.equalsIgnoreCase(configRec.Date_Type__c) && NULL == objTracker.Start_Date__c){
	                   						objTracker.Start_Date__c = DateTime.valueOf(objBO.get(configRec.Event_Value__c));
	                   					}
	                   					else if(END_DATE_TYPE.equalsIgnoreCase(configRec.Date_Type__c) && NULL == objTracker.End_Date__c){
	                   						objTracker.End_Date__c = DateTime.valueOf(objBO.get(configRec.Event_Value__c));
	                   					}
	                   				}
								}
							}
						}
						
						//If either of start date or end date is populated, then add it to time tracker map and list
	               		if(objTracker.Start_Date__c != NULL || objTracker.End_Date__c != NULL){
	               			list_TimeTracker.add(objTracker);
	               			if(map_MetricViseTrackerRec == NULL) map_MetricViseTrackerRec = new map<string,Map<String,Analytics_Time_Tracker__c>> ();
	               			if(map_categoryTrackerRecord == NULL) map_categoryTrackerRecord = new map<string,Analytics_Time_Tracker__c>();
				 			
				 			map_categoryTrackerRecord.put(categoryName,objTracker);
				 			map_MetricViseTrackerRec.put(metricName,map_categoryTrackerRecord);
				 			map_orderId_CategoryTrackerRecord.put(objBO.Id,map_MetricViseTrackerRec);
	               		}
					}
				}
			}
        }
        return list_TimeTracker;
    }
    /*
     * Created By ND, 4th March 2020
     * Compare different metrics for each Carrier Order, to update/ create Time TRacker information
     */
    public List<Analytics_Time_Tracker__c> syncTimeTrackingDetailsforCO(list<Carrier_Order__c> list_CO,List<Analytics_Time_Tracker__c> list_TimeTracker){
     	//Get related Carrier Order Ids to fetch existing Time TRacker records
     	Set<Id> set_RelatedRecId = new Set<Id>();
     	
     	for(Carrier_Order__c objCO : list_CO){
	        set_RelatedRecId.add(objCO.Id);
        }
        
        //Fetch Time TRacker records
        getTimeStampData(set_RelatedRecId,BTCarrierOrderRelatedFieldName);
        
        for(Carrier_Order__c objCO : list_CO){
        	map<string,Map<String,Map<String,Analytics_Configurations__mdt>>> map_categoryConfigRecord;

			//Check if Carrier Order is TaDa or not
			if(objCO.TAdA__c){
				map_categoryConfigRecord = map_categoryConfigTaDa;
			}
			else{
				map_categoryConfigRecord = map_categoryConfig;
			}
			//for each Metric Type and Category, compare the metrics
			if(map_categoryConfigRecord != NULL && map_categoryConfigRecord.size() > 0){
	            for(string metricName: map_categoryConfigRecord.keyset()){
					Map<String,Map<String,Analytics_Configurations__mdt>> map_PerCategoryConfig = map_categoryConfigRecord.get(metricName);
		            for(string categoryName: map_PerCategoryConfig.keyset()){
		            	//this map will always have 2 values, one config record for End date and one for START date
		                Map<String,Analytics_Configurations__mdt> map_configRec = map_PerCategoryConfig.get(categoryName);
		                map<string,Map<String,Analytics_Time_Tracker__c>> map_MetricViseTrackerRec;
		                
		                Analytics_Time_Tracker__c objTracker;  // current tracker record
		                Analytics_Configurations__mdt configRec;  // current config record
		               
		                map<string,Analytics_Time_Tracker__c> map_categoryTrackerRecord;
		                if(map_orderId_CategoryTrackerRecord != NULL && map_orderId_CategoryTrackerRecord.containsKey(objCO.Id)){
		                	map_MetricViseTrackerRec =	map_orderId_CategoryTrackerRecord.get(objCO.Id); 
		                 	
		                 	if(map_MetricViseTrackerRec != NULL && map_MetricViseTrackerRec.containsKey(metricName)){
			                	map_categoryTrackerRecord =	map_MetricViseTrackerRec.get(metricName); 
			                 	
			                 	//Time Tracker record already exists
			                 	if(map_categoryTrackerRecord != NULL && map_categoryTrackerRecord.containsKey(categoryName)){
			                 		objTracker = map_categoryTrackerRecord.get(categoryName);
			                 	}
		                	}
		                }
		                //Time Tracker record doesnot exist
		                if(objTracker == NULL){
		                	//create a new instance of Time TRacker
				 			objTracker = new Analytics_Time_Tracker__c( Carrier_Order__c = objCO.Id,
				 														Event_Type__c = categoryName, 
				 														Object_Name__c = 'Carrier_Order__c',
				 														Record_Id__c = objCO.Id,
				 														RecordTypeId = idBTTimeTrackerRecordType,
				 														Metric_Type__c = metricName);
				 		}
		               	if(map_configRec != NULL && map_configRec.size() > 0){
		               		//this loop will have only 2 iterations per Config Category, one for START date and another for END Date
		               		for(String dateType : map_configRec.keySet()){
		               			configRec = map_configRec.get(dateType);
		               			
		               			if(configRec != NULL){
		               				//if Event is Status Update on Order, then we have to check Order_Status_Change_History records
		               				if('Status Update'.equalsIgnoreCase(configRec.Event__c)){
		               					orderStatusCheck(objTracker,configRec, objCO.Carrier_Order_Stage_History__r);
		               				}
		               				//if Event is Order Field Update, then we just check the corresponding field on Order
	                   				else if('Order Field Update'.equalsIgnoreCase(configRec.Event__c)){
	                   					DateTime dtValue = DateTime.valueOf(objCO.get(configRec.Event_Value__c));
	                   					if(START_DATE_TYPE.equalsIgnoreCase(configRec.Date_Type__c) && NULL == objTracker.Start_Date__c){
	                   						objTracker.Start_Date__c = dtValue;
	                   					}
	                   					else if(END_DATE_TYPE.equalsIgnoreCase(configRec.Date_Type__c) && NULL == objTracker.End_Date__c){
	                   						objTracker.End_Date__c = dtValue;
	                   					}
	                   				}
								}
							}
						}
						//If either of start date or end date is populated, then add it to time tracker map and list
	               		if(objTracker.Start_Date__c != NULL || objTracker.End_Date__c != NULL){
	               			list_TimeTracker.add(objTracker);
	               			
	               			if(map_MetricViseTrackerRec == NULL) map_MetricViseTrackerRec = new map<string,Map<String,Analytics_Time_Tracker__c>> ();
	               			if(map_categoryTrackerRecord == NULL) map_categoryTrackerRecord = new map<string,Analytics_Time_Tracker__c>();
				 			
				 			map_categoryTrackerRecord.put(categoryName,objTracker);
				 			map_MetricViseTrackerRec.put(metricName,map_categoryTrackerRecord);
				 			map_orderId_CategoryTrackerRecord.put(objCO.Id,map_MetricViseTrackerRec);
	               		}
					}
	            }
			}
        }
        return list_TimeTracker;
    }
    /*
     * Created By ND, 4th March 2020
     * Check if Benefit Order Status or Carrier Order Stage changes satisfy the criteria on relevant Config records
     */
    public void orderStatusCheck(Analytics_Time_Tracker__c objTracker,Analytics_Configurations__mdt configRec, list<sObject> lst_History){
        //Proceed further only if either start date or end date is not set, or Criteria is to find the latest date
 		if(configRec.Event_Criteria__c.containsIgnoreCase(LATEST_VALUE) || (START_DATE_TYPE.equalsIgnoreCase(configRec.Date_Type__c) && NULL == objTracker.Start_Date__c)
 									||(END_DATE_TYPE.equalsIgnoreCase(configRec.Date_Type__c) && NULL == objTracker.End_Date__c)){
        	DateTime value;
        	String criteria;
        	//To determine how the comparison should be based on whether the Earliest or the Latest value is needed
        	if(configRec.Event_Criteria__c.containsIgnoreCase(EARLIEST_VALUE)){
	 			criteria = MIN_VALUE;
	 		}
	 		else {
	 			criteria = MAX_VALUE;
	 		}
			if(START_DATE_TYPE.equalsIgnoreCase(configRec.Date_Type__c) && NULL != objTracker.Start_Date__c){
				value = objTracker.Start_Date__c;
			}
			else if(END_DATE_TYPE.equalsIgnoreCase(configRec.Date_Type__c) && NULL != objTracker.End_Date__c){
				value = objTracker.End_Date__c;
			}
			String orderStatusToCompare;
			
			orderStatusToCompare = configRec.Event_Value__c;
			
			
			String field;
			//if End Date is needed, then we check if OrderStatusHistory.From_Status = the value in config record, otherwise we check to_Status on orderStatusHistory
			if(configRec.Record_Type__c == 'Benefits Transfer BO'){
				if(configRec.Event_Criteria__c.contains(END_DATE_TYPE)){
					field = 'From_Status__c';
				}
				else field = 'To_Status__c';
				
				List<Benefit_Order_Status_Change_History__c> lstBOHistory = (List<Benefit_Order_Status_Change_History__c>) lst_History;
				
				for(Benefit_Order_Status_Change_History__c rec: lstBOHistory){
					String val = rec.get(field) != NULL ? String.valueOf(rec.get(field)) : '';
					if(val.equalsIgnoreCase(orderStatusToCompare)){		
						if(NULL == value || (criteria == MIN_VALUE && value > rec.End_Time__c) || (criteria == MAX_VALUE && value < rec.End_Time__c)){						
							value = rec.End_Time__c;
						}
					}
				}
			}
			else if(configRec.Record_Type__c == 'Benefits Transfer CO'){
				if(configRec.Event_Criteria__c.contains(END_DATE_TYPE)){
					field = 'From_Stage__c';
				}
				else field = 'To_Stage__c';
				
				List<Carrier_Order_Stage_History__c> list_COHistory = (List<Carrier_Order_Stage_History__c>) lst_History;
				
				for(Carrier_Order_Stage_History__c rec: list_COHistory){
					String val = String.valueOf(rec.get(field));
					if(val.equalsIgnoreCase(orderStatusToCompare)){		
						if(NULL == value || (criteria == MIN_VALUE && value > rec.End_Time__c) || (criteria == MAX_VALUE && value < rec.End_Time__c)){						
							value = rec.End_Time__c;
						}
					}
				}
			}
            if(START_DATE_TYPE.equalsIgnoreCase(configRec.Date_Type__c)  && value != objTracker.Start_Date__c){
				objTracker.Start_Date__c = value;
			}
			else if(END_DATE_TYPE.equalsIgnoreCase(configRec.Date_Type__c) && value != objTracker.End_Date__c){
				objTracker.End_Date__c = value;
			}
        }
    }
}