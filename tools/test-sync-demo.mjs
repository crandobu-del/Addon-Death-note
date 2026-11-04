import assert from 'node:assert/strict';
import { fileURLToPath } from 'node:url';
import { mkdir } from 'node:fs/promises';
import { chromium } from 'playwright';
import { createDemoServer } from './serve-demo.mjs';
const server=await createDemoServer(0);
const browser=await chromium.launch({headless:true,...(process.env.PW_CHANNEL?{channel:process.env.PW_CHANNEL}:{})});
const context=await browser.newContext({viewport:{width:1180,height:900}});
const page=await context.newPage();const errors=[];
page.on('pageerror',error=>errors.push(error.message));
const screenshotDir=new URL('../docs/testing/screenshots/',import.meta.url);
await mkdir(screenshotDir,{recursive:true});
const member=index=>page.locator(`[data-register="${index}"]`);
async function ready(){await page.waitForFunction(()=>document.getElementById('sync-status').textContent.includes('Prêt'));}
async function noOverflow(){assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false);}
try{
 await page.goto(`http://127.0.0.1:${server.address().port}/sync.html`);await ready();
 assert.equal(await member(0).locator('tbody tr').count(),1);assert.equal(await member(1).locator('tbody tr').count(),0);
 await page.locator('#exchange').click();
 assert.equal(await member(1).locator('tbody tr').count(),1);
 await page.locator('#repeat').click();assert.match(await page.locator('#sync-status').innerText(),/aucun incident ni point ajouté/);
 await page.locator('[data-online="1"]').uncheck();
 await page.locator('[data-add="0"]').click();
 await page.locator('#exchange').click();assert.match(await page.locator('#sync-status').innerText(),/hors ligne/);
 assert.equal(await member(0).locator('tbody tr').count(),2);assert.equal(await member(1).locator('tbody tr').count(),1);
 await page.locator('[data-online="1"]').check();await page.locator('#exchange').click();
 assert.equal(await member(1).locator('tbody tr').count(),2);
 await page.locator('[data-claim="1"]').click();await page.locator('#exchange').click();
 for(const index of [0,1])assert.match(await member(index).locator('.sync-ranking').innerText(),/Kaëlan\s+2 réputation/);
 assert.equal(await member(0).locator('.sync-notice').count(),1);assert.equal(await member(1).locator('.sync-notice').count(),0);
 await member(0).locator('[data-thank]').click();await page.locator('#exchange').click();
 assert.equal(await member(0).locator('[data-thank]').isDisabled(),true);
 await page.screenshot({path:fileURLToPath(new URL('sync-shared-desktop.png',screenshotDir)),fullPage:true});
 await page.locator('#conflict-scenario').click();
 for(const index of [0,1]){
  assert.match(await member(index).locator('.sync-conflicts').innerText(),/2 revendications en attente/);
  assert.match(await member(index).locator('.sync-ranking').innerText(),/Aucune vengeance validée/);
  assert.match(await member(index).locator('tbody').innerText(),/En attente/);
  assert.match(await member(index).locator('.sync-counts').innerText(),/0 à venger · 1 en attente/);
  assert.equal(await member(index).locator('[data-claim]').isDisabled(),true);
 }
 await page.locator('#repeat').click();assert.equal(await page.locator('.sync-conflicts').count(),2);
 await page.screenshot({path:fileURLToPath(new URL('sync-conflict-desktop.png',screenshotDir)),fullPage:true});
 await noOverflow();await page.setViewportSize({width:360,height:800});await noOverflow();
 await page.screenshot({path:fileURLToPath(new URL('sync-mobile.png',screenshotDir)),fullPage:true});
 await page.locator('#reset-sync').click();assert.equal(await page.locator('.sync-conflicts').count(),0);
 await page.goto(new URL('../demo/build/sync.html',import.meta.url).href);await ready();
 assert.equal(await page.locator('.sync-register').count(),2);
 assert.deepEqual(errors,[]);
 console.log('Sync browser: catch-up, duplicates, offline member, private thanks, conflicting claims, mobile and direct file opening passed.');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
