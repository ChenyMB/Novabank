/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-16-2026
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
        User ejecutivo    = TestDataFactory.buildUser(TestDataFactory.ROLE_EJECUTIVO, 'ejecutivo.api@novabank.test.com');
        User analista     = TestDataFactory.buildUser(TestDataFactory.ROLE_ANALISTA,  'analista.api@novabank.test.com');
        insert new List<User>{ userNoAccess, ejecutivo, analista };
    }

    private static User getEjecutivo() {
    return [SELECT Id FROM User WHERE Username = 'ejecutivo.api@novabank.test.com'];
    }

    private static User getAnalista() {
        return [SELECT Id FROM User WHERE Username = 'analista.api@novabank.test.com'];
    }

    private static User getUserNoAccess() {
        return [SELECT Id FROM User WHERE Username = 'noaccess.account.api@novabank.test.com'];
    }

    private static Account getTestAccount() {
        return [SELECT Id, Name FROM Account WHERE Name = 'Francesca Moreno'];
    }

    private static User getUserByUsername(String username) {
        return [SELECT Id FROM User WHERE Username = :username];
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
        Account acc = getTestAccount();
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
        // GIVEN — setup tiene 1 ganada + 1 en Inicio
        setupRestContext(getTestAccount().Id);
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
        setupRestContext(getTestAccount().Id);
        // WHEN
        Test.startTest();
        OpportunityAPI_Ctr.getOportunidadesGanadas();
        Test.stopTest();
        // THEN
        OpportunityAPI_Ctr.OportunidadWrapper w = getResponse().oportunidadesGanadas[0];
        System.assertNotEquals(null, w.oportunidadId, 'oportunidadId no debe ser nulo');
        System.assertNotEquals(null, w.fechaCierre,   'fechaCierre no debe ser nula');
    }

    @isTest
    static void givenMultipleWonOppsWhenGetOpsThenAllReturned() {
        // GIVEN
        Account acc = getTestAccount();
        TestDataFactory.createWonOpportunity(acc.Id, true);
        setupRestContext(acc.Id);
        // WHEN
        Test.startTest();
        OpportunityAPI_Ctr.getOportunidadesGanadas();
        Test.stopTest();
        // THEN
        System.assertEquals(2, getResponse().totalOportunidades, 'Debe retornar 2 oportunidades ganadas');
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
        System.assertEquals(0, getResponse().totalOportunidades, 'Total debe ser 0');
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
    static void givenUserWithoutAccountAccessWhenGetOpsThenReturns404() {
        // GIVEN
        System.runAs(getUserNoAccess()) {
            setupRestContext(getTestAccount().Id);
            // WHEN
            Test.startTest();
            OpportunityAPI_Ctr.getOportunidadesGanadas();
            Test.stopTest();
            // THEN
            System.assertEquals(404, RestContext.response.statusCode, 'Sin acceso debe retornar 404');
        }
    }

    @isTest
    static void givenNullRequestWhenGetOpsThenReturns500() {
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

    @isTest
    static void givenEjecutivoWhenGetOpsThenReturns200() {
        // GIVEN
        System.runAs(getEjecutivo()) {
            setupRestContext(getTestAccount().Id);
            // WHEN
            Test.startTest();
            OpportunityAPI_Ctr.getOportunidadesGanadas();
            Test.stopTest();
            // THEN
            System.assertEquals(200, RestContext.response.statusCode, 'Ejecutivo debe recibir 200');
        }
    }

    @isTest
    static void givenAnalistaWhenGetOpsThenReturns200() {
        // GIVEN
        System.runAs(getAnalista()) {
            setupRestContext(getTestAccount().Id);
            // WHEN
            Test.startTest();
            OpportunityAPI_Ctr.getOportunidadesGanadas();
            Test.stopTest();
            // THEN
            System.assertEquals(200, RestContext.response.statusCode, 'Analista debe recibir 200');
        }
    }

    
}