const challenges = [
  { id: 1, category: "Connect", level: "tiny stretch", title: "Give someone a specific compliment.", why: "Not “nice shirt.” Tell them exactly what you noticed." },
  { id: 2, category: "Speak", level: "tiny stretch", title: "Ask one question in class.", why: "Even if your voice does that weird squeak. Especially then." },
  { id: 3, category: "Try", level: "warm-up", title: "Try one bite of something unfamiliar.", why: "Your taste buds deserve a plot twist." },
  { id: 4, category: "Connect", level: "tiny stretch", title: "Sit near someone new at lunch.", why: "You do not have to become best friends by dessert." },
  { id: 5, category: "Reset", level: "quiet brave", title: "Name the feeling you are actually having.", why: "Upgrade “fine” to one more honest word." },
  { id: 6, category: "Speak", level: "medium brave", title: "Say “I don’t understand yet.”", why: "Confusion is allowed. Pretending is exhausting." },
  { id: 7, category: "Connect", level: "tiny stretch", title: "Text someone you have been meaning to check on.", why: "Four words work: “Hey, how are you?”" },
  { id: 8, category: "Try", level: "medium brave", title: "Join something for ten minutes.", why: "A game, a club, a conversation. You can reassess at minute eleven." },
  { id: 9, category: "Reset", level: "quiet brave", title: "Take three slow breaths before replying.", why: "A dramatic pause, but useful." },
  { id: 10, category: "Speak", level: "medium brave", title: "Share an idea before it feels perfect.", why: "Rough drafts are allowed to leave your brain." },
  { id: 11, category: "Connect", level: "tiny stretch", title: "Learn how to pronounce someone’s name.", why: "Ask, listen, try again. Names matter." },
  { id: 12, category: "Try", level: "tiny stretch", title: "Do one thing without asking if it looks cool.", why: "Dance. Draw. Wear the socks. Survive the scandal." },
  { id: 13, category: "Reset", level: "medium brave", title: "Turn off your phone for twenty minutes.", why: "It will miss you terribly. It will recover." },
  { id: 14, category: "Speak", level: "bold-ish", title: "Disagree without making it personal.", why: "Try: “I see it differently because…”" },
  { id: 15, category: "Connect", level: "medium brave", title: "Invite someone who might be left out.", why: "Make the circle one person wider." },
  { id: 16, category: "Try", level: "medium brave", title: "Attempt the hard version first.", why: "One honest try. You can switch modes after." },
  { id: 17, category: "Reset", level: "quiet brave", title: "Write down one thing you handled well.", why: "Your brain keeps receipts for mistakes. Add a better one." },
  { id: 18, category: "Speak", level: "bold-ish", title: "Ask for help with one real thing.", why: "Specific is good: “Can you show me the first step?”" },
  { id: 19, category: "Connect", level: "medium brave", title: "Say thank you—and include the reason.", why: "Tell them what their help changed for you." },
  { id: 20, category: "Try", level: "bold-ish", title: "Start before you feel ready.", why: "Two minutes counts. Momentum is sneaky." },
  { id: 21, category: "Reset", level: "quiet brave", title: "Replace one mean self-joke.", why: "Talk to yourself like you are on your own team." },
  { id: 22, category: "Speak", level: "bold-ish", title: "Tell a friend what you need.", why: "No mind reading required: “Could you just listen?” works." },
  { id: 23, category: "Connect", level: "bold-ish", title: "Introduce yourself first.", why: "Name. Smile. Tiny leap. Done." },
  { id: 24, category: "Try", level: "tiny stretch", title: "Wear or carry something that feels like you.", why: "Even if it earns one raised eyebrow." },
  { id: 25, category: "Reset", level: "quiet brave", title: "Let one small mistake stay unhidden.", why: "Correct it if needed. Skip the five-minute apology tour." },
  { id: 26, category: "Speak", level: "medium brave", title: "Say “no” to one thing you do not have room for.", why: "A full sentence is optional. A boundary is not rude." },
  { id: 27, category: "Connect", level: "bold-ish", title: "Repair one awkward moment.", why: "Try: “That came out wrong. Can I try again?”" },
  { id: 28, category: "Try", level: "bold-ish", title: "Show someone something you made.", why: "No pre-apology. No “it’s bad, but…”" },
  { id: 29, category: "Reset", level: "medium brave", title: "Choose a second impression.", why: "Notice one new thing about someone you judged too quickly." },
  { id: 30, category: "Speak", level: "bold-ish", title: "Stand up for someone in a small, safe way.", why: "Include them, interrupt a joke, or get a trusted adult." },
  { id: 31, category: "Connect", level: "tiny stretch", title: "Ask someone what song they have on repeat.", why: "Listen to the answer. Bonus brave: play the song later." },
  { id: 32, category: "Speak", level: "medium brave", title: "Volunteer an answer before you are completely sure.", why: "Certainty is not an entrance requirement." },
  { id: 33, category: "Try", level: "tiny stretch", title: "Take a different route through a familiar place.", why: "Keep it safe. Let your routine be mildly surprised." },
  { id: 34, category: "Reset", level: "quiet brave", title: "Write one worry and circle the part you can control.", why: "The rest can sit outside the circle for a minute." },
  { id: 35, category: "Connect", level: "medium brave", title: "Introduce two people who might get along.", why: "Human bridge. Very small infrastructure project." },
  { id: 36, category: "Speak", level: "tiny stretch", title: "Ask one real follow-up question.", why: "Go one step past nodding like you understood everything." },
  { id: 37, category: "Try", level: "medium brave", title: "Practice a skill you avoid for five minutes.", why: "Being bad at minute one is extremely normal." },
  { id: 38, category: "Reset", level: "quiet brave", title: "Put your phone out of reach for one whole task.", why: "Not face-down. Actually out of reach. Bold." },
  { id: 39, category: "Connect", level: "medium brave", title: "Send a voice note to someone you miss.", why: "Your unedited voice counts as a complete message." },
  { id: 40, category: "Speak", level: "bold-ish", title: "Correct one wrong assumption about you—kindly.", why: "Try: “Actually, that’s not quite me.”" },
  { id: 41, category: "Try", level: "medium brave", title: "Do one small thing alone you usually wait to do with someone.", why: "A library table, a snack, a short walk in a safe place." },
  { id: 42, category: "Reset", level: "quiet brave", title: "Let an awkward silence last five seconds.", why: "Do not rescue it. Count slowly. Notice that everyone survives." },
  { id: 43, category: "Connect", level: "medium brave", title: "Thank someone whose work is usually invisible.", why: "Notice the setup, cleanup, fixing, carrying, or remembering." },
  { id: 44, category: "Speak", level: "bold-ish", title: "Share your opinion before checking everyone else’s.", why: "Your first thought is allowed into the room." },
  { id: 45, category: "Try", level: "medium brave", title: "Make something with a material you normally ignore.", why: "Tape, cardboard, voice memo, mud. Tiny laboratory rules." },
  { id: 46, category: "Reset", level: "medium brave", title: "Leave one nonessential thing unfinished overnight.", why: "Perfection can sleep outside for once." },
  { id: 47, category: "Connect", level: "tiny stretch", title: "Ask someone older what they were like at your age.", why: "Adults had awkward phases. Important historical evidence." },
  { id: 48, category: "Speak", level: "medium brave", title: "Admit one small mistake without explaining it away.", why: "A clean “that was me” is enough." },
  { id: 49, category: "Try", level: "bold-ish", title: "Be the first person to start a group task.", why: "Open the document. Move the chair. Say the first sentence." },
  { id: 50, category: "Reset", level: "quiet brave", title: "Name one useful thing your body did today.", why: "Breathing counts. Carrying you around definitely counts." },
  { id: 51, category: "Connect", level: "tiny stretch", title: "Offer help before someone asks.", why: "Carry one thing. Hold one door. Make one task lighter." },
  { id: 52, category: "Speak", level: "medium brave", title: "Say “I need a minute” instead of faking an answer.", why: "A pause can be more honest than a fast yes." },
  { id: 53, category: "Try", level: "bold-ish", title: "Practice where someone can see or hear you for five minutes.", why: "Let the rough draft be publicly alive." },
  { id: 54, category: "Reset", level: "medium brave", title: "Choose rest before you have completely earned it.", why: "Rest is fuel, not a prize at the bottom of the tank." },
  { id: 55, category: "Connect", level: "medium brave", title: "Ask someone to teach you one small thing.", why: "A knot, a shortcut, a word, a recipe. Be teachable." },
  { id: 56, category: "Speak", level: "bold-ish", title: "Ask for one specific piece of feedback.", why: "Specific question. Useful answer. Less mysterious doom." },
  { id: 57, category: "Try", level: "medium brave", title: "Enter a room without checking your phone.", why: "Look up. Arrive on purpose." },
  { id: 58, category: "Reset", level: "quiet brave", title: "Celebrate what is finished before naming what needs fixing.", why: "Good work gets one full sentence before the critique arrives." },
  { id: 59, category: "Connect", level: "bold-ish", title: "Tell someone what you appreciate about how they think.", why: "Compliment the mind, not just the result." },
  { id: 60, category: "Speak", level: "bold-ish", title: "Change the subject when a group conversation turns mean.", why: "A small redirect can be a quiet rescue." }
];

const ROUND_SIZE = 30;
const categoryColors = { Connect: "var(--blue)", Speak: "var(--pink)", Try: "var(--green)", Reset: "var(--lavender)" };
const comments = [
  "still thinking about it.", "one puff. balloon noticed.", "slightly less floppy.", "a cautious wobble.", "standing a little taller.",
  "swaying on purpose.", "testing the air.", "string getting nervous.", "heels off the ground.", "actually floating now.",
  "small lift. big deal.", "airborne and curious.", "learning to steer.", "left turn for no reason.", "right turn. also no reason.",
  "halfway and airborne.", "practicing a tiny dance.", "the wobble has rhythm.", "confidence doing loops.", "sky looking possible.",
  "officially hard to contain.", "balloon has opinions.", "dancing without permission.", "preparing to zoom.", "zoom rehearsal successful.",
  "main-character airspace.", "string barely involved.", "nearly ungovernable.", "one puff from legend.", "warming up the confetti.",
  "maximum puff. balloon has left the building."
];
const storeKey = "tiny-brave-progress-v3";
const seenPingKey = "tiny-brave-seen-pings";
const state = loadState();
if (state.completed.length >= ROUND_SIZE) state.showingReward = true;
let toastTimer;
let pingTimer;
let drawing = false;
let drawColor = "#171713";
let eraseMode = false;
let mediaStream = null;
let mediaRecorder = null;
let videoChunks = [];
let recordedBlob = null;
let recordedUrl = null;
let recordingTimer = null;
let secondsLeft = 15;
let discardRecording = false;
let reelTimer = null;
let reelItems = [];
let reelIndex = 0;
let finaleTimer = null;
let finalePending = false;

const $ = selector => document.querySelector(selector);
const els = {
  root: document.documentElement, doorScreen: $("#doorScreen"), openAppButton: $("#openAppButton"),
  completedCount: $("#completedCount"), progressbar: $("[role='progressbar']"), puffMarks: $("#puffMarks"), balloonComment: $("#balloonComment"), balloonZone: $(".balloon-zone"),
  categoryPill: $("#categoryPill"), difficultyLabel: $("#difficultyLabel"), challengeTitle: $("#challengeTitle"), challengeWhy: $("#challengeWhy"), roundLabel: $("#roundLabel"),
  activeActions: $("#activeActions"), rewardCard: $("#rewardCard"), rewardTitle: $("#rewardTitle"), completeButton: $("#completeButton"), swapButton: $("#swapButton"), nextButton: $("#nextButton"), newRoundButton: $("#newRoundButton"),
  drawTab: $("#drawTab"), videoTab: $("#videoTab"), drawPanel: $("#drawPanel"), videoPanel: $("#videoPanel"), drawingCanvas: $("#drawingCanvas"), canvasHint: $("#canvasHint"), eraserButton: $("#eraserButton"), clearCanvasButton: $("#clearCanvasButton"), saveDrawingButton: $("#saveDrawingButton"),
  videoPreview: $("#videoPreview"), videoPlaceholder: $("#videoPlaceholder"), recordTimer: $("#recordTimer"), videoNote: $("#videoNote"), recordButton: $("#recordButton"), saveVideoButton: $("#saveVideoButton"), retakeButton: $("#retakeButton"), saveStatus: $("#saveStatus"),
  trackButton: $("#trackButton"), progressLink: $("#progressLink"), progressDialog: $("#progressDialog"), closeProgressButton: $("#closeProgressButton"), statsCompleted: $("#statsCompleted"), statsResponses: $("#statsResponses"), statsStreak: $("#statsStreak"), responseGallery: $("#responseGallery"), emptyGallery: $("#emptyGallery"), completedList: $("#completedList"), playReelButton: $("#playReelButton"),
  circleButton: $("#circleButton"), circleChip: $("#circleChip"), circleChipText: $("#circleChipText"), circleDialog: $("#circleDialog"), closeCircleButton: $("#closeCircleButton"), circleSetup: $("#circleSetup"), circleHome: $("#circleHome"), createCircleButton: $("#createCircleButton"), joinCircleForm: $("#joinCircleForm"), circleCodeInput: $("#circleCodeInput"), circleCode: $("#circleCode"), inviteCircleButton: $("#inviteCircleButton"), memberList: $("#memberList"), pingFeed: $("#pingFeed"), circleStatus: $("#circleStatus"),
  friendPing: $("#friendPing"), friendPingName: $("#friendPingName"), friendPingMessage: $("#friendPingMessage"),
  reelDialog: $("#reelDialog"), reelMedia: $("#reelMedia"), reelCaption: $("#reelCaption"), reelCount: $("#reelCount"), reelProgress: $("#reelProgress"), closeReelButton: $("#closeReelButton"), replayReelButton: $("#replayReelButton"),
  finaleDialog: $("#finaleDialog"), finaleReelButton: $("#finaleReelButton"), finaleArchiveButton: $("#finaleArchiveButton"), finaleRoundButton: $("#finaleRoundButton"), closeFinaleButton: $("#closeFinaleButton"),
  resetButton: $("#resetButton"), resetDialog: $("#resetDialog"), confirmResetButton: $("#confirmResetButton"), cancelResetButton: $("#cancelResetButton"),
  roundDialog: $("#roundDialog"), roundDialogTitle: $("#roundDialogTitle"), roundDialogCopy: $("#roundDialogCopy"), continueRoundButton: $("#continueRoundButton"), cancelRoundButton: $("#cancelRoundButton"),
  confetti: $("#confetti"), toast: $("#toast")
};

function loadState() {
  try {
    const saved = JSON.parse(localStorage.getItem(storeKey) || localStorage.getItem("tiny-brave-progress-v2") || localStorage.getItem("tiny-brave-progress-v1"));
    if (saved && Array.isArray(saved.completed)) return {
      completed: [...new Set(saved.completed)].filter(id => id >= 1 && id <= 60),
      current: Number.isInteger(saved.current) ? saved.current : 1,
      round: Number.isInteger(saved.round) && saved.round > 0 ? saved.round : 1,
      mode: "classic", showingReward: false, responses: [], circle: null, user: null, streak: 0
    };
  } catch (_) {}
  return { completed: [], current: 1, round: 1, mode: "classic", showingReward: false, responses: [], circle: null, user: null, streak: 0 };
}

function saveLocal() { localStorage.setItem(storeKey, JSON.stringify({ completed: state.completed, current: state.current, round: state.round, mode: "classic" })); }
function roundPool(round = state.round) { return round % 2 === 1 ? challenges.slice(0,30) : challenges.slice(30,60); }
function currentChallenge() { const pool = roundPool(); return pool.find(item => item.id === state.current) || pool[0]; }
function localDate() { const now = new Date(); return `${now.getFullYear()}-${String(now.getMonth()+1).padStart(2,"0")}-${String(now.getDate()).padStart(2,"0")}`; }

async function api(path, options = {}) {
  const response = await fetch(path, options);
  const isJson = (response.headers.get("content-type") || "").includes("application/json");
  const data = isJson ? await response.json() : null;
  if (!response.ok) throw new Error(data?.error || "Something went sideways.");
  return data;
}

async function syncFromServer() {
  try {
    const data = await api("/api/me");
    state.user = data.user || null;
    state.responses = data.profile?.responses || [];
    state.circle = data.circle || null;
    state.streak = Number(data.profile?.streak) || 0;
    const serverRound = Number.isInteger(data.profile?.round) && data.profile.round > 0 ? data.profile.round : 1;
    if (Array.isArray(data.profile?.completed)) {
      const serverCompleted = data.profile.completed.filter(id => id >= 1 && id <= 60);
      state.completed = serverRound === state.round ? [...new Set([...state.completed,...serverCompleted])] : [...new Set(serverCompleted)];
    }
    if (Number.isInteger(data.profile?.current)) state.current = data.profile.current;
    state.round = serverRound;
    if (!roundPool().some(item => item.id === state.current)) state.current = roundPool()[0].id;
    if (state.completed.length >= ROUND_SIZE) state.showingReward = true;
    saveLocal(); render();
  } catch (error) { console.warn("Using device-only progress:", error.message); }
}

function syncProgress(event = null) {
  saveLocal();
  return api("/api/progress", { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ completed: state.completed, current: state.current, round: state.round, mode: "classic", event, activityDate: localDate() }) })
    .then(data => { if (data.circle) state.circle = data.circle; if (Number.isInteger(data.streak)) state.streak = data.streak; renderCircleBits(); renderProgress(); return data; })
    .catch(() => null);
}

function balloonMotion(total) {
  const progress = Math.min(total / ROUND_SIZE, 1);
  const eased = 1 - Math.pow(1 - progress, 3);
  const amplitude = 4 + 22 * Math.pow(progress, 1.25);
  const x = Math.sin(total * Math.PI / 15) * amplitude;
  const y = 50 - 82 * eased;
  const sx = .78 + .30 * progress;
  const sy = .48 + .60 * eased;
  const tilt = total === ROUND_SIZE ? 0 : Math.sin(total * Math.PI / 15) * (1.5 + 3.5 * progress);
  return {x,y,sx,sy,tilt};
}

function sceneStage(total) {
  if (total === 0) return "grounded";
  if (total <= 8) return "sway";
  if (total <= 18) return "lift";
  if (total <= 25) return "dance";
  if (total < 30) return "zip";
  return "final";
}

function render() {
  const challenge = currentChallenge();
  const total = Math.min(state.completed.length,ROUND_SIZE);
  const progress = total/ROUND_SIZE;
  const motion = balloonMotion(total);
  els.root.style.setProperty("--progress",progress.toFixed(3));
  els.root.style.setProperty("--balloon-x",`${motion.x.toFixed(1)}px`); els.root.style.setProperty("--balloon-y",`${motion.y.toFixed(1)}px`); els.root.style.setProperty("--balloon-sx",motion.sx.toFixed(3)); els.root.style.setProperty("--balloon-sy",motion.sy.toFixed(3)); els.root.style.setProperty("--balloon-tilt",`${motion.tilt.toFixed(1)}deg`);
  els.balloonZone.dataset.stage = sceneStage(total);
  const mix=(start,end)=>start.map((value,index)=>Math.round(value+(end[index]-value)*progress));
  const top=mix([184,225,242],[57,155,210]); const bottom=mix([226,241,248],[143,213,238]);
  els.balloonZone.style.background=`linear-gradient(rgb(${top.join(",")}),rgb(${bottom.join(",")}))`;
  els.completedCount.textContent = total; els.progressbar.setAttribute("aria-valuenow",String(total)); els.balloonComment.textContent = `Puff ${total}: ${comments[total]}`;
  [...els.puffMarks.children].forEach((mark,index)=>mark.classList.toggle("done",index<total));
  els.categoryPill.textContent = challenge.category.toUpperCase(); els.categoryPill.style.background = categoryColors[challenge.category]; els.difficultyLabel.textContent = challenge.level; els.challengeTitle.textContent = challenge.title; els.challengeWhy.textContent = challenge.why;
  els.roundLabel.textContent = `DAY ${Math.min(total+1,30)} · ROUND ${state.round}${state.round===2 ? " · ALL NEW" : ""}`;
  els.activeActions.hidden = state.showingReward; els.rewardCard.hidden = !state.showingReward;
  if (state.showingReward) els.rewardTitle.textContent = total===30 ? "thirty. whole. braves." : rewardMessage(total);
  els.nextButton.hidden = total===30; els.newRoundButton.hidden = total!==30 || finalePending;
  renderProgress(); renderCircleBits();
}

function rewardMessage(total) { const messages=["look at you.","tiny task. real puff.","courage got louder.","balloon definitely saw that.","fear found this inconvenient."]; return messages[total%messages.length]; }

function completeCurrent() {
  const isNew = !state.completed.includes(state.current);
  if (isNew) state.completed.push(state.current);
  state.showingReward = true;
  if (state.completed.length===ROUND_SIZE) finalePending = true;
  prepareCapture(); syncProgress(isNew ? "complete" : null); render(); celebrate();
  if (state.completed.length===ROUND_SIZE) scheduleFinale();
}

function scheduleFinale(delay = 5000) {
  clearTimeout(finaleTimer);
  finalePending = true;
  finaleTimer = setTimeout(()=>{
    finalePending = false;
    render();
    if (state.completed.length>=ROUND_SIZE&&!els.finaleDialog.open) els.finaleDialog.showModal();
  },delay);
}

function cancelFinale() { clearTimeout(finaleTimer); finaleTimer=null; finalePending=false; }

function selectChallenge(id) {
  state.current=id; state.showingReward=false; prepareCapture(); syncProgress(); render();
  $("#main-challenge").scrollIntoView({behavior:"smooth",block:"start"});
}

function pickRandom() {
  let pool=roundPool().filter(item=>!state.completed.includes(item.id)&&item.id!==state.current);
  if(!pool.length) pool=roundPool().filter(item=>item.id!==state.current);
  selectChallenge(pool[Math.floor(Math.random()*pool.length)].id);
}

function advanceNext() { if(state.completed.length>=ROUND_SIZE){ if(!finalePending&&!els.finaleDialog.open) els.finaleDialog.showModal(); return; } pickRandom(); }

function celebrate() {
  const colors=["#ef767a","#7ac7d4","#ffffff","#9fca90","#c5afe8","#f5c841"]; const pieces=state.completed.length===30?100:28;
  for(let i=0;i<pieces;i+=1){ const piece=document.createElement("span"); piece.className="confetti-piece"; const angle=(Math.PI*2*i)/pieces; const distance=80+Math.random()*210; piece.style.setProperty("--x",`${Math.cos(angle)*distance}px`); piece.style.setProperty("--y",`${Math.sin(angle)*distance+90}px`); piece.style.setProperty("--r",`${Math.random()*720-360}deg`); piece.style.background=colors[i%colors.length]; piece.style.animationDelay=`${Math.random()*.13}s`; els.confetti.appendChild(piece); setTimeout(()=>piece.remove(),1200); }
}

function showToast(message) { clearTimeout(toastTimer); els.toast.textContent=message; els.toast.classList.add("show"); toastTimer=setTimeout(()=>els.toast.classList.remove("show"),2200); }

function switchStudio(mode) { const drawingMode=mode==="draw"; els.drawTab.setAttribute("aria-selected",String(drawingMode)); els.videoTab.setAttribute("aria-selected",String(!drawingMode)); els.drawPanel.hidden=!drawingMode; els.videoPanel.hidden=drawingMode; els.saveStatus.textContent=""; if(drawingMode) resetVideo(); }
function prepareCapture() { if(els.drawingCanvas.getContext) resetCanvas(); resetVideo(); switchStudio("draw"); eraseMode=false; els.eraserButton.classList.remove("selected"); }

function setupDrawingCanvas() {
  const canvas=els.drawingCanvas,ctx=canvas.getContext("2d"); ctx.lineCap="round"; ctx.lineJoin="round"; ctx.lineWidth=9; resetCanvas();
  const point=event=>{ const rect=canvas.getBoundingClientRect(); return {x:(event.clientX-rect.left)*(canvas.width/rect.width),y:(event.clientY-rect.top)*(canvas.height/rect.height)}; };
  canvas.addEventListener("pointerdown",event=>{ drawing=true; canvas.setPointerCapture(event.pointerId); const p=point(event); ctx.beginPath(); ctx.moveTo(p.x,p.y); els.canvasHint.hidden=true; });
  canvas.addEventListener("pointermove",event=>{ if(!drawing)return; const p=point(event); ctx.strokeStyle=eraseMode?"#fffaf0":drawColor; ctx.lineWidth=eraseMode?30:9; ctx.lineTo(p.x,p.y); ctx.stroke(); });
  const stop=()=>{drawing=false;ctx.closePath();}; canvas.addEventListener("pointerup",stop); canvas.addEventListener("pointercancel",stop);
}
function resetCanvas(){ const ctx=els.drawingCanvas.getContext("2d"); ctx.save(); ctx.fillStyle="#fffaf0"; ctx.fillRect(0,0,els.drawingCanvas.width,els.drawingCanvas.height); ctx.restore(); els.canvasHint.hidden=false; }
function canvasBlob(){ return new Promise(resolve=>els.drawingCanvas.toBlob(resolve,"image/png",.92)); }

async function uploadResponse(blob,type){ const challenge=currentChallenge(); const form=new FormData(); form.append("file",blob,type==="drawing"?"tiny-brave.png":"tiny-brave.webm"); form.append("type",type); form.append("challengeId",String(challenge.id)); form.append("title",challenge.title); form.append("round",String(state.round)); const data=await api("/api/responses",{method:"POST",body:form}); state.responses=data.responses||state.responses; renderProgress(); }
async function saveDrawing(){ els.saveDrawingButton.disabled=true; els.saveStatus.textContent="keeping brave marks…"; try{ const blob=await canvasBlob(); await uploadResponse(blob,"drawing"); els.saveStatus.textContent="kept. opening next brave…"; showToast("drawing tucked into Track."); setTimeout(advanceNext,700); }catch(error){ els.saveStatus.textContent=error.message; }finally{ els.saveDrawingButton.disabled=false; } }

function preferredVideoType(){ const choices=["video/webm;codecs=vp9,opus","video/webm;codecs=vp8,opus","video/webm","video/mp4"]; return choices.find(type=>window.MediaRecorder?.isTypeSupported?.(type))||""; }
async function startRecording(){
  if(!navigator.mediaDevices?.getUserMedia||!window.MediaRecorder){ els.videoNote.textContent="Video recording is not supported here. Drawing still works."; return; }
  try{ mediaStream=await navigator.mediaDevices.getUserMedia({video:{facingMode:"user"},audio:true}); els.videoPreview.srcObject=mediaStream; els.videoPreview.muted=true; await els.videoPreview.play(); els.videoPlaceholder.hidden=true; videoChunks=[]; recordedBlob=null; discardRecording=false; const mimeType=preferredVideoType(); mediaRecorder=new MediaRecorder(mediaStream,mimeType?{mimeType}:undefined); mediaRecorder.addEventListener("dataavailable",event=>{if(event.data.size)videoChunks.push(event.data);}); mediaRecorder.addEventListener("stop",finishRecording); mediaRecorder.start(); secondsLeft=15; updateRecordTimer(); els.recordTimer.hidden=false; els.recordButton.textContent="stop camera"; els.recordButton.classList.add("recording"); els.saveVideoButton.hidden=true; els.retakeButton.hidden=true; recordingTimer=setInterval(()=>{secondsLeft-=1;updateRecordTimer();if(secondsLeft<=0)stopRecording();},1000);
  }catch(error){ els.videoNote.textContent=error.name==="NotAllowedError"?"Camera permission was declined. Drawing still works.":"The camera had a tiny crisis. Try again."; }
}
function updateRecordTimer(){ els.recordTimer.textContent=`0:${String(Math.max(0,secondsLeft)).padStart(2,"0")}`; }
function stopRecording(){ clearInterval(recordingTimer);recordingTimer=null;discardRecording=false;if(mediaRecorder?.state==="recording")mediaRecorder.stop(); }
function finishRecording(){ if(discardRecording){ videoChunks=[];discardRecording=false;return; } const mime=mediaRecorder?.mimeType||"video/webm"; recordedBlob=new Blob(videoChunks,{type:mime}); stopTracks(); if(recordedUrl)URL.revokeObjectURL(recordedUrl); recordedUrl=URL.createObjectURL(recordedBlob); els.videoPreview.srcObject=null;els.videoPreview.src=recordedUrl;els.videoPreview.muted=false;els.videoPreview.controls=true;els.videoPreview.play().catch(()=>{});els.recordTimer.hidden=true;els.recordButton.hidden=true;els.saveVideoButton.hidden=false;els.retakeButton.hidden=false;els.videoNote.textContent="tiny movie done. keep or do over."; }
function stopTracks(){mediaStream?.getTracks().forEach(track=>track.stop());mediaStream=null;}
function stopCamera(discard=true){clearInterval(recordingTimer);recordingTimer=null;if(mediaRecorder?.state==="recording"){discardRecording=discard;mediaRecorder.stop();}stopTracks();}
function resetVideo(){stopCamera(true);if(recordedUrl){URL.revokeObjectURL(recordedUrl);recordedUrl=null;}els.videoPreview.removeAttribute("src");els.videoPreview.srcObject=null;els.videoPreview.controls=false;els.videoPreview.muted=true;els.videoPlaceholder.hidden=false;els.recordButton.hidden=false;els.recordButton.textContent="wake camera";els.recordButton.classList.remove("recording");els.saveVideoButton.hidden=true;els.retakeButton.hidden=true;els.recordTimer.hidden=true;els.videoNote.textContent="tell story. make face. fifteen seconds plenty.";recordedBlob=null;}
async function saveVideo(){if(!recordedBlob)return;els.saveVideoButton.disabled=true;els.saveStatus.textContent="keeping tiny movie…";try{await uploadResponse(recordedBlob,"video");els.saveStatus.textContent="kept. opening next brave…";showToast("tiny movie tucked into Track.");setTimeout(advanceNext,700);}catch(error){els.saveStatus.textContent=error.message;}finally{els.saveVideoButton.disabled=false;}}

function renderProgress(){
  els.statsCompleted.textContent=state.completed.length;els.statsResponses.textContent=state.responses.length;els.statsStreak.textContent=state.streak||0;els.emptyGallery.hidden=state.responses.length>0;els.responseGallery.hidden=state.responses.length===0;
  els.responseGallery.innerHTML=state.responses.map(item=>{const media=item.type==="video"?`<video src="/api/media/${encodeURIComponent(item.id)}" preload="metadata" controls playsinline></video><span class="video-badge">VIDEO</span>`:`<img src="/api/media/${encodeURIComponent(item.id)}" alt="Saved drawing response" loading="lazy" />`;return `<article class="response-tile">${media}<span class="tile-label">R${item.round||1} · #${item.challengeId} · ${escapeHtml(item.title)}</span></article>`;}).join("");
  const done=roundPool().filter(item=>state.completed.includes(item.id));els.completedList.innerHTML=done.length?done.map(item=>`<span class="completed-chip">✓ ${escapeHtml(item.title)}</span>`).join(""):`<span class="completed-chip">your first brave is waiting.</span>`;
}
async function openProgress(){renderProgress();els.progressDialog.showModal();await syncFromServer();}

function seenPingIds(){try{return new Set(JSON.parse(localStorage.getItem(seenPingKey)||"[]"));}catch(_){return new Set();}}
function checkCirclePings(circle){const seen=seenPingIds();const fresh=(circle?.pings||[]).filter(ping=>!seen.has(ping.id));(circle?.pings||[]).forEach(ping=>seen.add(ping.id));localStorage.setItem(seenPingKey,JSON.stringify([...seen].slice(-80)));if(fresh[0])showFriendPing(fresh[0]);}
function showFriendPing(ping){clearTimeout(pingTimer);els.friendPingName.textContent=`${ping.name} did a tiny brave.`;els.friendPingMessage.textContent=ping.message;els.friendPing.hidden=false;requestAnimationFrame(()=>els.friendPing.classList.add("show"));pingTimer=setTimeout(()=>{els.friendPing.classList.remove("show");setTimeout(()=>{els.friendPing.hidden=true;},450);},4300);}

function renderCircleBits(){
  const circle=state.circle;els.circleChip.hidden=!circle;if(circle)els.circleChipText.textContent=`${circle.members.length} in circle`;els.circleSetup.hidden=!!circle;els.circleHome.hidden=!circle;if(!circle)return;els.circleCode.textContent=circle.code;
  const colors=["var(--blue)","var(--pink)","var(--green)","var(--lavender)"];els.memberList.innerHTML=circle.members.map((member,index)=>{const initials=member.name.split(/\s+/).map(part=>part[0]).join("").slice(0,2).toUpperCase();return `<div class="member-row"><span class="member-avatar" style="background:${colors[index%colors.length]}">${escapeHtml(initials)}</span><span class="member-copy"><strong>${escapeHtml(member.name)}</strong><small>${member.count?"balloon in motion":"warming up"}</small></span><span class="member-count">${member.count}/30<small>${member.streak||0} day streak</small></span></div>`;}).join("");
  els.pingFeed.innerHTML=(circle.pings||[]).length?(circle.pings||[]).slice(0,6).map(ping=>`<div class="ping-item"><i></i><span><strong>${escapeHtml(ping.name)}</strong> ${escapeHtml(ping.message)}</span></div>`).join(""):`<div class="ping-item"><i></i><span>quiet for now. the balloons are listening.</span></div>`;checkCirclePings(circle);
}
async function refreshCircle(){if(!state.circle)return;try{const data=await api("/api/circle");state.circle=data.circle||null;renderCircleBits();}catch(_) {}}
async function openCircle(){els.circleDialog.showModal();els.circleStatus.textContent="";try{const data=await api("/api/circle");state.circle=data.circle||null;renderCircleBits();}catch(error){els.circleStatus.textContent=error.message;}}
async function createCircle(){els.createCircleButton.disabled=true;els.circleStatus.textContent="inflating a new circle…";try{const data=await api("/api/circle/create",{method:"POST"});state.circle=data.circle;renderCircleBits();els.circleStatus.textContent="circle made. invite someone brave-ish.";}catch(error){els.circleStatus.textContent=error.message;}finally{els.createCircleButton.disabled=false;}}
async function joinCircle(event){event.preventDefault();const code=els.circleCodeInput.value.trim().toUpperCase();if(code.length!==6){els.circleStatus.textContent="that code needs six letters.";return;}els.circleStatus.textContent="looking for that circle…";try{const data=await api("/api/circle/join",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({code})});state.circle=data.circle;renderCircleBits();els.circleStatus.textContent="you’re in. media stays yours alone.";}catch(error){els.circleStatus.textContent=error.message;}}
async function inviteCircle(){const text=`Join my Tiny Brave circle. Code: ${state.circle.code}. Open ${location.origin} — the prototype owner may need to add you as a private viewer first.`;try{if(navigator.share)await navigator.share({title:"Tiny Brave Circle",text,url:location.origin});else{await navigator.clipboard.writeText(text);showToast("invite copied.");}}catch(error){if(error.name!=="AbortError")showToast(`circle code: ${state.circle.code}`);}}

function startReel(){
  const current=state.responses.filter(item=>(item.round||1)===state.round).slice().reverse();reelItems=current.length?current:state.responses.slice().reverse();reelIndex=0;els.progressDialog.close();if(els.finaleDialog.open)els.finaleDialog.close();if(!els.reelDialog.open)els.reelDialog.showModal();playReelItem();
}
function playReelItem(){
  clearTimeout(reelTimer);els.reelDialog.classList.remove("finished");els.reelProgress.parentElement.classList.remove("running");void els.reelProgress.parentElement.offsetWidth;
  if(!reelItems.length){els.reelCount.textContent="30 / 30";els.reelMedia.innerHTML=`<p class="reel-empty">no receipts. still brave.</p>`;els.reelCaption.textContent="the archive is empty, but the balloon remembers.";els.reelDialog.classList.add("finished");return;}
  if(reelIndex>=reelItems.length){els.reelDialog.classList.add("finished");els.reelCaption.textContent="end. courage was here.";return;}
  const item=reelItems[reelIndex];els.reelCount.textContent=`${reelIndex+1} / ${reelItems.length}`;els.reelCaption.textContent=item.title;els.reelMedia.innerHTML=item.type==="video"?`<video src="/api/media/${encodeURIComponent(item.id)}" autoplay muted playsinline></video>`:`<img src="/api/media/${encodeURIComponent(item.id)}" alt="Tiny Brave drawing" />`;els.reelProgress.parentElement.classList.add("running");reelTimer=setTimeout(()=>{reelIndex+=1;playReelItem();},2500);
}
function stopReel(){clearTimeout(reelTimer);els.reelMedia.querySelector("video")?.pause();els.reelDialog.close();}

function resetAll(){cancelFinale();state.completed=[];state.current=roundPool()[0].id;state.showingReward=false;prepareCapture();syncProgress();els.resetDialog.close();render();showToast("fresh balloon. archive stayed put.");}
function openRoundDialog(){const next=state.round+1;if(next===2){els.roundDialogTitle.textContent="thirty brand-new braves?";els.roundDialogCopy.textContent="Round 2 has 30 entirely new challenges. Your archive stays exactly where it is.";els.continueRoundButton.textContent="open round 2";}else{els.roundDialogTitle.textContent=`round ${next}?` ;els.roundDialogCopy.textContent=`Round ${next} revisits a 30-challenge set in a fresh surprise order. Your archive stays put.`;els.continueRoundButton.textContent=`open round ${next}`;}if(!els.roundDialog.open)els.roundDialog.showModal();}
function startNewRound(){cancelFinale();state.round+=1;state.completed=[];const pool=roundPool();state.current=pool[Math.floor(Math.random()*pool.length)].id;state.showingReward=false;prepareCapture();syncProgress();els.roundDialog.close();render();window.scrollTo({top:0,behavior:"smooth"});showToast(state.round===2?"30 new braves unlocked.":`round ${state.round} begins.`);}
function escapeHtml(value){return String(value||"").replace(/[&<>"']/g,char=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#039;"}[char]));}

els.openAppButton.addEventListener("click",()=>{els.doorScreen.classList.add("opened");setTimeout(()=>{els.doorScreen.hidden=true;if(state.completed.length>=ROUND_SIZE){finalePending=true;render();scheduleFinale(4200);}else els.completeButton.focus();},720);});
els.completeButton.addEventListener("click",completeCurrent);els.swapButton.addEventListener("click",pickRandom);els.nextButton.addEventListener("click",advanceNext);
els.drawTab.addEventListener("click",()=>switchStudio("draw"));els.videoTab.addEventListener("click",()=>{resetVideo();switchStudio("video");});els.saveDrawingButton.addEventListener("click",saveDrawing);els.clearCanvasButton.addEventListener("click",resetCanvas);els.eraserButton.addEventListener("click",()=>{eraseMode=!eraseMode;els.eraserButton.classList.toggle("selected",eraseMode);});
document.querySelectorAll(".color-swatch").forEach(button=>button.addEventListener("click",()=>{drawColor=button.dataset.color;eraseMode=false;els.eraserButton.classList.remove("selected");document.querySelectorAll(".color-swatch").forEach(swatch=>swatch.classList.toggle("selected",swatch===button));}));
els.recordButton.addEventListener("click",()=>mediaRecorder?.state==="recording"?stopRecording():startRecording());els.saveVideoButton.addEventListener("click",saveVideo);els.retakeButton.addEventListener("click",resetVideo);
els.trackButton.addEventListener("click",openProgress);els.progressLink.addEventListener("click",openProgress);els.closeProgressButton.addEventListener("click",()=>els.progressDialog.close());els.playReelButton.addEventListener("click",startReel);
els.circleButton.addEventListener("click",openCircle);els.circleChip.addEventListener("click",openCircle);els.closeCircleButton.addEventListener("click",()=>els.circleDialog.close());els.createCircleButton.addEventListener("click",createCircle);els.joinCircleForm.addEventListener("submit",joinCircle);els.inviteCircleButton.addEventListener("click",inviteCircle);
els.closeReelButton.addEventListener("click",stopReel);els.replayReelButton.addEventListener("click",()=>{reelIndex=0;playReelItem();});
els.finaleReelButton.addEventListener("click",startReel);els.finaleArchiveButton.addEventListener("click",()=>{els.finaleDialog.close();openProgress();});els.finaleRoundButton.addEventListener("click",()=>{els.finaleDialog.close();openRoundDialog();});els.closeFinaleButton.addEventListener("click",()=>els.finaleDialog.close());
els.resetButton.addEventListener("click",()=>els.resetDialog.showModal());els.confirmResetButton.addEventListener("click",resetAll);els.cancelResetButton.addEventListener("click",()=>els.resetDialog.close());els.newRoundButton.addEventListener("click",openRoundDialog);els.continueRoundButton.addEventListener("click",startNewRound);els.cancelRoundButton.addEventListener("click",()=>els.roundDialog.close());
[els.progressDialog,els.circleDialog,els.resetDialog,els.roundDialog,els.finaleDialog].forEach(dialog=>dialog.addEventListener("click",event=>{if(event.target===dialog)dialog.close();}));els.reelDialog.addEventListener("click",event=>{if(event.target===els.reelDialog)stopReel();});

for(let i=0;i<ROUND_SIZE;i+=1)els.puffMarks.appendChild(document.createElement("i"));
setupDrawingCanvas();render();syncFromServer();setInterval(refreshCircle,25000);
