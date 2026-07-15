(function(){
  var KEY='siteTheme';
  function current(){ return document.documentElement.getAttribute('data-theme')||'tech'; }
  function ready(fn){ if(document.readyState!=='loading') fn(); else document.addEventListener('DOMContentLoaded',fn); }
  function taipeiNow(){
    var parts=new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Taipei',year:'numeric',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit',second:'2-digit',hourCycle:'h23'}).formatToParts(new Date());
    var p={};parts.forEach(function(x){p[x.type]=x.value;});
    return p.year+'-'+p.month+'-'+p.day+' '+p.hour+':'+p.minute+':'+p.second;
  }
  function installSystemMeta(){
    var style=document.createElement('style');
    style.textContent='.system-meta-unified{display:inline-flex;align-items:center;justify-content:flex-end;gap:12px;margin-left:0;white-space:nowrap;font-family:var(--font-mono,monospace);font-size:.72rem;letter-spacing:.05em;color:var(--text-dim,#64748b);order:999}.system-connectivity-unified{display:inline-flex;align-items:center;gap:7px}.system-meta-unified .system-dot{width:7px;height:7px;border-radius:50%;background:var(--green,#00b87a);box-shadow:0 0 8px var(--green,#00b87a);flex:0 0 auto}.system-meta-unified.is-offline .system-dot{background:var(--red,#dc2626);box-shadow:0 0 8px var(--red,#dc2626)}.system-user-unified{max-width:240px;overflow:hidden;text-overflow:ellipsis;color:var(--text,#334155)}.system-clock-unified{color:var(--cyan,#0284c7);font-family:var(--font-mono,monospace);font-size:.72rem;letter-spacing:.08em}.system-user-unified,.system-connectivity-unified,.system-clock-unified{padding-left:11px;border-left:1px solid var(--border,#dbe4ee)}.system-meta-fallback{position:fixed;top:10px;right:12px;z-index:99998;padding:7px 10px;border:1px solid var(--border,#dbe4ee);background:var(--surface,#fff)}@media(max-width:1100px){.system-meta-unified{justify-content:flex-end}.topbar-right,.nav-right,.navbar,.topbar,#topbar{flex-wrap:wrap}}@media(max-width:720px){.system-meta-unified{gap:6px;font-size:.61rem;letter-spacing:0}.system-user-unified{max-width:145px}.system-clock-unified{font-size:.61rem;letter-spacing:0}.system-user-unified,.system-connectivity-unified,.system-clock-unified{padding-left:6px}}';
    document.head.appendChild(style);

    var meta=document.createElement('div');
    meta.className='system-meta-unified';
    meta.setAttribute('data-system-meta','');
    meta.innerHTML='<span class="system-user-unified" data-system-user>尚未登入</span><span class="system-connectivity-unified"><span class="system-dot" aria-hidden="true"></span><span class="system-connectivity-label">系統連線中</span></span><span class="system-clock-unified" data-system-clock>----</span>';
    var userMeta=meta.querySelector('[data-system-user]');
    var clock=meta.querySelector('[data-system-clock]');
    var label=meta.querySelector('.system-connectivity-label');
    document.querySelectorAll('#navUser,#topClock,#clock,.online-dot,.dot-online').forEach(function(el){el.style.display='none';});
    document.querySelectorAll('span,div').forEach(function(el){
      if(!el.closest('[data-system-meta]')&&(el.textContent||'').trim()==='系統連線中'){
        var old=el.closest('.status-pill')||el;
        old.style.display='none';
      }
    });
    var host=document.querySelector('.topbar-right')||document.querySelector('.nav-right')||document.querySelector('.navbar')||document.querySelector('.topbar')||document.querySelector('#topbar')||document.querySelector('.statusbar-right')||document.querySelector('header');
    if(host)host.appendChild(meta);
    else{meta.classList.add('system-meta-fallback');document.body.appendChild(meta);}

    var deptLookupStarted=false;
    function updateUser(){
      var name=sessionStorage.getItem('user_name')||'';
      var dept=sessionStorage.getItem('user_department')||'';
      userMeta.textContent=name?(dept||'未設定單位')+'｜'+name:'尚未登入';
      var deptId=sessionStorage.getItem('user_dept_id')||'';
      if(name&&!dept&&deptId&&!deptLookupStarted){
        deptLookupStarted=true;
        fetch('https://qztffronusdhgxhjjubt.supabase.co/rest/v1/departments?select=dept_id,name,parent_id&status=eq.active',{headers:{apikey:'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJIUzI1NiIsInJlZiI6InF6dGZmcm9udXNkaGd4aGpqdWJ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2OTI1MzgsImV4cCI6MjA5NzI2ODUzOH0.FnUxot5YXI3yKCUCmJA5P4ysEJhmtaQQA6rM7MRy3oA'}})
          .then(function(r){return r.ok?r.json():[];})
          .then(function(rows){
            var map={};rows.forEach(function(d){map[d.dept_id]=d;});
            var path=[],cur=map[deptId],guard=0;
            while(cur&&guard++<10){path.unshift(cur.name);cur=map[cur.parent_id];}
            if(path.length){sessionStorage.setItem('user_department',path.join(' / '));updateUser();}
          }).catch(function(){});
      }
    }

    function update(){
      var online=navigator.onLine;
      meta.classList.toggle('is-offline',!online);
      label.textContent=online?'系統連線中':'系統離線';
      clock.textContent=taipeiNow();
      updateUser();
    }
    update();
    setInterval(update,1000);
    window.addEventListener('online',update);
    window.addEventListener('offline',update);
  }
  ready(function(){
    installSystemMeta();
    var btn=document.createElement('button');
    btn.id='themeToggleBtn';
    btn.type='button';
    btn.setAttribute('aria-label','切換介面風格');
    btn.style.cssText='position:fixed;right:16px;bottom:16px;z-index:99999;width:44px;height:44px;'+
      'border-radius:50%;font-size:18px;cursor:pointer;display:flex;align-items:center;justify-content:center;'+
      'box-shadow:0 2px 10px rgba(0,0,0,.35);transition:background .2s,color .2s,border-color .2s;';
    function paint(){
      var t=current();
      var light=t==='light';
      btn.textContent=light?'🌙':'☀️';
      btn.title=light?'切換為科技版':'切換為一般版';
      btn.style.background=light?'rgba(255,255,255,.95)':'rgba(10,20,35,.88)';
      btn.style.color=light?'#1e293b':'#fff';
      btn.style.border='1px solid '+(light?'rgba(0,0,0,.15)':'rgba(255,255,255,.25)');
    }
    btn.addEventListener('click',function(){
      var next=current()==='light'?'tech':'light';
      localStorage.setItem(KEY,next);
      document.documentElement.setAttribute('data-theme',next);
      paint();
    });
    paint();
    document.body.appendChild(btn);
  });
})();
