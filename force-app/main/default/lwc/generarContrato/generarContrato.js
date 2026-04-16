import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import generarYAlmacenarContrato from '@salesforce/apex/Opportunity_Contract_Ctr.generarYAlmacenarContrato';

export default class GenerarContrato extends LightningElement {
    @api recordId;

    @api invoke() {
        generarYAlmacenarContrato({ oppId: this.recordId })
            .then(() => {
                return refreshApex(this.recordId);
            })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Éxito',
                    message: 'Contrato generado y almacenado correctamente.',
                    variant: 'success'
                }));
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: error.body?.message || 'Error al generar el contrato.',
                    variant: 'error'
                }));
                this.dispatchEvent(new CloseActionScreenEvent());
            });
    }
}