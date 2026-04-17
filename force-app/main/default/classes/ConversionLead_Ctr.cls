/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-16-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class ConversionLead_Ctr {

    /**
     * Obtiene el Id de la Opportunity creada
     * al convertir un Lead
     * Verifica acceso al objeto antes de consultar.
     * @param leadId Id del Lead convertido
     * @return Id de la Opportunity asociada
     */
    @AuraEnabled(cacheable=true)
    public static Id getConvertedOpportunityId(Id leadId) {
        try {
            if (!Schema.sObjectType.Lead.isAccessible()) {
                throw new AuraHandledException('No tiene permisos para acceder a Lead.');
            }
            Lead lead = [
                SELECT ConvertedOpportunityId
                FROM   Lead
                WHERE  Id = :leadId
                WITH   SECURITY_ENFORCED
            ];
            
            return lead.ConvertedOpportunityId;

        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}