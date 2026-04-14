/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-14-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class Opportunity_Contract_Service {

    /**
     * Genera el PDF y lo vincula a la Opportunity.
     * @param oppId Id de la Opportunity
     */
    public static void generateAndStoreContract(Id oppId) {
        try {
            Blob pdfBlob              = buildPdfBlob(oppId);
            ContentVersion cv         = buildContentVersion(oppId, pdfBlob);
            insertContentVersion(cv);

            Id contentDocumentId      = getContentDocumentId(cv.Id);
            insertContentDocumentLink(oppId, contentDocumentId);
        } catch (DmlException e) {
            throw new AuraHandledException('Error al guardar el contrato: ' + e.getMessage());
        }
    }

    /**
     * Renderiza la VF page Opportunity_Contract como PDF.
     * @param oppId Id de la Opportunity
     * @return Blob del PDF generado
     */
    private static Blob buildPdfBlob(Id oppId) {
        PageReference pdfPage = Page.Opportunity_Contract;
        pdfPage.getParameters().put('id', oppId);
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
        if (!Schema.sObjectType.ContentVersion.isAccessible()) {
            throw new AuraHandledException('No tiene permisos para acceder a al contenido.');
        }
        return [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cvId
            WITH SECURITY_ENFORCED
        ].ContentDocumentId;
    }

    /**
     * Vincula el ContentDocument a la Opportunity mediante ContentDocumentLink.
     * ShareType V = Viewer (solo lectura) — adecuado para documentos contractuales.
     * @param oppId Id de la Opportunity
     * @param contentDocumentId Id del ContentDocument a vincular
     */
    private static void insertContentDocumentLink(Id oppId, Id contentDocumentId) {
        if (!Schema.sObjectType.ContentDocumentLink.isCreateable()) {
            throw new AuraHandledException('No tiene permisos para crear ContentDocumentLink.');
        }
        ContentDocumentLink cdl  = new ContentDocumentLink();
        cdl.LinkedEntityId       = oppId;
        cdl.ContentDocumentId    = contentDocumentId;
        cdl.ShareType            = 'V';
        cdl.Visibility           = 'AllUsers';
        insert cdl;
    }
}