/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-16-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class Opportunity_Contract_Ctr {
    public Opportunity opp { get; private set; }

    /**
     * Constructor
     */
    public Opportunity_Contract_Ctr() {
        Id oppId = ApexPages.currentPage().getParameters().get('id');
        opp = getOpportunity(oppId);
    }

    /**
     * Consulta la Opportunity con todos los campos necesarios para el contrato.
     * @param oppId Id de la Opportunity
     * @return Opportunity con Account relacionada
     */
        private Opportunity getOpportunity(Id oppId) {
        if (oppId == null) {
            return null;
        }
        if (!Schema.sObjectType.Opportunity.isAccessible()) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'No tiene permisos para acceder a la información de la oportunidad.'
            ));
            return null;
        }
        return [
            SELECT Id, Name, RequestedCreditLine__c, InterestRate__c,
                PaymentDate__c, MachineWithdrawal__c, LeadSource, CloseDate,
                Product__c, Account.Name, Account.DocumentType__c, Account.Email__c
            FROM Opportunity
            WHERE Id = :oppId
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * Genera y almacena el contrato PDF.
     * @param oppId Id de la Opportunity
     */
    @AuraEnabled
    public static void generarYAlmacenarContrato(Id oppId) {
        Opportunity_Contract_Service.generateAndStoreContract(oppId);
    }
}