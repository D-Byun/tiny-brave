import { describe, expect, it } from "vitest";
import { isQuietHour, makeCode } from "../src/shared.js";

describe("isQuietHour", () => {
  // 03:00 UTC is 22:00 the previous day in Chicago (CDT) and 12:00 in Seoul.
  const at = new Date("2026-06-15T03:00:00Z");

  it("is quiet at night in the recipient's time zone", () => {
    expect(isQuietHour("America/Chicago", at)).toBe(true);
  });

  it("is not quiet in the daytime", () => {
    expect(isQuietHour("Asia/Seoul", at)).toBe(false);
  });

  it("never blocks pushes for a missing or bogus zone", () => {
    expect(isQuietHour(undefined, at)).toBe(false);
    expect(isQuietHour("Mars/Olympus", at)).toBe(false);
  });
});

describe("makeCode", () => {
  it("makes six unambiguous capital letters", () => {
    let i = 0;
    const code = makeCode(() => (i++ % 10) / 10);
    expect(code).toMatch(/^[A-HJ-NP-Z]{6}$/);
  });
});
