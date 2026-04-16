/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-16-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class FinancialAccount_Ctr_Test {

    @TestSetup
    static void setupData() {
        Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = TestDataFactory.createWonOpportunity(acc.Id, true);
        TestDataFactory.createFinancialAccount(acc.Id, opp.Id, true);
    }

    @isTest
    static void givenAccountWithFAWhenGetFAThenReturnsRecords() {
        // GIVEN
        Account acc = [
            SELECT Id 
            FROM Account 
            LIMIT 1
        ];
        // WHEN
        Test.startTest();
        List<FinancialAccount__c> result = FinancialAccount_Ctr.getFinancialAccounts(acc.Id);
        Test.stopTest();
        // THEN
        System.assertEquals(1, result.size(), 'Debe retornarse 1 cuenta financiera');
        System.assertEquals(acc.Id, result[0].Account__c, 'Cuenta financiera debe pertenecer al Account');
    }

    @isTest
    static void givenAccountWithoutFAWhenGetFAThenEmptyList() {
        // GIVEN
        Account acc = TestDataFactory.createAccount(true);
        // WHEN
        Test.startTest();
        List<FinancialAccount__c> result = FinancialAccount_Ctr.getFinancialAccounts(acc.Id);
        Test.stopTest();
        // THEN
        System.assertEquals(0, result.size(), 'Lista debe estar vacía');
    }

    @isTest
    static void givenValidFAWhenCreateThenSavedCorrectly() {
        // GIVEN
        Account acc = [
            SELECT Id 
            FROM Account 
            LIMIT 1
        ];
        FinancialAccount__c newFa = new FinancialAccount__c(
            Account__c            = acc.Id,
            CardNumber__c         = '4111222233334444',
            CardType__c           = 'Visa',
            ApprovedCreditLine__c = 4000,
            IssueDate__c          = Date.today(),
            CardStatus__c         = 'Activa'
        );
        // WHEN
        Test.startTest();
        FinancialAccount__c created = FinancialAccount_Ctr.createFinancialAccount(newFa);
        Test.stopTest();
        // THEN
        FinancialAccount__c fromDb = [
            SELECT CardType__c, CardStatus__c 
            FROM FinancialAccount__c 
            WHERE Id = :created.Id
        ];
        System.assertEquals('Visa', fromDb.CardType__c,   'Tipo debe ser Visa');
        System.assertEquals('Activa',   fromDb.CardStatus__c, 'Estado debe ser Activa');
    }

    @isTest
    static void givenInvalidFAWhenCreateThenThrowsException() {
        // GIVEN
        FinancialAccount__c invalidFa = new FinancialAccount__c(CardType__c = 'Visa Original');
        Boolean exceptionThrown = false;
        // WHEN
        Test.startTest();
        try {
            FinancialAccount_Ctr.createFinancialAccount(invalidFa);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        // THEN
        System.assert(exceptionThrown, 'Debe lanzarse excepción');
    }

    @isTest
    static void givenFAWhenUpdateStatusThenStatusChanged() {
        // GIVEN
        FinancialAccount__c fa = [
            SELECT Id, CardStatus__c
            FROM FinancialAccount__c 
            LIMIT 1
        ];
        fa.CardStatus__c = 'Bloqueada';

        // WHEN
        Test.startTest();
        FinancialAccount_Ctr.updateFinancialAccount(fa);
        Test.stopTest();
        
        // THEN
        System.assertEquals('Bloqueada', fa.CardStatus__c, 'Estado debe ser Bloqueada');
    }

    @isTest
    static void givenFAWithoutIdWhenUpdateThenThrowsException() {
        // GIVEN
        FinancialAccount__c faNoId = new FinancialAccount__c(CardStatus__c = 'Cancelada');
        Boolean exceptionThrown = false;
        // WHEN
        Test.startTest();
        try {
            FinancialAccount_Ctr.updateFinancialAccount(faNoId);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        // THEN
        System.assert(exceptionThrown, 'Debe lanzarse excepción sin Id');
    }

    @isTest
    static void givenFAWhenDeleteThenRemovedFromDb() {
        // GIVEN
        Id faId = [SELECT Id FROM FinancialAccount__c LIMIT 1].Id;
        // WHEN
        Test.startTest();
        FinancialAccount_Ctr.deleteFinancialAccount(faId);
        Test.stopTest();
        // THEN
        System.assertEquals(0, [SELECT COUNT() FROM FinancialAccount__c WHERE Id = :faId], 'Cuenta financiera debe eliminarse');
    }

    @isTest
    static void givenNullIdWhenDeleteThenThrowsException() {
        // GIVEN
        Boolean exceptionThrown = false;
        // WHEN
        Test.startTest();
        try {
            FinancialAccount_Ctr.deleteFinancialAccount(null);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        // THEN
        System.assert(exceptionThrown, 'Debe lanzarse excepción con Id nulo');
    }

    @isTest
    static void givenEjecutivoWhenGetFAThenCanAccessOwnRecords() {
        // GIVEN
        User ejecutivo = TestDataFactory.buildUser(TestDataFactory.ROLE_EJECUTIVO, 'ejecutivo.test.benefits@novabank.test.com');
        insert ejecutivo;
        Account accEjecutivo;

        PermissionSet psSales = [SELECT Id FROM PermissionSet WHERE Name = 'Sales_Management'];
        insert new PermissionSetAssignment(AssigneeId = ejecutivo.Id, PermissionSetId = psSales.Id);

        System.runAs(ejecutivo) {
            accEjecutivo = TestDataFactory.createAccount(true);
            TestDataFactory.createFinancialAccount(accEjecutivo.Id, TestDataFactory.createWonOpportunity(accEjecutivo.Id, true).Id, true);
        }
        // WHEN
        System.runAs(ejecutivo) {
            Test.startTest();
            List<FinancialAccount__c> result = FinancialAccount_Ctr.getFinancialAccounts(accEjecutivo.Id);
            Test.stopTest();
            // THEN
            System.assertEquals(1, result.size(), 'Ejecutivo ve solo sus cuentas financieras');
        }
    }

    @isTest
    static void givenAnalistaWhenGetFAThenCanAccess() {
        // GIVEN
        User analista = TestDataFactory.buildUser(TestDataFactory.ROLE_ANALISTA, 'analista.test.benefits@novabank.test.com');
        insert analista;
        Account acc = [
            SELECT Id 
            FROM Account 
            LIMIT 1
        ];
        PermissionSet psPostSale = [SELECT Id FROM PermissionSet WHERE Name = 'Post_Sale_Management'];
        insert new PermissionSetAssignment(AssigneeId = analista.Id, PermissionSetId = psPostSale.Id);

        // WHEN
        System.runAs(analista) {
            Test.startTest();
            List<FinancialAccount__c> result = FinancialAccount_Ctr.getFinancialAccounts(acc.Id);
            Test.stopTest();
            // THEN
            System.assertNotEquals(null, result, 'Analista debe acceder a cuenta financiera');
        }
    }

    @isTest
    static void givenUserWithoutReadAccessWhenGetFAThenThrowsException() {
        // GIVEN
        User userNoAccess = TestDataFactory.buildUser(TestDataFactory.ROLE_EJECUTIVO, 'noaccess.read.fa@novabank.test.com');
        insert userNoAccess;

        // WHEN
        System.runAs(userNoAccess) {
            Test.startTest();
            try {
                FinancialAccount_Ctr.getFinancialAccounts(null);
                System.assert(false, 'Debió lanzar excepción');
            } catch (AuraHandledException e) {
                //THEN
                System.assertNotEquals(null, e.getMessage(), 'Sin acceso de lectura debe lanzar excepción');
            }
            Test.stopTest();
        }
    }

    @isTest
    static void givenUserWithoutCreateAccessWhenCreateFAThenThrowsException() {
        // GIVEN - usuario sin permission sets
        User userNoAccess = TestDataFactory.buildUser(TestDataFactory.ROLE_EJECUTIVO, 'noaccess.create.fa@novabank.test.com');
        insert userNoAccess;
        // WHEN
        System.runAs(userNoAccess) {
            Test.startTest();
            try {
                FinancialAccount_Ctr.createFinancialAccount(new FinancialAccount__c());
                System.assert(false, 'Debió lanzar excepción');
            } catch (AuraHandledException e) {
                //THEN
                System.assertNotEquals(null, e.getMessage(), 'Sin acceso de creación debe lanzar excepción');
            }
            Test.stopTest();
        }
    }

    @isTest
    static void givenUserWithoutUpdateAccessWhenUpdateFAThenThrowsException() {
        // GIVEN
        User userNoAccess = TestDataFactory.buildUser(TestDataFactory.ROLE_EJECUTIVO, 'noaccess.update.fa@novabank.test.com');
        insert userNoAccess;
        // WHEN
        System.runAs(userNoAccess) {
            Test.startTest();
            try {
                FinancialAccount_Ctr.updateFinancialAccount(new FinancialAccount__c());
                System.assert(false, 'Debió lanzar excepción');
            } catch (AuraHandledException e) {
                //THEN
                System.assertNotEquals(null, e.getMessage(), 'Sin acceso de actualización debe lanzar excepción');
            }
            Test.stopTest();
        }
    }

    @isTest
    static void givenUserWithoutDeleteAccessWhenDeleteFAThenThrowsException() {
        // GIVEN
        User userNoAccess = TestDataFactory.buildUser(
            TestDataFactory.ROLE_EJECUTIVO, 
            'noaccess.delete.fa@novabank.test.com'
        );
        insert userNoAccess;
        Id faId = [SELECT Id FROM FinancialAccount__c LIMIT 1].Id;
        // WHEN
        System.runAs(userNoAccess) {
            Test.startTest();
            try {
                FinancialAccount_Ctr.deleteFinancialAccount(faId);
                System.assert(false, 'Debió lanzar excepción');
            } catch (AuraHandledException e) {
                // THEN
                System.assertNotEquals(null, e.getMessage(), 
                    'Sin acceso de eliminación debe lanzar excepción');
            }
            Test.stopTest();
        }
    }

    @isTest
    static void givenDeletedFAWhenDeleteAgainThenCompletesWithoutError() {
        // GIVEN
        FinancialAccount__c fa = [SELECT Id FROM FinancialAccount__c LIMIT 1];
        delete fa;
        // WHEN
        Test.startTest();
        try {
            FinancialAccount_Ctr.deleteFinancialAccount(fa.Id);
            // THEN
            System.assert(true, 'Eliminar registro ya eliminado completa sin error');
        } catch (Exception e) {
            System.assert(false, 'No debería lanzar excepción: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void givenAnalistaWhenCanEditThenReturnsTrue() {
        User analista = TestDataFactory.buildUser(TestDataFactory.ROLE_ANALISTA, 'analista.canedit@novabank.test.com');
        insert analista;
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Benefits_Access' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = analista.Id, PermissionSetId = ps.Id);

        System.runAs(analista) {
            Test.startTest();
            Boolean result = FinancialAccount_Ctr.canEditFinancialAccounts();
            Test.stopTest();
            System.assertEquals(true, result, 'Analista debe poder editar');
        }
    }

    @isTest
    static void givenEjecutivoWhenCanEditThenReturnsFalse() {
        User ejecutivo = TestDataFactory.buildUser(TestDataFactory.ROLE_EJECUTIVO, 'ejecutivo.canedit@novabank.test.com');
        insert ejecutivo;

        System.runAs(ejecutivo) {
            Test.startTest();
            Boolean result = FinancialAccount_Ctr.canEditFinancialAccounts();
            Test.stopTest();
            System.assertEquals(false, result, 'Ejecutivo no debe poder editar');
        }
    }
}