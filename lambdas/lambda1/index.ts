//
// Book Title Search
//
// Search for books by title and return a list of matches including book
// title, author(s), and isbn (sourced from either isbn10 or isbn13)
//
// For simplicity, the query is restricted to a maximum 5 results to encourage
// more specific search strings
//
// This function passes a search string to `books.volumes.list` method of
// provided by Google Books API
// https://developers.google.com/books/docs/v1/reference/volumes/list

import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";

enum HttpStatus {
  OK = 200,
  BAD_REQUEST = 400,
  TOO_MANY_REQUESTS = 429,
  INTERNAL_SERVER_ERROR = 500,
  BAD_GATEWAY = 502,
}

const CONFIG = {
  GOOGLE_BOOKS_URL: "https://www.googleapis.com/books/v1/volumes",
  MAX_RESULTS: 5,
  MAX_TITLE_LENGTH: 100,
};

// interfaces for expected data from Google Books
interface GoogleVolumeInfo {
  title: string;
  authors?: string[];
  description?: string;
  industryIdentifiers?: { type: string; identifier: string }[];
}

interface GoogleBookItem {
  id: string;
  volumeInfo: GoogleVolumeInfo;
}

interface GoogleBooksResponse {
  items?: GoogleBookItem[];
}

// structure for returning data to client
interface LibraryBookItem {
  id: string;
  title: string;
  authors: string[];
  isbn: string | null;
}

const createResponse = (
  statusCode: HttpStatus,
  body: object,
): APIGatewayProxyResult => ({
  statusCode,
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(body),
});

export const handler = async (
  event: APIGatewayProxyEvent,
): Promise<APIGatewayProxyResult> => {
  try {
    // verify api key exists
    const apiKey = process.env.GOOGLE_BOOKS_API_KEY;
    if (!apiKey) {
      console.error(
        "Error: Missing GOOGLE_BOOKS_API_KEY environment variable.",
      );
      return createResponse(HttpStatus.INTERNAL_SERVER_ERROR, {
        message: "Internal server error: Missing configuration data.",
      });
    }

    // validate query parameter
    const rawQuery = event.queryStringParameters?.q;
    if (!rawQuery) {
      return createResponse(HttpStatus.BAD_REQUEST, {
        message: "Missing required query parameter: 'q'",
      });
    }
    // Limit query length and encode
    if (rawQuery.length > CONFIG.MAX_TITLE_LENGTH) {
      return createResponse(HttpStatus.BAD_REQUEST, {
        message: "Query parameter 'q' is longer than maximum allowed length.",
      });
    }
    const sanitizedQuery = encodeURIComponent(rawQuery);

    // fetch data from Google Books
    // search through book titles only
    const apiUrl = `${CONFIG.GOOGLE_BOOKS_URL}?q=intitle:${sanitizedQuery}&maxResults=${CONFIG.MAX_RESULTS}&key=${apiKey}`;
    const response = await fetch(apiUrl);

    // handle external errors
    if (!response.ok) {
      console.error(
        `Google Books API error: ${response.status} ${response.statusText}`,
      );
      // If we get `429` pass that, otherwise assume `502`
      const statusCode =
        response.status === HttpStatus.TOO_MANY_REQUESTS
          ? HttpStatus.TOO_MANY_REQUESTS
          : HttpStatus.BAD_GATEWAY;
      return createResponse(statusCode, {
        message: "Error communicating with external service.",
      });
    }

    const data = (await response.json()) as GoogleBooksResponse;

    // Map Google data to our own interfrace
    const books: LibraryBookItem[] = (data.items || []).map((item) => {
      // extract standard ISBNs
      const isbn13 = item.volumeInfo.industryIdentifiers?.find(
        (id) => id.type === "ISBN_13",
      )?.identifier;
      const isbn10 = item.volumeInfo.industryIdentifiers?.find(
        (id) => id.type === "ISBN_10",
      )?.identifier;

      return {
        id: item.id,
        title: item.volumeInfo.title,
        authors: item.volumeInfo.authors || [],
        isbn: isbn13 || isbn10 || null,
      };
    });

    // Successful return successfully processed data
    return createResponse(HttpStatus.OK, { results: books });
  } catch (error) {
    console.error("Unexpected error in BookTitleSearchFunction:", error);
    return createResponse(HttpStatus.INTERNAL_SERVER_ERROR, {
      message: "An unexpected error occurred processing the request.",
    });
  }
};
