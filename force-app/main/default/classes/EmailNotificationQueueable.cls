/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-16-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class EmailNotificationQueueable implements Queueable {

    private List<Id> opportunityIds;

    @TestVisible
    private static String templateDevName = 'Confirmation_Email_Card';

    @TestVisible
    private static Boolean throwQueryExceptionForTest = false;

    @TestVisible
    private static Boolean throwEmailExceptionForTest = false;

    /**
     * @method      Constructor
     * @description Recibe el ID de la Oportunidad desde el contexto invocador.
     * @param       opportunityId   ID del registro Opportunity ganado.
     */
    public EmailNotificationQueueable(List<Id> opportunityIds) {
        this.opportunityIds = opportunityIds;
    }

    /**
     * @method      execute
     * @description Punto de entrada del job asíncrono.
     * @param       context     Contexto de ejecución del job asíncrono.
     */
    public void execute(QueueableContext context) {
        EmailTemplate template = obtenerTemplate();
        if (template == null) {
            return;
        }

        List<Opportunity> opps = obtenerOportunidades();
        if (opps.isEmpty()) {
            return;
        }

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Opportunity opp : opps) {
            if (validarEmail(opp)) {
                emails.add(construirEmail(opp, template));
            }
        }

        if (!emails.isEmpty()) {
            enviarEmails(emails);
        }
    }

    /**
     * @method      obtenerOportunidades
     * @description Consulta todas las Oportunidades de la lista.
     * @return      Lista de Opportunity con datos del titular
     */
    private List<Opportunity> obtenerOportunidades() {
        try {
            if (throwQueryExceptionForTest) {
                throw new QueryException('Error simulado para pruebas');
            }

            return [
                SELECT  Id, Name, AccountId, Account.Name, Account.Email__c, RequestedCreditLine__c, 
                Product__r.Name, CloseDate, OwnerId
                FROM    Opportunity
                WHERE   Id = :opportunityIds
                WITH    SECURITY_ENFORCED
            ];
        } catch (QueryException e) {
            System.debug(LoggingLevel.ERROR,'Error: ' + e.getMessage());
            return new List<Opportunity>();
        }
    }

    /**
     * @method      validarEmail
     * @description Verifica que la cuenta del cliente tenga un email registrado antes de intentar el envío.
     * @param       opp     Oportunidad con datos del Account titular.
     * @return      true si el email existe y no está en blanco, false si no.
     */
    private Boolean validarEmail(Opportunity opp) {
        if (String.isBlank(opp.Account.Email__c)) {
            System.debug(LoggingLevel.WARN, 'Sin email registrado. OppId: ' + opp.Id);
            return false;
        }
        return true;
    }

    /**
     * @method      obtenerTemplate
     * @description Recupera el Email Template configurado para la confirmación de emisión de tarjeta. 
     *              Usa WITH SECURITY_ENFORCED.
     * @return      EmailTemplate encontrado, o null si no existe en la org.
     */
    private EmailTemplate obtenerTemplate() {
        List<EmailTemplate> templates = [
            SELECT Id, HtmlValue, Subject
            FROM   EmailTemplate
            WHERE  DeveloperName = :templateDevName
            WITH   SECURITY_ENFORCED
            LIMIT 1
        ];
        
        if (templates.isEmpty()) {
            System.debug(LoggingLevel.WARN, 'Template no encontrado: ' + templateDevName);
            return null;
        }
        return templates[0];
    }

    /**
     * @method      construirEmail
     * @description Renderiza el template con merge fields de Opportunity y construye el email.
     * @param       opp         Oportunidad ganada con datos del titular.
     * @param       template    Email Template institucional NovaBank.
     * @return      Messaging.SingleEmailMessage listo para enviar.
     */
    private Messaging.SingleEmailMessage construirEmail(Opportunity opp, EmailTemplate template) {
        String htmlBody = template.HtmlValue;
        htmlBody = htmlBody.replace('{!Opportunity.Account}',          opp.Account.Name != null ? opp.Account.Name : '-');
        htmlBody = htmlBody.replace('{!Opportunity.Product__c}',       opp.Product__r?.Name != null ? opp.Product__r?.Name : '-');
        htmlBody = htmlBody.replace('{!Opportunity.RequestedCreditLine__c}', opp.RequestedCreditLine__c != null ? opp.RequestedCreditLine__c.format() : '-');
        htmlBody = htmlBody.replace('{!Opportunity.CloseDate}',        opp.CloseDate != null ? opp.CloseDate.format() : '-');

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setTargetObjectId(opp.OwnerId);
        email.setToAddresses(new List<String>{ opp.Account.Email__c });
        email.setTreatTargetObjectAsRecipient(false);
        email.setSubject(template.Subject);
        email.setHtmlBody(htmlBody);
        email.setSaveAsActivity(true);
        return email;
    }

    /**
     * @method      enviarEmail
     * @description Ejecuta el envío del email construido.
     * @param       email   Mensaje de email listo para mandar.
     */
    private void enviarEmails(List<Messaging.SingleEmailMessage> emails) {
        try {
            if (throwEmailExceptionForTest) {
                throw new EmailException('Error simulado para pruebas');
            }
            Messaging.sendEmail(emails);
        } catch (EmailException e) {
            System.debug(LoggingLevel.ERROR, 'Error de envío: ' + e.getMessage());
        }
    }
}