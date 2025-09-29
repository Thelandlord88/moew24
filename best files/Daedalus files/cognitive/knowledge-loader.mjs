{
  "domain": "software-engineering",
  "type": "failure-pattern",
  "entries": [
    {
      "id": "fp-001",
      "name": "Capacity Illusion",
      "description": "Teams overcommit because estimation ignores cognitive load and context switching.",
      "symptoms": [
        "Repeated sprint overruns",
        "High WIP with low throughput",
        "Engineers report 'always context switching'"
      ],
      "root_causes": [
        "Estimation based on ideal hours, not real capacity",
        "No visibility into cognitive tax"
      ],
      "interventions": [
        "Confidence-weighted estimation",
        "WIP limits tied to cognitive load metrics"
      ],
      "related_principles": ["kairos-principle-3", "logos-principle-1"],
      "historical_cases": ["2023-q4-release-delay", "2022-sprint-collapse"]
    }
  ]
}
// knowledge-loader.mjs
import { readdir, readFile } from 'node:fs/promises';
import { resolve } from 'node:path';

export async function loadKnowledge(corpusPath = './knowledge') {
  const knowledge = {};
  const domains = await readdir(resolve(corpusPath));
  
  for (const domain of domains) {
    if (domain === 'corpus.manifest.json') continue;
    knowledge[domain] = {};
    
    const files = await readdir(resolve(corpusPath, domain));
    for (const file of files) {
      const content = await readFile(resolve(corpusPath, domain, file), 'utf8');
      const key = file.replace(/\.(json|md)$/, '');
      knowledge[domain][key] = file.endsWith('.json') ? JSON.parse(content) : content;
    }
  }
  
  return knowledge;
}
// In evolution-engine-v3.mjs
const knowledge = await loadKnowledge();

// When invoking Kairos:
const kairosInsight = await kairos.analyze(problem, {
  knowledge: knowledge['team-dynamics'],
  historicalCases: knowledge['meta']['cognitive-biases']
});
// kairos.mjs
export function analyze(problem, context) {
  const { knowledge } = context;
  
  // Match symptoms to known failure patterns
  const matches = knowledge['failure-patterns'].entries.filter(pattern =>
    pattern.symptoms.some(symptom => 
      problem.toLowerCase().includes(symptom.toLowerCase())
    )
  );
  
  if (matches.length > 0) {
    return {
      reframing: `This matches the "${matches[0].name}" pattern: ${matches[0].description}`,
      leveragePoints: matches[0].interventions,
      knowledgeRef: matches[0].id
    };
  }
  
  // ... fallback to first-principles reasoning
}
// knowledge-retriever.mjs
export async function retrieveRelevant(problem, knowledge, topK = 3) {
  const problemEmbedding = await embed(problem);
  const scores = [];
  
  for (const entry of knowledge.entries) {
    const sim = cosineSimilarity(problemEmbedding, entry.embedding);
    scores.push({ entry, score: sim });
  }
  
  return scores
    .sort((a, b) => b.score - a.score)
    .slice(0, topK)
    .map(s => s.entry);
}
