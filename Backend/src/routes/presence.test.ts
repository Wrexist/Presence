//  Presence backend
//  presence.test.ts
//  Vitest + supertest coverage for /api/presence routes. Mocks
//  ../services/supabase + ../services/socketHub so tests don't need a
//  Supabase project or a running websocket. Each test composes its own
//  builder responses.

import { describe, it, expect, beforeEach, vi } from "vitest";
import request from "supertest";

const supabaseMock = {
  auth: { getUser: vi.fn() },
  from: vi.fn(),
  rpc: vi.fn()
};

vi.mock("../services/supabase.js", () => ({
  getSupabase: () => supabaseMock
}));

const broadcastMock = vi.fn();
vi.mock("../services/socketHub.js", () => ({
  broadcast: (...args: unknown[]) => broadcastMock(...args),
  setIO: () => undefined
}));

// Import AFTER mocks so the route module picks up the mocked services.
const { createApp } = await import("../app.js");
const app = createApp();

beforeEach(() => {
  supabaseMock.auth.getUser.mockReset();
  supabaseMock.from.mockReset();
  supabaseMock.rpc.mockReset();
  broadcastMock.mockReset();
});

// ─── Helpers ─────────────────────────────────────────────────────────────────

function authedUser(id = "11111111-1111-1111-1111-111111111111") {
  supabaseMock.auth.getUser.mockResolvedValue({ data: { user: { id } }, error: null });
}

interface BuilderResponse {
  data: unknown;
  error: unknown;
  count?: number;
}

function buildBuilder(response: BuilderResponse) {
  const builder: Record<string, unknown> = {
    insert: () => builder,
    select: () => builder,
    update: () => builder,
    eq: () => builder,
    gte: () => builder,
    lt: () => builder,
    single: () => builder,
    maybeSingle: () => builder,
    then: (resolve: (value: BuilderResponse) => unknown) =>
      Promise.resolve(response).then(resolve)
  };
  return builder;
}

// ─── POST /api/presence ──────────────────────────────────────────────────────

describe("POST /api/presence", () => {
  it("returns 401 without an Authorization header", async () => {
    const res = await request(app).post("/api/presence").send({
      location: { lat: 37.77, lng: -122.42 }
    });
    expect(res.status).toBe(401);
    expect(res.body).toEqual({ error: "unauthorized" });
  });

  it("returns 400 on a malformed body", async () => {
    authedUser();
    const res = await request(app)
      .post("/api/presence")
      .set("Authorization", "Bearer t")
      .send({ location: { lat: 999, lng: -122 } });
    expect(res.status).toBe(400);
    expect(res.body.error).toBe("invalid_request");
  });

  it("inserts and broadcasts presence_joined", async () => {
    authedUser("user-1");
    const expiresAt = "2026-04-26T20:00:00.000Z";
    // Calls in order: user lookup (is_plus), weekly count, presence insert.
    supabaseMock.from
      .mockReturnValueOnce(buildBuilder({ data: { is_plus: false }, error: null }))
      .mockReturnValueOnce(buildBuilder({ data: null, error: null, count: 0 }))
      .mockReturnValueOnce(
        buildBuilder({ data: { id: "p-1", expires_at: expiresAt }, error: null })
      );

    const res = await request(app)
      .post("/api/presence")
      .set("Authorization", "Bearer t")
      .send({
        location: { lat: 37.77, lng: -122.42 },
        venueName: "Bluestone",
        venueType: "cafe"
      });

    expect(res.status).toBe(201);
    expect(res.body).toEqual({ id: "p-1", expiresAt });
    expect(broadcastMock).toHaveBeenCalledTimes(1);
    const [room, event, payload] = broadcastMock.mock.calls[0]!;
    expect(room).toMatch(/^zone:[0-9a-z]{5}$/);
    expect(event).toBe("presence_joined");
    expect(payload).toMatchObject({ id: "p-1", lat: 37.77, lng: -122.42 });
  });

  it("returns 402 free_limit when a non-plus user has 3 presences this week", async () => {
    authedUser("user-1");
    supabaseMock.from
      .mockReturnValueOnce(buildBuilder({ data: { is_plus: false }, error: null }))
      .mockReturnValueOnce(buildBuilder({ data: null, error: null, count: 3 }));

    const res = await request(app)
      .post("/api/presence")
      .set("Authorization", "Bearer t")
      .send({ location: { lat: 37.77, lng: -122.42 } });

    expect(res.status).toBe(402);
    expect(res.body).toMatchObject({ error: "free_limit", weeklyUsed: 3 });
    expect(res.body.resetsAt).toEqual(expect.any(String));
    expect(broadcastMock).not.toHaveBeenCalled();
  });

  it("skips the limit check for plus users", async () => {
    authedUser("user-1");
    const expiresAt = "2026-04-26T20:00:00.000Z";
    // Only 2 calls: user lookup (is_plus=true skips count), then insert.
    supabaseMock.from
      .mockReturnValueOnce(buildBuilder({ data: { is_plus: true }, error: null }))
      .mockReturnValueOnce(
        buildBuilder({ data: { id: "p-2", expires_at: expiresAt }, error: null })
      );

    const res = await request(app)
      .post("/api/presence")
      .set("Authorization", "Bearer t")
      .send({ location: { lat: 37.77, lng: -122.42 } });

    expect(res.status).toBe(201);
  });

  it("returns 500 if the insert fails", async () => {
    authedUser();
    supabaseMock.from
      .mockReturnValueOnce(buildBuilder({ data: { is_plus: true }, error: null }))
      .mockReturnValueOnce(buildBuilder({ data: null, error: { message: "boom" } }));
    const res = await request(app)
      .post("/api/presence")
      .set("Authorization", "Bearer t")
      .send({ location: { lat: 37.77, lng: -122.42 } });
    expect(res.status).toBe(500);
  });
});

// ─── GET /api/presence/nearby ────────────────────────────────────────────────

describe("GET /api/presence/nearby", () => {
  it("returns 401 without auth", async () => {
    const res = await request(app).get("/api/presence/nearby?lat=37.77&lng=-122.42");
    expect(res.status).toBe(401);
  });

  it("returns 400 on missing query params", async () => {
    authedUser();
    const res = await request(app)
      .get("/api/presence/nearby")
      .set("Authorization", "Bearer t");
    expect(res.status).toBe(400);
  });

  it("maps RPC rows into camelCase response", async () => {
    authedUser("caller-id");
    supabaseMock.rpc.mockResolvedValue({
      data: [
        {
          id: "p-1",
          user_id: "u-1",
          username: "morningfern",
          bio: "loves coffee mornings",
          lat: 37.77,
          lng: -122.42,
          venue_name: "Bluestone",
          expires_at: "2026-04-26T20:00:00.000Z"
        }
      ],
      error: null
    });

    const res = await request(app)
      .get("/api/presence/nearby?lat=37.77&lng=-122.42&radiusM=750")
      .set("Authorization", "Bearer t");

    expect(res.status).toBe(200);
    expect(supabaseMock.rpc).toHaveBeenCalledWith("nearby_presences", {
      p_lat: 37.77,
      p_lng: -122.42,
      p_radius_m: 750,
      p_caller: "caller-id"
    });
    expect(res.body.presences[0]).toEqual({
      id: "p-1",
      userId: "u-1",
      username: "morningfern",
      bio: "loves coffee mornings",
      lat: 37.77,
      lng: -122.42,
      venueName: "Bluestone",
      expiresAt: "2026-04-26T20:00:00.000Z"
    });
  });
});

// ─── DELETE /api/presence/:id ────────────────────────────────────────────────

describe("DELETE /api/presence/:id", () => {
  it("returns 401 without auth", async () => {
    const res = await request(app).delete(
      "/api/presence/11111111-1111-1111-1111-111111111111"
    );
    expect(res.status).toBe(401);
  });

  it("returns 204 and broadcasts presence_left when a row was updated", async () => {
    authedUser("user-1");
    supabaseMock.from.mockReturnValue(
      buildBuilder({
        data: {
          id: "p-1",
          location: { type: "Point", coordinates: [-122.42, 37.77] }
        },
        error: null
      })
    );

    const res = await request(app)
      .delete("/api/presence/11111111-1111-1111-1111-111111111111")
      .set("Authorization", "Bearer t");

    expect(res.status).toBe(204);
    expect(broadcastMock).toHaveBeenCalledTimes(1);
    const [, event, payload] = broadcastMock.mock.calls[0]!;
    expect(event).toBe("presence_left");
    expect(payload).toEqual({ id: "p-1" });
  });

  it("returns 204 silently when nothing matched", async () => {
    authedUser();
    supabaseMock.from.mockReturnValue(buildBuilder({ data: null, error: null }));
    const res = await request(app)
      .delete("/api/presence/11111111-1111-1111-1111-111111111111")
      .set("Authorization", "Bearer t");
    expect(res.status).toBe(204);
    expect(broadcastMock).not.toHaveBeenCalled();
  });
});
