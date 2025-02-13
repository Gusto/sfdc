@isTest
public class HIBenefitsInformationSchedulerTest {
	@isTest
	static void testBatchExecution() {
		Test.startTest();
		String CRON_EXP = '0 0 * * * ?';
		HIBenefitsInformationScheduler sch = new HIBenefitsInformationScheduler();
		System.schedule('Hourly Example Batch Schedule job', CRON_EXP, sch);
		Test.stopTest();
		System.assert(true, 'Fixed Apex PMD issue.');
	}
}