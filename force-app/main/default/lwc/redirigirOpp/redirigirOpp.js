import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getConvertedOpportunity from '@salesforce/apex/ConversionLead_Ctr.getConvertedOpportunityId';

export default class RedirigirOpp extends NavigationMixin(LightningElement) {
    @api recordId;
    isLoading = false;
    errorMessage;

    /**
     * Consulta la Opportunity convertida del Lead
     * y navega a su registro
     */
    handleRedirect() {
        this.isLoading = true;
        this.errorMessage = null;

        getConvertedOpportunity({ leadId: this.recordId })
            .then(oppId => {
                if (oppId) {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: oppId,
                            actionName: 'view'
                        }
                    });
                } else {
                    this.errorMessage = 'No se encontró una oportunidad asociada.';
                }
            })
            .catch(() => {
                this.errorMessage = 'Error al obtener la oportunidad.';
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}