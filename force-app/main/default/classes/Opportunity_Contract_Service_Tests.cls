/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-16-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class Opportunity_Contract_Service_Tests {

    @TestSetup
    static void setupData() {
        Opportunity_Contract_Service.overridePdfBlob = Blob.valueOf('PDF simulado para tests');
        Account acc = TestDataFactory.createAccount(true);
        TestDataFactory.createOpportunity(acc.Id, 'Contrato', true);
    }

    @isTest
    static void givenValidOppWhenGenerateThenContentVersionCreated() {
        // GIVEN
        Opportunity_Contract_Service.overridePdfBlob = Blob.valueOf('PDF simulado para tests');

        Opportunity opp = [
            SELECT Id 
            FROM Opportunity 
            LIMIT 1
        ];
        // WHEN
        Test.startTest();
        Opportunity_Contract_Service.generateAndStoreContract(opp.Id);
        Test.stopTest();
        // THEN
        List<ContentVersion> cvs = [SELECT Id, Title FROM ContentVersion];
        System.assertEquals(1, cvs.size(), 'Debe crearse 1 ContentVersion');
        System.assert(cvs[0].Title.containsIgnoreCase('Contrato'), 'Título debe contener Contrato');
    }

    @isTest
    static void givenValidOppWhenGenerateThenVersionDataPopulated() {
        // GIVEN
        Opportunity_Contract_Service.overridePdfBlob = Blob.valueOf('PDF simulado para tests');

        Opportunity opp = [
            SELECT Id 
            FROM Opportunity 
            LIMIT 1
        ];
        // WHEN
        Test.startTest();
        Opportunity_Contract_Service.generateAndStoreContract(opp.Id);
        Test.stopTest();
        // THEN
        ContentVersion cv = [SELECT VersionData FROM ContentVersion LIMIT 1];
        System.assertNotEquals(null, cv.VersionData, 'VersionData no debe ser nulo');
        System.assert(cv.VersionData.size() > 0, 'VersionData debe tener contenido');
    }

    @isTest
    static void givenValidOppWhenGenerateThenLinkedToOpportunity() {
        // GIVEN
        Opportunity_Contract_Service.overridePdfBlob = Blob.valueOf('PDF simulado para tests');
    
        Opportunity opp = [
            SELECT Id 
            FROM Opportunity 
            LIMIT 1
        ];
        // WHEN
        Test.startTest();
        Opportunity_Contract_Service.generateAndStoreContract(opp.Id);
        Test.stopTest();
        // THEN
        ContentVersion cv = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];
        List<ContentDocumentLink> links = [
            SELECT Id FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
            AND LinkedEntityId = :opp.Id
        ];
        System.assertEquals(1, links.size(), 'PDF debe estar vinculado a la Opportunity');
    }

    @isTest
    static void givenValidOppWhenGenerateThenExtensionIsPdf() {
        // GIVEN
        Opportunity_Contract_Service.overridePdfBlob = Blob.valueOf('PDF simulado para tests');
    
        Opportunity opp = [
            SELECT Id 
            FROM Opportunity 
            LIMIT 1
        ];
        // WHEN
        Test.startTest();
        Opportunity_Contract_Service.generateAndStoreContract(opp.Id);
        Test.stopTest();
        // THEN
        ContentVersion cv = [SELECT PathOnClient FROM ContentVersion LIMIT 1];
        System.assert(cv.PathOnClient.endsWith('.pdf'), 'Extensión debe ser .pdf');
    }

    @isTest
    static void givenNullOppIdWhenGenerateThenThrowsException() {
        // GIVEN
        Boolean exceptionThrown = false;
        // WHEN
        Test.startTest();
        try {
            Opportunity_Contract_Service.generateAndStoreContract(null);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        // THEN
        System.assert(exceptionThrown, 'Debe lanzarse excepción con Id nulo');
    }

    @isTest
    static void givenNoContentVersionCreatePermWhenGenerateThenThrowsException() {
        // GIVEN
        Opportunity_Contract_Service.overridePdfBlob = Blob.valueOf('PDF simulado');
        Opportunity_Contract_Service.overrideContentVersionCreateable = false;
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        // WHEN
        Test.startTest();
        try {
            Opportunity_Contract_Service.generateAndStoreContract(opp.Id);
            System.assert(false, 'Debió lanzar excepción');
        } catch (AuraHandledException e) {
            // THEN
            System.assertNotEquals(null, e.getMessage(), 'Debe lanzar excepción sin permiso CV');
        }
        Test.stopTest();
    }

    @isTest
    static void givenNoContentVersionAccessPermWhenGenerateThenThrowsException() {
        // GIVEN
        Opportunity_Contract_Service.overridePdfBlob = Blob.valueOf('PDF simulado');
        Opportunity_Contract_Service.overrideContentVersionAccessible = false;
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        // WHEN
        Test.startTest();
        try {
            Opportunity_Contract_Service.generateAndStoreContract(opp.Id);
            System.assert(false, 'Debió lanzar excepción');
        } catch (AuraHandledException e) {
            // THEN
            System.assertNotEquals(null, e.getMessage(), 'Debe lanzar excepción sin acceso CV');
        }
        Test.stopTest();
    }

    @isTest
    static void givenNoContentDocLinkCreatePermWhenGenerateThenThrowsException() {
        // GIVEN
        Opportunity_Contract_Service.overridePdfBlob = Blob.valueOf('PDF simulado');
        Opportunity_Contract_Service.overrideContentDocumentLinkCreateable = false;
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        // WHEN
        Test.startTest();
        try {
            Opportunity_Contract_Service.generateAndStoreContract(opp.Id);
            System.assert(false, 'Debió lanzar excepción');
        } catch (AuraHandledException e) {
            // THEN
            System.assertNotEquals(null, e.getMessage(), 'Debe lanzar excepción sin permiso CDL');
        }
        Test.stopTest();
    }

    @isTest
    static void givenInvalidContentVersionWhenInsertThenThrowsDmlException() {
        // GIVEN
        Opportunity_Contract_Service.overridePdfBlob = Blob.valueOf('');
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        try {
            Opportunity_Contract_Service.overridePdfBlob = Blob.valueOf('x');
            Opportunity_Contract_Service.generateAndStoreContract(opp.Id);
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }
}