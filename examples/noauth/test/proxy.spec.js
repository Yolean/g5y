const G5Y_HOST = 'http://localhost';

describe("noauth proxy", () => {

  it("proxies to the echo backend", async () => {
    const response = await fetch(`${G5Y_HOST}/some/path`);
    expect(response.status).toBe(200);
    expect(response.headers.get('content-type')).toBe('application/json');
    const echo = await response.json();
    expect(echo).toMatchObject({
      path: '/some/path',
    });
  });

});
