import assert from 'node:assert/strict';
import { readFile,mkdir } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';
import { createDemoServer } from './serve-demo.mjs';
const server=await createDemoServer(0);
const browser=await chromium.launch({headless:true,...(process.env.PW_CHANNEL?{channel:process.env.PW_CHANNEL}:{})});
const context=await browser.newContext({viewport:{width:1180,height:900},acceptDownloads:true});
const page=await context.newPage();const errors=[],external=[];
page.on('pageerror',error=>errors.push(error.message));
page.on('request',request=>{if(!request.url().startsWith('http://127.0.0.1:')&&!request.url().startsWith('file:'))external.push(request.url());});
const screenshotDir=new URL('../docs/testing/screenshots/',import.meta.url);await mkdir(screenshotDir,{recursive:true});
try{
 await page.goto(`http://127.0.0.1:${server.address().port}/discord.html`);
 await page.waitForSelector('.discord-message');
 const count=await page.locator('.discord-message').count();assert.ok(count>=3);
 await page.locator('#toggle-examples').click();assert.ok(await page.locator('.discord-message').count()>count);
 await page.locator('#toggle-examples').click();assert.equal(await page.locator('.discord-message').count(),count);
 assert.match(await page.locator('.relay-disabled').innerText(),/Aucun message envoyé/);
 for(const category of ['new_wanted','bounty_increased','vengeance']){
  assert.ok(await page.locator(`[data-message-category="${category}"]`).count()>0);
  await page.locator(`[data-category="${category}"]`).uncheck();assert.equal(await page.locator(`[data-message-category="${category}"]`).count(),0);
 }
 assert.equal(await page.locator('#no-messages').isVisible(),true);
 await page.locator('[data-category="new_wanted"]').check();
 const downloadPromise=page.waitForEvent('download');await page.locator('#download-export').click();
 const download=await downloadPromise;const data=JSON.parse(await readFile(await download.path(),'utf8'));
 assert.equal(data.mode,'demo');assert.equal(data.target,'forever');assert.equal(data.guildName,'Le Syndicat Rouge');
 assert.equal(data.notificationState,undefined);assert.equal(data.webhook,undefined);
 await page.locator('[data-category="bounty_increased"]').check();await page.locator('[data-category="vengeance"]').check();
 await page.screenshot({path:fileURLToPath(new URL('discord-desktop.png',screenshotDir)),fullPage:true});
 assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false);
 await page.setViewportSize({width:360,height:800});assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false);
 await page.screenshot({path:fileURLToPath(new URL('discord-mobile.png',screenshotDir)),fullPage:true});
 await page.goto(new URL('../demo/build/discord.html',import.meta.url).href);await page.waitForSelector('.discord-message');
 assert.equal(await page.locator('.discord-message').count(),count);
 assert.deepEqual(errors,[]);assert.deepEqual(external,[]);
 console.log('Discord browser: real relay examples, category filters, demo JSON download, desktop/mobile, direct file and no external requests passed.');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
