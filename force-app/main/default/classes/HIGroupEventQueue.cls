/**
 * @name         HIGroupEventQueue
 * @author       Gireesh
 * @date         08/01/2020
 * @description  This class handles the queueing for HIGroupEvents
 * @test class   HIGroupEventTriggerHelperTest.cls
 * @revisions    Date ------------ Name ------------ Comments
 **/
public class HIGroupEventQueue implements Queueable {
	private List<HIGroupEvent__c> list_HIGroupEvent;

	public HIGroupEventQueue(List<HIGroupEvent__c> list_HIGroupEvent) {
		this.list_HIGroupEvent = list_HIGroupEvent;
	}

	public void execute(QueueableContext context) {
		HIGroupEventTriggerHelper.queue = true;
		if (list_HIGroupEvent.size() > 0) {
			update list_HIGroupEvent;
		}
	}
}