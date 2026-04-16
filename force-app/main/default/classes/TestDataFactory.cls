/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-16-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class TestDataFactory {

    public static final String PROFILE_NAME = 'Asesor de Venta y Reclamos';
    public static final String ROLE_EJECUTIVO = 'Ejecutivo';
    public static final String ROLE_ANALISTA  = 'Analista';

    /**
     * @description Construye un usuario con el perfil "Asesor de Venta y Reclamos" y el rol especificado. NO inserta el registro.
     *
     * @param roleName  Nombre del rol (Ejecutivo / Analista)
     * @param username  Username único (debe terminar en dominio de prueba)
     * @return          User sin insertar
     */
    public static User buildUser(String roleName, String username) {
        Profile prof = [
            SELECT Id 
            FROM Profile
            WHERE Name = :PROFILE_NAME
            LIMIT 1
        ];
        UserRole role = [
            SELECT Id 
            FROM UserRole
            WHERE Name = :roleName
            LIMIT 1
        ];
        return new User(
            FirstName         = 'Test',
            LastName          = roleName,
            Email             = username,
            Username          = username,
            Alias             = (roleName.length() > 8 ? roleName.left(8) : roleName),
            ProfileId         = prof.Id,
            UserRoleId        = role.Id,
            TimeZoneSidKey    = 'America/Lima',
            LocaleSidKey      = 'es_PE',
            LanguageLocaleKey = 'es',
            EmailEncodingKey  = 'UTF-8'
        );
    }

    /**
     * @description Construye un usuario con perfil Minimum Access — sin acceso a objetos CRM.
     * Útil para probar validaciones de isAccessible() en controladores.
     * @param username  Username único
     * @return          User sin insertar
     */
    public static User buildUserNoAccess(String username) {
        Profile minProfile = [
            SELECT Id FROM Profile 
            WHERE Name = 'Minimum Access - Salesforce' 
            LIMIT 1
        ];
        return new User(
            FirstName         = 'No',
            LastName          = 'Access',
            Email             = username,
            Username          = username,
            Alias             = 'noacc',
            ProfileId         = minProfile.Id,
            TimeZoneSidKey    = 'America/Lima',
            LocaleSidKey      = 'es_PE',
            LanguageLocaleKey = 'es',
            EmailEncodingKey  = 'UTF-8'
        );
}

    /**
     * @description Crea un Account estándar que representa un cliente de NovaBank.
     * Incluye campos custom transversales del modelo de datos.
     *
     * @param doInsert  Si true, inserta el registro en la base de datos
     * @return          Account con o sin Id según doInsert
     */
    public static Account createAccount(Boolean doInsert) {
        Account acc = new Account(
            Name                = 'Francesca Moreno',
            Email__c            = 'asmpmorenobest@gmail.com',
            DocumentType__c     = 'DNI',
            DocumentNumber__c   = '12345678',
            BirthDate__c        = Date.newInstance(2003, 6, 3),
            MonthlyIncome__c    = 5000,
            EmploymentStatus__c = 'Dependiente',
            MaritalStatus__c    = 'Soltero/a',
            NumberOfDependents__c = 0
        );
        if (doInsert){
            insert acc;
        } 
        return acc;
    }

    /**
     * @description Crea un Lead en estado "Inicio" con datos básicos de prospecto.
     *
     * @param doInsert  Si true, inserta el registro
     * @return          Lead con o sin Id
     */
    public static Lead createLead(Boolean doInsert) {
        Lead lead = new Lead(
            FirstName              = 'Francesca',
            LastName               = 'Best',
            Company                = 'NTT Data',
            Email                  = 'asmpmorenobest@gmail.com',
            Status                 = 'Inicio',
            MonthlyIncome__c       = 3000,
            RequestedCreditLine__c = 2500,
            Product__c             = 'Visa Plata',
            Max_Attention_Days__c  = 30
        );
        if (doInsert){
            insert lead;
        }
        return lead;
    }

    /**
     * @description Crea un Lead vencido (creado hace 31 días) para pruebas del Schedule-Triggered Flow de desestimación.
     *
     * @param doInsert  Si true, inserta el registro
     * @return          Lead con fecha de creación manipulada
     */
    public static Lead createExpiredLead(Boolean doInsert) {
        Lead lead = new Lead(
            FirstName              = 'Carlos',
            LastName               = 'Moreno',
            Company                = 'Sin Empresa',
            Email                  = 'asmpmorenobest@gmail.com',
            Status                 = 'Inicio',
            MonthlyIncome__c       = 2000,
            RequestedCreditLine__c = 1500,
            Product__c             = 'Visa Plata',
            Max_Attention_Days__c  = 30
        );
        if (doInsert){
            insert lead;
        }
        return lead;
    }

    /**
     * @description Crea una Opportunity en el estado indicado, vinculada al Account.
     *
     * @param accountId  Id del Account relacionado
     * @param stageName  Estado de la oportunidad
     * @param doInsert   Si true, inserta el registro
     * @return           Opportunity con o sin Id
     */
    public static Opportunity createOpportunity(Id accountId, String stageName, Boolean doInsert) {

        Product2 product = new Product2(
            Name                    = 'Visa Plata',
            IsActive                = true,
            Card_Type__c            = 'Visa',
            Card_Category__c        = 'Plata',
            Minimum_Credit_Line__c  = 500,
            Maximum_Credit_Line__c  = 3000,
            Interest_Rate__c        = 32.5,
            Sales_Channel__c        = 'Web'
        );

        insert product;

        Opportunity opp = new Opportunity(
            Name                   = 'Opp Test NovaBank',
            AccountId              = accountId,
            StageName              = stageName,
            CloseDate              = Date.today().addDays(30),
            RequestedCreditLine__c = 2500,
            InterestRate__c        = 24.5,
            PaymentDate__c         = Date.today().addDays(15),
            Product__c             = product.Id,
            MachineWithdrawal__c   = true,
            Approval_Status__c     = 'Pendiente'
        );
        if (doInsert) {
            insert opp;
        }
        return opp;
    }

    /**
     * @description Crea una Opportunity en estado "Cerrada Ganada".
     *              Útil para pruebas del REST API y creación de Financial Account.
     *
     * @param accountId  Id del Account relacionado
     * @param doInsert   Si true, inserta el registro
     * @return           Opportunity ganada
     */
    public static Opportunity createWonOpportunity(Id accountId, Boolean doInsert) {
        
        Product2 product = new Product2(
            Name                    = 'Visa Plata',
            IsActive                = true,
            Card_Type__c            = 'Visa',
            Card_Category__c        = 'Plata',
            Minimum_Credit_Line__c  = 500,
            Maximum_Credit_Line__c  = 3000,
            Interest_Rate__c        = 32.5,
            Sales_Channel__c        = 'Web'
        );

        insert product;

        Opportunity opp = new Opportunity(
            Name                   = 'Opp Ganada NovaBank',
            AccountId              = accountId,
            StageName              = 'Cerrada Ganada',
            CloseDate              = Date.today(),
            RequestedCreditLine__c = 2500,
            InterestRate__c        = 24.5,
            PaymentDate__c         = Date.today().addDays(15),
            Product__c             = product.Id,
            MachineWithdrawal__c   = true,
            Approval_Status__c     = 'Aprobado'
        );
        if (doInsert){
            insert opp;
        }
        return opp;
    }

    /**
     * @description Crea una Opportunity que requiere aprobación (línea crediticia > S/3,000).
     *
     * @param accountId  Id del Account relacionado
     * @param doInsert   Si true, inserta el registro
     * @return           Opportunity con línea alta
     */
    public static Opportunity createHighCreditOpportunity(Id accountId, Boolean doInsert) {
        Opportunity opp = new Opportunity(
            Name                   = 'Opp Alta Credito NovaBank',
            AccountId              = accountId,
            StageName              = 'Inicio',
            CloseDate              = Date.today().addDays(45),
            RequestedCreditLine__c = 5000,
            InterestRate__c        = 22.0,
            PaymentDate__c         = Date.today().addDays(1),
            Product__c             = 'Visa Oro',
            MachineWithdrawal__c   = true
        );
        if (doInsert){
            insert opp;
        }
        return opp;
    }

    /**
     * @description Crea un Financial Account (tarjeta emitida) vinculado a Account y Opportunity.
     *
     * @param accountId  Id del Account (titular)
     * @param oppId      Id de la Opportunity ganada
     * @param doInsert   Si true, inserta el registro
     * @return           FinancialAccount__c con o sin Id
     */
    public static FinancialAccount__c createFinancialAccount(
        Id accountId, Id oppId, Boolean doInsert
    ) {
        FinancialAccount__c financialAcc = new FinancialAccount__c(
            Account__c             = accountId,
            Opportunity_Won__c     = oppId,
            CardNumber__c          = '4111111111111111',
            CardType__c            = 'Visa',
            ApprovedCreditLine__c  = 2500,
            IssueDate__c           = Date.today(),
            CardStatus__c          = 'Activa'
        );
        if (doInsert){
            insert financialAcc;
        }
        return financialAcc;
    }

    /**
     * @description Crea un registro de Beneficio con valores por defecto (Visa Plata, prioridad 3, estado Activo).
     * @param doInsert  Si true, inserta el registro en la base de datos
     * @return          Benefits__c con valores por defecto, con o sin Id
     */
    public static Benefits__c createBenefit(Boolean doInsert) {
        Benefits__c benefit = new Benefits__c(
            CardName__c            = 'Visa Plata',
            Priority__c            = 3,
            Status__c              = 'Activo',
            AnnualEffectiveRate__c = 24.5,
            MilesAccumulation__c   = 1.5,
            CashBackPercentage__c  = 2.0,
            AnnualFee__c           = 150,
            AdditionalBenefits__c  = 'Seguro de viaje, Sala VIP'
        );
        if (doInsert) {
            insert benefit;
        }
        return benefit;
    }

    /**
     * @description Crea un Caso de postventa vinculado a un Account.
     *
     * @param accountId  Id del Account reclamante
     * @param doInsert   Si true, inserta el registro
     * @return           Case con o sin Id
     */
    public static Case createCase(Id accountId, Boolean doInsert) {
        Case c = new Case(
            AccountId       = accountId,
            Status          = 'En Revisión',
            Type            = 'Consumo Doble',
            Case_Subtype__c = 'Consumo duplicado nacional',
            Priority        = 'Medium',
            Subject         = 'Reclamo de prueba NovaBank',
            Description     = 'Descripción detallada del reclamo de prueba'
        );
        if (doInsert) {
            insert c;
        }
        return c;
    }

    /**
     * @description Crea un Caso con todos los campos de cierre completados
     *              para pruebas del flujo de cierre automático.
     *
     * @param accountId  Id del Account reclamante
     * @param doInsert   Si true, inserta el registro
     * @return           Case listo para cierre
     */
    public static Case createReadyToCloseCase(Id accountId, Boolean doInsert) {
        Case c = new Case(
            AccountId                    = accountId,
            Status                       = 'En Revisión',
            Type                         = 'Error de Facturación',
            Case_Subtype__c              = 'Intereses mal calculados',
            Priority                     = 'High',
            Subject                      = 'Caso listo para cierre',
            Description                  = 'Descripción completa',
            Case_Analysis__c             = 'Análisis realizado: se verificó el cargo',
            Internal_Observations__c     = 'Sin observaciones adicionales',
            Final_Resolution__c          = 'Cargo revertido correctamente'
        );
        if (doInsert) {
            insert c;
        }
        return c;
    }

    /**
     * @description Crea un ContentVersion (simulando un PDF de contrato) y lo vincula al registro indicado mediante ContentDocumentLink.
     *
     * @param linkedEntityId  Id del registro al que se vincula el documento
     * @param doInsert        Si true, inserta y vincula el documento
     * @return                ContentVersion con Id y ContentDocumentId populados
     */
    public static ContentVersion createContentVersion(Id linkedEntityId, Boolean doInsert) {
        ContentVersion cv = new ContentVersion(
            Title          = 'Contrato Tarjeta Test',
            PathOnClient   = 'Contrato_Tarjeta_Test.pdf',
            VersionData    = Blob.valueOf('PDF Content Simulado para Tests NovaBank'),
            IsMajorVersion = true
        );
        if (doInsert) {
            insert cv;
            cv = [
                SELECT Id, ContentDocumentId 
                FROM ContentVersion 
                WHERE Id = :cv.Id
                ];
            ContentDocumentLink cdl = new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId    = linkedEntityId,
                ShareType         = 'V',
                Visibility        = 'AllUsers'
            );
            insert cdl;
        }
        return cv;
    }

    /**
     * @description Crea un producto de tarjeta de crédito en el catálogo.
     *
     * @param productName  Nombre del producto (ej: 'Visa Plata')
     * @param doInsert     Si true, inserta el registro
     * @return             Product2 con o sin Id
     */
    public static Product2 createProduct(String productName, Boolean doInsert) {
        Product2 prod = new Product2(
            Name             = productName,
            IsActive         = true,
            Card_Type__c     = 'Visa',
            Card_Category__c = productName
        );
        if (doInsert) {
            insert prod;
        }
        return prod;
    }
}