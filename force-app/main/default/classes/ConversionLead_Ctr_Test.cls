/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-16-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class ConversionLead_Ctr_Test {

    @TestSetup
    static void setupData() {
        Lead lead = TestDataFactory.createLead(false);
        lead.DocumentType__c     = 'DNI';
        lead.DocumentNumber__c   = '12345678';
        lead.BirthDate__c        = Date.newInstance(1990, 1, 1);
        lead.MaritalStatus__c    = 'Soltero/a';
        lead.EmploymentStatus__c = 'Dependiente';
        insert lead;
    }

    private static Lead getTestLead() {
        return [SELECT Id FROM Lead WHERE LastName = 'Best' LIMIT 1];
    }

    @isTest
    static void givenLeadNotConvertedWhenGetOpportunityThenReturnsNull() {
        // GIVEN
        Lead lead = getTestLead();

        // WHEN
        Test.startTest();
        Id oppId = ConversionLead_Ctr.getConvertedOpportunityId(lead.Id);
        Test.stopTest();

        // THEN
        System.assertEquals(null, oppId, 'Lead no convertido debe retornar null');
    }

    @isTest
    static void givenLeadConvertedWhenGetOpportunityThenReturnsOppId() {
        // GIVEN
        Lead lead = getTestLead();

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead.Id);
        lc.setConvertedStatus('Closed - Converted');
        lc.setDoNotCreateOpportunity(false);
        Database.LeadConvertResult lcr = Database.convertLead(lc);

        // WHEN
        Test.startTest();
        Id oppId = ConversionLead_Ctr.getConvertedOpportunityId(lead.Id);
        Test.stopTest();

        // THEN
        System.assertNotEquals(null, oppId,
            'Lead convertido debe retornar Id de Opportunity');
        System.assertEquals(lcr.getOpportunityId(), oppId,
            'El Id retornado debe coincidir con la Opportunity creada');
    }

    @isTest
    static void givenNullIdWhenGetOpportunityThenThrowsException() {
        // GIVEN
        Boolean exceptionThrown = false;

        // WHEN
        Test.startTest();
        try {
            ConversionLead_Ctr.getConvertedOpportunityId(null);
        } catch (AuraHandledException e) {
            // THEN: verifica que el mensaje no es nulo
            exceptionThrown = true;
            System.assertNotEquals(null, e.getMessage(), 'El mensaje de error no debe ser nulo');
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Debió lanzar AuraHandledException con Id nulo');
    }

    @isTest
    static void givenNoAccessWhenGetOpportunityThenThrowsPermissionException() {
        // GIVEN
        User noAccess = TestDataFactory.buildUserNoAccess('noaccess.lead@novabank.test.com');
        insert noAccess;
        Lead lead = getTestLead();

        System.runAs(noAccess) {
            // WHEN
            Test.startTest();
            try {
                ConversionLead_Ctr.getConvertedOpportunityId(lead.Id);
                System.assert(false, 'Debió lanzar excepción de permisos');
            } catch (AuraHandledException e) {
                // THEN
                System.assertNotEquals(null, e.getMessage(), 'Debe haber mensaje de error de permisos');
            }
            Test.stopTest();
        }
    }
}