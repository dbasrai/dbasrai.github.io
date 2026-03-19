(() => {
  const container = document.getElementById('shows-list');
  if (!container) return;

  const jsonUrl = container.dataset.jsonUrl;
  if (!jsonUrl) {
    container.textContent = 'Shows data source not configured.';
    return;
  }

  const formatStart = (item) => {
    if (item.allDay) {
      return new Date(item.start).toLocaleDateString(undefined, {
        timeZone: item.timeZone || 'America/Chicago',
        year: 'numeric',
        month: 'short',
        day: '2-digit',
      });
    }

    return new Date(item.start).toLocaleString(undefined, {
      timeZone: item.timeZone || 'America/Chicago',
      weekday: 'short',
      year: 'numeric',
      month: 'short',
      day: '2-digit',
      hour: 'numeric',
      minute: '2-digit',
    });
  };

  const escapeHtml = (s) =>
    String(s ?? '')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#039;');

  const render = (items) => {
    if (!items || items.length === 0) {
      container.textContent = 'No upcoming shows found.';
      return;
    }

    const sorted = [...items].sort((a, b) => new Date(a.start).getTime() - new Date(b.start).getTime());

    container.innerHTML = `
      <div class="list-group">
        ${sorted
          .map((item) => {
            const title = escapeHtml(item.summary);
            const when = escapeHtml(formatStart(item));
            const location = item.location ? `<div class="text-muted small">${escapeHtml(item.location)}</div>` : '';
            const recurring = item.recurring && item.rruleLabel ? `<div class="small text-muted">Recurring: ${escapeHtml(item.rruleLabel)}</div>` : '';

            return `
              <div class="list-group-item">
                <div class="fw-bold">${title}</div>
                <div>${when}</div>
                ${location}
                ${recurring}
              </div>
            `;
          })
          .join('')}
      </div>
    `;
  };

  fetch(jsonUrl, { cache: 'no-store' })
    .then((r) => {
      if (!r.ok) throw new Error(`HTTP ${r.status} ${r.statusText}`);
      return r.json();
    })
    .then(render)
    .catch((err) => {
      container.textContent = `Failed to load upcoming shows. ${err?.message ? `(${err.message})` : ''}`.trim();
    });
})();

