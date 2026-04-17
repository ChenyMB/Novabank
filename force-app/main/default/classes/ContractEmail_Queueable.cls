/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-16-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class ContractEmail_Queueable implements Queueable {

    private Id oppId;

    /**
     * @description Constructor del Queueable.
     * @param oppId Id de la Opportunity ganada
     */
    public ContractEmail_Queueable(Id oppId) {
        this.oppId = oppId;
    }

    /**
     * @description Método invocable desde Flow.
     *              Flow siempre pasa listas — se toma solo el primero.
     * @param oppIds Lista de Ids de Opportunity
     */
    @InvocableMethod( label='Envío de contrato' description='Envía el contrato PDF al cliente de forma asíncrona')
    public static void invoke(List<Id> oppIds) {
        if (oppIds != null && !oppIds.isEmpty()) {
            System.enqueueJob(new ContractEmail_Queueable(oppIds[0]));
        }
    }

    /**
     * @description Construcción y envío del email con el contrato adjunto.
     *              Captura QueryException (acceso/datos) y EmailException (envío)
     *              para que el job no falle críticamente.
     * @param context Contexto de ejecución del Queueable
     */
    public void execute(QueueableContext context) {
        try {
            Opportunity opp   = getOpportunity(oppId);
            ContentVersion cv = getContractContentVersion(oppId);
            sendEmail(buildEmail(opp, cv));
        } catch (QueryException e) {
            System.debug(LoggingLevel.ERROR, 'Error al consultar datos: ' + e.getMessage());
        } catch (EmailException e) {
            System.debug(LoggingLevel.ERROR, 'Error al enviar contrato: ' + e.getMessage());
        }
    }

    /**
     * @description Obtiene la Opportunity con datos del cliente.
     *              Verifica acceso a nivel de objeto antes de la consulta.
     *              WITH SECURITY_ENFORCED cubre la seguridad a nivel de campo.
     * @param oppId Id de la Opportunity
     * @return Opportunity con Account relacionada
     */
    private Opportunity getOpportunity(Id oppId) {
        if (!Schema.sObjectType.Opportunity.isAccessible()) {
            throw new QueryException('Sin acceso al objeto Opportunity.');
        }
        return [
            SELECT Id, Name, Account.Name, Account.Email__c
            FROM   Opportunity
            WHERE  Id = :oppId
            WITH   SECURITY_ENFORCED
        ];
    }

    /**
     * @description Obtiene el ContentVersion del contrato PDF vinculado a la Opportunity.     *            
     *              IsLatest = true en ContentVersion garantiza la versión vigente.
     * @param oppId Id de la Opportunity
     * @return ContentVersion con el PDF del contrato
     */
    private ContentVersion getContractContentVersion(Id oppId) {
        ContentDocumentLink cdl = [
            SELECT ContentDocumentId
            FROM   ContentDocumentLink
            WHERE  LinkedEntityId = :oppId
            WITH   SECURITY_ENFORCED
            ORDER BY SystemModstamp DESC
            LIMIT 1
        ];

        return [
            SELECT Id, Title, VersionData, FileExtension
            FROM   ContentVersion
            WHERE  ContentDocumentId = :cdl.ContentDocumentId
            AND    FileExtension = 'pdf'
            AND    IsLatest = true
            WITH   SECURITY_ENFORCED
        ];
    }

    /**
     * @description Construye el email con el PDF adjunto.
     * @param opp Opportunity con datos del cliente
     * @param cv  ContentVersion con el PDF del contrato
     * @return SingleEmailMessage listo para enviar
     */
    private Messaging.SingleEmailMessage buildEmail(Opportunity opp, ContentVersion cv) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ opp.Account.Email__c });
        email.setSubject('Su contrato de tarjeta de crédito — NovaBank');
        email.setHtmlBody(buildEmailBody(opp));
        email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ buildAttachment(cv) });
        return email;
    }

    /**
     * @description Construye el adjunto del email desde el ContentVersion.
     * @param cv ContentVersion del PDF
     * @return EmailFileAttachment con el PDF
     */
    private Messaging.EmailFileAttachment buildAttachment(ContentVersion cv) {
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName(cv.Title + '.' + cv.FileExtension);
        attachment.setBody(cv.VersionData);
        attachment.setContentType('application/pdf');
        return attachment;
    }

    /**
     * @description Construye el cuerpo HTML del email.
     * @param opp Opportunity con datos del cliente
     * @return String con el HTML del email
     */
    private String buildEmailBody(Opportunity opp) {
        return '<p>Estimado/a <strong>' + opp.Account.Name + '</strong>,</p>'
             + '<p>Adjunto encontrará su contrato de tarjeta de crédito aprobado por NovaBank.</p>'
             + '<p>Atentamente,<br/> NovaBank</p>';
    }

    /**
     * @description Envía el email construido.
     * @param email SingleEmailMessage a enviar
     */
    private void sendEmail(Messaging.SingleEmailMessage email) {
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
    }
}