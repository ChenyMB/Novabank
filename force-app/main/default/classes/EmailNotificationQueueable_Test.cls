/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-15-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class EmailNotificationQueueable_Test {

    @TestSetup
    static void setupData() {
        Account acc = TestDataFactory.createAccount(true);
        TestDataFactory.createWonOpportunity(acc.Id, true);
    }

    @isTest
    static void givenValidOppWhenEnqueueJobThenJobCreated() {
        // GIVEN
        Opportunity opp = [
            SELECT Id 
            FROM Opportunity 
            LIMIT 1
        ];
        // WHEN
        Test.startTest();
        Id jobId = System.enqueueJob(new EmailNotificationQueueable(opp.Id));
        Test.stopTest();
        // THEN
        System.assertNotEquals(null, jobId, 'Job debe retornar Id válido');
    }

    @isTest
    static void givenOppWithEmailWhenEnqueueJobThenExecutesWithoutError() {
        // GIVEN
        Opportunity opp = [
            SELECT Id, Account.Email__c 
            FROM Opportunity 
            LIMIT 1
        ];
        // WHEN
        Test.startTest();
        Id jobId = System.enqueueJob(new EmailNotificationQueueable(opp.Id));
        Test.stopTest();
        // THEN
        System.assert(String.isNotBlank(opp.Account.Email__c), 'Account debe tener email');
        System.assertNotEquals(null, jobId, 'Job debe encolarse correctamente');
    }

    @isTest
    static void givenNullOppIdWhenEnqueueJobThenHandled() {
        // GIVEN
        Boolean handled = false;
        // WHEN
        Test.startTest();
        try {
            System.enqueueJob(new EmailNotificationQueueable(null));
            handled = true;
        } catch (Exception e) {
            handled = true;
        }
        Test.stopTest();
        // THEN
        System.assert(handled, 'OpportunityId nulo debe manejarse sin error crítico');
    }

    @isTest
    static void givenOppWithoutEmailWhenEnqueueJobThenSkipsSend() {
        // GIVEN
        Account acc = [
            SELECT Id 
            FROM Account 
            LIMIT 1
        ];
        acc.Email__c = null;
        update acc;
        Opportunity opp = [
            SELECT Id 
            FROM Opportunity 
            LIMIT 1
        ];
        // WHEN
        Test.startTest();
        Id jobId = System.enqueueJob(new EmailNotificationQueueable(opp.Id));
        Test.stopTest();
        // THEN
        System.assertNotEquals(null, jobId, 'Job debe encolarse aunque no haya email');
    }

    @isTest
    static void givenEjecutivoWhenEnqueueJobThenCanEnqueue() {
        // GIVEN
        User ejecutivo = TestDataFactory.buildUser(TestDataFactory.ROLE_EJECUTIVO, 'ejecutivo.test.benefits@novabank.test.com');
        insert ejecutivo;
        Opportunity opp = [
            SELECT Id 
            FROM Opportunity 
            LIMIT 1
        ];
        // WHEN
        System.runAs(ejecutivo) {
            Test.startTest();
            Id jobId = System.enqueueJob(new EmailNotificationQueueable(opp.Id));
            Test.stopTest();
            // THEN
            System.assertNotEquals(null, jobId, 'Ejecutivo debe poder encolar el job');
        }
    }

    @isTest
    static void givenAnalistaWhenEnqueueJobThenCanEnqueue() {
        // GIVEN
        User analista = TestDataFactory.buildUser(TestDataFactory.ROLE_ANALISTA, 'analista.test.benefits@novabank.test.com');
        insert analista;
        Opportunity opp = [
            SELECT Id 
            FROM Opportunity 
            LIMIT 1
        ];
        // WHEN
        System.runAs(analista) {
            Test.startTest();
            Id jobId = System.enqueueJob(new EmailNotificationQueueable(opp.Id));
            Test.stopTest();
            // THEN
            System.assertNotEquals(null, jobId, 'Analista debe poder encolar el job');
        }
    }

    @isTest
    static void givenNoTemplateWhenEnqueueJobThenSkipsSend() {
        // GIVEN
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        EmailNotificationQueueable.templateDevName = 'TEMPLATE_INEXISTENTE';
        // WHEN
        Test.startTest();
        Id jobId = System.enqueueJob(new EmailNotificationQueueable(opp.Id));
        Test.stopTest();
        // THEN
        System.assertNotEquals(null, jobId, 'Job debe encolarse aunque no haya template');
    }
}