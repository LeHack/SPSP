function settingsOnLoad(data) {
    if (data && data.status == "ERROR") {
        for(let p of Object.keys(data.errors)) {
            $('.settings-error-field.' + p).text(data.errors[p]);
        }
    }
    else if (data && data.settings)
        for(let p of Object.keys(data.settings)) {
            $('#' + p).val(data.settings[p]);
            $('.settings-error-field.' + p).text("");
        }
    else
        for (let p of $('.settings-error-field')) {
            $(p).text("")
        }

    $('#settings div.modal-body .progress').addClass('hidden')
    $('#settings div.modal-body .updating').addClass('hidden');
    $('#settings div.modal-body .form').removeClass('hidden');
    $('#settings div.modal-body .form').removeClass('is-blurred');
}

function loadSettings(force) {
    $('#settings div.modal-body .progress').removeClass('hidden')
    $('#settings div.modal-body .form').addClass('hidden')
    url = '/rest/settings'
    if (force)
        url += '?force=1'
    window.fetch(url).then(function(response){
        if (response.status !== 200) {
            throw reponse;
        }
        return response.json();
    }).then(settingsOnLoad).catch(function(ex) {
        console.log('Error while fetching settings:', ex);
    });
}

function updateSettings() {
	$('#settings div.modal-body .form').addClass('is-blurred');
	$('#settings div.modal-body .updating').removeClass('hidden');
	data = {}
    for(let p of $('#settings div.modal-body input')) {
        data[p.id] = p.value;
    }
	let form = new FormData();
	form.append('settings', JSON.stringify(data));
	form.append('csrfmiddlewaretoken', document.getElementsByName('csrfmiddlewaretoken')[0].value);
    window.fetch('/rest/settings/update', {
        method: 'POST',
        body: form,
        credentials: 'same-origin'
    }).then(function(response){
        if (response.status == 400) {
            return response.json();
        }
        else if (response.status !== 200) {
            throw reponse;
        }
        return;
    }).then(settingsOnLoad).catch(function(ex) {
        console.log('Error while updating settings:', ex);
    });
}
