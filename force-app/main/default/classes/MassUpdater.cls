/**
 * The massupdater is used to update a field of a set of records to a value
 * @author cchen
 */

public with sharing class MassUpdater {
	private final Schema.SObjectField field;
	private final Object fieldValue;
	private final List<SObject> objsToUpdate;
	private ApexPages.Message currentMsg;

	public MassUpdater(List<SObject> objs, Schema.SObjectField f, Object value) {
		objsToUpdate = objs;
		field = f;
		fieldValue = value;
	}

	public ApexPages.Message massUpdate() {
		if (field == null || objsToUpdate == null || objsToUpdate.size() < 1)
			return currentMsg = new ApexPages.Message(ApexPages.severity.ERROR, 'No record selected for update.  Please click close to return');

		DisplayType t = field.getDescribe().getType();

		list<id> toUpdateRecordIds = new List<id>();
		map<id, string> objectIDNameMap = new Map<id, string>();

		try {
			for (SObject o : objsToUpdate) {
				o.put(field, fieldValue);
				toUpdateRecordIds.add((id) o.get('Id'));
				objectIDNameMap.put((id) o.get('Id'), (string) o.get('Name'));
			}
		} catch (System.SObjectException e) {
			ExceptionLogUtil.logException('MassUpdater', 'massUpdate', e.getMessage(), e.getStackTraceString());
			return new ApexPages.Message(ApexPages.severity.ERROR, e.getMessage() + '<br></br>0 record updated');
		}

		list<Database.SaveResult> srList = new List<Database.SaveResult>();
		try {
			srList = database.update(objsToUpdate, false);
		} catch (System.DmlException e) {
			currentMsg = new ApexPages.Message(ApexPages.severity.ERROR, e.getDmlMessage(0) + '  No record updated');
		}

		integer recordsSccessfullyUpdate = 0;
		integer recordsFailedToUpdate = 0;
		string errorMessage = ' ';

		for (Database.SaveResult sr : srList) {
			if (sr.isSuccess()) {
				recordsSccessfullyUpdate++;
				toUpdateRecordIds.remove(0);
			} else {
				for (Database.Error err : sr.getErrors()) {
					recordsFailedToUpdate++;
					errorMessage +=
						'The following error has occurred with record [' +
						(objectIDNameMap.containsKey(toUpdateRecordIds.get(0)) ? objectIDNameMap.get(toUpdateRecordIds.get(0)) : toUpdateRecordIds.get(0)) +
						']. ' +
						string.valueof(err.getStatusCode()) +
						': ' +
						err.getMessage() +
						'</br>';
				}
				toUpdateRecordIds.remove(0);
			}
		}

		if (recordsFailedToUpdate > 0) {
			errorMessage += '</br>Failed to update ' + string.valueof(recordsFailedToUpdate) + ' records. </br></br>';
		}

		if (recordsSccessfullyUpdate > 0) {
			errorMessage += 'Successfully updated ' + string.valueof(recordsSccessfullyUpdate) + ' records.';
		}

		if (recordsFailedToUpdate > 0) {
			currentMsg = new ApexPages.Message(ApexPages.severity.ERROR, errorMessage);
		} else {
			currentMsg = new ApexPages.Message(ApexPages.severity.Info, errorMessage);
		}

		return currentMsg;
	}
}