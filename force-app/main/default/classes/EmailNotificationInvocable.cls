/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-16-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
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
     * @method      encolarJobsa
     * @description Itera la lista de IDs válidos y encola un job Queueable independiente por cada Oportunidad.
     * @param       idsValidos  Lista de IDs de Oportunidades ya validados.
     */
    private static void encolarJobs(List<Id> idsValidos) {
        if (!idsValidos.isEmpty()) {
            System.enqueueJob(new EmailNotificationQueueable(idsValidos));
        }
    }
}