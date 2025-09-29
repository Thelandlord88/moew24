import type { FaqItem } from "./faq-types";

function stripTags(html: string): string {
  return html.replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim();
}

export function toFaqPageJsonLd(items: FaqItem[]) {
  return {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: items.map((it) => ({
      "@type": "Question",
      name: it.q,
      acceptedAnswer: { 
        "@type": "Answer", 
        text: stripTags(it.a)
      },
    })),
  };
}

export function normalizeFaq(items: FaqItem[]): FaqItem[] {
  return items.map(({ q, a }) => ({
    q: q.trim().replace(/\s+/g, " "),
    a: a.trim(),
  }));
}

export function dedupeFaqs(items: FaqItem[]): FaqItem[] {
  const seen = new Set<string>();
  return items.filter((x) => {
    const key = x.q.trim().toLowerCase();
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

export function createAnchor(question: string, fallbackIndex: number): string {
  const slug = question
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "");
  return slug || String(fallbackIndex);
}
