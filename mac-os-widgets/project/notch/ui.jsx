(() => {
const NT = {
  font: '-apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro", "Helvetica Neue", Helvetica, sans-serif',
  rounded: 'ui-rounded, "SF Pro Rounded", -apple-system, BlinkMacSystemFont, "Helvetica Neue", sans-serif',
  blue: '#0A84FF', orange: '#FF9F0A', green: '#30D158', red: '#FF453A', yellow: '#FFD60A', indigo: '#5E5CE6', teal: '#64D2FF', pink: '#FF375F', purple: '#BF5AF2',
  label: 'rgba(255,255,255,0.92)', secondary: 'rgba(235,235,245,0.62)', tertiary: 'rgba(235,235,245,0.38)',
  fill: 'rgba(255,255,255,0.08)', track: 'rgba(255,255,255,0.12)',
  ease: 'cubic-bezier(0.32,0.72,0,1)',
};

const P = {
  bell: <><path d="M6 16.5V11a6 6 0 0 1 12 0v5.5l1.5 1.5h-15z"/><path d="M10 20.5a2 2 0 0 0 4 0"/></>,
  play: <path d="M8 5.2v13.6a.6.6 0 0 0 .9.5l10.6-6.8a.6.6 0 0 0 0-1L8.9 4.7a.6.6 0 0 0-.9.5z" fill="currentColor" stroke="none"/>,
  pause: <><rect x="6.5" y="5" width="3.6" height="14" rx="1.2" fill="currentColor" stroke="none"/><rect x="13.9" y="5" width="3.6" height="14" rx="1.2" fill="currentColor" stroke="none"/></>,
  reset: <><path d="M4.5 12a7.5 7.5 0 1 0 2.3-5.4"/><path d="M4.5 4.5v4h4"/></>,
  plus: <path d="M12 5v14M5 12h14"/>,
  tray: <><path d="M4 13.5 6.6 6h10.8L20 13.5V19H4z"/><path d="M4 13.5h4.5l1 2h5l1-2H20"/></>,
  check: <path d="M5.5 12.5 10 17l8.5-9.5"/>,
  xmark: <path d="M7 7l10 10M17 7 7 17"/>,
  speaker: <><path d="M4 9.5h3.5L12 6v12l-4.5-3.5H4z"/><path d="M15.5 9.2a4 4 0 0 1 0 5.6M18 6.8a7.5 7.5 0 0 1 0 10.4"/></>,
  watch: <><rect x="6.5" y="6.5" width="11" height="11" rx="3.2"/><path d="M9 6.5l.6-3h4.8l.6 3M9 17.5l.6 3h4.8l.6-3"/></>,
  area: <><rect x="4" y="5" width="16" height="14" rx="2" strokeDasharray="2.6 2.4"/></>,
  window: <><rect x="3.5" y="5" width="17" height="14" rx="2.5"/><path d="M3.5 9h17"/></>,
  display: <><rect x="3" y="4.5" width="18" height="11.5" rx="2"/><path d="M9 20h6M12 16v4"/></>,
  copy: <><rect x="8.5" y="8.5" width="11" height="11" rx="2.2"/><path d="M5 15V6.2C5 5.5 5.5 5 6.2 5H15"/></>,
  calendar: <><rect x="4" y="5.5" width="16" height="14.5" rx="2.5"/><path d="M4 10h16M8.5 3.5v3.5M15.5 3.5v3.5"/></>,
  eye: <><path d="M2.5 12S6 5.8 12 5.8 21.5 12 21.5 12 18 18.2 12 18.2 2.5 12 2.5 12z"/><circle cx="12" cy="12" r="3"/></>,
  viewfinder: <><path d="M4 8.5V6a2 2 0 0 1 2-2h2.5M15.5 4H18a2 2 0 0 1 2 2v2.5M20 15.5V18a2 2 0 0 1-2 2h-2.5M8.5 20H6a2 2 0 0 1-2-2v-2.5"/><circle cx="12" cy="12" r="2.6"/></>,
  timer: <><circle cx="12" cy="13" r="7.5"/><path d="M12 13V9M10 2.8h4"/></>,
  arrowDown: <path d="M12 5v13M6.5 12.5 12 18l5.5-5.5"/>,
  chevronLeft: <path d="M14.5 5.5 8 12l6.5 6.5"/>,
  gear: <><circle cx="12" cy="12" r="3.2"/><path d="M12 3v2.6M12 18.4V21M3 12h2.6M18.4 12H21M5.6 5.6l1.9 1.9M16.5 16.5l1.9 1.9M18.4 5.6l-1.9 1.9M7.5 16.5l-1.9 1.9"/></>,
};

const Icon = ({ name, size = 14, color = 'currentColor', stroke = 1.8, style }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={stroke} strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0, display: 'block', ...style }}>{P[name]}</svg>
);

const Btn = ({ variant = 'glass', size, icon, children, className = '', ...rest }) => (
  <button className={`nb nb-${variant} ${size === 'sm' ? 'nb-sm' : ''} ${!children ? 'nb-icon' : ''} ${className}`} {...rest}>
    {icon && <Icon name={icon} size={size === 'sm' ? 12 : 13} stroke={2} />}
    {children}
  </button>
);

const Segmented = ({ options, value, onChange }) => {
  const i = Math.max(0, options.findIndex(o => o.value === value));
  const n = options.length;
  return (
    <div style={{ position: 'relative', display: 'grid', gridTemplateColumns: `repeat(${n},1fr)`, height: 24, padding: 2, borderRadius: 12, background: 'rgba(118,118,128,0.24)' }}>
      <div style={{ position: 'absolute', top: 2, bottom: 2, left: 2, width: `calc((100% - 4px) / ${n})`, transform: `translateX(${i * 100}%)`, borderRadius: 10, background: 'rgba(255,255,255,0.22)', boxShadow: '0 1px 3px rgba(0,0,0,0.25), inset 0 0.5px 0 rgba(255,255,255,0.25)', transition: `transform 0.32s ${NT.ease}` }}></div>
      {options.map(o => (
        <button key={o.value} title={o.title || o.label} onClick={() => onChange(o.value)} style={{ position: 'relative', border: 0, background: 'none', padding: '0 6px', color: o.value === value ? NT.label : NT.secondary, font: `500 11.5px ${NT.font}`, letterSpacing: '-0.01em', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 4, cursor: 'default', transition: 'color .2s', whiteSpace: 'nowrap' }}>
          {o.icon && <Icon name={o.icon} size={12} stroke={1.9} />}{o.label}
        </button>
      ))}
    </div>
  );
};

const Ring = ({ size, stroke, progress, color, children }) => {
  const r = (size - stroke) / 2, c = 2 * Math.PI * r;
  return (
    <div style={{ position: 'relative', width: size, height: size, flexShrink: 0 }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)', display: 'block' }}>
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={NT.track} strokeWidth={stroke} />
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={color} strokeWidth={stroke} strokeLinecap="round" strokeDasharray={c} strokeDashoffset={c * (1 - Math.max(0, Math.min(1, progress)))} style={{ transition: 'stroke-dashoffset .4s linear, stroke .3s' }} />
      </svg>
      {children && <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>{children}</div>}
    </div>
  );
};

const CardTitle = ({ icon, color, children, right }) => (
  <div className="ntitle">
    <Icon name={icon} size={13} color={color} stroke={2} />
    <span>{children}</span>
    {right && <span style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 6 }}>{right}</span>}
  </div>
);

Object.assign(window, { NT, Icon, Btn, Segmented, Ring, CardTitle });
})();
