package su.nsk.iae.edtl.generator

import org.logicng.formulas.Formula
import org.logicng.formulas.FormulaFactory

public class TermToLogicNGConverter {

    val FormulaFactory f;

    new (FormulaFactory f) {
        this.f = f;
    }

    def Formula convert(Term term) {
        if (term instanceof AndTerm) {
            return f.and(convert(term.left), convert(term.right))
        }

        if (term instanceof OrTerm) {
            return f.or(convert(term.left), convert(term.right))
        }

        if (term instanceof ImplTerm) {
            return f.implication(convert(term.left), convert(term.right))
        }

        if (term instanceof FTerm) {
            throw new IllegalArgumentException("Unsupported term")
        }

        if (term instanceof GTerm) {
            throw new IllegalArgumentException("Unsupported term")
        }

        if (term instanceof WTerm) {
            throw new IllegalArgumentException("Unsupported term")
        }

        if (term instanceof BoolTerm) {
            return f.constant(term.value)
        }

        if (term instanceof VarTerm) {
            return f.variable(term.name)
        }

        if (term instanceof TimeTerm) {
            throw new IllegalArgumentException("Unsupported term")
        }

        if (term instanceof NestTerm) {
            return convert(term.term)
        }

        if (term instanceof NotTerm) {
            return f.not(convert(term.term))
        }

        if (term instanceof FeTerm) {
            throw new IllegalArgumentException("Unsupported term")
        }

        if (term instanceof ReTerm) {
            throw new IllegalArgumentException("Unsupported term")
        }

        if (term instanceof HighTerm) {
            throw new IllegalArgumentException("Unsupported term")
        }

        if (term instanceof LowTerm) {
            throw new IllegalArgumentException("Unsupported term")
        }

        throw new IllegalArgumentException("Unsupported term type")
    }
}
