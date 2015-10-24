function saveSelected() {
	var compared = [];

	var tbl = document.getElementById('comparison');
	var tblHead = tbl.rows[0].cells;
	for (var i = 1; i < tblHead.length; i++) {
		var lang = tblHead[i].id.substring(7);
		if (tblHead[i].style.display != 'none') {
			compared.push(lang);
		}
	}

	localStorage.setItem('compared', compared.join(','));
}

function loadSelected() {
	var comparedStr = localStorage.getItem('compared');
	if (comparedStr == null)
		return;

	var compared = comparedStr.split(',');

	var tbl = document.getElementById('comparison');
	var tblHead = tbl.rows[0].cells;
	for (var i = 1; i < tblHead.length; i++) {
		var lang = tblHead[i].id.substring(7);
		var state = compared.indexOf(lang) < 0 ? false : true
		setColumnVisibility(tbl, i, state);
		document.getElementById('check-' + lang).checked = state;
	}
}

function switchColumn(el, col) {
	setColumnVisibility(
		document.getElementById('comparison'),
		col,
		el.checked
	);
	saveSelected();
}

function setColumnVisibility(tbl, col, state) {
	var d = state ? '' : 'none';
	for (var i = 0; i < tbl.rows.length; i++) {
		var cell = tbl.rows[i].cells[col];
		if (cell != null)
			cell.style.display = d;
	}
}

function setForHeadersVisibility(state) {
	var css = getCssByTitle('temp-styles');
	var d = state ? 'block' : 'none';
	if (css.cssRules.length > 0) {
		css.removeRule(0);
	}
	css.insertRule(".for-header { display: " + d + "; }", 0);
}

function getCssByTitle(t) {
	for (var i = 0; i < document.styleSheets.length; i++) {
		var sheet = document.styleSheets[i];
		if (sheet.title == t)
			return sheet;
	}
}
