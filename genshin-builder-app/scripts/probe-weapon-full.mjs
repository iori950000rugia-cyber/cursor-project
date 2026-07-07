const r = await fetch("https://gi.yatta.moe/api/v2/jp/weapon/11509", {
  signal: AbortSignal.timeout(15000),
});
const j = await r.json();
console.log(JSON.stringify(j.data, null, 2).slice(0, 12000));
