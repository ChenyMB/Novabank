/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-16-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class EmailNotificationInvocable_Test {

    @TestSetup
    static void setupData() {
        User ejecutivo = TestDataFactory.buildUser( TestDataFactory.ROLE_EJECUTIVO, 'ejecutivo.notification@novabank.test.com');
        User analista = TestDataFactory.buildUser( TestDataFactory.ROLE_ANALISTA, 'analista.notification@novabank.test.com');
        insert new List<User>{ ejecutivo, analista };
    }

    private static void insertOppData() {
        Account acc = TestDataFactory.createAccount(true);
        TestDataFactory.createWonOpportunity(acc.Id, true);
    }

    private static Opportunity getTestOpportunity() {
        return [SELECT Id FROM Opportunity WHERE Name = 'Opp Ganada NovaBank' LIMIT 1];
    }

    private static Account getTestAccount() {
        return [SELECT Id FROM Account WHERE Name = 'Francesca Moreno' LIMIT 1];
    }

    private static User getEjecutivo() {
        return [SELECT Id FROM User WHERE Username = 'ejecutivo.notification@novabank.test.com'];
    }

    private static User getAnalista() {
        return [SELECT Id FROM User WHERE Username = 'analista.notification@novabank.test.com'];
    }

    @isTest
    static void givenValidOppIdWhenInvokeThenJobEnqueued() {
        // GIVEN
        insertOppData();
        Opportunity opp = getTestOpportunity();

        // WHEN
        Test.startTest();
        EmailNotificationInvocable.enviarNotificacion(new List<Id>{ opp.Id });
        Test.stopTest();

        // THEN
        List<AsyncApexJob> jobs = [
            SELECT Id
            FROM   AsyncApexJob
            WHERE  ApexClass.Name = 'EmailNotificationQueueable'
        ];
        System.assert(jobs.size() >= 1, 'Debe encolarse al menos 1 job');
    }

    @isTest
    static void givenMultipleOppsWhenInvokeThenAllJobsEnqueued() {
        // GIVEN
        insertOppData();
        TestDataFactory.createWonOpportunity(getTestAccount().Id, true);
        List<Id> ids = new List<Id>();
        for (Opportunity o : [SELECT Id FROM Opportunity]) {
            ids.add(o.Id);
        }

        // WHEN
        Test.startTest();
        EmailNotificationInvocable.enviarNotificacion(ids);
        Test.stopTest();

        // THEN
        List<AsyncApexJob> jobs = [
            SELECT Id
            FROM   AsyncApexJob
            WHERE  ApexClass.Name = 'EmailNotificationQueueable'
        ];
        System.assertEquals(1, jobs.size(), 'Debe encolarse 1 solo job con todas las opps agrupadas');
    }

    @isTest
    static void givenEmptyListWhenInvokeThenNoException() {
        // GIVEN / WHEN
        Test.startTest();
        try {
            EmailNotificationInvocable.enviarNotificacion(new List<Id>());
            // THEN
            System.assert(true, 'Lista vacía no debe lanzar excepción');
        } catch (Exception e) {
            System.assert(false, 'No debió lanzar excepción: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void givenNullIdInListWhenInvokeThenSkipsNull() {
        // GIVEN
        insertOppData();
        Opportunity opp = getTestOpportunity();

        // WHEN
        Test.startTest();
        EmailNotificationInvocable.enviarNotificacion(new List<Id>{ null, opp.Id });
        Test.stopTest();

        // THEN
        List<AsyncApexJob> jobs = [
            SELECT Id
            FROM   AsyncApexJob
            WHERE  ApexClass.Name = 'EmailNotificationQueueable'
        ];
        System.assertEquals(1, jobs.size(), 'Solo debe encolarse 1 job, el nulo se omite');
    }

    @isTest
    static void givenEjecutivoWhenInvokeThenJobEnqueued() {
        // GIVEN
        insertOppData();
        User ejecutivo = getEjecutivo();
        Opportunity opp = getTestOpportunity();

        System.runAs(ejecutivo) {
            // WHEN
            Test.startTest();
            EmailNotificationInvocable.enviarNotificacion(new List<Id>{ opp.Id });
            Test.stopTest();

            // THEN
            List<AsyncApexJob> jobs = [
                SELECT Id
                FROM   AsyncApexJob
                WHERE  ApexClass.Name = 'EmailNotificationQueueable'
            ];
            System.assert(jobs.size() >= 1, 'Ejecutivo debe poder encolar el job');
        }
    }

    @isTest
    static void givenAnalistaWhenInvokeThenJobEnqueued() {
        // GIVEN
        insertOppData();
        User analista = getAnalista();
        Opportunity opp = getTestOpportunity();

        System.runAs(analista) {
            // WHEN
            Test.startTest();
            EmailNotificationInvocable.enviarNotificacion(new List<Id>{ opp.Id });
            Test.stopTest();

            // THEN
            List<AsyncApexJob> jobs = [
                SELECT Id
                FROM   AsyncApexJob
                WHERE  ApexClass.Name = 'EmailNotificationQueueable'
            ];
            System.assert(jobs.size() >= 1, 'Analista debe poder encolar el job');
        }
    }
}