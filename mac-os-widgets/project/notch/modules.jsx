(() => {
const { useState, useRef, useEffect } = React;

/* ── Parsing + formatting ── */
function parseReminder(input, now = new Date()) {
  let s = ' ' + input + ' ';
  const take = re => { const m = s.match(re); if (m) s = s.slice(0, m.index) + ' ' + s.slice(m.index + m[0].length); return m; };
  let due = null, dayOffset = null, weekday = null, hh = null, mm = 0, m;
  if ((m = take(/\s+in\s+(\d+)\s*(minutes?|mins?|m|hours?|hrs?|hr|h)(?=\s)/i))) {
    const n = +m[1]; due = new Date(now.getTime() + (/^h/i.test(m[2]) ? n * 3600e3 : n * 60e3));
  } else {
    if (take(/\s+today(?=\s)/i)) dayOffset = 0;
    else if (take(/\s+(tomorrow|tmrw|tmr)(?=\s)/i)) dayOffset = 1;
    else if (take(/\s+tonight(?=\s)/i)) { dayOffset = 0; hh = 20; }
    else if ((m = take(/\s+(?:on\s+|next\s+)?(sunday|monday|tuesday|wednesday|thursday|friday|saturday|sun|mon|tue|wed|thu|fri|sat)(?=\s)/i)))
      weekday = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'].indexOf(m[1].slice(0, 3).toLowerCase());
    if ((m = take(/\s+(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)(?=\s)/i))) { hh = (+m[1] % 12) + (/pm/i.test(m[3]) ? 12 : 0); mm = +(m[2] || 0); }
    else if ((m = take(/\s+at\s+(\d{1,2})(?::(\d{2}))?(?=\s)/i))) { hh = +m[1]; if (hh < 8) hh += 12; mm = +(m[2] || 0); }
    else if ((m = take(/\s+(\d{1,2}):(\d{2})(?=\s)/))) { hh = +m[1]; mm = +m[2]; }
    else if ((m = take(/\s+(?:at\s+|in the\s+|this\s+)?(noon|morning|afternoon|evening)(?=\s)/i))) hh = { noon: 12, morning: 9, afternoon: 15, evening: 18 }[m[1].toLowerCase()];
    if (dayOffset !== null || weekday !== null || hh !== null) {
      const d = new Date(now); d.setSeconds(0, 0);
      if (weekday !== null) { let diff = (weekday - now.getDay() + 7) % 7; if (!diff) diff = 7; d.setDate(d.getDate() + diff); }
      else if (dayOffset) d.setDate(d.getDate() + dayOffset);
      d.setHours(hh !== null ? hh : 9, hh !== null ? mm : 0);
      if (dayOffset === null && weekday === null && d <= now) d.setDate(d.getDate() + 1);
      due = d;
    }
  }
  let title = s.replace(/\s+/g, ' ').trim().replace(/\s+(at|on|by)$/i, '').trim();
  title = title.charAt(0).toUpperCase() + title.slice(1);
  return { title, due };
}

const fmtTime = d => d.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
const dayDiff = (d, now) => Math.round((new Date(d).setHours(0, 0, 0, 0) - new Date(now).setHours(0, 0, 0, 0)) / 864e5);
const fmtDue = (d, now) => {
  const k = dayDiff(d, now);
  const day = k === 0 ? 'Today' : k === 1 ? 'Tomorrow' : k < 7 ? d.toLocaleDateString('en-US', { weekday: 'long' }) : d.toLocaleDateString('en-US', { day: 'numeric', month: 'short' });
  return `${day}, ${fmtTime(d)}`;
};
const fmtCountdown = (d, now) => {
  const min = Math.ceil((d - now) / 60e3);
  if (min <= 0) return 'now';
  if (min < 60) return `in ${min} min`;
  const h = Math.floor(min / 60), r = min % 60;
  if (h < 24 && dayDiff(d, now) === 0) return r ? `in ${h} hr ${r} min` : `in ${h} hr`;
  return dayDiff(d, now) === 1 ? `tomorrow, ${fmtTime(d)}` : fmtDue(d, now);
};
const fmtMMSS = s => `${String(Math.floor(s / 60)).padStart(2, '0')}:${String(Math.floor(s % 60)).padStart(2, '0')}`;
const fmtAgo = (t, now) => { const m = Math.floor((now - t) / 60e3); return m < 1 ? 'Now' : m < 60 ? `${m}m` : m < 1440 ? `${Math.floor(m / 60)}h` : `${Math.floor(m / 1440)}d`; };

/* ── Day strip ── */
const DAY_BLOCKS = [
  { s: 9, e: 10.5, t: 'Deep work', c: NT.indigo },
  { s: 11, e: 11.5, t: 'Standup', c: NT.teal },
  { s: 12.5, e: 13.5, t: 'Lunch', c: NT.green },
  { s: 14, e: 15.5, t: 'Design review', c: NT.pink },
  { s: 16, e: 17.5, t: 'Focus block', c: NT.orange },
  { s: 19, e: 20, t: 'Gym', c: NT.purple },
];
const D0 = 7, D1 = 23;
const hToDate = h => { const d = new Date(); d.setHours(Math.floor(h), Math.round((h % 1) * 60), 0, 0); return d; };
const pct = h => `${((Math.max(D0, Math.min(D1, h)) - D0) / (D1 - D0)) * 100}%`;

const DayStrip = ({ now, reminders }) => {
  const nh = now.getHours() + now.getMinutes() / 60;
  const cur = DAY_BLOCKS.find(b => nh >= b.s && nh < b.e);
  const next = DAY_BLOCKS.find(b => b.s > nh);
  const status = cur ? `${cur.t} · until ${fmtTime(hToDate(cur.e))}` : next ? `Free until ${fmtTime(hToDate(next.s))} · ${next.t}` : 'Nothing else scheduled';
  const todays = reminders.filter(r => r.due && dayDiff(r.due, now) === 0);
  return (
    <div className="ncard" style={{ gridColumn: '1 / -1', gap: 8 }}>
      <CardTitle icon="calendar" color={NT.red} right={<span style={{ fontWeight: 400, color: NT.secondary }}>{status}</span>}>
        Today<span style={{ fontWeight: 400, color: NT.tertiary, marginLeft: 6 }}>{now.toLocaleDateString('en-US', { weekday: 'long', day: 'numeric', month: 'long' })}</span>
      </CardTitle>
      <div style={{ position: 'relative', height: 26, borderRadius: 8, background: NT.fill }}>
        {DAY_BLOCKS.map(b => (
          <div key={b.t} title={`${b.t} · ${fmtTime(hToDate(b.s))}–${fmtTime(hToDate(b.e))}`} style={{ position: 'absolute', top: 3, bottom: 3, left: pct(b.s), width: `calc(${pct(b.e)} - ${pct(b.s)} - 2px)`, borderRadius: 5, background: `color-mix(in srgb, ${b.c} ${b === cur ? 62 : 38}%, transparent)`, opacity: b.e <= nh ? 0.4 : 1, padding: '0 6px', display: 'flex', alignItems: 'center', font: `500 11px ${NT.font}`, color: '#fff', overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis' }}>{b.t}</div>
        ))}
        {todays.map(r => (
          <div key={r.id} title={`${r.title} · ${fmtTime(r.due)}`} style={{ position: 'absolute', bottom: -5, left: pct(r.due.getHours() + r.due.getMinutes() / 60), width: 5, height: 5, marginLeft: -2.5, borderRadius: 3, background: NT.label }}></div>
        ))}
        <div style={{ position: 'absolute', top: -4, bottom: -4, left: pct(nh), width: 2, marginLeft: -1, borderRadius: 1, background: NT.red, boxShadow: '0 0 0 1px rgba(0,0,0,0.25)', transition: 'left 1s linear' }}>
          <div style={{ position: 'absolute', top: -3, left: -3, width: 8, height: 8, borderRadius: 4, background: NT.red }}></div>
        </div>
      </div>
      <div style={{ position: 'relative', height: 12 }}>
        {[8, 10, 12, 14, 16, 18, 20, 22].map(h => (
          <span key={h} style={{ position: 'absolute', left: pct(h), transform: 'translateX(-50%)', font: `400 10px ${NT.font}`, color: NT.tertiary, whiteSpace: 'nowrap' }}>{h % 12 || 12} {h < 12 ? 'AM' : 'PM'}</span>
        ))}
      </div>
    </div>
  );
};

/* ── Focus (Pomodoro) ── */
const FocusCard = ({ pomo, onStart, onPause, onReset, alertType, setAlertType }) => {
  const isFocus = pomo.phase === 'focus';
  const color = isFocus ? NT.orange : NT.green;
  const idle = !pomo.running && pomo.remaining === pomo.total;
  return (
    <div className="ncard">
      <CardTitle icon="timer" color={NT.orange}>Focus</CardTitle>
      <div style={{ display: 'flex', alignItems: 'center', gap: 14, flex: 1, minHeight: 0 }}>
        <Ring size={112} stroke={7} progress={1 - pomo.remaining / pomo.total} color={color}>
          <div style={{ font: `600 25px ${NT.rounded}`, fontVariantNumeric: 'tabular-nums', color: NT.label, letterSpacing: '-0.02em' }}>{fmtMMSS(pomo.remaining)}</div>
          <div style={{ font: `500 11px ${NT.font}`, color: isFocus ? NT.secondary : NT.green, marginTop: 1 }}>{isFocus ? 'Focus' : pomo.phase === 'long' ? 'Long Break' : 'Break'}</div>
        </Ring>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10, flex: 1, minWidth: 0 }}>
          <div>
            <div style={{ display: 'flex', gap: 5, marginBottom: 5 }}>
              {[0, 1, 2, 3].map(i => {
                const done = i < pomo.done, current = i === pomo.cycle - 1 && !done;
                return <div key={i} style={{ width: 9, height: 9, borderRadius: 5, background: done ? NT.orange : 'transparent', boxShadow: `inset 0 0 0 1.5px ${done || current ? NT.orange : NT.track}` }}></div>;
              })}
            </div>
            <div style={{ font: `400 11px ${NT.font}`, color: NT.secondary }}>Cycle {pomo.cycle} of 4 · 25 min</div>
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            {pomo.running
              ? <Btn variant="glass" icon="pause" onClick={onPause} style={{ flex: 1 }}>Pause</Btn>
              : <Btn variant="prom" icon="play" onClick={onStart} style={{ flex: 1 }}>{idle ? 'Start' : 'Resume'}</Btn>}
            <Btn variant="glass" icon="reset" onClick={onReset} title="Reset" disabled={idle}></Btn>
          </div>
          <div>
            <div style={{ font: `400 10.5px ${NT.font}`, color: NT.tertiary, marginBottom: 4 }}>Break alert</div>
            <Segmented value={alertType} onChange={setAlertType} options={[{ value: 'sound', label: 'Sound', icon: 'speaker' }, { value: 'haptic', label: 'Watch', icon: 'watch', title: 'Haptic on Apple Watch' }]} />
          </div>
        </div>
      </div>
    </div>
  );
};

/* ── Reminders ── */
const RemindersCard = ({ reminders, now, onAdd }) => {
  const [text, setText] = useState('');
  const [saved, setSaved] = useState(false);
  const upcoming = reminders.filter(r => r.due && r.due > now).sort((a, b) => a.due - b.due);
  const [next, ...later] = upcoming;
  const parsed = text.trim() ? parseReminder(text, now) : null;
  const submit = e => {
    e.preventDefault();
    if (!parsed || !parsed.title) return;
    onAdd(parsed); setText(''); setSaved(true); setTimeout(() => setSaved(false), 1600);
  };
  return (
    <div className="ncard">
      <CardTitle icon="bell" color={NT.blue} right={saved && <span style={{ color: NT.green, fontWeight: 500, display: 'flex', alignItems: 'center', gap: 3, animation: 'nwFade .2s ease' }}><Icon name="check" size={11} stroke={2.4} />Saved to Reminders</span>}>Up Next</CardTitle>
      {next ? (
        <div>
          <div style={{ font: `600 15px ${NT.font}`, color: NT.label, letterSpacing: '-0.015em', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{next.title}</div>
          <div style={{ font: `400 12px ${NT.font}`, color: NT.secondary, marginTop: 2 }}><span style={{ color: NT.orange, fontWeight: 500 }}>{fmtCountdown(next.due, now)}</span> · {fmtTime(next.due)}</div>
        </div>
      ) : <div style={{ font: `400 13px ${NT.font}`, color: NT.tertiary }}>No upcoming reminders</div>}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 5, flex: 1, minHeight: 0, overflow: 'hidden' }}>
        {later.slice(0, 2).map(r => (
          <div key={r.id} style={{ display: 'flex', gap: 8, font: `400 12px ${NT.font}` }}>
            <span style={{ color: NT.label, flex: 1, minWidth: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.title}</span>
            <span style={{ color: NT.tertiary, whiteSpace: 'nowrap' }}>{fmtDue(r.due, now)}</span>
          </div>
        ))}
      </div>
      <form onSubmit={submit} style={{ position: 'relative' }}>
        <input className="ntf" value={text} onChange={e => setText(e.target.value)} placeholder="Call Rahul tomorrow 6pm" style={{ paddingRight: parsed && parsed.due ? 132 : 10 }} />
        {parsed && parsed.due && (
          <span style={{ position: 'absolute', right: 5, top: 5, height: 20, padding: '0 7px', borderRadius: 10, background: 'rgba(10,132,255,0.22)', color: '#6CB6FF', font: `500 11px ${NT.font}`, display: 'flex', alignItems: 'center', gap: 4, whiteSpace: 'nowrap', animation: 'nwFade .15s ease' }}>
            <Icon name="calendar" size={11} stroke={2} />{fmtDue(parsed.due, now)}
          </span>
        )}
      </form>
    </div>
  );
};

/* ── Inbox ── */
const InboxCard = ({ items, now, onAdd, onDone, onRemind }) => {
  const [text, setText] = useState('');
  const submit = e => { e.preventDefault(); if (text.trim()) { onAdd(text.trim()); setText(''); } };
  return (
    <div className="ncard">
      <CardTitle icon="tray" color={NT.teal} right={items.length > 0 && <span style={{ minWidth: 18, height: 16, padding: '0 5px', borderRadius: 8, background: NT.fill, color: NT.secondary, font: `600 10.5px ${NT.font}`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{items.length}</span>}>Inbox</CardTitle>
      <form onSubmit={submit}><input className="ntf" value={text} onChange={e => setText(e.target.value)} placeholder="Capture a thought…" /></form>
      <div style={{ display: 'flex', flexDirection: 'column', flex: 1, minHeight: 0, overflow: 'hidden', margin: '0 -6px' }}>
        {items.length === 0 && <div style={{ font: `400 12px ${NT.font}`, color: NT.tertiary, padding: '4px 6px' }}>All sorted.</div>}
        {items.slice(0, 3).map(it => (
          <div key={it.id} className="nrow">
            <span style={{ flex: 1, minWidth: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', color: NT.label }}>{it.text}</span>
            <span className="nrow-time">{fmtAgo(it.t, now)}</span>
            <span className="nrow-act">
              <button className="nmini" title="Make reminder" onClick={() => onRemind(it)}><Icon name="bell" size={12} stroke={2} /></button>
              <button className="nmini" title="Done" onClick={() => onDone(it.id)}><Icon name="check" size={12} stroke={2.2} /></button>
            </span>
          </div>
        ))}
        {items.length > 3 && <div style={{ font: `400 11px ${NT.font}`, color: NT.tertiary, padding: '3px 6px' }}>{items.length - 3} more to sort</div>}
      </div>
    </div>
  );
};

/* ── Snips ── */
const TW = 78, TH = 56;
const SnipThumb = ({ s, now, copied, onCopy, onDelete }) => {
  const k = Math.min(TW / s.w, TH / s.h);
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 4, width: TW }}>
      <div className="nthumb" onClick={() => onCopy(s.id)} title={`${Math.round(s.w)} × ${Math.round(s.h)}`}>
        <div style={{ width: s.w * k, height: s.h * k, borderRadius: 4, background: window.NW_WALL, backgroundSize: `${s.vw * k}px ${s.vh * k}px`, backgroundPosition: `${-s.x * k}px ${-s.y * k}px`, boxShadow: '0 0 0 0.5px rgba(255,255,255,0.25)' }}></div>
        <button className="nmini nthumb-x" title="Delete" onClick={e => { e.stopPropagation(); onDelete(s.id); }}><Icon name="xmark" size={10} stroke={2.4} /></button>
      </div>
      <div style={{ font: `400 10.5px ${NT.font}`, color: copied ? NT.green : NT.tertiary, textAlign: 'center', whiteSpace: 'nowrap' }}>{copied ? 'Copied' : fmtAgo(s.t, now)}</div>
    </div>
  );
};

const SnipsCard = ({ snips, now, mode, setMode, onCapture, onDelete }) => {
  const [copied, setCopied] = useState(null);
  const copy = id => { setCopied(id); setTimeout(() => setCopied(c => c === id ? null : c), 1400); };
  return (
    <div className="ncard" style={{ gridColumn: 'span 2', flexDirection: 'row', gap: 14 }}>
      <div style={{ width: 150, display: 'flex', flexDirection: 'column', gap: 8, flexShrink: 0 }}>
        <CardTitle icon="viewfinder" color={NT.purple}>Screen Snip</CardTitle>
        <Segmented value={mode} onChange={setMode} options={[{ value: 'area', icon: 'area', label: '', title: 'Selected area' }, { value: 'window', icon: 'window', label: '', title: 'Window' }, { value: 'screen', icon: 'display', label: '', title: 'Entire screen' }]} />
        <Btn variant="prom" onClick={onCapture} style={{ width: '100%' }}>Capture<span style={{ opacity: 0.6, fontWeight: 400, fontSize: 11 }}>⇧⌘4</span></Btn>
      </div>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 8, minWidth: 0 }}>
        <div className="ntitle" style={{ color: NT.tertiary, fontWeight: 500 }}>Recent</div>
        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
          {[0, 1, 2, 3].map(i => snips[i]
            ? <SnipThumb key={snips[i].id} s={snips[i]} now={now} copied={copied === snips[i].id} onCopy={copy} onDelete={onDelete} />
            : <div key={'e' + i} style={{ width: TW, height: TH, borderRadius: 8, boxShadow: `inset 0 0 0 1px ${NT.fill}` }}></div>)}
        </div>
      </div>
    </div>
  );
};

/* ── Distraction nudge ── */
const normHost = s => s.trim().toLowerCase().replace(/^[a-z]+:\/\//, '').replace(/^www\./, '').split(/[\/?#\s]/)[0];
const GuardCard = ({ guard, sites, nowMs, onDismiss, onAddSite, onRemoveSite }) => {
  const [adding, setAdding] = useState(false);
  const [url, setUrl] = useState('');
  const [mins, setMins] = useState(15);
  const site = guard.site && sites.find(s => s.host === guard.site);
  const limitMin = site ? site.min : 10;
  const elapsed = guard.site ? (nowMs - guard.since) / 1000 : 0;
  const host = normHost(url);
  const valid = /^[a-z0-9-]+(\.[a-z0-9-]+)+$/.test(host);
  const submit = e => { e.preventDefault(); if (!valid) return; onAddSite({ host, min: mins }); setUrl(''); setMins(15); setAdding(false); };
  const cancel = () => { setAdding(false); setUrl(''); };

  if (adding) return (
    <form className="ncard" style={{ gap: 8 }} onSubmit={submit} onKeyDown={e => e.key === 'Escape' && cancel()}>
      <CardTitle icon="eye" color={NT.yellow} right={<button type="button" className="nlink" onClick={cancel}>Cancel</button>}>New Nudge</CardTitle>
      <input className="ntf" autoFocus value={url} onChange={e => setUrl(e.target.value)} placeholder="Website, e.g. netflix.com" />
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        <span style={{ font: `400 11px ${NT.font}`, color: NT.secondary }}>After</span>
        <div style={{ display: 'flex', alignItems: 'center', gap: 2, height: 24, padding: 2, borderRadius: 12, background: 'rgba(118,118,128,0.24)' }}>
          <button type="button" className="nmini" style={{ width: 20, height: 20, background: 'none' }} disabled={mins <= 5} onClick={() => setMins(m => Math.max(5, m - 5))}>−</button>
          <span style={{ minWidth: 42, textAlign: 'center', font: `600 12px ${NT.rounded}`, fontVariantNumeric: 'tabular-nums', color: NT.label }}>{mins} min</span>
          <button type="button" className="nmini" style={{ width: 20, height: 20, background: 'none' }} disabled={mins >= 120} onClick={() => setMins(m => Math.min(120, m + 5))}>+</button>
        </div>
        <Btn size="sm" variant="prom" type="submit" disabled={!valid} style={{ marginLeft: 'auto' }}>Add</Btn>
      </div>
    </form>
  );

  return (
    <div className="ncard" style={{ gap: 8 }}>
      <CardTitle icon="eye" color={NT.yellow} right={!guard.site && <button className="nmini" title="Add a website" onClick={() => setAdding(true)}><Icon name="plus" size={12} stroke={2.2} /></button>}>Distraction Nudge</CardTitle>
      {guard.site ? (
        <>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
            <span style={{ font: `600 13px ${NT.font}`, color: NT.label, flex: 1, minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis' }}>{guard.site}</span>
            <span style={{ font: `500 12px ${NT.rounded}`, fontVariantNumeric: 'tabular-nums', color: guard.nudging ? NT.yellow : NT.secondary }}>{fmtMMSS(elapsed)}</span>
          </div>
          <div style={{ height: 4, borderRadius: 2, background: NT.track, overflow: 'hidden' }}>
            <div style={{ height: '100%', width: `${Math.min(1, elapsed / (limitMin * 60)) * 100}%`, background: guard.nudging ? NT.yellow : NT.secondary, borderRadius: 2, transition: 'width 1s linear' }}></div>
          </div>
          {guard.nudging
            ? <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}><span style={{ font: `400 11px ${NT.font}`, color: NT.secondary, flex: 1 }}>{limitMin} minutes here.</span><Btn size="sm" variant="glass" onClick={onDismiss}>Back to work</Btn></div>
            : <div style={{ font: `400 11px ${NT.font}`, color: NT.tertiary }}>Nudge at {limitMin} min</div>}
        </>
      ) : (
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4, overflow: 'hidden', minHeight: 0 }}>
          {sites.length === 0 && <span style={{ font: `400 11px ${NT.font}`, color: NT.tertiary }}>Add a website to get nudged.</span>}
          {sites.map(s => (
            <span key={s.host} className="nchip" title={`Nudge after ${s.min} min on ${s.host}`}>
              {s.host}<span style={{ color: NT.tertiary }}>{s.min}m</span>
              <button className="nchip-x" title="Remove" onClick={() => onRemoveSite(s.host)}><Icon name="xmark" size={8} stroke={2.6} /></button>
            </span>
          ))}
        </div>
      )}
    </div>
  );
};

/* ── Break alarm ── */
const AlarmView = ({ alarm, alertType, onPrimary, onSecondary }) => {
  const focusDone = alarm.kind === 'focusDone';
  const long = focusDone && alarm.cycle === 4;
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 16, padding: '0 22px', height: '100%' }}>
      <Ring size={64} stroke={6} progress={1} color={focusDone ? NT.orange : NT.green}>
        <Icon name={focusDone ? 'check' : 'timer'} size={24} stroke={2.4} color={focusDone ? NT.orange : NT.green} />
      </Ring>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ font: `600 17px ${NT.font}`, color: NT.label, letterSpacing: '-0.02em' }}>{focusDone ? 'Focus session complete' : 'Break’s over'}</div>
        <div style={{ font: `400 13px ${NT.font}`, color: NT.secondary, marginTop: 2 }}>{focusDone ? `Cycle ${alarm.cycle} of 4 done. Take a ${long ? '15' : '5'}-minute break.` : `Ready for cycle ${alarm.nextCycle} of 4?`}</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 5, marginTop: 6, font: `500 11px ${NT.font}`, color: NT.tertiary }}>
          <span style={{ display: 'flex', animation: 'nwPulse 1.2s ease-in-out infinite' }}><Icon name={alertType === 'sound' ? 'speaker' : 'watch'} size={12} stroke={2} /></span>
          {alertType === 'sound' ? 'Playing chime' : 'Tapping your Apple Watch'}
        </div>
      </div>
      <div style={{ display: 'flex', gap: 8 }}>
        <Btn variant="glass" onClick={onSecondary}>{focusDone ? 'Skip' : 'Later'}</Btn>
        <Btn variant="prom" onClick={onPrimary}>{focusDone ? 'Start Break' : 'Start Focus'}</Btn>
      </div>
    </div>
  );
};

/* ── Area selection overlay ── */
const SnipOverlay = ({ onDone, onCancel }) => {
  const [a, setA] = useState(null), [b, setB] = useState(null);
  useEffect(() => { const k = e => e.key === 'Escape' && onCancel(); window.addEventListener('keydown', k); return () => window.removeEventListener('keydown', k); }, []);
  const r = a && b ? { x: Math.min(a.x, b.x), y: Math.min(a.y, b.y), w: Math.abs(a.x - b.x), h: Math.abs(a.y - b.y) } : null;
  return (
    <div onMouseDown={e => { setA({ x: e.clientX, y: e.clientY }); setB({ x: e.clientX, y: e.clientY }); }}
      onMouseMove={e => a && setB({ x: e.clientX, y: e.clientY })}
      onMouseUp={() => { if (r && r.w > 12 && r.h > 12) onDone(r); else { setA(null); setB(null); } }}
      style={{ position: 'fixed', inset: 0, zIndex: 2000, cursor: 'crosshair', background: r ? 'transparent' : 'rgba(0,0,0,0.22)' }}>
      {r && <div style={{ position: 'absolute', left: r.x, top: r.y, width: r.w, height: r.h, boxShadow: '0 0 0 9999px rgba(0,0,0,0.32)', outline: '1px solid rgba(255,255,255,0.85)' }}>
        <span style={{ position: 'absolute', right: 0, bottom: -22, font: `500 11px ${NT.font}`, color: '#fff', fontVariantNumeric: 'tabular-nums', textShadow: '0 1px 3px rgba(0,0,0,.6)' }}>{Math.round(r.w)} × {Math.round(r.h)}</span>
      </div>}
      {!a && <div style={{ position: 'absolute', top: 64, left: '50%', transform: 'translateX(-50%)', padding: '7px 14px', borderRadius: 16, background: 'rgba(30,30,34,0.7)', backdropFilter: 'blur(30px)', WebkitBackdropFilter: 'blur(30px)', font: `500 12px ${NT.font}`, color: NT.label, pointerEvents: 'none', boxShadow: 'inset 0 0 0 .5px rgba(255,255,255,.15)' }}>Drag to select an area · Esc to cancel</div>}
    </div>
  );
};

Object.assign(window, { parseReminder, fmtTime, fmtCountdown, fmtMMSS, DayStrip, FocusCard, RemindersCard, InboxCard, SnipsCard, GuardCard, AlarmView, SnipOverlay });
})();
