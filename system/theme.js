(function(){
  var KEY='siteTheme';
  function current(){ return document.documentElement.getAttribute('data-theme')||'tech'; }
  function ready(fn){ if(document.readyState!=='loading') fn(); else document.addEventListener('DOMContentLoaded',fn); }
  function taipeiNow(){
    var parts=new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Taipei',year:'numeric',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit',second:'2-digit',hourCycle:'h23'}).formatToParts(new Date());
    var p={};parts.forEach(function(x){p[x.type]=x.value;});
    return p.year+'-'+p.month+'-'+p.day+' '+p.hour+':'+p.minute+':'+p.second;
  }
  function findStatusText(){
    var nodes=document.querySelectorAll('span,div');
    for(var i=0;i<nodes.length;i++){
      if((nodes[i].textContent||'').trim()==='系統連線中') return nodes[i];
    }
    return null;
  }
  function setStatusText(el,text){
    var nodes=el.childNodes;
    for(var i=0;i<nodes.length;i++){
      if(nodes[i].nodeType===3&&nodes[i].nodeValue.trim()){
        nodes[i].nodeValue=text;
        return;
      }
    }
    el.appendChild(document.createTextNode(text));
  }
  function installSystemMeta(){
    var style=document.createElement('style');
    style.textContent='.system-meta-unified{display:inline-flex;align-items:center;gap:8px;white-space:nowrap;font-family:var(--font-mono,monospace);font-size:.72rem;letter-spacing:.06em;color:var(--text-dim,#64748b)}.system-meta-unified .system-dot{width:7px;height:7px;border-radius:50%;background:var(--green,#00b87a);box-shadow:0 0 8px var(--green,#00b87a);flex:0 0 auto}.system-meta-unified.is-offline .system-dot{background:var(--red,#dc2626);box-shadow:0 0 8px var(--red,#dc2626)}.system-user-unified{max-width:240px;overflow:hidden;text-overflow:ellipsis;color:var(--text,#334155);border-left:1px solid var(--border,#dbe4ee);padding-left:8px}.system-clock-unified{color:var(--cyan,#0284c7);font-family:var(--font-mono,monospace);font-size:.72rem;letter-spacing:.08em;white-space:nowrap}.system-meta-fallback{position:fixed;top:10px;right:12px;z-index:99998;padding:7px 10px;border:1px solid var(--border,#dbe4ee);background:var(--surface,#fff)}@media(max-width:720px){.system-meta-unified{gap:5px;font-size:.62rem;letter-spacing:0}.system-user-unified{max-width:150px;padding-left:5px}.system-clock-unified{font-size:.62rem;letter-spacing:.02em}.system-connectivity-label{display:none}}';
    document.head.appendChild(style);

    var clock=document.querySelector('[data-system-clock],#topClock,#clock');
    if(clock){clock.classList.add('system-clock-unified');clock.setAttribute('data-system-clock','');}
    var existing=findStatusText();
    var meta;
    if(existing){
      meta=existing.closest('.status-pill')||existing;
      meta.classList.add('system-meta-unified');
      existing.classList.add('system-connectivity-label');
    }else{
      meta=document.createElement('span');
      meta.className='system-meta-unified';
      meta.innerHTML='<span class="system-dot" aria-hidden="true"></span><span class="system-connectivity-label">系統連線中</span>';
      var host=document.querySelector('.topbar-right,.nav-right,.navbar,.topbar,#topbar,.statusbar-right,header');
      if(clock&&clock.parentNode){clock.parentNode.insertBefore(meta,clock);}
      else if(host){host.appendChild(meta);}
      else{meta.classList.add('system-meta-fallback');document.body.appendChild(meta);}
    }
    var legacyDot=document.querySelector('.online-dot');
    if(legacyDot&&!meta.contains(legacyDot))legacyDot.remove();
    var userMeta=document.createElement('span');
    userMeta.className='system-user-unified';
    userMeta.setAttribute('data-system-user','');
    userMeta.textContent='尚未登入';
    meta.appendChild(userMeta);
    document.querySelectorAll('#navUser').forEach(function(el){el.style.display='none';});

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
      var label=meta.querySelector('.system-connectivity-label')||existing;
      if(label)setStatusText(label,online?'系統連線中':'系統離線');
      if(clock)clock.textContent=taipeiNow();
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
