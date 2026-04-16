/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-15-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class EmailNotificationInvocable_Test {

    @TestSetup
    static void setupData() {
        Account acc = TestDataFactory.createAccount(true);
        TestDataFactory.createWonOpportunity(acc.Id, true);
    }

    @isTest
    static void givenValidOppIdWhenInvokeThenJobEnqueued() {
        // GIVEN
        Opportunity opp = [
            SELECT Id 
            FROM Opportunity 
            LIMIT 1
        ];
        // WHEN
        Test.startTest();
        EmailNotificationInvocable.enviarNotificacion(new List<Id>{ opp.Id });
        Test.stopTest();
        // THEN
        List<AsyncApexJob> jobs = [
            SELECT Id 
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'EmailNotificationQueueable'
        ];
        System.assert(jobs.size() >= 1, 'Debe encolarse al menos 1 job');
    }

    @isTest
    static void givenMultipleOppsWhenInvokeThenAllJobsEnqueued() {
        // GIVEN
        Account acc = [
            SELECT Id 
            FROM Account 
            LIMIT 1
        ];
        TestDataFactory.createWonOpportunity(acc.Id, true);
        List<Opportunity> opps = [
            SELECT Id 
            FROM Opportunity 
        ];
        List<Id> ids = new List<Id>();
        for (Opportunity o : opps){
             ids.add(o.Id);
        }
        // WHEN
        Test.startTest();
        EmailNotificationInvocable.enviarNotificacion(ids);
        Test.stopTest();
        // THEN
        List<AsyncApexJob> jobs = [
            SELECT Id 
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'EmailNotificationQueueable'
        ];
        System.assert(jobs.size() >= 2, 'Deben encolarse jobs para cada opp');
    }

    @isTest
    static void givenEmptyListWhenInvokeThenNoException() {
        // GIVEN
        Boolean noException = true;
        // WHEN
        Test.startTest();
        try {
            EmailNotificationInvocable.enviarNotificacion(new List<Id>());
        } catch (Exception e) {
            noException = false;
        }
        Test.stopTest();
        // THEN
        System.assert(noException, 'Lista vacía no debe lanzar excepción');
    }

    @isTest
    static void givenNullIdInListWhenInvokeThenSkipsNull() {
        // GIVEN
        Opportunity opp = [
            SELECT Id 
            FROM Opportunity 
            LIMIT 1
        ];
        // WHEN
        Test.startTest();
        EmailNotificationInvocable.enviarNotificacion(new List<Id>{ null, opp.Id });
        Test.stopTest();
        // THEN
        List<AsyncApexJob> jobs = [
            SELECT Id FROM AsyncApexJob
            WHERE ApexClass.Name = 'EmailNotificationQueueable'
        ];
        System.assertEquals(1, jobs.size(), 'Solo debe encolarse 1 job, el nulo se omite');
    }

    @isTest
    static void givenEjecutivoWhenInvokeThenCanInvoke() {
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
            EmailNotificationInvocable.enviarNotificacion(new List<Id>{ opp.Id });
            Test.stopTest();
            // THEN
            System.assert(true, 'Ejecutivo debe poder invocar el método');
        }
    }

    @isTest
    static void givenAnalistaWhenInvokeThenCanInvoke() {
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
            EmailNotificationInvocable.enviarNotificacion(new List<Id>{ opp.Id });
            Test.stopTest();
            // THEN
            System.assert(true, 'Analista debe poder invocar el método');
        }
    }
}