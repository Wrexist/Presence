import { describe, it, expect } from "vitest";
import { geohashOf } from "./geohash.js";

describe("geohashOf", () => {
  it("returns a 5-char base32 hash by default", () => {
    const hash = geohashOf(37.7749, -122.4194);
    expect(hash).toMatch(/^[0-9a-z]{5}$/);
  });

  it("is stable for the same coords", () => {
    expect(geohashOf(37.7749, -122.4194)).toEqual(geohashOf(37.7749, -122.4194));
  });

  it("places nearby coords (≈100m) in the same 5-char bucket", () => {
    // ~110m east at this latitude
    const a = geohashOf(37.7749, -122.4194);
    const b = geohashOf(37.7749, -122.4181);
    expect(a).toEqual(b);
  });

  it("places far-apart coords in different buckets", () => {
    expect(geohashOf(37.7749, -122.4194)).not.toEqual(geohashOf(40.7128, -74.006));
  });

  it("respects the precision argument", () => {
    expect(geohashOf(0, 0, 7)).toHaveLength(7);
  });
});
