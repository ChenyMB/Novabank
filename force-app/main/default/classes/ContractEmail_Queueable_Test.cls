/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-16-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class ContractEmail_Queueable_Test {

    @TestSetup
    static void setupData() {
        User ejecutivo = TestDataFactory.buildUser( TestDataFactory.ROLE_EJECUTIVO, 'ejecutivo.contract@novabank.test.com');
        User analista = TestDataFactory.buildUser( TestDataFactory.ROLE_ANALISTA, 'analista.contract@novabank.test.com');
        User noAccess = TestDataFactory.buildUserNoAccess( 'noaccess.contract@novabank.test.com');
        insert new List<User>{ ejecutivo, analista, noAccess };
    }

    private static void insertContractData() {
        Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = TestDataFactory.createOpportunity(acc.Id, 'Contrato', true);
        TestDataFactory.createContentVersion(opp.Id, true);
    }

    private static Opportunity getTestOpportunity() {
        return [SELECT Id FROM Opportunity WHERE Name = 'Opp Test NovaBank' LIMIT 1];
    }

    private static User getEjecutivo() {
        return [SELECT Id FROM User WHERE Username = 'ejecutivo.contract@novabank.test.com'];
    }

    private static User getAnalista() {
        return [SELECT Id FROM User WHERE Username = 'analista.contract@novabank.test.com'];
    }

    private static User getNoAccessUser() {
        return [SELECT Id FROM User WHERE Username = 'noaccess.contract@novabank.test.com'];
    }

    @isTest
    static void givenOppWithContractWhenEnqueueThenJobCreated() {
        // GIVEN
        insertContractData();
        Opportunity opp = getTestOpportunity();

        // WHEN
        Test.startTest();
        Id jobId = System.enqueueJob(new ContractEmail_Queueable(opp.Id));
        Test.stopTest();

        // THEN
        System.assertNotEquals(null, jobId, 'Job debe retornar Id válido');
    }

    @isTest
    static void givenOppWithContractWhenEnqueueThenJobRegistered() {
        // GIVEN
        insertContractData();
        Opportunity opp = getTestOpportunity();

        // WHEN
        Test.startTest();
        Id jobId = System.enqueueJob(new ContractEmail_Queueable(opp.Id));
        Test.stopTest();

        // THEN — Id es único: sin LIMIT
        AsyncApexJob job = [
            SELECT ApexClass.Name, Status
            FROM   AsyncApexJob
            WHERE  Id = :jobId
        ];
        System.assertEquals('ContractEmail_Queueable', job.ApexClass.Name, 'Clase del job incorrecta');
        System.assert(
            job.Status == 'Completed' || job.Status == 'Queued' || job.Status == 'Processing',
            'Estado inválido: ' + job.Status
        );
    }

    @isTest
    static void givenOppIdWhenInvokeThenJobEnqueued() {
        // GIVEN
        insertContractData();
        Opportunity opp = getTestOpportunity();

        // WHEN
        Test.startTest();
        ContractEmail_Queueable.invoke(new List<Id>{ opp.Id });
        Test.stopTest();

        // THEN
        List<AsyncApexJob> jobs = [
            SELECT Id
            FROM   AsyncApexJob
            WHERE  ApexClass.Name = 'ContractEmail_Queueable'
        ];
        System.assert(jobs.size() >= 1, 'Debe encolarse al menos 1 job');
    }

    @isTest
    static void givenEmptyListWhenInvokeThenNoException() {
        // GIVEN / WHEN
        Test.startTest();
        try {
            ContractEmail_Queueable.invoke(new List<Id>());
            // THEN
            System.assert(true, 'Lista vacía no debe lanzar excepción');
        } catch (Exception e) {
            System.assert(false, 'No debió lanzar excepción: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void givenNullOppIdWhenEnqueueThenHandledGracefully() {
        // GIVEN / WHEN
        Test.startTest();
        Id jobId = System.enqueueJob(new ContractEmail_Queueable(null));
        Test.stopTest();

        // THEN: job se encola y ejecuta sin explotar
        AsyncApexJob job = [
            SELECT Status
            FROM   AsyncApexJob
            WHERE  Id = :jobId
        ];
        System.assertNotEquals(null, job, 'El job debe existir aunque el Id sea nulo');
    }

    @isTest
    static void givenOppWithoutContractWhenEnqueueThenHandledGracefully() {
        // GIVEN
        insertContractData();
        Account acc = [SELECT Id FROM Account WHERE Name = 'Francesca Moreno' LIMIT 1];
        Opportunity newOpp = TestDataFactory.createOpportunity(acc.Id, 'Contrato', true);

        // WHEN
        Test.startTest();
        Id jobId = System.enqueueJob(new ContractEmail_Queueable(newOpp.Id));
        Test.stopTest();

        // THEN
        AsyncApexJob job = [SELECT Status FROM AsyncApexJob WHERE Id = :jobId];
        System.assertNotEquals(null, job, 'El job debe existir aunque no haya contrato');
    }

    @isTest
    static void givenEjecutivoWhenEnqueueThenCanEnqueue() {
        // GIVEN
        insertContractData();
        User ejecutivo = getEjecutivo();
        Opportunity opp = getTestOpportunity();

        System.runAs(ejecutivo) {
            // WHEN
            Test.startTest();
            Id jobId = System.enqueueJob(new ContractEmail_Queueable(opp.Id));
            Test.stopTest();

            // THEN
            System.assertNotEquals(null, jobId, 'Ejecutivo debe poder encolar el job');
        }
    }

    @isTest
    static void givenAnalistaWhenEnqueueThenCanEnqueue() {
        // GIVEN
        insertContractData();
        User analista = getAnalista();
        Opportunity opp = getTestOpportunity();

        System.runAs(analista) {
            // WHEN
            Test.startTest();
            Id jobId = System.enqueueJob(new ContractEmail_Queueable(opp.Id));
            Test.stopTest();

            // THEN
            System.assertNotEquals(null, jobId, 'Analista debe poder encolar el job');
        }
    }

    @isTest
    static void givenUserWithNoAccessWhenEnqueueThenJobHandledGracefully() {
        // GIVEN
        insertContractData();
        User noAccess = getNoAccessUser();
        Opportunity opp = getTestOpportunity();

        System.runAs(noAccess) {
            // WHEN
            Test.startTest();
            Id jobId = System.enqueueJob(new ContractEmail_Queueable(opp.Id));
            Test.stopTest();

            // THEN
            AsyncApexJob job = [SELECT Status FROM AsyncApexJob WHERE Id = :jobId];
            System.assertNotEquals(null, job, 'Job debe existir aunque el usuario no tenga acceso');
        }
    }
}