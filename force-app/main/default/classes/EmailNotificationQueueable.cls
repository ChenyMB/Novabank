/**
 * @class       EmailNotificationQueueable
 * @description Clase Queueable que gestiona el envío asíncrono de correo electrónico al cliente cuando su tarjeta de crédito es emitida.
 *              Se dispara desde el Record-Triggered Flow al ganar una Oportunidad.
 *              Aplica with sharing para respetar el modelo de seguridad de la org.
 * @author      NovaBank - Michelle Moreno
 */
public with sharing class EmailNotificationQueueable implements Queueable {

    private Id opportunityId;

    /**
     * @method      Constructor
     * @description Recibe el ID de la Oportunidad desde el contexto invocador.
     * @param       opportunityId   ID del registro Opportunity ganado.
     */
    public EmailNotificationQueueable(Id opportunityId) {
        this.opportunityId = opportunityId;
    }

    /**
     * @method      execute
     * @description Punto de entrada del job asíncrono.
     * @param       context     Contexto de ejecución del job asíncrono.
     */
    public void execute(QueueableContext context) {
        Opportunity opp = obtenerOportunidad();
        if (opp == null) {
            return;
        }
        if (!validarEmail(opp)) {
            return;
        }
        EmailTemplate template = obtenerTemplate();
        if (template == null) {
            return;
        }
        Messaging.SingleEmailMessage email = construirEmail(opp, template);
        enviarEmail(email);
    }

    /**
     * @method      obtenerOportunidad
     * @description Consulta la Oportunidad con los campos necesarios para el email.
     *              Usa WITH SECURITY_ENFORCED para respetar la seguridad a nivel de campo y objeto del usuario en ejecución.
     * @return      Opportunity con datos del titular, o null si no se encuentra.
     */
    private Opportunity obtenerOportunidad() {
        try {
            return [
                SELECT  Id, Name, AccountId, Account.Name, Account.Email__c, RequestedCreditLine__c, Product__r.Name, CloseDate, OwnerId
                FROM    Opportunity
                WHERE   Id = :opportunityId
                WITH    SECURITY_ENFORCED
            ];
        } catch (QueryException e) {
            System.debug(LoggingLevel.ERROR,'Error: ' + e.getMessage());
            return null;
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
            System.debug(LoggingLevel.WARN,'Sin email registrado. OppId: '+ opportunityId);
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
    @TestVisible
    private static String templateDevName = 'Confirmation_Email_Card';

    private EmailTemplate obtenerTemplate() {
        List<EmailTemplate> templates = [
            SELECT Id, HtmlValue, Subject
            FROM   EmailTemplate
            WHERE  DeveloperName = :templateDevName
            LIMIT 1
        ];
        if (templates.isEmpty()) {
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
    private void enviarEmail(Messaging.SingleEmailMessage email) {
        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
            System.debug(LoggingLevel.INFO,'Email enviado. OppId: '+ opportunityId);
        } catch (EmailException e) {
            System.debug(LoggingLevel.ERROR,'EmailNotificationQueueable.enviarEmail - Error de envío: '+ e.getMessage());
        }
    }
}