/*
--@Author: David (Dato) Tsamalashvili
--@CreateDate: 05/07/2018
-- To Execute BatchToUpdateCasesWithContactLead On Every Saturday
*/
global class BatchToUpdateCasesWithContactLeadSch implements Schedulable {
	global void execute(SchedulableContext sc) {
		database.executebatch(new BatchToUpdateCasesWithContactLead(), 150);
	}
}