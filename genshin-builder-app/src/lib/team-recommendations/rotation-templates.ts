import type { TeamCandidate } from "./types";
import { ROTATION_TEMPLATE_VERSION } from "./settings";

export interface RotationTemplate {
  version: string;
  confidence: "high" | "medium" | "low";
  render(characterKeys: string[], attackerKey: string): string;
}

export class RotationTemplateRepository {
  select(candidate: TeamCandidate): RotationTemplate {
    const confidence = candidate.observedByAza ? "medium" : "low";
    return {
      version: ROTATION_TEMPLATE_VERSION,
      confidence,
      render: (keys, attackerKey) => {
        const supports = keys.filter((key) => key !== attackerKey);
        return [
          "while 1 {",
          ...supports.flatMap((key) => [`  ${key} skill;`, `  ${key} burst;`]),
          `  ${attackerKey} skill;`,
          `  ${attackerKey} burst;`,
          `  ${attackerKey} attack:5;`,
          "}",
        ].join("\n");
      },
    };
  }
}
