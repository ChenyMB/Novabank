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

    private static Opportunity getTestOpp() {
        return [SELECT Id FROM Opportunity];
    }

    private static void setCurrentPage(Id oppId) {
        PageReference page = Page.Opportunity_Contract;
        if (oppId != null) {
            page.getParameters().put('id', oppId);
        }
        Test.setCurrentPage(page);
    }

    @isTest
    static void givenValidOppIdWhenConstructorThenOppLoaded() {
        // GIVEN
        Opportunity opp = getTestOpp();
        setCurrentPage(opp.Id);
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
        setCurrentPage(null);
        // WHEN
        Test.startTest();
        Opportunity_Contract_Ctr ctr = new Opportunity_Contract_Ctr();
        Test.stopTest();
        // THEN
        System.assertEquals(null, ctr.opp, 'Con Id nulo, opp debe ser null');
    }

    @isTest
    static void givenNoAccessWhenConstructorThenOppIsNull() {
        // GIVEN
        Opportunity opp = getTestOpp();
        setCurrentPage(opp.Id);
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

    @isTest
    static void givenValidOppIdWhenGenerarContratoThenContentVersionCreated() {
        // GIVEN
        Opportunity_Contract_Service.overridePdfBlob = Blob.valueOf('PDF simulado Ctr Test');
        Id oppId = getTestOpp().Id;
        // WHEN
        Test.startTest();
        Opportunity_Contract_Ctr.generarYAlmacenarContrato(oppId);
        Test.stopTest();
        // THEN
        List<ContentVersion> cvs = [SELECT Id, Title FROM ContentVersion];
        System.assertEquals(1, cvs.size(), 'Debe crearse 1 ContentVersion');
        System.assert(cvs[0].Title.containsIgnoreCase('Contrato'), 'Título debe contener Contrato');
    }

    @isTest
    static void givenValidOppIdWhenGenerarContratoThenLinkedToOpp() {
        // GIVEN
        Opportunity_Contract_Service.overridePdfBlob = Blob.valueOf('PDF simulado Ctr Test');
        Id oppId = getTestOpp().Id;
        // WHEN
        Test.startTest();
        Opportunity_Contract_Ctr.generarYAlmacenarContrato(oppId);
        Test.stopTest();
        // THEN
        ContentVersion cv = [SELECT ContentDocumentId FROM ContentVersion];
        List<ContentDocumentLink> links = [
            SELECT Id
            FROM   ContentDocumentLink
            WHERE  ContentDocumentId = :cv.ContentDocumentId
            AND    LinkedEntityId    = :oppId
        ];
        System.assertEquals(1, links.size(), 'Contrato debe estar vinculado a la Opportunity');
    }
}