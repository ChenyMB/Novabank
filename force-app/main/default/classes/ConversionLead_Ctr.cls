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
     * @param leadId Id del Lead convertido
     * @return Id de la Opportunity asociada
     */
    @AuraEnabled(cacheable=true)
    public static Id getConvertedOpportunityId(Id leadId) {
        try {
            Lead lead = [
                SELECT ConvertedOpportunityId 
                FROM Lead 
                WHERE Id = :leadId 
                LIMIT 1
            ];
            return lead.ConvertedOpportunityId;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}