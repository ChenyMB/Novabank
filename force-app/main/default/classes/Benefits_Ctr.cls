/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-16-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class Benefits_Ctr {
    /**
     * Obtiene todos los beneficios activos ordenados por prioridad ascendente.
     * @return Lista de Benefits__c ordenada por Priority__c
     */
    @AuraEnabled(cacheable=true)
    public static List<Benefits__c> getBenefits() {
        if (!Schema.sObjectType.Benefits__c.isAccessible()) {
            throw new AuraHandledException('No tiene permisos para acceder a Beneficios.');
        }
        return [
            SELECT Id, Name, CardName__c, AnnualEffectiveRate__c, MilesAccumulation__c, CashBackPercentage__c, AnnualFee__c, AdditionalBenefits__c, Priority__c, Status__c, Product__c, Product__r.Name
            FROM Benefits__c
            WHERE Status__c = 'Activo'
            WITH SECURITY_ENFORCED
            ORDER BY Priority__c ASC
        ];
    }
}