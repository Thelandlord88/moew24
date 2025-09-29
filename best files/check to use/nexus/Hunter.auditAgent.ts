import { NEXUSOrchestrator, ComposedAgent } from './NEXUS.engine.js';
import { HunterPolicy, AuditScope } from './Hunter.policy.js';

export class HunterAuditAgent {
  private nexus: NEXUSOrchestrator;
  private policy: HunterPolicy;

  constructor(nexus: NEXUSOrchestrator) {
    this.nexus = nexus;
    this.policy = new HunterPolicy();
  }

  async createAuditAgent(taskDescription: string): Promise<ComposedAgent> {
    const forcedTraits = [
      'Evidence Verification',
      'Gap Analysis',
      'Architectural Violation Detection',
      'Forensic Analysis',
      'Brutal Honesty'
    ];

    return this.nexus.createOptimizedSession(
      `audit ${taskDescription} with forensic evidence verification and brutal honesty`,
      { requiredTraits: forcedTraits }
    );
  }

  async executeComprehensiveAudit(scope: AuditScope): Promise<any> {
    const auditAgent = await this.createAuditAgent('component quality and security');

    const [enhanced, policyAudit] = await Promise.all([
      auditAgent.execute({ task: 'Forensic audit of target scope', scope }),
      this.policy.auditComponent(scope)
    ]);

    return this.combineResults(enhanced, policyAudit);
  }

  private combineResults(enhancedAnalysis: any, policyAudit: any) {
    const combinedFindings = [...policyAudit.findings];

    if (enhancedAnalysis?.response) {
      combinedFindings.push({
        type: 'insight',
        severity: 'low',
        description: 'NEXUS-enhanced cognitive synthesis attached',
        evidence: [`Traits used: ${enhancedAnalysis.traitsUsed?.join(', ') || ''}`],
        impact: 'Provides broader cross-domain context',
        recommendation: 'Review synthesis alongside evidence-based findings',
        testable: false,
        nexusResponse: enhancedAnalysis.response
      });
    }

    return {
      ...policyAudit,
      findings: combinedFindings,
      enhancedInsights: enhancedAnalysis?.response ?? null,
      runtimeSource: enhancedAnalysis?.source ?? 'local-composition',
      traitsUsed: enhancedAnalysis?.traitsUsed ?? []
    };
  }
}
