/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-16-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class Benefits_Ctr_Test {

    @TestSetup
    static void setupData() {

        User ejecutivo = TestDataFactory.buildUser( TestDataFactory.ROLE_EJECUTIVO, 'ejecutivo.test.benefits@novabank.test.com');
        User analista = TestDataFactory.buildUser( TestDataFactory.ROLE_ANALISTA, 'analista.test.benefits@novabank.test.com');

        insert new List<User>{ ejecutivo, analista };

        PermissionSet psAccess = [
            SELECT Id FROM PermissionSet WHERE Name = 'Benefits_Access'
        ];
        PermissionSet psPostSale = [
            SELECT Id FROM PermissionSet WHERE Name = 'Post_Sale_Management'
        ];

        insert new List<PermissionSetAssignment>{
            new PermissionSetAssignment(AssigneeId = analista.Id, PermissionSetId = psAccess.Id),
            new PermissionSetAssignment(AssigneeId = analista.Id, PermissionSetId = psPostSale.Id)
        };
    }

    private static User getEjecutivo() {
        return [SELECT Id FROM User WHERE Username = 'ejecutivo.test.benefits@novabank.test.com'];
    }

    private static User getAnalista() {
        return [SELECT Id FROM User WHERE Username = 'analista.test.benefits@novabank.test.com'];
    }

    private static void insertBenefitsData() {
        Benefits__c infinite = TestDataFactory.createBenefit(false);
        infinite.CardName__c = 'Visa Infinite';
        infinite.Priority__c = 1;

        Benefits__c oro = TestDataFactory.createBenefit(false);
        oro.CardName__c = 'Visa Oro';
        oro.Priority__c = 2;

        Benefits__c plata = TestDataFactory.createBenefit(false);

        Benefits__c inactiva = TestDataFactory.createBenefit(false);
        inactiva.Priority__c = 99;
        inactiva.Status__c   = 'Inactivo';

        insert new List<Benefits__c>{ infinite, oro, plata, inactiva };
    }


    @isTest
    static void givenActiveBenefitsWhenGetBenefitsThenReturnsOnlyActive() {
        // GIVEN
        insertBenefitsData();

        // WHEN
        Test.startTest();
        List<Benefits__c> result = Benefits_Ctr.getBenefits();
        Test.stopTest();

        // THEN
        System.assertNotEquals(null, result, 'La lista no debe ser nula');
        System.assertEquals(3, result.size(), 'Solo deben retornarse los 3 activos');
    }

    @isTest
    static void givenBenefitsWithPriorityWhenGetBenefitsThenOrderedAsc() {
        // GIVEN
        insertBenefitsData();

        // WHEN
        Test.startTest();
        List<Benefits__c> result = Benefits_Ctr.getBenefits();
        Test.stopTest();

        // THEN
        System.assertEquals('Visa Infinite', result[0].CardName__c, 'Primero debe ser Infinite');
        System.assertEquals('Visa Plata',    result[2].CardName__c, 'Último debe ser Plata');
    }

    @isTest
    static void givenBenefitsWhenGetBenefitsThenMandatoryFieldsPopulated() {
        // GIVEN
        insertBenefitsData();

        // WHEN
        Test.startTest();
        List<Benefits__c> result = Benefits_Ctr.getBenefits();
        Test.stopTest();

        // THEN
        for (Benefits__c b : result) {
            System.assertNotEquals(null, b.AnnualEffectiveRate__c, 'TEA nula: '      + b.CardName__c);
            System.assertNotEquals(null, b.MilesAccumulation__c,   'Millas nulas: '  + b.CardName__c);
            System.assertNotEquals(null, b.CashBackPercentage__c,  'CashBack nulo: ' + b.CardName__c);
        }
    }

    @isTest
    static void givenAllInactivoWhenGetBenefitsThenEmptyList() {
        // GIVEN
        insertBenefitsData();
        List<Benefits__c> all = [SELECT Id, Status__c FROM Benefits__c];
        for (Benefits__c b : all) {
            b.Status__c = 'Inactivo';
        }
        update all;

        // WHEN
        Test.startTest();
        List<Benefits__c> result = Benefits_Ctr.getBenefits();
        Test.stopTest();

        // THEN
        System.assertNotEquals(null, result, 'La lista no debe ser nula');
        System.assertEquals(0, result.size(), 'La lista debe estar vacía');
    }
    @isTest
    static void givenEjecutivoWhenGetBenefitsThenThrowsException() {
        // GIVEN: Ejecutivo sin Benefits_Access — no necesita data de beneficios
        User ejecutivo = getEjecutivo();

        System.runAs(ejecutivo) {
            // WHEN
            Test.startTest();
            try {
                Benefits_Ctr.getBenefits();
                System.assert(false, 'Debió lanzar AuraHandledException');
            } catch (AuraHandledException e) {
                // THEN
                System.assertNotEquals(null, e.getMessage(), 'El mensaje de error no debe ser nulo');
            }
            Test.stopTest();
        }
    }

    @isTest
    static void givenAnalistaWithPermissionWhenGetBenefitsThenCanRead() {
        // GIVEN
        User analista = getAnalista();

        System.runAs(analista) {
            insertBenefitsData();
            // WHEN
            Test.startTest();
            List<Benefits__c> result = Benefits_Ctr.getBenefits();
            Test.stopTest();

            // THEN
            System.assertNotEquals(null, result, 'El Analista debe poder leer beneficios');
            System.assertNotEquals(0, result.size(), 'El Analista debe ver al menos un beneficio activo');
        }
    }
}