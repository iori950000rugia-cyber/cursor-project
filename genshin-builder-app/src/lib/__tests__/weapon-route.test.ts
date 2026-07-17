import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  fetchWeaponDetail: vi.fn(),
  getWeaponUpgrade: vi.fn(),
  isKnownWeapon: vi.fn(),
}));

vi.mock("@/lib/api/amber-details", () => ({
  fetchWeaponDetail: mocks.fetchWeaponDetail,
}));
vi.mock("@/lib/repository/upgrade-data", () => ({
  getWeaponUpgrade: mocks.getWeaponUpgrade,
}));
vi.mock("@/lib/repository/weapons", () => ({
  isKnownWeapon: mocks.isKnownWeapon,
}));

import { GET } from "@/app/api/weapons/[id]/route";

describe("GET /api/weapons/[id]", () => {
  beforeEach(() => {
    vi.resetAllMocks();
    mocks.isKnownWeapon.mockResolvedValue(true);
    mocks.fetchWeaponDetail.mockResolvedValue({
      id: "11501",
      name: "Test Weapon",
      promotes: [],
    });
    mocks.getWeaponUpgrade.mockResolvedValue(null);
  });

  it.each([
    "",
    "1234",
    "1".repeat(11),
    "abcde",
    "../sync",
    "１２３４５",
  ])("rejects an invalid ID without DB or upstream access: %s", async (id) => {
    const response = await callGet(id);

    expect(response.status).toBe(400);
    expect(mocks.isKnownWeapon).not.toHaveBeenCalled();
    expect(mocks.fetchWeaponDetail).not.toHaveBeenCalled();
    expect(mocks.getWeaponUpgrade).not.toHaveBeenCalled();
  });

  it("rejects a validly shaped but unknown ID before upstream access", async () => {
    mocks.isKnownWeapon.mockResolvedValue(false);

    const response = await callGet("11501");

    expect(response.status).toBe(404);
    expect(mocks.isKnownWeapon).toHaveBeenCalledWith("11501");
    expect(mocks.fetchWeaponDetail).not.toHaveBeenCalled();
    expect(mocks.getWeaponUpgrade).not.toHaveBeenCalled();
  });

  it("returns a known weapon and preserves the response contract", async () => {
    const response = await callGet("11501");
    const body = await response.json();

    expect(response.status).toBe(200);
    expect(body.id).toBe("11501");
    expect(body.name).toBe("Test Weapon");
    expect(body.promotes).toEqual([]);
    expect(mocks.fetchWeaponDetail).toHaveBeenCalledWith("11501");
    expect(mocks.getWeaponUpgrade).toHaveBeenCalledWith("11501");
  });

  it("does not expose internal failure details in response or logs", async () => {
    const log = vi.spyOn(console, "error").mockImplementation(() => {});
    mocks.isKnownWeapon.mockRejectedValue(
      new Error("DATABASE_URL=postgres://secret@private-host"),
    );

    const response = await callGet("11501");
    const body = await response.json();

    expect(response.status).toBe(500);
    expect(JSON.stringify(body)).not.toMatch(/secret|private-host|DATABASE_URL/);
    expect(JSON.stringify(log.mock.calls)).not.toMatch(
      /secret|private-host|DATABASE_URL/,
    );
  });
});

function callGet(id: string): Promise<Response> {
  return GET(new Request(`https://example.test/api/weapons/${id}`), {
    params: Promise.resolve({ id }),
  });
}
