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
        Product2 producto = new Product2(
            Name                   = 'Visa Oro',
            IsActive               = true,
            Card_Type__c           = 'Visa',
            Card_Category__c       = 'Oro',
            Minimum_Credit_Line__c = 1000,
            Maximum_Credit_Line__c = 5000,
            Interest_Rate__c       = 28.0,
            Sales_Channel__c       = 'Web'
        );
        insert producto;

        Lead lead = new Lead(
            FirstName              = 'Test',
            LastName               = 'Lead',
            Company                = 'NovaBank',
            Status                 = 'Inicio',
            MonthlyIncome__c       = 3000,
            RequestedCreditLine__c = 2000,
            Product__c             = producto.Id,
            DocumentType__c        = 'DNI',
            DocumentNumber__c      = '12345678',
            BirthDate__c           = Date.newInstance(1990, 1, 1),
            MaritalStatus__c       = 'Soltero/a',
            EmploymentStatus__c    = 'Dependiente'
        );
        insert lead;
    }

    /**
     * Given un Lead no convertido
     * When se consulta su Opportunity
     * Then retorna null
     */
    @isTest
    static void givenLeadNotConvertedWhenGetOpportunityThenReturnsNull() {
        // GIVEN
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        // WHEN
        Test.startTest();
        Id oppId = ConversionLead_Ctr.getConvertedOpportunityId(lead.Id);
        Test.stopTest();

        // THEN
        System.assertEquals(null, oppId,
            'Lead no convertido debe retornar null');
    }

    /**
     * Given un Lead convertido
     * When se consulta su Opportunity
     * Then retorna el Id correcto
     */
    @isTest
    static void givenLeadConvertedWhenGetOpportunityThenReturnsOppId() {
        // GIVEN
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

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

    /**
     * Given un Id nulo
     * When se consulta la Opportunity
     * Then lanza excepción controlada
     */
    @isTest
    static void givenNullIdWhenGetOpportunityThenThrowsException() {
        // GIVEN
        Id nullId = null;

        // WHEN
        Test.startTest();
        try {
            ConversionLead_Ctr.getConvertedOpportunityId(nullId);

            // THEN
            System.assert(false, 'Debió lanzar excepción');
        } catch (Exception e) {

            // THEN
            System.assert(true, 'Excepción manejada correctamente');
        }
        Test.stopTest();
    }
}