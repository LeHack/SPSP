function setAndSubmit(name, value) {
    let form = jQuery("#data");
    form.find("input[name=" + name + "]").val(value);
    form.get(0).submit();
    return false;
}

var Refresh = (function() {
    let running = false;
    function Refresh(){}

    Refresh.prototype.start = function(handler, area, param) {
        window.fetch('/rest/refresh/start/' + area + '/' + param).then(function(response){
            if (response.status !== 200) {
                throw reponse;
            }
            return response.json();
        }).then(handler).catch(function(ex) {
            console.log('Error starting a refresh request:', ex);
        });
    };

    Refresh.prototype.check = function(handler) {
        window.fetch('/rest/refresh/check').then(function(response){
            if (response.status !== 200) {
                throw reponse;
            }
            return response.json();
        }).then(handler).catch(function(ex) {
            console.log('Error checking the status of a refresh request:', ex);
        });
    };

    return Refresh;
})();

function runRefresh(elem) {
    let jElem = jQuery(elem);
    let r = new Refresh();
    let orgText = jElem.text();
    let handler = function(data) {
        if (data.refresh == "started") {
            jElem.addClass("loading");
            jElem.text("Odświeżanie...");
            jElem.get(0).disabled = true;
            setTimeout(function(){ r.check(handler); }, 750);
        }
        else if (data.refresh === "working") {
            setTimeout(function(){ r.check(handler); }, 750);
        }
        else if (data.refresh === "ready") {
            // finalize by reloading the page to the current date
            setAndSubmit("date", null);
        }
        else {
            console.log("Incorrect status received: ", data);
        }
    }

    let form    = jQuery("#data");
    let area    = form.find("input[name=area]").val()
    let pm_type = form.find("input[name=pm]").val()
    r.start(handler, area, pm_type);

    return elem.blur();
}