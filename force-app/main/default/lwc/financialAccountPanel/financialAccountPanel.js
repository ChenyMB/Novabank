import { LightningElement, api, wire, track } from 'lwc';
import getFinancialAccounts from '@salesforce/apex/FinancialAccount_Ctr.getFinancialAccounts';
import createFinancialAccount from '@salesforce/apex/FinancialAccount_Ctr.createFinancialAccount';
import updateFinancialAccount from '@salesforce/apex/FinancialAccount_Ctr.updateFinancialAccount';
import deleteFinancialAccount from '@salesforce/apex/FinancialAccount_Ctr.deleteFinancialAccount';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FinancialAccountPanel extends LightningElement {

    @api recordId;
    @track financialAccounts = [];
    @track isLoading = true;
    @track errorMessage = '';
    @track showModal = false;
    @track modalTitle = '';
    @track currentRecord = {};
    @track isEditMode = false;

    wiredResult;

    cardTypeOptions = [
        { label: 'Visa', value: 'Visa' },
        { label: 'Mastercard', value: 'Mastercard' }
    ];

    cardStatusOptions = [
        { label: 'Activa', value: 'Activa' },
        { label: 'Bloqueada', value: 'Bloqueada' },
        { label: 'Cancelada', value: 'Cancelada' }
    ];

    @wire(getFinancialAccounts, { accountId: '$recordId' })
    wiredAccounts(result) {
        this.wiredResult = result;
        this.isLoading = false;
        if (result.data) {
            this.financialAccounts = result.data;
            this.errorMessage = '';
        } else if (result.error) {
            this.errorMessage = result.error.body.message;
        }
    }

    get hasRecords() {
        return this.financialAccounts && this.financialAccounts.length > 0;
    }

    handleNew() {
        this.modalTitle = 'Nueva Cuenta Financiera';
        this.currentRecord = { Account__c: this.recordId };
        this.isEditMode = false;
        this.showModal = true;
    }

    handleEdit(event) {
        const recordId = event.currentTarget.dataset.id;
        this.currentRecord = { ...this.financialAccounts.find(fa => fa.Id === recordId) };
        this.modalTitle = 'Editar Cuenta Financiera';
        this.isEditMode = true;
        this.showModal = true;
    }

    handleFieldChange(event) {
        const field = event.currentTarget.dataset.field;
        this.currentRecord = { ...this.currentRecord, [field]: event.detail.value };
    }

    handleCancel() {
        this.showModal = false;
        this.currentRecord = {};
    }

    handleSave() {
        this.isLoading = true;
        const action = this.isEditMode
            ? updateFinancialAccount({ financialAccount: this.currentRecord })
            : createFinancialAccount({ financialAccount: this.currentRecord });

        action
            .then(() => {
                this.showToast('Éxito', 'Cuenta Financiera guardada correctamente.', 'success');
                this.showModal = false;
                this.currentRecord = {};
                return refreshApex(this.wiredResult);
            })
            .catch(error => {
                this.errorMessage = error.body.message;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleDelete(event) {
        const recordId = event.currentTarget.dataset.id;
        this.isLoading = true;
        deleteFinancialAccount({ financialAccountId: recordId })
            .then(() => {
                this.showToast('Éxito', 'Cuenta Financiera eliminada correctamente.', 'success');
                return refreshApex(this.wiredResult);
            })
            .catch(error => {
                this.errorMessage = error.body.message;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}