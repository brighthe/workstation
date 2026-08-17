// Minimal ACP probe for deepseek-acp: initialize -> session/new -> prompt -> print replies.
// Usage: node acp-probe.mjs "<prompt>"
// Reads/writes JSON-RPC over the child's stdio (newline-delimited).
import { spawn } from "node:child_process";

const prompt = process.argv[2] ?? "你好，请用一句话回复";
// ACP_BIN may be a bare command or "node <path>"; split on spaces into argv.
const binRaw = process.env.ACP_BIN ?? "deepseek-acp";
const binArgv = binRaw.split(/\s+/).filter(Boolean);

const child = spawn(binArgv[0], binArgv.slice(1), {
  stdio: ["pipe", "pipe", "pipe"],
  env: { ...process.env },
});

let buf = "";
let nextId = 1;
const pending = new Map();

function send(method, params) {
  const id = nextId++;
  const frame = JSON.stringify({ jsonrpc: "2.0", id, method, params });
  child.stdin.write(frame + "\n");
  return new Promise((resolve, reject) => {
    pending.set(id, { resolve, reject, method });
    setTimeout(() => {
      if (pending.has(id)) {
        pending.delete(id);
        reject(new Error(`timeout waiting for ${method}`));
      }
    }, 120000);
  });
}

function onMessage(msg) {
  if (msg.id !== undefined && pending.has(msg.id)) {
    const p = pending.get(msg.id);
    pending.delete(msg.id);
    if (msg.error) p.reject(new Error(`${p.method} error: ${JSON.stringify(msg.error)}`));
    else p.resolve(msg.result);
    return;
  }
  if (msg.method) {
    // Notifications: log interesting ones briefly.
    const brief = { method: msg.method };
    if (msg.method === "session/update" && msg.params?.session_update) {
      const u = msg.params.session_update;
      brief.update = u.update;
      if (u.text?.length) brief.text = u.text.slice(0, 200);
    }
    console.log(`[notif] ${JSON.stringify(brief)}`);
  }
}

child.stdout.on("data", (d) => {
  buf += d.toString();
  let idx;
  while ((idx = buf.indexOf("\n")) >= 0) {
    const line = buf.slice(0, idx).trim();
    buf = buf.slice(idx + 1);
    if (!line) continue;
    try {
      onMessage(JSON.parse(line));
    } catch (e) {
      console.log(`[non-json] ${line.slice(0, 300)}`);
    }
  }
});

child.stderr.on("data", (d) => {
  process.stderr.write(`[stderr] ${d.toString().trimEnd()}\n`);
});

child.on("exit", (code, sig) => {
  console.log(`[child exit] code=${code} sig=${sig}`);
});

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

try {
  console.log(`== initialize ==`);
  const init = await send("initialize", {
    protocolVersion: 1,
    clientCapabilities: {},
    clientInfo: { name: "acp-probe", version: "0.0.1" },
  });
  console.log(`init ok: agent=${JSON.stringify(init.agentInfo?.name)} auth=${JSON.stringify(init.authMethods ?? [])}`);

  console.log(`== session/new ==`);
  const sess = await send("session/new", {
    cwd: process.cwd(),
    additionalDirectories: [],
    mcpServers: {},
  });
  const sessionId = sess.sessionId;
  console.log(`session: ${sessionId}`);

  console.log(`== session/prompt ==`);
  const result = await send("session/prompt", {
    sessionId,
    prompt: [
      {
        type: "text",
        text: prompt,
      },
    ],
  });
  console.log(`prompt done: stopReason=${JSON.stringify(result?.stopReason)} turn=${JSON.stringify(result?.turn)}`);

  await sleep(500);
  console.log(`== done ==`);
  child.kill();
  process.exit(0);
} catch (e) {
  console.error(`[probe failed] ${e.message}`);
  child.kill();
  process.exit(1);
}
