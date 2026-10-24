import { env } from "../config/env";
import { HttpError } from "../utils/httpError";

export async function fetchJson<T>(url: string, init?: RequestInit): Promise<T> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), env.requestTimeoutMs);

  try {
    const response = await fetch(url, {
      ...init,
      signal: controller.signal,
      headers: {
        Accept: "application/json",
        ...(init?.headers ?? {})
      }
    });

    if (!response.ok) {
      if (response.status === 429) {
        throw new HttpError(503, "The external map service is rate-limiting requests. Please try again later.");
      }
      throw new HttpError(502, `External map service returned status ${response.status}.`);
    }

    return (await response.json()) as T;
  } catch (error) {
    if (error instanceof HttpError) throw error;
    if (error instanceof Error && error.name === "AbortError") {
      throw new HttpError(504, "The map service timed out. Please try again.");
    }
    throw new HttpError(502, "Could not reach the external map service.");
  } finally {
    clearTimeout(timeout);
  }
}
