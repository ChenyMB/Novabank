/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-16-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class Opportunity_Contract_Service {
    @TestVisible
    private static Blob overridePdfBlob = null;
    @TestVisible 
    private static Boolean overrideContentVersionCreateable = null;
    @TestVisible 
    private static Boolean overrideContentVersionAccessible = null;
    @TestVisible 
    private static Boolean overrideContentDocumentLinkCreateable = null;

    /**
     * Genera el PDF y lo vincula a la Opportunity.
     * @param oppId Id de la Opportunity
     */
    public static void generateAndStoreContract(Id oppId) {
        Blob pdfBlob         = buildPdfBlob(oppId);
        ContentVersion cv    = buildContentVersion(oppId, pdfBlob);
        insertContentVersion(cv);
        Id contentDocumentId = getContentDocumentId(cv.Id);
        insertContentDocumentLink(oppId, contentDocumentId);
    }

    /**
     * Renderiza la VF page Opportunity_Contract como PDF.
     * @param oppId Id de la Opportunity
     * @return Blob del PDF generado
     */
    private static Blob buildPdfBlob(Id oppId) {
        if (overridePdfBlob != null) {
            return overridePdfBlob;
        }
        PageReference pdfPage = Page.Opportunity_Contract;
        pdfPage.getParameters().put('id', oppId);
        pdfPage.getParameters().put('action', 'pdf');
        return pdfPage.getContentAsPDF();
    }

    /**
     * Construye el ContentVersion con el Blob del PDF.
     * @param oppId Id de la Opportunity — usado para nombrar el archivo
     * @param pdfBlob Blob del PDF generado
     * @return ContentVersion listo para insertar
     */
    private static ContentVersion buildContentVersion(Id oppId, Blob pdfBlob) {
        ContentVersion cv  = new ContentVersion();
        cv.Title           = 'Contrato - ' + oppId;
        cv.PathOnClient    = 'Contrato_' + oppId + '.pdf';
        cv.VersionData     = pdfBlob;
        cv.IsMajorVersion  = true;
        return cv;
    }

    /**
     * Inserta el ContentVersion en base de datos.
     * @param cv ContentVersion a persistir
     */
    private static void insertContentVersion(ContentVersion cv) {
        if (overrideContentVersionCreateable != null && !overrideContentVersionCreateable) {
            throw new AuraHandledException('No tiene permisos para crear ContentVersion.');
        }
        if (!Schema.sObjectType.ContentVersion.isCreateable()) {
            throw new AuraHandledException('No tiene permisos para crear ContentVersion.');
        }
        insert cv;
    }


    /**
     * Obtiene el ContentDocumentId del ContentVersion recién insertado.
     * Singleton directo por Id — garantiza único resultado.
     * @param cvId Id del ContentVersion insertado
     * @return Id del ContentDocument asociado
     */
    private static Id getContentDocumentId(Id cvId) {
        Boolean canAccess = overrideContentVersionAccessible != null ? overrideContentVersionAccessible 
            : Schema.sObjectType.ContentVersion.isAccessible();
        if (!canAccess) {
            throw new AuraHandledException('No tiene permisos para acceder a al contenido.');
        }
        return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cvId WITH SECURITY_ENFORCED].ContentDocumentId;
    }

    /**
     * Vincula el ContentDocument a la Opportunity mediante ContentDocumentLink.
     * ShareType V = Viewer (solo lectura) — adecuado para documentos contractuales.
     * @param oppId Id de la Opportunity
     * @param contentDocumentId Id del ContentDocument a vincular
     */
    private static void insertContentDocumentLink(Id oppId, Id contentDocumentId) {
        if (overrideContentDocumentLinkCreateable != null && !overrideContentDocumentLinkCreateable) {
            throw new AuraHandledException('No tiene permisos para crear ContentDocumentLink.');
        }
        if (!Schema.sObjectType.ContentDocumentLink.isCreateable()) {
            throw new AuraHandledException('No tiene permisos para crear ContentDocumentLink.');
        }
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId    = oppId;
        cdl.ContentDocumentId = contentDocumentId;
        cdl.ShareType         = 'V';
        cdl.Visibility        = 'AllUsers';
        insert cdl;
    }
}