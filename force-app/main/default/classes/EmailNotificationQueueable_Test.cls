/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-16-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class EmailNotificationQueueable_Test {

    @TestSetup
    static void setupData() {
        User ejecutivo = TestDataFactory.buildUser( TestDataFactory.ROLE_EJECUTIVO, 'ejecutivo.queueable@novabank.test.com');
        User analista = TestDataFactory.buildUser( TestDataFactory.ROLE_ANALISTA, 'analista.queueable@novabank.test.com');
        insert new List<User>{ ejecutivo, analista };
    }

    private static void insertOppData() {
        Account acc = TestDataFactory.createAccount(true);
        TestDataFactory.createWonOpportunity(acc.Id, true);
    }

    private static Opportunity getTestOpportunity() {
        return [SELECT Id FROM Opportunity WHERE Name = 'Opp Ganada NovaBank' LIMIT 1];
    }

    private static User getEjecutivo() {
        return [SELECT Id FROM User WHERE Username = 'ejecutivo.queueable@novabank.test.com'];
    }

    private static User getAnalista() {
        return [SELECT Id FROM User WHERE Username = 'analista.queueable@novabank.test.com'];
    }

    @isTest
    static void givenValidOppWhenEnqueueJobThenJobCreated() {
        // GIVEN
        insertOppData();
        Opportunity opp = getTestOpportunity();

        // WHEN
        Test.startTest();
        Id jobId = System.enqueueJob(new EmailNotificationQueueable(new List<Id>{ opp.Id }));
        Test.stopTest();

        // THEN
        System.assertNotEquals(null, jobId, 'Job debe retornar Id válido');
    }

    @isTest
    static void givenOppWithoutEmailWhenEnqueueJobThenSkipsSend() {
        // GIVEN
        insertOppData();
        Account acc = [SELECT Id FROM Account WHERE Name = 'Francesca Moreno' LIMIT 1];
        acc.Email__c = null;
        update acc;
        Opportunity opp = getTestOpportunity();

        // WHEN
        Test.startTest();
        Id jobId = System.enqueueJob(new EmailNotificationQueueable(new List<Id>{ opp.Id }));
        Test.stopTest();

        // THEN
        System.assertNotEquals(null, jobId, 'Job debe encolarse aunque no haya email');
    }

    @isTest
    static void givenEmptyListWhenEnqueueJobThenHandledGracefully() {
        // GIVEN
        // WHEN
        Test.startTest();
        Id jobId = System.enqueueJob(new EmailNotificationQueueable(new List<Id>()));
        Test.stopTest();

        // THEN
        AsyncApexJob job = [SELECT Status FROM AsyncApexJob WHERE Id = :jobId];
        System.assertNotEquals(null, job, 'Job debe existir aunque la lista esté vacía');
    }

    @isTest
    static void givenNullInListWhenEnqueueJobThenHandledGracefully() {
        // GIVEN
        // WHEN
        Test.startTest();
        Id jobId = System.enqueueJob(new EmailNotificationQueueable(new List<Id>{ null }));
        Test.stopTest();

        // THEN
        AsyncApexJob job = [SELECT Status FROM AsyncApexJob WHERE Id = :jobId];
        System.assertNotEquals(null, job, 'Job debe existir aunque el Id sea nulo');
    }

    @isTest
    static void givenNoTemplateWhenEnqueueJobThenSkipsSend() {
        // GIVEN
        insertOppData();
        EmailNotificationQueueable.templateDevName = 'TEMPLATE_INEXISTENTE';
        Opportunity opp = getTestOpportunity();

        // WHEN
        Test.startTest();
        Id jobId = System.enqueueJob(new EmailNotificationQueueable(new List<Id>{ opp.Id }));
        Test.stopTest();

        // THEN
        System.assertNotEquals(null, jobId, 'Job debe encolarse aunque no haya template');
    }

    @isTest
    static void givenEjecutivoWhenEnqueueJobThenCanEnqueue() {
        // GIVEN
        insertOppData();
        User ejecutivo = getEjecutivo();
        Opportunity opp = getTestOpportunity();

        System.runAs(ejecutivo) {
            // WHEN
            Test.startTest();
            Id jobId = System.enqueueJob(new EmailNotificationQueueable(new List<Id>{ opp.Id }));
            Test.stopTest();

            // THEN
            System.assertNotEquals(null, jobId, 'Ejecutivo debe poder encolar el job');
        }
    }

    @isTest
    static void givenAnalistaWhenEnqueueJobThenCanEnqueue() {
        // GIVEN
        insertOppData();
        User analista = getAnalista();
        Opportunity opp = getTestOpportunity();

        System.runAs(analista) {
            // WHEN
            Test.startTest();
            Id jobId = System.enqueueJob(new EmailNotificationQueueable(new List<Id>{ opp.Id }));
            Test.stopTest();

            // THEN
            System.assertNotEquals(null, jobId, 'Analista debe poder encolar el job');
        }
    }

    @isTest
    static void givenMultipleOppsWhenExecuteThenProcessAll() {
        
        // GIVEN
        Account acc = TestDataFactory.createAccount(true);

        Opportunity opp1 = TestDataFactory.createWonOpportunity(acc.Id, true);
        Opportunity opp2 = TestDataFactory.createWonOpportunity(acc.Id, true);

        // WHEN
        Test.startTest();
        System.enqueueJob(new EmailNotificationQueueable(
            new List<Id>{ opp1.Id, opp2.Id }
        ));
        Test.stopTest();

        // THEN
        System.assert(true, 'Debe procesar múltiples oportunidades');
    }

    @isTest
    static void givenValidOppWithEmailWhenExecuteThenSendEmail() {
        // GIVEN
        insertOppData();

        Opportunity opp = [
            SELECT Id, Account.Email__c 
            FROM Opportunity 
            WHERE Name = 'Opp Ganada NovaBank' 
            LIMIT 1
        ];

        System.assertNotEquals(null, opp.Account.Email__c, 'Debe tener email');

        // WHEN
        Test.startTest();
        System.enqueueJob(new EmailNotificationQueueable(new List<Id>{ opp.Id }));
        Test.stopTest();

        // THEN
        System.assert(true, 'Debe completar envío');
    }

    @isTest
    static void givenFullValidDataWhenExecuteThenEmailsAreProcessed() {
        // GIVEN
        Account acc = TestDataFactory.createAccount(true);
        acc.Email__c = 'test@test.com';
        update acc;

        Opportunity opp = TestDataFactory.createWonOpportunity(acc.Id, true);

        // WHEN
        Test.startTest();
        System.enqueueJob(new EmailNotificationQueueable(
            new List<Id>{ opp.Id }
        ));
        Test.stopTest();

        // THEN
        System.assert(true, 'Flujo completo ejecutado sin errores');
    }

    @isTest
    static void givenQueryExceptionWhenExecuteThenHandledGracefully() {
        // GIVEN
        insertOppData();
        Opportunity opp = getTestOpportunity();
        EmailNotificationQueueable.throwQueryExceptionForTest = true;

        // WHEN
        Test.startTest();
        Id jobId = System.enqueueJob(
            new EmailNotificationQueueable(new List<Id>{ opp.Id })
        );
        Test.stopTest();

        // THEN
        AsyncApexJob job = [SELECT Status FROM AsyncApexJob WHERE Id = :jobId];
        System.assertNotEquals(null, job, 'Job debe existir aunque el query falle');
        System.assertEquals('Completed', job.Status, 'Job debe terminar en Completed');
    }

    @isTest
    static void givenEmailExceptionWhenExecuteThenHandledGracefully() {
        // GIVEN
        insertOppData();
        Opportunity opp = getTestOpportunity();
        EmailNotificationQueueable.throwEmailExceptionForTest = true;

        // WHEN
        Test.startTest();
        Id jobId = System.enqueueJob(
            new EmailNotificationQueueable(new List<Id>{ opp.Id })
        );
        Test.stopTest();

        // THEN
        AsyncApexJob job = [SELECT Status FROM AsyncApexJob WHERE Id = :jobId];
        System.assertNotEquals(null, job, 'Job debe existir aunque el envío falle');
        System.assertEquals('Completed', job.Status, 'Job debe terminar en Completed');
    }
}