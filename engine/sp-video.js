/* sp-video.js — the Ship Proven demo-video engine.
 *
 * A page provides TWO things and calls SPVideo.mount():
 *   1) panels with data-k="…" on anything you want to spotlight/pin/zoom
 *   2) a BEATS array (the timeline) + optional per-beat fx
 *
 * The engine owns everything else: spotlight, in-panel highlight, cross-screen
 * pins, zoom, caption word-reveal, scrubber, voiceover (recorded mp3 →
 * audio/beatNN.mp3, falling back to the browser speech API), reveal/dismiss of
 * panels, and ?autoplay=1. This is the fixed implementation of FEATURES.md — a
 * new video should NOT re-create it; it should link to it and describe beats.
 *
 * Beat shape (all fields optional except d, pane, step, txt):
 *   { d:6, pane:'gh', set:['term','gh'], keys:['g1'], zoom:'g3',
 *     pin:{target:'t4',side:'left',html:'…'}, fx:'type'|'out'|'swap',
 *     step:'2 · title', txt:'HTML shown', say:'plain spoken' }
 */
(function (global) {
  function mount(opts) {
    const movie = document.getElementById(opts.movie || 'movie');
    const stage = movie.querySelector('.stage');
    const cap = document.getElementById('caption');
    const capStep = document.getElementById('cap-step');
    const capTxt = document.getElementById('cap-txt');
    const fill = document.getElementById('fill');
    const timeEl = document.getElementById('time');
    const playBtn = document.getElementById('play');
    const pinlayer = document.getElementById('pinlayer');
    const BEATS = opts.beats;
    const AUDIO_DUR = opts.audioDur || BEATS.map(() => 0);
    const audioSlug = opts.audioSlug || 'beat';     // audio/<slug>NN.mp3
    const nextVideo = opts.nextVideo || null;

    // panels: every .pane with an id pane-X → key X
    const panes = {};
    movie.querySelectorAll('.pane').forEach(p => {
      const k = (p.id || '').replace(/^pane-/, '');
      if (k) panes[k] = p;
    });

    let t = 0, playing = false, raf = null, last = null;
    let voiceOn = false, spokenBeat = -1, capBeat = -1, lastBeat = -1;
    const present = {};
    Object.keys(panes).forEach(k => (present[k] = true));

    const audioEl = new Audio();
    const stopAudio = () => {
      try { audioEl.pause(); audioEl.currentTime = 0; } catch (e) {}
      if ('speechSynthesis' in window) window.speechSynthesis.cancel();
    };
    const fmt = s => `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, '0')}`;
    const beatDur = i => (voiceOn ? Math.max(BEATS[i].d, (AUDIO_DUR[i] || 0) + 0.6) : BEATS[i].d);
    const T = () => BEATS.reduce((s, _, i) => s + beatDur(i), 0);
    const beatIdx = x => { let a = 0; for (let i = 0; i < BEATS.length; i++) { if (x < a + beatDur(i)) return i; a += beatDur(i); } return BEATS.length - 1; };
    const beatInto = x => { let a = 0; for (let i = 0; i < BEATS.length; i++) { if (x < a + beatDur(i)) return x - a; a += beatDur(i); } return 0; };

    function speak(i) {
      if (!voiceOn || i === spokenBeat) return;
      spokenBeat = i; stopAudio();
      const src = `audio/${audioSlug}${String(i + 1).padStart(2, '0')}.mp3`;
      const fb = () => { if ('speechSynthesis' in window) {
        const u = new SpeechSynthesisUtterance(BEATS[i].say || BEATS[i].txt.replace(/<[^>]+>/g, ''));
        u.rate = 1; window.speechSynthesis.speak(u);
      } };
      audioEl.onerror = fb; audioEl.src = src; audioEl.play().catch(fb);
    }

    // panel reveal/dismiss from beat.set (optional)
    function syncPanels(b, hard) {
      if (!b.set) return;
      const want = {}; Object.keys(panes).forEach(k => (want[k] = false));
      b.set.forEach(k => (want[k] = true));
      // the first pane in the page is always present unless set says otherwise
      for (const k of Object.keys(panes)) {
        if (want[k] && !present[k]) {
          present[k] = true; panes[k].classList.remove('leaving', 'hidden');
          if (!hard) { panes[k].classList.add('reveal'); setTimeout(() => panes[k].classList.remove('reveal'), 640); }
        } else if (!want[k] && present[k]) {
          present[k] = false;
          if (hard) { panes[k].classList.add('hidden'); }
          else { panes[k].classList.add('leaving'); setTimeout(() => { panes[k].classList.add('hidden'); panes[k].classList.remove('leaving'); }, 540); }
        }
      }
      const n = b.set.length;
      stage.classList.toggle('two', n === 2);
      stage.classList.toggle('three', n >= 3);
    }

    function placePin(spec) {
      pinlayer.innerHTML = '';
      document.querySelectorAll('.ring').forEach(e => e.classList.remove('ring'));
      if (!spec) return;
      const tgt = document.querySelector(`[data-k="${spec.target}"]`);
      if (!tgt) return;
      const box = tgt.getBoundingClientRect(); if (box.width === 0) return;
      tgt.classList.add('ring');
      const m = movie.getBoundingClientRect();
      const pin = document.createElement('div'); pin.className = 'pin ' + (spec.side || 'left');
      pin.innerHTML = `<div class="bubble">${spec.html}</div><div class="arrow"></div>`;
      pinlayer.appendChild(pin);
      const pr = pin.getBoundingClientRect();
      let x, y = box.top - m.top + box.height / 2 - 16;
      if (spec.side === 'right') x = box.right - m.left + 14; else x = box.left - m.left - pr.width - 14;
      x = Math.max(8, Math.min(x, m.width - pr.width - 8));
      y = Math.max(8, Math.min(y, m.height - pr.height - 8));
      pin.style.left = x + 'px'; pin.style.top = y + 'px';
      requestAnimationFrame(() => pin.classList.add('show'));
    }

    function revealCaption(el, html) {
      const tmp = document.createElement('div'); tmp.innerHTML = html;
      const walk = node => {
        const out = document.createDocumentFragment();
        node.childNodes.forEach(ch => {
          if (ch.nodeType === 3) {
            ch.textContent.split(/(\s+)/).forEach(tok => {
              if (tok.trim() === '') out.appendChild(document.createTextNode(tok));
              else { const w = document.createElement('span'); w.className = 'w'; w.textContent = tok; out.appendChild(w); }
            });
          } else { const c = ch.cloneNode(false); c.appendChild(walk(ch)); out.appendChild(c); }
        });
        return out;
      };
      el.innerHTML = ''; el.appendChild(walk(tmp));
      el.querySelectorAll('.w').forEach((w, k) => (w.style.animationDelay = 0.04 * k + 's'));
    }

    // optional fx hook the page supplies for typewriter / live->after etc.
    const applyFx = opts.applyFx || function () {};

    function render(hard) {
      const i = beatIdx(t), b = BEATS[i], into = beatInto(t);
      if (hard || i !== lastBeat) { syncPanels(b, hard); lastBeat = i; }
      movie.classList.toggle('playing', playing || t > 0);
      movie.classList.toggle('multi', !b.set || b.set.length > 1);
      for (const k in panes) panes[k].classList.toggle('active', panes[k] === panes[b.pane]);
      document.querySelectorAll('.spot').forEach(e => e.classList.remove('spot'));
      if (b.keys) b.keys.forEach(k => document.querySelectorAll(`[data-k="${k}"]`).forEach(e => e.classList.add('spot')));
      movie.classList.toggle('zoom', !!b.zoom);
      document.querySelectorAll('.zoomed').forEach(e => e.classList.remove('zoomed'));
      if (b.zoom) { const z = document.querySelector(`[data-k="${b.zoom}"]`); if (z) z.classList.add('zoomed'); }
      placePin(b.pin);
      applyFx(b, into, { movie, panes });
      if (playing) speak(i);
      if (i !== capBeat) {
        capBeat = i; capStep.innerHTML = b.step; revealCaption(capTxt, b.txt);
        cap.classList.remove('pop'); void cap.offsetWidth; cap.classList.add('pop', 'show');
      }
      fill.style.width = 100 * t / T() + '%';
      timeEl.textContent = `${fmt(t)} / ${fmt(T())}`;
    }

    function upNext() {
      if (!nextVideo) return;
      let n = 5;
      const ov = document.createElement('div');
      ov.style.cssText = 'position:absolute;inset:0;display:grid;place-items:center;background:rgba(9,12,16,.86);backdrop-filter:blur(4px);z-index:7;text-align:center';
      ov.innerHTML = `<div><div style="color:#bc8cff;font-size:12px;font-weight:700;text-transform:uppercase;letter-spacing:.06em">Up next</div><div style="font-size:22px;font-weight:600;margin:6px 0 2px">${nextVideo.title}</div><div id="cd" style="color:#8b949e;margin-top:10px">starting in ${n}s…</div></div>`;
      movie.appendChild(ov);
      const go = () => { clearInterval(iv); location.href = nextVideo.href; };
      const iv = setInterval(() => { n--; const cd = document.getElementById('cd'); if (cd) cd.textContent = `starting in ${n}s…`; if (n <= 0) go(); }, 1000);
    }

    function tick(ts) {
      if (!playing) return; if (last == null) last = ts;
      t += (ts - last) / 1000; last = ts;
      if (t >= T()) { t = T(); render(); pause(); upNext(); return; }
      render(); raf = requestAnimationFrame(tick);
    }
    function play() { if (t >= T()) { t = 0; spokenBeat = -1; capBeat = -1; lastBeat = -1; } playing = true; last = null; playBtn.textContent = '⏸'; raf = requestAnimationFrame(tick); render(); }
    function pause() { playing = false; playBtn.textContent = '▶'; cancelAnimationFrame(raf); stopAudio(); }

    playBtn.onclick = () => (playing ? pause() : play());
    const voiceBtn = document.getElementById('voice');
    if (voiceBtn) voiceBtn.onclick = () => {
      voiceOn = !voiceOn; voiceBtn.classList.toggle('on', voiceOn);
      if (!voiceOn) stopAudio(); else { spokenBeat = -1; if (playing) speak(beatIdx(t)); }
    };
    document.getElementById('track').onclick = e => {
      const r = e.currentTarget.getBoundingClientRect();
      t = Math.max(0, Math.min(T(), (e.clientX - r.left) / r.width * T()));
      render(true);
    };

    render(true);
    if (new URLSearchParams(location.search).get('autoplay') === '1') play();
  }

  global.SPVideo = { mount };
})(window);
