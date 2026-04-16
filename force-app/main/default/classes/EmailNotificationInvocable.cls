/**
 * @class       EmailNotificationInvocable
 * @description Expone un método invocable que el Flow llama directamente al ganar una Oportunidad, delegando el envío asíncrono al Queueable.
 *              Aplica with sharing para respetar el modelo de seguridad de la org.
 * @author      NovaBank - Michelle Moreno
 */
public with sharing class EmailNotificationInvocable {

    /**
     * @method      enviarNotificacion
     * @description Método invocable desde Flow. Recibe la lista de IDs de Oportunidades ganadas y delega el encolamiento a un método separado para respetar la separación de responsabilidades.
     * @param       opportunityIds  Lista de IDs de Oportunidades ganadoras.
     */
    @InvocableMethod(
        label       = 'Enviar Notificación Email Tarjeta'
        description = 'En cola el envío asíncrono de email de confirmación de tarjeta emitida.'
    )
    public static void enviarNotificacion(List<Id> opportunityIds) {
        List<Id> idsValidos = filtrarIdsValidos(opportunityIds);
        encolarJobs(idsValidos);
    }

    /**
     * @method      filtrarIdsValidos
     * @description Filtra la lista de IDs recibida eliminando valores nulos antes de encolar.
     * @param       opportunityIds  Lista original de IDs desde el Flow.
     * @return      Lista limpia de IDs válidos listos para encolar.
     */
    private static List<Id> filtrarIdsValidos(List<Id> opportunityIds) {
        List<Id> idsValidos = new List<Id>();
        for (Id oppId : opportunityIds) {
            if (oppId != null) {
                idsValidos.add(oppId);
            }
        }
        return idsValidos;
    }

    /**
     * @method      encolarJobs
     * @description Itera la lista de IDs válidos y encola un job Queueable independiente por cada Oportunidad.
     * @param       idsValidos  Lista de IDs de Oportunidades ya validados.
     */
    private static void encolarJobs(List<Id> idsValidos) {
        for (Id oppId : idsValidos) {
            System.enqueueJob(new EmailNotificationQueueable(oppId));
        }
    }
}