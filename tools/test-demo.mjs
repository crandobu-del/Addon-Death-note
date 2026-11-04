import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';
import { mkdir } from 'node:fs/promises';
import { chromium } from 'playwright';
import { createDemoServer } from './serve-demo.mjs';

const server=await createDemoServer(0);
const url=`http://127.0.0.1:${server.address().port}`;
const browser=await chromium.launch({headless:true,...(process.env.PW_CHANNEL?{channel:process.env.PW_CHANNEL}:{})});
const context=await browser.newContext({viewport:{width:1180,height:900}});
const page=await context.newPage();
const errors=[];page.on('pageerror',error=>errors.push(error.message));
const screenshots=new URL('../docs/testing/screenshots/',import.meta.url);
await mkdir(screenshots,{recursive:true});
async function ready(){await page.waitForFunction(()=>document.getElementById('status').textContent.includes('prête'));}
async function noOverflow(){assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false,'horizontal overflow');}
try {
 await page.goto(url);await ready();
 assert.equal(await page.locator('.target').count(),4);
 await page.getByRole('button',{name:'Masquer le registre'}).click();
 assert.equal(await page.locator('.book').isVisible(),false);
 await page.getByRole('button',{name:'Afficher le registre'}).click();
 assert.equal(await page.locator('.book').isVisible(),true);
 assert.match(await page.locator('#dossier .reward').innerText(),/\+3 réputation/);
 await page.screenshot({path:fileURLToPath(new URL('wanted-desktop.png',screenshots)),fullPage:true});
 await page.locator('#simulate').click();
 assert.equal(await page.locator('#simulate').isDisabled(),true);
 assert.match(await page.locator('#dossier .reward').innerText(),/\+0 réputation/);
 await page.getByRole('tab',{name:'Vengeurs'}).click();
 assert.match(await page.locator('#ranking tr').first().innerText(),/Kaëlan/);
 assert.equal(await page.locator('#ranking tr').first().locator('td').nth(2).innerText(),'4');
 await page.screenshot({path:fileURLToPath(new URL('avengers-desktop.png',screenshots)),fullPage:true});
 await page.getByRole('tab',{name:'Journal',exact:true}).click();
 assert.equal(await page.locator('#journal .event').count(),12);
 await page.getByRole('button',{name:'Vengeances',exact:true}).click();
 assert.equal(await page.locator('#journal .event').count(),4);
 await page.screenshot({path:fileURLToPath(new URL('journal-desktop.png',screenshots)),fullPage:true});
 await page.getByRole('tab',{name:/Notifications/}).click();
 assert.equal(await page.locator('#notifications .notice').count(),2);
 assert.equal(await page.locator('#unread').innerText(),'2');
 await page.locator('[data-thank]').first().click();
 assert.equal(await page.locator('[data-thank]').first().isDisabled(),true);
 assert.equal(await page.locator('#unread').innerText(),'1');
 await page.locator('#alert-vengeance').uncheck();
 await page.screenshot({path:fileURLToPath(new URL('notifications-desktop.png',screenshots)),fullPage:true});
 await page.reload();await ready();
 await page.getByRole('tab',{name:/Notifications/}).click();
 assert.equal(await page.locator('[data-thank]').first().isDisabled(),true);
 assert.equal(await page.locator('#alert-vengeance').isChecked(),false);
 await page.getByRole('tab',{name:'Recherchés'}).click();
 await page.locator('#search').fill('inexistant');assert.equal(await page.locator('.target').count(),0);
 await page.locator('#search').fill('<img src=x onerror=alert(1)>');assert.equal(await page.locator('.target').count(),0);
 await page.locator('#search').fill('');
 await noOverflow();
 await page.setViewportSize({width:360,height:800});
 for(const name of ['Recherchés','Vengeurs','Journal']){await page.getByRole('tab',{name,exact:true}).click();await noOverflow();}
 await page.getByRole('tab',{name:/Notifications/}).click();await noOverflow();
 await page.screenshot({path:fileURLToPath(new URL('notifications-mobile.png',screenshots)),fullPage:true});
 await page.locator('#reset').click();assert.equal(await page.locator('#unread').innerText(),'1');
 assert.match(await page.locator('#dossier .reward').innerText(),/\+3 réputation/);
 // Corrupted state is reported and retained rather than silently overwritten.
 await page.evaluate(()=>localStorage.setItem('syndicat-rouge:offline-demo:v1','{"broken"'));
 await page.reload();await ready();assert.equal(await page.locator('#storage-warning').isVisible(),true);
 assert.equal(await page.evaluate(()=>localStorage.getItem('syndicat-rouge:offline-demo:v1')),'{"broken"');
 await page.locator('#reset').click();assert.equal(await page.locator('#storage-warning').isVisible(),false);
 const localPage=await context.newPage();localPage.on('pageerror',error=>errors.push(error.message));
 await localPage.goto(new URL('../demo/build/index.html',import.meta.url).href);
 await localPage.waitForFunction(()=>document.getElementById('status').textContent.includes('prête'));
 assert.equal(await localPage.locator('.target').count(),4);
 await localPage.close();
 assert.deepEqual(errors,[]);
 console.log(`Browser ${await browser.version()}: navigation, shared Lua rewards, notifications, thanks, reload, search, mobile layout, reset, corrupted storage and direct file opening passed.`);
} finally {await browser.close();await new Promise(resolve=>server.close(resolve));}
