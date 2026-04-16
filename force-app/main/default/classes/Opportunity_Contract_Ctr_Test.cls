/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-16-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class Opportunity_Contract_Ctr_Test {

    @TestSetup
    static void setupData() {
        Account acc = TestDataFactory.createAccount(true);
        TestDataFactory.createOpportunity(acc.Id, 'Contrato', true);
    }

    @isTest
    static void givenValidOppIdWhenConstructorThenOppLoaded() {
        // GIVEN
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PageReference page = Page.Opportunity_Contract;
        page.getParameters().put('id', opp.Id);
        Test.setCurrentPage(page);

        // WHEN
        Test.startTest();
        Opportunity_Contract_Ctr ctr = new Opportunity_Contract_Ctr();
        Test.stopTest();

        // THEN
        System.assertNotEquals(null, ctr.opp, 'Opp debe cargarse correctamente');
        System.assertEquals(opp.Id, ctr.opp.Id, 'Id debe coincidir');
    }

    @isTest
    static void givenNullOppIdWhenConstructorThenOppIsNull() {
        // GIVEN
        PageReference page = Page.Opportunity_Contract;
        Test.setCurrentPage(page);

        // WHEN
        Test.startTest();
        Opportunity_Contract_Ctr ctr = new Opportunity_Contract_Ctr();
        Test.stopTest();

        // THEN
        System.assertEquals(null, ctr.opp, 'Con Id nulo, opp debe ser null');
    }

    @isTest
    static void givenValidOppIdWhenGenerarContratThenContentVersionCreated() {
        // GIVEN
        Opportunity_Contract_Service.overridePdfBlob = Blob.valueOf('PDF simulado Ctr Test');
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        // WHEN
        Test.startTest();
        Opportunity_Contract_Ctr.generarYAlmacenarContrato(opp.Id);
        Test.stopTest();

        // THEN
        List<ContentVersion> cvs = [SELECT Id, Title FROM ContentVersion];
        System.assertEquals(1, cvs.size(), 'Debe crearse 1 ContentVersion');
        System.assert(cvs[0].Title.containsIgnoreCase('Contrato'), 'Título debe contener Contrato');
    }

    @isTest
    static void givenValidOppIdWhenGenerarContratThenLinkedToOpp() {
        // GIVEN
        Opportunity_Contract_Service.overridePdfBlob = Blob.valueOf('PDF simulado Ctr Test');
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        // WHEN
        Test.startTest();
        Opportunity_Contract_Ctr.generarYAlmacenarContrato(opp.Id);
        Test.stopTest();

        // THEN
        ContentVersion cv = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];
        List<ContentDocumentLink> links = [
            SELECT Id FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
            AND   LinkedEntityId    = :opp.Id
        ];
        System.assertEquals(1, links.size(), 'Contrato debe estar vinculado a la Opportunity');
    }

    @isTest
    static void givenNoAccessWhenConstructorThenOppIsNull() {
        // GIVEN
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PageReference page = Page.Opportunity_Contract;
        page.getParameters().put('id', opp.Id);
        Test.setCurrentPage(page);

        User noAccess = TestDataFactory.buildUserNoAccess('noaccess.ctr@novabank.test.com');
        insert noAccess;

        // WHEN
        System.runAs(noAccess) {
            Test.startTest();
            Opportunity_Contract_Ctr ctr = new Opportunity_Contract_Ctr();
            Test.stopTest();

            // THEN
            System.assertEquals(null, ctr.opp, 'Sin acceso opp debe ser null');
        }
    }
}