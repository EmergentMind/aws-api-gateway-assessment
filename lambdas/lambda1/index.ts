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
      return {
        statusCode: 500,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          message: "Internal server error: Missing configuration data.",
        }),
      };
    }

    // validate query parameter
    // FIXME: add sanitization and bounds
    const query = event.queryStringParameters?.q;
    if (!query) {
      return {
        statusCode: 400,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          message: "Missing required query parameter: 'q'",
        }),
      };
    }

    // fetch data from Google Books
    // search through book titles only, return a maximum 5 results
    const apiUrl = `https://www.googleapis.com/books/v1/volumes?q=intitle:${encodeURIComponent(query)}&maxResults=5&key=${apiKey}`;
    const response = await fetch(apiUrl);

    // handle external errors
    // FIXME: handle additional codes?
    if (!response.ok) {
      console.error(
        `Google Books API error: ${response.status} ${response.statusText}`,
      );
      return {
        // If we get '429 Too Many Requests' pass that, otherwise assume `502 Bad Gateway`
        statusCode: response.status === 429 ? 429 : 502,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          message: "Error communicating with external service.",
        }),
      };
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
    return {
      statusCode: 200,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ results: books }),
    };
  } catch (error) {
    console.error("Unexpected error in BookTitleSearchFunction:", error);
    return {
      statusCode: 500,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        message: "An unexpected error occurred processing the request.",
      }),
    };
  }
};
