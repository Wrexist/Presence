//  Presence backend
//  geohash.ts
//  5-char geohash buckets are ~4.9km × 4.9km — coarse enough that all users
//  in a typical neighborhood share a room, fine enough that we don't fan
//  out a city-wide event to everyone. Self-contained (no `ngeohash` dep)
//  so deploys stay light.

const BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz";

// Lookup tables for the 4-direction adjacency algorithm. For each direction
// we encode which letters land in the neighbor (NEIGHBORS) vs which letters
// require carrying into the parent geohash (BORDERS). The "even" / "odd"
// split is over the 1-indexed length of the prefix being computed.
const NEIGHBORS = {
  n: { even: "p0r21436x8zb9dcf5h7kjnmqesgutwvy", odd: "bc01fg45238967deuvhjyznpkmstqrwx" },
  s: { even: "14365h7k9dcfesgujnmqp0r2twvyx8zb", odd: "238967debc01fg45kmstqrwxuvhjyznp" },
  e: { even: "bc01fg45238967deuvhjyznpkmstqrwx", odd: "p0r21436x8zb9dcf5h7kjnmqesgutwvy" },
  w: { even: "238967debc01fg45kmstqrwxuvhjyznp", odd: "14365h7k9dcfesgujnmqp0r2twvyx8zb" }
} as const;

const BORDERS = {
  n: { even: "prxz", odd: "bcfguvyz" },
  s: { even: "028b", odd: "0145hjnp" },
  e: { even: "bcfguvyz", odd: "prxz" },
  w: { even: "0145hjnp", odd: "028b" }
} as const;

type Cardinal = "n" | "s" | "e" | "w";

export function geohashOf(lat: number, lng: number, precision = 5): string {
  let latLow = -90;
  let latHigh = 90;
  let lngLow = -180;
  let lngHigh = 180;

  let bit = 0;
  let ch = 0;
  let evenBit = true;
  let geohash = "";

  while (geohash.length < precision) {
    if (evenBit) {
      const lngMid = (lngLow + lngHigh) / 2;
      if (lng >= lngMid) {
        ch = (ch << 1) | 1;
        lngLow = lngMid;
      } else {
        ch = ch << 1;
        lngHigh = lngMid;
      }
    } else {
      const latMid = (latLow + latHigh) / 2;
      if (lat >= latMid) {
        ch = (ch << 1) | 1;
        latLow = latMid;
      } else {
        ch = ch << 1;
        latHigh = latMid;
      }
    }
    evenBit = !evenBit;
    bit++;
    if (bit === 5) {
      geohash += BASE32[ch];
      bit = 0;
      ch = 0;
    }
  }
  return geohash;
}

/// Returns the geohash one step in the given direction. Recursive on parent
/// when crossing a boundary (e.g. moving north out of "x" into the next
/// parent prefix).
export function adjacentGeohash(hash: string, dir: Cardinal): string {
  if (hash.length === 0) return hash;
  const last = hash.slice(-1);
  let parent = hash.slice(0, -1);
  const parity = hash.length % 2 === 0 ? "even" : "odd";

  if (BORDERS[dir][parity].includes(last) && parent.length > 0) {
    parent = adjacentGeohash(parent, dir);
  }

  const idx = NEIGHBORS[dir][parity].indexOf(last);
  if (idx < 0) return hash;
  const nextChar = BASE32[idx]!;
  return parent + nextChar;
}

/// Returns the central geohash plus its 8 neighbors (N, NE, E, SE, S, SW, W, NW).
/// Order is stable but unimportant for room subscription.
export function geohashAndNeighbors(hash: string): string[] {
  const n = adjacentGeohash(hash, "n");
  const s = adjacentGeohash(hash, "s");
  const e = adjacentGeohash(hash, "e");
  const w = adjacentGeohash(hash, "w");
  const ne = adjacentGeohash(n, "e");
  const nw = adjacentGeohash(n, "w");
  const se = adjacentGeohash(s, "e");
  const sw = adjacentGeohash(s, "w");
  return [hash, n, ne, e, se, s, sw, w, nw];
}

