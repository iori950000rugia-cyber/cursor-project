const r = await fetch("https://gi.yatta.moe/api/v2/jp/avatar/10000046", {
  signal: AbortSignal.timeout(15000),
});
const j = await r.json();
console.log(JSON.stringify(j.data.upgrade, null, 2).slice(0, 8000));
