//  Presence backend
//  geohash.ts
//  5-char geohash buckets are ~4.9km × 4.9km — coarse enough that all users
//  in a typical neighborhood share a room, fine enough that we don't fan
//  out a city-wide event to everyone. Self-contained (no `ngeohash` dep)
//  so deploys stay light.

const BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz";

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
