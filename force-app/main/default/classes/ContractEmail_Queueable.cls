/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-14-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class ContractEmail_Queueable implements Queueable {

    private Id oppId;

    /**
     * Constructor
     * @param oppId Id de la Opportunity ganada
     */
    public ContractEmail_Queueable(Id oppId) {
        this.oppId = oppId;
    }

    /**
     * Método invocable desde Flow.
     * @param oppIds Lista de Ids de Opportunity — Flow siempre pasa listas
     */
    @InvocableMethod(label='Envío de contrato' description='Envía el contrato PDF al cliente de forma asíncrona')
    public static void invoke(List<Id> oppIds) {
        if (oppIds != null && !oppIds.isEmpty()) {
            System.enqueueJob(new ContractEmail_Queueable(oppIds[0]));
        }
    }

    /**
     * Obtención de datos y el envío del email.
     * @param context Contexto de ejecución del Queueable
     */
    public void execute(QueueableContext context) {
        try { 
            Opportunity opp             = getOpportunity(oppId);
            ContentVersion cv           = getContractContentVersion(oppId);
            Messaging.SingleEmailMessage email = buildEmail(opp, cv);
            sendEmail(email);

        } catch (QueryException e) {
            throw new AuraHandledException('Error al consultar datos para el envío: ' + e.getMessage());
        } catch (EmailException e) {
            throw new AuraHandledException('Error al enviar el contrato por email: ' + e.getMessage());
        }
    }

    /**
     * Obtiene la Opportunity con datos del cliente.
     * @param oppId Id de la Opportunity
     * @return Opportunity con Account relacionada
     */
    private Opportunity getOpportunity(Id oppId) {
        if (!Schema.sObjectType.Opportunity.isAccessible()) {
            throw new AuraHandledException('No tiene permisos para acceder a Opportunity.');
        }
        return [
            SELECT Id, Name, Account.Name, Account.Email__c
            FROM Opportunity
            WHERE Id = :oppId
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * Obtiene el ContentVersion del contrato PDF vinculado a la Opportunity.
     * IsLatest = true garantiza único resultado — sin necesidad de ORDER BY ni LIMIT.
     * @param oppId Id de la Opportunity
     * @return ContentVersion con el PDF del contrato
     */
    private ContentVersion getContractContentVersion(Id oppId) {
        if (!Schema.sObjectType.ContentDocumentLink.isAccessible()) {
            throw new AuraHandledException('No tiene permisos para acceder al documento.');
        }
        ContentDocumentLink cdl = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :oppId
            WITH SECURITY_ENFORCED
            ORDER BY SystemModstamp DESC
        ];

        if (!Schema.sObjectType.ContentVersion.isAccessible()) {
            throw new AuraHandledException('No tiene permisos para acceder a contenido.');
        }
        return [
            SELECT Id, Title, VersionData, FileExtension
            FROM ContentVersion
            WHERE ContentDocumentId = :cdl.ContentDocumentId
            AND   FileExtension = 'pdf'
            AND   IsLatest = true
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * Construye el email con el PDF adjunto usando la plantilla configurada.
     * @param opp Opportunity con datos del cliente
     * @param cv ContentVersion con el PDF del contrato
     * @return SingleEmailMessage listo para enviar
     */
    private Messaging.SingleEmailMessage buildEmail(Opportunity opp, ContentVersion cv) {
        Messaging.EmailFileAttachment attachment = buildAttachment(cv);

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ opp.Account.Email__c });
        email.setSubject('Su contrato de tarjeta de crédito — NovaBank');
        email.setHtmlBody(buildEmailBody(opp));
        email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachment });
        return email;
    }

    /**
     * Construye el adjunto del email desde el ContentVersion.
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
     * Construye el cuerpo HTML del email.
     * @param opp Opportunity con datos del cliente
     * @return String con el HTML del email
     */
    private String buildEmailBody(Opportunity opp) {
        return '<p>Estimado/a <strong>' + opp.Account.Name + '</strong>,</p>'
             + '<p>Adjunto encontrará su contrato de tarjeta de crédito aprobado por NovaBank.</p>'
             + '<p>Atentamente,<br/> NovaBank</p>';
    }

    /**
     * Envía el email construido.
     * @param email SingleEmailMessage a enviar
     */
    private void sendEmail(Messaging.SingleEmailMessage email) {
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
    }
}