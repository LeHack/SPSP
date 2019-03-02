var Chart = function(defaultType, defaultRange) {
	let selectedType = defaultType, selectedRange = defaultRange;
	let setLoading = function(state) {
		if (state) {
		    $('#charts div.modal-body img').addClass('hidden');
		    $('#charts div.modal-body .progress').removeClass('hidden');
		}
		else {
		    $('#charts div.modal-body img').removeClass('hidden');
		    $('#charts div.modal-body .progress').addClass('hidden');
		}
	}
	let updateDropdown = function(id, selected) {
		console.log("Updating: ", id, "using", selected)
		for (let el of $('#' + id).parent().find('.dropdown-menu li')) {
			if (selected == el.getAttribute('data-value')) {
				$('#' + id + ' .selectedVal').text(el.childNodes[0].innerHTML)
				break;
			}
		}
	}

	let chartOnLoad = function(data) {
		// update image
		if (data)
			$('#charts div.modal-body img').attr("src", data.chart);
	    setLoading(false);
	}
	let reload = function() {
		setLoading(true);
		updateDropdown('dropdownType', selectedType);
		updateDropdown('dropdownRange', selectedRange);
	    window.fetch("/rest/chart/" + selectedType + "/" + selectedRange).then(function(response){
	        if (response.status !== 200) {
	            throw reponse;
	        }
	        return response.json();
	    }).then(chartOnLoad).catch(function(ex) {
	        console.log('Error while fetching chart:', ex);
	    });
	}

	return {
		reload: reload,
		setType: function(type) {
			selectedType = type;
			reload();
		},
		setRange: function(range) {
			selectedRange = range;
			reload();
		},
	}
}
