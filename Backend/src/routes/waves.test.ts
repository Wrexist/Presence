//  Presence backend
//  waves.test.ts
//  Vitest coverage for /api/waves. Mocks ../services/supabase,
//  ../services/socketHub, and ../services/pushService so the wave flow
//  can be exercised without external services.

import { describe, it, expect, beforeEach, vi } from "vitest";
import request from "supertest";

const supabaseMock = {
  auth: { getUser: vi.fn() },
  from: vi.fn()
};

vi.mock("../services/supabase.js", () => ({
  getSupabase: () => supabaseMock
}));

const broadcastMock = vi.fn();
vi.mock("../services/socketHub.js", () => ({
  broadcast: (...args: unknown[]) => broadcastMock(...args),
  setIO: () => undefined
}));

const sendPushMock = vi.fn();
vi.mock("../services/pushService.js", () => ({
  sendPushToUser: (...args: unknown[]) => sendPushMock(...args)
}));

const { createApp } = await import("../app.js");
const app = createApp();

beforeEach(() => {
  supabaseMock.auth.getUser.mockReset();
  supabaseMock.from.mockReset();
  broadcastMock.mockReset();
  sendPushMock.mockReset();
});

function authedUser(id = "11111111-1111-1111-1111-111111111111") {
  supabaseMock.auth.getUser.mockResolvedValue({ data: { user: { id } }, error: null });
}

interface BuilderResponse {
  data: unknown;
  error: unknown;
}

function buildBuilder(response: BuilderResponse) {
  const builder: Record<string, unknown> = {
    insert: () => builder,
    select: () => builder,
    update: () => builder,
    upsert: () => builder,
    eq: () => builder,
    or: () => builder,
    gt: () => builder,
    order: () => builder,
    limit: () => builder,
    single: () => builder,
    maybeSingle: () => builder,
    then: (resolve: (value: BuilderResponse) => unknown) =>
      Promise.resolve(response).then(resolve)
  };
  return builder;
}

const SENDER = "11111111-1111-1111-1111-111111111111";
const RECEIVER = "22222222-2222-2222-2222-222222222222";

// ─── POST /api/waves ─────────────────────────────────────────────────────────

describe("POST /api/waves", () => {
  it("rejects self-waves with 400", async () => {
    authedUser(SENDER);
    const res = await request(app)
      .post("/api/waves")
      .set("Authorization", "Bearer t")
      .send({
        receiverId: SENDER,
        icebreaker: "Hey, do you know if the place across the street is good?"
      });
    expect(res.status).toBe(400);
    expect(res.body.error).toBe("self_wave");
  });

  it("returns 403 when blocked", async () => {
    authedUser(SENDER);
    // First .from() call is the blocks lookup — return a non-empty array.
    supabaseMock.from.mockReturnValueOnce(
      buildBuilder({ data: [{ blocker_id: RECEIVER }], error: null })
    );
    const res = await request(app)
      .post("/api/waves")
      .set("Authorization", "Bearer t")
      .send({
        receiverId: RECEIVER,
        icebreaker: "This place has the best afternoon light — local favourite?"
      });
    expect(res.status).toBe(403);
    expect(res.body.error).toBe("blocked");
  });

  it("inserts, broadcasts, and queues a push on success", async () => {
    authedUser(SENDER);
    // Calls in order: blocks lookup, waves insert, users select.
    supabaseMock.from
      .mockReturnValueOnce(buildBuilder({ data: [], error: null }))
      .mockReturnValueOnce(
        buildBuilder({
          data: {
            id: "wave-1",
            sender_id: SENDER,
            receiver_id: RECEIVER,
            icebreaker: "x".repeat(40),
            status: "sent",
            sent_at: "2026-04-26T12:00:00.000Z",
            responded_at: null,
            expires_at: "2026-04-26T14:00:00.000Z"
          },
          error: null
        })
      )
      .mockReturnValueOnce(
        buildBuilder({
          data: { id: SENDER, username: "morningfern", bio: "loves coffee mornings" },
          error: null
        })
      );

    sendPushMock.mockResolvedValue({ sent: 0, ok: false });

    const res = await request(app)
      .post("/api/waves")
      .set("Authorization", "Bearer t")
      .send({
        receiverId: RECEIVER,
        icebreaker: "This place has the best afternoon light — local favourite?"
      });

    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({ id: "wave-1", status: "sent" });

    expect(broadcastMock).toHaveBeenCalledTimes(1);
    const [room, event, payload] = broadcastMock.mock.calls[0]!;
    expect(room).toBe(`user:${RECEIVER}`);
    expect(event).toBe("wave_received");
    expect(payload).toMatchObject({
      id: "wave-1",
      senderUsername: "morningfern"
    });

    expect(sendPushMock).toHaveBeenCalledTimes(1);
    expect(sendPushMock.mock.calls[0]![0]).toBe(RECEIVER);
  });
});

// ─── POST /api/waves/:id/respond ─────────────────────────────────────────────

describe("POST /api/waves/:id/respond", () => {
  const waveId = "33333333-3333-3333-3333-333333333333";

  it("returns 403 when caller is not the receiver", async () => {
    authedUser(SENDER); // pretend the sender tries to respond to their own wave
    supabaseMock.from.mockReturnValueOnce(
      buildBuilder({
        data: {
          id: waveId,
          sender_id: SENDER,
          receiver_id: RECEIVER,
          status: "sent",
          expires_at: new Date(Date.now() + 60_000).toISOString()
        },
        error: null
      })
    );

    const res = await request(app)
      .post(`/api/waves/${waveId}/respond`)
      .set("Authorization", "Bearer t")
      .send({ accepted: true });

    expect(res.status).toBe(403);
    expect(res.body.error).toBe("not_receiver");
  });

  it("returns 410 when expired", async () => {
    authedUser(RECEIVER);
    supabaseMock.from.mockReturnValueOnce(
      buildBuilder({
        data: {
          id: waveId,
          sender_id: SENDER,
          receiver_id: RECEIVER,
          status: "sent",
          expires_at: new Date(Date.now() - 60_000).toISOString()
        },
        error: null
      })
    );

    const res = await request(app)
      .post(`/api/waves/${waveId}/respond`)
      .set("Authorization", "Bearer t")
      .send({ accepted: true });

    expect(res.status).toBe(410);
  });

  it("creates a connection + dual broadcast on accepted", async () => {
    authedUser(RECEIVER);
    // Calls: load wave, update wave, insert connection.
    supabaseMock.from
      .mockReturnValueOnce(
        buildBuilder({
          data: {
            id: waveId,
            sender_id: SENDER,
            receiver_id: RECEIVER,
            status: "sent",
            expires_at: new Date(Date.now() + 60_000).toISOString()
          },
          error: null
        })
      )
      .mockReturnValueOnce(buildBuilder({ data: { id: waveId }, error: null }))
      .mockReturnValueOnce(buildBuilder({ data: { id: "conn-1" }, error: null }));

    sendPushMock.mockResolvedValue({ sent: 0, ok: false });

    const res = await request(app)
      .post(`/api/waves/${waveId}/respond`)
      .set("Authorization", "Bearer t")
      .send({ accepted: true });

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ mutual: true, waveId });
    expect(broadcastMock).toHaveBeenCalledTimes(2);
    const rooms = broadcastMock.mock.calls.map((c) => c[0]);
    expect(rooms).toContain(`user:${SENDER}`);
    expect(rooms).toContain(`user:${RECEIVER}`);
  });

  it("just stamps responded_at when declined", async () => {
    authedUser(RECEIVER);
    supabaseMock.from
      .mockReturnValueOnce(
        buildBuilder({
          data: {
            id: waveId,
            sender_id: SENDER,
            receiver_id: RECEIVER,
            status: "sent",
            expires_at: new Date(Date.now() + 60_000).toISOString()
          },
          error: null
        })
      )
      .mockReturnValueOnce(buildBuilder({ data: null, error: null }));

    const res = await request(app)
      .post(`/api/waves/${waveId}/respond`)
      .set("Authorization", "Bearer t")
      .send({ accepted: false });

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ mutual: false });
    expect(broadcastMock).not.toHaveBeenCalled();
  });
});

// ─── GET /api/waves ──────────────────────────────────────────────────────────

describe("GET /api/waves", () => {
  it("returns incoming + outgoing", async () => {
    authedUser(RECEIVER);
    supabaseMock.from
      .mockReturnValueOnce(
        buildBuilder({
          data: [
            {
              id: "w1",
              sender_id: SENDER,
              receiver_id: RECEIVER,
              icebreaker: "hi",
              status: "sent",
              sent_at: "2026-04-26T12:00:00.000Z",
              expires_at: "2026-04-26T14:00:00.000Z"
            }
          ],
          error: null
        })
      )
      .mockReturnValueOnce(buildBuilder({ data: [], error: null }));

    const res = await request(app)
      .get("/api/waves")
      .set("Authorization", "Bearer t");

    expect(res.status).toBe(200);
    expect(res.body.incoming).toHaveLength(1);
    expect(res.body.incoming[0]).toMatchObject({ id: "w1", senderId: SENDER });
    expect(res.body.outgoing).toEqual([]);
  });
});
