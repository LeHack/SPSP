function liveViewOnLoad(data) {
    for(let p of Object.keys(data.readings)) {
        $('#liveview td.liveview-' + p + ' span.paramValue').text(data.readings[p]);
    }
    $('#liveview div.modal-body .progress').addClass('hidden')
    $('#liveview div.modal-body table.params').removeClass('hidden');
}

function loadReadings() {
    $('#liveview div.modal-body .progress').removeClass('hidden')
    $('#liveview div.modal-body table.params').addClass('hidden')
    
    window.fetch('/rest/latest').then(function(response){
        if (response.status !== 200) {
            throw reponse;
        }
        return response.json();
    }).then(liveViewOnLoad).catch(function(ex) {
        console.log('Error while fetching latest data:', ex);
    });
}
