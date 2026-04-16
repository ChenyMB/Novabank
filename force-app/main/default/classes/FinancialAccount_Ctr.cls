/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-16-2026
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
        
        if (Schema.sObjectType.FinancialAccount__c
            .fields.CardNumber__c.isAccessible()) {
            return [
                SELECT Id, Name, Account__c, CardType__c, CardNumber__c, 
                    ApprovedCreditLine__c, CardStatus__c, IssueDate__c, 
                    ProductCard__c, ProductCard__r.Name, 
                    Opportunity_Won__c, Opportunity_Won__r.Name
                FROM FinancialAccount__c
                WHERE Account__c = :accountId
                WITH SECURITY_ENFORCED
                ORDER BY IssueDate__c DESC
            ];
        }
        
        return [
            SELECT Id, Name, Account__c, CardType__c, 
                ApprovedCreditLine__c, CardStatus__c, IssueDate__c,
                ProductCard__c, ProductCard__r.Name,
                Opportunity_Won__c, Opportunity_Won__r.Name
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
    public static FinancialAccount__c createFinancialAccount(FinancialAccount__c financialAccount) {
        if (!Schema.sObjectType.FinancialAccount__c.isCreateable() ||
            !Schema.sObjectType.FinancialAccount__c.fields.CardNumber__c.isAccessible()) {
            throw new AuraHandledException('No tiene permisos para crear Cuentas Financieras.');
        }
        try {
            insert financialAccount;
            return financialAccount;
        } catch (DmlException e) {
            throw new AuraHandledException('Error al crear la Cuenta Financiera: ' + e.getMessage());
        }
    }

    /**
     * Actualiza una FinancialAccount__c existente.
     * @param financialAccount Registro con cambios a persistir
     */
    @AuraEnabled
    public static FinancialAccount__c updateFinancialAccount(FinancialAccount__c financialAccount) {
        if (!Schema.sObjectType.FinancialAccount__c.isUpdateable() ||
            !Schema.sObjectType.FinancialAccount__c.fields.CardNumber__c.isAccessible()) {
            throw new AuraHandledException('No tiene permisos para actualizar Cuentas Financieras.');
        }
        try {
            update financialAccount;
            return financialAccount;
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
        if (financialAccountId == null) {
            throw new AuraHandledException('El Id de la cuenta financiera es requerido.');
        }
        if (!Schema.sObjectType.FinancialAccount__c.isDeletable() ||
            !Schema.sObjectType.FinancialAccount__c.fields.CardNumber__c.isAccessible()) {
            throw new AuraHandledException('No tiene permisos para eliminar Cuentas Financieras.');
        }
        List<FinancialAccount__c> recordsToDelete = [
            SELECT Id FROM FinancialAccount__c
            WHERE Id = :financialAccountId
            WITH SECURITY_ENFORCED
        ];
        delete recordsToDelete;
    }

    /**
     * @description Verifica si el usuario tiene el Custom Permission
     *              Benefits_Access asignado exclusivamente al Analista
     *              via Benefits Access PS. Controla visibilidad de botones
     *              Nueva, Editar y Eliminar en el LWC Financial Account.
     * @return      true si es Analista, false si es Ejecutivo
     */
    @AuraEnabled(cacheable=true)
    public static Boolean canEditFinancialAccounts() {
        return FeatureManagement.checkPermission('Benefits_Access');
    }
}