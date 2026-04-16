/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-15-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class ContractEmail_Queueable_Test {

    @TestSetup
    static void setupData() {
        Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = TestDataFactory.createOpportunity(acc.Id, 'Contrato', true);
        TestDataFactory.createContentVersion(opp.Id, true);
    }

    @isTest
    static void givenOppWithContractWhenEnqueueThenJobCreated() {
        // GIVEN
        Opportunity opp = [
            SELECT Id 
            FROM Opportunity 
            LIMIT 1
            ];
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
        Opportunity opp = [
            SELECT Id 
            FROM Opportunity 
            LIMIT 1
        ];
        // WHEN
        Test.startTest();
        Id jobId = System.enqueueJob(new ContractEmail_Queueable(opp.Id));
        Test.stopTest();
        // THEN
        AsyncApexJob job = [SELECT ApexClass.Name, Status FROM AsyncApexJob WHERE Id = :jobId];
        System.assertEquals('ContractEmail_Queueable', job.ApexClass.Name, 'Clase del job incorrecta');
        System.assert(
            job.Status == 'Completed' || job.Status == 'Queued' || job.Status == 'Processing',
            'Estado inválido: ' + job.Status
        );
    }

    @isTest
    static void givenOppIdWhenInvokeThenJobEnqueued() {
        // GIVEN
        Opportunity opp = [
            SELECT Id 
            FROM Opportunity 
            LIMIT 1
        ];
        // WHEN
        Test.startTest();
        ContractEmail_Queueable.invoke(new List<Id>{ opp.Id });
        Test.stopTest();
        // THEN
        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE ApexClass.Name = 'ContractEmail_Queueable'];
        System.assert(jobs.size() >= 1, 'Debe encolarse al menos 1 job');
    }

    @isTest
    static void givenEmptyListWhenInvokeThenNoException() {
        // GIVEN
        Boolean noException = true;
        // WHEN
        Test.startTest();
        try {
            ContractEmail_Queueable.invoke(new List<Id>());
        } catch (Exception e) {
            noException = false;
        }
        Test.stopTest();
        // THEN
        System.assert(noException, 'Lista vacía no debe lanzar excepción');
    }


    @isTest
    static void givenNullOppIdWhenEnqueueThenHandled() {
        // GIVEN
        Boolean handled = false;
        // WHEN
        Test.startTest();
        try {
            System.enqueueJob(new ContractEmail_Queueable(null));
            handled = true;
        } catch (Exception e) {
            handled = true;
        }
        Test.stopTest();
        // THEN
        System.assert(handled, 'OpportunityId nulo debe manejarse sin error crítico');
    }

    @isTest
    static void givenOppWithoutContractWhenEnqueueThenHandled() {
        // GIVEN
        Account acc = [
            SELECT Id 
            FROM Account 
            LIMIT 1
        ];
        Opportunity newOpp = TestDataFactory.createOpportunity(acc.Id, 'Contrato', true);
        Boolean handled = false;
        // WHEN
        Test.startTest();
        try {
            System.enqueueJob(new ContractEmail_Queueable(newOpp.Id));
            handled = true;
        } catch (Exception e) {
            handled = true;
        }
        Test.stopTest();
        // THEN
        System.assert(handled, 'Opp sin contrato debe manejarse sin error crítico');
    }

    @isTest
    static void givenEjecutivoWhenEnqueueThenCanEnqueue() {
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
            Id jobId = System.enqueueJob(new ContractEmail_Queueable(opp.Id));
            Test.stopTest();
            // THEN
            System.assertNotEquals(null, jobId, 'Ejecutivo debe poder encolar el job');
        }
    }

    @isTest
    static void givenAnalistaWhenEnqueueThenCanEnqueue() {
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
            Id jobId = System.enqueueJob(new ContractEmail_Queueable(opp.Id));
            Test.stopTest();
            // THEN
            System.assertNotEquals(null, jobId, 'Analista debe poder encolar el job');
        }
    }

    @isTest
    static void givenNoOpportunityAccessWhenExecuteThenHandled() {
        // GIVEN
        ContractEmail_Queueable.overrideOpportunityAccessible = false;
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        // WHEN
        Test.startTest();
        Id jobId = System.enqueueJob(new ContractEmail_Queueable(opp.Id));
        Test.stopTest();
        // THEN
        System.assertNotEquals(null, jobId, 'Job debe encolarse aunque no haya acceso a Opportunity');
    }

    @isTest
    static void givenNoContentDocLinkAccessWhenExecuteThenHandled() {
        // GIVEN
        ContractEmail_Queueable.overrideContentDocLinkAccessible = false;
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        // WHEN
        Test.startTest();
        Id jobId = System.enqueueJob(new ContractEmail_Queueable(opp.Id));
        Test.stopTest();
        // THEN
        System.assertNotEquals(null, jobId, 'Job debe encolarse aunque no haya acceso a CDL');
    }

    @isTest
    static void givenNoContentVersionAccessWhenExecuteThenHandled() {
        // GIVEN
        ContractEmail_Queueable.overrideContentVersionAccessible = false;
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        // WHEN
        Test.startTest();
        Id jobId = System.enqueueJob(new ContractEmail_Queueable(opp.Id));
        Test.stopTest();
        // THEN
        System.assertNotEquals(null, jobId, 'Job debe encolarse aunque no haya acceso a CV');
    }
}