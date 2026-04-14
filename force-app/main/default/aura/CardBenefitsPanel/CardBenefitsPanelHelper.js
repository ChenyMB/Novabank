({
    loadBenefits: function(component) {
        var action = component.get('c.getBenefits');
        action.setCallback(this, function(response) {
            var state = response.getState();
            component.set('v.isLoading', false);
            if (state === 'SUCCESS') {
                component.set('v.benefits', response.getReturnValue());
            } else {
                var errors = response.getError();
                var message = (errors && errors[0] && errors[0].message) ? errors[0].message : 'Error al cargar los beneficios.';
                component.set('v.errorMessage', message);
            }
        });
        $A.enqueueAction(action);
    }
})