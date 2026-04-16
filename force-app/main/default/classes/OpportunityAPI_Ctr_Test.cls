/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-15-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class OpportunityAPI_Ctr_Test {

    @TestSetup
    static void setupData() {
        Account acc = TestDataFactory.createAccount(true);
        TestDataFactory.createWonOpportunity(acc.Id, true);
        TestDataFactory.createOpportunity(acc.Id, 'Inicio', true);

        User userNoAccess = TestDataFactory.buildUserNoAccess('noaccess.account.api@novabank.test.com');
        insert userNoAccess;
    }

    private static void setupRestContext(String clienteId) {
        RestRequest req  = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI   = '/services/apexrest/v1/clientes/' + clienteId + '/oportunidades-ganadas';
        req.httpMethod   = 'GET';
        RestContext.request  = req;
        RestContext.response = res;
    }

    private static OpportunityAPI_Ctr.ClienteResponse getResponse() {
        return (OpportunityAPI_Ctr.ClienteResponse) JSON.deserialize(
            RestContext.response.responseBody.toString(),
            OpportunityAPI_Ctr.ClienteResponse.class
        );
    }

    @isTest
    static void givenWonOppWhenGetOpsThenResponseStructureValid() {
        // GIVEN
        Account acc = [
            SELECT Id, Name 
            FROM Account LIMIT 1
        ];
        setupRestContext(acc.Id);
        // WHEN
        Test.startTest();
        OpportunityAPI_Ctr.getOportunidadesGanadas();
        Test.stopTest();
        // THEN
        OpportunityAPI_Ctr.ClienteResponse response = getResponse();
        System.assertEquals(200, RestContext.response.statusCode, 'Status debe ser 200');
        System.assertEquals(String.valueOf(acc.Id), response.clienteId, 'clienteId debe coincidir');
        System.assertNotEquals(null, response.oportunidadesGanadas, 'Lista no debe ser nula');
    }

    @isTest
    static void givenMixedOppsWhenGetOpsThenOnlyWonReturned() {
        // GIVEN
        Account acc = [
            SELECT Id 
            FROM Account 
            LIMIT 1
        ];
        setupRestContext(acc.Id);
        // WHEN
        Test.startTest();
        OpportunityAPI_Ctr.getOportunidadesGanadas();
        Test.stopTest();
        // THEN
        OpportunityAPI_Ctr.ClienteResponse response = getResponse();
        System.assertEquals(1, response.totalOportunidades,          'Solo 1 ganada');
        System.assertEquals(1, response.oportunidadesGanadas.size(), 'Lista con 1 elemento');
    }

    @isTest
    static void givenWonOppWhenGetOpsThenWrapperFieldsPopulated() {
        // GIVEN
        Account acc = [
            SELECT Id 
            FROM Account 
            LIMIT 1
        ];
        setupRestContext(acc.Id);
        // WHEN
        Test.startTest();
        OpportunityAPI_Ctr.getOportunidadesGanadas();
        Test.stopTest();
        // THEN
        OpportunityAPI_Ctr.ClienteResponse response = getResponse();
        OpportunityAPI_Ctr.OportunidadWrapper w = response.oportunidadesGanadas[0];
        System.assertNotEquals(null, w.oportunidadId, 'oportunidadId nulo');
        System.assertNotEquals(null, w.fechaCierre,   'fechaCierre nula');
    }

    @isTest
    static void givenMultipleWonOppsWhenGetOpsThenAllReturned() {
        // GIVEN
        Account acc = [
            SELECT Id 
            FROM Account 
            LIMIT 1
        ];
        TestDataFactory.createWonOpportunity(acc.Id, true);
        setupRestContext(acc.Id);
        // WHEN
        Test.startTest();
        OpportunityAPI_Ctr.getOportunidadesGanadas();
        Test.stopTest();
        // THEN
        OpportunityAPI_Ctr.ClienteResponse response = getResponse();
        System.assertEquals(2, response.totalOportunidades, '2 oportunidades ganadas');
    }

    @isTest
    static void givenAccountWithoutWonOppsWhenGetOpsThenEmptyList() {
        // GIVEN
        Account acc = TestDataFactory.createAccount(true);
        setupRestContext(acc.Id);
        // WHEN
        Test.startTest();
        OpportunityAPI_Ctr.getOportunidadesGanadas();
        Test.stopTest();
        // THEN
        OpportunityAPI_Ctr.ClienteResponse response = getResponse();
        System.assertEquals(0, response.totalOportunidades, 'Total debe ser 0');
    }

    @isTest
    static void givenInvalidIdWhenGetOpsThenReturns404() {
        // GIVEN
        setupRestContext('ID_INVALIDO');
        // WHEN
        Test.startTest();
        OpportunityAPI_Ctr.getOportunidadesGanadas();
        Test.stopTest();
        // THEN
        System.assertEquals(404, RestContext.response.statusCode, 'Debe retornar 404');
    }

    @isTest
    static void givenEjecutivoWhenGetOpsThenCanCallApi() {
        // GIVEN
        User ejecutivo = TestDataFactory.buildUser(TestDataFactory.ROLE_EJECUTIVO, 'ejecutivo.test.benefits@novabank.test.com');
        insert ejecutivo;
        Account acc = [
            SELECT Id 
            FROM Account 
            LIMIT 1
        ];
        // WHEN
        System.runAs(ejecutivo) {
            setupRestContext(acc.Id);
            Test.startTest();
            OpportunityAPI_Ctr.getOportunidadesGanadas();
            Test.stopTest();
            // THEN
            System.assertEquals(200, RestContext.response.statusCode, 'Ejecutivo debe recibir 200');
        }
    }

    @isTest
    static void givenAnalistaWhenGetOpsThenCanCallApi() {
        // GIVEN
        User analista = TestDataFactory.buildUser(TestDataFactory.ROLE_ANALISTA, 'analista.test.benefits@novabank.test.com');
        insert analista;
        Account acc = [
            SELECT Id 
            FROM Account 
            LIMIT 1
        ];
        // WHEN
        System.runAs(analista) {
            setupRestContext(acc.Id);
            Test.startTest();
            OpportunityAPI_Ctr.getOportunidadesGanadas();
            Test.stopTest();
            // THEN
            System.assertEquals(200, RestContext.response.statusCode, 'Analista debe recibir 200');
        }
    }

    @isTest
    static void givenUserWithoutAccountAccessWhenGetOpsThenReturns404() {
        // GIVEN
        User userNoAccess = [
            SELECT Id FROM User 
            WHERE Username = 'noaccess.account.api@novabank.test.com' 
            LIMIT 1
        ];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        System.runAs(userNoAccess) {
            setupRestContext(acc.Id);
            // WHEN
            Test.startTest();
            OpportunityAPI_Ctr.getOportunidadesGanadas();
            Test.stopTest();
            // THEN
            System.assertEquals(404, RestContext.response.statusCode, 
                'Sin acceso a Account debe retornar 404');
        }
    }

    @isTest
    static void givenUserWithoutOpportunityAccessWhenGetOpsThenReturns404() {
        // GIVEN
        User userNoAccess = TestDataFactory.buildUser(TestDataFactory.ROLE_EJECUTIVO, 'noaccess.opp.api@novabank.test.com');
        insert userNoAccess;
        PermissionSet ps = [
            SELECT Id 
            FROM PermissionSet 
            WHERE Name = 'Sales_Management' 
            LIMIT 1
        ];
        insert new PermissionSetAssignment(AssigneeId = userNoAccess.Id, PermissionSetId = ps.Id);

        Account acc = [SELECT Id FROM Account LIMIT 1];
        System.runAs(userNoAccess) {
            setupRestContext(acc.Id);
            // WHEN
            Test.startTest();
            OpportunityAPI_Ctr.getOportunidadesGanadas();
            Test.stopTest();
            // THEN
           System.assertEquals(200, RestContext.response.statusCode, 'Usuario con perfil base puede acceder a Account');
        }
    }

    @isTest
    static void givenNullURIWhenGetOpsThenReturns500() {
        // GIVEN
        RestContext.request  = null;
        RestContext.response = new RestResponse();
        // WHEN
        Test.startTest();
        OpportunityAPI_Ctr.getOportunidadesGanadas();
        Test.stopTest();
        // THEN
        System.assertEquals(500, RestContext.response.statusCode, 'Request nulo debe retornar 500');
    }
}