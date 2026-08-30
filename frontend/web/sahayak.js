const GROUPS=["O-","O+","A-","A+","B-","B+","AB-","AB+"];
const I = {
  en: {
    s1h:"Email or mobile. We never read SMS on your phone.",
    viaEmail:"Email", viaMobile:"Mobile",
    getCode:"Get a code", enterCode:"Enter the code",
    email:"Your email", mobile:"Your mobile", send:"Send my code",
    code:"The six numbers", enter:"Enter",
    homeh:"Who are you right now?",
    needsub:"Hospital asked for blood. We start with people you trust.",
    donsub:"I can give. My phone stays hidden until I say I can go.",
    more:"More — extra help, not the emergency",
    three:"A few taps", locdisc:"Nearby matching people — only after you tap. Or pick a city. We never follow you.",
    locdisc2:"We only show who needs you nearby. Pins stay fuzzy until you tap I can go.",
    city:"City if you skip GPS", gps:"Use my location (ask first)",
    grp:"Blood group the hospital asked for", comp:"Kind of bag", urg:"When", hosp:"Hospital name",
    homeb:"Home", control:"You stay in control", myg:"My blood group", save:"Save me, then show who needs help",
    paste:"Paste a WhatsApp message (optional)",
    fillForm:"Fill the form — we have not sent anyone yet",
    opt:"Optional extras", opth:"These are not for the first minute of an emergency. Use Home if someone needs blood now.",
    slipk:"Hospital paper", sliph:"Photo stays on this phone. Type the three words on the slip. We never send from here.",
    slipp:"Photo of the slip", slipl:"What the paper says", slipf:"Fill from the paper — not sent",
    nbneed:"Your family groups (private)",
    calmk:"Calm extras",
    nbk:"Family groups", nbs:"Dadi’s group, private. Tap a name when you need blood.",
    nbh:"Short name + group. Only you see this. Never on a map.", nbwho:"Who", nbgrp:"Their group", nbsave:"Save this name",
    lanek:"Monthly bag", lanes:"Thalassemia or dialysis. Quiet. Never a public ping.",
    laneh:"One tap for a regular need. Family Ring first. No city-wide ping.", lanedue:"Day this month", lanesend:"Ask quietly for this bag",
    snk:"Same hospital tonight", sns:"Share a wait or a cab. No phone numbers.",
    snh:"We only show that another family is here. Never a phone.", snlook:"Who else is here?", snwait:"Offer a shared wait", sncab:"Offer a shared cab",
    ridek:"This train only", rides:"I am on this local. When the ride ends, the pin dies.",
    rideh:"Pick the corridor. We hide your phone. When the minutes end, you vanish.", ridemin:"Minutes on this ride", ridesend:"I am on this local",
    nightk:"Open after 10pm", nights:"Blood desks listed for late night. Official hours only.",
    nighth:"Listed night desks. Not a live camera on the door.", nightgo:"Show night desks"
  },
  hi: {
    s1h:"ईमेल या मोबाइल। हम आपके फोन पर SMS नहीं पढ़ते।",
    viaEmail:"ईमेल", viaMobile:"मोबाइल",
    getCode:"कोड लें", enterCode:"कोड लिखें",
    email:"ईमेल", mobile:"मोबाइल", send:"कोड भेजें",
    code:"छह अंक", enter:"दाखिल हों",
    homeh:"अभी आप कौन हैं?",
    needsub:"अस्पताल ने रक्त माँगा। पहले आपके भरोसे के लोग।",
    donsub:"मैं दे सकता/सकती हूँ। फोन तब तक छिपा जब तक मैं कहूँ कि मैं जाऊँगा/जाऊँगी।",
    more:"और — आपात नहीं, अतिरिक्त मदद",
    three:"कुछ टैप", locdisc:"पास के मैचिंग लोग — तभी जब आप टैप करें। या शहर चुनें। पीछे से नहीं।",
    locdisc2:"सिर्फ़ यह कि पास किसे ज़रूरत है। पिन धुंधले जब तक आप ‘मैं जा सकता हूँ’ न दबाएँ।",
    city:"शहर (GPS न दें तो)", gps:"मेरी लोकेशन (पहले पूछें)",
    grp:"अस्पताल ने जो ग्रुप लिखा", comp:"किस तरह की थैली", urg:"कब", hosp:"अस्पताल का नाम",
    homeb:"होम", control:"आपका नियंत्रण", myg:"मेरा ब्लड ग्रुप", save:"सेव करें, फिर देखें किसे मदद चाहिए",
    paste:"व्हाट्सऐप संदेश चिपकाएँ (वैकल्पिक)",
    fillForm:"फॉर्म भरें — अभी किसी को नहीं भेजा",
    opt:"वैकल्पिक", opth:"आपात के पहले मिनट के लिए नहीं। रक्त चाहिए तो होम पर जाएँ।",
    slipk:"अस्पताल की पर्ची", sliph:"फोटो इस फोन पर रहती है। पर्ची की तीन बातें लिखें। यहाँ से नहीं भेजा जाता।",
    slipp:"पर्ची की फोटो", slipl:"कागज़ पर क्या लिखा है", slipf:"पर्ची से भरें — अभी नहीं भेजा",
    nbneed:"परिवार के ग्रुप (निजी)",
    calmk:"शांत मदद",
    nbk:"परिवार के ग्रुप", nbs:"दादी का ग्रुप, निजी। रक्त चाहिए तो नाम दबाएँ।",
    nbh:"छोटा नाम + ग्रुप। सिर्फ़ आप देखें। मैप पर नहीं।", nbwho:"कौन", nbgrp:"उनका ग्रुप", nbsave:"यह नाम सेव करें",
    lanek:"मासिक थैली", lanes:"थैलेसीमिया या डायलिसिस। शांत। सार्वजनिक पिंग नहीं।",
    laneh:"नियमित ज़रूरत। पहले Family Ring। शहर-भर पिंग नहीं।", lanedue:"इस महीने का दिन", lanesend:"शांत तरीके से पूछें",
    snk:"आज यही अस्पताल", sns:"इंतज़ार या कैब बाँटें। फोन नहीं।",
    snh:"सिर्फ़ यह कि और परिवार यहाँ है। फोन कभी नहीं।", snlook:"और कौन है?", snwait:"इंतज़ार बाँटें", sncab:"कैब बाँटें",
    ridek:"सिर्फ़ यह ट्रेन", rides:"मैं इस लोकल पर हूँ। सफर खत्म तो पिन खत्म।",
    rideh:"कॉरिडोर चुनें। फोन छिपा। मिनट खत्म तो आप गायब।", ridemin:"इस सफर के मिनट", ridesend:"मैं इस लोकल पर हूँ",
    nightk:"रात 10 बजे के बाद", nights:"रात की खिड़की वाले डेस्क। सिर्फ़ लिखे घंटे।",
    nighth:"सूचीबद्ध रात डेस्क। दरवाज़े का कैमरा नहीं।", nightgo:"रात के डेस्क दिखाएँ"
  }
};
let lang="en", token="", needG="B+", donG="O+", nbG="O-", laneG="B+", rideC="Sealdah";
let cities={}, lastReq="", lat=22.5726, lng=88.3639;
let maps={}, channel="email";
const RIDES=["Howrah","Sealdah","New Delhi"];

function setLang(l){
  lang=l;
  enBtn.classList.toggle("on", l==="en");
  hiBtn.classList.toggle("on", l==="hi");
  document.querySelectorAll("[data-i]").forEach(el=>{
    const k=el.getAttribute("data-i");
    if(I[l][k]) el.textContent=I[l][k];
  });
  if(token) fetch("/v1/language",{method:"POST",headers:h(),body:JSON.stringify({language:l})});
  paintChannel();
}

function paintChannel(){
  const em=channel==="email";
  chEmail.classList.toggle("on", em);
  chMobile.classList.toggle("on", !em);
  idLabel.textContent=I[lang][em?"email":"mobile"];
  email.type=em?"email":"tel";
  email.autocomplete=em?"email":"tel";
  email.placeholder=em?"you@email.com":"10-digit mobile";
  email.inputMode=em?"email":"numeric";
}
function setChannel(c){
  channel=c;
  paintChannel();
}

chips(needChips, needG, g=>needG=g);
chips(donChips, donG, g=>donG=g);
chips(nbChips, nbG, g=>nbG=g);
chips(laneChips, laneG, g=>laneG=g);
chips(rideChips, rideC, g=>rideC=g, RIDES);

function chips(el, cur, set, list){
  const arr=list||GROUPS;
  if(!el) return;
  el.innerHTML=arr.map(g=>`<button type="button" class="chip ${g===cur?"on":""}">${g}</button>`).join("");
  [...el.children].forEach((b,i)=>b.onclick=()=>{ set(arr[i]); chips(el, arr[i], set, list); });
}

function say(id,t){ const n=document.getElementById(id); n.textContent=t; n.classList.remove("hidden"); }
function h(){return {Authorization:"Bearer "+token,"Content-Type":"application/json"};}
function showHome(){ ["need","donate","more"].forEach(x=>document.getElementById(x).classList.add("hidden")); home.classList.remove("hidden"); }
function show(id){
  home.classList.add("hidden");
  ["need","donate","more"].forEach(x=>document.getElementById(x).classList.toggle("hidden", x!==id));
  setTimeout(()=>{
    if(id==="need"){ ensureMap("needMap"); loadNotebook(); }
    if(id==="donate") {
      ensureMap("donMap");
      // Initialize enhanced features for donate section
      if (token) {
        showGraceDate();
        if (donorHoldCard) donorHoldCard.classList.remove("hidden");
      }
    }
    if(id==="more") ensureMap("helpMap");
  }, 80);
}

function ensureMap(id){
  if(document.body.classList.contains("data-saver")) return;
  if(maps[id] || !window.L) return;
  const m=L.map(id).setView([lat,lng], 12);
  L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png",{attribution:"© OpenStreetMap"}).addTo(m);
  maps[id]=m;
  L.circle([lat,lng],{radius:900,color:"#e8c07a"}).addTo(m);
}

async function boot(){
  const m=await (await fetch("/v1/meta")).json();
  cities=m.cities||{};
  const opts=Object.keys(cities).map(c=>`<option value="${c}">${c}</option>`).join("");
  cityNeed.innerHTML=opts; cityDon.innerHTML=opts;
  cityNeed.value="Kolkata"; cityDon.value="Kolkata";
  if(laneDue){
    laneDue.innerHTML=Array.from({length:28},(_,i)=>`<option value="${i+1}">${i+1}</option>`).join("");
    laneDue.value="12";
  }
  const flags=m.flags||{};
  if(otpHonest){
    otpHonest.textContent = flags.whatsapp_enabled
      ? "WhatsApp can carry a code when the operator turns it on."
      : "Live SMS is off. The code stays on this computer until a gateway is paid. We never read SMS on your phone.";
  }
  if(localStorage.getItem("sahayak_night")==="1" || (new Date().getHours()>=22 || new Date().getHours()<6)){
    if(nightMode) nightMode.checked=true;
    setNight(true);
  }
  if(localStorage.getItem("sahayak_saver")==="1"){
    if(dataSaver) dataSaver.checked=true;
    setSaver(true);
  }
  const q=new URLSearchParams(location.search);
  if(q.get("hosp")) hospital.value=q.get("hosp");
  if(q.get("ward")) ward.value=q.get("ward");
  
  // Enhanced features initialization
  checkLowBattery();
  checkAutoNightMode();
  setInterval(checkAutoNightMode, 60000); // Check every minute
}

function cityLL(sel){
  const p=cities[sel.value];
  if(p){ lat=p[0]; lng=p[1]; }
}

function locate(which){
  if(!confirm(lang==="hi"
    ? "SaHayak पास के मैचिंग डोनर ढूँढने के लिए लोकेशन माँगता है। पीछे से नहीं। शहर से भी चल सकता है।"
    : "SaHayak asks for location only to find matching donors nearby. Foreground only. You can use a city instead.")) return;
  if(!navigator.geolocation){ say(which==="need"?"needStrip":"donateStrip","Use the city list."); return; }
  navigator.geolocation.getCurrentPosition(pos=>{
    lat=pos.coords.latitude; lng=pos.coords.longitude;
    const id=which==="need"?"needMap":"donMap";
    ensureMap(id);
    maps[id] && maps[id].setView([lat,lng], 13);
    say(which==="need"?"needStrip":"donateStrip","Location saved for this search only.");
  }, err=>{
    if(window.SahayakPause) SahayakPause.show(err && err.code===1 ? "location_denied" : "location_off");
    say(which==="need"?"needStrip":"donateStrip","Location skipped. Using the city you picked.");
  });
}

async function otp(){
  const body=channel==="mobile"?{channel:"mobile",phone:email.value,email:""}:{channel:"email",email:email.value,phone:""};
  const r=await fetch("/v1/auth/otp/request",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify(body)});
  const j=await r.json(); code.value=j.dev_otp||"";
  say("authStrip", j.human || (j.dev_otp ? "A code is ready. We never read SMS on your phone." : "Check your email."));
}
async function verify(){
  const body=channel==="mobile"?{channel:"mobile",phone:email.value,email:"",code:code.value}:{channel:"email",email:email.value,phone:"",code:code.value};
  const r=await fetch("/v1/auth/otp/verify",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify(body)});
  const j=await r.json(); if(!j.token){ say("authStrip", j.human||"That code did not match."); return; }
  token=j.token; localStorage.setItem("sahayak_token", token);
  auth.classList.add("hidden"); home.classList.remove("hidden");
  if(seekerPhone.value) await fetch("/v1/me",{method:"POST",headers:h(),body:JSON.stringify({phone:seekerPhone.value})});
}

async function createReq(){
  cityLL(cityNeed);
  if(seekerPhone.value) await fetch("/v1/me",{method:"POST",headers:h(),body:JSON.stringify({phone:seekerPhone.value, language:lang})});
  const body={
    recipient_group:needG, units:Number(units.value||2), lat, lng,
    hospital_name:hospital.value, ward:ward.value, bed:bed.value,
    urgency:urg.value, component:comp.value, language:lang,
    minor_patient:minor.checked, guardian_name:guardian.value,
    women_first: !!(document.getElementById("womenFirst")&&womenFirst.checked)
  };
  let r, j;
  try {
    r=await fetch("/v1/blood-requests",{method:"POST",headers:h(),body:JSON.stringify(body)});
    j=await r.json();
  } catch(e) {
    localStorage.setItem("sahayak_offline", JSON.stringify(body));
    say("needStrip","No network. Saved on this computer. Open SaHayak again when data returns.");
    return;
  }
  const rec=j.request||{};
  lastReq=rec.id||"";
  const guest=location.origin+(rec.guest_url||"");
  if(j.twin || j.merged){
    twinBox.classList.remove("hidden");
    twinBox.textContent = j.human || "Same emergency — we did not double-ping.";
  } else {
    twinBox.classList.add("hidden");
    showBreath();
  }
  if(undoBtn) undoBtn.classList.remove("hidden");
  if(stillBtn) stillBtn.classList.remove("hidden");
  say("needStrip", (j.human||"")+"\nFamily link (no phone): "+guest);
}

async function fillPaste(){
  const r=await fetch("/v1/need/parse",{method:"POST",headers:h(),body:JSON.stringify({text:waPaste.value,language:lang})});
  const j=await r.json();
  applyParsed(j.parsed||{});
  say("needStrip", j.human||"Check the form. Tap Send only when it looks right.");
}

function applyParsed(p){
  if(p.recipient_group){ needG=p.recipient_group; chips(needChips, needG, g=>needG=g); }
  if(p.hospital_name) hospital.value=p.hospital_name;
  if(p.ward) ward.value=p.ward;
  if(p.bed) bed.value=p.bed;
  if(p.units) units.value=p.units;
  if(p.component) comp.value=p.component;
  if(p.urgency) urg.value=p.urgency;
}

function noteSlip(){
  const f=slipFile.files&&slipFile.files[0];
  slipName.textContent=f? (f.name+" · stays on this phone") : "";
}

async function fillSlip(){
  const f=slipFile.files&&slipFile.files[0];
  const r=await fetch("/v1/need/slip",{method:"POST",headers:h(),body:JSON.stringify({
    text:slipLine.value||waPaste.value, filename:f?f.name:"", has_photo:!!f, language:lang
  })});
  const j=await r.json();
  applyParsed(j.parsed||{});
  say("needStrip", j.human||"Check the form. Nobody has been told.");
}

function easy(id){
  ["notebook","lane","samenight","ride","night"].forEach(x=>{
    const el=document.getElementById("ez-"+x);
    if(el) el.classList.toggle("hidden", x!==id);
  });
  if(id==="notebook") loadNotebook();
}

async function loadNotebook(){
  if(!token) return;
  const r=await fetch("/v1/family-notebook",{headers:h()});
  const j=await r.json();
  paintPeople(nbList, j.people||[], true);
  paintPeople(nbNeedChips, j.people||[], false);
}

function paintPeople(el, people, canRemove){
  if(!el) return;
  if(!people.length){ el.innerHTML=canRemove?'<p class="tiny">No names yet. Add Dadi or Baba above.</p>':''; return; }
  el.innerHTML=people.map(p=>`<button type="button" class="person">${p.who} · ${p.group}</button>`).join("");
  [...el.children].forEach((b,i)=>{
    b.onclick=()=>{
      needG=people[i].group;
      chips(needChips, needG, g=>needG=g);
      show("need");
      say("needStrip", people[i].who+" · "+people[i].group+". Check, then Send.");
    };
  });
}

async function saveNote(){
  const r=await fetch("/v1/family-notebook",{method:"POST",headers:h(),body:JSON.stringify({who:nbWho.value, group:nbG})});
  const j=await r.json();
  say("moreStrip", j.human||"Saved.");
  if(j.people) paintPeople(nbList, j.people, true);
  paintPeople(nbNeedChips, j.people||[], false);
}

async function sendMonthly(){
  cityLL(cityNeed);
  const body={
    recipient_group:laneG, units:Number(laneUnits.value||1), lat, lng,
    hospital_name:laneHosp.value, ward:"", bed:"",
    urgency:"scheduled", component:"whole", language:lang,
    lane:"regular", due_on:String(laneDue.value||"12")
  };
  const r=await fetch("/v1/blood-requests",{method:"POST",headers:h(),body:JSON.stringify(body)});
  const j=await r.json();
  const rec=j.request||{};
  lastReq=rec.id||lastReq;
  const guest=location.origin+(rec.guest_url||"");
  say("moreStrip", (j.human||"")+(rec.guest_url? "\nFamily link (no phone): "+guest:""));
}

async function lookSameNight(){
  const r=await fetch("/v1/same-night?hospital="+encodeURIComponent(snHosp.value||""),{headers:h()});
  const j=await r.json();
  const mates=j.mates||[];
  snMates.innerHTML=mates.map(m=>`<div class="mate">${m.group||""} · ${m.units_progress||""} · ward ${m.ward||"—"} · no phone</div>`).join("") || "";
  say("moreStrip", j.human||"");
}

async function shareNight(kind){
  const r=await fetch("/v1/same-night/share",{method:"POST",headers:h(),body:JSON.stringify({hospital_name:snHosp.value, kind})});
  const j=await r.json();
  say("moreStrip", j.human||"Offered.");
}

async function postRide(){
  const r=await fetch("/v1/give-windows",{method:"POST",headers:h(),body:JSON.stringify({kind:"ride", corridor:rideC, minutes:Number(rideMin.value||40), lat, lng})});
  const j=await r.json();
  say("moreStrip", j.human||"Ride posted.");
}

async function dirNight(){
  const r=await fetch("/v1/directory?night=true",{headers:h()});
  const j=await r.json();
  say("moreStrip", (j.entries||[]).map(e=>e.name+" · "+(e.hours||"")+" · "+(e.phone||"")).join("\n") || j.human);
  ensureMap("helpMap");
  (j.entries||[]).forEach(e=>{
    if(maps.helpMap && e.lat) L.marker([e.lat,e.lng]).addTo(maps.helpMap).bindPopup(e.name+"<br>"+(e.hours||"")+"<br>after 10pm");
  });
}

async function saveDonor(){
  cityLL(cityDon);
  await fetch("/v1/donors/me",{method:"POST",headers:h(),body:JSON.stringify({
    blood_group:donG, lat, lng, available:avail.checked, self_hold:hold.checked, phone:donPhone.value, city:cityDon.value,
    woman: !!(document.getElementById("donWoman")&&donWoman.checked)
  })});
  const g=await fetch("/v1/grace-date",{headers:h()});
  const gj=await g.json();
  if(graceStrip){ graceStrip.textContent=gj.human||gj.message||""; graceStrip.classList.remove("hidden"); }
  const r=await fetch("/v1/blood-requests/open",{headers:h()});
  const j=await r.json();
  openList.innerHTML=(j.requests||[]).map(x=>`<div class="req"><div><strong>${x.recipient_group}</strong> at ${x.hospital_name}<div class="tiny">${x.units_progress} · phone hidden · approx pin</div></div><button class="cta trust" style="width:auto;margin:0;padding:10px 16px" onclick="accept('${x.id}')">I can go</button></div>`).join("") || '<p class="tiny">No open requests in this city yet.</p>';
  ensureMap("donMap");
  (j.requests||[]).forEach(x=>{
    if(maps.donMap && x.lat) L.circleMarker([x.lat,x.lng],{radius:8,color:"#c42b4a"}).addTo(maps.donMap).bindPopup(x.recipient_group+" · "+x.hospital_name);
  });
  say("donateStrip", j.human||"Open needs nearby.");
}
async function accept(id){
  const r=await fetch("/v1/blood-requests/"+id+"/accept",{method:"POST",headers:h(),body:"{}"});
  const j=await r.json();
  const tel=j.phone? (" Call family: "+j.phone) : "";
  say("donateStrip", (j.human||"") + tel);
}

async function inbox(){ const r=await fetch("/v1/inbox",{headers:h()}); const j=await r.json(); say("moreStrip", (j.notices||[]).map(n=>n.body).slice(-5).join(" · ") || j.human); }
async function assist(){
  const r=await fetch("/v1/assistant/messages",{method:"POST",headers:h(),body:JSON.stringify({text:"need B+ at SSKM",lat:String(lat),lng:String(lng)})});
  const j=await r.json(); say("moreStrip", j.human||("Heard "+j.parsed_group));
}
async function dir(){
  const r=await fetch("/v1/directory",{headers:h()}); const j=await r.json();
  say("moreStrip", (j.entries||[]).map(e=>e.name+" · "+(e.hours||"")+" · "+(e.phone||"")).join("\n"));
  ensureMap("helpMap");
  (j.entries||[]).forEach(e=>{
    if(maps.helpMap && e.lat) L.marker([e.lat,e.lng]).addTo(maps.helpMap).bindPopup(e.name+"<br>"+(e.hours||"")+"<br><a href='tel:"+e.phone+"'>"+(e.phone||"")+"</a>");
  });
}
async function post(path,body){ const r=await fetch(path,{method:"POST",headers:h(),body:JSON.stringify(body)}); const j=await r.json(); say("moreStrip", j.human || (j.ok?"Saved.":"Could not save.")); }
async function giveWin(){
  await post("/v1/give-windows",{place:"Howrah",until:"19:00",lat,lng,station_lat:22.583,station_lng:88.3426,station_radius_km:8});
}
async function camps(){
  const r=await fetch("/v1/camps",{headers:h()}); const j=await r.json();
  const list=j.camps||[];
  if(!list.length){ say("moreStrip","No camp yet. Hospitals add them on the Console."); return; }
  const c=list[0];
  await post("/v1/camps/"+c.id+"/rsvp",{});
}
async function copyStatus(){
  if(!lastReq){ const mine=await (await fetch("/v1/blood-requests/mine",{headers:h()})).json(); lastReq=(mine.requests&&mine.requests[0]&&mine.requests[0].id)||""; }
  if(!lastReq){ say("moreStrip","Send a Need blood first."); return; }
  const t=await (await fetch("/v1/status-card/"+lastReq+"?language="+lang,{headers:h()})).text();
  await navigator.clipboard.writeText(t);
  say("moreStrip","Copied. You paste it on WhatsApp Status yourself. SaHayak does not post.");
}
async function delMe(){
  if(!confirm("Delete your SaHayak account on this copy?")) return;
  const r=await fetch("/v1/me",{method:"DELETE",headers:h()});
  const j=await r.json();
  say("moreStrip", j.human||"Deleted.");
  token=""; localStorage.removeItem("sahayak_token");
}

function setNight(on){
  document.body.classList.toggle("night-mode", !!on);
  localStorage.setItem("sahayak_night", on?"1":"0");
}
function setSaver(on){
  document.body.classList.toggle("data-saver", !!on);
  localStorage.setItem("sahayak_saver", on?"1":"0");
}
function paintHold(){
  if(holdRing) holdRing.classList.toggle("on", !!(hold&&hold.checked));
}
function showBreath(){
  const b=document.getElementById("breath");
  if(!b) return;
  b.classList.remove("hidden");
  setTimeout(()=> b.classList.add("hidden"), 8000);
}
async function undoNeed(){
  if(!lastReq){ say("needStrip","Send first."); return; }
  const r=await fetch("/v1/blood-requests/"+lastReq+"/undo",{method:"POST",headers:h(),body:"{}"});
  const j=await r.json();
  say("needStrip", j.human||"Undone.");
}
async function stillNeed(){
  if(!lastReq){ say("needStrip","Send first."); return; }
  const r=await fetch("/v1/blood-requests/"+lastReq+"/still-need",{method:"POST",headers:h(),body:"{}"});
  const j=await r.json();
  say("needStrip", j.human||"Family Ring again.");
}
async function saveStandIn(){
  const name=(document.getElementById("standInName")||{}).value||"sister";
  const r=await fetch("/v1/stand-in",{method:"POST",headers:h(),body:JSON.stringify({name, stand_in_user_id:name})});
  const j=await r.json();
  say("moreStrip", j.human||"Saved.");
}

/* === Phase 4: Enhanced Features JavaScript === */

// Low battery detection and display
function checkLowBattery() {
  if (!navigator.getBattery) return;
  navigator.getBattery().then(battery => {
    function updateBattery() {
      if (battery.level <= 0.2) {
        lowBatteryStrip.classList.remove("hidden");
        const percent = Math.round(battery.level * 100);
        lowBatteryText.textContent = 
          lang === "hi" 
            ? `बैटरी कम है (${percent}%). मैप बंद। शहर सूची का उपयोग करें।`
            : `Low battery (${percent}%). Maps off. Use city list.`;
      } else {
        lowBatteryStrip.classList.add("hidden");
      }
    }
    updateBattery();
    battery.addEventListener("levelchange", updateBattery);
  });
}

function dismissLowBattery() {
  lowBatteryStrip.classList.add("hidden");
}

// Auto night mode at 22:00-06:00
function checkAutoNightMode() {
  const hour = new Date().getHours();
  if (hour >= 22 || hour < 6) {
    if (!document.body.classList.contains("night-mode")) {
      setNight(true);
      if (nightMode) nightMode.checked = true;
    }
  } else {
    if (document.body.classList.contains("night-mode") && localStorage.getItem("sahayak_night") !== "1") {
      setNight(false);
      if (nightMode) nightMode.checked = false;
    }
  }
}

// Update donor hold status (fasting/fever)
async function updateDonorHold() {
  if (!token) return;
  const fasting = fastingToggle?.checked || false;
  const fever = feverToggle?.checked || false;
  
  if (donorHoldCard) {
    if (fasting || fever) {
      donorHoldCard.classList.remove("hidden");
      if (holdWarning) {
        holdWarning.classList.remove("hidden");
      }
    } else {
      if (holdWarning) holdWarning.classList.add("hidden");
    }
  }
  
  const r = await fetch("/v1/donors/me/hold", {
    method: "POST",
    headers: h(),
    body: JSON.stringify({ fasting, fever })
  });
  const j = await r.json();
  if (!j.ok && window.SahayakPause) {
    SahayakPause.show(j.error || "hold_update_failed");
  }
}

// Load and display feature flags
async function loadFeatureFlags() {
  if (!token) return;
  const r = await fetch("/v1/feature-flags", { headers: h() });
  const j = await r.json();
  if (j.features) {
    // Enable/disable features based on flags
    // For now, just log them
    console.log("Feature flags loaded:", j.features);
  }
  return j.features || {};
}

// Display grace date card
async function showGraceDate() {
  if (!token || !graceDateCard) return;
  const r = await fetch("/v1/grace-date", { headers: h() });
  const j = await r.json();
  
  if (j.last_donation_days_ago === undefined || j.last_donation_days_ago < 0) {
    graceDateCard.classList.add("hidden");
    return;
  }
  
  const isEligible = j.last_donation_days_ago >= j.next_eligible_days_away;
  graceDateCard.classList.remove("hidden");
  
  if (graceStatus) {
    graceStatus.textContent = isEligible 
      ? (lang === "hi" ? "आप अब दे सकते हैं" : "You're eligible now")
      : (lang === "hi" ? "आप अभी नहीं दे सकते" : "Not eligible yet");
  }
  
  if (graceDaysAgo) {
    graceDaysAgo.textContent = lang === "hi"
      ? `आपने ${j.last_donation_days_ago} दिन पहले दिया था`
      : `You donated ${j.last_donation_days_ago} days ago`;
  }
  
  if (graceDisclaimer) {
    graceDisclaimer.textContent = lang === "hi"
      ? "चिकित्सीय सलाह नहीं। सिर्फ़ जानकारी।"
      : "Not medical advice. Informational only.";
  }
  
  document.body.classList.toggle("grace-eligible", isEligible);
}

// Render bag progress visual
function renderBagProgress(total, accepted) {
  const container = document.createElement("div");
  container.className = "bag-progress";
  
  const remaining = total - accepted;
  
  for (let i = 0; i < accepted; i++) {
    const drop = document.createElement("div");
    drop.className = "bag-drop filled";
    drop.innerHTML = "✓";
    container.appendChild(drop);
  }
  
  for (let i = 0; i < Math.max(0, remaining - 1); i++) {
    const drop = document.createElement("div");
    drop.className = "bag-drop promised";
    drop.innerHTML = "◐";
    container.appendChild(drop);
  }
  
  const text = document.createElement("div");
  text.className = "bag-progress-text";
  text.textContent = lang === "hi"
    ? `${accepted}/${total} मिल गए`
    : `${accepted}/${total} collected`;
  container.appendChild(text);
  
  return container;
}

// Render surgeon waiting pulse
function renderSurgeonWaiting(unitsNeeded, unitsAccepted) {
  if (unitsNeeded <= unitsAccepted) return null;
  
  const container = document.createElement("div");
  container.className = "surgeon-pulse";
  
  const text = document.createElement("div");
  text.className = "surgeon-pulse-text";
  text.innerHTML = `<svg class="ico" viewBox="0 0 24 24" fill="currentColor" style="margin-right:8px;display:inline-block"><path d="M12 2c-5.33 4.55-8 8.48-8 11.8 0 4.98 3.8 8.2 8 8.2s8-3.22 8-8.2c0-3.32-2.67-7.25-8-11.8zm0 18c-3.35 0-6-2.57-6-6.1 0-2.6 1.35-5.55 6-9.14 4.65 3.59 6 6.54 6 9.14 0 3.53-2.65 6.1-6 6.1z"/></svg>` + 
    (lang === "hi" 
      ? `सर्जन का इंतज़ार — अभी ${unitsNeeded - unitsAccepted} यूनिट चाहिए`
      : `Surgeon waiting — ${unitsNeeded - unitsAccepted} more units needed`);
  container.appendChild(text);
  
  return container;
}

// Display heatmap grid
function renderHeatmapGrid(points) {
  if (!heatmapGrid) return;
  
  if (!points || points.length === 0) {
    heatmapGrid.innerHTML = lang === "hi"
      ? "<p class=\"heatmap-title\">कोई खुली रिक्वेस्ट नहीं</p>"
      : "<p class=\"heatmap-title\">No open requests</p>";
    return;
  }
  
  let html = `<p class="heatmap-title">${lang === "hi" ? "जरूरत का घनत्व" : "Need intensity"}</p>`;
  html += '<div class="heatmap-legend">';
  html += '<div class="heatmap-legend-item"><div class="heatmap-legend-dot" style="background: rgba(139, 115, 85, 0.6)"></div><span>' + 
    (lang === "hi" ? "कम" : "Low") + '</span></div>';
  html += '<div class="heatmap-legend-item"><div class="heatmap-legend-dot" style="background: var(--gold)"></div><span>' + 
    (lang === "hi" ? "अधिक" : "High") + '</span></div>';
  html += '</div>';
  
  points.forEach((p, i) => {
    let intensity = p.intensity || 50;
    let className = "heatmap-point-low";
    if (intensity >= 75) className = "heatmap-point-high";
    else if (intensity >= 50) className = "heatmap-point-medium";
    
    html += `<div class="heatmap-point ${className}">
      <div class="heatmap-point-text">
        <p>${lang === "hi" ? "रिक्वेस्ट" : "Request"} ${i + 1}: ${p.units_needed} ${lang === "hi" ? "चाहिए" : "needed"}, ${p.units_accepted} ${lang === "hi" ? "मिल गए" : "accepted"}</p>
      </div>
      <div class="heatmap-point-intensity">${Math.round(intensity)}%</div>
    </div>`;
  });
  
  heatmapGrid.innerHTML = html;
}

// Enhanced saveDonor with new features
const _saveDonor = saveDonor;
saveDonor = async function() {
  await _saveDonor();
  await showGraceDate();
  
  // Load open requests with enhanced data
  const r = await fetch("/v1/blood-requests/open", { headers: h() });
  const j = await r.json();
  
  // Render enhanced open requests list
  if (openList) {
    let html = "";
    (j.requests || []).forEach(x => {
      html += `<div class="request-card">
        <div class="request-header">
          <div class="request-title">${x.recipient_group} at ${x.hospital_name}</div>
          <div class="request-urgency">${x.urgency === "critical" ? (lang === "hi" ? "तुरंत" : "NOW") : (lang === "hi" ? "योजनित" : "Planned")}</div>
        </div>`;
      
      if (x.bag_progress) {
        html += renderBagProgress(x.bag_progress.total, x.bag_progress.accepted).outerHTML;
      }
      
      if (x.surgeon_waiting) {
        html += renderSurgeonWaiting(x.units, x.bag_progress?.accepted || 0).outerHTML;
      }
      
      if (x.walk_visual) {
        html += `<div class="walk-card">
          <div class="card-title">${lang === "hi" ? "इसी जगह जाइए" : "Go to this place"}</div>
          <div class="walk-step">
            <div class="label">${lang === "hi" ? "अस्पताल" : "Hospital"}</div>
            <div class="value">${x.walk_visual.hospital_name || x.hospital_name}</div>
          </div>
          <div class="walk-step">
            <div class="label">${lang === "hi" ? "वार्ड" : "Ward"}</div>
            <div class="value">${x.walk_visual.ward_number || x.ward}</div>
          </div>
          <div class="walk-step">
            <div class="label">${lang === "hi" ? "ब्लड बैंक" : "Blood bank"}</div>
            <div class="value">${lang === "hi" ? "दरवाज़ा — बिस्तर पर नहीं" : "Door — not bedside"}</div>
          </div>
          <div class="phone-note">${lang === "hi" ? "फोन स्वीकार के बाद ही" : "Phone only after you accepted"}</div>
        </div>`;
      }
      
      html += `<button class="cta trust" style="width:100%;margin-top:10px;padding:12px 16px" onclick="accept('${x.id}')">${lang === "hi" ? "मैं जा सकता/सकती हूँ" : "I can go"}</button></div>`;
    });
    
    if (!html) {
      html = `<p class="tiny">${lang === "hi" ? "इस शहर में अभी कोई खुली रिक्वेस्ट नहीं" : "No open requests in this city yet."}</p>`;
    }
    openList.innerHTML = html;
  }
  
  // Show heatmap if available
  if (j.heatmap_points) {
    renderHeatmapGrid(j.heatmap_points);
  }
};

boot().then(async ()=>{
  const t=localStorage.getItem("sahayak_token");
  if(t){
    token=t;
    const me=await fetch("/v1/me",{headers:h()});
    if(me.ok){ auth.classList.add("hidden"); home.classList.remove("hidden"); }
    else localStorage.removeItem("sahayak_token");
  }
  const off=localStorage.getItem("sahayak_offline");
  if(off && token){
    await fetch("/v1/offline-queue",{method:"POST",headers:h(),body:off});
    localStorage.removeItem("sahayak_offline");
  }
  const tour=new URLSearchParams(location.search).get("tour");
  if(tour==="home"||tour==="need"||tour==="donate"||tour==="more"){
    auth.classList.add("hidden");
    if(tour==="home"){ home.classList.remove("hidden"); ["need","donate","more"].forEach(x=>document.getElementById(x).classList.add("hidden")); }
    else show(tour);
  }
});
