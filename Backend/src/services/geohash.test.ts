import { describe, it, expect } from "vitest";
import { geohashOf, adjacentGeohash, geohashAndNeighbors } from "./geohash.js";

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

describe("adjacentGeohash", () => {
  it("matches well-known reference values for 'gbsuv'", () => {
    // Reference values computed against the standard geohash neighbor
    // tables (Movable Type variant). "gbsuv" has odd length, so N + E
    // each cross a parent boundary; S + W stay within "gbsu*".
    expect(adjacentGeohash("gbsuv", "n")).toBe("gbsvj");
    expect(adjacentGeohash("gbsuv", "s")).toBe("gbsut");
    expect(adjacentGeohash("gbsuv", "e")).toBe("gbsuy");
    expect(adjacentGeohash("gbsuv", "w")).toBe("gbsuu");
  });

  it("walking N then S returns the original hash", () => {
    const start = geohashOf(37.7749, -122.4194);
    expect(adjacentGeohash(adjacentGeohash(start, "n"), "s")).toBe(start);
  });
});

describe("geohashAndNeighbors", () => {
  it("returns 9 unique buckets for an interior cell", () => {
    const center = geohashOf(37.7749, -122.4194);
    const all = geohashAndNeighbors(center);
    expect(all).toHaveLength(9);
    expect(new Set(all).size).toBe(9);
  });
});

