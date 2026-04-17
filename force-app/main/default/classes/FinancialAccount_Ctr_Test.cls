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

    private static Account getTestAccount() {
        return [SELECT Id FROM Account WHERE Name = 'Francesca Moreno'];
    }

    private static FinancialAccount__c getTestFA() {
        return [SELECT Id FROM FinancialAccount__c];
    }

    private static User crearEjecutivo(String username) {
        User u = TestDataFactory.buildUser(TestDataFactory.ROLE_EJECUTIVO, username);
        insert u;
        return u;
    }

    private static User crearAnalista(String username) {
        User u = TestDataFactory.buildUser(TestDataFactory.ROLE_ANALISTA, username);
        insert u;
        return u;
    }

    private static void asignarPS(Id userId, String psName) {
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = :psName];
        insert new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = ps.Id);
    }

    private static FinancialAccount__c buildFA(Id accountId) {
        return new FinancialAccount__c(
            Account__c            = accountId,
            CardNumber__c         = '4111222233334444',
            CardType__c           = 'Visa',
            ApprovedCreditLine__c = 4000,
            IssueDate__c          = Date.today(),
            CardStatus__c         = 'Activa'
        );
    }

    @isTest
    static void givenAccountWithFAWhenGetFAThenReturnsRecords() {
        // GIVEN
        Account acc = getTestAccount();
        // WHEN
        Test.startTest();
        List<FinancialAccount__c> result = FinancialAccount_Ctr.getFinancialAccounts(acc.Id);
        Test.stopTest();
        // THEN
        System.assertEquals(1, result.size(), 'Debe retornar 1 cuenta financiera');
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
    static void givenEjecutivoWhenGetFAThenCardNumberStripped() {
        // GIVEN
        User ejecutivo = crearEjecutivo('ejecutivo.strip@novabank.test.com');
        asignarPS(ejecutivo.Id, 'Sales_Management');
        Account accEjecutivo;
        System.runAs(ejecutivo) {
            accEjecutivo = TestDataFactory.createAccount(true);
            Opportunity opp = TestDataFactory.createWonOpportunity(accEjecutivo.Id, true);
            TestDataFactory.createFinancialAccount(accEjecutivo.Id, opp.Id, true);
        }
        // WHEN
        System.runAs(ejecutivo) {
            Test.startTest();
            List<FinancialAccount__c> result = FinancialAccount_Ctr.getFinancialAccounts(accEjecutivo.Id);
            Test.stopTest();
            // THEN
            System.assertEquals(1, result.size(), 'Ejecutivo ve sus registros');
            System.assert( !result[0].getPopulatedFieldsAsMap().containsKey('CardNumber__c'), 'CardNumber__c debe haber sido removido por stripInaccessible para el Ejecutivo'
            );
        }
    }

    @isTest
    static void givenAnalistaWhenGetFAThenCanAccess() {
        // GIVEN
        User analista = crearAnalista('analista.getfa@novabank.test.com');
        asignarPS(analista.Id, 'Post_Sale_Management');
        Account acc = getTestAccount();
        // WHEN
        System.runAs(analista) {
            Test.startTest();
            List<FinancialAccount__c> result = FinancialAccount_Ctr.getFinancialAccounts(acc.Id);
            Test.stopTest();
            // THEN
            System.assertNotEquals(null, result, 'Analista debe acceder a cuentas financieras');
        }
    }

    @isTest
    static void givenValidFAWhenCreateThenSavedCorrectly() {
        // GIVEN
        FinancialAccount__c newFa = buildFA(getTestAccount().Id);
        // WHEN
        Test.startTest();
        FinancialAccount__c created = FinancialAccount_Ctr.createFinancialAccount(newFa);
        Test.stopTest();
        // THEN — verificación desde DB
        FinancialAccount__c fromDb = [
            SELECT CardType__c, CardStatus__c
            FROM   FinancialAccount__c
            WHERE  Id = :created.Id
        ];
        System.assertEquals('Visa',   fromDb.CardType__c,   'Tipo debe ser Visa');
        System.assertEquals('Activa', fromDb.CardStatus__c, 'Estado debe ser Activa');
    }

    @isTest
    static void givenInvalidFAWhenCreateThenThrowsException() {
        // GIVEN
        Boolean exceptionThrown = false;
        // WHEN
        Test.startTest();
        try {
            FinancialAccount_Ctr.createFinancialAccount(new FinancialAccount__c());
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        // THEN
        System.assert(exceptionThrown, 'Debe lanzarse AuraHandledException');
    }

    @isTest
    static void givenUserWithoutCreateAccessWhenCreateFAThenThrowsException() {
        // GIVEN
        User userNoAccess = crearEjecutivo('noaccess.create@novabank.test.com');
        // WHEN
        System.runAs(userNoAccess) {
            Test.startTest();
            try {
                FinancialAccount_Ctr.createFinancialAccount(new FinancialAccount__c());
                System.assert(false, 'Debió lanzar excepción');
            } catch (AuraHandledException e) {
                // THEN
                System.assertNotEquals(null, e.getMessage(), 'Debe informar falta de permisos');
            }
            Test.stopTest();
        }
    }

    // ─── updateFinancialAccount ───────────────────────────────────────────────

    @isTest
    static void givenFAWhenUpdateStatusThenStatusChangedInDb() {
        // GIVEN
        FinancialAccount__c fa = getTestFA();
        fa.CardStatus__c = 'Bloqueada';
        // WHEN
        Test.startTest();
        FinancialAccount_Ctr.updateFinancialAccount(fa);
        Test.stopTest();
        // THEN
        FinancialAccount__c fromDb = [
            SELECT CardStatus__c
            FROM   FinancialAccount__c
            WHERE  Id = :fa.Id
        ];
        System.assertEquals('Bloqueada', fromDb.CardStatus__c, 'Estado debe persistir en DB');
    }

    @isTest
    static void givenFAWithoutIdWhenUpdateThenThrowsException() {
        // GIVEN
        Boolean exceptionThrown = false;
        // WHEN
        Test.startTest();
        try {
            FinancialAccount_Ctr.updateFinancialAccount(new FinancialAccount__c(CardStatus__c = 'Cancelada'));
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        // THEN
        System.assert(exceptionThrown, 'Debe lanzarse excepción sin Id');
    }

    @isTest
    static void givenUserWithoutUpdateAccessWhenUpdateFAThenThrowsException() {
        // GIVEN
        User userNoAccess = crearEjecutivo('noaccess.update@novabank.test.com');
        // WHEN
        System.runAs(userNoAccess) {
            Test.startTest();
            try {
                FinancialAccount_Ctr.updateFinancialAccount(new FinancialAccount__c());
                System.assert(false, 'Debió lanzar excepción');
            } catch (AuraHandledException e) {
                // THEN
                System.assertNotEquals(null, e.getMessage(), 'Debe informar falta de permisos');
            }
            Test.stopTest();
        }
    }

    @isTest
    static void givenFAWhenDeleteThenRemovedFromDb() {
        // GIVEN
        Id faId = getTestFA().Id;
        // WHEN
        Test.startTest();
        FinancialAccount_Ctr.deleteFinancialAccount(faId);
        Test.stopTest();
        // THEN
        System.assertEquals(
            0,
            [SELECT COUNT() FROM FinancialAccount__c WHERE Id = :faId],
            'Cuenta financiera debe eliminarse'
        );
    }

    @isTest
    static void givenNullIdWhenDeleteThenThrowsException() {
        // GIVEN
        Boolean exceptionThrown = false;
        // WHEN
        Test.startTest();
        try {
            FinancialAccount_Ctr.deleteFinancialAccount(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        // THEN
        System.assert(exceptionThrown, 'Debe lanzarse excepción con Id nulo');
    }

    @isTest
    static void givenAlreadyDeletedFAWhenDeleteThenCompletesWithoutError() {
        // GIVEN
        FinancialAccount__c fa = getTestFA();
        delete fa;
        // WHEN
        Test.startTest();
        try {
            FinancialAccount_Ctr.deleteFinancialAccount(fa.Id);
            // THEN
            System.assert(true, 'Debe completar sin error gracias al guard isEmpty');
        } catch (Exception e) {
            System.assert(false, 'No debe lanzar excepción: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void givenUserWithoutDeleteAccessWhenDeleteFAThenThrowsException() {
        // GIVEN
        User userNoAccess = crearEjecutivo('noaccess.delete@novabank.test.com');
        Id faId = getTestFA().Id;
        // WHEN
        System.runAs(userNoAccess) {
            Test.startTest();
            try {
                FinancialAccount_Ctr.deleteFinancialAccount(faId);
                System.assert(false, 'Debió lanzar excepción');
            } catch (AuraHandledException e) {
                // THEN
                System.assertNotEquals(null, e.getMessage(), 'Debe informar falta de permisos');
            }
            Test.stopTest();
        }
    }

    @isTest
    static void givenAnalistaWhenCanEditThenReturnsTrue() {
        // GIVEN
        User analista = crearAnalista('analista.canedit@novabank.test.com');
        asignarPS(analista.Id, 'Benefits_Access');
        // WHEN
        System.runAs(analista) {
            Test.startTest();
            Boolean result = FinancialAccount_Ctr.canEditFinancialAccounts();
            Test.stopTest();
            // THEN
            System.assertEquals(true, result, 'Analista con Benefits_Access debe poder editar');
        }
    }

    @isTest
    static void givenEjecutivoWhenCanEditThenReturnsFalse() {
        // GIVEN
        User ejecutivo = crearEjecutivo('ejecutivo.canedit@novabank.test.com');
        // WHEN
        System.runAs(ejecutivo) {
            Test.startTest();
            Boolean result = FinancialAccount_Ctr.canEditFinancialAccounts();
            Test.stopTest();
            // THEN
            System.assertEquals(false, result, 'Ejecutivo sin Benefits_Access no puede editar');
        }
    }
}