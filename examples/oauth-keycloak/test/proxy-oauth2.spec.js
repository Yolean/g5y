const G5Y_HOST = 'http://localhost';

describe("oauth-keycloak proxy", () => {

  it("requires authentication", async () => {
    const response = await fetch(`${G5Y_HOST}/some/path`);
    expect(response.status).toBe(401);
  });

});
