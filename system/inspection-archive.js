(() => {
  const archivePage = 'inspection-archived.html';
  if (location.pathname.endsWith('/' + archivePage)) return;
  const source = location.pathname.split('/').pop() || '巡檢系統';
  const target = new URL(archivePage, location.href);
  target.searchParams.set('from', source);
  location.replace(target.href);
})();
