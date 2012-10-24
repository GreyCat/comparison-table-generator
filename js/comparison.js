function switchColumn(el, col) {
	var tbl = document.getElementById('comparison');
	var state = el.checked ? '' : 'none';
	for (var i = 0; i < tbl.rows.length; i++) {
		var cell = tbl.rows[i].cells[col];
		if (cell != null)
			cell.style.display = state;
	}
}
