import { handler } from "./index";
import { APIGatewayProxyEvent, Context } from "aws-lambda";

// Mock the fetch function so we don't make actual HTTP requests
global.fetch = jest.fn();

describe("BookTitleSearchFunction", () => {
  // Save the original env vars to restore after tests
  const originalEnv = process.env;

  beforeEach(() => {
    jest.resetModules();
    process.env = { ...originalEnv, GOOGLE_BOOKS_API_KEY: "mock-api-key" };
    jest.clearAllMocks();

    // mute console.error for expected failure logs
    jest.spyOn(console, "error").mockImplementation(() => {});
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  //
  // ========= Mock the API Gateway event =========
  //
  // FIXME: add additional event properties? our handler function only uses
  // `queryStringParameters` though so may be overkill
  const createMockEvent = (
    queryStringParameters: any = {},
  ): APIGatewayProxyEvent =>
    ({
      queryStringParameters,
    }) as any;

  //
  // ========= Happy Path =========
  //
  it("returns 200 and book data on successful API call", async () => {
    // mock Google Books payload. in particular the industryIdentifiers key because it should
    // get parsed into our 'clean' interface
    const mockGoogleResponse = {
      items: [
        {
          id: "123",
          volumeInfo: {
            title: "Accelerando",
            authors: ["Charles Stross"],
            industryIdentifiers: [
              { type: "ISBN_13", identifier: "9781101208472" },
            ],
          },
        },
      ],
    };

    (global.fetch as jest.Mock).mockResolvedValue({
      ok: true,
      json: async () => mockGoogleResponse,
    });

    const event = createMockEvent({ q: "accelerando" });
    const response = await handler(event);

    expect(response.statusCode).toBe(200);
    const body = JSON.parse(response.body);

    // Assert that mocked Google data is mapped to our 'clean' interface
    expect(body.results).toHaveLength(1);
    expect(body.results[0]).toEqual({
      id: "123",
      title: "Accelerando",
      authors: ["Charles Stross"],
      isbn: "9781101208472",
    });
  });

  //
  // ========= Data Handling =========
  //
  it("correctly handles multiple industryIdentifier members (ISBN13, ISBN10, missing)", async () => {
    const mockGoogleResponse = {
      items: [
        {
          id: "book-1",
          volumeInfo: {
            title: "Book with ISBN10 only",
            authors: ["Author A"],
            industryIdentifiers: [
              { type: "ISBN_10", identifier: "1234567890" },
            ],
          },
        },
        {
          id: "book-2",
          volumeInfo: {
            title: "Book with ISBN10 and ISBN13",
            authors: ["Author C"],
            industryIdentifiers: [
              { type: "ISBN_10", identifier: "0987654321" },
              { type: "ISBN_13", identifier: "9780987654321" },
            ],
          },
        },
        {
          id: "book-3",
          volumeInfo: {
            title: "Book with no industryIdentifiers",
            authors: ["Author B"],
            // industryIdentifiers intentionally omitted
          },
        },
      ],
    };

    (global.fetch as jest.Mock).mockResolvedValue({
      ok: true,
      json: async () => mockGoogleResponse,
    });

    const event = createMockEvent({ q: "edge cases" });
    const response = await handler(event);
    const body = JSON.parse(response.body);

    expect(response.statusCode).toBe(200);
    expect(body.results).toHaveLength(3);

    // Assert extraction of ISBN10
    expect(body.results[0].isbn).toBe("1234567890");
    // Assert ISBN13 extracted instead of ISBN10
    expect(body.results[1].isbn).toBe("9780987654321");
    // Assert safely handling missing identifiers
    expect(body.results[2].isbn).toBeNull();
  });

  //
  // ========= Response Code Handling (non-200) =========
  //
  // ========= 400 series =========
  it('returns 400 if "q" param is missing', async () => {
    const event = createMockEvent({});
    const response = await handler(event);

    expect(response.statusCode).toBe(400);
    expect(JSON.parse(response.body).message).toContain(
      "Missing required query parameter: 'q'",
    );
  });

  it("returns 429 if Google Books API rate limits the request", async () => {
    (global.fetch as jest.Mock).mockResolvedValue({
      ok: false,
      status: 429,
      statusText: "Too Many Requests",
    });

    const event = createMockEvent({ q: "accelerando" });
    const response = await handler(event);

    expect(response.statusCode).toBe(429);
    expect(JSON.parse(response.body).message).toContain(
      "Error communicating with external service",
    );
  });

  // ========= 500 series =========
  it("returns 500 if API key is missing", async () => {
    delete process.env.GOOGLE_BOOKS_API_KEY;
    const event = createMockEvent({ q: "foundation" });

    const response = await handler(event);

    expect(response.statusCode).toBe(500);
    expect(JSON.parse(response.body).message).toContain(
      "Internal server error: Missing configuration data.",
    );
  });

  it("returns 500 if an unhandled runtime exception occurs", async () => {
    // Force the fetch call to throw a catastrophic error
    (global.fetch as jest.Mock).mockRejectedValue(
      new Error("Simulated DNS resolution failure"),
    );

    const event = createMockEvent({ q: "accelerando" });
    const response = await handler(event);

    expect(response.statusCode).toBe(500);
    expect(JSON.parse(response.body).message).toContain(
      "An unexpected error occurred",
    );
  });

  it("should return 502 if the external Google API fails", async () => {
    (global.fetch as jest.Mock).mockResolvedValue({
      ok: false,
      status: 500,
      statusText: "Internal Server Error",
    });

    const event = createMockEvent({ q: "accelerando" });
    const response = await handler(event);

    expect(response.statusCode).toBe(502);
    expect(JSON.parse(response.body).message).toContain(
      "Error communicating with external service",
    );
  });
});
