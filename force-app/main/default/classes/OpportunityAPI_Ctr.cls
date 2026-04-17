/**
 * @description REST API para exponer oportunidades Cerrada-Ganada de un cliente.
 *              Endpoint: GET /services/apexrest/v1/clientes/{clienteId}/oportunidades-ganadas
 *              Autenticación: OAuth 2.0 Bearer Token (Client Credentials Flow)
 * @author      Michelle Moreno
 * */

@RestResource(urlMapping='/v1/clientes/*/oportunidades-ganadas')
global with sharing class OpportunityAPI_Ctr {

    global class ClienteResponse {
        global String clienteId;
        global String nombreCliente;
        global List<OportunidadWrapper> oportunidadesGanadas;
        global Integer totalOportunidades;
    }

    global class OportunidadWrapper {
        global String  oportunidadId;
        global String  producto;
        global Decimal montoAprobado;
        global Decimal lineaCredito;
        global Decimal tasaInteres;
        global String  fechaCierre;
        global String  canalOrigen;
        global String  ejecutivo;
    }

    /**
     * Endpoint GET — retorna oportunidades ganadas del cliente.
     * URL: GET /services/apexrest/v1/clientes/{clienteId}/oportunidades-ganadas
     * Autenticación
     */
    @HttpGet
    global static void getOportunidadesGanadas() {
        RestRequest  req      = RestContext.request;
        RestResponse res      = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {
            String clienteId = extractClienteId(req.requestURI);
            Account account  = getAccount(clienteId);

            List<Opportunity> opps = getOpportunities(account.Id);

            ClienteResponse response    = buildResponse(account, opps);
            res.statusCode              = 200;
            res.responseBody            = Blob.valueOf(JSON.serialize(response));

        } catch (QueryException e) {
            res.statusCode   = 404;
            res.responseBody = Blob.valueOf('{"error": "Cliente no encontrado."}');
        } catch (Exception e) {
            res.statusCode   = 500;
            res.responseBody = Blob.valueOf('{"error": "' + e.getMessage() + '"}');
        }
    }

    /**
     * Extrae el clienteId desde la URL de la request.
     * URL pattern: /v1/clientes/{clienteId}/oportunidades-ganadas
     * @param requestURI URI completa del request
     * @return clienteId extraído de la URI
     */
    private static String extractClienteId(String requestURI) {
        List<String> parts = requestURI.split('/');
        return parts[parts.size() - 2];
    }

    /**
     * Obtiene el Account por Id o por DocumentNumber__c.
     * @param clienteId Id o número de documento del cliente
     * @return Account encontrado
     */
    private static Account getAccount(String clienteId) {
        if (!Schema.sObjectType.Account.isAccessible()) {
            throw new QueryException('No tiene permisos para acceder a Account.');
        }
        return [
            SELECT Id, Name
            FROM Account
            WHERE Id = :clienteId OR DocumentNumber__c = :clienteId
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * Obtiene las oportunidades Cerradas Ganadas del Account.
     * @param accountId Id del Account
     * @return Lista de Opportunity ganadas
     */
    private static List<Opportunity> getOpportunities(Id accountId) {
        if (!Schema.sObjectType.Opportunity.isAccessible()) {
            throw new QueryException('No tiene permisos para acceder a Opportunity.');
        }
        return [
            SELECT Id, Product__r.Name, Amount, RequestedCreditLine__c, 
            InterestRate__c, CloseDate, LeadSource, Owner.Name
            FROM Opportunity
            WHERE AccountId      = :accountId
            AND   StageName      = 'Cerrada Ganada'
            WITH SECURITY_ENFORCED
            ORDER BY CloseDate DESC
        ];
    }

    /**
     * Construye el wrapper de respuesta con Account y Opportunities.
     * @param account Account del cliente
     * @param opps Lista de oportunidades ganadas
     * @return ClienteResponse serializable a JSON
     */
    private static ClienteResponse buildResponse(Account account, List<Opportunity> opps) {
        ClienteResponse response        = new ClienteResponse();
        response.clienteId              = account.Id;
        response.nombreCliente          = account.Name;
        response.oportunidadesGanadas   = buildOportunidadWrappers(opps);
        response.totalOportunidades     = opps.size();
        return response;
    }

    /**
     * Construye la lista de wrappers de oportunidades.
     * @param opps Lista de Opportunity
     * @return Lista de OportunidadWrapper
     */
    private static List<OportunidadWrapper> buildOportunidadWrappers(List<Opportunity> opps) {
        List<OportunidadWrapper> wrappers = new List<OportunidadWrapper>();
        for (Opportunity opp : opps) {
            wrappers.add(buildOportunidadWrapper(opp));
        }
        return wrappers;
    }

    /**
     * Construye un wrapper individual de Opportunity.
     * @param opp Opportunity a mapear
     * @return OportunidadWrapper mapeado
     */
    private static OportunidadWrapper buildOportunidadWrapper(Opportunity opp) {
        OportunidadWrapper wrapper  = new OportunidadWrapper();
        wrapper.oportunidadId       = opp.Id;
        wrapper.producto            = opp.Product__r.Name;
        wrapper.montoAprobado       = opp.Amount;
        wrapper.lineaCredito        = opp.RequestedCreditLine__c;
        wrapper.tasaInteres         = opp.InterestRate__c;
        wrapper.fechaCierre         = String.valueOf(opp.CloseDate);
        wrapper.canalOrigen         = opp.LeadSource;
        wrapper.ejecutivo           = opp.Owner.Name;
        return wrapper;
    }
}