/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-14-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class FinancialAccount_Ctr {
    /**
     * Obtiene las cuentas financieras asociadas a un Account.
     * @param accountId Id del Account titular
     * @return Lista de FinancialAccount__c vinculadas al cliente
     */
    @AuraEnabled(cacheable=true)
    public static List<FinancialAccount__c> getFinancialAccounts(Id accountId) {
        if (!Schema.sObjectType.FinancialAccount__c.isAccessible()) {
            throw new AuraHandledException('No tiene permisos para acceder a Cuentas Financieras.');
        }
        return [
            SELECT Id, Name, CardType__c, CardNumber__c, ApprovedCreditLine__c, CardStatus__c, IssueDate__c, ProductCard__c, ProductCard__r.Name, Opportunity_Won__c, Opportunity_Won__r.Name
            FROM FinancialAccount__c
            WHERE Account__c = :accountId
            WITH SECURITY_ENFORCED
            ORDER BY IssueDate__c DESC
        ];
    }

    /**
     * Crea una nueva FinancialAccount__c vinculada al Account.
     * @param financialAccount Registro a insertar
     */
    @AuraEnabled
    public static void createFinancialAccount(FinancialAccount__c financialAccount) {
        if (!Schema.sObjectType.FinancialAccount__c.isCreateable()) {
            throw new AuraHandledException('No tiene permisos para crear Cuentas Financieras.');
        }
        try {
            insert financialAccount;
        } catch (DmlException e) {
            throw new AuraHandledException('Error al crear la Cuenta Financiera: ' + e.getMessage());
        }
    }

    /**
     * Actualiza una FinancialAccount__c existente.
     * @param financialAccount Registro con cambios a persistir
     */
    @AuraEnabled
    public static void updateFinancialAccount(FinancialAccount__c financialAccount) {
        if (!Schema.sObjectType.FinancialAccount__c.isUpdateable()) {
            throw new AuraHandledException('No tiene permisos para actualizar Cuentas Financieras.');
        }
        try {
            update financialAccount;
        } catch (DmlException e) {
            throw new AuraHandledException('Error al actualizar la Cuenta Financiera: ' + e.getMessage());
        }
    }

    /**
     * Elimina una FinancialAccount__c por Id.
     * @param financialAccountId Id del registro a eliminar
     */
    @AuraEnabled
    public static void deleteFinancialAccount(Id financialAccountId) {
        if (!Schema.sObjectType.FinancialAccount__c.isDeletable()) {
            throw new AuraHandledException('No tiene permisos para eliminar Cuentas Financieras.');
        }
        try {
            delete [
                SELECT Id
                FROM FinancialAccount__c
                WHERE Id = :financialAccountId
                WITH SECURITY_ENFORCED
            ];
        } catch (DmlException e) {
            throw new AuraHandledException('Error al eliminar la cuenta financiera: ' + e.getMessage());
        }
    }
}