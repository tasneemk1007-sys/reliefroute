const pptxgen = require('pptxgenjs');

const pptx = new pptxgen();
pptx.layout = 'LAYOUT_WIDE';
pptx.author = 'ReliefRoute student project';
pptx.subject = 'Medication ordering and delivery app';
pptx.title = 'RELIEFROUTE Project Presentation';
pptx.company = 'ReliefRoute';
pptx.lang = 'en-ZA';
pptx.theme = {
  headFontFace: 'Aptos Display', bodyFontFace: 'Aptos', lang: 'en-ZA'
};

const purple = '4C1D95';
const violet = '8B5CF6';
const pale = 'FCFAFF';
const ink = '171321';
const muted = '6B6475';

function title(slide, heading, sub = '') {
  slide.background = { color: pale };
  slide.addText(heading, { x: 0.65, y: 0.45, w: 11.8, h: 0.55, fontFace: 'Aptos Display', fontSize: 26, bold: true, color: purple, margin: 0 });
  if (sub) slide.addText(sub, { x: 0.68, y: 1.05, w: 11.4, h: 0.3, fontSize: 11, color: muted, margin: 0 });
  slide.addShape(pptx.ShapeType.line, { x: 0.68, y: 1.45, w: 11, h: 0, line: { color: 'E5E7EB', width: 1 } });
}
function bullet(slide, text, y, opts = {}) {
  slide.addText(text, { x: opts.x || 0.9, y, w: opts.w || 5.2, h: 0.35, fontSize: opts.size || 16, color: ink, bullet: { indent: 14 }, breakLine: false, margin: 0 });
}
function footer(slide, n) {
  slide.addText(`RELIEFROUTE  •  ${n}`, { x: 10.5, y: 7.05, w: 2, h: 0.2, fontSize: 8, color: muted, align: 'right', margin: 0 });
}

let s = pptx.addSlide();
s.background = { color: purple };
s.addShape(pptx.ShapeType.arc, { x: 8.2, y: -0.8, w: 5.5, h: 5.5, line: { color: violet, transparency: 35, width: 4 } });
s.addText('RELIEFROUTE', { x: 0.8, y: 1.55, w: 8, h: 0.7, fontSize: 38, bold: true, color: 'FFFFFF', margin: 0 });
s.addText('A simple healthcare ordering and delivery app', { x: 0.85, y: 2.45, w: 7, h: 0.45, fontSize: 20, color: 'EDE9FE', margin: 0 });
s.addText('Project presentation', { x: 0.85, y: 5.8, w: 4, h: 0.3, fontSize: 14, color: 'DDD6FE', margin: 0 });
footer(s, 1);

s = pptx.addSlide(); title(s, 'The problem', 'Why this project is needed');
bullet(s, 'Medicine ordering can feel confusing and fragmented.', 1.9);
bullet(s, 'People need a clear view of prescriptions, reminders, and delivery status.', 2.55);
bullet(s, 'A mobile-first service can make routine healthcare tasks easier to follow.', 3.2);
s.addShape(pptx.ShapeType.roundRect, { x: 7.2, y: 1.9, w: 4.7, h: 2.6, rectRadius: 0.1, fill: { color: 'EDE9FE' }, line: { color: 'DDD6FE' } });
s.addText('Goal', { x: 7.6, y: 2.25, w: 1.5, h: 0.3, fontSize: 17, bold: true, color: purple, margin: 0 });
s.addText('Make the next healthcare action obvious.', { x: 7.6, y: 2.85, w: 3.8, h: 0.8, fontSize: 24, bold: true, color: ink, margin: 0, fit: 'shrink' });
footer(s, 2);

s = pptx.addSlide(); title(s, 'Proposed experience', 'A focused flow from sign-in to delivery');
const steps = [['01', 'Sign in', 'Simple account access'], ['02', 'Find', 'Search the medicine catalogue'], ['03', 'Order', 'Review items and address'], ['04', 'Track', 'Follow delivery progress']];
steps.forEach((item, i) => { const x = 0.8 + i * 3.05; s.addShape(pptx.ShapeType.roundRect, { x, y: 2.15, w: 2.35, h: 2.35, rectRadius: 0.08, fill: { color: i === 0 ? purple : 'FFFFFF' }, line: { color: i === 0 ? purple : 'E5E7EB' } }); s.addText(item[0], { x: x + 0.22, y: 2.4, w: 0.55, h: 0.3, fontSize: 12, bold: true, color: i === 0 ? 'DDD6FE' : violet, margin: 0 }); s.addText(item[1], { x: x + 0.22, y: 3.05, w: 1.9, h: 0.4, fontSize: 21, bold: true, color: i === 0 ? 'FFFFFF' : purple, margin: 0 }); s.addText(item[2], { x: x + 0.22, y: 3.7, w: 1.9, h: 0.5, fontSize: 11, color: i === 0 ? 'EDE9FE' : muted, margin: 0, fit: 'shrink' }); });
footer(s, 3);

s = pptx.addSlide(); title(s, 'Interface design', 'The visual system used in the Flutter app');
[['4C1D95', 'Primary'], ['8B5CF6', 'Accent'], ['FCFAFF', 'Background'], ['16855B', 'Success']].forEach((c, i) => { const x = 0.9 + i * 2.7; s.addShape(pptx.ShapeType.roundRect, { x, y: 2, w: 2.15, h: 1.15, rectRadius: 0.08, fill: { color: c[0] }, line: { color: c[0] } }); s.addText(c[1], { x, y: 3.35, w: 2.15, h: 0.3, align: 'center', fontSize: 13, bold: true, color: ink, margin: 0 }); });
bullet(s, 'Rounded cards group related information.', 4.35, { x: 1.05, w: 5.1 });
bullet(s, 'Large headings and clear verbs support quick scanning.', 4.85, { x: 1.05, w: 5.1 });
bullet(s, 'Status is shown with text and colour for accessibility.', 5.35, { x: 1.05, w: 5.1 });
footer(s, 4);

s = pptx.addSlide(); title(s, 'Technical solution', 'How the parts work together');
[['Flutter app', 'Mobile interface\nSample fallback'], ['Spring Boot', 'REST endpoints\nValidation'], ['MySQL', 'Users, medicines\nOrders and records'], ['Firebase', 'Authentication\nFirestore rules']].forEach((item, i) => { const x = 0.7 + i * 3.1; s.addShape(pptx.ShapeType.roundRect, { x, y: 2.2, w: 2.5, h: 1.65, rectRadius: 0.08, fill: { color: i === 0 ? 'EDE9FE' : 'FFFFFF' }, line: { color: 'DDD6FE' } }); s.addText(item[0], { x: x + 0.2, y: 2.48, w: 2.1, h: 0.3, fontSize: 16, bold: true, color: purple, margin: 0, align: 'center' }); s.addText(item[1], { x: x + 0.2, y: 3.0, w: 2.1, h: 0.55, fontSize: 11, color: muted, margin: 0, align: 'center' }); if (i < 3) s.addText('→', { x: x + 2.57, y: 2.75, w: 0.45, h: 0.4, fontSize: 22, color: violet, margin: 0, align: 'center' }); });
footer(s, 5);

s = pptx.addSlide(); title(s, 'Current implementation', 'What is already available');
['Flutter Android and iOS project structure', 'RELIEFROUTE mobile branding', 'Login and dashboard screens', 'Medicine finder with backend connection', 'Orders, reminders, and prescription API endpoints', 'MySQL schema and Firebase security rules', 'Release Android APK build'].forEach((t, i) => bullet(s, t, 1.8 + i * 0.55, { x: 1.0, w: 8.8 }));
footer(s, 6);

s = pptx.addSlide(); title(s, 'Next steps', 'Moving from student prototype to a live service');
['Connect Firebase project and real user login', 'Persist orders, reminders, and prescriptions in MySQL', 'Host the Spring Boot API securely', 'Test on Android and iPhone devices', 'Add privacy, error handling, and release documentation'].forEach((t, i) => bullet(s, t, 1.9 + i * 0.65, { x: 1.0, w: 9.5 }));
s.addText('Thank you', { x: 0.9, y: 5.7, w: 4, h: 0.5, fontSize: 26, bold: true, color: purple, margin: 0 });
footer(s, 7);

pptx.writeFile({ fileName: 'RELIEFROUTE_Project_Presentation.pptx' });
