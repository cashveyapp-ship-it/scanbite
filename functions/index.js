// v5 - clean
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");

exports.scanbiteOpenAI = onCall(
  {
    region: "us-central1",
    secrets: [OPENAI_API_KEY],
    timeoutSeconds: 120,
    memory: "512MiB",
  },
  async (request) => {

    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign-in required.");
    }

    const apiKey = OPENAI_API_KEY.value();
    if (!apiKey) {
      throw new HttpsError("failed-precondition", "Missing OPENAI_API_KEY secret.");
    }

    const mode        = String(request.data?.mode        ?? "text").trim();
    const prompt      = String(request.data?.prompt      ?? "").trim();
    const imageBase64 = String(request.data?.imageBase64 ?? "").trim();
    const imageMime   = String(request.data?.imageMime   ?? "image/jpeg").trim();

    if (!prompt) throw new HttpsError("invalid-argument", "Missing prompt.");
    if (prompt.length > 20000) throw new HttpsError("invalid-argument", "Prompt too long.");

    if (mode === "vision" && !imageBase64) {
      throw new HttpsError("invalid-argument", "Missing imageBase64 for vision mode.");
    }

    const messages = [
      {
        role: "system",
        content: "You are a helpful nutrition assistant. Always respond with valid JSON only. No markdown.",
      },
    ];

    if (mode === "vision") {
      messages.push({
        role: "user",
        content: [
          { type: "text", text: prompt },
          {
            type: "image_url",
            image_url: {
              url: "data:" + imageMime + ";base64," + imageBase64,
              detail: "low",
            },
          },
        ],
      });
    } else {
      messages.push({ role: "user", content: prompt });
    }

    let resp;
    try {
      resp = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Authorization": "Bearer " + apiKey,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model:       mode === "vision" ? "gpt-4o" : "gpt-4o-mini",
          messages,
          temperature: mode === "vision" ? 0.2 : 0.7,
          max_tokens:  mode === "vision" ? 2500 : 300,
        }),
        signal: AbortSignal.timeout(90000),
      });
    } catch (networkErr) {
      console.error("Network error calling OpenAI:", networkErr.message);
      throw new HttpsError("deadline-exceeded", "Could not reach OpenAI. Try again.");
    }

    if (!resp.ok) {
      const bodyText = await resp.text();
      console.error("OpenAI HTTP " + resp.status + ": " + bodyText);

      if (resp.status === 401) {
        throw new HttpsError("failed-precondition", "Invalid OpenAI API key.", { status: 401 });
      }
      if (resp.status === 429) {
        throw new HttpsError("resource-exhausted", "OpenAI rate limit exceeded.", { status: 429 });
      }
      throw new HttpsError("internal", "OpenAI error " + resp.status, { status: resp.status });
    }

    const json = await resp.json();
    const content = json?.choices?.[0]?.message?.content ?? "";

    if (!content) {
      throw new HttpsError("internal", "OpenAI returned empty content.");
    }

    console.log("scanbiteOpenAI [" + mode + "] OK - " + content.length + " chars");
    return { ok: true, content };
  }
);
